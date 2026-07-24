use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::IntervalTree::Shared;

# A child cannot finish adding 2M intervals in 50ms; SIGKILL it mid-storm while
# it may hold the write lock, then verify the parent can still take the write
# lock and add -- the futex rwlock's dead-owner recovery.  The anonymous
# MAP_SHARED mapping is inherited across fork, so parent and child contend on the
# one index.
my $h = Data::IntervalTree::Shared->new(undef, 3_000_000);
my $pid = fork // die $!;
if (!$pid) { my $s = 1; for (1 .. 2_000_000) { $s = ($s * 1103515245 + 12345) & 0x7fffffff; my $lo = $s % 1_000_000; $h->add($lo, $lo + 50) } exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

my $before = $h->count;
my $idx = eval { $h->add(500_000, 500_100, 999) };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{count}), 'stats reachable (lock not stranded)';
cmp_ok $h->count, '>', $before, 'the post-crash add took effect';
# a query after recovery must rebuild a balanced tree and find the interval we added
my @at = eval { $h->stab(500_050) };
ok !$@, 'query after recovery rebuilds and runs';
ok +(grep { $_->{id} == 999 } @at), 'the post-crash interval is found by the query';

done_testing;
