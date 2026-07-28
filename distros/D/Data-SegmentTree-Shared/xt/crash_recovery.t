use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SegmentTree::Shared;

# A child cannot finish 2M range_adds in 50ms; SIGKILL it mid-storm while it may
# hold the write lock, then verify the parent can still take the write lock and
# update -- the futex rwlock's dead-owner recovery.  The anonymous MAP_SHARED
# mapping is inherited across fork, so parent and child contend on the one tree.
my $n = 1000;
my $h = Data::SegmentTree::Shared->new(undef, $n);
my $pid = fork // die $!;
if (!$pid) { $h->range_add(0, $n - 1, 1) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

my $before = $h->get(0);
eval { $h->add(0, 1) };
ok !$@, 'update after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{n}), 'stats reachable (lock not stranded)';
is $h->get(0), $before + 1, 'the post-crash update took effect';
ok defined($h->sum(0, $n - 1)), 'range query reachable after recovery';

done_testing;
