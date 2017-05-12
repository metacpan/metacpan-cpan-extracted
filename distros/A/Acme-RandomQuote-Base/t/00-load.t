#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::RandomQuote::Base' );
}

diag( "Testing Acme::RandomQuote::Base $Acme::RandomQuote::Base::VERSION, Perl $], $^X" );
