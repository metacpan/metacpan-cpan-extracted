#!perl -T

=head1 PURPOSE

Test retrieving objects by non-unique field via retrieve_list(), with different
cache options.

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

# Tests.
my $tests =
[
	{
		skip_cache           => undef,
		second_retrieve_list =>
		{
			list_cache_used   => 1,
			object_cache_used => 1,
		},
	},
	{
		skip_cache           => 0,
		second_retrieve_list =>
		{
			list_cache_used   => 1,
			object_cache_used => 1,
		},
	},
	{
		skip_cache           => 1,
		second_retrieve_list =>
		{
			list_cache_used   => 0,
			object_cache_used => 0,
		},
	},
];

plan( tests => scalar( @$tests ) );

# Run tests.
my $count = 0;
foreach my $test ( @$tests )
{
	$count++;
	my $skip_cache = $test->{'skip_cache'};

	subtest(
		'Test with skip_cache=' . ( $skip_cache // 'undef' ). '.',
		sub
		{
			plan( tests => 10 );

			# Insert row.
			ok(
				defined(
					my $insert_test = DBIx::NinjaORM::Test->new()
				),
				'Create DBIx::NinjaORM::Test object.',
			);

			my $value = 'value_by_non_unique_field_' . $count . '_' . time();
			lives_ok(
				sub
				{
					$insert_test->insert(
						{
							name  => 'by_non_unique_field_' . $count . '_' . time(),
							value => $value,
						}
					);
				},
				'Insert new row.',
			);

			# Retrieve the corresponding object for the first time. It obviously
			# can't/shouldn't be in the cache at this stage, since it was just
			# inserted.
			ok(
				my $tests1 = DBIx::NinjaORM::Test->retrieve_list(
					{
						value => $value,
					},
					skip_cache => $skip_cache,
				),
				'Retrieve rows by ID.',
			);

			is(
				scalar( @$tests1 ),
				1,
				'Found one row.',
			);

			my $test1 = $tests1->[0];

			is(
				$test1->{'_debug'}->{'list_cache_used'},
				0,
				'The list cache is not used.',
			) || diag( explain( $test1->{'_debug'} ) );

			is(
				$test1->{'_debug'}->{'object_cache_used'},
				0,
				'The object cache is not used.',
			) || diag( explain( $test1->{'_debug'} ) );

			# Retrieve the corresponding object a second time. If cache options are
			# set accordingly and we're not explicitely skipping the cache, we should
			# have it in the cache.
			ok(
				my $tests2 = DBIx::NinjaORM::Test->retrieve_list(
					{
						value => $value,
					},
					skip_cache => $skip_cache,
				),
				'Retrieve rows by ID.',
			);

			is(
				scalar( @$tests2 ),
				1,
				'Found one row.',
			);

			my $test2 = $tests2->[0];

			my $expected_list_cache = $test->{'second_retrieve_list'}->{'list_cache_used'};
			is(
				$test2->{'_debug'}->{'list_cache_used'},
				$expected_list_cache,
				'The list cache is ' . ( $expected_list_cache ? 'used' : 'not used' ) . '.',
			) || diag( explain( $test2->{'_debug'} ) );

			my $expected_object_cache = $test->{'second_retrieve_list'}->{'object_cache_used'};
			is(
				$test2->{'_debug'}->{'object_cache_used'},
				$expected_object_cache,
				'The object cache is ' . ( $expected_object_cache ? 'used' : 'not used' ) . '.',
			) || diag( explain( $test2->{'_debug'} ) );
		}
	);
}


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
