#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Meow' );
}

diag( "Testing Acme::Meow $Acme::Meow::VERSION, Perl $], $^X" );
