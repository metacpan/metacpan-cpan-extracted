#!/usr/bin/env perl
# Subscriber monitor: prints throughput, lag, and overflow stats
#
# Usage:
#   # Terminal 1 — publisher:
#   perl -Mblib -MData::PubSub::Shared -e '
#     my $ps = Data::PubSub::Shared::Int->new("/tmp/monitor_demo.shm", 65536);
#     my $i = 0;
#     while (1) { $ps->publish(++$i); select undef,undef,undef,0.00001 }
#   '
#
#   # Terminal 2 — monitor:
#   perl -Mblib eg/monitor.pl /tmp/monitor_demo.shm
#
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use Data::PubSub::Shared;

my $path     = shift || '/tmp/monitor_demo.shm';
my $interval = shift || 1;

my $ps = Data::PubSub::Shared::Int->new($path, 65536);
my $sub = $ps->subscribe;

my $prev_cursor = $sub->cursor;
my $prev_time   = time;
my $prev_overflow = 0;

printf "%-12s %12s %10s %10s %12s\n",
    'elapsed', 'throughput', 'lag', 'overflows', 'write_pos';

while (1) {
    sleep($interval);

    # drain all available (don't fall behind)
    my $count = 0;
    $sub->poll_cb(sub { $count++ });

    my $now     = time;
    my $dt      = $now - $prev_time;
    my $cursor  = $sub->cursor;
    my $delta   = $cursor - $prev_cursor;
    my $rate    = $dt > 0 ? $delta / $dt : 0;
    my $lag     = $sub->lag;
    my $ovf     = $sub->overflow_count;
    my $new_ovf = $ovf - $prev_overflow;

    printf "%-12.1f %10.1fK/s %10d %10d %12d\n",
        $now - $prev_time + $interval, $rate / 1000, $lag, $new_ovf, $sub->write_pos;

    $prev_cursor   = $cursor;
    $prev_time     = $now;
    $prev_overflow = $ovf;
}
