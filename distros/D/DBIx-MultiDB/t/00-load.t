#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::MultiDB' );
}

diag( "Testing DBIx::MultiDB $DBIx::MultiDB::VERSION, Perl $], $^X" );
