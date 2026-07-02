use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::BloomFilter::Shared;

# A child cannot finish a 2M-item add storm in 50ms; SIGKILL it mid-storm while it
# may hold the write lock, then verify the parent can still take the write lock and
# add -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping is
# inherited across fork, so parent and child contend on the one shared bit array.
my $h = Data::BloomFilter::Shared->new(undef, 2_000_000, 0.01);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{count}), 'stats reachable (lock not stranded)';
ok $h->contains("after-the-crash"), 'the post-crash add took effect (no false negative)';

done_testing;
