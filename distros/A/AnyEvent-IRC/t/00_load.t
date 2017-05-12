#!perl -T

use Test::More tests => 4;

BEGIN {
   use_ok( 'AnyEvent::IRC' );
   use_ok( 'AnyEvent::IRC::Util' );
   use_ok( 'AnyEvent::IRC::Connection' );
   use_ok( 'AnyEvent::IRC::Client' );
}

diag( "Testing AnyEvent::IRC $AnyEvent::IRC::VERSION, Perl $], $^X" );
