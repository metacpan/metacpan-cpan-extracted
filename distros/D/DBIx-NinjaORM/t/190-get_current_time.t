#!perl -T

=head1 PURPOSE

Test retrieving the current time.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use TestSubclass::TestTable;


# Make sure the method exists in DBIx::NinjaORM itself.
can_ok(
	'DBIx::NinjaORM',
	'get_current_time',
);

# Make sure the method is inherited by the subclasses.
can_ok(
	'TestSubclass::TestTable',
	'get_current_time',
);

my $time;
lives_ok(
	sub
	{
		$time = DBIx::NinjaORM->get_current_time();
	},
	'Call get_current_time().',
);

ok(
	time() - $time < 5,
	'The time returned matches the current time.',
) || diag( explain( $time ) );
