#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Lvalue' );
}

diag( "Testing Acme::Lvalue $Acme::Lvalue::VERSION, Perl $], $^X" );
