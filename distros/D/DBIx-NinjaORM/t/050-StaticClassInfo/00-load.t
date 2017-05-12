#!perl -T

=head1 PURPOSE

Test that DBIx::NinjaORM::StaticClassInfo loads.

=cut

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


BEGIN
{
	use_ok( 'DBI' );
	use_ok( 'DBIx::NinjaORM::StaticClassInfo' );
}

diag( "Testing DBIx::NinjaORM::StaticClassInfo $DBIx::NinjaORM::StaticClassInfo::VERSION, Perl $], $^X" );
