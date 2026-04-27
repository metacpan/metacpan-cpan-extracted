use strict;
use warnings;
use Test::More;
use Data::Stack::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Random-op fuzzer: compare against a Perl-side oracle LIFO.
my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 10_000;
my $cap = 64;
my $s = Data::Stack::Shared::Int->new(undef, $cap);
my @oracle;

for my $i (1..$N) {
    my $r = rand;
    if ($r < 0.5 && @oracle < $cap) {
        my $v = int(rand 1_000_000);
        if ($s->push($v)) { push @oracle, $v }
    } elsif ($r < 0.85) {
        my $got = $s->pop;
        my $exp = pop @oracle;
        if (($got // 'U') ne ($exp // 'U')) {
            fail "LIFO mismatch iter $i: got=" . ($got // 'undef') .
                 " expected=" . ($exp // 'undef');
            done_testing; exit;
        }
    } elsif ($r < 0.99) {
        my $size = $s->size;
        if ($size != scalar @oracle) {
            fail "size mismatch iter $i: got=$size expected=" . scalar @oracle;
            done_testing; exit;
        }
    } else {
        $s->drain;
        @oracle = ();
    }
}

pass "$N random ops completed";
while (@oracle) {
    is $s->pop, pop(@oracle), "final drain";
}
is $s->size, 0, 'stack drained';

done_testing;
