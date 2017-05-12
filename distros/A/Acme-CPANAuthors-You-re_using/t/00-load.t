#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 local $^W = 0;
 local $Acme::CPANAuthors::You're_using::SKIP = 1;
 use_ok( "Acme::CPANAuthors::You're_using" );
}

diag( "Testing Acme::CPANAuthors::You're_using $Acme::CPANAuthors::You're_using::VERSION, Perl $], $^X" );
