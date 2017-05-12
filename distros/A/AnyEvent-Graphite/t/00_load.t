#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'AnyEvent::Graphite' );
	use_ok( 'AnyEvent::Graphite::SNMPAgent' );
}

diag( "Testing AnyEvent::Graphite $AnyEvent::Graphite::VERSION, Perl $], $^X" );
