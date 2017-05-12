#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('Acme::CPANAuthors::Register');
    use_ok('Acme::CPANAuthors');
	use_ok('Acme::CPANAuthors::Russian');
}

diag( "Testing Acme::CPANAuthors::Russian $Acme::CPANAuthors::Russian::VERSION, Perl $], $^X" );
