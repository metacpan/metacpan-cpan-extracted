#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.005;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start;

skip "consul test environment not available", 15 unless $tc;

my $kv = Consul->kv(port => $tc->port);
ok $kv, "got KV API object";

my ($r, $meta, $index);

lives_ok { ($r, $meta) = $kv->get("foo") } "KV get succeeded";
is $r, undef, "key not found";
isa_ok $meta, 'Consul::Meta', "got server meta object";
$index = $meta->index;

lives_ok { $r = $kv->put(foo => "bar") } "KV put succeeded";

lives_ok { ($r, $meta) = $kv->get("foo") } "KV get succeeded";
is $r->value, "bar", "returned KV has correct value";
isa_ok $meta, 'Consul::Meta', "got server meta object";
ok $meta->index > $index, "index advanced";
$index = $meta->index;

lives_ok { $r = $kv->put(foo => "baz", cas => 1) } "KV put (invalid cas) succeeded";
ok !$r, "key was not updated";

lives_ok { $r = $kv->put(foo => "baz", cas => $index) } "KV put (valid cas) succeeded";
ok $r, "key was updated";

lives_ok { $r = $kv->get("foo") } "KV get succeeded";
is $r->value, "baz", "key has correct value";

done_testing;
