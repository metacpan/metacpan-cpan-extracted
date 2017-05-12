#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::Image::Text2Image' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::View::Image::Text2Image $Catalyst::View::Image::Text2Image::VERSION, Perl $], $^X" );
