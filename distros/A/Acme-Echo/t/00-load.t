#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Echo' );
}

diag( "Testing Acme::Echo $Acme::Echo::VERSION, Perl $], $^X" );
