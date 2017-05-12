#!/usr/local/bin/perl

=head1 PURPOSE

Test retrieving objects via retrieve_list(), with different some objects being
cached and some others not being cached.

This is to make sure that the end result is properly sorted, even if we're
getting objects from two different sources (the memcache object cache and
the database).

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


# These tests require memcache to be running.
LocalTest::ok_memcache();
plan( tests => 13 );

# Insert test records.
my $time = time();
subtest(
	'Insert test records.',
	sub
	{
		plan( tests => 10 );

		foreach my $i ( 1..10 )
		{
			lives_ok(
				sub
				{
					my $test = DBIx::NinjaORM::Test->new();
					$test->insert(
						{
							name  => 'partial_cache_' . $i . '_' . $time,
							value => "$time-$i",
						}
					);
				},
				"Insert test row $i.",
			);
		}
	}
);

# Get all the records in the object cache.
note( "Let's get rows 1-6 in the object cache." );
ok(
	defined(
		my $preload_tests = DBIx::NinjaORM::Test->retrieve_list(
			{
				value =>
				[
					"$time-1",
					"$time-2",
					"$time-3",
					"$time-4",
					"$time-5",
					"$time-6",
				],
			},
			order_by => 'tests.name ASC',
		)
	),
	'Retrieve rows 1-6.',
);

# Make sure we're not using the list cache here.
subtest(
	'Verify that the list cache was not used to translate parameters into IDs.',
	sub
	{
		foreach my $test ( @$preload_tests )
		{
			is(
				$test->{'_debug'}->{'list_cache_used'},
				0,
				'The object "' . $test->get('name') . '" did not through the list cache.',
			);
		}
	}
);

# Expire objects 2, 4, and 6.
my $objects_by_value =
{
	map { $_->get('value') => $_ } @$preload_tests
};
foreach my $i ( 2, 4, 6 )
{
	subtest(
		"Expire object cache for row $i.",
		sub
		{
			plan( tests => 3 );

			ok(
				defined(
					my $object = $objects_by_value->{ "$time-$i" }
				),
				"Get object for value=$time-$i.",
			);

			ok(
				defined(
					my $object_cache_key = $object->get_object_cache_key()
				),
				'Retrieve the object cache key.',
			);

			ok(
				DBIx::NinjaORM::Test->delete_cache( key => $object_cache_key ),
				'Expire the object cache',
			);
		}
	);
}

# Let's get rows 1-6 again, the list cache is still valid but if things go well,
# 2, 4, and 6 are not going to be in the object cache anymore.;
ok(
	defined(
		my $tests = DBIx::NinjaORM::Test->retrieve_list(
			{
				value    =>
				[
					"$time-1",
					"$time-2",
					"$time-3",
					"$time-4",
					"$time-5",
					"$time-6",
				],
			},
			order_by => 'tests.name ASC',
		)
	),
	'Retrieve rows 1-6.',
);

# Since retrieve_list_cache() is pulling objects both from memcache and from
# the database, the sort is not being performed by the database. We need to
# make sure here that the order of the objects in the list cache is respected.
subtest(
	'Verify the order in which the objects were returned.',
	sub
	{
		plan( tests => 6 );

		my $i = 0;
		foreach my $test ( @$tests )
		{
			$i++;

			is(
				$test->get('value'),
				"$time-$i",
				"Retrieve object $i.",
			);
		}
	}
);

subtest(
	'Verify that the list cache was used to translate parameters into IDs.',
	sub
	{
		foreach my $test ( @$tests )
		{
			is(
				$test->{'_debug'}->{'list_cache_used'},
				1,
				'The object >' . $test->get('name') . '< went through the list cache.',
			);
		}
	}
);

subtest(
	'Verify that cached objects were retrieved from the cache, and that we made a query for the others.',
	sub
	{
		my $expected_object_cache_use =
		{
			"partial_cache_1_$time" => 1,
			"partial_cache_2_$time" => 0,
			"partial_cache_3_$time" => 1,
			"partial_cache_4_$time" => 0,
			"partial_cache_5_$time" => 1,
			"partial_cache_6_$time" => 0,
		};

		foreach my $test ( @$tests )
		{
			if ( $expected_object_cache_use->{ $test->get('name') } )
			{
				is(
					$test->{'_debug'}->{'object_cache_used'},
					1,
					'The object >' . $test->get('name') . '< was retrieved from the object cache.',
				);
			}
			else
			{
				is(
					$test->{'_debug'}->{'object_cache_used'},
					0,
					'The object >' . $test->get('name') . '< was retrieved directly from the database.',
				);
			}
		}
	}
);

ok(
	defined(
		my $tests2 = DBIx::NinjaORM::Test->retrieve_list(
			{
				value =>
				[
					"$time-1",
					"$time-2",
					"$time-3",
					"$time-4",
					"$time-5",
					"$time-6",
				],
			},
			order_by => 'tests.name ASC',
		)
	),
	'Retrieve rows 1-6.',
);

subtest(
	'Verify that the list cache was used to translate parameters into IDs.',
	sub
	{
		foreach my $test ( @$tests2 )
		{
			is(
				$test->{'_debug'}->{'list_cache_used'},
				1,
				'The object >' . $test->get('name') . '< went through the list cache.',
			);
		}
	}
);

subtest(
	'Verify that cached objects were retrieved from the cache.',
	sub
	{
		foreach my $test ( @$tests2 )
		{
			is(
				$test->{'_debug'}->{'object_cache_used'},
				1,
				'The object >' . $test->get('name') . '< was retrieved from the object cache.',
			);
		}
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
			default_dbh       => LocalTest::get_database_handle(),
			table_name        => 'tests',
			primary_key_name  => 'test_id',
			filtering_fields  => [ 'value' ],
			object_cache_time => 100,
			list_cache_time   => 100,
			memcache          => LocalTest::get_memcache(),
		}
	);

	return $info;
}

1;
