#!/usr/bin/env perl
# Sharded queue: several Str queues behind one push and one consumer loop.
# Every handle bounds its wait for a shard's lock, so a stalled shard holds up
# nobody: a producer moves on to the next shard, the consumer to the next round.
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my ($shards, $producers, $per_producer) = (4, 8, 20_000);
my @q = map { Data::Queue::Shared::Str->new(undef, 4096) } 1 .. $shards;
$_->lock_timeout(0.0002) for @q;

sub push_sharded {
    my ($home, $value) = @_;
    for my $i (0 .. $#q) {
        return 1 if $q[($home + $i) % @q]->push($value);   # false: lock busy ($!{EAGAIN}) or full
    }
    return 0;
}

my @pids;
for my $p (1 .. $producers) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        push_sharded($p % @q, "p$p:$_") for 1 .. $per_producer;
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

my $received = 0;
while (1) {
    @pids = grep { waitpid($_, POSIX::WNOHANG()) == 0 } @pids;
    my $producers_done = !@pids;
    my $got = 0;
    $got += () = $_->pop_multi(256, 64 * 1024) for @q;
    $received += $got;
    last if $producers_done && !$got;
    select(undef, undef, undef, 0.001) unless $got;
}

my $sent = $producers * $per_producer;
printf "sent %d, received %d, dropped %d\n", $sent, $received, $sent - $received;

my %total;
for my $q (@q) {
    my $s = $q->stats;
    $total{$_} += $s->{$_} for qw(lock_waits lock_timeouts);
}
printf "%-13s %d\n", $_, $total{$_} for sort keys %total;
