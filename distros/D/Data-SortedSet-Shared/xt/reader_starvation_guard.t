use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# The rwlock is write-preferring: a writer must keep making progress even under
# sustained concurrent read load (no reader starvation, no deadlock).

my $z = Data::SortedSet::Shared->new(undef, 100_000);
$z->add($_, rand() * 1000) for 1 .. 5000;

my $READERS = $ENV{READERS} || 8;
my @pids;
for (1 .. $READERS) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $end = time + 3;
        $z->rank(int(rand(5000)) + 1) while time < $end;   # hammer the read lock
        _exit(0);
    }
    push @pids, $pid;
}

my $WRITES = 2000;
my $t0 = time;
$z->incr(1, 1) for 1 .. $WRITES;          # re-score under the write lock; stalls if starved
my $dt = time - $t0;

kill 'TERM', @pids;
waitpid $_, 0 for @pids;

ok 1, "$WRITES writes completed under $READERS concurrent readers (no deadlock)";
cmp_ok $dt, '<', 10, sprintf('writer not starved: %d writes in %.2fs', $WRITES, $dt);
diag sprintf '%.0f writes/s under %d readers', $WRITES / $dt, $READERS;

done_testing;
