#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::FIREXFLY::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::FIREXFLY::Utils $Acme::FIREXFLY::Utils::VERSION, Perl $], $^X" );
