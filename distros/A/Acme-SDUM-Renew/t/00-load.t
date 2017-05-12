#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::SDUM::Renew' );
}

diag( "Testing Acme::SDUM::Renew $Acme::SDUM::Renew::VERSION, Perl $], $^X" );
