#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BSON::Decode' ) || print "Bail out!\n";
}

diag( "Testing BSON::Decode $BSON::Decode::VERSION, Perl $], $^X" );
