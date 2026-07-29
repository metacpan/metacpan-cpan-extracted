#!/usr/bin/env perl
# Cross-process: parent builds a top-k summary via memfd, children open the same
# fd and each feed a slice of the stream into the one shared set of counters.
# The heavy hitters are recovered from the merged summary regardless of which
# worker saw which records.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::TopK::Shared;
$| = 1;

my $capacity = 64;
my $kids     = 4;
my $per      = 50_000;

my $tk = Data::TopK::Shared->new_memfd('topk-demo', $capacity);
my $fd = $tk->memfd;
printf "parent: created top-k (capacity %d) via memfd fd=%d\n", $tk->capacity, $fd;

my @hot = map { "hot-$_" } 1 .. 5;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # the memfd fd is inherited across fork; reopen it to share the counters
        my $child = Data::TopK::Shared->new_from_fd($fd);
        my $seed = 1000 + $c;
        for (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $r = $seed / 0x7fffffff;
            my $key = $r < 0.5 ? $hot[ int($r * 2 * @hot) % @hot ]
                               : "cold-" . int($r * 1e6);
            $child->add($key);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: after %d children fed %d each, seen=%d tracked=%d\n\n",
    $kids, $per, $tk->seen, $tk->tracked;

printf "%-10s %10s %8s\n", "key", "est", "error";
for my $h ($tk->top(8)) {
    printf "%-10s %10d %8d\n", $h->{key}, $h->{count}, $h->{error};
}
