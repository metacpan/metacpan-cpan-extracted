#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::Store::Redis' );
}

diag( "Testing Catalyst::Plugin::Session::Store::Redis $Catalyst::Plugin::Session::Store::Redis::VERSION, Perl $], $^X" );
