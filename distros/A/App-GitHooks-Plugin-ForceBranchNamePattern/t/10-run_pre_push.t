#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Test::Exception;
use Test::Git;
use Test::Requires::Git;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::ProhibitComplexRegexes)


# The plugin relies on the pre-push hook, which is only available as of git
# v1.8.2.
test_requires_git( '1.8.2' );

# List of tests to perform.
my $tests =
[
	# Test alphanumeric branches.
	{
		name           => 'Branch passes alphanumeric only requirement.',
		create_branch  => 'test',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^[a-zA-Z0-9]+$/' . "\n",
		expected       => qr/\Q[new branch]\E\s+\Qtest -> test\E/,
		exit_status    => 0,
	},
	{
		name           => 'Branch fails alphanumeric only requirement.',
		create_branch  => 'test_',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^[a-zA-Z0-9]+$/' . "\n",
		expected       => qr/\QThe following branch does not match the pattern enforced by the git hooks configuration file: test_.\E/,
		exit_status    => 1,
	},

	# Test branches starting with a JIRA ID.
	{
		name           => 'Branch passes JIRA ID followed by an underscore.',
		create_branch  => 'DEV-123_test_feature',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^DEV-\d+_/' . "\n",
		expected       => qr/\Q[new branch]\E\s+\QDEV-123_test_feature -> DEV-123_test_feature\E/,
		exit_status    => 0,
	},
	{
		name           => 'Branch fails JIRA ID followed by an underscore.',
		create_branch  => 'DEV-123',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^DEV-\d+_/' . "\n",
		expected       => qr/\QThe following branch does not match the pattern enforced by the git hooks configuration file: DEV-123.\E/,
		exit_status    => 1,
	},

	# Test prefixed branches starting with a JIRA ID.
	{
		name           => 'Branch passes JIRA ID followed by an underscore, no prefix.',
		create_branch  => 'DEV-123_test_feature',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)?DEV-\d+_/' . "\n",
		expected       => qr/\Q[new branch]\E\s+\QDEV-123_test_feature -> DEV-123_test_feature\E/,
		exit_status    => 0,
	},
	{
		name           => 'Branch passes JIRA ID followed by an underscore, with prefix.',
		create_branch  => 'ga/DEV-123_test_feature',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)?DEV-\d+_/' . "\n",
		expected       => qr/\Q[new branch]\E\s+\Qga\/DEV-123_test_feature -> ga\/DEV-123_test_feature\E/,
		exit_status    => 0,
	},
	{
		name           => 'Branch fails JIRA ID followed by an underscore, with prefix.',
		create_branch  => 'ga/DEV-123',
		config         => "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)DEV-\d+_/' . "\n",
		expected       => qr/\QThe following branch does not match the pattern enforced by the git hooks configuration file: ga\/DEV-123\E/,
		exit_status    => 1,
	},

	# Test project prefixes.
	{
		name           => 'Branch passes JIRA ID using project prefixes set in config.',
		create_branch  => 'DEV-123_test_feature',
		config         => "[_]\n"
			. "project_prefixes = DEV, OPS\n"
			. "\n"
			. "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)?$project_prefixes-\d+_/' . "\n",
		expected       => qr/\Q[new branch]\E\s+\QDEV-123_test_feature -> DEV-123_test_feature\E/,
		exit_status    => 0,
	},
	{
		name           => 'Branch fails JIRA ID with a project prefix not defined in the list of valid project prefixes.',
		create_branch  => 'ga/DEV-123',
		config         => "[_]\n"
			. "project_prefixes = OPS, IT\n"
			. "\n"
			. "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)$project_prefixes-\d+_/' . "\n",
		expected       => qr/\QThe following branch does not match the pattern enforced by the git hooks configuration file: ga\/DEV-123\E/,
		exit_status    => 1,
	},
	{
		name           => '"branch_name_pattern" uses $project_prefixes, but "project_prefix" is not defined.',
		create_branch  => 'ga/DEV-123',
		config         => "[_]\n"
			. "\n"
			. "[ForceBranchNamePattern]\n"
			. 'branch_name_pattern = /^(?:[^\/]+\/)$project_prefixes-\d+_/' . "\n",
		expected       => qr/\QNo 'project_prefixes' values specified, but required in the pattern specified by 'branch_name_pattern' in the [ForceBranchNamePattern] section of the config.\E/,
		exit_status    => 1,
	},

	# Test missing branch_name_pattern.
	{
		name           => 'branch_name_pattern is not defined in the config.',
		create_branch  => 'DEV-123_test_feature',
		config         => "[ForceBranchNamePattern]\n",
		expected       => qr/\Q[new branch]\E\s+\QDEV-123_test_feature -> DEV-123_test_feature\E/,
		exit_status    => 0,
	},
];

plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 9 );

			my $local_repository = ok_setup_repository(
				cleanup_test_repository => 0,
				config                  => $test->{'config'},
				hooks                   => [ 'pre-push' ],
				plugins                 => [ 'App::GitHooks::Plugin::ForceBranchNamePattern' ],
			);

			# Set up test files.
			ok_add_files(
				files      =>
				{
					'test.txt' => "Test.\n",
				},
				repository => $local_repository,
			);

			# Create a first commit, so that we can clone this repo afterwards to
			# create a remote.
			lives_ok(
				sub
				{
					$local_repository->run( 'commit', '-m', 'Test message.' );
				},
				'Commit the changes.',
			);

			my $remote_repository;
			lives_ok(
				sub
				{
					my $output = Capture::Tiny::capture_merged(
						sub
						{
							$remote_repository = Test::Git::test_repository(
								clone => [ $local_repository->git_dir() ],
								temp  => [ CLEANUP => 0 ],
							);
						}
					);
					note( $output );
				}
			);

			# Set the test remote so that the local repository can push.
			lives_ok(
				sub
				{
					$local_repository->run( 'remote', 'add', 'origin', 'file://' . $remote_repository->git_dir() );
				},
				'Set up a remote on the local repository.',
			);

			# Create the test branch.
			lives_ok(
				sub
				{
					my $output = Capture::Tiny::capture_merged(
						sub
						{
							print $local_repository->run( 'checkout', '-b', $test->{'create_branch'} );
						}
					);
					note( $output );
				},
				'Create the test branch.',
			);

			# Try to push.
			my $output;
			my $exit_status;
			lives_ok(
				sub
				{
					$output = Capture::Tiny::capture_merged(
						sub
						{
							print $local_repository->run( 'push', '--set-upstream', 'origin', $test->{'create_branch'} );
							$exit_status = $? >> 8;
						}
					);
					note( $output );
				},
				'Push the branch to the remote.',
			);

			like(
				$output,
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
