#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Algorithm::Graphs::Reachable::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Graphs::Reachable::Tiny $Algorithm::Graphs::Reachable::Tiny::VERSION, Perl $], $^X" );
