#!perl -T

=head1 PURPOSE

Test that DBIx::NinjaORM::Utils loads.

=cut

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


BEGIN
{
	use_ok( 'DBI' );
	use_ok( 'DBIx::NinjaORM::Utils' );
}

diag( "Testing DBIx::NinjaORM::Utils $DBIx::NinjaORM::Utils::VERSION, Perl $], $^X" );
