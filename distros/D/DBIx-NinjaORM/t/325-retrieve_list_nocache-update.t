#!perl -T

=head1 PURPOSE

Test that updates and cache in retrieve_list() do not interfere.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;


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

# Insert test row.
my $test_name = 'test_nocache_update_' . time();
my $object;
subtest(
	'Insert test row.',
	sub
	{
		plan( tests => 2 );

		ok(
			$object = DBIx::NinjaORM::Test->new(),
			'Create new object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name  => $test_name,
						value => 1,
					}
				)
			},
			'Insert succeeds.',
		);
	}
);

# Retrieve the object again, and verify the value.
my $test;
subtest(
	'Check initial value.',
	sub
	{
		plan( tests => 2 );

		ok(
			defined(
				$test = DBIx::NinjaORM::Test->new(
					{ name => $test_name },
				)
			),
			'Retrieve the object.',
		);

		is(
			$test->get('value'),
			1,
			'The value is correct.',
		);
	}
);

# Update the value on the object.
my $updated_value = 2;
ok(
	$test->update(
		{
			value => $updated_value,
		}
	),
	'Update the value.',
);

# Since there is no cache, the objects we retrieve again should have the updated value.
subtest(
	'Check updated value.',
	sub
	{
		plan( tests => 2 );

		ok(
			defined(
				my $test = DBIx::NinjaORM::Test->new(
					{ name => $test_name },
				)
			),
			'Retrieve the object.',
		);

		is(
			$test->get('value'),
			$updated_value,
			'The value on the retrieved object matches the update.',
		);
	}
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
			'default_dbh'       => LocalTest::get_database_handle(),
			'table_name'        => 'tests',
			'primary_key_name'  => 'test_id',
			'unique_fields'     => [ 'name' ],
			'list_cache_time'   => undef,
			'object_cache_time' => undef,
		}
	);

	return $info;
}

1;

