use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::DisjointSet::Shared;

# A child cannot finish 2M unions in 50ms; SIGKILL it mid-storm while it may hold
# the write lock, then verify the parent can still take the write lock and mutate
# -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping is
# inherited across fork, and the bounded key space (indices mod capacity) keeps
# every operand in range so the storm only ever UPDATES the partition, it never
# croaks for a reason other than the SIGKILL.
my $h = Data::DisjointSet::Shared->new(undef, 100_000);
my $pid = fork // die $!;
if (!$pid) { $h->union($_ % 100_000, ($_ + 7) % 100_000) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->union(1, 2) };
ok !$@, 'mutate after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{sets}), 'stats reachable';
ok $h->connected(1, 2), 'union took effect after recovery';

done_testing;
