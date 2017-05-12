#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Timeout' );
}

diag( "Testing DBIx::Timeout $DBIx::Timeout::VERSION, Perl $], $^X" );
