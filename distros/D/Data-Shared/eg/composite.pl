#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_set shared_get shared_exists shared_delete);

my $root = Data::Shared->new;

my $users = eval { $root->mount('users', ['hashmap:ss', 1000, ['bloomfilter', 10000, 0.01]]) };
if ($users) {
    shared_set($root, '/users/alice/event-42', 1);
    shared_set($root, '/users/bob/event-7', 1);
    print "users: ", join(', ', $root->children('/users')), "\n";
    print "alice event-42: ", shared_exists($root, '/users/alice/event-42'), "\n";
    print "alice filter count: ", $root->node('/users/alice')->call('count'), "\n";
    shared_delete($root, '/users/bob');
    print "after delete bob, users: ", join(', ', $root->children('/users')), "\n";
} else {
    die $@ unless $@ =~ /is not available; install the/;
    print "skip users: $@";
}

my $leaders = eval { $root->mount('leaders', ['sortedset:strings', { max => 1000 }, ['bloomfilter', 10000, 0.01]]) };
if ($leaders) {
    shared_set($root, '/leaders/alice', 1500);
    shared_set($root, '/leaders/alice/event-9', 1);
    print "alice score: ", shared_get($root, '/leaders/alice'),
          " event-9: ", shared_exists($root, '/leaders/alice/event-9'), "\n";
} else {
    die $@ unless $@ =~ /is not available; install the/;
    print "skip leaders: $@";
}
