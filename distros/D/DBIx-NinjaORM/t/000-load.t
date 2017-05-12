#!perl -T

=head1 PURPOSE

Test that DBIx::NinjaORM loads.

=cut

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


BEGIN
{
	use_ok( 'DBI' );
	use_ok( 'DBIx::NinjaORM' );
}

diag( "Testing DBIx::NinjaORM $DBIx::NinjaORM::VERSION, Perl $], $^X" );
