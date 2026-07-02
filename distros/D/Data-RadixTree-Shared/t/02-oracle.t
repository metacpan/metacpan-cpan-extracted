use strict;
use warnings;
use Test::More;
use Data::RadixTree::Shared;

# Deterministic oracle. No RNG, no sleep: a fixed set of byte-string keys is
# inserted into both the XS radix tree and a pure-Perl reference (a plain hash
# plus a brute-force longest-prefix scan). For every key, lookup()/exists() must
# match the hash; for a sample of probe strings, longest_prefix() must match a
# brute-force "longest stored key that is a prefix of the probe" scan. Then half
# the keys are deleted and everything is re-verified.

# Generous capacities so the oracle never hits exhaustion.
my $t = Data::RadixTree::Shared->new(undef, 200_000, 4_000_000);

# ---- build ~2000 deterministic keys with shared prefixes ----
my %ref;   # the reference: key -> value

my $val = 0;
# (1) "keyNNNN" -- a flat family sharing the "key" prefix
for my $i (0 .. 999) {
    my $k = sprintf "key%04d", $i;
    $val = ($i * 2654435761 + 12345) % 1_000_000 + 1;   # deterministic non-zero value
    $ref{$k} = $val;
}
# (2) dotted-decimal "10.a.b.c" -- heavy shared-prefix structure (routing-table-like)
for my $i (0 .. 999) {
    my $a = $i % 8;
    my $b = ($i * 3) % 16;
    my $c = ($i * 7) % 32;
    my $k = "10.$a.$b.$c";
    $val = ($i * 40503 + 7) % 1_000_000 + 1;
    $ref{$k} = $val;   # later i wins on a collision -- matches insert's update semantics
}
# (3) a few explicit nested prefixes to exercise longest_prefix backoff
for my $k (qw(10 10.0 10.0.0 192 192.168 192.168.0)) {
    $val = (length($k) * 111 + 1);
    $ref{$k} = $val;
}

# insert every reference key into the XS tree (insert in a sorted, deterministic
# order; the later-wins collisions above are already resolved in %ref).
my @keys = sort keys %ref;
for my $k (@keys) {
    $t->insert($k, $ref{$k});
}

# ---- (a) count matches the number of distinct keys ----
is $t->count, scalar(keys %ref), 'count == number of distinct reference keys';

# ---- (b) lookup() and exists() match the reference for every key ----
{
    my ($lk_bad, $ex_bad) = (0, 0);
    for my $k (@keys) {
        my $got = $t->lookup($k);
        $lk_bad++ unless defined($got) && $got == $ref{$k};
        $ex_bad++ unless $t->exists($k);
    }
    is $lk_bad, 0, 'lookup() matches the reference for every stored key';
    is $ex_bad, 0, 'exists() is true for every stored key';
}

# ---- (b cont.) a sample of NON-keys are absent ----
{
    my $bad = 0;
    for my $k (qw(ke key key10000 10. 10.0.0.0.0 192.168.0.0 nope zzzzz), "key0001x") {
        next if exists $ref{$k};
        $bad++ if $t->exists($k);
        $bad++ if defined $t->lookup($k);
    }
    is $bad, 0, 'a sample of non-keys are absent (exists false, lookup undef)';
}

# ---- (c) longest_prefix matches a brute-force scan for a sample of probes ----
sub ref_longest_prefix {
    my ($q) = @_;
    my ($best_len, $best_val) = (-1, undef);
    for my $k (keys %ref) {
        next if length($k) > length($q);
        next unless substr($q, 0, length $k) eq $k;   # $k is a prefix of $q
        if (length($k) > $best_len) { $best_len = length $k; $best_val = $ref{$k}; }
    }
    return $best_val;   # undef if no stored key is a prefix of $q
}

{
    my @probes = (
        # dotted-decimal probes that should hit the 10.* / 192.168.* structure
        "10.0.0.255", "10.0.0", "10.3.9.1", "10.7.15.31", "10.5",
        "192.168.0.1", "192.168.5", "192.0.0.0", "192", "193.1.1.1",
        # key-family probes
        "key0001", "key0500", "key0999", "key1000", "key", "keyx",
        # misc / no-match probes
        "9", "1", "", "z", "10", "10.0", "100", "1.2.3.4",
    );
    my $bad = 0;
    for my $q (@probes) {
        my $xs  = $t->longest_prefix($q);
        my $rf  = ref_longest_prefix($q);
        if (!defined($xs) && !defined($rf)) { next; }
        if (!defined($xs) || !defined($rf) || $xs != $rf) {
            $bad++;
            diag "longest_prefix mismatch for '$q': xs=" . (defined $xs ? $xs : 'undef')
               . " ref=" . (defined $rf ? $rf : 'undef');
        }
    }
    is $bad, 0, 'longest_prefix() matches the brute-force reference for every probe';
}

# ---- sizes within capacity ----
{
    my $st = $t->stats;
    cmp_ok $st->{nodes_used}, '<=', $st->{nodes_capacity}, 'nodes_used within capacity';
    cmp_ok $st->{arena_used}, '<=', $st->{arena_capacity}, 'arena_used within capacity';
    diag sprintf "2000-key oracle: nodes_used=%d/%d arena_used=%d/%d keys=%d",
        $st->{nodes_used}, $st->{nodes_capacity},
        $st->{arena_used}, $st->{arena_capacity}, $st->{keys};
}

# ---- (d) delete half the keys, re-verify ----
{
    my @sorted = @keys;            # deterministic order
    my @deleted;
    my $expect_count = scalar @sorted;
    for my $idx (0 .. $#sorted) {
        next unless $idx % 2 == 0; # delete every other key (deterministic ~half)
        my $k = $sorted[$idx];
        my $r = $t->delete($k);
        $expect_count-- if $r == 1;
        delete $ref{$k};
        push @deleted, $k;
    }

    is $t->count, scalar(keys %ref), 'count matches the reference after deleting half';
    is $t->count, $expect_count, 'count decremented exactly once per successful delete';

    # deleted keys are gone; surviving keys still resolve to their values
    my ($gone_bad, $live_bad) = (0, 0);
    $gone_bad++ for grep { $t->exists($_) } @deleted;
    for my $k (keys %ref) {
        my $got = $t->lookup($k);
        $live_bad++ unless defined($got) && $got == $ref{$k};
    }
    is $gone_bad, 0, 'every deleted key is absent after the bulk delete';
    is $live_bad, 0, 'every surviving key still looks up to its reference value';

    # longest_prefix still matches the (now smaller) reference on the same probes
    my @probes = ("10.0.0.255", "10.3.9.1", "192.168.0.1", "key0001", "key0500", "9", "1", "");
    my $lp_bad = 0;
    for my $q (@probes) {
        my $xs = $t->longest_prefix($q);
        my $rf = ref_longest_prefix($q);
        next if !defined($xs) && !defined($rf);
        $lp_bad++ if !defined($xs) || !defined($rf) || $xs != $rf;
    }
    is $lp_bad, 0, 'longest_prefix() still matches the reference after deletions';
}

done_testing;
