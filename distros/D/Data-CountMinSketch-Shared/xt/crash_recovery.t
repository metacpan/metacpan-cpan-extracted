use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::CountMinSketch::Shared;

# A child cannot finish 2M adds in 50ms; SIGKILL it mid-storm while it may hold
# the write lock, then verify the parent can still take the write lock and add --
# the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping is
# inherited across fork. The sketch is fixed-size, so the unbounded key space
# only updates counters (it never grows), leaving the storm a pure stream of
# write-lock acquisitions for the SIGKILL to land inside of.
my $h = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{total}), 'stats reachable (lock not stranded)';
cmp_ok $h->estimate("after-the-crash"), '>=', 1, 'the post-crash add took effect';

done_testing;
