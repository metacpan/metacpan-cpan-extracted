#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.005;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start;

skip "consul test environment not available", 27 unless $tc;

my $kv = Consul->kv(port => $tc->port);
ok $kv, "got KV API object";

my $r;

lives_ok { $r = $kv->get("foo") } "KV get succeeded";
is $r, undef, "key not found";

lives_ok { $r = $kv->put(foo => "bar") } "KV put succeeded";
ok $r, "key was updated";

lives_ok { $r = $kv->get("foo") } "KV get succeeded";
is $r->value, "bar", "returned KV has correct value";

lives_ok { $r = $kv->delete("foo") } "KV delete succeeded";
is $kv->get("foo"), undef, "key not found";

lives_ok { $r = $kv->put(foo => 1) } "KV put succeeded";
ok $r, "key was updated";
lives_ok { $r = $kv->put(bar => 2) } "KV put succeeded";
ok $r, "key was updated";
lives_ok { $r = $kv->put(baz => 3) } "KV put succeeded";
ok $r, "key was updated";

lives_ok { $r = $kv->put(quux => undef) } "KV put null value succeeds";
ok $r, "key was updated";
lives_ok { $r = $kv->get("quux") } "KV get succeeded";
ok !defined($r->value), "returned key is null";

lives_ok { $r = $kv->keys("") } "KV keys succeeded";
is_deeply [sort @$r], [sort qw(foo bar baz quux)], "return KV keys are correct";

lives_ok { $r = $kv->put("foo" => 1) } "KV put succeeded";
ok $r, "key was updated";
lives_ok { $r = $kv->put("foo/bar" => 2) } "KV put succeeded";
ok $r, "key was updated";
lives_ok { $r = $kv->put("foo/bar/baz" => 3) } "KV put succeeded";
ok $r, "key was updated";

lives_ok { $r = $kv->get_all("foo") } "KV get_all succeeded";
is scalar(@$r), 3, "3 keys returned";
is_deeply [sort map { $_->key } @$r], [sort qw(foo foo/bar foo/bar/baz)], "return KV keys are correct";
is_deeply [sort map { $_->value } @$r], [sort qw(1 2 3)], "return KV values are correct";

lives_ok { $r = $kv->delete("foo", recurse => 1) } "KV delete recursive succeeded";

lives_ok { $r = $kv->get_all("foo") } "KV get_all succeeded";
ok defined($r) && ref($r) eq 'ARRAY', "get_all returned an arrayref";
is scalar(@$r), 0, "0 keys returned";

subtest 'zero value works' => sub{
  lives_ok { $r = $kv->get("foozero") } "KV get succeeded";
  is $r, undef, "key not found";

  lives_ok { $r = $kv->put(foozero => 0) } "KV put succeeded";
  ok $r, "key was updated";

  lives_ok { $r = $kv->get("foozero") } "KV get succeeded";
  is $r->value, 0, "returned KV has correct value";

  lives_ok { $r = $kv->delete("foozero") } "KV delete succeeded";
  is $kv->get("foo"), undef, "key not found";
};

done_testing;
