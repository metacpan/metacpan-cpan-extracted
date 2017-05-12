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
	'test.pl'          => "#!perl\n\nuse strict;\n",
	'.last_update.txt' => time() - 10000,
};

# Plugin configuration options.
my $description = './update_libs';
my $env_variable = 'test_environment';

# List of tests to perform.
my $tests =
[
	{
		name        => 'Commit after a recent update.',
		environment => 'development',
		config      => "max_update_age = 172800 # 2 days\n"
			. "update_file = .last_update.txt\n",
		expected    => qr/^(?!.*\Q$description\E)/s,
	},
	{
		name        => 'Commit after an old update.',
		environment => 'development',
		config      => "max_update_age = 10 # 10 seconds\n"
			. "update_file = .last_update.txt\n",
		expected    => qr/^\Qx It appears that you haven't performed $description on this machine for a long time. Please do that and try to commit again.\E/,
	},
	# Make sure the env variable check works.
	{
		name        => 'Commit in production.',
		environment => 'production',
		config      => "max_update_age = 172800 # 2 days\n"
			. "update_file = .does_not_exist.txt\n",
		expected    => qr/^(?!.*\Q$description\E)/s,
	},
	{
		name        => 'Commit in development.',
		environment => 'development',
		config      => "max_update_age = 172800 # 2 days\n"
			. "update_file = .does_not_exist.txt\n",
		expected    => qr/^\Qx It appears that you have never performed $description on this machine - please do that before committing.\E/,
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

			ok(
				$ENV{ $env_variable } = $test->{'environment'},
				'Change environment.',
			);

			my $repository = ok_setup_repository(
				cleanup_test_repository => 0,
				config                  => "[ForceRegularUpdate]\n"
					. "description = $description\n"
					. "env_variable = $env_variable\n"
					. "env_regex = /^development\$/\n"
					. "$test->{'config'}\n",
				hooks                   => [ 'pre-commit' ],
				plugins                 => [ 'App::GitHooks::Plugin::ForceRegularUpdate' ],
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

			like(
				$stderr,
				$test->{'expected'},
				"The output matches expected results.",
			);
		}
	);
}
