#!/bin/perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

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

ok($cache->set("key", "value"));
is($cache->get("key"), "value", "Get After Set - Value");

ok($cache->delete("key"));
is($cache->get("key"), undef, "Get After Delete Is Undef");

is($cache->get(), undef, "Get Without Key Is Undef");
is($cache->get(""), undef, "Get With Empty String Key Is Undef");
is($cache->get(undef), undef, "Get With Undef Key Is Undef");

ok($cache->set("key", ""));
is($cache->get("key"), "", "Get After Set Empty String Returns Empty String");

ok($cache->set("key", "value"));
my $ref = $cache->gets("key");

ok($ref, "Gets After Set Is Not Undef");
ok(looks_like_number($ref->[0]), "Gets After Set - Cas Is Number");
is($ref->[1], "value", "Gets After Set - Value");

ok($cache->delete("key"));
is($cache->gets("key"), undef, "Gets After Delete Is Undef");

is($cache->gets(), undef, "Gets Without Key Is Undef");
is($cache->gets(""), undef, "Gets With Empty String Key Is Undef");
is($cache->gets(undef), undef, "Gets With Undef Key Is Undef");

ok($cache->flush_all);

ok($cache->set("key", ""));
$ref = $cache->get_or_set("key", sub {
  return "value";
}, 60);
is($ref, "", "Get Or Set To Stored Value Returns Old Value");

ok($cache->delete("key"));
$ref = $cache->get_or_set("key", sub {
  return "value";
}, 60);
is($ref, "value", "Get Or Set To Not Stored Value Returns Callback Value");

done_testing();
