use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::TopK::Shared;

# A child cannot finish a 2M-observation feed storm in 50ms; SIGKILL it mid-storm
# while it may hold the write lock, then verify the parent can still take the
# write lock and add -- the futex rwlock's dead-owner recovery.  The anonymous
# MAP_SHARED mapping is inherited across fork, so parent and child contend on the
# one shared summary.
my $h = Data::TopK::Shared->new(undef, 64);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{seen}), 'stats reachable (lock not stranded)';
cmp_ok $h->seen, '>', 0, 'summary has observations after recovery';
# the summary is full after the storm, so the new key enters by eviction and
# inherits the victim's count -- what matters is that the add took effect at all
cmp_ok $h->estimate("after-the-crash"), '>', 0, 'the post-crash add took effect (key now tracked)';

done_testing;
