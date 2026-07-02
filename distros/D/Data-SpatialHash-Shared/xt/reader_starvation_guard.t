use strict; use warnings; use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

use Data::SpatialHash::Shared;

# The rwlock is write-preferring: a writer must keep making progress even under
# sustained concurrent read load (no reader starvation, no deadlock).

my $s = Data::SpatialHash::Shared->new(undef, 100_000, 0, 1.0);
$s->insert(rand()*1000, rand()*1000, $_) for 1 .. 5000;

my $READERS = $ENV{READERS} || 8;
my @pids;
for (1 .. $READERS) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $end = time + 3;
        $s->query_radius(rand()*1000, rand()*1000, 8) while time < $end;
        _exit(0);
    }
    push @pids, $pid;
}

my $WRITES = 2000;
my $h  = $s->insert(0, 0, -1);
my $t0 = time;
$s->move($h, rand()*1000, rand()*1000) for 1 .. $WRITES;   # if starved, this loop stalls
my $dt = time - $t0;

kill 'TERM', @pids; waitpid($_, 0) for @pids;

ok 1, "$WRITES writes completed under $READERS concurrent readers (no deadlock)";
cmp_ok $dt, '<', 10, sprintf('writer not starved: %d writes in %.2fs', $WRITES, $dt);
diag sprintf '%.0f writes/s under %d readers', $WRITES / $dt, $READERS;

done_testing;
