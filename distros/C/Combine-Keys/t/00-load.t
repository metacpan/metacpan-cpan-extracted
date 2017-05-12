#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Combine::Keys' ) || print "Bail out!\n";
}

diag( "Testing Combine::Keys $Combine::Keys::VERSION, Perl $], $^X" );
