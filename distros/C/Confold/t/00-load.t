#!perl
use 5.038;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Confold' ) || print "Bail out!\n";
}

diag( "Testing Confold $Confold::VERSION, Perl $], $^X" );
