#!perl -T
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( "Acme::CPANAuthors::InMemoriam" );
}

diag( "Testing Acme::CPANAuthors::InMemoriam $Acme::CPANAuthors::InMemoriam::VERSION, Perl $], $^X" );
