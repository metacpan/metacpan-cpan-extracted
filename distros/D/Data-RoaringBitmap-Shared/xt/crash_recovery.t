use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::RoaringBitmap::Shared;

# A child cannot finish a 2M-add storm in 50ms; SIGKILL it mid-storm while it may
# hold the write lock, then verify the parent can still take the write lock and
# add -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping
# is inherited across fork. The value range is bounded to ~8 high-16 buckets
# (<= 8 of the 256 container slots) so the storm UPDATES the same handful of
# containers rather than exhausting the finite pool: the wrapped re-adds are
# no-ops but each still takes the write lock, giving SIGKILL a wide window to land
# while the lock is held.
my $h = Data::RoaringBitmap::Shared->new(undef, 256);
my $pid = fork // die $!;
if (!$pid) { $h->add($_ % 500_000) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add(123_456_789) };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok $h->contains(123_456_789), 'the post-crash add took effect';
ok defined $h->stats->{ops}, 'stats reachable (lock not stranded)';

done_testing;
