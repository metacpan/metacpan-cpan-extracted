#!/bin/perl

use strict;
use warnings;
use Test::More;

use Arcus::Client;

use FindBin;
use lib "$FindBin::Bin";
use ArcusTestCommon;

if (not ArcusTestCommon->is_zk_port_opened()) {
  plan skip_all => "zk is not running...";
}

open(STDERR, '>', '/dev/null');

my $cache = ArcusTestCommon->create_client("perl-test:");
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

ok($cache->add("iek", 129), "Add Test");
is($cache->get("iek"), 129, "Get Test");

ok($cache->delete("iek"), "Delete Test");
ok(!$cache->get("iek"), "Get Fail Test");
ok(!$cache->delete("iek"), "Delete Fail Test");

# ok($cache->add("iek", 129), "Add Test");
# is($cache->get("iek"), 129, "Get Test");
#
# ok($cache->delete("iek", 1), "Delete After 1s Test");
# is($cache->get("iek"), 129, "Get Test");
#
# sleep(1);
# ok(!$cache->get("iek"), "Get After 1s Fail Test");
# ok(!$cache->delete("iek"), "Delete After 1s Fail Test");

ok($cache->flush_all, "Flush All");
done_testing();
