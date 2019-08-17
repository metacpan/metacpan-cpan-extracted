#!perl -T
use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( "Acme::CPANAuthors::British" );
    use_ok( "Acme::CPANAuthors::British::Companies" );
}

diag( "Testing Acme::CPANAuthors::British $Acme::CPANAuthors::British::VERSION, Perl $], $^X" );
