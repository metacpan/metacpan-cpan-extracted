#!perl -T

=head1 PURPOSE

Test locking the retrieved rows in subclassed retrieve_list_nocache() methods
that also perform a SQL JOIN.

To allow locking only the row(s) corresponding to the object(s) retrieved,
DBIx::NinjaORM has to perform the locking in a separate query. This test
suite is designed to test this code path.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;
use Test::Type;


# Create account.
ok(
	defined(
		my $account = DBIx::NinjaORM::Account->new()
	),
	'Create a new account object.',
);

my $test_email = 'join_and_lock@test.invalid';
lives_ok(
	sub
	{
		$account->insert(
			{
				email => $test_email,
			}
		);
	},
	'Insert the account.',
);

# Create a test object tied to the account we just inserted.
ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new test object.',
);

my $test_name = 'join_and_lock_' . time();
lives_ok(
	sub
	{
		$object->insert(
			{
				name       => $test_name,
				account_id => $account->id(),
			}
		);
	},
	'Insert the test object.',
);

# Retrieve the object corresponding to the row we just inserted.
my $objects;
lives_ok(
	sub
	{
		$objects = DBIx::NinjaORM::Test->retrieve_list_nocache(
			{
				name => $test_name,
			},
			lock => 1,
		);
	},
	'Retrieve the objects matching the name and lock the underlying row.',
);

is(
	scalar( @$objects ),
	1,
	'Retrieved one object.',
) || diag( explain( $objects ) );


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

	$info->{'default_dbh'} = LocalTest::get_database_handle();
	$info->{'table_name'} = 'tests';
	$info->{'primary_key_name'} = 'test_id';
	$info->{'filtering_fields'} = [ 'name' ];

	return $info;
}

# Subclass 'retrieve_list_nocache' to add the information about the JOIN.
sub retrieve_list_nocache
{
	my ( $class, $filters, %args ) = @_;

	return $class->SUPER::retrieve_list_nocache(
		$filters,
		%args,
		query_extensions =>
		{
			joins         =>
			q|
				LEFT JOIN accounts ON accounts.account_id = tests.account_id
			|,
			joined_fields =>
			q|
				accounts.email AS _account_email
			|,
		},
	);
}

1;


# Test subclass for accounts.
package DBIx::NinjaORM::Account;

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
			'table_name'       => 'accounts',
			'primary_key_name' => 'account_id',
			'default_dbh'      => LocalTest::get_database_handle(),
		}
	);

	return $info;
}

1;
