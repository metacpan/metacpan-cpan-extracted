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

# Test files.
my $files =
{
	'test.pl' => "#!perl\n\nuse strict;\n",
};

# Failure message to detect.
my $failure_message = 'x Test plugin - custom return codes.';

# .githooksrc additions.
my $config = "[Test::CustomReply]\n"
	. "pre_commit = PLUGIN_RETURN_FAILED\n"
	. "pre_commit_file = PLUGIN_RETURN_FAILED\n"
	. "prepare_commit_msg = PLUGIN_RETURN_SKIPPED\n";

# List of tests to perform.
my $tests =
[
	{
		name        => 'Commit without --no-verify.',
		no_verify   => 0,
	},
	{
		name        => 'Commit with --no-verify.',
		no_verify   => 1,
	},
];

# Bail out if Git isn't available.
test_requires_git();
plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 6 );

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => $config,
				hooks                   =>
				[
					'pre-commit',
					'prepare-commit-msg',
				],
				plugins                 =>
				[
					'App::GitHooks::Plugin::DetectCommitNoVerify',
					'App::GitHooks::Plugin::Test::CustomReply',
				],
			);

			# Set up test files.
			ok_add_files(
				files      => $files,
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
							my @args = $test->{'no_verify'}
								? ( '--no-verify' )
								: '';
							$repository->run( 'commit', '-m', 'Test message.', @args );
							$exit_status = $? >> 8;
						}
					);
					note( $stderr );
				},
				'Commit the changes.',
			);

			# Test messages printed by git hooks prior to the commit itself.
			if ( $test->{'no_verify'} )
			{
				ok(
					!defined( $stderr ) || ( $stderr !~ /\w/ ),
					'No error message is printed prior to the commit.',
				) || diag( "STDERR: >$stderr<." );
			}
			else
			{
				like(
					$stderr,
					qr/\Q$failure_message\E/,
					'The commit failed with an error message.',
				);
			}

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
					qr/\Q$failure_message\E/,
					'The pre-commit errors are embedded in the commit message.',
				);
			}
		}
	);
}
