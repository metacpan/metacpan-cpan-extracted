#! /usr/bin/env perl

use Test::More;

diag "\nSample run. May take some seconds...";
my $out = qx"$^X -Ilib bin/benchmark-perlformance --fastmode -vv";
ok($out, "sample run");
diag "\n".$out;

SKIP: {
    skip "sample run --stabilize-cpu - needs TEST_PERLFORMANCE_WITH_STABILIZE=1 (uses sudo)", 1
        unless $ENV{TEST_PERLFORMANCE_WITH_STABILIZE};

    $out = qx"$^X -Ilib bin/benchmark-perlformance --fastmode --stabilize-cpu";
    ok($out, "sample run --stabilize-cpu");
    diag "\n".$out;
}

done_testing();
