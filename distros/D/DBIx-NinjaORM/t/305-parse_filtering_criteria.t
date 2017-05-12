#!perl -T

=head1 PURPOSE

Test parsing arguments that are normally passed via retrieve_list(), and make sure
that it turns them into proper SQL clauses with their corresponding values.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 10;


my $dbh = LocalTest::ok_database_handle();

# Quoted field names.
my $table = $dbh->quote_identifier( 'tests' );
my $field1 = $dbh->quote_identifier( 'field1' );
my $field2 = $dbh->quote_identifier( 'field2' );

# Tests.
my $tests =
[
	# The first argument must be a hashref.
	{
		name     => 'The first argument cannot be undef.',
		input    => undef,
		expected => undef,
	},
	{
		name     => 'The first argument cannot be a scalar.',
		input    => 'test',
		expected => undef,
	},

	# Parse with one field.
	{
		name     => 'Parse with one field.',
		input    =>
		{
			'field1' => 'value1',
		},
		expected =>
		{
			clauses     =>
			[
				"$table.$field1 IN (?)",
			],
			values      =>
			[
				[ 'value1' ],
			],
			keys_passed => 1,
		},
	},

	# Parse with two fields.
	{
		name     => 'Parse with two fields.',
		input    =>
		{
			'field1' => 'value1',
			'field2' => 'value2',
		},
		expected =>
		{
			clauses     =>
			[
				"$table.$field1 IN (?)",
				"$table.$field2 IN (?)",
			],
			values      =>
			[
				[ 'value1' ],
				[ 'value2' ],
			],
			keys_passed => 1,
		},
	},

	# Parse the field's values being an arrayref.
	{
		name     => 'Parse the field\'s values being an arrayref.',
		input    =>
		{
			'field1' => [ 'value1', 2 ],
		},
		expected =>
		{
			clauses     =>
			[
				"$table.$field1 IN (?, ?)",
			],
			values      =>
			[
				[ 'value1', 2 ],
			],
			keys_passed => 1,
		},
	},

	# Parse non implicit operator.
	{
		name     => 'Parse a non-implicit operator.',
		input    =>
		{
			'field1' =>
			{
				operator => '>',
				value    => 2,
			},
		},
		expected =>
		{
			clauses     =>
			[
				"$table.$field1 > ?",
			],
			values      =>
			[
				[ 2 ],
			],
			keys_passed => 1,
		},
	},
	{
		name     => 'Parse a non-implicit operator with an arrayref of values.',
		input    =>
		{
			'field1' =>
			{
				operator => 'not',
				value    => [ 'a', 'b', 'c' ],
			},
		},
		expected =>
		{
			clauses     =>
			[
				"$table.$field1 NOT IN (?, ?, ?)",
			],
			values      =>
			[
				[ 'a', 'b', 'c' ],
			],
			keys_passed => 1,
		},
	},

	# Verify that only supported operators are accepted.
	{
		name     => 'Verify that only supported operators are accepted.',
		input    =>
		{
			'field1' =>
			{
				operator => 'invalid_operator',
				value    => 'x'
			},
		},
		expected => undef,
	},
];

# TODO: test all the custom operators to make sure they're supported.

# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'parse_filtering_criteria',
);

# Run tests.
foreach my $test ( @$tests )
{
	my $input = $test->{'input'};
	my $expected = $test->{'expected'};

	if ( defined( $expected ) )
	{
		# If we're expected a return, test the returned values.
		subtest(
			$test->{'name'},
			sub
			{
				plan( tests => 4 );

				my ( $where_clauses, $where_values, $filtering_field_keys_passed );
				lives_ok(
					sub
					{
						( $where_clauses, $where_values, $filtering_field_keys_passed ) =
							@{
								DBIx::NinjaORM::Test->parse_filtering_criteria(
									$input
								)
							};
					},
					'Parse the filtering criteria.',
				);

				is_deeply(
					$where_clauses,
					$expected->{'clauses'},
					'The clause matches.',
				) || diag( explain( 'Retrieved: ', $where_clauses, 'Expected: ', $expected->{'clauses'} ) );

				is_deeply(
					$where_values,
					$expected->{'values'},
					'The values match.',
				) || diag( explain( 'Retrieved: ', $where_values, 'Expected: ', $expected->{'values'} ) );

				is(
					$filtering_field_keys_passed,
					$expected->{'keys_passed'},
					'Detect filtering field keys passed.',
				);
			}
		);
	}
	else
	{
		# If we're not expecting a return, make sure the method dies to indicate
		# that there's a problem.
		dies_ok(
			sub
			{
				DBIx::NinjaORM::Test->parse_filtering_criteria(
					$input
				);
			},
			$test->{'name'},
		);
	}
}


# Test subclass.
package DBIx::NinjaORM::Test;

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'table_name'       => 'tests',
			'primary_key_name' => 'test_id',
			'default_dbh'      => LocalTest::get_database_handle(),
			'filtering_fields' => [ 'field1', 'field2' ],
		}
	);

	return $info;
}

1;
