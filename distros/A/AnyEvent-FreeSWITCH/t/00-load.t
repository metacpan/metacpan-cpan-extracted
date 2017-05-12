#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::FreeSWITCH' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::FreeSWITCH $AnyEvent::FreeSWITCH::VERSION, Perl $], $^X" );
