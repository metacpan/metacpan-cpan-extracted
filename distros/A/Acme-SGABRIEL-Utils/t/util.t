#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

#plan tests => 3;

BEGIN {
    use_ok( 'Acme::SGABRIEL::Utils' ) || print "Bail out!\n";
    use_ok( 'Acme::SGABRIEL::Utils::Test' ) || print "Bail out!\n";
    use_ok( 'Tie::Cycle' ) || print "Bailout\n";
}


ok(Acme::SGABRIEL::Utils::sum(2,2,2) == 6, "Sum Function Works" );
Acme::SGABRIEL::Utils::Test::sum_ok(sum(2,2,2),6);

plan tests => 5;
