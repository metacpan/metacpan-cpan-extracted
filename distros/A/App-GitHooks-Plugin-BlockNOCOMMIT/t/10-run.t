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
		name     => 'Detect "# NOCOMMIT".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict; # NOCOMMIT\n1;\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'Detect "#NOCOMMIT".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict; #NOCOMMIT\n1;\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'Detect "# NO COMMIT".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict; # NO COMMIT\n1;\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'Detect "#    NO   COMMIT".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict; #   NO   COMMIT\n1;\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'Detect "#    NO   COMMIT".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict; #   NO   COMMIT\n1;\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'Pass file without the no-commit comment".',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/\Qo The file has no #NOCOMMIT tags.\E/,
	},
	{
		name     => 'All files are tested for the no-commit comment presence.',
		files    =>
		{
			'test' => "A text file\nwith\nsome # NOCOMMIT\n information.\n",
		},
		expected => qr/\Qx The file has no #NOCOMMIT tags.\E/,
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
				plugins                 => [ 'App::GitHooks::Plugin::BlockNOCOMMIT' ],
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
