#!perl -T

=head1 PURPOSE

Test building SQL clauses from arguments that will be normally passed to
retrieve_list().

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 24;


my $dbh = LocalTest::ok_database_handle();

my $quoted_field = $dbh->quote_identifier( 'test_field' );

# Tests.
my $tests =
[
	# Operator "between".
	{
		name     => 'Test operator="between" with correct input.',
		input    =>
		{
			field    => 'test_field',
			operator => 'between',
			values   => [ 1, 2 ],
		},
		expected =>
		{
			clause => "$quoted_field BETWEEN ? AND ?",
			values => [ 1, 2 ],
		},
	},
	{
		name     => 'Test operator="between" with incorrect values.',
		input    =>
		{
			field    => 'test_field',
			operator => 'between',
			values   => 3,
		},
		expected => undef,
	},

	# Operator "not_null".
	{
		name     => 'Test operator="not_null" with correct input.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not_null',
			values   => [],
		},
		expected =>
		{
			clause => "$quoted_field IS NOT NULL",
			values => [],
		},
	},
	{
		name     => 'Test operator="not_null" with values that should be ignored.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not_null',
			values   => [ 1, 2, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field IS NOT NULL",
			values => [],
		},
	},

	# Operator "null".
	{
		name     => 'Test operator="null" with correct input.',
		input    =>
		{
			field    => 'test_field',
			operator => 'null',
			values   => [],
		},
		expected =>
		{
			clause => "$quoted_field IS NULL",
			values => [],
		},
	},
	{
		name     => 'Test operator="null" with values that should be ignored.',
		input    =>
		{
			field    => 'test_field',
			operator => 'null',
			values   => [ 1, 2, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field IS NULL",
			values => [],
		},
	},

	# Operator "=".
	{
		name     => 'Test operator="=" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => '=',
			values   => 'test_value',
		},
		expected =>
		{
			clause => "$quoted_field = ?",
			values => [ 'test_value' ],
		},
	},
	{
		name     => 'Test operator="=" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => '=',
			values   => [ 1, 'a' ],
		},
		expected =>
		{
			clause => "$quoted_field IN (?, ?)",
			values => [ 1, 'a' ],
		},
	},

	# Operator "not".
	{
		name     => 'Test operator="not" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not',
			values   => 'test_value',
		},
		expected =>
		{
			clause => "$quoted_field != ?",
			values => [ 'test_value' ],
		},
	},
	{
		name     => 'Test operator="not" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not',
			values   => [ 1, 'a' ],
		},
		expected =>
		{
			clause => "$quoted_field NOT IN (?, ?)",
			values => [ 1, 'a' ],
		},
	},

	# Operator ">".
	{
		name     => 'Test operator=">" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => '>',
			values   => 4,
		},
		expected =>
		{
			clause => "$quoted_field > ?",
			values => [ 4 ],
		},
	},
	{
		name     => 'Test operator=">" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => '>',
			values   => [ 1, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field > ?",
			values => [ 3 ],
		},
	},

	# Operator ">=".
	{
		name     => 'Test operator=">" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => '>=',
			values   => 4,
		},
		expected =>
		{
			clause => "$quoted_field >= ?",
			values => [ 4 ],
		},
	},
	{
		name     => 'Test operator=">=" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => '>=',
			values   => [ 1, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field >= ?",
			values => [ 3 ],
		},
	},

	# Operator "<".
	{
		name     => 'Test operator="<" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => '<',
			values   => 4,
		},
		expected =>
		{
			clause => "$quoted_field < ?",
			values => [ 4 ],
		},
	},
	{
		name     => 'Test operator="<" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => '<',
			values   => [ 1, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field < ?",
			values => [ 1 ],
		},
	},

	# Operator "<=".
	{
		name     => 'Test operator="<=" with values=scalar.',
		input    =>
		{
			field    => 'test_field',
			operator => '<=',
			values   => 4,
		},
		expected =>
		{
			clause => "$quoted_field <= ?",
			values => [ 4 ],
		},
	},
	{
		name     => 'Test operator="<=" with values=arrayref.',
		input    =>
		{
			field    => 'test_field',
			operator => '<=',
			values   => [ 1, 3 ],
		},
		expected =>
		{
			clause => "$quoted_field <= ?",
			values => [ 1 ],
		},
	},
	# Operator "like".
	{
		name     => 'Test operator="like" with one input value.',
		input    =>
		{
			field    => 'test_field',
			operator => 'like',
			values   => [ '1b%' ],
		},
		expected =>
		{
			clause => "$quoted_field LIKE ?",
			values => [ '1b%' ],
		},
	},
	{
		name     => 'Test operator="like" with > 1 input value.',
		input    =>
		{
			field    => 'test_field',
			operator => 'like',
			values   => [ '1b%', '1245%' ],
		},
		expected =>
		{
			clause => "$quoted_field LIKE ? OR $quoted_field LIKE ?",
			values => [ '1b%', '1245%' ],
		},
	},
	# Operator "not_like".
	{
		name     => 'Test operator="not_like" with one input value.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not_like',
			values   => [ '1b%' ],
		},
		expected =>
		{
			clause => "$quoted_field NOT LIKE ?",
			values => [ '1b%' ],
		},
	},
	{
		name     => 'Test operator="not_like" with > 1 input value.',
		input    =>
		{
			field    => 'test_field',
			operator => 'not_like',
			values   => [ '1b%', '1245%' ],
		},
		expected =>
		{
			clause => "$quoted_field NOT LIKE ? AND $quoted_field NOT LIKE ?",
			values => [ '1b%', '1245%' ],
		},
	},

];

# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'build_filtering_clause',
);

# Run tests.
foreach my $test ( @$tests )
{
	my $input = $test->{'input'};
	my $expected = $test->{'expected'};

	if ( defined( $expected ) )
	{
		subtest(
			$test->{'name'},
			sub
			{
				plan( tests => 3 );

				my ( $clause, $values );
				lives_ok(
					sub
					{
						( $clause, $values ) = DBIx::NinjaORM::Test->build_filtering_clause(
							%$input
						);
					},
					'Create the filtering clause.',
				);

				is(
					$clause,
					$expected->{'clause'},
					'The clause matches.',
				);

				is_deeply(
					$values,
					$expected->{'values'},
					'The values match.',
				) || diag( explain( 'Retrieved: ', $values, 'Expected: ', $expected->{'values'} ) );
			}
		);
	}
	else
	{
		dies_ok(
			sub
			{
				DBIx::NinjaORM::Test->build_filtering_clause(
					%$input
				);
			},
			$test->{'name'},
		);
	}
}


# Test subclass. We just need 'default_dbh' to be set up, as testing this
# method requires it to quote fields.
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
			'default_dbh' => LocalTest::get_database_handle(),
		}
	);

	return $info;
}

1;
