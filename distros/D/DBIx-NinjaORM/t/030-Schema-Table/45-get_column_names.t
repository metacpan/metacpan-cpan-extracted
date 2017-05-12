#!perl -T

=head1 PURPOSE

Test the C<get_column_names()> method on L<DBIx::NinjaORM::Schema::Table>
objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM::Schema::Table;
use LocalTest;
use Test::Deep;
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

my $column_names;
lives_ok(
	sub
	{
		$column_names = $table_schema->get_column_names();
	},
	'Retrieve the column names.',
);

is_deeply(
	$column_names,
	[
		'test_id',
		'name',
		'value',
		'account_id',
		'created',
		'modified'
	],
	'The column names are correct.',
) || diag( explain( $column_names ) );
