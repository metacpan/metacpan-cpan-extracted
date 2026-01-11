#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ACME::2026' ) || print "Bail out!\n";
}

diag( "Testing ACME::2026 $ACME::2026::VERSION, Perl $], $^X" );
