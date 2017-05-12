#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::RNA::SpliceSites::Scoring::MaxEntScan' ) || print "Failed to load module!\n";
}

diag( "Testing Bio::RNA::SpliceSites::Scoring::MaxEntScan $Bio::RNA::SpliceSites::Scoring::MaxEntScan::VERSION, Perl $], $^X" );
