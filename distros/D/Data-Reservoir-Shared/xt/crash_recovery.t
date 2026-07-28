use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Reservoir::Shared;

# A child cannot finish a 2M-item feed storm in 50ms; SIGKILL it mid-storm while
# it may hold the write lock, then verify the parent can still take the write
# lock and add -- the futex rwlock's dead-owner recovery over the shared slots.
my $h = Data::Reservoir::Shared->new(undef, 100, 32);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{seen}), 'stats reachable (lock not stranded)';
cmp_ok $h->count, '>', 0, 'reservoir has items after recovery';

done_testing;
