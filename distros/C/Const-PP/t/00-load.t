#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Const::PP' ) || print "Bail out!\n";
}

diag( "Testing Const::PP $Const::PP::VERSION, Perl $], $^X" );
