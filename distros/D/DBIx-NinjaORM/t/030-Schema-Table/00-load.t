#!perl -T

=head1 PURPOSE

Test that DBIx::NinjaORM::Schema::Table loads.

=cut

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


BEGIN
{
	use_ok( 'DBI' );
	use_ok( 'DBIx::NinjaORM::Schema::Table' );
}

diag( "Testing DBIx::NinjaORM::Schema::Table $DBIx::NinjaORM::Schema::Table::VERSION, Perl $], $^X" );
