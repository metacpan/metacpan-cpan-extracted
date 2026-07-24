use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Fenwick::Shared;

# A child cannot finish a 2M-update storm in 50ms; SIGKILL it mid-storm while it
# may hold the write lock, then verify the parent can still take the write lock
# and update -- the futex rwlock's dead-owner recovery over the shared int64
# tree. The anonymous MAP_SHARED mapping is inherited across fork.
my $h = Data::Fenwick::Shared->new(undef, 2_000_000);
my $pid = fork // die $!;
if (!$pid) { $h->update(($_ % 2_000_000) + 1, 1) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->update(1, 7) };
ok !$@, 'update after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{total}), 'stats reachable (lock not stranded)';
cmp_ok $h->point(1), '>=', 7, 'the post-crash update took effect';

done_testing;
