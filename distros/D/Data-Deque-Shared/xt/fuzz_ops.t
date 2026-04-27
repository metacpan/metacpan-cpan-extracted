use strict;
use warnings;
use Test::More;
use Data::Deque::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Random double-ended ops against a Perl array oracle.
my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 10_000;
my $cap = 64;
my $d = Data::Deque::Shared::Int->new(undef, $cap);
my @oracle;

for my $i (1..$N) {
    my $r = rand;
    if ($r < 0.25 && @oracle < $cap) {
        my $v = int(rand 1_000_000);
        if ($d->push_back($v)) { push @oracle, $v }
    } elsif ($r < 0.50 && @oracle < $cap) {
        my $v = int(rand 1_000_000);
        if ($d->push_front($v)) { unshift @oracle, $v }
    } elsif ($r < 0.70) {
        my $got = $d->pop_front;
        my $exp = shift @oracle;
        if (($got // 'U') ne ($exp // 'U')) {
            fail "pop_front mismatch iter $i";
            done_testing; exit;
        }
    } elsif ($r < 0.90) {
        my $got = $d->pop_back;
        my $exp = pop @oracle;
        if (($got // 'U') ne ($exp // 'U')) {
            fail "pop_back mismatch iter $i";
            done_testing; exit;
        }
    } elsif ($r < 0.99) {
        my $size = $d->size;
        if ($size != scalar @oracle) {
            fail "size mismatch iter $i: got=$size expected=" . scalar @oracle;
            done_testing; exit;
        }
    } else {
        $d->drain;
        @oracle = ();
    }
}

pass "$N random ops completed";
is $d->size, scalar(@oracle), 'final sizes match';
done_testing;
