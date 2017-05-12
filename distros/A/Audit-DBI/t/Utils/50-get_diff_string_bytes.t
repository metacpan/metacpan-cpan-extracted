#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


# 'expected_relative' is the expected return value with absolute=0.
# 'expected_absolute' is the expected return value with absolute=1.
my $tests =
[
	{
		name              => 'Test empty diff.',
		diff              => undef,
		expected_relative => 0,
		expected_absolute => 0,
	},
	{
		name     => 'Test string.',
		diff     =>
		{
			old => 'Test',
			new => '12',
		},
		expected_relative => -2,
		expected_absolute => 6,
	},
	{
		name              => 'Test arrayref.',
		diff              =>
		[
			{
				'index' => 1,
				'new'   => 42,
				'old'   => 3,
			},
		],
		expected_relative => 1,
		expected_absolute => 3,
	},
	{
		name              => 'Test hashref.',
		diff              =>
		{
			'key2' =>
			{
				'new' => 3,
				'old' => 24,
			},
		},
		expected_relative => -1,
		expected_absolute => 3,
	},
];

can_ok(
	'Audit::DBI::Utils',
	'get_diff_string_bytes',
);

subtest(
	'Test relative diffs.',
	sub
	{
		plan( tests => scalar( @$tests ) );

		foreach my $test ( @$tests )
		{
			is(
				Audit::DBI::Utils::get_diff_string_bytes( $test->{'diff'} ),
				$test->{'expected_relative'},
				$test->{'name'},
			);
		}
	},
);

SKIP:
{
	eval "use String::Diff";
	skip( 'String::Diff needs to be installed to test absolute diffs.', 1 )
		if $@;

	subtest(
		'Test absolute diffs.',
		sub
		{
			plan( tests => scalar( @$tests ) );

			foreach my $test ( @$tests )
			{
				is(
					Audit::DBI::Utils::get_diff_string_bytes(
						$test->{'diff'},
						absolute => 1,
					),
					$test->{'expected_absolute'},
					$test->{'name'},
				);
			}
		},
	);
}

throws_ok(
	sub
	{
		Audit::DBI::Utils::get_diff_string_bytes(
			'invalid diff structure',
			absolute => 0,
		);
	},
	qr/Invalid diff structure/,
	'Require a valid diff structure.',
);
