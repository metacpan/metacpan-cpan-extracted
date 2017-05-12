#!perl -T

=head1 PURPOSE

Test that insert() can insert rows on a database handle that is different
from the default database handle specified in static_class_info().

This helps support classes that have different reader/writer databases.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;


my $dbh = LocalTest::ok_database_handle();

ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new object.',
);

dies_ok(
	sub
	{
		$object->insert(
			{
				name => 'test_insert_dbh_' . time(),
			}
		)
	},
	'Insert on the default dbh fails.',
);

lives_ok(
	sub
	{
		$object->insert(
			{
				name => 'test_insert_dbh_' . time(),
			},
			dbh => $dbh,
		)
	},
	'Insert with a custom dbh succeeds.',
);


# Test subclass with an invalid 'default_dbh'. This will allow detecting
# inserts using the default class database handle, as they will fail.
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

	$info->set(
		{
			'default_dbh'      => 'invalid',
			'table_name'       => 'tests',
			'primary_key_name' => 'test_id',
		}
	);

	return $info;
}

1;
