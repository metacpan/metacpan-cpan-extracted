#!perl -T

=head1 PURPOSE

Test retrieving objects and specifing which fields to include from the
underlying table.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;
use Data::Dumper;


LocalTest::ok_memcache();

plan( tests => 5 );

# Insert row.
my $value = 'select_fields_' . time();
subtest(
	'Insert the test object.',
	sub
	{
		plan( tests => 2 );

		ok(
			defined(
				my $object = DBIx::NinjaORM::Test->new()
			),
			'Create DBIx::NinjaORM::Test object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name  => $value,
						value => $value,
					}
				);
			},
			'Insert test',
		);
	}
);

# Retrieve the corresponding object for the first time. It obviously
# can't/shouldn't be in the cache at this stage, since it was just inserted.
subtest(
	'Retrieve the object for the first time.',
	sub
	{
		plan( tests => 7 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
				select_fields =>
				[
					'test_id',
					'value',
				],
			),
			'Retrieve rows',
		);

		is(
			scalar( @$objects ),
			1,
			'Found one row.',
		);

		my $object = $objects->[0];
		is(
			$object->{'_debug'}->{'list_cache_used'},
			0,
			'The list cache was not used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_debug'}->{'object_cache_used'},
			0,
			'The object cache was not used.',
		) || diag( explain( $object->{'_debug'} ) );
		is_deeply(
			$object->{'_selected_fields'},
			[
				'test_id',
				'value',
			],
			'The object has recorded the field names that were explicitly retrieved.',
		);
		ok(
			exists( $object->{'value'} ),
			'The explicitly selected field exists on the object.',
		);
		ok(
			!exists( $object->{'name'} ),
			'A non-selected field does not exist on the object.',
		);
	}
);

# Retrieve the corresponding object a second time. Because we explicitly
# selected a field the first time around, the object cache should be empty (so
# we won't see the object as coming from it), but the list cache should be used.
subtest(
	'Retrieve the object for the second time.',
	sub
	{
		plan( tests => 7 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
				select_fields =>
				[
					'test_id',
					'value',
				],
			),
			'Retrieve rows',
		);

		is(
			scalar( @$objects ),
			1,
			'Found one row.',
		);

		my $object = $objects->[0];
		is(
			$object->{'_debug'}->{'list_cache_used'},
			1,
			'The list cache was used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_debug'}->{'object_cache_used'},
			0,
			'The object cache was not used.',
		) || diag( explain( $object->{'_debug'} ) );
		is_deeply(
			$object->{'_selected_fields'},
			[
				'test_id',
				'value',
			],
			'The object has recorded the list of field names that were explicitly retrieved.',
		) || diag( explain( $object ) );
		ok(
			exists( $object->{'value'} ),
			'The explicitly selected field exists on the object.',
		);
		ok(
			!exists( $object->{'name'} ),
			'A field that was not explicitly selected does not exist on the object.',
		);
	}
);

# Retrieve the full object. This will populate the object cache.
subtest(
	'Retrieve the object with all the fields.',
	sub
	{
		plan( tests => 6 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
			),
			'Retrieve rows',
		);

		is(
			scalar( @$objects ),
			1,
			'Found one row.',
		);

		my $object = $objects->[0];
		is(
			$object->{'_debug'}->{'list_cache_used'},
			1,
			'The list cache was used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_debug'}->{'object_cache_used'},
			0,
			'The object cache was not used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_selected_fields'},
			undef,
			'The object has not recorded any explicitly selected field names.',
		);
		is(
			$object->{'value'},
			$value,
			'The value field exists on the object.',
		);
	}
);

# Retrieve the corresponding object a third time. Because we just retrieved the
# full object, we should see the object as coming from the cache this time, even
# if we asked for fields to be explicitly selected.
subtest(
	'Retrieve the object for the third time.',
	sub
	{
		plan( tests => 6 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
				select_fields =>
				[
					'test_id',
					'value',
				],
			),
			'Retrieve rows',
		);

		is(
			scalar( @$objects ),
			1,
			'Found one row.',
		);

		my $object = $objects->[0];
		is(
			$object->{'_debug'}->{'list_cache_used'},
			1,
			'The list cache was used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_debug'}->{'object_cache_used'},
			1,
			'The object cache was used.',
		) || diag( explain( $object->{'_debug'} ) );
		is(
			$object->{'_selected_fields'},
			undef,
			'The object has not recorded a list of fields to select explicitly.',
		);
		is(
			$object->{'value'},
			$value,
			'The value field exists on the object.',
		);
	}
);


# Test subclass with enough information to insert rows properly, and with both
# 'object_cache_time' and 'list_cache_time' set.
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
			default_dbh       => LocalTest::get_database_handle(),
			table_name        => 'tests',
			primary_key_name  => 'test_id',
			filtering_fields  => [ 'value' ],
			object_cache_time => 3,
			list_cache_time   => 3,
			memcache          => LocalTest::get_memcache(),
		}
	);

	return $info;
}

1;
