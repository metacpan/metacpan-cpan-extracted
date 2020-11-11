#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::TOMOYAMA::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::TOMOYAMA::Utils $Acme::TOMOYAMA::Utils::VERSION, Perl $], $^X" );
