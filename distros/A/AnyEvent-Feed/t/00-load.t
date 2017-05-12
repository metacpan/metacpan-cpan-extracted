#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AnyEvent::Feed' );
}

diag( "Testing AnyEvent::Feed $AnyEvent::Feed::VERSION, Perl $], $^X" );
