#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Array::Objectify' ) || print "Bail out!\n";
}

diag( "Testing Array::Objectify $Array::Objectify::VERSION, Perl $], $^X" );
