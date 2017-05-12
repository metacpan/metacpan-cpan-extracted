#!perl -T

=head1 PURPOSE

Test the C<get_name()> method on L<DBIx::NinjaORM::Schema::Table> objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


can_ok(
	'DBIx::NinjaORM::Schema::Table',
	'get_name',
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

is(
	$table_schema->get_name(),
	'tests',
	'get_name() returns the value passed to the constructor.',
);
