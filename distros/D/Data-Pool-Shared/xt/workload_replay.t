use strict;
use warnings;
use Test::More;

# Workload trace replay: record every op's args from a deterministic
# random sequence, replay on a fresh pool. Both runs must produce
# identical final state. Provides a reproducer template for future
# failures — if a test fails, FUZZ_SEED pinpoints the trace.

use Data::Pool::Shared;

my $seed = $ENV{FUZZ_SEED} || 42;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 1000;

sub run_trace {
    my $p = Data::Pool::Shared::I64->new_memfd("replay", 128);
    srand $seed;  # reset for deterministic trace

    my @live;
    my @trace;   # (op, arg) pairs
    for (1..$N) {
        my $r = rand;
        if ($r < 0.5 || !@live) {
            my $s = $p->alloc;
            if (defined $s) {
                my $v = int(rand(1e9));
                $p->set($s, $v);
                push @live, [$s, $v];
                push @trace, ['alloc', $s, $v];
            }
        } else {
            my $i = int(rand(@live));
            my ($s, $v) = @{ splice @live, $i, 1 };
            $p->free($s);
            push @trace, ['free', $s, $v];
        }
    }

    # Snapshot state
    my @state;
    for my $s (0 .. $p->capacity - 1) {
        push @state, $p->is_allocated($s) ? [$s, $p->get($s)] : ();
    }
    return (\@state, \@trace);
}

my ($state1, $trace1) = run_trace();
my ($state2, $trace2) = run_trace();

is_deeply $state2, $state1,
    "identical final state on second replay with same seed";
is_deeply $trace2, $trace1, "trace recorded deterministically";

cmp_ok scalar(@$trace1), '==', $N, "full $N-op trace";

done_testing;
