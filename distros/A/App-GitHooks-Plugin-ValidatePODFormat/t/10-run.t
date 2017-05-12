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
		name     => 'No POD.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n",
		},
		expected => qr/o POD format is valid/,
	},
	{
		name     => 'Valid POD.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n=head1 FUNCTIONS\n\n=cut\n",
		},
		expected => qr/o POD format is valid/,
	},
	{
		name     => 'Invalid POD.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n=head5 FUNCTIONS\n\n=cut\n",
		},
		expected => qr/x POD format is valid/,
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
				plugins                 => [ 'App::GitHooks::Plugin::ValidatePODFormat' ],
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
