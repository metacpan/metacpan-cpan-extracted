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

# Initialize
ok($cache->add("iek", 129), "Add Test");
is($cache->get("iek"), 129, "Get Test");

is($cache->incr("iek"), 130, "Incr(default) Test");
is($cache->incr("iek", 125), 255, "Incr Test");
is($cache->decr("iek"), 254, "Decr(default) Test");
is($cache->decr("iek", 30), 224, "Decr Test");
is($cache->decr("iek", 500), "0E0", "Decr Too Large Value");

# Negative offset : converted and processed as the unsinged number.
ok($cache->replace("iek", 224), "Replace Test");
ok($cache->get("iek") < $cache->incr("iek", -1), "Incr Negative value");
ok($cache->replace("iek", 224), "Replace Test");
is($cache->decr("iek", -1), "0E0", "Decr Negative value");

ok($cache->replace("iek", -1), "Replace Test");

is($cache->incr("iek"), undef, "Incr Fail Test");
is($cache->decr("iek"), undef, "Decr Fail Test");

ok(!$cache->incr(undef));
ok(!$cache->decr(undef));

ok(!$cache->incr("iek", "offset"));
ok(!$cache->decr("iek", "offset"));

ok($cache->replace("iek", "forever"), "Replace Test");

is($cache->incr("iek"), undef, "Incr Fail Test");
is($cache->decr("iek"), undef, "Decr Fail Test");

is($cache->incr("empty"), undef, "Incr Not Eexist Test");
is($cache->decr("empty"), undef, "Decr Not Exist Test");

ok($cache->set("key", 0));
my $decr = $cache->decr("key", 100);
ok($decr, "Decr to Zero Is True");
ok($decr == 0, "Decr to Zero Is Zero");

ok($cache->flush_all, "Flush All");
done_testing();
