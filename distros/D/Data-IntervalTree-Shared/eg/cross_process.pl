#!/usr/bin/env perl
# Cross-process: parent builds an interval tree via memfd, children open the same
# fd and each add their own block of intervals into the one shared index.  The
# parent then queries the combined set -- a fleet of workers populating a single
# interval index, rebuilt once on the first query.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::IntervalTree::Shared;
$| = 1;

my $kids = 4;
my $per  = 25_000;
my $cap  = $kids * $per;

my $it = Data::IntervalTree::Shared->new_memfd('intervaltree-demo', $cap);
my $fd = $it->memfd;
printf "parent: created interval tree (capacity %d) via memfd fd=%d\n", $it->capacity, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::IntervalTree::Shared->new_from_fd($fd);
        my $seed = 1000 + $c * 7919;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $lo = $seed % 1_000_000;
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $len = $seed % 1000;
            $child->add($lo, $lo + $len, $c * $per + $i);   # globally unique id
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: after %d children added %d intervals each, count=%d\n\n", $kids, $per, $it->count;

my $p = 500_000;
printf "intervals containing point %d: %d\n", $p, scalar $it->stab($p);
printf "intervals overlapping [%d, %d]: %d\n", 499_000, 501_000, scalar(my @o = $it->overlaps(499_000, 501_000));
