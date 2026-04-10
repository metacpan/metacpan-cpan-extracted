#!/usr/bin/env perl
# Multiprocess fan-out: 1 publisher, N subscriber workers
#
# Usage: perl -Mblib eg/fanout.pl [workers] [messages]
#
use strict;
use warnings;
use Data::PubSub::Shared;

my $n_workers = shift || 4;
my $n_msgs    = shift || 1000;

my $ps = Data::PubSub::Shared::Str->new(undef, 65536);

my @pids;
for my $id (1..$n_workers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $sub = $ps->subscribe;
        my $count = 0;
        while ($count < $n_msgs) {
            my $msg = $sub->poll_wait(5);
            last unless defined $msg;
            $count++;
        }
        printf "worker %d: received %d/%d msgs (overflow: %d)\n",
            $id, $count, $n_msgs, $sub->overflow_count;
        exit 0;
    }
    push @pids, $pid;
}

# let workers subscribe before publishing
select(undef, undef, undef, 0.1);

for my $i (1..$n_msgs) {
    $ps->publish("event-$i: " . localtime);
}

waitpid($_, 0) for @pids;
print "publisher: sent $n_msgs messages to $n_workers workers\n";
