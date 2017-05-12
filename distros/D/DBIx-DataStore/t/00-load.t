#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::DataStore' );
}

diag( "Testing DBIx::DataStore $DBIx::DataStore::VERSION, Perl $], $^X" );
