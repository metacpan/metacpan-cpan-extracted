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
		name           => 'Missing ticket ID.',
		files          => $files,
		commit_message => 'Test',
		expected       => qr/\Qx Your commit message needs to start with a ticket ID.\E/,
	},
	{
		name           => 'Properly formatted ticket ID.',
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/^$/,
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
			plan( tests => 4 );

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => "[_]\n"
					. "project_prefixes = DEV\n"
					. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
				hooks                   => [ 'commit-msg' ],
				plugins                 => [ 'App::GitHooks::Plugin::RequireTicketID' ],
			);

			# Set up test files.
			ok_add_files(
				files      => $test->{'files'},
				repository => $repository,
			);

			# Try to commit.
			my $stderr;
			lives_ok(
				sub
				{
					$stderr = Capture::Tiny::capture_stderr(
						sub
						{
							$repository->run( 'commit', '-m', $test->{'commit_message'} );
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
		}
	);
}
