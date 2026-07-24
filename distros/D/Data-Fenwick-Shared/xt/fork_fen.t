use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Fenwick::Shared;

# Anonymous MAP_SHARED tree inherited across fork: children update DISJOINT
# position ranges concurrently (contending on the shared int64 tree under the
# rwlock), and the parent must see every update -- no lost updates cross-process.
my $kids = 4;
my $per  = 25_000;
my $n    = $kids * $per;
my $f = Data::Fenwick::Shared->new(undef, $n);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = $k * $per;
        $f->update($base + $_, 1) for 1 .. $per;   # disjoint range per child
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $f->total, $n, "cross-process: all $n updates present (no lost updates)";
my $bad = 0;
for my $k (0 .. $kids - 1) {
    $bad++ if $f->range($k * $per + 1, ($k + 1) * $per) != $per;
}
is $bad, 0, 'each child range sums to exactly its update count';

# shared positions: all children increment the SAME positions -> exact accumulation
{
    my $g = Data::Fenwick::Shared->new(undef, 10);   # before fork
    my @cp;
    for my $k (0 .. $kids - 1) {
        my $pid = fork // die "fork: $!";
        if (!$pid) { for (1 .. 1000) { $g->update(3, 1); $g->update(7, 1) } _exit(0) }
        push @cp, $pid;
    }
    waitpid $_, 0 for @cp;
    is $g->point(3), $kids * 1000, 'cross-process shared-position accumulation (pos 3)';
    is $g->point(7), $kids * 1000, 'cross-process shared-position accumulation (pos 7)';
}

done_testing;
