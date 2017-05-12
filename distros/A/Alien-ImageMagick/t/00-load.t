#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::ImageMagick' ) || print "Bail out!\n";
}

diag( "Testing Alien::ImageMagick $Alien::ImageMagick::VERSION, Perl $], $^X" );
