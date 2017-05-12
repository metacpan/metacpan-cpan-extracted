#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::SQLite::Deploy' );
}

diag( "Testing DBIx::SQLite::Deploy $DBIx::SQLite::Deploy::VERSION, Perl $], $^X" );
