use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Under heavy concurrent push/pop, RELAXED stat updates could in principle
# lose increments due to compiler/CPU reordering or simply from bugs.
# Verify reported counters are within 5% of observed ground truth.

my $N_WORKERS = 8;
my $PER       = 10_000;
my $q = Data::Queue::Shared::Int->new(undef, 256);

my @pids;
for my $w (1..$N_WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        if ($w <= $N_WORKERS / 2) {
            for (1..$PER) { while (!$q->push($_)) { } }
        } else {
            my $got = 0;
            while ($got < $PER) { defined $q->pop and $got++ }
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

my $expected = ($N_WORKERS / 2) * $PER;
my $s = $q->stats;

# After waitpid, all child RELAXED stores are visible to the parent
# via the kernel's process-exit barrier through MAP_SHARED. Stats
# should match exactly — no tolerance band needed.
is $s->{push_ok}, $expected, "push_ok matches exactly under contention";
is $s->{pop_ok},  $expected, "pop_ok matches exactly under contention";

is $q->size, 0, 'queue drained at end';

done_testing;
