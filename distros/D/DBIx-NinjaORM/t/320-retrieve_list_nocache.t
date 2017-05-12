#!perl -T

=head1 PURPOSE

Test retrieve_list_nocache(), which is how we turn SELECTs into objects without
any caching involved.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;
use Test::Type;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'retrieve_list_nocache',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'retrieve_list_nocache',
);

throws_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{
				value => 'value',
			},
		);
	},
	qr/\QThe filtering criteria 'value' passed to DBIx::NinjaORM->retrieve_list() via DBIx::NinjaORM::Test->retrieve_list() is not handled by the superclass\E/,
	'Detect fields that are not listed as allowing filtering.',
);

throws_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{},
		);
	},
	qr/At least one argument must be passed/,
	'Require at least one filtering criteria by default.',
);

throws_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{},
			allow_all => 0,
		);
	},
	qr/At least one argument must be passed/,
	'Require at least one filtering criteria unless allow_all=1.',
);

throws_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{
				name => undef,
			},
			allow_all => 0,
		);
	},
	qr/At least one argument must be passed/,
	'Require at least one filtering criteria unless allow_all=1 (ignore undef criteria).',
);

throws_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{
				name => [],
			},
			allow_all => 0,
		);
	},
	qr/At least one argument must be passed/,
	'Require at least one filtering criteria unless allow_all=1 (ignore [] criteria).',
);

lives_ok(
	sub
	{
		DBIx::NinjaORM::Test->retrieve_list_nocache(
			{},
			allow_all => 1,
		);
	},
	'No filtering criteria works with allow_all=1.',
);


# Test subclass.
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
			'table_name'       => 'tests',
			'primary_key_name' => 'test_id',
			'default_dbh'      => LocalTest::get_database_handle(),
			'filtering_fields' => [ 'name' ],
		}
	);

	return $info;
}

1;
