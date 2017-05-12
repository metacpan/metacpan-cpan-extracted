#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::FreeImage' ) || print "Bail out!";
}

diag( "Testing Alien::FreeImage $Alien::FreeImage::VERSION, Perl $], $^X" );
