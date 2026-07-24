use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::DDSketch::Shared;

# A child cannot finish a 2M-value feed storm in 50ms; SIGKILL it mid-storm while
# it may hold the write lock, then verify the parent can still take the write lock
# and add -- the futex rwlock's dead-owner recovery.  The anonymous MAP_SHARED
# mapping is inherited across fork, so parent and child contend on the one sketch.
my $h = Data::DDSketch::Shared->new(undef, 0.01);
my $pid = fork // die $!;
if (!$pid) { $h->add($_ % 1000 + 1) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

my $before = $h->count;
eval { $h->add(12345) };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{count}), 'stats reachable (lock not stranded)';
cmp_ok $h->count, '>', $before, 'the post-crash add took effect';
ok defined($h->quantile(0.5)), 'quantile reachable after recovery';

done_testing;
