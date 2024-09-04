#!/bin/perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw/weaken/;

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

my $big_value = 'x' x ( 1024 * 1024 * 10 );
is($cache->set("key", $big_value), undef, "Set With Too Big Value Is Undef");
is($cache->add("key", $big_value), undef, "Add With Too Big Value Is Undef");
is($cache->replace("key", $big_value), undef, "Replace With Too Big Value Is Undef");
is($cache->prepend("key", $big_value), undef, "Prepend With Too Big Value Is Undef");
is($cache->append("key", $big_value), undef, "Append With Too Big Value Is Undef");
is($cache->cas("key", 1, $big_value), undef, "Cas With Too Big Value Is Undef");

is($cache->set(undef), undef);
is($cache->set(undef, 129), undef);
is($cache->set("iek", undef), undef);
is($cache->set("iek", 10, "exptime"), undef);

ok($cache->set("kv01", "abc"), "str - set");
ok($cache->set("kv02", 123), "int - set");
ok($cache->set("kv03", [ "elem1", "elem2" ]), "arr - set");
ok($cache->set("kv04", { "field1" => "elem1" }), "hash - set");
is_deeply($cache->get("kv01"), "abc", "str - get");
is_deeply($cache->get("kv02"), 123, "int - get");
is_deeply($cache->get("kv03"), [ "elem1", "elem2" ], "arr - get");
is_deeply($cache->get("kv04"), { "field1" => "elem1" }, "hash - get");

ok($cache->add("iek", 129), "Add Test");
is($cache->get("iek"), 129, "Get Test");
ok($cache->add("가 Þ 💧", 129), "Sanitized Add Test");
is($cache->get("가 Þ 💧"), 129, "Sanitized Get Test");

ok($cache->set("가 Þ 💧", 20), "Sanitized Set Test");
is($cache->get("가 Þ 💧"), 20, "Sanitized Get Test");

is($cache->add("iek", 129), 0);
ok($cache->replace("iek", 76), "Replace Test");

ok($cache->append("iek", 255), "Append Test");
is($cache->get("iek"), 76255, "Get Test");
ok($cache->prepend("가 Þ 💧", 22), "Sanitized Prepend Test");
is($cache->get("가 Þ 💧"), 2220, "Sanitized Get Test");

# cas
my $ref = $cache->gets("iek");
is($ref->[1], 76255, "Gets Test");
is($cache->cas("iek", $ref->[0], undef), undef);

$ref = $cache->gets("iek");
is($ref->[1], 76255, "Gets Test");
ok($cache->cas("iek", $ref->[0], 129), "Cas Test");
is($cache->get("iek"), 129, "Get Test");
is($cache->cas("iek", 0, 130), undef);

is($cache->replace(1), undef);
ok($cache->set(1, 20), "Set Test");
is($cache->get(1), 20, "Get Test");

ok($cache->set("iek", 129, time() - 1), "Set Exptime Test");
is($cache->get("iek"), undef, "Already Expired item");

ok($cache->set("iek", 129));
is($cache->replace("iek", undef), undef);

ok($cache->flush_all, "Flush All");
done_testing();
