use strict;
use warnings;
use diagnostics;
use Test::More tests => 4;
use Test::Exception;
my $valid_bag = "bagit_conformance_suite/v1.0/valid/basicBag";
my $invalid_bag = "bagit_conformance_suite/v1.0/invalid/missing-from-manifest";
use Archive::BagIt;

{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $valid_bag]);
    ok($bag->verify_bag(), "conformance v1.0, pass");
}
#
#
#
{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => $invalid_bag]);
    throws_ok(sub {$bag->verify_bag()}, qr{which is not in}, "conformance v1.0, fail");
}

1;
