#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::cpackage' ) || print "Bail out!\n";
}

diag( "Testing App::cpackage $App::cpackage::VERSION, Perl $], $^X" );
