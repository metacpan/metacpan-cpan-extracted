#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Business::ES::NIF' ) || print "Bail out!\n";
}

diag( "Testing Business::ES::NIF $Business::ES::NIF::VERSION, Perl $], $^X" );
