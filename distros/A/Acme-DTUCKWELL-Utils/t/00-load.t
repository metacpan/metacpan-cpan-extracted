#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::DTUCKWELL::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::DTUCKWELL::Utils $Acme::DTUCKWELL::Utils::VERSION, Perl $], $^X" );
