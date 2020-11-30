#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::libgraphqlparser' ) || print "Bail out!\n";
}

diag( "Testing Alien::libgraphqlparser $Alien::libgraphqlparser::VERSION, Perl $], $^X" );
