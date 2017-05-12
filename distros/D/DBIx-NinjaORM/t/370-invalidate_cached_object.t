#!perl -T

=head1 PURPOSE

Test the invalidate_cached_object() method.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;
use Test::Type;


# We must have memcache enabled for this test.
LocalTest::ok_memcache();
plan( tests => 10 );

# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'invalidate_cached_object',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'invalidate_cached_object',
);

# Insert an object we'll use for tests here.
my $object_id;
subtest(
	'Insert a new object.',
	sub
	{
		plan( tests => 2 );

		ok(
			defined(
				my $object = DBIx::NinjaORM::Test->new()
			),
			'Create new object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name => 'test_invalidate_cached_object_' . time(),
					}
				)
			},
			'Insert succeeds.',
		);

		$object_id = $object->id();
	}
);

# Retrieve the object.
ok(
	defined(
		my $object = DBIx::NinjaORM::Test->new(
			{ id => $object_id },
		)
	),
	'Retrieve the object previously inserted.',
);

# The object cache shouldn't have been used, since it's the first time we're
# loading the object.
is(
	$object->{'_debug'}->{'object_cache_used'},
	0,
	'The object cache was not used.',
) || diag( explain( $object ) );

# Retrieve the object again.
ok(
	defined(
		$object = DBIx::NinjaORM::Test->new(
			{ id => $object_id },
		)
	),
	'Retrieve the object again.',
);

# The object cache should have been used, since it's the second time we're
# loading the object.
is(
	$object->{'_debug'}->{'object_cache_used'},
	1,
	'The object cache was used.',
) || diag( explain( $object ) );

# Expire the object from the cache.
lives_ok(
	sub
	{
		$object->invalidate_cached_object();
	},
	'Invalidate the object in the cache.',
);

# Retrieve the object.
ok(
	defined(
		$object = DBIx::NinjaORM::Test->new(
			{ id => $object_id },
		)
	),
	'Retrieve the object again.',
);

# The object cache shouldn't have been used, since it's the first time we're
# loading the object.
is(
	$object->{'_debug'}->{'object_cache_used'},
	0,
	'The object cache was not used.',
) || diag( explain( $object ) );


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

	$info->set(
		{
			default_dbh       => LocalTest::get_database_handle(),
			table_name        => 'tests',
			primary_key_name  => 'test_id',
			object_cache_time => 10,
			memcache          => LocalTest::get_memcache(),
		}
	);

	return $info;
}

1;

