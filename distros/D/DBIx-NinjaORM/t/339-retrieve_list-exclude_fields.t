#!perl -T

=head1 PURPOSE

Test retrieving objects and excluding some fields from the main underlying
table.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


LocalTest::ok_memcache();

plan( tests => 5 );

# Insert row.
my $value = 'exclude_fields_' . time();
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
		plan( tests => 6 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
				exclude_fields =>
				[
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
			$object->{'_excluded_fields'},
			[
				'value',
			],
			'The object has recorded the excluded field names.',
		);
		ok(
			!exists( $object->{'value'} ),
			'The excluded field does not exist as on the object.',
		);
	}
);

# Retrieve the corresponding object a second time. Because we excluded a field
# the first time around, the object cache should be empty (so we won't see the
# object as coming from it), but the list cache should be used.
subtest(
	'Retrieve the object for the second time.',
	sub
	{
		plan( tests => 6 );

		ok(
			my $objects = DBIx::NinjaORM::Test->retrieve_list(
				{
					value => $value,
				},
				exclude_fields =>
				[
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
			$object->{'_excluded_fields'},
			[
				'value',
			],
			'The object has recorded the excluded field names.',
		) || diag( explain( $object ) );
		ok(
			!exists( $object->{'value'} ),
			'The excluded field does not exist as on the object.',
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
			$object->{'_excluded_fields'},
			undef,
			'The object has not recorded any excluded field names.',
		);
		is(
			$object->{'value'},
			$value,
			'The value field exists on the object.',
		);
	}
);

# Retrieve the corresponding object a third time. Because we just retrieved the full object, we should see the object as coming from the cache this time, even if we asked for fields to be excluded.
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
				exclude_fields =>
				[
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
			$object->{'_excluded_fields'},
			undef,
			'The object has not recorded any excluded field names.',
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
