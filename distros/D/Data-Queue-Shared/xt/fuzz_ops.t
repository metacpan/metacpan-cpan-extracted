use strict;
use warnings;
use Test::More;

# Operation fuzzing: random sequences of push/pop/peek/size against a
# Str queue with mixed sizes. Seeded for reproducibility. Passes if
# the queue invariant (push-then-pop FIFO, size matches, no crash)
# holds across N random operations.

use Data::Queue::Shared::Str;

my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 10_000;

my $q = Data::Queue::Shared::Str->new_memfd("fuzz", 128, 16384);

my @oracle;   # reference queue
my $ops = { push => 0, pop => 0, size => 0, clear => 0 };

for my $i (1..$N) {
    my $r = rand;
    if ($r < 0.5 && @oracle < 120) {
        my $len = int(rand(256)) + 1;
        my $val = join '', map chr(int rand 90 + 32), 1..$len;
        if ($q->push($val)) {
            push @oracle, $val;
            $ops->{push}++;
        }
    } elsif ($r < 0.85) {
        my $got = $q->pop;
        my $exp = shift @oracle;
        if (defined $got || defined $exp) {
            if (($got // '') ne ($exp // '')) {
                fail "FIFO mismatch iteration $i: got=" . (defined $got ? "'$got'" : 'undef') .
                     " expected=" . (defined $exp ? "'$exp'" : 'undef');
                done_testing; exit;
            }
            $ops->{pop}++;
        }
    } elsif ($r < 0.99) {
        my $s = $q->size;
        if ($s != scalar @oracle) {
            fail "size mismatch iteration $i: got=$s expected=" . scalar @oracle;
            done_testing; exit;
        }
        $ops->{size}++;
    } else {
        $q->clear;
        @oracle = ();
        $ops->{clear}++;
    }
}

pass "$N random operations: " . join(', ', map "$_=$ops->{$_}", sort keys %$ops);

# Drain remaining and verify final equality
while (@oracle) {
    my $got = $q->pop;
    my $exp = shift @oracle;
    is $got, $exp, "final-drain FIFO (oracle " . scalar(@oracle) . " left)";
}

is $q->size, 0, "queue fully drained";

done_testing;
