#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::Graphs::TransitiveClosure::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Graphs::TransitiveClosure::Tiny $Algorithm::Graphs::TransitiveClosure::Tiny::VERSION, Perl $], $^X" );
