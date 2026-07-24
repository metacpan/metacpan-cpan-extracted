#!/usr/bin/env perl
# Cross-process: parent builds a sketch via memfd, children open the same fd and
# each fold a disjoint slice of one big set into the shared registers.  Because
# a MinHash register only ever moves down to a smaller value, concurrent folds
# commute -- the final sketch is exactly the sketch of the whole set, no matter
# how the work was split or interleaved across processes.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::MinHash::Shared;
$| = 1;

my $k    = 256;
my $kids = 4;
my $per  = 50_000;                 # each child folds this many elements

my $mh = Data::MinHash::Shared->new_memfd('minhash-demo', $k);
my $fd = $mh->memfd;
printf "parent: created sketch k=%d via memfd fd=%d\n", $mh->size, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # the memfd fd is inherited across fork; reopen it to share the registers
        my $child = Data::MinHash::Shared->new_from_fd($fd);
        my $lo = $c * $per + 1;
        $child->add("e$_") for $lo .. $lo + $per - 1;   # disjoint slice
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# compare the collaboratively-built sketch against one process folding the whole
# set: they must estimate similarity ~1.0 (they are the same set)
my $ref = Data::MinHash::Shared->new(undef, $k);
$ref->add("e$_") for 1 .. $kids * $per;

printf "parent: after %d children, %d/%d registers filled\n",
    $kids, $mh->filled, $mh->size;
printf "parent: similarity(shared, single-process reference) = %.4f (expect ~1.0)\n",
    $mh->similarity($ref);
