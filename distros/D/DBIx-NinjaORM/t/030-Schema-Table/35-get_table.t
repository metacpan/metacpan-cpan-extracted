#!perl -T

=head1 PURPOSE

Test the C<get_table()> method on L<DBIx::NinjaORM::Schema::Table> objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'DBIx::NinjaORM::Schema::Table',
	'get_table',
);

ok(
	defined(
		my $table_schema = DBIx::NinjaORM::Schema::Table->new(
			dbh  => LocalTest::get_database_handle(),
			name => 'tests',
		)
	),
	'Instantiate a new object.',
);

my $table;
lives_ok(
	sub
	{
		$table = $table_schema->get_table();
	},
	'Retrieve the DBIx::Inspector::Table object.',
);

isa_ok(
	$table,
	'DBIx::Inspector::Table',
);
