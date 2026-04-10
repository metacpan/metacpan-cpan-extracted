#!/usr/bin/env perl
# Basic publisher + subscriber example
use strict;
use warnings;
use Data::PubSub::Shared;

my $path = '/tmp/pubsub_example.shm';

# Create pub/sub ring with 1024 slots
my $ps = Data::PubSub::Shared::Int->new($path, 1024);

# Create subscriber before publishing (gets future messages only)
my $sub = $ps->subscribe;

# Publish some messages
$ps->publish(42);
$ps->publish_multi(100, 200, 300);

# Poll messages
while (defined(my $val = $sub->poll)) {
    print "got: $val\n";
}

# String variant
my $sps = Data::PubSub::Shared::Str->new(undef, 256);
$sps->publish("hello world");
$sps->publish("foo bar");

my $ssub = $sps->subscribe_all;
my @msgs = $ssub->drain;
print "drained: @msgs\n";

# Multiprocess
if (fork() == 0) {
    my $child_ps = Data::PubSub::Shared::Int->new($path, 1024);
    my $child_sub = $child_ps->subscribe;
    my $val = $child_sub->poll_wait(2);
    print "child got: $val\n" if defined $val;
    exit 0;
}

$ps->publish(999);
wait;

$ps->unlink;
