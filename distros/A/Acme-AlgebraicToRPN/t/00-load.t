#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::AlgebraicToRPN' );
}

diag( "Testing Acme::AlgebraicToRPN $Acme::AlgebraicToRPN::VERSION, Perl $], $^X" );
