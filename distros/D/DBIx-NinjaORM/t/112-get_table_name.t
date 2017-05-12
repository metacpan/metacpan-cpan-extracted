#!perl -T

=head1 PURPOSE

Make sure that get_table_name() returns the table name specified in the static
class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Warn;
use TestSubclass::Accessors;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get_table_name',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_table_name',
);

# Tests.
my $tests =
[
	{
		name => 'Test calling get_table_name() on the class',
		ref  => 'TestSubclass::Accessors',
	},
	{
		name => 'Test calling get_table_name() on an object',
		ref  => bless( {}, 'TestSubclass::Accessors' ),
	},
];

# Run tests.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 2 );

			my $table_name;
			warning_like(
				sub
				{
					$table_name = $test->{'ref'}->get_table_name();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$table_name,
				'TEST_TABLE_NAME',
				'get_table_name() returns the value set up in static_class_info().',
			);
		}
	);
}
