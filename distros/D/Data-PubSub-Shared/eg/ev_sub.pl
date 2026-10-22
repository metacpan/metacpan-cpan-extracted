#!/usr/bin/env perl
# Event-loop subscriber and a forked publisher sharing one eventfd.
# Usage: perl -Mblib eg/ev_sub.pl
use strict;
use warnings;
use EV;
use Data::PubSub::Shared;

my $ps = Data::PubSub::Shared::Str->new(undef, 1024);
my $fd = $ps->eventfd;
my $sub = $ps->subscribe;
my $pid = fork // die "fork: $!";
if (!$pid) {
    for (1..10) {
        $ps->publish_notify("message $_");
        sleep 1;
    }
    exit 0;
}

my $count = 0;
my $watcher = EV::io $fd, EV::READ, sub {
    for my $msg ($sub->drain_notify) {
        print "received: $msg\n";
        $count++;
    }
    EV::break if $count >= 10;
};
my $timeout = EV::timer 30, 0, sub { EV::break };
EV::run;
waitpid($pid, 0);
print "Done.\n";
