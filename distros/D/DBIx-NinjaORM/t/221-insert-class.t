#!perl -T

=head1 PURPOSE

Test inserting rows without an object, by using the insert() method directly on
a class.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use TestSubclass::TestTable;


my $dbh = LocalTest::ok_database_handle();

ok(
	defined(
		my $name = "test_" . time()
	),
	'Create test field name.',
);

# Insert directly from the class, with $class->insert() instead
# of $object->insert().
lives_ok(
	sub
	{
		TestSubclass::TestTable->insert(
			{
				name  => $name,
				value => 1,
			}
		)
	},
	'Insert a test record using the class name.',
);

# Verify that the insert worked.
my $row;
lives_ok(
	sub
	{
		$row = $dbh->selectrow_hashref(
			q|
				SELECT *
				FROM tests
				WHERE name = ?
			|,
			{},
			$name,
		);

		die 'No row'
			if !defined( $row );
	},
	'Retrieve the inserted row',
);

is(
	$row->{'value'},
	1,
	'The row was properly inserted.',
);
