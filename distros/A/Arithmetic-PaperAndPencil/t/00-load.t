#!perl
use 5.38.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Arithmetic::PaperAndPencil' ) || print "Bail out!\n";
}

diag( "Testing Arithmetic::PaperAndPencil $Arithmetic::PaperAndPencil::VERSION, Perl $], $^X" );
