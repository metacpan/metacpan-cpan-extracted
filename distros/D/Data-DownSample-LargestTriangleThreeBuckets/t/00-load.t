#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::DownSample::LargestTriangleThreeBuckets' ) || print "Bail out!\n";
}

diag( "Testing Data::DownSample::LargestTriangleThreeBuckets $Data::DownSample::LargestTriangleThreeBuckets::VERSION, Perl $], $^X" );
