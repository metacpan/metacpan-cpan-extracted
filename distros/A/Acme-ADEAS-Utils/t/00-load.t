#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::ADEAS::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::ADEAS::Utils $Acme::ADEAS::Utils::VERSION, Perl $], $^X" );
