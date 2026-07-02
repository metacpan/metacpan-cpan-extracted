use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::NDArray::Shared;

# A child cannot finish 2M write-locked fills in 50ms; SIGKILL it mid-storm while
# it may hold the write lock, then verify the parent can still take the write lock
# and mutate -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED
# mapping is inherited across fork.
my $h = Data::NDArray::Shared->new(undef, "i64", 1000);
my $pid = fork // die $!;
if (!$pid) { $h->fill($_ & 0x7f) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->fill(42) };
ok !$@, 'mutate after child SIGKILL (write-lock dead-owner recovery)';
ok defined $h->stats->{size}, 'stats reachable (lock not stranded)';
is $h->sum, 42 * 1000, 'last fill took effect (every element == 42)';

done_testing;
