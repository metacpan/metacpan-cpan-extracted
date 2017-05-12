#!perl -T

=head1 PURPOSE

Test creating a new L<DBIx::NinjaORM::Schema::Table> object.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


can_ok(
	'DBIx::NinjaORM::Schema::Table',
	'new',
);

throws_ok(
	sub
	{
		my $table_schema = DBIx::NinjaORM::Schema::Table->new();
	},
	qr/\QThe argument "name" is mandatory\E/,
	'The argument "name" is mandatory.',
);

throws_ok(
	sub
	{
		my $table_schema = DBIx::NinjaORM::Schema::Table->new(
			name => 'tests',
		);
	},
	qr/\QThe argument "dbh" is mandatory\E/,
	'The argument "dbh" is mandatory.',
);

my $table_schema;
lives_ok(
	sub
	{
		$table_schema = DBIx::NinjaORM::Schema::Table->new(
			dbh  => LocalTest::get_database_handle(),
			name => 'tests',
		);
	},
	'Instantiate a new object.',
);

isa_ok(
	$table_schema,
	'DBIx::NinjaORM::Schema::Table',
);
