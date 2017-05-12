#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyMQ::RawSocket' ) || print "Bail out!\n";
}

diag( "Testing AnyMQ::RawSocket $AnyMQ::RawSocket::VERSION, Perl $], $^X" );
