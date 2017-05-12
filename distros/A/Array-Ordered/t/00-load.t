#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Array::Ordered' ) || print "Bail out!\n";
}

diag( "Testing Array::Ordered $Array::Ordered::VERSION, Perl $], $^X" );
