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
		name     => 'Fail interpreter check.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/x The Perl interpreter line is correct/,
	},
	{
		name     => 'Pass interpreter check.',
		files    =>
		{
			'test.pl' => "#!/usr/bin/env perl\n\nuse strict;\n1;\n",
		},
		expected => qr/o The Perl interpreter line is correct/,
	},
	# Make sure the correct file times are analyzed.
	{
		name     => 'Skip non-Perl files',
		files    =>
		{
			'test.txt' => 'A text file.',
		},
		expected => qr/^(?!.*\Qx The Perl interpreter line is correct\E)/,
	},
	{
		name     => 'Catch .pl files.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/x The Perl interpreter line is correct/,
	},
	{
		name     => 'Catch .t files.',
		files    =>
		{
			'test.t' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/x The Perl interpreter line is correct/,
	},
	{
		name     => 'Catch files without extension but with a Perl hashbang line.',
		files    =>
		{
			'test' => "#!perl\n\nuse strict;\n1;\n",
		},
		expected => qr/x The Perl interpreter line is correct/,
	},
	{
		name     => 'Skip files without extension and no hashbang.',
		files    =>
		{
			'test' => "A regular non-Perl file.\n",
		},
		expected => qr/^(?!.*\QThe Perl interpreter line is correct\E)/,
	},
	# Test recommended interpreter.
	{
		name     => 'Fail interpreter check and recommend interpreter.',
		files    =>
		{
			'test.pl' => "#!perl\n\nuse strict;\n1;\n",
		},
		config   => "recommended_interpreter = #!/usr/bin/env perl\n",
		expected => qr|\QRecommended: #!/usr/bin/env perl\E|,
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

			my $config = $test->{'config'} // '';
			my $repository = ok_setup_repository(
				cleanup_test_repository => 1,
				config                  => '[PerlInterpreter]' . "\n"
					. 'interpreter_regex = /^#!\/usr\/bin\/env perl$/' . "\n"
					. $config . "\n",
				hooks                   => [ 'pre-commit' ],
				plugins                 => [ 'App::GitHooks::Plugin::PerlInterpreter' ],
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
