#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::WikiLink' ) || print "Bail out!\n";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::WikiLink $Bot::BasicBot::Pluggable::Module::WikiLink::VERSION, Perl $], $^X" );
