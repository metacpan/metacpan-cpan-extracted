use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Histogram::Shared;

# A child cannot finish 2M records in 50ms; SIGKILL it mid-storm while it may hold
# the write lock, then verify the parent can still take the write lock and record
# -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED mapping is
# inherited across fork, so parent and child contend on the one counts array.
my $h = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
my $pid = fork // die $!;
if (!$pid) { $h->record(1 + ($_ % 1_000_000)) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;   # 50ms -- the child is still storming
kill 'KILL', $pid;
waitpid $pid, 0;

my $total = eval { $h->record(500) };
ok !$@, 'record after child SIGKILL (write-lock dead-owner recovery)';
ok defined $h->stats->{count}, 'stats reachable (lock not stranded)';
cmp_ok $total, '>=', 1, 'record returned a total (the mutation took effect)';
cmp_ok $h->max, '>=', 500, 'max reflects the value recorded after recovery';

done_testing;
