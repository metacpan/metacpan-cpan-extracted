#!perl
# 01-accel-flags.t
#
# Sanity-checks the $HAS_C / $HAS_OPENMP / $HAS_SIMD package variables
# that record what the Inline::C build picked up at module load.  These
# are read by `iforest accel` and by any user code that wants to make
# decisions based on which backend is active.
#
# What we verify (always):
#   * the three vars are defined and 0/1-valued
#   * SIMD => OpenMP    (`#pragma omp simd` is gated on _OPENMP)
#   * OpenMP => Inline::C  (OpenMP only matters with the C backend)
#
# We do NOT assert that any backend is *available* -- the test should
# pass cleanly on a pure-Perl install too.

use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

my $has_c      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $has_openmp = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;
my $has_simd   = $Algorithm::Classifier::IsolationForest::HAS_SIMD;

ok( defined $has_c,      '$HAS_C is defined' );
ok( defined $has_openmp, '$HAS_OPENMP is defined' );
ok( defined $has_simd,   '$HAS_SIMD is defined' );

for my $pair ( [ '$HAS_C', $has_c ], [ '$HAS_OPENMP', $has_openmp ], [ '$HAS_SIMD', $has_simd ], ) {
	my ( $name, $val ) = @$pair;
	ok( $val == 0 || $val == 1, "$name is 0 or 1 (got '$val')" );
}

ok( !$has_openmp || $has_c,      'OpenMP implies Inline::C (parallel scoring needs the C backend)' );
ok( !$has_simd   || $has_openmp, 'SIMD implies OpenMP (omp simd pragma is gated on _OPENMP)' );

diag( sprintf 'Active backend flags: HAS_C=%d HAS_OPENMP=%d HAS_SIMD=%d', $has_c, $has_openmp, $has_simd );

done_testing;
