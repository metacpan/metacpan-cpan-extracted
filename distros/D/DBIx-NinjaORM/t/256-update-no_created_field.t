#!perl -T

=head1 PURPOSE

Test updating rows when the table doesn't have a 'created' field.

=cut

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new object.',
);

my $name = 'test_update_nocreated_' . time();
lives_ok(
	sub
	{
		$object->insert(
			{
				name  => $name,
				value => 1,
			}
		)
	},
	'Insert succeeds.',
);

lives_ok(
	sub
	{
		$object->update(
			{
				value => 2,
			}
		)
	},
	'Update succeeds.',
);

ok(
	!exists( $object->{'created'} ),
	'The object does not have a created field.',
);


# Test subclass with enough information to successfully insert rows, and
# 'has_created_field' set to 0.
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
			'table_name'        => 'no_created_tests',
			'primary_key_name'  => 'test_id',
			'has_created_field' => 0,
		}
	);

	return $info;
}

1;

