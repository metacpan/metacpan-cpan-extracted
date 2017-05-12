#!perl -T

=head1 PURPOSE

Test the C<get_dbh()> method on L<DBIx::NinjaORM::Schema::Table> objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'DBIx::NinjaORM::Schema::Table',
	'get_name',
);

my $dbh = LocalTest::ok_database_handle();

ok(
	defined(
		my $table_schema = DBIx::NinjaORM::Schema::Table->new(
			dbh  => $dbh,
			name => 'tests',
		)
	),
	'Instantiate a new object.',
);

is(
	Scalar::Util::refaddr( $table_schema->get_dbh() ),
	Scalar::Util::refaddr( $dbh ),
	'get_name() returns the value passed to the constructor.',
);
