#!/usr/local/bin/perl

=head1 PURPOSE

Test the pagination feature in retrieve_list().

=cut

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;


# Use time to make the test records unique, in case we need to run this test file
# more than one time during development.
my $time = time();

# Insert 15 rows that we'll use exclusively for testing pagination.
subtest(
	'Insert test rows.',
	sub
	{
		plan( tests => 25 );

		foreach my $i ( 1 .. 25 )
		{
			my $test = DBIx::NinjaORM::Test->new();
			lives_ok(
				sub
				{
					$test->insert(
						{
							name => "pagination_${time}_" . sprintf( '%02d', $i ),
						}
					);
				},
				"Insert row $i.",
			);
		}
	}
);

my $tests =
[
	# 6 objects total, but pages of 5. This tests that the boundary of the
	# page is correctly calculated.
	{
		name     => 'Retrieve page 1 of 2 out of 6.',
		input    =>
		[
			{
				name => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..6 ) ],
			},
			pagination =>
			{
				per_page => 5,
				page     => 1,
			},
			order_by   => 'name DESC',
		],
		expected =>
		{
			objects_count => 5,
			object_names  => [ reverse map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 2..6 ) ],
			pagination    =>
			{
				'page'        => 1,
				'page_max'    => 2,
				'per_page'    => 5,
				'total_count' => 6,
			},
		},
	},

	# Make sure that 10 objects on pages of 5 only make 2 pages.
	{
		name     => 'Retrieve page 2 of 2 out of 10.',
		input    =>
		[
			{
				name => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..10 ) ],
			},
			pagination =>
			{
				per_page => 5,
				page     => 2,
			},
			order_by   => 'name ASC',
		],
		expected =>
		{
			objects_count => 5,
			object_names  => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 6..10 ) ],
			pagination    =>
			{
				'page'        => 2,
				'page_max'    => 2,
				'per_page'    => 5,
				'total_count' => 10,
			},
		},
	},

	# If no page is specified, this should default to page 1.
	{
		name     => 'Retrieve default page.',
		input    =>
		[
			{
				name => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..10 ) ],
			},
			pagination =>
			{
				per_page => 5,
			},
			order_by   => 'name ASC',
		],
		expected =>
		{
			objects_count => 5,
			object_names  => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..5 ) ],
			pagination    =>
			{
				'page'        => 1,
				'page_max'    => 2,
				'per_page'    => 5,
				'total_count' => 10,
			},
		},
	},

	# If no number of results per page is specified, this should default to 20.
	{
		name     => 'Retrieve default page count.',
		input    =>
		[
			{
				name => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..10 ) ],
			},
			pagination =>
			{
				page => 1,
			},
			order_by   => 'name ASC',
		],
		expected =>
		{
			objects_count => 10,
			object_names  => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..10 ) ],
			pagination    =>
			{
				'page'        => 1,
				'page_max'    => 1,
				'per_page'    => 20,
				'total_count' => 10,
			},
		},
	},

	# We allow "pagination => 1" as a shortcut for the default pagination
	# settings.
	{
		name     => 'Verify that the pagination=1 shortcut for default pagination settings is available.',
		input    =>
		[
			{
				name => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..25 ) ],
			},
			pagination => 1,
			order_by   => 'name ASC',
		],
		expected =>
		{
			objects_count => 20,
			object_names  => [ map { "pagination_${time}_" . sprintf( '%02d', $_ ) } ( 1..20 ) ],
			pagination    =>
			{
				'page'        => 1,
				'page_max'    => 2,
				'per_page'    => 20,
				'total_count' => 25,
			},
		},
	},
];

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 4 );

			my ( $objects, $pagination );
			lives_ok(
				sub
				{
					( $objects, $pagination ) = DBIx::NinjaORM::Test->retrieve_list(
						@{ $test->{'input'} }
					);
				},
				'Retrieve objects and pagination information.',
			);

			is(
				scalar( @$objects ),
				$test->{'expected'}->{'objects_count'},
				'Retrieved the correct number of objects.',
			);

			my $expected_pagination = $test->{'expected'}->{'pagination'};
			is_deeply(
				$pagination,
				$expected_pagination,
				'The pagination information is correct.',
			) || diag( explain( [ "Got:", $pagination, "Expected:", $expected_pagination ] ) );

			my $expected_names = $test->{'expected'}->{'object_names'};
			my $names = [ map { $_->get('name') } @$objects ];
			is_deeply(
				$names,
				$expected_names,
				'The objects were returned in the expected order.',
			) || diag( explain( [ "Got:", $names, "Expected:", $expected_names ] ) );
		}
	);
}


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
			filtering_fields  => [ 'name' ],
		}
	);

	return $info;
}

1;

