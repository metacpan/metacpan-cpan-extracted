#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::AsciiArtFarts' ) || print "Bail out!
";
}

diag( "Testing Acme::AsciiArtFarts $Acme::AsciiArtFarts::VERSION, Perl $], $^X" );
