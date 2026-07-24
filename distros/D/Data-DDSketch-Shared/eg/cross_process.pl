#!/usr/bin/env perl
# Cross-process: parent builds a sketch via memfd, children open the same fd and
# each feed their own slice of measurements into the one shared distribution.
# The parent reads combined percentiles -- a fleet of workers building a single
# latency summary with no coordination beyond the shared mapping.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::DDSketch::Shared;
$| = 1;

my $kids = 4;
my $per  = 250_000;

my $dd = Data::DDSketch::Shared->new_memfd('ddsketch-demo', 0.01);
my $fd = $dd->memfd;
printf "parent: created sketch (alpha=%.2f) via memfd fd=%d\n", $dd->alpha, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # the memfd fd is inherited across fork; reopen it to share the buckets
        my $child = Data::DDSketch::Shared->new_from_fd($fd);
        my $seed = 1000 + $c * 7919;
        for (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $ms = -25 * log(1 - $seed / 0x7fffffff);
            $child->add($ms);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: after %d children fed %d each, count=%d\n\n", $kids, $per, $dd->count;
printf "min  %.3f ms   mean %.3f ms   max %.3f ms\n\n", $dd->min, $dd->mean, $dd->max;
for my $q (0.5, 0.9, 0.99, 0.999) {
    printf "p%-5s %.3f ms\n", $q * 100, $dd->quantile($q);
}
