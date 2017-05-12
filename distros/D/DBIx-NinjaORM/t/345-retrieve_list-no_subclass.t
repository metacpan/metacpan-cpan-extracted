#!/usr/local/bin/perl

=head1 PURPOSE

Make sure that retrieve_list() cannot be subclassed.

Subclassing retrieve_list() could result in infinite recursion, so
retrieve_list() should detect this and die early.

=cut

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'retrieve_list',
);

# The subclass inherits the method, so can() should detect it.
can_ok(
	'DBIx::NinjaORM::Test',
	'retrieve_list',
);

throws_ok(
	sub
	{
		my $tests = DBIx::NinjaORM::Test->retrieve_list(
			{},
			allow_all => 1,
		);
	},
	qr/\QYou have subclassed retrieve_list(), which is not allowed to prevent infinite recursions\E/,
	'A direct retrieve_list() call in a subclass is forbidden.',
);

lives_ok(
	sub
	{
		my $tests = DBIx::NinjaORM::Test->retrieve_list(
			{},
			allow_all         => 1,
			allow_subclassing => 1,
		);
	},
	'A direct retrieve_list() call with allow_subclassing=1 is allowed.',
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
		}
	);

	return $info;
}

# Subclass retrieve_list(), to make sure it triggers an error.
sub retrieve_list
{
	my ( $class, @args ) = @_;
	return $class->SUPER::retrieve_list( @args );
}

1;
