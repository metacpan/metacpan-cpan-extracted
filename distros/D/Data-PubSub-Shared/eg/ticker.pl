#!/usr/bin/env perl
# Ticker: publisher at fixed rate, subscribers at different speeds
# Demonstrates overflow recovery for slow subscribers
#
# Usage: perl -Mblib eg/ticker.pl [rate_hz] [duration_sec]
#
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use Data::PubSub::Shared;

my $rate     = shift || 10000;   # publishes per second
my $duration = shift || 5;
my $interval = 1.0 / $rate;

my $ps = Data::PubSub::Shared::Int->new(undef, 1024);

# Subscriber configs: name, processing delay per message
my @configs = (
    ['fast',   0          ],  # no delay — keeps up
    ['medium', $interval*5],  # 5x slower than publisher
    ['slow',   $interval*50], # 50x slower — will overflow
);

my @pids;
for my $cfg (@configs) {
    my ($name, $delay) = @$cfg;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $sub = $ps->subscribe;
        my $received = 0;
        my $t0 = time;
        while (time - $t0 < $duration + 1) {
            my $v = $sub->poll_wait(0.5);
            if (defined $v) {
                $received++;
                sleep($delay) if $delay;
            }
        }
        # drain remaining
        $sub->poll_cb(sub { $received++ });

        printf "  %-8s  received: %6d  overflow: %6d  final lag: %d\n",
            $name, $received, $sub->overflow_count, $sub->lag;
        exit 0;
    }
    push @pids, $pid;
}

sleep(0.05);

my $total = $rate * $duration;
my $t0 = time;
my $published = 0;
printf "publishing %d msgs at %d Hz for %ds (ring cap=1024)\n\n", $total, $rate, $duration;

while ($published < $total) {
    $ps->publish(++$published);
    # pace to target rate
    my $target = $t0 + $published * $interval;
    my $now = time;
    sleep($target - $now) if $target > $now;
}

my $dt = time - $t0;
printf "\npublished %d msgs in %.1fs (%.0f Hz actual)\n\n", $published, $dt, $published/$dt;

waitpid($_, 0) for @pids;
