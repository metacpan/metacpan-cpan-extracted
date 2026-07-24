use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Fenwick2D::Shared;

# A child cannot finish a 2M-update storm in 50ms; SIGKILL it mid-storm while it
# may hold the write lock, then verify the parent can still take the write lock
# and update -- the futex rwlock's dead-owner recovery over the shared int64
# grid.  The anonymous MAP_SHARED mapping is inherited across fork.
my ($R, $C) = (2000, 1000);   # 2M cells
my $h = Data::Fenwick2D::Shared->new(undef, $R, $C);
my $pid = fork // die $!;
if (!$pid) {
    my $s = 1;
    for (1 .. 2_000_000) {
        $s = ($s * 1103515245 + 12345) & 0x7fffffff;
        $h->update(1 + ($s % $R), 1 + (($s >> 8) % $C), 1);
    }
    exit 0;
}
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->update(1, 1, 7) };
ok !$@, 'update after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{total}), 'stats reachable (lock not stranded)';
cmp_ok $h->point(1, 1), '>=', 7, 'the post-crash update took effect';

done_testing;
