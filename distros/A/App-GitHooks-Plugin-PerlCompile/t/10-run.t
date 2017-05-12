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
	# Make sure the plugin correctly analyzes Perl files.
	{
		name     => 'Fail compilation check.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/x The file passes perl -c/,
	},
	{
		name     => 'Pass compilation check.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/o The file passes perl -c/,
	},
	# Make sure the correct file times are analyzed.
	{
		name     => 'Skip non-Perl files',
		files    =>
		{
			'test.txt' => 'A text file.',
		},
		expected => qr/^(?!.*\QThe file passes perl -c\E)/,
	},
	{
		name     => 'Catch .pm files.',
		files    =>
		{
			'test.pm' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/x The file passes perl -c/,
	},
	{
		name     => 'Catch .pl files.',
		files    =>
		{
			'test.pm' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/x The file passes perl -c/,
	},
	{
		name     => 'Catch .t files.',
		files    =>
		{
			'test.pm' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/x The file passes perl -c/,
	},
	{
		name     => 'Catch files without extension but with a Perl hashbang line.',
		files    =>
		{
			'test' => "#!perl\n\nuse strict;\nbareword;\n",
		},
		expected => qr/x The file passes perl -c/,
	},
	{
		name     => 'Skip files without extension and no hashbang.',
		files    =>
		{
			'test' => "A regular non-Perl file.\n",
		},
		expected => qr/^(?!.*\QThe file passes perl -c\E)/,
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
				config                  => $test->{'config'},
				hooks                   => [ 'pre-commit' ],
				plugins                 => [ 'App::GitHooks::Plugin::PerlCompile' ],
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
