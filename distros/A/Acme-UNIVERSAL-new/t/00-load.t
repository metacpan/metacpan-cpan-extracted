#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::UNIVERSAL::new' );
}

diag( "Testing Acme::UNIVERSAL::new $Acme::UNIVERSAL::new::VERSION, Perl $], $^X" );
