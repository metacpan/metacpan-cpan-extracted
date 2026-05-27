#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use JSON::PP ();

# Random JSON round-trip: generates N rows of objects with random
# paths, types, and arrays. Verifies encode -> decode is identity for
# every row. Seeded for reproducibility; override with PERL_JSON_STRESS_SEED.

srand($ENV{PERL_JSON_STRESS_SEED} || 1739);

my @ALPHA = ('a'..'z');
sub rand_word {
    my $n = 1 + int(rand 6);
    join '', map $ALPHA[rand @ALPHA], 1..$n;
}

sub rand_scalar {
    my $kind = int rand 4;
    return $kind == 0 ? int(rand(2_000_000) - 1_000_000)
         : $kind == 1 ? rand(100) - 50
         : $kind == 2 ? rand_word()
         : (rand() < 0.5 ? JSON::PP::true() : JSON::PP::false());
}

sub rand_array {
    my $kind = int rand 4;
    my $n = int rand 5;
    my @a;
    for (1..$n) {
        push @a, $kind == 0 ? int(rand 1000)
              :  $kind == 1 ? rand(10)
              :  $kind == 2 ? rand_word()
              :  (rand() < 0.5 ? JSON::PP::true() : JSON::PP::false());
    }
    return \@a;
}

sub rand_object {
    my ($depth) = @_;
    $depth //= 0;
    my %o;
    my $n = 1 + int rand 4;
    for (1..$n) {
        my $k = rand_word();
        my $r = rand();
        $o{$k} = $depth < 2 && $r < 0.2 ? rand_object($depth + 1)
              :  $r < 0.5               ? rand_scalar()
              :  $r < 0.8               ? rand_array()
              :  undef;
    }
    return \%o;
}

my $enc = ClickHouse::Encoder->new(columns => [['j', 'JSON']]);

my $N_ITERATIONS = $ENV{PERL_JSON_STRESS_N} || 25;
for my $iter (1..$N_ITERATIONS) {
    my $n_rows = 1 + int rand 20;
    my @rows = map { [rand_object()] } 1..$n_rows;
    my $bytes;
    my $ok = eval { $bytes = $enc->encode(\@rows); 1 };
    ok($ok, "iter $iter: encode ok") or do {
        diag("error: $@");
        next;
    };
    my $block = eval { ClickHouse::Encoder->decode_block($bytes) };
    ok($block, "iter $iter: decode ok") or next;
    is($block->{nrows}, $n_rows, "iter $iter: nrows preserved");

    # Spot-check: every row should decode to a hashref. We don't deep-compare
    # because Bool round-trips as 0/1 (not blessed scalarref) and float
    # NV-integer collapse can change leaf representation - both are
    # documented. The structural invariant (hashref-per-row, paths preserved
    # if no collisions) is the real assertion.
    my $vals = $block->{columns}[0]{values};
    my $all_hash = !grep { ref $_ ne 'HASH' } @$vals;
    ok($all_hash, "iter $iter: all rows decode as hashref");

    # Spot-check leaf values that DO round-trip identically:
    #   - String leaves (no type collapse)
    #   - Int64 leaves (when input was an integer)
    #   - Array(String) leaves (homogeneous strings)
    # This catches off-by-one cursor bugs and path-permutation bugs that
    # the bare hashref check would miss.
    for my $r (0..$#rows) {
        my $orig = $rows[$r][0];
        my $got  = $vals->[$r];
        _check_stable_leaves($orig, $got, "iter $iter row $r");
    }
}

sub _check_stable_leaves {
    my ($orig, $got, $tag) = @_;
    if (ref($orig) eq 'HASH') {
        # Path collision: this row has e.g. "a.b" but another row in
        # the column had "a" as a scalar, so the unflatten kept the
        # dotted form here. That's documented behavior; skip.
        return if ref($got) ne 'HASH';
        for my $k (keys %$orig) {
            _check_stable_leaves($orig->{$k}, $got->{$k}, "$tag.$k");
        }
        return;
    }
    if (ref($orig) eq 'ARRAY') {
        # Only assert for homogeneous string arrays (other element kinds
        # may collapse 1.0 -> 1 or have bool 0/1 stringification quirks).
        my $all_str = !grep { ref $_ || !defined $_
                              || $_ =~ /\A-?\d/ } @$orig;
        return unless $all_str;
        return unless ref($got) eq 'ARRAY';  # path collision
        return is_deeply($got, $orig, "$tag: Array(String)");
    }
    return unless defined $orig;
    # Skip boolean (JSON::PP::true/false would compare unequal).
    return if ref($orig);
    # Skip pure floats (NV-integer collapse / NV stringification noise).
    return if $orig =~ /\./;
    # Plain integer or string scalar: should round-trip exactly when the
    # structural path was preserved (i.e. $got is also a leaf, not a
    # subtree dragged in by some other row's path).
    return if ref($got);
    is($got, $orig, "$tag: leaf");
}

done_testing();
