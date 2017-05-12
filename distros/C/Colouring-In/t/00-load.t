#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Colouring::In' ) || print "Bail out!\n";
}

diag( "Testing Colouring::In $Colouring::In::VERSION, Perl $], $^X" );
