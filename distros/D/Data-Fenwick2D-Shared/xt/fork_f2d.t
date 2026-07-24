use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Fenwick2D::Shared;

# Anonymous MAP_SHARED grid inherited across fork: each child updates a DISJOINT
# block of rows concurrently (contending on the shared int64 grid under the
# rwlock), and the parent must see every update -- no lost updates cross-process.
my $kids     = 4;
my $rows_per = 20;
my $R        = $kids * $rows_per;
my $C        = 30;
my $per      = 500;                 # updates per child
my $f = Data::Fenwick2D::Shared->new(undef, $R, $C);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $r0   = $k * $rows_per;
        my $seed = $k + 1;
        for (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $x = $r0 + 1 + ($seed % $rows_per);        # within this child's row block
            my $y = 1 + (($seed >> 8) % $C);
            $f->update($x, $y, 1);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $f->total, $kids * $per, "cross-process: all updates present (no lost updates)";
my $bad = 0;
for my $k (0 .. $kids - 1) {
    my $r1 = $k * $rows_per + 1;
    my $r2 = ($k + 1) * $rows_per;
    $bad++ if $f->rect($r1, 1, $r2, $C) != $per;          # each child's block sums to its count
}
is $bad, 0, 'each child row-block sums to exactly its update count';

# shared cells: all children increment the SAME cells -> exact accumulation
{
    my $g = Data::Fenwick2D::Shared->new(undef, 10, 10);
    my @cp;
    for my $k (0 .. $kids - 1) {
        my $pid = fork // die "fork: $!";
        if (!$pid) { for (1 .. 1000) { $g->update(3, 4, 1); $g->update(7, 8, 1) } _exit(0) }
        push @cp, $pid;
    }
    waitpid $_, 0 for @cp;
    is $g->point(3, 4), $kids * 1000, 'cross-process shared-cell accumulation (3,4)';
    is $g->point(7, 8), $kids * 1000, 'cross-process shared-cell accumulation (7,8)';
}

done_testing;
