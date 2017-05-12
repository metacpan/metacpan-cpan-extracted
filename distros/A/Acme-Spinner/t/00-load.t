#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Spinner' );
}

diag( "Testing Acme::Spinner $Acme::Spinner::VERSION, Perl $], $^X" );
