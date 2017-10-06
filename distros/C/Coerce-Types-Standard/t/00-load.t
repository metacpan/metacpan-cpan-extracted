#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Coerce::Types::Standard' ) || print "Bail out!\n";
}

diag( "Testing Coerce::Types::Standard $Coerce::Types::Standard::VERSION, Perl $], $^X" );
