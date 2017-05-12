#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Array::MaxSize' ) || print "Bail out!\n";
}

diag( "Testing Acme::Array::MaxSize $Acme::Array::MaxSize::VERSION, Perl $], $^X" );
