#!perl -T

=head1 PURPOSE

Verify that C<get_table_schema()> loads correctly the underlying table for a
given class.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;
use TestSubclass::TestTable;


# Make sure that get_table_schema() is supported by DBIx::NinjaORM.
can_ok(
	'DBIx::NinjaORM',
	'get_table_schema',
);
can_ok(
	'TestSubclass::TestTable',
	'get_table_schema',
);

my $table_schema;
lives_ok(
	sub
	{
		$table_schema = TestSubclass::TestTable->get_table_schema();
	},
	'Retrieve the table schema.',
);

isa_ok(
	$table_schema,
	'DBIx::NinjaORM::Schema::Table',
) || diag( explain( $table_schema ) );
