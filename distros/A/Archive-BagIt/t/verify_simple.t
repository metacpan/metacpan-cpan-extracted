use strict;
use warnings;
use diagnostics;
use Test::More tests =>33;
use Test::Exception;
my $valid_bag = "bagit_conformance_suite/v1.0/valid/basicBag";
my $invalid_bag = "bagit_conformance_suite/v1.0/invalid/missing-from-manifest";
use Archive::BagIt;

{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $valid_bag, use_parallel => 0, use_async => 0 ]);
    ok(!$bag->use_parallel(), "confirmed serial (serial/sync)");
    ok(!$bag->use_async(), "confirmed sync (serial/sync)");
    ok($bag->verify_bag(), "conformance v1.0, pass (serial/sync)");
}
#
{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $valid_bag, use_parallel => 0, use_async => 1 ]);
    ok(!$bag->use_parallel(), "confirmed serial (serial/async)");
    ok($bag->use_async(), "confirmed async (serial/async)");
    ok($bag->verify_bag(), "conformance v1.0, pass (serial/async)");
}
#
#
{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $invalid_bag, use_parallel => 0, use_async => 0 ]);
    ok(!$bag->use_parallel(), "confirmed serial (serial/sync)");
    ok(!$bag->use_async(), "confirmed sync (serial/sync)");
    throws_ok(sub {$bag->verify_bag()}, qr{which is not in}, "conformance v1.0, fail (serial/sync)");
}
#
{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $invalid_bag, use_parallel => 0, use_async => 1 ]);
    ok(!$bag->use_parallel(), "confirmed serial (serial/async)");
    ok($bag->use_async(), "confirmed async (serial/async)");
    throws_ok(sub {$bag->verify_bag()}, qr{which is not in}, "conformance v1.0, fail (serial/async)");
}
#
SKIP: {
    skip "Parallel::parallel_map is unstable under MSWindows", 17 if $^O eq 'MSWin32';
    {
        my $bag = new_ok("Archive::BagIt" => [ bag_path => $valid_bag, use_parallel => 1, use_async => 0 ]);
        ok($bag->use_parallel(), "confirmed parallel (parallel/sync)");
        ok(!$bag->use_async(), "confirmed sync (parallel/sync)");
        ok($bag->verify_bag(), "conformance v1.0, pass (parallel/sync)");
    }
    #
    {
        my $bag = new_ok("Archive::BagIt" => [ bag_path => $valid_bag, use_parallel => 1, use_async => 1 ]);
        ok($bag->use_parallel(), "confirmed parallel (parallel/async)");
        ok($bag->use_async(), "confirmed async (parallel/async)");
        ok($bag->verify_bag(), "conformance v1.0, pass (parallel/async)");
    }
    {
        my $bag = new_ok("Archive::BagIt" => [ bag_path => $invalid_bag, use_parallel => 1, use_async => 0 ]);
        ok($bag->use_parallel(), "confirmed parallel (parallel/sync)");
        ok(!$bag->use_async(), "confirmed sync (parallel/sync)");
        throws_ok(sub {$bag->verify_bag()}, qr{which is not in}, "conformance v1.0, fail (parallel/sync)");
    }
    #
    {
        my $bag = new_ok("Archive::BagIt" => [ bag_path => $invalid_bag, use_parallel => 1, use_async => 1 ]);
        ok($bag->use_parallel(), "confirmed parallel (parallel/async)");
        ok($bag->use_async(), "confirmed async (parallel/async)");
        throws_ok(sub {$bag->verify_bag()}, qr{which is not in}, "conformance v1.0, fail (parallel/async)");
        throws_ok(sub {$bag->verify_bag({return_all_errors => 1})}, qr{which is not in}, "conformance v1.0, fail, all_errors (parallel/async)");
    }
}


1;