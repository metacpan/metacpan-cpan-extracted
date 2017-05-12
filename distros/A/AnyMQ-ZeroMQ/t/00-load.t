#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyMQ::ZeroMQ' ) || print "Bail out!\n";
}

diag( "Testing AnyMQ::ZeroMQ $AnyMQ::ZeroMQ::VERSION, Perl $], $^X" );
