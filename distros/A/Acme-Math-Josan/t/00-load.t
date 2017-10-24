#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Acme::Math::Josan' ) || print "Bail out!\n";
    warn josan(1, 2);

    my $count = 0;
    for (1 .. 100000) {
        $count++ if josan(4,2) == 2;
    }
    ok($count < 51000);
    ok($count > 49000);
}

diag( "Testing Acme::Math::Josan $Acme::Math::Josan::VERSION, Perl $], $^X" );
