#!/usr/bin/env perl
# Event-loop subscriber using EV + eventfd
#
# Run publisher in one terminal:
#   perl -Mblib -MData::PubSub::Shared -e '
#     my $ps = Data::PubSub::Shared::Str->new("/tmp/ev_example.shm", 1024);
#     for (1..10) { $ps->publish_notify("message $_"); sleep 1 }
#   '
#
# Run this subscriber in another:
#   perl -Mblib eg/ev_sub.pl
#
use strict;
use warnings;
use EV;
use Data::PubSub::Shared;

my $path = shift || '/tmp/ev_example.shm';

my $ps = Data::PubSub::Shared::Str->new($path, 1024);
my $fd = $ps->eventfd;
my $sub = $ps->subscribe;

print "Listening on $path (fd=$fd)...\n";

# EV watcher fires when publisher calls notify()
my $w = EV::io $fd, EV::READ, sub {
    # drain_notify = eventfd_consume + drain in one call
    my @msgs = $sub->drain_notify;
    for my $msg (@msgs) {
        print "received: $msg\n";
    }
};

# Or use poll_cb for maximum throughput:
#
# my $w = EV::io $fd, EV::READ, sub {
#     $ps->eventfd_consume;
#     $sub->poll_cb(sub {
#         my ($msg) = @_;
#         print "received: $msg\n";
#     });
# };

# Timeout to exit after 30 seconds of inactivity
my $timeout = EV::timer 30, 0, sub { EV::break };

EV::run;
print "Done.\n";
