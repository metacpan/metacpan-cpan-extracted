#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::RJWETMORE::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::RJWETMORE::Utils $Acme::RJWETMORE::Utils::VERSION, Perl $], $^X" );
