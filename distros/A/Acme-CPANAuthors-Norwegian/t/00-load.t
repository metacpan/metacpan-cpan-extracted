#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('Acme::CPANAuthors::Register');
    use_ok('Acme::CPANAuthors');
	use_ok('Acme::CPANAuthors::Norwegian');
}

diag( "Testing Acme::CPANAuthors::Norwegian $Acme::CPANAuthors::Norwegian::VERSION, Perl $], $^X" );
