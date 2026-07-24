use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::MinHash::Shared;

# A child cannot finish a 2M-element fold storm in 50ms; SIGKILL it mid-storm
# while it may hold the write lock, then verify the parent can still take the
# write lock and add -- the futex rwlock's dead-owner recovery.  The anonymous
# MAP_SHARED mapping is inherited across fork, so parent and child contend on
# the one shared register array.
my $h = Data::MinHash::Shared->new(undef, 4096);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{filled}), 'stats reachable (lock not stranded)';
cmp_ok $h->filled, '>', 0, 'sketch has folded elements after recovery';

done_testing;
