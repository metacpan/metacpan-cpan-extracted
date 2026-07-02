use strict;
use warnings;
use Test::More;
use Data::DisjointSet::Shared;

# Deterministic checks. No RNG, no sleep: a fixed arithmetic sequence of unions
# applied to both the XS structure and a pure-Perl reference union-find must
# leave them in agreement on num_sets and on connectivity for a sample of pairs.

my $N = 1000;

# ---- pure-Perl reference union-find (plain quick-union + union by size) ----
my @parent = (0 .. $N - 1);
my @size   = (1) x $N;
my $sets   = $N;

sub ref_find {
    my ($x) = @_;
    $x = $parent[$x] while $parent[$x] != $x;   # find root (no compression needed for the reference)
    return $x;
}
sub ref_union {
    my ($a, $b) = @_;
    my $ra = ref_find($a);
    my $rb = ref_find($b);
    return 0 if $ra == $rb;
    ($ra, $rb) = ($rb, $ra) if $size[$ra] < $size[$rb];
    $parent[$rb] = $ra;
    $size[$ra] += $size[$rb];
    $sets--;
    return 1;
}
sub ref_connected { ref_find($_[0]) == ref_find($_[1]) }

# ---- apply the SAME fixed sequence of ~2000 unions to both ----
my $d = Data::DisjointSet::Shared->new(undef, $N);

my $xs_merges  = 0;
my $ref_merges = 0;
for my $i (0 .. 1999) {
    my $a = $i % $N;
    my $b = ($i * 7 + 3) % $N;     # fixed deterministic partner
    $xs_merges  += $d->union($a, $b);
    $ref_merges += ref_union($a, $b);
    # check agreement on the running set count after each union
    if ($d->num_sets != $sets) {
        is $d->num_sets, $sets, "num_sets diverged at step $i";
        last;
    }
}

# (a) num_sets and the merge counts must match the reference exactly
is $d->num_sets, $sets, 'XS num_sets matches the reference set count';
is $xs_merges, $ref_merges, 'XS and reference performed the same number of merges';

# (a, cont.) connectivity matches the reference for a deterministic sample of pairs
{
    my $mismatch = 0;
    for my $a (0 .. $N - 1) {
        # sample a handful of partners per element, deterministically
        for my $off (1, 7, 13, 100, 499) {
            my $b = ($a + $off) % $N;
            my $xs  = $d->connected($a, $b) ? 1 : 0;
            my $rf  = ref_connected($a, $b) ? 1 : 0;
            $mismatch++ if $xs != $rf;
        }
    }
    is $mismatch, 0, 'connected() matches the reference for every sampled pair';
}

# (b) set_size over distinct roots sums to N: the partition covers every element
#     exactly once.
{
    my %seen_root;
    my $sum = 0;
    for my $x (0 .. $N - 1) {
        my $r = $d->find($x);
        next if $seen_root{$r}++;     # count each set once, via its root
        $sum += $d->set_size($r);
    }
    is $sum, $N, 'sum of set_size over distinct roots == N (partition is exact)';

    # the number of distinct roots must equal num_sets
    is scalar(keys %seen_root), $d->num_sets, 'distinct-root count == num_sets';
}

# (c) connected is an equivalence relation on a sample:
#     reflexive, symmetric, and transitive.
{
    my @sample = (0, 1, 2, 3, 7, 50, 123, 499, 500, 777, 998, 999);

    my $reflexive_bad = 0;
    $reflexive_bad++ for grep { !$d->connected($_, $_) } @sample;
    is $reflexive_bad, 0, 'connected is reflexive on the sample';

    my $symmetric_bad = 0;
    for my $a (@sample) {
        for my $b (@sample) {
            $symmetric_bad++ if ($d->connected($a, $b) ? 1 : 0) != ($d->connected($b, $a) ? 1 : 0);
        }
    }
    is $symmetric_bad, 0, 'connected is symmetric on the sample';

    my $transitive_bad = 0;
    for my $a (@sample) {
        for my $b (@sample) {
            next unless $d->connected($a, $b);
            for my $c (@sample) {
                # a~b and b~c  =>  a~c
                $transitive_bad++ if $d->connected($b, $c) && !$d->connected($a, $c);
            }
        }
    }
    is $transitive_bad, 0, 'connected is transitive on the sample';
}

# (c, cont.) find is idempotent and all members of a set share the root's size.
{
    my $bad = 0;
    for my $x (0 .. $N - 1) {
        my $r = $d->find($x);
        $bad++ unless $d->find($r) == $r;                 # root is its own root
        $bad++ unless $d->set_size($x) == $d->set_size($r); # members share the set size
    }
    is $bad, 0, 'find is idempotent on roots and set_size is consistent within a set';
}

done_testing;
