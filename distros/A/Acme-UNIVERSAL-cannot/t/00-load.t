#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::UNIVERSAL::cannot' );
}

diag( "Testing Acme::UNIVERSAL::cannot $Acme::UNIVERSAL::cannot::VERSION, Perl $], $^X" );
