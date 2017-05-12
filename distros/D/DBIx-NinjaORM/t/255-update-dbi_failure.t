#!perl -T

=head1 PURPOSE

Test that errors thrown by DBI when trying to update a row via
DBIx::NinjaORM->update() are caught and propagated properly.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;
use Test::Type;
use TestSubclass::TestTable;


# Insert a test object.
my $object;
subtest(
	'Create test object and insert the corresponding test row.',
	sub
	{
		ok(
			$object = TestSubclass::TestTable->new(),
			'Create new object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name => 'test_update_failure_' . time(),
					},
				);
			},
			'Insert succeeds.',
		);
	}
);

# Re-bless the database connection as a DBI::db::Test object, which is the
# same as DBI::db except that it overrides prepare() to make it die.
my $dbh = $object->get_info('default_dbh');
bless( $dbh, 'DBI::db::Test' );

throws_ok(
	sub
	{
		$object->update(
			{
				name => 'test_update_failure_' . time(),
			}
		);
	},
	qr/\A\QUpdate failed: died in prepare()\E/,
	'Caught update failure.',
);


# Subclass DBI::db and override prepare() to make it die.
# This is what allows testing that errors thrown by DBI are properly handled
# by DBIx::NinjaORM.
package DBI::db::Test;

use base 'DBI::db';

sub prepare
{
	die 'died in prepare()';
}

1;
