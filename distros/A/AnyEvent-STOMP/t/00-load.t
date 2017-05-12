#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::STOMP' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::STOMP $AnyEvent::STOMP::VERSION, Perl $], $^X" );
