#!/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use Arcus::Client;
use POSIX ":sys_wait_h";

use FindBin;
use lib "$FindBin::Bin";
use ArcusTestCommon;

if (not ArcusTestCommon->is_zk_port_opened()) {
  plan skip_all => "zk is not running...";
}

open(STDERR, '>', '/dev/null');

my $tb = Test::Builder->new;
$tb->no_ending(1);

my $cache = ArcusTestCommon->create_client("perl-test:");
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

my $num_children = 3;

for (my $i = 1; $i <= $num_children; $i++) {
  my $key = "key_$i";
  my $value = "value_from_process_0";
  ok($cache->add($key, $value), "Parent: add $key");
}

my $version = $cache->server_versions;

for (my $i = 1; $i <= $num_children; $i++) {
  my $pid = fork();
  ok(defined($pid), "Fork Success $i") if $pid;
  if ($pid == 0) {
    my $tb = Test::Builder->new;
    $tb->no_header(1);
    $tb->no_ending(1);
    my $key = "key_$i";
    my $value = "value_from_process_$i";
    exit(0) unless $cache->get($key) eq "value_from_process_0";
    exit(0) unless $cache->set($key, $value);
    exit(0) unless $cache->get($key) eq $value;
    exit(0) unless eq_deeply($cache->server_versions, $version);
    exit($i);
  }
}

while (waitpid(-1, 0) > 0) {
  my $id = $? >> 8;
  ok($id > 0, "Child(".($id ? $id : "").") get and set test");
}

is_deeply($cache->server_versions, $version, "Parent: version");

for (my $i = 1; $i <= $num_children; $i++) {
  my $key = "key_$i";
  my $value = "value_from_process_$i";
  is($cache->get($key), $value, "Parent: get $key");
}

$num_children = 100;
for (my $i = 1; $i <= $num_children; $i++) {
  my $pid = fork();
  if ($pid == 0) {
    my $cache = ArcusTestCommon->create_client("perl-test:");

    exit(1) unless $cache;
    exit(1) unless $cache->set("key", $i);

    exit(0);
  }
}

while (waitpid(-1, 0) > 0) {
  my $id = $? >> 8;
  is($id, 0);
}

ok(grep { $_ eq $cache->get("key") } (1..$num_children), "value is one of the expected values");

ok($cache->flush_all, "Flush All");
done_testing();
