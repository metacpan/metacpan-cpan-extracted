#!perl
# 02-accel-selection.t
#
# Exercises the per-instance acceleration selection knobs `use_c` and
# `use_openmp` exposed by new() and verifies they actually steer which
# code path runs:
#
#   * Defaults come from the package flags $HAS_C / $HAS_OPENMP.
#   * use_c => 0 disables the Inline::C scoring backend even when the
#     module compiled it in.  After fit() such an instance has no
#     _c_nodes attached, so we know scoring is hitting the pure-Perl
#     fallback.
#   * use_c => 1 is honoured when $HAS_C is set, ignored (clamped via
#     truthiness) otherwise.
#   * use_openmp => 0 keeps the C tree-walk serial without disabling
#     the C backend itself.
#   * C-backed and Perl-fallback scoring agree -- when the C backend
#     compiled successfully we should be able to flip use_c off and
#     get the same scores back from the pure-Perl path.
#   * pack_data() refuses to run on a use_c => 0 instance (it needs
#     the C backend).
#   * The bundled `iforest accel` CLI command runs cleanly and reports
#     a status consistent with the package flags.

use strict;
use warnings;
use Test::More;
use File::Spec;

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C      ? 1 : 0;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP ? 1 : 0;
my $HAS_SIMD   = $Algorithm::Classifier::IsolationForest::HAS_SIMD   ? 1 : 0;

# Small but non-trivial dataset shared by every subtest below.  A handful
# of obvious outliers tacked on the end of a uniform cluster keeps the
# scores well separated so cross-backend comparisons are unambiguous.
srand(11);
my @data;
push @data, [ rand(), rand(), rand() ] for 1 .. 60;
push @data, [ 12, 12, 12 ], [ -11, -11, -11 ], [ 10, -10, 9 ];

subtest 'defaults: _use_c / _use_openmp follow the package flags' => sub {
    my $f = $CLASS->new( n_trees => 20, sample_size => 32, seed => 3 );
    is( $f->{_use_c},      $HAS_C,      '_use_c defaults to $HAS_C' );
    is( $f->{_use_openmp}, $HAS_OPENMP, '_use_openmp defaults to $HAS_OPENMP' );
};

subtest 'use_c => 0 forces the pure-Perl path' => sub {
    my $f = $CLASS->new(
        n_trees     => 20,
        sample_size => 32,
        seed        => 3,
        use_c       => 0,
    );
    is( $f->{_use_c}, 0, '_use_c is 0 after use_c => 0' );

    $f->fit( \@data );
    ok( !exists $f->{_c_nodes} || !defined $f->{_c_nodes},
        'fit() does not build _c_nodes when use_c is off' );

    # Scoring must still work end-to-end via the Perl fallback.
    my $scores = $f->score_samples( \@data );
    is( ref $scores, 'ARRAY',         'score_samples returns an arrayref' );
    is( scalar @$scores, scalar @data, 'one score per sample' );
    my $bad = grep { !defined $_ || $_ <= 0 || $_ > 1 } @$scores;
    is( $bad, 0, 'every Perl-path score is in (0, 1]' );
};

subtest 'use_c => 0 propagates through reload (from_json/load)' => sub {
    # An instance with use_c off should still serialise and reload, and the
    # reloaded model's runtime preference comes from the *current* package
    # flags (from_json wires _use_c => $HAS_C).  We're really checking that
    # the round trip doesn't crash and produces a working model.
    my $f = $CLASS->new(
        n_trees     => 12,
        sample_size => 24,
        seed        => 5,
        use_c       => 0,
    );
    $f->fit( \@data );

    my $json     = $f->to_json;
    my $reloaded = $CLASS->from_json($json);
    is( $reloaded->{_use_c}, $HAS_C,
        'from_json picks up the current $HAS_C, not the saved instance flag' );

    my $a = $f->score_samples( \@data );
    my $b = $reloaded->score_samples( \@data );
    is( scalar @$a, scalar @$b, 'same row count after reload' );
};

SKIP: {
    skip 'no Inline::C backend compiled in', 1 unless $HAS_C;

    subtest 'use_c => 1 honoured when $HAS_C is set' => sub {
        my $f = $CLASS->new(
            n_trees     => 20,
            sample_size => 32,
            seed        => 3,
            use_c       => 1,
        );
        is( $f->{_use_c}, 1, '_use_c is 1 after use_c => 1' );

        $f->fit( \@data );
        ok( ref $f->{_c_nodes} eq 'ARRAY' && @{ $f->{_c_nodes} },
            'fit() builds _c_nodes when use_c is on' );
    };
}

SKIP: {
    skip 'use_c => 0 vs use_c => 1 comparison needs Inline::C', 1
        unless $HAS_C;

    subtest 'C-backed and Perl-fallback scores agree' => sub {
        # Identical seed + identical hyperparameters => identical trees =>
        # the two code paths should produce the same scores (up to the
        # tiny floating-point reordering inside score_all_xs vs the Perl
        # loop -- well under 1e-9 in practice for this scale).
        my $fc = $CLASS->new(
            n_trees     => 30,
            sample_size => 40,
            seed        => 17,
            use_c       => 1,
        );
        my $fp = $CLASS->new(
            n_trees     => 30,
            sample_size => 40,
            seed        => 17,
            use_c       => 0,
        );
        $fc->fit( \@data );
        $fp->fit( \@data );

        my $sc = $fc->score_samples( \@data );
        my $sp = $fp->score_samples( \@data );
        is( scalar @$sc, scalar @$sp, 'same length' );

        my $max_diff = 0;
        for my $i ( 0 .. $#$sc ) {
            my $d = abs( $sc->[$i] - $sp->[$i] );
            $max_diff = $d if $d > $max_diff;
        }
        cmp_ok( $max_diff, '<', 1e-9,
            "C and Perl scores agree (max diff $max_diff)" );

        # Labels at the default cutoff must match exactly.
        my $lc = $fc->predict( \@data );
        my $lp = $fp->predict( \@data );
        my $mismatches = grep { $lc->[$_] != $lp->[$_] } 0 .. $#$lc;
        is( $mismatches, 0, 'predict() labels agree across backends' );
    };
}

SKIP: {
    skip 'OpenMP not linked in', 1 unless $HAS_OPENMP;

    subtest 'use_openmp => 0 keeps C backend, disables parallel walk' => sub {
        my $f = $CLASS->new(
            n_trees     => 20,
            sample_size => 32,
            seed        => 3,
            use_openmp  => 0,
        );
        is( $f->{_use_c},      1, '_use_c stays on with use_openmp => 0' );
        is( $f->{_use_openmp}, 0, '_use_openmp is 0 after use_openmp => 0' );

        $f->fit( \@data );
        my $scores = $f->score_samples( \@data );
        is( scalar @$scores, scalar @data,
            'serial C path still scores every sample' );
    };

    subtest 'use_openmp => 1 honoured when $HAS_OPENMP is set' => sub {
        my $f = $CLASS->new(
            n_trees     => 20,
            sample_size => 32,
            seed        => 3,
            use_openmp  => 1,
        );
        is( $f->{_use_openmp}, 1, '_use_openmp is 1 after use_openmp => 1' );
    };
}

subtest 'use_openmp clamped to 0 when use_c is off' => sub {
    # OpenMP only matters with the C tree walk; if the C backend is off
    # the OpenMP flag is meaningless, so the constructor should clear it
    # rather than leaving it set to a value that never gets read.
    my $f = $CLASS->new(
        n_trees     => 10,
        sample_size => 16,
        seed        => 1,
        use_c       => 0,
        use_openmp  => 1,
    );
    is( $f->{_use_c},      0, '_use_c is 0' );
    is( $f->{_use_openmp}, 0, '_use_openmp clamped to 0 since C backend is off' );
};

subtest 'use_c => 1 clamped against $HAS_C in the constructor' => sub {
    # Fake "no Inline::C compiled" by localising the package flags.  The
    # XS subs themselves remain defined in this process (they were loaded
    # at module init), but the constructor's contract is to clamp against
    # $HAS_C so a fresh build without Inline::C wouldn't end up calling
    # an undefined sub at score time.
    local $Algorithm::Classifier::IsolationForest::HAS_C      = 0;
    local $Algorithm::Classifier::IsolationForest::HAS_OPENMP = 0;

    my $f = $CLASS->new(
        n_trees     => 10,
        sample_size => 16,
        seed        => 1,
        use_c       => 1,
        use_openmp  => 1,
    );
    is( $f->{_use_c}, 0,
        'use_c => 1 clamped to 0 when $HAS_C is 0' );
    is( $f->{_use_openmp}, 0,
        'use_openmp => 1 clamped to 0 when $HAS_OPENMP is 0' );

    # Defaults follow the (faked) flags too.
    my $g = $CLASS->new( n_trees => 10, sample_size => 16, seed => 1 );
    is( $g->{_use_c},      0, 'default _use_c follows the faked $HAS_C' );
    is( $g->{_use_openmp}, 0, 'default _use_openmp follows the faked $HAS_OPENMP' );
};

subtest 'use_openmp => 1 clamped against $HAS_OPENMP' => sub {
    # $HAS_C stays on so the C backend is still picked up; only OpenMP
    # is faked off.  use_openmp => 1 should clamp to 0.
    local $Algorithm::Classifier::IsolationForest::HAS_OPENMP = 0;

    my $f = $CLASS->new(
        n_trees     => 10,
        sample_size => 16,
        seed        => 1,
        use_openmp  => 1,
    );
    is( $f->{_use_c},      $HAS_C, '_use_c follows $HAS_C' );
    is( $f->{_use_openmp}, 0,
        'use_openmp => 1 clamped to 0 when $HAS_OPENMP is 0' );
};

subtest 'pack_data croaks when use_c is off' => sub {
    my $f = $CLASS->new(
        n_trees     => 10,
        sample_size => 20,
        seed        => 9,
        use_c       => 0,
    );
    $f->fit( \@data );
    eval { $f->pack_data( \@data ) };
    like(
        $@,
        qr/requires the Inline::C backend/,
        'pack_data refuses to run without the C backend'
    );
};

# ------------------------------------------------------------------------
# CLI: `iforest accel` should run cleanly and report a status consistent
# with the package flags this process sees.  We bypass it entirely if
# bin/iforest isn't there (e.g. unusual install layouts).
# ------------------------------------------------------------------------
SKIP: {
    my $bin = File::Spec->rel2abs('bin/iforest');
    skip "bin/iforest not found", 1 unless -x $bin;

    subtest 'iforest accel CLI reports a consistent status' => sub {
        my $out = `$^X -Ilib $bin accel 2>&1`;
        is( $?, 0, 'iforest accel exits 0' );

        like(
            $out,
            qr/Algorithm::Classifier::IsolationForest acceleration status/,
            'prints the status header'
        );
        like( $out, qr/Inline::C\s*:/, 'mentions Inline::C' );
        like( $out, qr/OpenMP\s*:/,    'mentions OpenMP' );
        like( $out, qr/SIMD\s*:/,      'mentions SIMD' );
        like( $out, qr/Active backend:/, 'prints an Active backend line' );

        # Cross-check the per-feature status lines against the package
        # flags the test process observed.  This is what makes this test
        # actually verify selection rather than just "doesn't crash".
        if ($HAS_C) {
            like( $out, qr/Inline::C\s*:\s*available/,
                'CLI reports Inline::C available, matching $HAS_C' );
        } else {
            like( $out, qr/Inline::C\s*:\s*not available/,
                'CLI reports Inline::C not available, matching $HAS_C' );
        }
        if ($HAS_OPENMP) {
            like( $out, qr/OpenMP\s*:\s*available/,
                'CLI reports OpenMP available, matching $HAS_OPENMP' );
        } else {
            like( $out, qr/OpenMP\s*:\s*not available/,
                'CLI reports OpenMP not available, matching $HAS_OPENMP' );
        }
        if ($HAS_SIMD) {
            like( $out, qr/SIMD\s*:\s*available/,
                'CLI reports SIMD available, matching $HAS_SIMD' );
        } else {
            like( $out, qr/SIMD\s*:\s*not available/,
                'CLI reports SIMD not available, matching $HAS_SIMD' );
        }

        # The "Active backend:" summary should reflect the same picture.
        if ( $HAS_C && ( $HAS_OPENMP || $HAS_SIMD ) ) {
            like(
                $out,
                qr/Active backend:\s*Inline::C with /,
                'summary names Inline::C plus features'
            );
        } elsif ($HAS_C) {
            like(
                $out,
                qr/Active backend:\s*Inline::C \(serial, scalar\)/,
                'summary names serial/scalar Inline::C'
            );
        } else {
            like(
                $out,
                qr/Active backend:\s*pure Perl/,
                'summary falls back to pure Perl'
            );
        }
    };
}

diag( sprintf 'test ran with HAS_C=%d HAS_OPENMP=%d HAS_SIMD=%d',
    $HAS_C, $HAS_OPENMP, $HAS_SIMD );

done_testing;
