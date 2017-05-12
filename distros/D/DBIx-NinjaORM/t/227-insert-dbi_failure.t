#!perl -T

=head1 PURPOSE

Test that errors thrown by DBI when trying to insert a row via
DBIx::NinjaORM->insert() are caught and propagated properly.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;
use Test::Type;


ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new object.',
);

throws_ok(
	sub
	{
		$object->insert(
			{
				name => 'test_insert_' . time(),
			}
		);
	},
	qr/\A\QInsert failed: died in do()\E/,
	'Caught insert failure.',
);


# Test subclass with enough information to insert rows.
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

	# Get a regular database connection DBI::db object, then
	# re-bless it as DBI::db::Test which overrides the do() method
	# to make it die.
	my $dbh = LocalTest::get_database_handle();
	bless( $dbh, 'DBI::db::Test' );

	# Regular setup.
	$info->set(
		{
			'default_dbh'      => $dbh,
			'table_name'       => 'tests',
			'primary_key_name' => 'test_id',
		}
	);

	return $info;
}

1;


# Subclass DBI::db and override do() to make it die.
# This is what allows testing that errors thrown by DBI are properly handled
# by DBIx::NinjaORM.
package DBI::db::Test;

use base 'DBI::db';

sub do
{
	die 'died in do()';
}

1;
