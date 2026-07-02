use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::HyperLogLog::Shared;

# A child cannot finish 2M adds in 50ms; SIGKILL it mid-storm while it may hold the
# write lock, then verify the parent can still take the write lock and add -- the
# futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping is inherited
# across fork.
my $h = Data::HyperLogLog::Shared->new(undef, 14);
my $pid = fork // die $!;
if (!$pid) { $h->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $h->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{ops}), 'stats reachable (lock not stranded)';
ok $h->count > 0, 'estimate reflects completed adds after recovery';

done_testing;
