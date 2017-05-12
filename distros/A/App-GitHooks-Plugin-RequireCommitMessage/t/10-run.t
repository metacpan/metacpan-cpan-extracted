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
my $files =
{
	'test.pl' => "#!perl\n\nuse strict;\n1;\n",
};
my $tests =
[
	{
		name           => 'Completely empty commit message.',
		files          => $files,
		commit_message => '',
		# This test should show "Aborting commit due to empty commit message" but
		# not a line starting with "x " which would indicate that the git hook is
		# still active. Because this git message is language-dependent based on the
		# locale of the user, we can only test the negative lookahead of the latter.
		expected       => qr/^(?!x )/,
		exit_status    => 1,
	},
	{
		name           => 'Non-empty commit message without ticket ID.',
		files          => $files,
		commit_message => 'Test commit message.',
		expected       => qr/^$/,
		exit_status    => 0,
	},
	{
		name           => 'Non-empty commit message with only a ticket ID',
		files          => $files,
		commit_message => 'DEV-1234: ',
		expected       => qr/^x You did not enter a commit message/,
		exit_status    => 1,
	},
	{
		name           => 'Non-empty commit message with ticket ID.',
		files          => $files,
		commit_message => 'DEV-1234: Test commit message.',
		expected       => qr/^$/,
		exit_status    => 0,
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
			plan( tests => 5 );

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => "[_]\n"
					. "project_prefixes = DEV\n"
					. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): ?/' . "\n",
				hooks                   => [ 'commit-msg' ],
				plugins                 => [ 'App::GitHooks::Plugin::RequireCommitMessage' ],
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
							$repository->run( 'commit', '-m', $test->{'commit_message'} );
							$exit_status = $? >> 8;
						}
					);
					note( $stderr );
				},
				'Commit the changes.',
			);

			like(
				$stderr,
				$test->{'expected'},
				"The output matches expected results.",
			);

			is(
				$exit_status,
				$test->{'exit_status'},
				'The exit status is correct.',
			);
		}
	);
}
