#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Cisco::ACI' ) || print "Bail out!\n";
}

diag( "Testing Cisco::ACI $Cisco::ACI::VERSION, Perl $], $^X" );
