#!perl
# 34-missing-values.t
#
# Exercises the four `missing =>` strategies for fitting on data that
# contains undef (missing) feature cells:
#
#   die    -- croak from fit() on any undef in the training data (default)
#   zero   -- treat missing as the value 0
#   impute -- replace missing with the learned per-feature mean/median
#   nan    -- build ranges over present values and route missing rows right
#
# Every strategy is exercised against the pure-Perl backend and, when it
# compiled, the C backend; a missing C backend skips that arm rather than
# failing.  The equivalence tests pin each strategy to its contract:
#   * zero   == fitting the same data with undef pre-replaced by 0
#   * impute == fitting the same data with undef pre-replaced by the fill
#   * nan     gives matching scores under the C and pure-Perl backends

use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

use Algorithm::Classifier::IsolationForest;

my $CLASS  = 'Algorithm::Classifier::IsolationForest';
my $SEED   = 42;
my $HAS_C  = $Algorithm::Classifier::IsolationForest::HAS_C;

my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ] if $HAS_C;

# Helper: run a block, return any warnings it emitted.
sub _warnings {
    my ($code) = @_;
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $code->();
    return @w;
}

# Largest absolute elementwise difference between two score arrayrefs.
sub _max_abs_diff {
    my ( $x, $y ) = @_;
    my $max = 0;
    for my $i ( 0 .. $#$x ) {
        my $d = abs( $x->[$i] - $y->[$i] );
        $max = $d if $d > $max;
    }
    return $max;
}

# Clean 2-D training grid (no undef anywhere).
my @clean;
for my $i ( -7 .. 7 ) {
    for my $j ( -7 .. 7 ) {
        push @clean, [ $i / 7.0, $j / 7.0 ];
    }
}

# A copy of the grid with a scattering of undef cells punched into it.
my @holey = map { [ @$_ ] } @clean;
for my $k ( 0 .. $#holey ) {
    $holey[$k][0] = undef if $k % 9 == 0;     # missing in column 0
    $holey[$k][1] = undef if $k % 13 == 0;    # missing in column 1
}

# Score-time test points, some with undef columns.
my @test = (
    [ 0.3,   0.3 ],
    [ 6.0,   6.0 ],
    [ 0.3,   undef ],
    [ undef, 0.5 ],
    [ undef, undef ],
);

# ---------------------------------------------------------------------------
# Constructor validation (backend-independent)
# ---------------------------------------------------------------------------
subtest 'constructor validates missing / impute_with' => sub {
    ok( eval { $CLASS->new( missing => 'zero' ); 1 }, "missing => 'zero' accepted" );
    ok( eval { $CLASS->new( missing => 'nan' );  1 }, "missing => 'nan' accepted" );
    ok( !eval { $CLASS->new( missing => 'bogus' ); 1 }, 'bad missing rejected' );
    like( $@, qr/missing must be one of/, 'bad missing message' );

    ok( eval { $CLASS->new( impute_with => 'median' ); 1 }, "impute_with => 'median' accepted" );
    ok( !eval { $CLASS->new( impute_with => 'mode' ); 1 }, 'bad impute_with rejected' );
    like( $@, qr/impute_with must be/, 'bad impute_with message' );

    is( $CLASS->new->{missing}, 'die', 'missing defaults to die' );
};

for my $be (@BACKENDS) {
    my ( $be_name, $USE_C ) = @$be;

    # -----------------------------------------------------------------------
    # die (default): fatal on undef in training, scoring still tolerates it
    # -----------------------------------------------------------------------
    subtest "[$be_name] die mode croaks on undef training data" => sub {
        my $f = $CLASS->new( n_trees => 50, seed => $SEED, use_c => $USE_C );
        ok( !eval { $f->fit( \@holey ); 1 }, 'fit on holey data croaks' );
        like( $@, qr/undef feature value at sample \d+, column \d+/, 'helpful croak message' );

        ok( eval { $f->fit( \@clean ); 1 }, 'fit on clean data succeeds' );

        # A model fitted on clean data still scores rows with missing
        # features, mapping undef -> 0 (the pre-existing behaviour).
        my @w = _warnings( sub { $f->score_samples( \@test ) } );
        is( scalar @w, 0, 'scoring undef rows emits no warnings under die mode' );
    };

    # -----------------------------------------------------------------------
    # zero: fitting on undef data == fitting on the same data with undef -> 0
    # -----------------------------------------------------------------------
    subtest "[$be_name] zero mode equals explicit-zero fit" => sub {
        my @zeroed = map { [ map { defined $_ ? $_ : 0 } @$_ ] } @holey;

        my $a = $CLASS->new(
            n_trees => 80, seed => $SEED, missing => 'zero', use_c => $USE_C );
        my @w = _warnings( sub { $a->fit( \@holey ) } );
        is( scalar @w, 0, 'zero-mode fit on undef data emits no warnings' );

        my $b = $CLASS->new( n_trees => 80, seed => $SEED, use_c => $USE_C );
        $b->fit( \@zeroed );    # die mode, clean zeroed data

        cmp_ok( _max_abs_diff( $a->score_samples( \@clean ), $b->score_samples( \@clean ) ),
            '<', 1e-9, 'zero-mode scores match explicit-zero fit' );
    };

    # -----------------------------------------------------------------------
    # impute: fill is the per-feature statistic; fit == densify-then-fit
    # -----------------------------------------------------------------------
    for my $how (qw(mean median)) {
        subtest "[$be_name] impute mode ($how) learns fill and matches densified fit" => sub {
            my $imp = $CLASS->new(
                n_trees     => 80,
                seed        => $SEED,
                missing     => 'impute',
                impute_with => $how,
                use_c       => $USE_C,
            );
            my @w = _warnings( sub { $imp->fit( \@holey ) } );
            is( scalar @w, 0, "impute ($how) fit emits no warnings" );

            my $fill = $imp->{missing_fill};
            is( scalar @$fill, 2, 'fill vector has one entry per feature' );

            # Independently compute the expected statistic for each column.
            for my $col ( 0, 1 ) {
                my @present = grep { defined } map { $_->[$col] } @holey;
                my $want;
                if ( $how eq 'mean' ) {
                    $want = sum(@present) / scalar @present;
                } else {
                    my @s = sort { $a <=> $b } @present;
                    my $n = scalar @s;
                    $want = $n % 2 ? $s[ int( $n / 2 ) ]
                                  : ( $s[ $n / 2 - 1 ] + $s[ $n / 2 ] ) / 2;
                }
                cmp_ok( abs( $fill->[$col] - $want ), '<', 1e-12,
                    "column $col fill is the $how of present values" );
            }

            # Densify with the learned fill, then a plain (die) fit must agree.
            my @densified
                = map { my $r = $_; [ map { defined $r->[$_] ? $r->[$_] : $fill->[$_] } 0, 1 ] }
                @holey;
            my $ref = $CLASS->new( n_trees => 80, seed => $SEED, use_c => $USE_C );
            $ref->fit( \@densified );

            cmp_ok(
                _max_abs_diff( $imp->score_samples( \@clean ), $ref->score_samples( \@clean ) ),
                '<', 1e-9, "impute ($how) scores match densified fit" );
        };
    }

    # -----------------------------------------------------------------------
    # impute: a feature column that's entirely undef has no statistic to
    # learn, and must croak -- on the first such column in feature order,
    # matching the pure-Perl fallback's message exactly. This exercises
    # the multi-column case (one good column, one entirely-undef column)
    # specifically: an earlier regression in the C fast path freed a
    # good column's scratch buffer once when computing its fill and then
    # again while cleaning up after discovering the later, entirely-undef
    # column -- a double free that only shows up with more than one
    # feature column, so a single-column case wouldn't have caught it.
    # -----------------------------------------------------------------------
    subtest "[$be_name] impute mode croaks on a feature with no present values"
        => sub {
        my @all_missing_second = map { [ $_->[0], undef ] } @holey;
        my $f = $CLASS->new(
            n_trees => 20, seed => $SEED, missing => 'impute', use_c => $USE_C );
        ok( !eval { $f->fit( \@all_missing_second ); 1 },
            'fit croaks when a feature column is entirely undef' );
        like( $@, qr/impute: feature column 1 has no present values/,
            'names the offending column' );

        my @all_missing_first = map { [ undef, $_->[1] ] } @holey;
        my $g = $CLASS->new(
            n_trees => 20, seed => $SEED, missing => 'impute', use_c => $USE_C );
        ok( !eval { $g->fit( \@all_missing_first ); 1 },
            'fit croaks when the first feature column is entirely undef' );
        like( $@, qr/impute: feature column 0 has no present values/,
            'names the offending column' );
        };

    # -----------------------------------------------------------------------
    # Persistence: every strategy round-trips, and impute carries its fill
    # -----------------------------------------------------------------------
    subtest "[$be_name] save/load round-trips each strategy" => sub {
        for my $cfg (
            [ zero   => {} ],
            [ impute => { impute_with => 'median' } ],
            [ nan    => {} ],
            )
        {
            my ( $strategy, $extra ) = @$cfg;
            my $f = $CLASS->new(
                n_trees => 60, seed => $SEED, missing => $strategy,
                use_c => $USE_C, %$extra,
            );
            $f->fit( \@holey );
            my $reloaded = $CLASS->from_json( $f->to_json );

            is( $reloaded->{missing}, $strategy, "$strategy: missing restored" );
            if ( $strategy eq 'impute' ) {
                is_deeply( $reloaded->{missing_fill}, $f->{missing_fill},
                    'impute: fill vector restored' );
            }

            cmp_ok(
                _max_abs_diff( $f->score_samples( \@test ), $reloaded->score_samples( \@test ) ),
                '<', 1e-9, "$strategy: reloaded scores match original" );
        }
    };

    # -----------------------------------------------------------------------
    # Old models (no `missing` key) load as zero and keep undef -> 0 scoring
    # -----------------------------------------------------------------------
    subtest "[$be_name] pre-missing models default to zero on load" => sub {
        my $f = $CLASS->new( n_trees => 40, seed => $SEED, use_c => $USE_C )
            ->fit( \@clean );
        my $json = $f->to_json;

        # Strip the missing-value keys to mimic a model saved by an older release.
        $json =~ s/"missing"\s*:\s*"[^"]*"\s*,?//;
        $json =~ s/"impute_with"\s*:\s*"[^"]*"\s*,?//;
        $json =~ s/"missing_fill"\s*:\s*(?:null|\[[^\]]*\])\s*,?//;

        my $reloaded = $CLASS->from_json($json);
        is( $reloaded->{missing}, 'zero', 'legacy model loads as zero' );
        ok( eval { $reloaded->score_samples( \@test ); 1 }, 'legacy model scores undef rows' );
    };
}

# ---------------------------------------------------------------------------
# nan: the C and pure-Perl backends must route missing values identically.
# Only meaningful when the C backend compiled; otherwise we still confirm the
# pure-Perl path fits and scores without error.
# ---------------------------------------------------------------------------
for my $mode (qw(axis extended)) {
    subtest "nan mode ($mode): C and pure-Perl scores agree" => sub {
        my $p = $CLASS->new(
            n_trees => 80, seed => $SEED, missing => 'nan',
            mode => $mode, use_c => 0,
        );
        my @w = _warnings( sub { $p->fit( \@holey ) } );
        is( scalar @w, 0, 'nan-mode fit emits no warnings' );
        ok( !$p->{_use_c}, 'pure-Perl model does not use the C backend' );

        my $sp = $p->score_samples( \@test );
        is( scalar @$sp, scalar @test, 'pure-Perl nan scoring returns a score per row' );

      SKIP: {
            skip 'C backend not built', 2 unless $HAS_C;

            my $c = $CLASS->new(
                n_trees => 80, seed => $SEED, missing => 'nan',
                mode => $mode, use_c => 1,
            );
            $c->fit( \@holey );
            ok( $c->{_use_c}, 'C model uses the C backend' );

            cmp_ok( _max_abs_diff( $c->score_samples( \@test ), $sp ),
                '<', 1e-9, 'C and Perl nan-mode scores agree' );
        }
    };
}

done_testing;
