#!perl -T

=head1 PURPOSE

130-assert_dbh.t tests passing standard DBI::db objects, but we also support
passing a coderef that gets evaluated only when a database handle is actually
needed. This test suite is focused on the latter.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


# Retrieve test database handle.
ok(
	defined(
		my $test_dbh = LocalTest::get_database_handle()
	),
	'Retrieve test database handle.',
);

# Verify that when no argument is passed to assert_dbh(), the default is used.
subtest(
	'By default, assert_dbh() returns "default_dbh".',
	sub
	{
		plan( tests => 2 );

		my $dbh;
		lives_ok(
			sub
			{
				$dbh = DBIx::NinjaORM::TestDefault->assert_dbh();
			},
			'Retrieve database handle.',
		);

		isa_ok(
			$dbh,
			'DBI::db',
			'Retrieved default handle',
		);
	}
);

# Verify that when a valid DBI::db argument is passed to assert_dbh(), it is used
# in lieu of the default.
subtest(
	'assert_dbh( [valid database handle] ) returns that database handle.',
	sub
	{
		plan( tests => 2 );

		my $dbh;
		lives_ok(
			sub
			{
				$dbh = DBIx::NinjaORM::TestNoDefault->assert_dbh(
					sub
					{
						return $test_dbh;
					}
				);
			},
			'Retrieve database handle.',
		);

		isa_ok(
			$dbh,
			'DBI::db',
			'Retrieved test handle',
		);
	}
);


# Test subclass with a valid default_dbh value.
package DBIx::NinjaORM::TestDefault;

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->{'default_dbh'} = sub
	{
		return LocalTest::get_database_handle();
	};

	return $info;
}

1;


# Test subclass with an invalid default_dbh value.
package DBIx::NinjaORM::TestNoDefault;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			# Not a DBI::db object.
			'default_dbh' => "INVALID",
		}
	);

	return $info;
}

1;

