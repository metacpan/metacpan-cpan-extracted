use strict;
use warnings;
use Test::More;
use Data::MinHash::Shared;

# ----------------------------------------------------------------------------
# b-bit MinHash: estimate Jaccard from only the low b bits of each register,
# and export a compact packed signature.
# ----------------------------------------------------------------------------

my $k = 1024;

# build a sketch over a set of integers
sub sketch { my $s = Data::MinHash::Shared->new(undef, $k); $s->add($_) for @_; $s }

# set pairs with a known true Jaccard
my @cases = (
    [ 'disjoint',  [1 .. 1000], [1001 .. 2000], 0.0     ],
    [ 'third',     [1 .. 1000], [ 501 .. 1500], 1/3     ],
    [ 'sixty',     [1 ..  800], [ 201 .. 1000], 0.6     ],
    [ 'identical', [1 .. 1000], [1    .. 1000], 1.0     ],
);

# ---- b-bit estimate tracks the true Jaccard across b ----
for my $c (@cases) {
    my ($name, $sa, $sb, $J) = @$c;
    my $A = sketch(@$sa);
    my $B = sketch(@$sb);
    for my $b (2, 4, 8, 16, 64) {
        my $est = $A->bbit_similarity($B, $b);
        cmp_ok abs($est - $J), '<', 0.08, "$name b=$b: est $est ~ J=$J";
    }
    # b=64 masks all bits -> exactly the plain similarity
    cmp_ok abs($A->bbit_similarity($B, 64) - $A->similarity($B)), '<', 1e-12,
        "$name: b=64 equals plain similarity";
}

# ---- self-similarity is 1 for every b ----
{
    my $A = sketch(1 .. 500);
    cmp_ok abs($A->bbit_similarity($A, 1)  - 1), '<', 1e-9, 'self bbit b=1 == 1';
    cmp_ok abs($A->bbit_similarity($A, 8)  - 1), '<', 1e-9, 'self bbit b=8 == 1';
}

# ---- signature: correct length, and round-trips exactly vs the live compare ----
{
    my $A = sketch(1 .. 800);
    my $B = sketch(201 .. 1000);
    for my $b (1, 2, 4, 8, 16, 32, 64) {
        my $sa = $A->bbit_signature($b);
        my $sb = $B->bbit_signature($b);
        is length($sa), int(($k * $b + 7) / 8), "b=$b signature length = ceil(k*b/8)";
        my $live = $A->bbit_similarity($B, $b);
        my $sig  = Data::MinHash::Shared->bbit_similarity_of($sa, $sb, $k, $b);
        cmp_ok abs($live - $sig), '<', 1e-12, "b=$b: signature compare == live compare";
    }
    # a b=1 signature is 64x smaller than the full 8-bytes-per-register sketch
    cmp_ok length($A->bbit_signature(1)), '<', $k * 8 / 8, 'b=1 signature is far smaller than the full sketch';
}

# ---- error handling ----
{
    my $A = sketch(1 .. 10);
    my $B = sketch(1 .. 10);
    eval { $A->bbit_similarity($B, 0)  }; like $@, qr/between 1 and 64/, 'b=0 croaks';
    eval { $A->bbit_similarity($B, 65) }; like $@, qr/between 1 and 64/, 'b=65 croaks';
    eval { $A->bbit_signature(0) };       like $@, qr/between 1 and 64/, 'signature b=0 croaks';

    my $C = Data::MinHash::Shared->new(undef, $k * 2);   # different register count
    eval { $A->bbit_similarity($C, 4) };  like $@, qr/register-count mismatch/, 'k mismatch croaks';

    eval { Data::MinHash::Shared->bbit_similarity_of("x", "y", $k, 8) };
    like $@, qr/too short/, 'short signature croaks';
    eval { Data::MinHash::Shared->bbit_similarity_of("", "", 0, 8) };
    like $@, qr/k must be/, 'k=0 in bbit_similarity_of croaks';
    eval { Data::MinHash::Shared->bbit_similarity_of("x" x 8, "y" x 8, 2**58, 64) };
    like $@, qr/2\^24|<= 16777216/, 'oversized k croaks instead of overflowing k*b (no OOB read)';
}

# ---- cross-process: signature exported by one handle compares via another ----
{
    my $A = Data::MinHash::Shared->new_memfd("bbit-demo", $k);
    $A->add($_) for 1 .. 500;
    my $sig_a = $A->bbit_signature(4);
    my $fd = $A->memfd;
  SKIP: {
        skip "no memfd", 1 unless defined $fd && $fd >= 0;
        my $A2 = Data::MinHash::Shared->new_from_fd($fd);
        my $sig_a2 = $A2->bbit_signature(4);
        is $sig_a2, $sig_a, 'same sketch via another handle exports the same b-bit signature';
    }
}

done_testing;
