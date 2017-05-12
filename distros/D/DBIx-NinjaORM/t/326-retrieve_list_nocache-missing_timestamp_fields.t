#!perl -T

=head1 PURPOSE

Verify that retrieve_list_nocache() can pull objects without a created field.

=cut

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests =
[
	{
		name => 'Table without a "created" field.',
		class => 'DBIx::NinjaORM::TestNoCreated',
	},
	{
		name => 'Table without a "modified" field.',
		class => 'DBIx::NinjaORM::TestNoModified',
	},
];

plan( tests => 2 );

foreach my $test ( @$tests )
{
	my $class = $test->{'class'};

	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 3 );

			my $test_name = 'test_rl_nofield' . time();

			# Insert the object we'll use next for testing.
			subtest(
				"Insert test object.",
				sub
				{
					plan( tests => 2 );

					ok(
						my $object = $class->new(),
						'Create new object.',
					);

					lives_ok(
						sub
						{
							$object->insert(
								{
									name => $test_name,
								}
							);
						},
						'Insert succeeds.',
					);
				}
			);

			# Retrieve the objects we just inserted.
			my $objects;
			lives_ok(
				sub
				{
					$objects = $class->retrieve_list_nocache(
						{
							name => $test_name,
						}
					);
				},
				'Retrieve the objects matching the names.',
			);

			SKIP:
			{
				skip(
					'retrieve_list() failed.',
					1,
				) if !defined( $objects );

				is(
					scalar( @$objects ),
					1,
					'Retrieved object.',
				) || diag( explain( $objects ) );
			}
		}
	);
}


# Test subclass with enough information to successfully insert/retrieve rows,
# and 'has_created_field' set to 0.
package DBIx::NinjaORM::TestNoCreated;

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
			'table_name'        => 'no_created_tests',
			'primary_key_name'  => 'test_id',
			'filtering_fields'  => [ 'name' ],
			'has_created_field' => 0,
		}
	);

	return $info;
}

1;


# Test subclass with enough information to successfully insert/retrieve rows,
# and 'has_modified_field' set to 0.
package DBIx::NinjaORM::TestNoModified;

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
			'default_dbh'        => LocalTest::get_database_handle(),
			'table_name'         => 'no_modified_tests',
			'primary_key_name'   => 'test_id',
			'filtering_fields'   => [ 'name' ],
			'has_modified_field' => 0,
		}
	);

	return $info;
}

1;
