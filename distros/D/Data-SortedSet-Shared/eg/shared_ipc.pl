#!/usr/bin/env perl
# Cross-process leaderboard. A producer process feeds scores into a fork-shared
# set and rings an eventfd after each batch; the consumer blocks on that eventfd
# and prints the running top-3. Shows anonymous-mmap sharing + eventfd wakeups.
use strict;
use warnings;
use POSIX qw(WNOHANG);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SortedSet::Shared;

my $z = Data::SortedSet::Shared->new(undef, 100_000);
$z->eventfd;                                   # notification fd, inherited across fork

my $pid = fork // die "fork: $!";
if (!$pid) {                                   # ---- producer ----
    srand(1);
    for (1 .. 5) {
        $z->add(int(rand(1000)), int(rand(10_000))) for 1 .. 200;
        $z->notify;                            # wake the consumer
        select undef, undef, undef, 0.05;
    }
    exit 0;
}

# ---- consumer: react to each notify, stop once the producer has exited ----
while (1) {
    vec(my $rin = '', $z->fileno, 1) = 1;
    if (select(my $r = $rin, undef, undef, 0.5)) {
        $z->eventfd_consume;                   # clear the counter
        my @top = $z->rev_range_by_rank(0, 2, withscores => 1);
        printf "%5d players; top: %s\n", $z->count,
            join(', ', map { "$top[2*$_]=$top[2*$_+1]" } 0 .. $#top / 2);
    }
    last if waitpid($pid, WNOHANG) == $pid;    # producer finished
}
