#!perl -T

=head1 PURPOSE

Test the C<get_columns()> method on L<DBIx::NinjaORM::Schema::Table> objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;


can_ok(
	'DBIx::NinjaORM::Schema::Table',
	'get_columns',
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

my $columns;
lives_ok(
	sub
	{
		$columns = $table_schema->get_columns();
	},
	'Retrieve the columns.',
);

ok_arrayref(
	$columns,
	name                  => 'The columns',
	allow_empty           => 0,
	element_validate_type => sub
	{
		return Data::Validate::Type::is_instance(
			$_[0],
			class => 'DBIx::Inspector::Column',
		);
	},
);
