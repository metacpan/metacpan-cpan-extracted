#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::Image::Empty' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::View::Image::Empty $Catalyst::View::Image::Empty::VERSION, Perl $], $^X" );
