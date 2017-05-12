#!perl

use Test::More;

BEGIN {
    use_ok('Acme::JMOLLY::Utils') || BAIL_OUT("Could not load Acme::JMOLLY::Utils");
}

ok(! sum(), "Empty sum is 0");
ok( sum(2,2), "2+2 = 4");

done_testing();