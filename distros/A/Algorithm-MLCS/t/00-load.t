#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::MLCS' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::MLCS $Algorithm::MLCS::VERSION, Perl $], $^X" );
