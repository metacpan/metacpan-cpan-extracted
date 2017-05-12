#!perl

use strict;
use warnings;

use App::GitHooks;
use App::GitHooks::Test;
use App::GitHooks::Utils;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );

# List of tests to run.
my $tests =
[
	{
		name     => 'No value defined in the config, fall back on the default.',
		config   => "project_prefixes = OPS DEV\n",
		expected => '^((?:OPS|DEV)-\d+|--)\: ?',
	},
	{
		name     => 'Value defined in the config.',
		config   => "project_prefixes = OPS DEV\n"
			. 'extract_ticket_id_from_commit = /^($project_prefixes)_(\d+)/' . "\n",
		expected => '^((?:OPS|DEV))_(\d+)',
	},
];

# Declare tests.
plan( tests => scalar( @$tests + 1 ) );

# Make sure the function exists before we start.
can_ok(
	'App::GitHooks::Utils',
	'get_ticket_id_from_commit_regex',
);

# Run each test in a subtest.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 4 );

			# Set up githooks config.
			App::GitHooks::Test::ok_reset_githooksrc(
				content => $test->{'config'},
			);

			ok(
				defined(
					my $app = App::GitHooks->new(
						arguments => [],
						name      => 'commit-msg',
					)
				),
				'Instantiate a new App::GitHooks object.',
			);

			my $ticket_id_regex;
			lives_ok(
				sub
				{
					$ticket_id_regex = App::GitHooks::Utils::get_ticket_id_from_commit_regex( $app );
				},
				'Retrieve the ticket ID regex.',
			);

			is(
				$ticket_id_regex,
				$test->{'expected'},
				'Compare the output and expected results.',
			);
		}
	);
}
