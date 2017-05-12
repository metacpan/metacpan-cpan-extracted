#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Data::Dumper;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


# Tests to run. Each test requires two data structures to be compared ('old'
# and 'new'), a test name, and expected outputs for the different comparison
# functions:
#     * expected_default: the output without a comparison function specified.
#     * expected_eq: the output with 'eq' used as the comparison function
#       (only if it is different from 'expected_default').
#     * expected_custom: the output with a custom comparison function
#       (only if it is different from 'expected_default').
#
my $tests =
[
	{
		name             => 'diff() on matching scalars.',
		old              => 'A',
		new              => 'A',
		expected_default => undef,
	},
	{
		name             => 'diff() on scalars.',
		old              => 'A',
		new              => 'B',
		expected_default =>
		{
			old => 'A',
			new => 'B',
		},
	},
	{
		name             => 'diff() on arrayrefs.',
		old              =>
		[
			1,
			2,
			3,
		],
		new              =>
		[
			1,
			4,
			3,
		],
		expected_default =>
		[
			{
				'index' => 1,
				'new'   => 4,
				'old'   => 2
			},
		],
	},
	{
		name             => 'diff() on hashrefs.',
		old              =>
		{
			'key1' => 1,
			'key2' => 2,
		},
		new              =>
		{
			'key1' => 1,
			'key2' => 3,
		},
		expected_default =>
		{
			'key2' =>
			{
				'new' => 3,
				'old' => 2
			},
		},
	},
	{
		name             => 'diff() numbers with a different format.',
		old              => '1',
		new              => '1.00',
		expected_default => undef,
		expected_eq      =>
		{
			old => '1',
			new => '1.00',
		},
		expected_custom  =>
		{
			old => '1',
			new => '1.00',
		},
	},
	{
		name             => 'diff() on matching scalars with a different case.',
		old              => 'a',
		new              => 'A',
		expected_default =>
		{
			old => 'a',
			new => 'A',
		},
		expected_eq      =>
		{
			old => 'a',
			new => 'A',
		},
		expected_custom  => undef,
	},
	{
		name             => 'diff() with the first structure being undef.',
		old              => undef,
		new              => {},
		expected_default =>
		{
			old => undef,
			new => {},
		},
	},
	{
		name             => 'diff() with the second structure being undef.',
		old              => {},
		new              => undef,
		expected_default =>
		{
			old => {},
			new => undef,
		},
	},
	{
		name             => 'diff() with both structures being undef.',
		old              => undef,
		new              => undef,
		expected_default => undef,
	},
];

# Comparison function to use in each case.
my $comparison_functions =
{
	'default' => undef,
	'eq'      => 'eq',
	# Custom comparison function (case-insensitive 'eq').
	'custom'  => sub
	{
		my ( $variable_1, $variable_2 ) = @_;

		return lc( $variable_1 ) eq lc( $variable_2 );
	},
};

# Plan tests.
plan( tests => scalar( keys %$comparison_functions ) + 1 );

# Make sure the diff_structures() function exists.
can_ok(
	'Audit::DBI::Utils',
	'diff_structures',
);

# Run tests.
foreach my $comparison_function ( keys %$comparison_functions )
{
	subtest(
		"Compare using function '$comparison_function'.",
		sub
		{
			plan( tests => scalar ( @$tests ) );

			foreach my $test ( @$tests )
			{
				my $expected = exists( $test->{ 'expected_' . $comparison_function } )
					? $test->{ 'expected_' . $comparison_function }
					: $test->{ 'expected_default' };

				is_deeply(
					Audit::DBI::Utils::diff_structures(
						$test->{'old'},
						$test->{'new'},
						comparison_function => $comparison_functions->{ $comparison_function },
					),
					$expected,
					$test->{'name'},
				) || diag(
					'Old structure: ' . Dumper( $test->{'old'} ) . "\n" .
					'New structure: ' . Dumper( $test->{'new'} ) . "\n" .
					'Expected: ' . Dumper( $expected )
				);
			}
		},
	);
}
