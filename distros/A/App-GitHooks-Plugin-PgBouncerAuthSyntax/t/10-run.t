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
	{
		comments_setting => 'allow_anywhere',
		name             => 'Pass syntax check (two fields).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|,
		},
		expected         => qr/o The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'allow_anywhere',
		name     => 'Pass syntax check (extra information).',
		files    =>
		{
			'userlist.txt' => qq|"user" "password" "something else"\n|,
		},
		expected => qr/o The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'allow_anywhere',
		name             => 'Fail syntax check (extra double quote).',
		files            =>
		{
			'userlist.txt' => qq|"us"er" "password"\n|,
		},
		expected         => qr/\Qx The PgBouncer syntax is correct\E.*\QLine 0: "us"er" "password"\E/s,
	},
	{
		comments_setting => 'allow_anywhere',
		name             => 'Fail syntax check (extra double quote in later line).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|"us"er" "password"\n|,
		},
		expected         => qr/\Qx The PgBouncer syntax is correct\E.*\QLine 1: "us"er" "password"\E/s,
	},
	{
		comments_setting => 'allow_anywhere',
		name             => 'Fail syntax check (only one field provided).',
		files            =>
		{
			'userlist.txt' => qq|"user"\n|,
		},
		expected => qr/\Qx The PgBouncer syntax is correct\E.*\QLine 0: "user"\E/s,
	},
	{
		comments_setting => 'allow_anywhere',
		name             => 'Skip syntax check (file not in pattern).',
		files            =>
		{
			'test.txt'     => qq|"user"\n|,
		},
		expected         => qr/(?!\QThe PgBouncer syntax is correct\E)/,
	},
	{
		comments_setting => 'allow_anywhere',
		name             => 'Ignore comment lines (comments_setting=allow_anywhere).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|; A commment\n|
				. qq|"user" "password"\n|,
		},
		expected         => qr/o The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'allow_end_only',
		name             => 'Ignore comment lines at the end of the file (comments_setting=allow_end_only).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|"user" "password"\n|
				. qq|; A commment\n|,
		},
		expected         => qr/o The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'allow_end_only',
		name             => 'Prevent comment lines not at the end of the file (comments_setting=allow_end_only).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|; A commment\n|
				. qq|"user" "password"\n|,
		},
		expected         => qr/x The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'disallow',
		name             => 'Prevent comment lines at the end of the file (comments_setting=disallow).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|"user" "password"\n|
				. qq|; A commment\n|,
		},
		expected         => qr/x The PgBouncer syntax is correct/,
	},
	{
		comments_setting => 'disallow',
		name             => 'Prevent comment lines not at the end of the file (comments_setting=disallow).',
		files            =>
		{
			'userlist.txt' => qq|"user" "password"\n|
				. qq|; A commment\n|
				. qq|"user" "password"\n|,
		},
		expected         => qr/x The PgBouncer syntax is correct/,
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
				cleanup_test_repository => 0,
				config                  => "[PgBouncerAuthSyntax]\n"
					. "file_pattern = /\Quserlist.txt\E\$/\n"
					. "comments_setting = $test->{'comments_setting'}\n"
					. "\n",
				hooks                   => [ 'pre-commit' ],
				plugins                 => [ 'App::GitHooks::Plugin::PgBouncerAuthSyntax' ],
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
