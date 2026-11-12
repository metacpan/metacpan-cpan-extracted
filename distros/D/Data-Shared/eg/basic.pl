#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_get shared_set shared_exists shared_call shared_push shared_pop);

my $root = Data::Shared->new;
$root->mount('cache', 'hashmap:ii', undef, 100_000);
$root->mount('visitors', 'hyperloglog', undef, 14);
$root->mount('jobs', 'queue:int', undef, 1024);

shared_set($root, '/cache/42', 100);
print "cache/42 = ", shared_get($root, '/cache/42'), "\n";
print "exists   = ", shared_exists($root, '/cache/42'), "\n";

shared_call($root, '/visitors', 'add', $_) for qw(alice bob alice);
print "visitors ~ ", shared_call($root, '/visitors', 'count'), "\n";

shared_push($root, '/jobs', 42);
print "job      = ", shared_pop($root, '/jobs'), "\n";
