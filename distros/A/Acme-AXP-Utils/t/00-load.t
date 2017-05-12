#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 0.62 tests => 1;

BEGIN {
    use_ok( 'Acme::AXP::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::AXP::Utils $Acme::AXP::Utils::VERSION, Perl $], $^X" );
