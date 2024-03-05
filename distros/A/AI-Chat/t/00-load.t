#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AI::Chat' ) || print "Bail out!\n";
}

diag( "Testing AI::Chat $AI::Chat::VERSION, Perl $], $^X" );
