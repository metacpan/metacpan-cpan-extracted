#!perl -T
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( "Acme::CPANAuthors::BackPAN::OneHundred" );
}

diag( "Testing Acme::CPANAuthors::BackPAN::OneHundred $Acme::CPANAuthors::BackPAN::OneHundred::VERSION, Perl $], $^X" );
