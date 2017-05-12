#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Terror' );
}

diag( "Testing Acme::Terror $Acme::Terror::VERSION, Perl $], $^X" );
