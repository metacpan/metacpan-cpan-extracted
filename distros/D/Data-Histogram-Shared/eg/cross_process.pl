#!/usr/bin/env perl
# Cross-process: parent builds a latency histogram via memfd, child opens the same
# fd, both record into the one shared counts array.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Histogram::Shared;
$| = 1;

# track 1 microsecond .. 1 second with 3 significant figures
my $h = Data::Histogram::Shared->new_memfd('hist-demo', 1, 1_000_000, 3);
my $fd = $h->memfd;

# Parent records a handful of fast latencies (microseconds) before the fork
$h->record($_) for (120, 130, 150, 200, 250);
printf "parent: recorded %d samples, p50=%d us max=%d us fd=%d\n",
    $h->total_count, $h->value_at_percentile(50), $h->max, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::Histogram::Shared->new_from_fd($fd);
    printf "child:  sees %d samples from parent (p50=%d us)\n",
        $c->total_count, $c->value_at_percentile(50);
    # Child records a slow-tail batch into the same shared histogram
    $c->record($_) for (900, 1500, 3000, 7500, 12000);
    printf "child:  added 5 tail samples, count now=%d max=%d us\n",
        $c->total_count, $c->max;
    _exit(0);
}
waitpid($pid, 0);

# The child's recordings are visible in the parent's view of the shared mapping
printf "parent: after child, count=%d\n", $h->total_count;
printf "parent: p50=%d  p90=%d  p99=%d  max=%d us\n",
    $h->value_at_percentile(50), $h->value_at_percentile(90),
    $h->value_at_percentile(99), $h->max;
