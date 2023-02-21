#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Matrix' ) || print "Bail out!\n";
}

diag( "Testing Acme::Matrix $Acme::Matrix::VERSION, Perl $], $^X" );
