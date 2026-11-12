#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_push shared_pop shared_call shared_get);

my $root = Data::Shared->new;
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('jobs', 'queue:int', undef, 1024)) {
    shared_push($root, '/jobs', $_) for 1 .. 3;
    print "queue pop: ", shared_pop($root, '/jobs'), "\n";
    print "queue size: ", shared_call($root, '/jobs', 'size'), "\n";
}
if (mount_or_skip('stack', 'stack:str', undef, 50, 64)) {
    shared_push($root, '/stack', 'first');
    shared_push($root, '/stack', 'second');
    print "stack pop: ", shared_pop($root, '/stack'), "\n";
}
if (mount_or_skip('tasks', 'heap', undef, 100)) {
    shared_push($root, '/tasks', 5, 500);
    shared_push($root, '/tasks', 1, 100);
    my ($pri, $job) = shared_pop($root, '/tasks');
    print "heap pop: pri=$pri job=$job\n";
}
if (mount_or_skip('audit', 'log', undef, 100_000)) {
    shared_push($root, '/audit', 'boot');
    shared_push($root, '/audit', 'ready');
    print "log entries: ", shared_call($root, '/audit', 'entry_count'), "\n";
}
if (mount_or_skip('ring', 'ringbuffer:int', undef, 100)) {
    shared_push($root, '/ring', $_) for 41, 42;
    print "ring latest: ", shared_get($root, '/ring'), "\n";
}
if (mount_or_skip('events', 'pubsub:int', undef, 1024)) {
    my $sub = shared_call($root, '/events', 'subscribe');
    shared_push($root, '/events', 99);
    print "pubsub poll: ", $sub->poll, "\n";
}
