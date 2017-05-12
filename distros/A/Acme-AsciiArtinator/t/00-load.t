#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::AsciiArtinator' );
}

diag( "Testing Acme::AsciiArtinator $Acme::AsciiArtinator::VERSION, Perl $], $^X" );
