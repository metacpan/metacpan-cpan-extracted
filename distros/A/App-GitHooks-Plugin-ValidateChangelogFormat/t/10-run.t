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
	# Make sure the plugin correctly analyzes changelog files.
	(
		map
		{
			{
				name     => "'$_' is a monitored file name.",
				files    =>
				{
					$_ => "test\n",
				},
				expected => qr/\Qx The changelog format matches CPAN::Changes::Spec.\E/,
			},
		} qw( Changes CHANGELOG Changes.pod changelog.md )
	),
	# The changelog must contain at least one release.
	{
		name     => 'The changelog must contain at least one release.',
		files    =>
		{
			'Changes' => "Release for test package.\n",
		},
		expected => qr/\Qx The changelog format matches CPAN::Changes::Spec.\E/,
	},
	# Test custom version numbers.
	{
		name     => 'Fail version format specification in githooksrc.',
		config   => "[ValidateChangelogFormat]\n"
			. 'version_format_regex = /^v\d+$/' . "\n",
		files    =>
		{
			'Changes' => "Release for test package.\n"
				. "\n"
				. "1.2.3  2014-01-01\n"
				. "  - Test feature.\n",
		},
		expected => qr|\QRelease 1/1: version '1.2.3' is not a valid version number\E|,
	},
	{
		name     => 'Pass version format specification in githooksrc.',
		config   => "[ValidateChangelogFormat]\n"
			. 'version_format_regex = /^v\d+$/' . "\n",
		files    =>
		{
			'Changes' => "Release for test package.\n"
				. "\n"
				. "v1  2014-01-01\n"
				. "  - Test feature.\n",
		},
		expected => qr/o The changelog format matches CPAN::Changes::Spec/,
	},
	# Test custom date formats.
	{
		name     => 'Fail date format specification in githooksrc.',
		config   => "[ValidateChangelogFormat]\n"
			. 'date_format_regex = /^\d{4}-\d{2}-\d{2}$/' . "\n",
		files    =>
		{
			'Changes' => "Release for test package.\n"
				. "\n"
				. "v1.2.3  2014-01-01 01:00\n"
				. "  - Test feature.\n",
		},
		expected => qr|\QRelease 1/1: date '2014-01-01T01:00Z' is not in the recommended format\E|,
	},
	{
		name     => 'Pass date format specification in githooksrc.',
		config   => "[ValidateChangelogFormat]\n"
			. 'date_format_regex = /^\d{4}-\d{2}-\d{2}$/' . "\n",
		files    =>
		{
			'Changes' => "Release for test package.\n"
				. "\n"
				. "v1.2.3  2014-01-01\n"
				. "  - Test feature.\n",
		},
		expected => qr/o The changelog format matches CPAN::Changes::Spec/,
	},
	# Make sure that releases contain at least one change.
	{
		name     => 'A release must contain at least one change.',
		files    =>
		{
			'Changes' => "Release for test package.\n"
				. "\n"
				. "v1.2.3  2014-01-01\n"
		},
		expected => qr|\QRelease 1/1: the release does not contain a description of changes\E|,
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
				plugins                 => [ 'App::GitHooks::Plugin::ValidateChangelogFormat' ],
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
