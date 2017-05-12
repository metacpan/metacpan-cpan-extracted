#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Test::Exception;
use Test::Requires::Git;;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


# Require git.
test_requires_git( '1.7.4.1' );

## no critic (RegularExpressions::RequireExtendedFormatting)

# Test files.
my $files =
{
	'test.pl' => "#!perl\n\nuse strict;\n",
};

# Plugin configuration options.
my $env_variable = 'test_environment';

# Regex to detect when the plugin has identified a commit in production.
my $failure = qr/x Non-dev environment detected - please commit from your dev instead/;

# List of tests to perform.
my $tests =
[
	{
		name        => 'Commit in production.',
		environment => 'production',
		allow       => 0,
	},
	{
		name        => 'Commit in development.',
		environment => 'development',
		allow       => 1,
	},
	# TODO: test whitelisting a remote.
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

			ok(
				$ENV{ $env_variable } = $test->{'environment'},
				'Change environment.',
			);

			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => "[BlockProductionCommits]\n"
					. "env_variable = $env_variable\n"
					. "env_safe_regex = /^development\$/\n"
					. "remotes_whitelist_regex = /\\/test\.git/\n",
				hooks                   => [ 'pre-commit' ],
				plugins                 => [ 'App::GitHooks::Plugin::BlockProductionCommits' ],
			);

			# Set up test files.
			ok_add_files(
				files      => $files,
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
							$repository->run( 'commit', '-m', 'Test message.' );
						}
					);
					note( $stderr );
				},
				'Commit the changes.',
			);

			if ( $test->{'allow'} )
			{
				unlike(
					$stderr,
					$failure,
					"The output matches expected results.",
				);
			}
			else
			{
				like(
					$stderr,
					$failure,
					"The output matches expected results.",
				);
			}
		}
	);
}
