#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AnyEvent::SOCKS::Client' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::SOCKS::Client $AnyEvent::SOCKS::Client::VERSION, Perl $], $^X" );
