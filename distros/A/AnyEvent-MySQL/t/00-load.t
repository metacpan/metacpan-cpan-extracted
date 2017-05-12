#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::MySQL' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::MySQL $AnyEvent::MySQL::VERSION, Perl $], $^X" );
