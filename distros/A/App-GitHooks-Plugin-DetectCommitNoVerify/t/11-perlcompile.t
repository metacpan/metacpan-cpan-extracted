#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Test::Exception;
use Test::Requires::Git;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


## no critic (RegularExpressions::RequireExtendedFormatting)

# Require git.
test_requires_git( '1.7.4.1' );

# List of tests to perform.
my $tests =
[
	# Make sure the plugin correctly analyzes Perl files.
	{
		name     => 'If one of the checks fails, the error must be included in the commit message.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/\Qx The file passes perl -c\E/,
	},
	{
		name     => 'If all the checks pass, the commit message must be left untouched.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/^\s*\QTest message.\E\s*$/,
	},
];

# Bail out if Git isn't available.
test_requires_git();

# Bail out if App::GitHooks::Plugin::PerlCompile is not available.
my $module = 'App::GitHooks::Plugin::PerlCompile';
eval { require $module };
plan( skip_all => "$module is not installed." )
	if $@;

plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 5 );

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => $test->{'config'},
				hooks                   =>
				[
					'pre-commit',
					'prepare-commit-msg',
				],
				plugins                 =>
				[
					'App::GitHooks::Plugin::PerlCompile',
					'App::GitHooks::Plugin::DetectCommitNoVerify',
				],
			);

			# Set up test files.
			ok_add_files(
				files      => $test->{'files'},
				repository => $repository,
			);

			# Try to commit.
			my $stderr;
			my $exit_status;
			lives_ok(
				sub
				{
					$stderr = Capture::Tiny::capture_stderr(
						sub
						{
							$repository->run( 'commit', '-m', 'Test message.', '--no-verify' );
							$exit_status = $? >> 8;
						}
					);
				},
				'Commit the changes.',
			);
			note( $stderr )
				if $stderr;

			SKIP:
			{
				skip(
					'Commit failed, cannot test commit message.',
					2,
				) if $exit_status != 0;

				# Retrieve the commit message.
				my $commit_message;
				lives_ok(
					sub
					{
						$commit_message = $repository->run( 'log', '-1', '--pretty=%B' );
					},
					'Retrieve the commit message.',
				);

				# Check the format of the commit message.
				like(
					$commit_message,
					$test->{'expected'},
					'The commit message includes the expected information.',
				);
			}
		}
	);
}
