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

# Regex test key.
my $key_name = 'regex';

# List of tests to run.
my $tests =
[
	{
		name     => 'Key not defined.',
		config   => '',
		expected => undef,
	},
	{
		name     => 'Empty value.',
		config   => "$key_name =\n",
		expected => undef,
	},
	{
		name     => 'Value is not a regex.',
		config   => "$key_name = test\n",
		throws   => "The key $key_name in the section _ is not a regex, use /.../ to delimit your expression",
	},
	{
		name     => 'Value has unescaped slash delimiters.',
		config   => "$key_name = /test/test/\n",
		throws   => "The key $key_name in the section _ does not specify a valid regex, it has unescaped '/' delimiters inside it",
	},
	{
		name     => 'Valid regex.',
		config   => "$key_name = /test/\n",
		expected => 'test',
	},
];

# Declare tests.
plan( tests => scalar( @$tests + 1 ) );

# Make sure the function exists before we start.
can_ok(
	'App::GitHooks::Config',
	'get_regex',
);

# Run each test in a subtest.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 5 );

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

			ok(
				defined(
					my $config = $app->get_config()
				),
				'Retrieve the corresponding config object.',
			);

			my $regex;
			if ( defined( $test->{'throws'} ) )
			{
				throws_ok(
					sub
					{
						$regex = $config->get_regex( '_', $key_name );
					},
					qr/\Q$test->{'throws'}\E/,
					'regex() throws the expected error.',
				);
			}
			else
			{
				lives_ok(
					sub
					{
						$regex = $config->get_regex( '_', $key_name );
					},
					'Retrieve the regex value.',
				);
			}

			SKIP:
			{
				skip('The regex() call should return an exception.', 1)
					if defined( $test->{'throws'} );

				is(
					$regex,
					$test->{'expected'},
					'The regex returned matches the expected value.',
				);
			}
		}
	);
}
