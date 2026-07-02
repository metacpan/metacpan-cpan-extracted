use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::CuckooFilter::Shared;

# A child cannot add 2M distinct items in 50ms; SIGKILL it mid-add-storm while it
# may hold the write lock, then verify the parent can still acquire the write lock
# and add -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED
# mapping is inherited across fork. Capacity 2M yields ~4.19M slots, so the storm
# stays well under full: every add stores (returns 1) and nothing croaks, so the
# child can only ever die from the SIGKILL, not a runtime error.
my $cf = Data::CuckooFilter::Shared->new(undef, 2_000_000);
my $pid = fork // die $!;
if (!$pid) { $cf->add("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $cf->add("after-the-crash") };
ok !$@, 'add after child SIGKILL (write-lock dead-owner recovery)';
ok $cf->contains("after-the-crash"), 'parent still adds after child SIGKILL';
ok defined $cf->stats->{count}, 'stats reachable (lock not stranded)';

done_testing;
