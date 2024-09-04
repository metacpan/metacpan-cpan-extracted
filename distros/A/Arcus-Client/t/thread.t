#!/bin/perl

use strict;
use warnings;
use Test::More;

use Arcus::Client;
use threads;
use threads::shared;

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

sub cache_worker {
  my ($thread_id) = @_;
  my $key = "key_$thread_id";
  my $value = "value_from_thread_$thread_id";
  if ($cache->set($key, $value) and ($cache->get($key) eq $value)) {
    return 1;
  }
  return 0;
}

my @threads;
for my $i (1..5) {
  push @threads, threads->create(\&cache_worker, $i);
}

for my $i (0 .. $#threads) {
  my $ret = $threads[$i]->join();
  ok($ret, "Thread $i Test");
}

for my $i (1..5) {
  my $key = "key_$i";
  my $value = "value_from_thread_$i";
  is($cache->get($key), $value, "Main: get $key");
}

sub update_worker {
  my ($thread_id) = @_;
  $cache->set("key", $thread_id);
  return 1;
}

my @update_threads;
my $num_threads = 5;
for my $i (1..$num_threads) {
  push @update_threads, threads->create(\&update_worker, $i);
}

for my $i (0 .. $#update_threads) {
  my $ret = $update_threads[$i]->join();
  ok($ret, "Thread $i Test");
}

ok(grep { $_ eq $cache->get("key") } (1..$num_threads), "value is one of the expected values");

ok($cache->flush_all, "Flush All");
done_testing();
