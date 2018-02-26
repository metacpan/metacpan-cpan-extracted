#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::ForKids::LogicalPuzzleGenerator' ) || print "Bail out!\n";
}

diag( "Testing App::ForKids::LogicalPuzzleGenerator $App::ForKids::LogicalPuzzleGenerator::VERSION, Perl $], $^X" );
