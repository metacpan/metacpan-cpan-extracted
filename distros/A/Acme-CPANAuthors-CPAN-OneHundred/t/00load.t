#!perl -T
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( "Acme::CPANAuthors::CPAN::OneHundred" );
}

diag( "Testing Acme::CPANAuthors::CPAN::OneHundred $Acme::CPANAuthors::CPAN::OneHundred::VERSION, Perl $], $^X" );
