#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Emitter' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::Emitter $AnyEvent::Emitter::VERSION, Perl $], $^X" );
