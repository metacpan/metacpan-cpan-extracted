#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Crayon' ) || print "Bail out!\n";
}

diag( "Testing Crayon $Crayon::VERSION, Perl $], $^X" );
