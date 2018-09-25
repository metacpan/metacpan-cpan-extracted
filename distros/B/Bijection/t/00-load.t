#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bijection' ) || print "Bail out!\n";
}

diag( "Testing Bijection $Bijection::VERSION, Perl $], $^X" );
