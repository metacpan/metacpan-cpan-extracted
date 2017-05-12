#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('Acme::CPANAuthors::Register');
    use_ok('Acme::CPANAuthors');
	use_ok('Acme::CPANAuthors::Ukrainian');
}

diag( "Testing Acme::CPANAuthors::Ukrainian $Acme::CPANAuthors::Ukrainian::VERSION, Perl $], $^X" );
