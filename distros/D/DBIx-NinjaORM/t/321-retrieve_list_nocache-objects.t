#!perl -T

=head1 PURPOSE

Verify that retrieve_list_nocache() returns proper objects.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;
use Test::Type;


my $test_name = 'test_nocache_' . time() . '_';

# Insert objects we'll use next for testing.
foreach my $count ( 1..3 )
{
	subtest(
		"Insert test object $count.",
		sub
		{
			ok(
				my $object = DBIx::NinjaORM::Test->new(),
				'Create new object.',
			);

			lives_ok(
				sub
				{
					$object->insert(
						{
							name => $test_name . $count,
						}
					);
				},
				'Insert succeeds.',
			);
		}
	);
}

# Retrieve the objects we just inserted.
my $objects;
lives_ok(
	sub
	{
		$objects = DBIx::NinjaORM::Test->retrieve_list_nocache(
			{
				name => [ map { $test_name . $_ } ( 1..3 ) ],
			}
		);
	},
	'Retrieve the objects matching the names.',
);

is(
	scalar( @$objects ),
	3,
	'Retrieved three objects.',
) || diag( explain( $objects ) );

# Make sure the objects are blessed correctly.
subtest(
	'Verify class of objects.',
	sub
	{
		plan( tests => 3 );

		foreach my $object ( @$objects )
		{
			isa_ok(
				$object,
				'DBIx::NinjaORM::Test',
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
			'table_name'       => 'tests',
			'primary_key_name' => 'test_id',
			'default_dbh'      => LocalTest::get_database_handle(),
			'filtering_fields' => [ 'name' ],
		}
	);

	return $info;
}

1;
