#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bijection::XS' ) || print "Bail out!\n";
}

diag( "Testing Bijection::XS $Bijection::XS::VERSION, Perl $], $^X" );
