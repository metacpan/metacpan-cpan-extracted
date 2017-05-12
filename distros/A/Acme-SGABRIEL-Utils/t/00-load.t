#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Acme::SGABRIEL::Utils' ) || print "Bail out!\n";
    use_ok( 'Acme::SGABRIEL::Utils::Test' ) || print "Bail out!\n";
    use_ok( 'Tie::Cycle' ) || print "Bail out!\n";

}

diag( "Testing Acme::SGABRIEL::Utils $Acme::SGABRIEL::Utils::VERSION, Perl $], $^X" );
