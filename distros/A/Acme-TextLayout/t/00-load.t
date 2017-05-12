#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::TextLayout' );
}

diag( "Testing Acme::TextLayout $Acme::TextLayout::VERSION, Perl $], $^X" );
