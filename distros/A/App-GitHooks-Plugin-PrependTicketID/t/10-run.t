#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Carp;
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
		name           => 'The commit message is prepended with the branch ticket prefix.',
		branch         => 'dev1234_test_branch',
		files          => $files,
		commit_message => 'Test',
		expected       => qr/^DEV-1234: Test/,
	},
	{
		name           => 'The commit message is not prepended with the branch ticket prefix if it already has a matching ticket ID.',
		branch         => 'dev1234_test_branch',
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/^DEV-1234: Test/,
	},
	{
		name           => 'The commit message is not prepended with the branch ticket prefix even if the commit message includes a different ticket ID.',
		branch         => 'dev1234_test_branch',
		files          => $files,
		commit_message => 'DEV-5678: Test',
		expected       => qr/^DEV-5678: Test/,
	},
	{
		name           => 'The commit message is not prepended if the branch has no ticket prefix.',
		branch         => 'master',
		files          => $files,
		commit_message => 'Test',
		expected       => qr/^Test/,
	},
	{
		name           => 'The commit message is not prepended with the branch ticket prefix if the project prefix is incorrect.',
		branch         => 'test1234_test_branch',
		files          => $files,
		commit_message => 'Test',
		expected       => qr/^Test/,
	},
	{
		name           => 'The commit message is prepended with the branch ticket prefix for private branches as well.',
		branch         => 'ga/dev1234_test_branch',
		files          => $files,
		commit_message => 'Test',
		expected       => qr/^DEV-1234: Test/,
	},
	{
		name           => 'The custom commit_prefix_format configuration option is respected.',
		branch         => 'ga/dev1234_test_branch',
		files          => $files,
		config         => "[PrependTicketID]\n"
			. 'commit_prefix_format = /($ticket_id) /' . "\n",
		commit_message => 'Test',
		expected       => qr/^\Q(DEV-1234) Test\E/,
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

			$test->{'config'} = ''
				if !defined( $test->{'config'} );

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => "[_]\n"
					. "project_prefixes = DEV\n"
					. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
					. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
					. $test->{'config'},
				hooks                   => [ 'prepare-commit-msg' ],
				plugins                 => [ 'App::GitHooks::Plugin::PrependTicketID' ],
			);

			# Switch to the branch used for testing.
			my $branch = $test->{'branch'};
			croak 'The test must define a branch'
				if !defined( $branch ) || ( $branch eq '' );

			lives_ok(
				sub
				{
					my $stderr = Capture::Tiny::capture_stderr(
						sub
						{
							$repository->run( 'checkout', '-b', $branch );
						}
					);
					note( $stderr );
				},
				'Switch branches.',
			);

			# Set up test files.
			ok_add_files(
				files      => $test->{'files'},
				repository => $repository,
			);

			# Commit.
			lives_ok(
				sub
				{
					$repository->run( 'commit', '-m', $test->{'commit_message'} );
				},
				'Commit the changes.',
			);

			# Retrieve the commit message.
			my $commit_message;
			lives_ok(
				sub
				{
					$commit_message = $repository->run( 'log', '-1', '--pretty=%B' );
				},
				'Retrieve the commit message.',
			);
			note( "Commit message: >$commit_message<." );

			# Check the format of the commit message.
			like(
				$commit_message,
				$test->{'expected'},
				"The output matches expected results.",
			);
		}
	);
}
