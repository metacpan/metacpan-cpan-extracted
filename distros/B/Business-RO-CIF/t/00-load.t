#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Business::RO::CIF' ) || print "Bail out!\n";
}

diag( "Testing Business::RO::CIF $Business::RO::CIF::VERSION, Perl $], $^X" );
