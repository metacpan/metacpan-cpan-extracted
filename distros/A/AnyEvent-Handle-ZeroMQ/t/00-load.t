#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Handle::ZeroMQ' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::Handle::ZeroMQ $AnyEvent::Handle::ZeroMQ::VERSION, Perl $], $^X" );
