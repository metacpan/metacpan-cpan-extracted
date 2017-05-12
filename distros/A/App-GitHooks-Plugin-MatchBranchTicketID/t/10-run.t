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
## no critic (RegularExpressions::ProhibitComplexRegexes)

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
		name           => 'Branch: dev1234 prefix; Project prefixes: DEV; commit ticket ID: DEV-1234; expected: success.',
		branch         => 'dev1234_test_branch',
		config         => "[_]\n"
			. "project_prefixes = DEV\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/^$/,
	},
	{
		name           => 'Branch: dev1234 prefix; Project prefixes: DEV; commit ticket ID: DEV-12344; expected: error.',
		branch         => 'dev1234_test_branch',
		config         => "[_]\n"
			. "project_prefixes = DEV\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-12344: Test',
		expected       => qr/\QYour branch is referencing DEV-1234, but your commit message references DEV-12344.\E/,
	},
	{
		name           => 'Branch: no prefix; Project prefixes: DEV; commit ticket ID: DEV-1234; expected: skip.',
		branch         => 'master',
		config         => "[_]\n"
			. "project_prefixes = DEV\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/^$/,
	},
	{
		name           => 'Branch: dev1234 prefix; Project prefixes: OPS; commit ticket ID: DEV-12344; expected: skip.',
		branch         => 'dev1234_test_branch',
		config         => "[_]\n"
			. "project_prefixes = OPS\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-12344: Test',
		expected       => qr/^$/,
	},
	{
		name           => 'Branch: dev1234 prefix; Project prefixes: OPS, DEV, TEST; commit ticket ID: DEV-1234; expected: success.',
		branch         => 'dev1234_test_branch',
		config         => "[_]\n"
			. "project_prefixes = OPS, DEV, TEST\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/^$/,
	},
	{
		name           => 'Branch: dev1234 prefix; Project prefixes: OPS, DEV, TEST; commit ticket ID: DEV-1234; Invalid normalize_branch_ticket_id regex; expected: failure.',
		branch         => 'dev1234_test_branch',
		config         => "[_]\n"
			. "project_prefixes = OPS, DEV, TEST\n"
			. 'extract_ticket_id_from_branch = /^($project_prefixes\d+)/' . "\n"
			. 'normalize_branch_ticket_id = s/^(.*?)/(\d+)$/\U$1-$2/' . "\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /' . "\n",
		files          => $files,
		commit_message => 'DEV-1234: Test',
		expected       => qr/\QERROR: Unsafe replacement pattern in 'normalize_branch_ticket_id', escape your slashes\E/,
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
				config                  => $test->{'config'},
				hooks                   => [ 'commit-msg' ],
				plugins                 => [ 'App::GitHooks::Plugin::MatchBranchTicketID' ],
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
