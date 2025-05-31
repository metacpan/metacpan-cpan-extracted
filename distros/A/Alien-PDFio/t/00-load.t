#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::PDFio' ) || print "Bail out!\n";
}

diag( "Testing Alien::PDFio $Alien::PDFio::VERSION, Perl $], $^X" );
