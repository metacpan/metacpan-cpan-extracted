#!/usr/bin/env perl
# Shared metrics: atomic counters + gauges across worker forks
#
# Workers atomically increment counters and update gauges.
# A monitoring process reads them on demand (no locks for reads).
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F64;

# metric layout:
# I64 counters: 0=requests, 1=errors, 2=bytes_in, 3=bytes_out
# F64 gauges:   0=avg_latency_ms, 1=cpu_usage_pct
my $counters = Data::Buffer::Shared::I64->new_anon(4);
my $gauges = Data::Buffer::Shared::F64->new_anon(2);

my $nworkers = 4;
my $work_items = 10_000;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork();
    if ($pid == 0) {
        srand($$);
        for (1..$work_items) {
            $counters->incr(0);                          # requests++
            $counters->add(2, 100 + int(rand(900)));     # bytes_in
            $counters->add(3, 50 + int(rand(450)));      # bytes_out
            if (rand() < 0.01) { $counters->incr(1) }   # 1% error rate
            # update gauge (last-writer-wins, acceptable for gauges)
            $gauges->set(0, rand(50));                   # latency ms
            $gauges->set(1, 10 + rand(80));              # cpu %
        }
        _exit(0);
    }
    push @pids, $pid;
}

# monitoring: sample metrics while workers are running
my $samples = 0;
while (1) {
    sleep 0.01;
    my $reqs = $counters->get(0);
    last if $reqs >= $nworkers * $work_items;
    $samples++ if $reqs > 0;
}
waitpid($_, 0) for @pids;

printf "metrics after %d workers x %d items:\n", $nworkers, $work_items;
printf "  requests:   %d\n", $counters->get(0);
printf "  errors:     %d (%.2f%%)\n",
    $counters->get(1), $counters->get(1) / $counters->get(0) * 100;
printf "  bytes_in:   %d\n", $counters->get(2);
printf "  bytes_out:  %d\n", $counters->get(3);
printf "  last_latency: %.1fms\n", $gauges->get(0);
printf "  last_cpu:     %.1f%%\n", $gauges->get(1);
printf "  monitoring samples taken: %d\n", $samples;
