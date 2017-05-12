#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::DBSCAN' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::DBSCAN $Algorithm::DBSCAN::VERSION, Perl $], $^X" );
