package Algorithm::Classifier::IsolationForest;

use strict;
use warnings;
use Carp         qw(croak);
use Config       ();
use List::Util   qw(min);
use Scalar::Util qw(looks_like_number);
use POSIX        qw(ceil);
use JSON::PP     ();
use File::Slurp  qw(read_file write_file);

our $VERSION = '0.7.0';

use constant EULER => 0.5772156649015329;

# Narrowed to C double precision so _randn() multiplies by the exact
# constant _c_randn() uses.  A no-op on nvsize == 8 perls.
use constant TWO_PI => unpack( 'd', pack 'd', 6.283185307179586 );

# Node-type tags stored in index 0 of every tree node arrayref.
# 0 is falsy, so  while ($node->[0])  acts as  while (!leaf).
use constant _NODE_LEAF    => 0;
use constant _NODE_AXIS    => 1;
use constant _NODE_OBLIQUE => 2;

# The Inline::C tree builder computes everything in C doubles.  On a perl
# whose NV is wider than a double (-Duselongdouble / -Dusequadmath) the
# pure-Perl builder keeps extra low bits at every step, so the two
# backends would stop producing bit-identical trees for the same seed
# (the parity t/03-fit-determinism.t checks).  _NV_IS_DOUBLE guards
# narrowing statements wherever the pure-Perl builder computes a value
# that gets STORED in a tree (split points, hyperplane coefficients and
# offsets, impute fills), rounding at the same points the C builder
# rounds.  It is compile-time true on nvsize == 8 perls, so there the
# guarded statements are optimised away and cost nothing.
#
# The row-partition loops (v < split, dot <= b) are deliberately NOT
# narrowed: with both operands already double-exact an axis comparison
# is identical anyway, and an oblique dot product accumulated in a wider
# NV flips a comparison only when |dot - b| falls inside the NV-vs-double
# rounding gap (~1e-19 relative) -- negligible, and those are the hot
# loops.
use constant _NV_IS_DOUBLE => $Config::Config{nvsize} == 8;

# Round an NV to C double precision.  Only ever reached on wide-NV
# perls -- see _NV_IS_DOUBLE.
#
# Args:
#   $nv :: any number.  On a -Duselongdouble / -Dusequadmath perl it may
#          carry more precision than a C double can hold.
#
# Returns: the same number rounded to the nearest IEEE 754 double.  A no-op
# for a value that is already double-exact.
#
# Example:
#   _to_double( $lo + rand() * ( $hi - $lo ) );   # what the C builder stores
sub _to_double { unpack 'd', pack 'd', $_[0] }

# ---------------------------------------------------------------------------
# Optional Inline::C accelerator for the scoring hot path.
#
# pack_input_xs(data_sv, out_sv, n_pts, n_feats, miss_mode, fill_sv)
#     Walks the Perl arrayref-of-arrayrefs and writes a packed double buffer
#     into out_sv.  Replaces the dominant per-call Perl map-pack loop.
#     miss_mode selects how an undef cell is packed: 0 => 0.0, 1 => the
#     per-feature fill from fill_sv (impute), 2 => NaN (nan strategy).
#
# score_all_xs(nodes_av, idx_av, val_av, x_sv, sm_sv,
#              n_pts, n_feats, n_trees, use_openmp)
#     Sums path lengths for all n_pts query points across all n_trees trees
#     in one call.  Outer loop over points is OpenMP-parallel when the
#     module was built with OpenMP (each iteration writes to a unique sm[i],
#     so no synchronisation is needed).  Tree pointers are extracted from
#     the AVs before the parallel region; the parallel region touches only
#     raw int / double buffers.
#
# vote_all_xs(nodes_av, idx_av, val_av, x_sv, sm_sv,
#             n_pts, n_feats, n_trees, depth_cut, min_votes, use_openmp)
#     Majority-voting (voting => 'majority') counterpart of score_all_xs:
#     instead of summing path lengths it counts, per point, how many trees
#     "vote anomalous" (path length <= depth_cut).  min_votes == 0 writes
#     the full vote count into sm[i]; min_votes > 0 writes a 0.0/1.0 label
#     with per-point early exit once the majority outcome is decided --
#     the MVIForest scoring loop.  See the function's own comment.
#
# Node layout (6 doubles per node, "IF_NZ = 6"):
#   leaf:    [0, size, c(size), 0, 0, 0]
#   axis:    [1, attr, split, li, ri, 0]
#   oblique: [2, coff, nf,  li, ri, b]
#
# c(size) is the expected-path-length adjustment for a leaf holding
# `size` points, precomputed by _pack_tree (it involves a log(); doing
# it at pack time keeps transcendentals out of the per-point per-tree
# scoring loop).  The fit-time TreeBuf writer leaves that slot 0 --
# its buffers are unpacked into Perl trees and re-packed by
# _pack_tree before score_all_xs ever sees them.
#
# Coefficient storage uses a Structure-of-Arrays layout: one int32 array
# per tree (feature indices, packed with 'l*') and one double array per
# tree (coefficients, packed with 'd*').  Both are indexed by `coff` --
# the same offset addresses paired entries in the two arrays.  Splitting
# them this way halves index bandwidth, removes the per-element
# (int)<double> cast inside the SIMD loop, and lets the value loads be
# contiguous so the compiler emits a clean FMA chain over val[k] with
# the feature gather on xi[idx[k]] kept separate.
#
# Dense-pack fast path: when an oblique node uses every feature (the
# common case in extended mode with extension_level == n_features - 1),
# _pack_tree writes its coefficients in feature order so val[k] is the
# coefficient for feature k.  score_all_xs detects this via `nf ==
# n_feats` and uses a no-gather dot product (dot += val[k] * xi[k])
# that vectorizes cleanly with FMA -- substantially faster than the
# sparse gather path on high-feature-count models.
# x:     row-major doubles, n_pts rows of n_feats each.
# sums:  out double array of length n_pts; score_all_xs writes once per i.
#
# OpenMP is enabled at module load when the toolchain accepts -fopenmp and
# libgomp is linkable; otherwise the same C code compiles to a serial loop
# (the #pragma is silently ignored without _OPENMP defined).
# ---------------------------------------------------------------------------
our $HAS_C      = 0;
our $HAS_OPENMP = 0;
our $HAS_SIMD   = 0;
our $OPT_LEVEL  = '';    # the actual -O.../-march=... flags used to build, if any
our $C_SOURCE   = '';    # 'prebuilt' (object installed at `make` time) or
                         # 'runtime' (compiled at first load into _Inline/);
                         # '' when $HAS_C is 0
{
	my $C_CODE = <<'__INLINE_C__';
#include <math.h>
#include <string.h>
#include <stdint.h>
#ifdef _OPENMP
#include <omp.h>
#endif
#define IF_NZ 6

/* Data prefetch hint; a no-op on compilers without __builtin_prefetch.
 * Purely a performance hint -- never affects results. */
#if defined(__GNUC__) || defined(__clang__)
#define IF_PREFETCH(p) __builtin_prefetch(p)
#else
#define IF_PREFETCH(p)
#endif

int has_openmp_xs(){
#ifdef _OPENMP
    return 1;
#else
    return 0;
#endif
}

/* SIMD on the extended-mode oblique dot product is enabled via
 * `#pragma omp simd`, which OpenMP 4.0 (_OPENMP == 201307) introduced.
 * Anything older silently ignores the pragma -- the loop still runs,
 * just not auto-vectorised.  So "simd available" really means the
 * compiler is going to honour the pragma we put on that loop. */
int has_simd_xs(){
#if defined(_OPENMP) && _OPENMP >= 201307
    return 1;
#else
    return 0;
#endif
}

/* pack_input_xs(data_sv, out_sv, n_pts, n_feats, miss_mode, fill_sv)
 *
 * Walks a Perl arrayref-of-arrayrefs (n_pts rows of n_feats doubles each)
 * directly in C and writes the packed double buffer into out_sv (which the
 * caller pre-allocates with "\0" x (n_pts*n_feats*8)).  Replaces
 *
 *   pack('d*', map { my $r=$_; map { $r->[$_] // 0 } 0..$nf-1 } @$data)
 *
 * which was the dominant per-call overhead for high feature counts.
 *
 * miss_mode selects what an undef cell (or missing row) becomes:
 *   0 => 0.0          (the 'die'/'zero' missing strategies)
 *   1 => fill[k]      (the 'impute' strategy; fill_sv is a packed
 *                      double buffer of n_feats per-feature fill values)
 *   2 => NaN          (the 'nan' strategy; the C scorer's `<` / `<=`
 *                      comparisons are both false for NaN, so a point
 *                      missing the split feature falls to the right
 *                      child -- matching how fit() routes it)
 * fill_sv is only dereferenced when miss_mode == 1. */
void pack_input_xs(SV* data_sv, SV* out_sv, int n_pts, int n_feats,
                   int miss_mode, SV* fill_sv){
    STRLEN tl;
    double* out;
    const double* fill = NULL;
    double missval;
    AV* outer;
    int i, k;

    if (!SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
        croak("pack_input_xs: data must be an arrayref");
    }
    outer = (AV*)SvRV(data_sv);
    out   = (double*)SvPVbyte_force(out_sv, tl);

    if (miss_mode == 1) {
        STRLEN fl;
        fill = (const double*)SvPVbyte(fill_sv, fl);
    }
    missval = (miss_mode == 2) ? NAN : 0.0;

    for (i = 0; i < n_pts; i++) {
        SV** row_pp = av_fetch(outer, i, 0);
        double* dst = out + (size_t)i * (size_t)n_feats;
        if (!row_pp || !*row_pp || !SvROK(*row_pp) ||
            SvTYPE(SvRV(*row_pp)) != SVt_PVAV) {
            for (k = 0; k < n_feats; k++)
                dst[k] = (miss_mode == 1) ? fill[k] : missval;
            continue;
        }
        {
            AV* row = (AV*)SvRV(*row_pp);
            for (k = 0; k < n_feats; k++) {
                SV** v = av_fetch(row, k, 0);
                if (v && *v && SvOK(*v)) {
                    dst[k] = SvNV(*v);
                } else {
                    dst[k] = (miss_mode == 1) ? fill[k] : missval;
                }
            }
        }
    }
}

/* first_missing_xs(data_sv, n_pts, n_feats, out_rv)
 *
 * C replacement for _prepare_fit_data's missing => 'die' scan, which is a
 * pure-Perl double loop over every cell of the training set and, being the
 * default strategy, the single largest fixed cost of a fit on wide or long
 * data.  Walks the same arrayref-of-arrayrefs pack_input_xs walks, in the
 * same row-major order, and stops at the first cell that is undef or
 * absent, pushing (row, col) into out_rv.  Leaves out_rv empty when every
 * cell is present.
 *
 * A row that is not an arrayref counts as missing at column 0 -- the same
 * reading pack_input_xs gives it (it fills such a row entirely from the
 * missing branch), so the two agree on what "present" means. */
void first_missing_xs(SV* data_sv, int n_pts, int n_feats, SV* out_rv){
    dTHX;
    AV *outer, *out;
    int i, k;

    if (!SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
        croak("first_missing_xs: data must be an arrayref");
    }
    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("first_missing_xs: out must be an arrayref");
    }
    outer = (AV*)SvRV(data_sv);
    out   = (AV*)SvRV(out_rv);
    av_clear(out);

    for (i = 0; i < n_pts; i++) {
        SV** row_pp = av_fetch(outer, i, 0);
        AV* row;
        if (!row_pp || !*row_pp || !SvROK(*row_pp) ||
            SvTYPE(SvRV(*row_pp)) != SVt_PVAV) {
            av_push(out, newSViv(i));
            av_push(out, newSViv(0));
            return;
        }
        row = (AV*)SvRV(*row_pp);
        for (k = 0; k < n_feats; k++) {
            SV** v = av_fetch(row, k, 0);
            if (!v || !*v || !SvOK(*v)) {
                av_push(out, newSViv(i));
                av_push(out, newSViv(k));
                return;
            }
        }
    }
}

/* finalize_scores_xs(sm_sv, n_pts, inv, out_rv)
 *
 * Fills the pre-allocated arrayref out_rv with exp(-sm[i] * inv) for
 * i in 0..n_pts-1.  Replaces the trailing
 *
 *   my @sums = unpack('d*', $sums_packed);
 *   return [ map { exp(-$_ * $inv) } @sums ];
 *
 * which allocated ~2*n_pts intermediate Perl SVs per scoring call. */
void finalize_scores_xs(SV* sm_sv, int n_pts, double inv, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("finalize_scores_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        av_store(out, i, newSVnv(exp(-sm[i] * inv)));
    }
}

/* finalize_path_lengths_xs(sm_sv, n_pts, t, out_rv)
 *
 * Same idea as finalize_scores_xs but writes sm[i] / t (the average path
 * length across n_trees=t trees) instead of the exp normalisation. */
void finalize_path_lengths_xs(SV* sm_sv, int n_pts, double t, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("finalize_path_lengths_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        av_store(out, i, newSVnv(sm[i] / t));
    }
}

/* predict_sums_xs(sm_sv, n_pts, sum_threshold, out_rv)
 *
 * Fills out_rv with 0/1 IVs based on sm[i] <= sum_threshold.  The caller
 * pre-computes sum_threshold = -log(score_threshold) * c * n_trees / log(2),
 * so this skips both the per-point exp() and the intermediate scores
 * arrayref that the old "score_samples + map threshold" path created. */
void predict_sums_xs(SV* sm_sv, int n_pts, double sum_threshold, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("predict_sums_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        av_store(out, i, newSViv(sm[i] <= sum_threshold ? 1 : 0));
    }
}

/* score_predict_xs(sm_sv, n_pts, inv, sum_threshold, out_rv)
 *
 * Combines finalize_scores_xs + predict_sums_xs: fills the pre-allocated
 * out_rv with [score, label] pairs in one pass over sm_sv.  Replaces the
 * trailing Perl loop in score_predict_samples that built ~3*n_pts SVs
 * (n_pts scores + n_pts labels + n_pts inner arrayrefs) via a Perl
 * foreach -- here the same SVs are allocated directly inside C.
 *
 * Refcount note: newRV_noinc takes ownership of the inner AV without
 * incrementing it, and av_store takes ownership of the RV.  When the
 * outer AV is destroyed it frees the RVs, which free the inner AVs,
 * which free the score/label SVs.  No leak. */
void score_predict_xs(SV* sm_sv, int n_pts, double inv,
                       double sum_threshold, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("score_predict_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        AV* row = newAV();
        av_extend(row, 1);
        /* av_extend filled both slots with &PL_sv_undef.  Since that
         * sentinel is immortal (its refcount is never freed) we can
         * overwrite the slots directly and bump AvFILLp, skipping the
         * per-element bounds/magic checks av_store would do. */
        AvARRAY(row)[0] = newSVnv(exp(-sm[i] * inv));
        AvARRAY(row)[1] = newSViv(sm[i] <= sum_threshold ? 1 : 0);
        AvFILLp(row)    = 1;
        av_store(out, i, newRV_noinc((SV*)row));
    }
}

/* score_predict_split_xs(sm_sv, n_pts, inv, sum_threshold,
 *                          scores_rv, labels_rv)
 *
 * Parallel-arrays variant of score_predict_xs: fills two pre-allocated
 * arrayrefs (scores: NV, labels: IV) instead of an AV-of-[score, label]
 * pairs.  Allocates ~2*n_pts SVs instead of ~4*n_pts -- no inner AV and
 * no RV per point -- so it's about twice as cheap for callers that
 * don't need the paired shape. */
void score_predict_split_xs(SV* sm_sv, int n_pts, double inv,
                             double sum_threshold,
                             SV* scores_rv, SV* labels_rv){
    STRLEN tl;
    const double* sm;
    AV* scores;
    AV* labels;
    int i;

    if (!SvROK(scores_rv) || SvTYPE(SvRV(scores_rv)) != SVt_PVAV ||
        !SvROK(labels_rv) || SvTYPE(SvRV(labels_rv)) != SVt_PVAV) {
        croak("score_predict_split_xs: scores/labels must be arrayrefs");
    }
    sm     = (const double*)SvPVbyte(sm_sv, tl);
    scores = (AV*)SvRV(scores_rv);
    labels = (AV*)SvRV(labels_rv);
    av_clear(scores);
    av_clear(labels);
    if (n_pts > 0) {
        av_extend(scores, n_pts - 1);
        av_extend(labels, n_pts - 1);
    }
    for (i = 0; i < n_pts; i++) {
        av_store(scores, i, newSVnv(exp(-sm[i] * inv)));
        av_store(labels, i, newSViv(sm[i] <= sum_threshold ? 1 : 0));
    }
}

/* Walk one point through one tree; returns the path length (depth plus
 * the precomputed c(leaf size) adjustment from the leaf record).
 *
 * Invariant: every feature index stored in a tree node is in
 * [0, n_feats).  fit() builds trees against n_features columns and
 * pack_input_xs writes exactly that many doubles per row, and
 * _resolve_input rejects PackedData with a mismatched feature count.
 * So the loop can omit per-iteration bounds checks on attr / fi --
 * this is what lets the oblique dot product vectorize cleanly under
 * the omp-simd reductions below. */
#if defined(__GNUC__) || defined(__clang__)
__attribute__((always_inline))
#endif
static inline double if_walk_tree(const double *nd, const int *ico,
                                  const double *vco, const double *xi,
                                  int n_feats) {
    int ni = 0, depth = 0;
    for (;;) {
        const double *node = nd + (size_t)ni * IF_NZ;
        int type = (int)node[0];
        if (type == 0) {
            /* node[2] is c(leaf size), precomputed by _pack_tree; a
             * log() here would otherwise run once per point per tree. */
            return depth + node[2];
        }
        if (type == 1) {
            double fv = xi[(int)node[1]];
            ni = (fv < node[2]) ? (int)node[3] : (int)node[4];
        } else {
            int coff = (int)node[1], nf = (int)node[2];
            double b = node[5], dot = 0.0;
            const double *val_p = vco + (size_t)coff;

            /* Both children are known before the dot product resolves
             * which one gets taken, so start pulling their records in
             * now and let the FMA loop below hide the latency.  One of
             * the two prefetches is always wasted -- affordable here
             * on the oblique path, where there is real work to hide it
             * under, but not on the axis path, whose single compare
             * resolves immediately. */
            const int li = (int)node[3], ri = (int)node[4];
            IF_PREFETCH(nd + (size_t)li * IF_NZ);
            IF_PREFETCH(nd + (size_t)ri * IF_NZ);
            if (nf == n_feats) {
                /* Dense oblique split: this node uses every feature,
                 * so _pack_tree laid the coefficients out in feature
                 * order.  No gather -- the inner loop is a textbook
                 * FMA-vectorizable dot product over two contiguous
                 * double streams.  Common case in extended mode at
                 * the default extension_level (== n_feats-1). */
                #ifdef _OPENMP
                #pragma omp simd reduction(+:dot)
                #endif
                for (int k = 0; k < n_feats; k++) {
                    dot += val_p[k] * xi[k];
                }
            } else {
                /* Sparse oblique split: only nf < n_feats features
                 * participate, so we still need the gather on
                 * xi[idx_p[k]].  Storing idx as contiguous int32
                 * (rather than interleaved doubles) keeps the gather
                 * pattern clean and the val[] load contiguous. */
                const int *idx_p = ico + (size_t)coff;
                #ifdef _OPENMP
                #pragma omp simd reduction(+:dot)
                #endif
                for (int k = 0; k < nf; k++) {
                    dot += val_p[k] * xi[idx_p[k]];
                }
            }
            ni = (dot <= b) ? li : ri;
        }
        depth++;
    }
}

/* score_all_xs(nodes_av, idx_av, val_av, x_sv, sm_sv,
 *              n_pts, n_feats, n_trees, use_openmp)
 *
 * Scores all points across all trees in one C call.  See header comment
 * above for the bigger picture.  Writes sm[i] = sum_over_trees(path_len);
 * the caller need not zero-init sm.
 *
 * idx_av holds per-tree packed int32 buffers of feature indices and
 * val_av holds per-tree packed double buffers of coefficients (the SoA
 * counterpart of the old interleaved layout).  See the file-top
 * comment for the rationale.
 *
 * Thread-safety: the parallel region only reads node/idx/val/x pointers
 * (extracted before the region) and writes sm[i] for a unique i per
 * iteration.  No Perl API is called from inside the parallel region. */
void score_all_xs(SV* nodes_av_sv, SV* idx_av_sv, SV* val_av_sv,
                  SV* x_sv, SV* sm_sv,
                  int n_pts, int n_feats, int n_trees,
                  int use_openmp){
    STRLEN tl;
    AV *nodes_av, *idx_av, *val_av;
    const double *xd;
    double *sm;
    int ti;

    if (!SvROK(nodes_av_sv) || SvTYPE(SvRV(nodes_av_sv)) != SVt_PVAV ||
        !SvROK(idx_av_sv)   || SvTYPE(SvRV(idx_av_sv))   != SVt_PVAV ||
        !SvROK(val_av_sv)   || SvTYPE(SvRV(val_av_sv))   != SVt_PVAV) {
        croak("score_all_xs: nodes/idx/val must be arrayrefs");
    }
    nodes_av = (AV*)SvRV(nodes_av_sv);
    idx_av   = (AV*)SvRV(idx_av_sv);
    val_av   = (AV*)SvRV(val_av_sv);

    /* C99 VLAs -- n_trees is small (typ. 100) and fits on the stack. */
    const double *node_ptrs[n_trees];
    const int    *idx_ptrs[n_trees];
    const double *val_ptrs[n_trees];

    /* forest_bytes totals every buffer the tree walks touch; it decides
     * between the two loop shapes below. */
    size_t forest_bytes = 0;
    for (ti = 0; ti < n_trees; ti++) {
        SV** np = av_fetch(nodes_av, ti, 0);
        SV** ip = av_fetch(idx_av,   ti, 0);
        SV** vp = av_fetch(val_av,   ti, 0);
        if (!np || !*np || !ip || !*ip || !vp || !*vp) {
            croak("score_all_xs: missing tree %d", ti);
        }
        node_ptrs[ti] = (const double*)SvPVbyte(*np, tl); forest_bytes += tl;
        idx_ptrs[ti]  = (const int*)   SvPVbyte(*ip, tl); forest_bytes += tl;
        val_ptrs[ti]  = (const double*)SvPVbyte(*vp, tl); forest_bytes += tl;
    }

    xd = (const double*)SvPVbyte(x_sv, tl);
    sm = (double*)SvPVbyte_force(sm_sv, tl);

    /* Two loop shapes over the same per-point ascending-t additions --
     * bit-identical results either way, so the size heuristic choosing
     * between them can never change scores.
     *
     * Point-major (small forests): each point walks all trees with its
     * path-length sum held in a register.  Cheapest per walk, and the
     * whole forest stays cache-resident across points anyway.
     *
     * Tree-blocked (large forests): once the forest outgrows L3, the
     * point-major loop re-streams every tree's nodes and coefficients
     * from memory for every point -- an extended-mode tree is ~56 KB
     * at 16 features (24 KB nodes + 32 KB dense coefficients), and its
     * per-tree scoring cost measured 2.2x worse at 400 trees than at
     * 100.  Walking a block of points through ONE tree at a time keeps
     * that tree hot in L1/L2 while the block's rows stream through it
     * (measured 3.1x faster at 400 extended trees, 20k points).  The
     * blocked shape pays an sm[i] load+store per walk instead of a
     * register add, which measurably hurts cheap axis walks while the
     * forest still fits in cache -- hence the byte threshold rather
     * than always tiling. */
    if (forest_bytes <= (size_t)4 * 1024 * 1024) {
#ifdef _OPENMP
        #pragma omp parallel for schedule(static) if(use_openmp)
#endif
        for (int i = 0; i < n_pts; i++) {
            const double *xi = xd + (size_t)i * (size_t)n_feats;
            double sum = 0.0;
            for (int t = 0; t < n_trees; t++) {
                sum += if_walk_tree(node_ptrs[t], idx_ptrs[t],
                                    val_ptrs[t], xi, n_feats);
            }
            sm[i] = sum;
        }
    }
    else {
        /* 256 rows x 16 features x 8 bytes = 32 KB of input per block
         * -- comfortable in L2 next to one tree.  Each OpenMP thread
         * owns whole blocks and therefore a unique slice of sm[], so
         * there is still no synchronisation.  For small batches the
         * tile shrinks to keep ~4 blocks per thread available; losing
         * per-block tree reuse there is fine, since a small batch
         * never re-streams much anyway. */
        int tile = 256;
#ifdef _OPENMP
        if (use_openmp) {
            int min_blocks = omp_get_max_threads() * 4;
            if (min_blocks > 0 && (n_pts + tile - 1) / tile < min_blocks) {
                tile = (n_pts + min_blocks - 1) / min_blocks;
                if (tile < 1) tile = 1;
            }
        }
#endif
        int n_blocks = (n_pts + tile - 1) / tile;

#ifdef _OPENMP
        #pragma omp parallel for schedule(static) if(use_openmp)
#endif
        for (int blk = 0; blk < n_blocks; blk++) {
            const int i0 = blk * tile;
            const int i1 = (i0 + tile < n_pts) ? i0 + tile : n_pts;
            for (int i = i0; i < i1; i++) sm[i] = 0.0;
            for (int t = 0; t < n_trees; t++) {
                const double *nd  = node_ptrs[t];
                const int    *ico = idx_ptrs[t];
                const double *vco = val_ptrs[t];
                for (int i = i0; i < i1; i++) {
                    sm[i] += if_walk_tree(nd, ico, vco,
                                          xd + (size_t)i * (size_t)n_feats,
                                          n_feats);
                }
            }
        }
    }
}

/* vote_all_xs(nodes_av, idx_av, val_av, x_sv, sm_sv,
 *             n_pts, n_feats, n_trees, depth_cut, min_votes, use_openmp)
 *
 * Majority-voting (MVIForest) tree walk: a tree votes a point anomalous
 * when the point's path length in that tree is <= depth_cut -- the
 * depth-domain image of the per-tree score cutoff (the Perl side
 * precomputes depth_cut = -c(psi) * log2(threshold), so no per-tree
 * exp()/log() runs in here).
 *
 * min_votes == 0: sm[i] = the point's full vote count over all n_trees
 *   trees (a small integer stored as a double, so the existing
 *   finalize_* helpers work on the buffer unchanged).
 * min_votes > 0:  sm[i] = 1.0/0.0 anomaly label, with per-point early
 *   exit: the walk stops as soon as the point has min_votes votes (the
 *   remaining trees can't change the outcome) or can no longer reach
 *   min_votes.  This is MVIForest's "stop at majority" scoring loop.
 *
 * Always point-major, unlike score_all_xs's two loop shapes: the vote
 * count / early exit is per-point state, so a tree-blocked loop would
 * have to re-load it per walk and could never exit a point early.
 * Votes are integer counts, so there is no summation-order concern
 * either way.  Thread-safety matches score_all_xs: the parallel region
 * reads extracted pointers and writes a unique sm[i] per iteration. */
void vote_all_xs(SV* nodes_av_sv, SV* idx_av_sv, SV* val_av_sv,
                 SV* x_sv, SV* sm_sv,
                 int n_pts, int n_feats, int n_trees,
                 double depth_cut, int min_votes, int use_openmp){
    STRLEN tl;
    AV *nodes_av, *idx_av, *val_av;
    const double *xd;
    double *sm;
    int ti;

    if (!SvROK(nodes_av_sv) || SvTYPE(SvRV(nodes_av_sv)) != SVt_PVAV ||
        !SvROK(idx_av_sv)   || SvTYPE(SvRV(idx_av_sv))   != SVt_PVAV ||
        !SvROK(val_av_sv)   || SvTYPE(SvRV(val_av_sv))   != SVt_PVAV) {
        croak("vote_all_xs: nodes/idx/val must be arrayrefs");
    }
    nodes_av = (AV*)SvRV(nodes_av_sv);
    idx_av   = (AV*)SvRV(idx_av_sv);
    val_av   = (AV*)SvRV(val_av_sv);

    const double *node_ptrs[n_trees];
    const int    *idx_ptrs[n_trees];
    const double *val_ptrs[n_trees];

    for (ti = 0; ti < n_trees; ti++) {
        SV** np = av_fetch(nodes_av, ti, 0);
        SV** ip = av_fetch(idx_av,   ti, 0);
        SV** vp = av_fetch(val_av,   ti, 0);
        if (!np || !*np || !ip || !*ip || !vp || !*vp) {
            croak("vote_all_xs: missing tree %d", ti);
        }
        node_ptrs[ti] = (const double*)SvPVbyte(*np, tl);
        idx_ptrs[ti]  = (const int*)   SvPVbyte(*ip, tl);
        val_ptrs[ti]  = (const double*)SvPVbyte(*vp, tl);
    }

    xd = (const double*)SvPVbyte(x_sv, tl);
    sm = (double*)SvPVbyte_force(sm_sv, tl);

#ifdef _OPENMP
    #pragma omp parallel for schedule(static) if(use_openmp)
#endif
    for (int i = 0; i < n_pts; i++) {
        const double *xi = xd + (size_t)i * (size_t)n_feats;
        int votes = 0;
        if (min_votes > 0) {
            double label = 0.0;
            for (int t = 0; t < n_trees; t++) {
                if (if_walk_tree(node_ptrs[t], idx_ptrs[t],
                                 val_ptrs[t], xi, n_feats) <= depth_cut) {
                    votes++;
                    if (votes >= min_votes) { label = 1.0; break; }
                }
                if (votes + (n_trees - 1 - t) < min_votes) break;
            }
            sm[i] = label;
        } else {
            for (int t = 0; t < n_trees; t++) {
                votes += (if_walk_tree(node_ptrs[t], idx_ptrs[t],
                                       val_ptrs[t], xi, n_feats)
                          <= depth_cut) ? 1 : 0;
            }
            sm[i] = (double)votes;
        }
    }
}

/* vote_labels_xs(sm_sv, n_pts, out_rv)
 *
 * Converts the 0.0/1.0 label buffer vote_all_xs writes in early-exit
 * mode into an arrayref of 0/1 IVs -- the majority-voting counterpart
 * of predict_sums_xs (whose <= comparison points the wrong way for
 * vote counts, where HIGH means anomalous). */
void vote_labels_xs(SV* sm_sv, int n_pts, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("vote_labels_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        av_store(out, i, newSViv(sm[i] != 0.0 ? 1 : 0));
    }
}

/* vote_score_predict_xs(sm_sv, n_pts, t, min_votes, out_rv)
 *
 * Fills out_rv with [vote_fraction, majority_label] pairs from a
 * vote-count buffer (vote_all_xs with min_votes == 0): score is
 * votes/t, label is votes >= min_votes.  Same allocation pattern and
 * refcount discipline as score_predict_xs. */
void vote_score_predict_xs(SV* sm_sv, int n_pts, double t,
                            double min_votes, SV* out_rv){
    STRLEN tl;
    const double* sm;
    AV* out;
    int i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("vote_score_predict_xs: out must be an arrayref");
    }
    sm  = (const double*)SvPVbyte(sm_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_pts > 0) av_extend(out, n_pts - 1);
    for (i = 0; i < n_pts; i++) {
        AV* row = newAV();
        av_extend(row, 1);
        AvARRAY(row)[0] = newSVnv(sm[i] / t);
        AvARRAY(row)[1] = newSViv(sm[i] >= min_votes ? 1 : 0);
        AvFILLp(row)    = 1;
        av_store(out, i, newRV_noinc((SV*)row));
    }
}

/* vote_score_predict_split_xs(sm_sv, n_pts, t, min_votes,
 *                              scores_rv, labels_rv)
 *
 * Parallel-arrays variant of vote_score_predict_xs, mirroring
 * score_predict_split_xs's shape for the majority-voting path. */
void vote_score_predict_split_xs(SV* sm_sv, int n_pts, double t,
                                  double min_votes,
                                  SV* scores_rv, SV* labels_rv){
    STRLEN tl;
    const double* sm;
    AV* scores;
    AV* labels;
    int i;

    if (!SvROK(scores_rv) || SvTYPE(SvRV(scores_rv)) != SVt_PVAV ||
        !SvROK(labels_rv) || SvTYPE(SvRV(labels_rv)) != SVt_PVAV) {
        croak("vote_score_predict_split_xs: scores/labels must be arrayrefs");
    }
    sm     = (const double*)SvPVbyte(sm_sv, tl);
    scores = (AV*)SvRV(scores_rv);
    labels = (AV*)SvRV(labels_rv);
    av_clear(scores);
    av_clear(labels);
    if (n_pts > 0) {
        av_extend(scores, n_pts - 1);
        av_extend(labels, n_pts - 1);
    }
    for (i = 0; i < n_pts; i++) {
        av_store(scores, i, newSVnv(sm[i] / t));
        av_store(labels, i, newSViv(sm[i] >= min_votes ? 1 : 0));
    }
}

/* ---------------------------------------------------------------------
 * build_forest_xs -- C-accelerated fit() tree builder.
 *
 * Replaces the pure-Perl _subsample + _build_tree + _axis_split /
 * _oblique_split recursion with an equivalent C implementation that
 * partitions plain `int` row-index arrays instead of copying arrayrefs
 * of Perl SVs at every split.  Random draws go through Drand01() --
 * the exact generator Perl's own rand()/srand() use internally -- in
 * the same call order the Perl code used, so a fit() with a given
 * seed produces BIT-IDENTICAL trees whether use_c is on or off.  This
 * is what lets fit() reuse the existing `use_c` knob instead of a new
 * one: switching backends never changes the model, only how fast it's
 * built.  (Verified by t/02-accel-selection.t's "identical seed =>
 * identical trees" subtest, which exercises both backends.)
 *
 * Output trees are plain Perl arrayrefs in the same node shape
 * _build_tree produces (leaf/axis/oblique -- see the file-top
 * comment), so every downstream consumer (_pack_tree, to_json,
 * from_json, the pure-Perl scorer) is unchanged.
 *
 * x_sv: packed row-major double buffer, n_pts rows of n_feats each
 *       (from pack_input_xs -- NaN marks a missing cell under the
 *       'nan' missing-strategy).
 * mode_flag: 0 => axis-parallel splits, 1 => oblique (extended).
 * ext_level: extension_level_used (ignored when mode_flag == 0).
 * out_rv: pre-existing arrayref; filled with n_trees tree roots.
 * ------------------------------------------------------------------ */

/* Box-Muller normal draw, in the same rand() call order as _randn(). */
static double _c_randn(pTHX) {
    double u1 = Drand01();
    double u2;
    if (u1 == 0.0) u1 = 1e-12;
    u2 = Drand01();
    return sqrt(-2.0 * log(u1)) * cos(6.283185307179586 * u2);
}

static SV* _mk_leaf(pTHX_ int size) {
    AV* av = newAV();
    av_extend(av, 1);
    AvARRAY(av)[0] = newSVnv(0.0);
    AvARRAY(av)[1] = newSViv(size);
    AvFILLp(av)    = 1;
    return newRV_noinc((SV*)av);
}

static SV* _mk_axis(pTHX_ int attr, double split, SV* left, SV* right) {
    AV* av = newAV();
    av_extend(av, 4);
    AvARRAY(av)[0] = newSVnv(1.0);
    AvARRAY(av)[1] = newSViv(attr);
    AvARRAY(av)[2] = newSVnv(split);
    AvARRAY(av)[3] = left;
    AvARRAY(av)[4] = right;
    AvFILLp(av)    = 4;
    return newRV_noinc((SV*)av);
}

static SV* _mk_oblique(pTHX_ const int* idx, const double* coef, int n,
                        double b, SV* left, SV* right) {
    AV *iav, *cav, *av;
    int k;
    iav = newAV();
    cav = newAV();
    if (n > 0) {
        av_extend(iav, n - 1);
        av_extend(cav, n - 1);
    }
    for (k = 0; k < n; k++) {
        AvARRAY(iav)[k] = newSViv(idx[k]);
        AvARRAY(cav)[k] = newSVnv(coef[k]);
    }
    AvFILLp(iav) = n - 1;
    AvFILLp(cav) = n - 1;

    av = newAV();
    av_extend(av, 5);
    AvARRAY(av)[0] = newSVnv(2.0);
    AvARRAY(av)[1] = newRV_noinc((SV*)iav);
    AvARRAY(av)[2] = newRV_noinc((SV*)cav);
    AvARRAY(av)[3] = newSVnv(b);
    AvARRAY(av)[4] = left;
    AvARRAY(av)[5] = right;
    AvFILLp(av)    = 5;
    return newRV_noinc((SV*)av);
}

/* Builds one node from the point set `idxs` (row indices into `x`,
 * length `size`); recurses left-then-right, matching _build_tree's
 * traversal order so nested splits draw random numbers in the same
 * sequence the pure-Perl path would.  Takes ownership of `idxs` --
 * frees it before returning. */
static SV* _build_node_c(pTHX_ const double* x, int nf, int* idxs, int size,
                          int depth, int limit, int mode_flag,
                          int ext_active) {
    double *lo, *hi;
    int *varying, nv, f;
    SV *result;

    if (depth >= limit || size <= 1) {
        SV* leaf = _mk_leaf(aTHX_ size);
        free(idxs);
        return leaf;
    }

    lo = (double*)malloc(nf * sizeof(double));
    hi = (double*)malloc(nf * sizeof(double));
    for (f = 0; f < nf; f++) {
        lo[f] = HUGE_VAL;
        hi[f] = -HUGE_VAL;
    }
    for (int i = 0; i < size; i++) {
        const double* row = x + (size_t)idxs[i] * (size_t)nf;
        /* No isnan() guard needed: NaN < x and NaN > x are always false
         * under IEEE 754, so a NaN cell (the 'nan' missing strategy)
         * already leaves lo/hi untouched without an explicit check --
         * one less branch, and it's what lets this loop vectorize
         * cleanly as a plain elementwise min/max scan. */
        #ifdef _OPENMP
        #pragma omp simd
        #endif
        for (int f2 = 0; f2 < nf; f2++) {
            double v = row[f2];
            if (v < lo[f2]) lo[f2] = v;
            if (v > hi[f2]) hi[f2] = v;
        }
    }

    varying = (int*)malloc(nf * sizeof(int));
    nv      = 0;
    for (f = 0; f < nf; f++) {
        if (lo[f] < hi[f]) varying[nv++] = f;
    }

    if (nv == 0) {
        free(lo); free(hi); free(varying);
        SV* leaf = _mk_leaf(aTHX_ size);
        free(idxs);
        return leaf;
    }

    if (mode_flag == 0) {
        /* Axis-parallel split: one varying feature, one threshold. */
        int attr      = varying[(int)(Drand01() * nv)];
        double split  = lo[attr] + Drand01() * (hi[attr] - lo[attr]);
        int *lidx = (int*)malloc(size * sizeof(int));
        int *ridx = (int*)malloc(size * sizeof(int));
        int ln = 0, rn = 0, i;
        SV *left, *right;

        for (i = 0; i < size; i++) {
            int row = idxs[i];
            double v = x[(size_t)row * (size_t)nf + attr];
            if (v < split) lidx[ln++] = row; else ridx[rn++] = row;
        }
        free(idxs); free(lo); free(hi); free(varying);

        left  = _build_node_c(aTHX_ x, nf, lidx, ln, depth + 1, limit,
                               mode_flag, ext_active);
        right = _build_node_c(aTHX_ x, nf, ridx, rn, depth + 1, limit,
                               mode_flag, ext_active);
        result = _mk_axis(aTHX_ attr, split, left, right);
    } else {
        /* Oblique split: a random hyperplane over `active` features. */
        int active = ext_active + 1;
        int *pool, *lidx, *ridx;
        double *coef;
        double b = 0.0;
        int ln = 0, rn = 0, i, k;
        SV *left, *right;

        if (active > nv) active = nv;
        pool = (int*)malloc(nv * sizeof(int));
        memcpy(pool, varying, nv * sizeof(int));
        for (i = 0; i < active; i++) {
            int j = i + (int)(Drand01() * (nv - i));
            int tmp = pool[i]; pool[i] = pool[j]; pool[j] = tmp;
        }

        coef = (double*)malloc(active * sizeof(double));
        for (k = 0; k < active; k++) {
            int ff  = pool[k];
            double c = _c_randn(aTHX);
            double p = lo[ff] + Drand01() * (hi[ff] - lo[ff]);
            coef[k] = c;
            b += c * p;
        }

        lidx = (int*)malloc(size * sizeof(int));
        ridx = (int*)malloc(size * sizeof(int));
        for (i = 0; i < size; i++) {
            int row = idxs[i];
            double dot = 0.0;
            for (k = 0; k < active; k++) {
                dot += coef[k] * x[(size_t)row * (size_t)nf + pool[k]];
            }
            if (dot <= b) lidx[ln++] = row; else ridx[rn++] = row;
        }
        free(idxs); free(lo); free(hi); free(varying);

        left  = _build_node_c(aTHX_ x, nf, lidx, ln, depth + 1, limit,
                               mode_flag, ext_active);
        right = _build_node_c(aTHX_ x, nf, ridx, rn, depth + 1, limit,
                               mode_flag, ext_active);
        result = _mk_oblique(aTHX_ pool, coef, active, b, left, right);
        free(pool); free(coef);
    }
    return result;
}

void build_forest_xs(SV* x_sv, int n_pts, int n_feats, int n_trees,
                      int psi, int limit, int mode_flag, int ext_level,
                      SV* out_rv) {
    dTHX;
    STRLEN tl;
    const double* x;
    AV* out;
    int* all;
    int t, i;

    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("build_forest_xs: out must be an arrayref");
    }
    x   = (const double*)SvPVbyte(x_sv, tl);
    out = (AV*)SvRV(out_rv);
    av_clear(out);
    if (n_trees > 0) av_extend(out, n_trees - 1);

    all = (int*)malloc(n_pts * sizeof(int));
    for (t = 0; t < n_trees; t++) {
        int* sample;

        for (i = 0; i < n_pts; i++) all[i] = i;
        for (i = 0; i < psi; i++) {
            int j = i + (int)(Drand01() * (n_pts - i));
            int tmp = all[i]; all[i] = all[j]; all[j] = tmp;
        }
        sample = (int*)malloc(psi * sizeof(int));
        memcpy(sample, all, psi * sizeof(int));

        av_store(out, t,
            _build_node_c(aTHX_ x, n_feats, sample, psi, 0, limit,
                          mode_flag, ext_level));
    }
    free(all);
}

/* ---------------------------------------------------------------------
 * build_forest_openmp_xs -- OpenMP-parallel fit() tree builder.
 *
 * build_forest_xs (above) is bit-identical to the pure-Perl path
 * because every random draw goes through Drand01(), the same
 * generator Perl's rand()/srand() use -- but that generator is a
 * single mutable struct shared by the whole interpreter, so calling
 * it concurrently from multiple OpenMP threads would be a data race.
 * The same is true of any Perl API call (newAV, newSViv, ...): Perl's
 * SV allocator isn't safe to call from multiple OS threads sharing one
 * interpreter without a lock that would just serialise everything
 * anyway.
 *
 * So this builder trades the bit-identical guarantee for real thread
 * parallelism: each tree gets its own splitmix64 PRNG stream, seeded
 * from a tree index (not thread id or scheduling order), so results
 * are still reproducible for a fixed seed and n_trees regardless of
 * OMP_NUM_THREADS -- just different from what build_forest_xs or the
 * pure-Perl path would produce for the same seed. The one Drand01()
 * call in this function happens before the parallel region starts
 * (single-threaded), so the result still varies with the model's
 * `seed` the way every other code path does; it isn't used inside the
 * parallel loop.
 *
 * Each tree is built entirely with plain C data (row-index int arrays,
 * a growable TreeBuf of packed doubles/ints) -- no Perl API call
 * happens anywhere inside the parallel region. Each node record in
 * TreeBuf uses _pack_tree's 6-double SoA layout (see the file-top
 * comment), but the node ORDER differs: records are appended
 * post-order (a node is pushed after both its children, since child
 * indices must be known first), so the root is the last record --
 * _pack_tree's pre-order puts it at 0.  _unpack_forest accounts for
 * this.  Oblique coefficients are also always stored sparse (in the
 * random pool's order) -- the dense-pack fast path is skipped because
 * its only purpose is speeding up score_all_xs, and _rebuild_c_trees
 * reapplies it anyway once the caller unpacks these buffers back into
 * the standard Perl tree shape and re-derives the scoring buffers.
 *
 * After the parallel region, each tree's TreeBuf is copied into a Perl
 * string SV (one memcpy each, serially) and stored into nodes_rv /
 * idx_rv / val_rv -- the caller unpacks these into ordinary nested
 * Perl trees for $self->{trees} (so to_json/persistence/_rebuild_c_trees
 * are unaffected). ------------------------------------------------ */

typedef struct {
    double *nodes; size_t n_nodes, cap_nodes;
    int    *idx;   size_t n_idx,   cap_idx;
    double *val;   size_t n_val,   cap_val;
} TreeBuf;

static void tb_init(TreeBuf *b) {
    b->nodes = NULL; b->n_nodes = 0; b->cap_nodes = 0;
    b->idx   = NULL; b->n_idx   = 0; b->cap_idx   = 0;
    b->val   = NULL; b->n_val   = 0; b->cap_val   = 0;
}

static void tb_free(TreeBuf *b) {
    free(b->nodes); free(b->idx); free(b->val);
}

static int tb_push_node(TreeBuf *b, double f0, double f1, double f2,
                         double f3, double f4, double f5) {
    double *slot;
    if (b->n_nodes == b->cap_nodes) {
        size_t newcap = b->cap_nodes ? b->cap_nodes * 2 : 64;
        b->nodes = (double*)realloc(b->nodes, newcap * 6 * sizeof(double));
        b->cap_nodes = newcap;
    }
    slot = b->nodes + b->n_nodes * 6;
    slot[0] = f0; slot[1] = f1; slot[2] = f2;
    slot[3] = f3; slot[4] = f4; slot[5] = f5;
    return (int)(b->n_nodes++);
}

/* Appends n (idx[k], val[k]) pairs and returns the offset they start
 * at -- the `coff` an oblique node record stores. */
static int tb_push_coef(TreeBuf *b, const int *idx, const double *val,
                         int n) {
    int off = (int)b->n_idx;
    if (b->n_idx + (size_t)n > b->cap_idx) {
        size_t newcap = b->cap_idx ? b->cap_idx * 2 : 64;
        if (newcap < b->n_idx + (size_t)n) newcap = b->n_idx + (size_t)n;
        b->idx     = (int*)realloc(b->idx, newcap * sizeof(int));
        b->cap_idx = newcap;
    }
    if (b->n_val + (size_t)n > b->cap_val) {
        size_t newcap = b->cap_val ? b->cap_val * 2 : 64;
        if (newcap < b->n_val + (size_t)n) newcap = b->n_val + (size_t)n;
        b->val     = (double*)realloc(b->val, newcap * sizeof(double));
        b->cap_val = newcap;
    }
    memcpy(b->idx + b->n_idx, idx, (size_t)n * sizeof(int));
    memcpy(b->val + b->n_val, val, (size_t)n * sizeof(double));
    b->n_idx += n;
    b->n_val += n;
    return off;
}

/* splitmix64 -- fast, well-mixed, and per-stream state fits in one
 * uint64_t, which is all a thread-private PRNG needs here. Not
 * cryptographic; doesn't need to be. */
static uint64_t sm64_next(uint64_t *s) {
    uint64_t z = (*s += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

static double sm64_drand(uint64_t *s) {
    return (double)(sm64_next(s) >> 11) * (1.0 / 9007199254740992.0);
}

static double _ts_randn(uint64_t *s) {
    double u1 = sm64_drand(s);
    double u2;
    if (u1 == 0.0) u1 = 1e-12;
    u2 = sm64_drand(s);
    return sqrt(-2.0 * log(u1)) * cos(6.283185307179586 * u2);
}

/* Thread-safe twin of _build_node_c: same split algorithm, but reads
 * randomness from a thread-private splitmix64 stream instead of
 * Drand01(), and writes into a TreeBuf instead of allocating Perl AVs
 * -- so it touches no interpreter-global state and is safe to call
 * concurrently from an OpenMP parallel region, one tree per thread. */
static int _build_node_packed(const double* x, int nf, int* idxs, int size,
                               int depth, int limit, int mode_flag,
                               int ext_active, TreeBuf *buf, uint64_t *rng) {
    double *lo, *hi;
    int *varying, nv, f, my_idx;

    if (depth >= limit || size <= 1) {
        my_idx = tb_push_node(buf, 0.0, (double)size, 0.0, 0.0, 0.0, 0.0);
        free(idxs);
        return my_idx;
    }

    lo = (double*)malloc(nf * sizeof(double));
    hi = (double*)malloc(nf * sizeof(double));
    for (f = 0; f < nf; f++) {
        lo[f] = HUGE_VAL;
        hi[f] = -HUGE_VAL;
    }
    for (int i = 0; i < size; i++) {
        const double* row = x + (size_t)idxs[i] * (size_t)nf;
        /* See the matching comment in _build_node_c: no isnan() guard
         * needed, since NaN < x / NaN > x are always false already --
         * that's what lets this vectorize as a plain min/max scan.
         * omp simd here is thread-safe to call from inside the caller's
         * omp parallel region: it's a per-thread vectorization hint,
         * not a team construct, so it doesn't nest into anything. */
        #ifdef _OPENMP
        #pragma omp simd
        #endif
        for (int f2 = 0; f2 < nf; f2++) {
            double v = row[f2];
            if (v < lo[f2]) lo[f2] = v;
            if (v > hi[f2]) hi[f2] = v;
        }
    }

    varying = (int*)malloc(nf * sizeof(int));
    nv      = 0;
    for (f = 0; f < nf; f++) {
        if (lo[f] < hi[f]) varying[nv++] = f;
    }

    if (nv == 0) {
        free(lo); free(hi); free(varying);
        my_idx = tb_push_node(buf, 0.0, (double)size, 0.0, 0.0, 0.0, 0.0);
        free(idxs);
        return my_idx;
    }

    if (mode_flag == 0) {
        int attr     = varying[(int)(sm64_drand(rng) * nv)];
        double split = lo[attr] + sm64_drand(rng) * (hi[attr] - lo[attr]);
        int *lidx = (int*)malloc(size * sizeof(int));
        int *ridx = (int*)malloc(size * sizeof(int));
        int ln = 0, rn = 0, i, li, ri;

        for (i = 0; i < size; i++) {
            int row  = idxs[i];
            double v = x[(size_t)row * (size_t)nf + attr];
            if (v < split) lidx[ln++] = row; else ridx[rn++] = row;
        }
        free(idxs); free(lo); free(hi); free(varying);

        li = _build_node_packed(x, nf, lidx, ln, depth + 1, limit,
                                 mode_flag, ext_active, buf, rng);
        ri = _build_node_packed(x, nf, ridx, rn, depth + 1, limit,
                                 mode_flag, ext_active, buf, rng);
        my_idx = tb_push_node(buf, 1.0, (double)attr, split,
                               (double)li, (double)ri, 0.0);
    } else {
        int active = ext_active + 1;
        int *pool, *lidx, *ridx;
        double *coef;
        double b = 0.0;
        int ln = 0, rn = 0, i, k, li, ri, coff;

        if (active > nv) active = nv;
        pool = (int*)malloc(nv * sizeof(int));
        memcpy(pool, varying, nv * sizeof(int));
        for (i = 0; i < active; i++) {
            int j = i + (int)(sm64_drand(rng) * (nv - i));
            int tmp = pool[i]; pool[i] = pool[j]; pool[j] = tmp;
        }

        coef = (double*)malloc(active * sizeof(double));
        for (k = 0; k < active; k++) {
            int ff   = pool[k];
            double c = _ts_randn(rng);
            double p = lo[ff] + sm64_drand(rng) * (hi[ff] - lo[ff]);
            coef[k]  = c;
            b += c * p;
        }

        lidx = (int*)malloc(size * sizeof(int));
        ridx = (int*)malloc(size * sizeof(int));
        for (i = 0; i < size; i++) {
            int row    = idxs[i];
            double dot = 0.0;
            for (k = 0; k < active; k++) {
                dot += coef[k] * x[(size_t)row * (size_t)nf + pool[k]];
            }
            if (dot <= b) lidx[ln++] = row; else ridx[rn++] = row;
        }
        free(idxs); free(lo); free(hi); free(varying);

        li = _build_node_packed(x, nf, lidx, ln, depth + 1, limit,
                                 mode_flag, ext_active, buf, rng);
        ri = _build_node_packed(x, nf, ridx, rn, depth + 1, limit,
                                 mode_flag, ext_active, buf, rng);
        coff   = tb_push_coef(buf, pool, coef, active);
        my_idx = tb_push_node(buf, 2.0, (double)coff, (double)active,
                               (double)li, (double)ri, b);
        free(pool); free(coef);
    }
    return my_idx;
}

void build_forest_openmp_xs(SV* x_sv, int n_pts, int n_feats, int n_trees,
                             int psi, int limit, int mode_flag,
                             int ext_level, SV* nodes_rv, SV* idx_rv,
                             SV* val_rv, int use_openmp) {
    dTHX;
    STRLEN tl;
    const double* x;
    AV *nodes_av, *idx_av, *val_av;
    TreeBuf *bufs;
    uint64_t base_seed;
    int t;

    if (!SvROK(nodes_rv) || SvTYPE(SvRV(nodes_rv)) != SVt_PVAV ||
        !SvROK(idx_rv)   || SvTYPE(SvRV(idx_rv))   != SVt_PVAV ||
        !SvROK(val_rv)   || SvTYPE(SvRV(val_rv))   != SVt_PVAV) {
        croak("build_forest_openmp_xs: nodes/idx/val must be arrayrefs");
    }
    x        = (const double*)SvPVbyte(x_sv, tl);
    nodes_av = (AV*)SvRV(nodes_rv);
    idx_av   = (AV*)SvRV(idx_rv);
    val_av   = (AV*)SvRV(val_rv);
    av_clear(nodes_av); av_clear(idx_av); av_clear(val_av);
    if (n_trees > 0) {
        av_extend(nodes_av, n_trees - 1);
        av_extend(idx_av,   n_trees - 1);
        av_extend(val_av,   n_trees - 1);
    }

    /* Single Drand01() call, before the parallel region starts, so it's
     * still a plain serial call into the interpreter's RNG state. */
    base_seed = (uint64_t)(Drand01() * 18446744073709551615.0);

    bufs = (TreeBuf*)malloc((size_t)n_trees * sizeof(TreeBuf));
    for (t = 0; t < n_trees; t++) tb_init(&bufs[t]);

    #ifdef _OPENMP
    #pragma omp parallel for schedule(dynamic) if(use_openmp)
    #endif
    for (int t = 0; t < n_trees; t++) {
        /* Seeded from the tree index, not thread id or iteration order,
         * so the mapping from tree -> RNG stream is independent of
         * OMP_NUM_THREADS / scheduling.  sm64_next() mixes once more so
         * adjacent tree indices (which differ by one golden-ratio step)
         * don't start from too-similar states. */
        uint64_t rng = base_seed + (uint64_t)t * 0x9E3779B97F4A7C15ULL;
        rng = sm64_next(&rng);
        int *all = (int*)malloc((size_t)n_pts * sizeof(int));
        int *sample;
        int i;

        for (i = 0; i < n_pts; i++) all[i] = i;
        for (i = 0; i < psi; i++) {
            int j = i + (int)(sm64_drand(&rng) * (n_pts - i));
            int tmp = all[i]; all[i] = all[j]; all[j] = tmp;
        }
        sample = (int*)malloc((size_t)psi * sizeof(int));
        memcpy(sample, all, (size_t)psi * sizeof(int));
        free(all);

        _build_node_packed(x, n_feats, sample, psi, 0, limit, mode_flag,
                            ext_level, &bufs[t], &rng);
    }

    for (t = 0; t < n_trees; t++) {
        /* newSVpvn(NULL, 0) makes an undef SV, not an empty-string one --
         * axis-mode trees never call tb_push_coef, so idx/val stay NULL.
         * Pass "" instead so the Perl side's unpack('...', $sv) always
         * gets a defined (if empty) string, never undef. */
        av_store(nodes_av, t, newSVpvn((char*)bufs[t].nodes,
                     bufs[t].n_nodes * 6 * sizeof(double)));
        av_store(idx_av, t, bufs[t].n_idx
                     ? newSVpvn((char*)bufs[t].idx, bufs[t].n_idx * sizeof(int))
                     : newSVpvn("", 0));
        av_store(val_av, t, bufs[t].n_val
                     ? newSVpvn((char*)bufs[t].val, bufs[t].n_val * sizeof(double))
                     : newSVpvn("", 0));
        tb_free(&bufs[t]);
    }
    free(bufs);
}

/* ---------------------------------------------------------------------
 * pack_tree_xs(root_rv, n_features, nodes_sv, idx_sv, val_sv)
 *
 * C image of _pack_tree: flattens one tree into the three packed buffers
 * the scorer walks.  _rebuild_c_trees runs it once per tree at the end of
 * every fit() and every from_json(), and in Perl each node costs a
 * recursive closure call, an arrayref and six SVs, plus a trailing map
 * that pushes every one of those SVs back onto the stack for pack() --
 * which made it the largest single phase of an axis-mode fit.  This is
 * the same walk done in C, appending into the TreeBuf above and handing
 * the three buffers back as plain strings.
 *
 * The layout is unchanged: nodes are numbered DFS pre-order (a node's
 * record is reserved before its children recurse, so the root is 0 and
 * every child index sits above its parent's -- unlike the post-order
 * _build_node_packed above), oblique coefficients dense-pack in feature
 * order when a node uses every feature, and a leaf's slot 2 carries
 * c(size).  Output is byte-identical to the Perl path.
 *
 * The Perl side only calls this on nvsize == 8 perls: c(size) is computed
 * here in C doubles, and a wide-NV perl's _c() keeps extra low bits, so
 * the stored leaf adjustment would otherwise differ in the last ulp
 * between backends -- the same parity concern _NV_IS_DOUBLE guards
 * everywhere else.
 * ------------------------------------------------------------------ */

/* Scratch reused across every node of a tree, so packing a node
 * allocates nothing.  Grown on demand rather than sized once from
 * n_features: a model saved before n_features was persisted packs with
 * n_features == -1, which leaves no up-front bound on an oblique node's
 * coefficient count. */
typedef struct {
    double *dense;    /* coefficients by feature index, for the dense pack */
    int    *order;    /* 0..cap-1 -- the dense pack's index array */
    int    *ix;       /* sparse pack scratch */
    double *cv;
    int     cap;
} PackScratch;

static void ps_init(PackScratch *s) {
    s->dense = NULL; s->order = NULL; s->ix = NULL; s->cv = NULL; s->cap = 0;
}

static void ps_free(PackScratch *s) {
    free(s->dense); free(s->order); free(s->ix); free(s->cv);
}

static void ps_reserve(PackScratch *s, int n) {
    int k;
    if (n <= s->cap) return;
    s->dense = (double*)realloc(s->dense, (size_t)n * sizeof(double));
    s->order = (int*)   realloc(s->order, (size_t)n * sizeof(int));
    s->ix    = (int*)   realloc(s->ix,    (size_t)n * sizeof(int));
    s->cv    = (double*)realloc(s->cv,    (size_t)n * sizeof(double));
    for (k = s->cap; k < n; k++) s->order[k] = k;
    s->cap = n;
}

/* c(n) -- the expression _c() evaluates, operation for operation. */
static double _pt_c(double n) {
    double harmonic;
    if (n <= 1.0) return 0.0;
    if (n == 2.0) return 1.0;
    harmonic = log(n - 1.0) + 0.5772156649015329;
    return 2.0 * harmonic - (2.0 * (n - 1.0) / n);
}

/* Appends the subtree rooted at node_rv to buf; returns its node index. */
static int _pack_node_xs(pTHX_ SV* node_rv, int n_features, TreeBuf* b,
                          PackScratch* s) {
    AV* node;
    SV** slots;
    int type, my_idx;
    double* rec;

    if (!SvROK(node_rv) || SvTYPE(SvRV(node_rv)) != SVt_PVAV) {
        croak("pack_tree_xs: tree node is not an arrayref");
    }
    node  = (AV*)SvRV(node_rv);
    slots = AvARRAY(node);
    type  = (int)SvIV(slots[0]);

    /* Reserved before recursing so children are numbered above us. */
    my_idx = tb_push_node(b, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

    if (type == 0) {
        double size = SvNV(slots[1]);
        rec = b->nodes + (size_t)my_idx * IF_NZ;
        rec[1] = size;
        rec[2] = _pt_c(size);    /* the rest of the record stays zero */
    } else if (type == 1) {
        double attr  = SvNV(slots[1]);
        double split = SvNV(slots[2]);
        int li = _pack_node_xs(aTHX_ slots[3], n_features, b, s);
        int ri = _pack_node_xs(aTHX_ slots[4], n_features, b, s);
        /* tb_push_node reallocs, so the record's address is only valid
         * once the children are back. */
        rec = b->nodes + (size_t)my_idx * IF_NZ;
        rec[0] = 1.0; rec[1] = attr; rec[2] = split;
        rec[3] = (double)li; rec[4] = (double)ri;
    } else {
        AV *iav, *cav;
        double bcoef;
        int num, coff, li, ri, k, dense_ok;

        if (!SvROK(slots[1]) || SvTYPE(SvRV(slots[1])) != SVt_PVAV ||
            !SvROK(slots[2]) || SvTYPE(SvRV(slots[2])) != SVt_PVAV) {
            croak("pack_tree_xs: oblique node needs idx/coef arrayrefs");
        }
        iav   = (AV*)SvRV(slots[1]);
        cav   = (AV*)SvRV(slots[2]);
        bcoef = SvNV(slots[3]);
        num   = (int)AvFILLp(iav) + 1;
        ps_reserve(s, num > n_features ? num : n_features);

        for (k = 0; k < num; k++) {
            s->ix[k] = (int)SvIV(AvARRAY(iav)[k]);
            s->cv[k] = SvNV(AvARRAY(cav)[k]);
        }

        /* Dense pack when the node uses every feature, so val[k] is the
         * coefficient for feature k and score_all_xs can take its
         * no-gather inner loop.  For any tree this module builds the
         * indices are a permutation of 0..n_features-1; the range check
         * only stops a hand-edited model from walking off the scratch,
         * and the zero-fill covers a repeated index leaving a hole. */
        dense_ok = (n_features > 0 && num == n_features);
        for (k = 0; dense_ok && k < num; k++) {
            if (s->ix[k] < 0 || s->ix[k] >= n_features) dense_ok = 0;
        }
        if (dense_ok) {
            memset(s->dense, 0, (size_t)n_features * sizeof(double));
            for (k = 0; k < num; k++) s->dense[s->ix[k]] = s->cv[k];
            coff = tb_push_coef(b, s->order, s->dense, n_features);
        } else {
            coff = tb_push_coef(b, s->ix, s->cv, num);
        }

        li = _pack_node_xs(aTHX_ slots[4], n_features, b, s);
        ri = _pack_node_xs(aTHX_ slots[5], n_features, b, s);
        rec = b->nodes + (size_t)my_idx * IF_NZ;
        rec[0] = 2.0; rec[1] = (double)coff; rec[2] = (double)num;
        rec[3] = (double)li; rec[4] = (double)ri; rec[5] = bcoef;
    }
    return my_idx;
}

/* n_features may be -1 ("unknown"), which just disables the dense pack.
 * The three output SVs are overwritten with the packed bytes. */
void pack_tree_xs(SV* root_rv, int n_features, SV* nodes_sv, SV* idx_sv,
                   SV* val_sv) {
    dTHX;
    TreeBuf b;
    PackScratch s;

    tb_init(&b);
    ps_init(&s);
    _pack_node_xs(aTHX_ root_rv, n_features, &b, &s);
    ps_free(&s);

    /* An axis-only tree never calls tb_push_coef, so idx/val stay NULL --
     * pass "" so the Perl side always receives a defined string, matching
     * what build_forest_openmp_xs hands back. */
    sv_setpvn(nodes_sv, (char*)b.nodes, b.n_nodes * IF_NZ * sizeof(double));
    sv_setpvn(idx_sv, b.n_idx ? (char*)b.idx : "", b.n_idx * sizeof(int));
    sv_setpvn(val_sv, b.n_val ? (char*)b.val : "", b.n_val * sizeof(double));
    tb_free(&b);
}

/* ---------------------------------------------------------------------
 * impute_fill_xs(data_sv, n_pts, n_feats, how, out_rv)
 *
 * C replacement for _compute_impute_fill's Perl loop: walks the raw
 * arrayref-of-arrayrefs directly (like pack_input_xs), collecting each
 * feature's present (defined) values, then reduces them to one fill
 * value per feature -- mean (how == 0) or median (how == 1) -- and
 * writes n_feats doubles into out_rv.
 *
 * Values are collected in row order (i = 0..n_pts-1), the same order
 * the Perl version's `grep { defined } map { $_->[$f] } @data` walks
 * them in, so the mean's left-to-right summation lands on the exact
 * same float as the Perl path -- use_c toggles speed here, not the
 * computed fill, matching the rest of the module.
 *
 * The median is an exact order statistic (not summation-dependent), so
 * it matches the Perl path's sort-based median by definition regardless
 * of which selection algorithm finds it. Croaks with the same message
 * as the Perl fallback if a feature has no present values anywhere in
 * the dataset. */
typedef struct { double *v; size_t n, cap; } DVec;

static void dvec_push(DVec *d, double x) {
    if (d->n == d->cap) {
        size_t newcap = d->cap ? d->cap * 2 : 64;
        d->v = (double*)realloc(d->v, newcap * sizeof(double));
        d->cap = newcap;
    }
    d->v[d->n++] = x;
}

static void _dswap(double *a, double *b) { double t = *a; *a = *b; *b = t; }

/* Lomuto partition with a median-of-three pivot (avoids the O(n^2)
 * worst case a fixed pivot hits on already-sorted or reverse-sorted
 * input, which real feature columns -- timestamps, counters -- often
 * are). Returns the pivot's final index. */
static int _partition_lomuto(double *a, int lo, int hi) {
    int mid = lo + (hi - lo) / 2;
    double pivot;
    int i, j;
    if (a[mid] < a[lo]) _dswap(&a[lo],  &a[mid]);
    if (a[hi]  < a[lo]) _dswap(&a[lo],  &a[hi]);
    if (a[hi]  < a[mid]) _dswap(&a[mid], &a[hi]);
    _dswap(&a[mid], &a[hi]);
    pivot = a[hi];
    i = lo;
    for (j = lo; j < hi; j++) {
        if (a[j] < pivot) { _dswap(&a[i], &a[j]); i++; }
    }
    _dswap(&a[i], &a[hi]);
    return i;
}

/* Quickselect: returns the k-th smallest (0-indexed) of a[0..n-1],
 * reordering a[] in the process (fine -- it's a private scratch copy).
 * O(n) average case vs. a full O(n log n) sort. */
static double _kth_smallest(double *a, int n, int k) {
    int lo = 0, hi = n - 1;
    while (lo < hi) {
        int p = _partition_lomuto(a, lo, hi);
        if (p == k) return a[p];
        if (p < k) lo = p + 1; else hi = p - 1;
    }
    return a[lo];
}

/* Median of a[0..n-1] (reorders a[]).  Odd n: the single middle order
 * statistic.  Even n: quickselect finds the lower-median at k = n/2-1,
 * which leaves every a[i > k] >= a[k] (the standard quickselect
 * post-condition) -- so the upper-median is just the min of that
 * remaining slice, one more linear scan instead of a second full
 * selection pass. */
static double _median_select(double *a, int n) {
    if (n % 2 == 1) {
        return _kth_smallest(a, n, n / 2);
    } else {
        int k = n / 2 - 1;
        double lower = _kth_smallest(a, n, k);
        double upper = a[k + 1];
        int i;
        for (i = k + 2; i < n; i++) {
            if (a[i] < upper) upper = a[i];
        }
        return (lower + upper) / 2.0;
    }
}

void impute_fill_xs(SV* data_sv, int n_pts, int n_feats, int how,
                     SV* out_rv) {
    dTHX;
    AV *outer, *out;
    DVec *cols;
    int i, f;

    if (!SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
        croak("impute_fill_xs: data must be an arrayref");
    }
    if (!SvROK(out_rv) || SvTYPE(SvRV(out_rv)) != SVt_PVAV) {
        croak("impute_fill_xs: out must be an arrayref");
    }
    outer = (AV*)SvRV(data_sv);
    out   = (AV*)SvRV(out_rv);

    cols = (DVec*)calloc((size_t)n_feats, sizeof(DVec));

    for (i = 0; i < n_pts; i++) {
        SV** row_pp = av_fetch(outer, i, 0);
        AV* row;
        if (!row_pp || !*row_pp || !SvROK(*row_pp) ||
            SvTYPE(SvRV(*row_pp)) != SVt_PVAV) {
            continue;
        }
        row = (AV*)SvRV(*row_pp);
        for (f = 0; f < n_feats; f++) {
            SV** v = av_fetch(row, f, 0);
            if (v && *v && SvOK(*v)) {
                dvec_push(&cols[f], SvNV(*v));
            }
        }
    }

    /* Validate every column before freeing anything: croak() longjmps
     * out of this function, so any cleanup loop reachable after a
     * partial computation has already started (and already freed some
     * cols[i].v) risks a double free on those same pointers. Checking
     * all columns up front, before the computation loop below frees
     * anything, avoids that entirely. Matches the Perl fallback's
     * behaviour of reporting the first empty column in feature order. */
    for (f = 0; f < n_feats; f++) {
        if (cols[f].n == 0) {
            int col = f;
            for (i = 0; i < n_feats; i++) free(cols[i].v);
            free(cols);
            croak("impute: feature column %d has no present values", col);
        }
    }

    av_clear(out);
    if (n_feats > 0) av_extend(out, n_feats - 1);

    for (f = 0; f < n_feats; f++) {
        double result;
        if (how == 0) {
            double sum = 0.0;
            for (i = 0; i < (int)cols[f].n; i++) sum += cols[f].v[i];
            result = sum / (double)cols[f].n;
        } else {
            result = _median_select(cols[f].v, (int)cols[f].n);
        }
        av_store(out, f, newSVnv(result));
        free(cols[f].v);
    }
    free(cols);
}

/* ---------------------------------------------------------------------
 * Online Isolation Forest (Algorithm::Classifier::IsolationForest::
 * Online) learn / unlearn / score-row accelerators.
 *
 * Unlike everything above, these operate directly on LIVE Perl
 * arrayref trees: online trees mutate on every learned point, so there
 * is no immutable packed form to walk during learning.  Node layout
 * (Online.pm's _N_* constants):
 *
 *   leaf:     [0, count, \@lo, \@hi]
 *   internal: [1, count, \@lo, \@hi, attr, split, left, right]
 *
 * and a tree record is a hashref { root, count, depth_limit }; root is
 * undef until the tree learns its first point, and a leaf built from an
 * empty synthetic partition has undef lo/hi until a real point reaches
 * it.
 *
 * Random draws go through Drand01() in EXACTLY the order the pure-Perl
 * learn path calls rand(): an optional per-tree subsample gate (drawn
 * only when subsample < 1), and -- only when a leaf splits --
 * count * nf box-sample draws that SKIP zero-width features (the Perl
 * _sample_box never draws for those), then per synthetic internal node
 * one draw for the split feature and one for the split value, recursing
 * left before right.  A learn() with a given seed therefore produces
 * BIT-IDENTICAL trees whether use_c is on or off (on nvsize == 8 perls;
 * wide-NV perls keep extra low bits in the pure-Perl path, as with
 * fit()), which is what lets the online class reuse the existing use_c
 * knob for learning instead of growing a new one.
 * ------------------------------------------------------------------ */

#define OL_TYPE  0
#define OL_COUNT 1
#define OL_LO    2
#define OL_HI    3
#define OL_ATTR  4
#define OL_SPLIT 5
#define OL_LEFT  6
#define OL_RIGHT 7

/* ln(4) as the exact double Perl's compile-time log(4) produces --
 * spelled as a literal (like TWO_PI on the Perl side) so a compiler
 * that constant-folds log(4.0) differently from libm cannot introduce
 * a one-ulp parity break in the depth budget. */
#define OL_LOG4 1.3862943611198906

/* Depth budget for n points -- the C image of Online.pm's _rpl(). */
static double _ol_rpl(double n, int eta) {
    if (n < (double)eta) return 0.0;
    return log(n / (double)eta) / OL_LOG4;
}

/* Points a node at `depth` needs before it may split (below which, on
 * forgetting, it collapses back into a leaf) -- _split_threshold().
 * ldexp keeps the adaptive 2**depth factor exact, matching Perl's
 * NV exponentiation. */
static double _ol_split_threshold(int eta, int adaptive, int depth) {
    return (double)eta * (adaptive ? ldexp(1.0, depth) : 1.0);
}

/* Fresh [v0 .. v(nf-1)] arrayref (a bounding-box side). */
static SV* _ol_mk_box(pTHX_ const double* v, int nf) {
    AV* av = newAV();
    int k;
    av_extend(av, nf - 1);
    for (k = 0; k < nf; k++) AvARRAY(av)[k] = newSVnv(v[k]);
    AvFILLp(av) = nf - 1;
    return newRV_noinc((SV*)av);
}

/* lo_rv/hi_rv may be NULL => undef box (leaf from an empty synthetic
 * partition).  Takes ownership of non-NULL refs. */
static SV* _ol_mk_leaf(pTHX_ IV count, SV* lo_rv, SV* hi_rv) {
    AV* av = newAV();
    av_extend(av, 3);
    AvARRAY(av)[0] = newSViv(0);
    AvARRAY(av)[1] = newSViv(count);
    AvARRAY(av)[2] = lo_rv ? lo_rv : &PL_sv_undef;
    AvARRAY(av)[3] = hi_rv ? hi_rv : &PL_sv_undef;
    AvFILLp(av)    = 3;
    return newRV_noinc((SV*)av);
}

static SV* _ol_mk_axis(pTHX_ IV count, SV* lo_rv, SV* hi_rv, int attr,
                       double split, SV* left, SV* right) {
    AV* av = newAV();
    av_extend(av, 7);
    AvARRAY(av)[0] = newSViv(1);
    AvARRAY(av)[1] = newSViv(count);
    AvARRAY(av)[2] = lo_rv;
    AvARRAY(av)[3] = hi_rv;
    AvARRAY(av)[4] = newSViv(attr);
    AvARRAY(av)[5] = newSVnv(split);
    AvARRAY(av)[6] = left;
    AvARRAY(av)[7] = right;
    AvFILLp(av)    = 7;
    return newRV_noinc((SV*)av);
}

/* Recursively build a subtree over synthetic points (row indices into
 * pts, a rows x nf buffer) -- the C image of _build_from_points(), in
 * the same draw order: split feature, split value, left subtree, right
 * subtree.  The partition is stable, matching the Perl push loop. */
static SV* _ol_build(pTHX_ const double* pts, const int* idx, int n, int nf,
                     int depth, double limit, int eta, int adaptive) {
    SV *lo_rv = NULL, *hi_rv = NULL;
    int i, f;

    if (n > 0) {
        double* lo = (double*)malloc(nf * sizeof(double));
        double* hi = (double*)malloc(nf * sizeof(double));
        const double* p0 = pts + (size_t)idx[0] * (size_t)nf;
        for (f = 0; f < nf; f++) { lo[f] = p0[f]; hi[f] = p0[f]; }
        for (i = 0; i < n; i++) {
            const double* p = pts + (size_t)idx[i] * (size_t)nf;
            for (f = 0; f < nf; f++) {
                if (p[f] < lo[f]) lo[f] = p[f];
                if (p[f] > hi[f]) hi[f] = p[f];
            }
        }
        lo_rv = _ol_mk_box(aTHX_ lo, nf);
        hi_rv = _ol_mk_box(aTHX_ hi, nf);
        free(lo);
        free(hi);
    }

    if ((double)n < _ol_split_threshold(eta, adaptive, depth) ||
        (double)depth >= limit) {
        return _ol_mk_leaf(aTHX_ (IV)n, lo_rv, hi_rv);
    }

    {
        int attr    = (int)(Drand01() * nf);
        double pmin = pts[(size_t)idx[0] * (size_t)nf + attr];
        double pmax = pmin;
        double split;
        int *l, *r, ln = 0, rn = 0;
        SV *left, *right;

        for (i = 0; i < n; i++) {
            double v = pts[(size_t)idx[i] * (size_t)nf + attr];
            if (v < pmin) pmin = v;
            if (v > pmax) pmax = v;
        }
        split = pmin + Drand01() * (pmax - pmin);

        l = (int*)malloc(n * sizeof(int));
        r = (int*)malloc(n * sizeof(int));
        for (i = 0; i < n; i++) {
            if (pts[(size_t)idx[i] * (size_t)nf + attr] < split) l[ln++] = idx[i];
            else                                                 r[rn++] = idx[i];
        }
        left  = _ol_build(aTHX_ pts, l, ln, nf, depth + 1, limit, eta, adaptive);
        right = _ol_build(aTHX_ pts, r, rn, nf, depth + 1, limit, eta, adaptive);
        free(l);
        free(r);
        return _ol_mk_axis(aTHX_ (IV)n, lo_rv, hi_rv, attr, split, left, right);
    }
}

/* Route one point down, growing counts and boxes -- _node_learn().
 * Returns the (possibly replaced) node ref; a changed return is stored
 * back by the caller, exactly like the Perl recursion's assignment.
 * When a leaf is replaced by a freshly built subtree the return value
 * is a new ref with refcount 1 and the caller's store drops the old
 * leaf's reference. */
static SV* _ol_node_learn(pTHX_ SV* node_rv, const double* x, int nf,
                          int depth, double limit, int eta, int adaptive) {
    AV* node   = (AV*)SvRV(node_rv);
    SV** slots = AvARRAY(node);
    IV count   = SvIV(slots[OL_COUNT]) + 1;
    int f;

    sv_setiv(slots[OL_COUNT], count);

    if (!SvOK(slots[OL_LO])) {
        /* Leaf born from an empty synthetic partition: the first real
         * point initialises the box. */
        av_store(node, OL_LO, _ol_mk_box(aTHX_ x, nf));
        av_store(node, OL_HI, _ol_mk_box(aTHX_ x, nf));
        slots = AvARRAY(node);
    } else {
        AV* lo = (AV*)SvRV(slots[OL_LO]);
        AV* hi = (AV*)SvRV(slots[OL_HI]);
        for (f = 0; f < nf; f++) {
            SV** lv = av_fetch(lo, f, 1);
            SV** hv = av_fetch(hi, f, 1);
            if (x[f] < SvNV(*lv)) sv_setnv(*lv, x[f]);
            if (x[f] > SvNV(*hv)) sv_setnv(*hv, x[f]);
        }
    }

    if (SvIV(slots[OL_TYPE]) == 0) {    /* leaf */
        if ((double)count >= _ol_split_threshold(eta, adaptive, depth) &&
            (double)depth < limit) {
            AV* lo      = (AV*)SvRV(AvARRAY(node)[OL_LO]);
            AV* hi      = (AV*)SvRV(AvARRAY(node)[OL_HI]);
            double* lod = (double*)malloc(nf * sizeof(double));
            double* hid = (double*)malloc(nf * sizeof(double));
            double* pts = (double*)malloc((size_t)count * (size_t)nf * sizeof(double));
            int* idx    = (int*)malloc((size_t)count * sizeof(int));
            SV* subtree;
            int i;

            for (f = 0; f < nf; f++) {
                SV** lv = av_fetch(lo, f, 0);
                SV** hv = av_fetch(hi, f, 0);
                lod[f] = (lv && *lv && SvOK(*lv)) ? SvNV(*lv) : 0.0;
                hid[f] = (hv && *hv && SvOK(*hv)) ? SvNV(*hv) : 0.0;
            }
            /* Synthetic points, point-major, one draw per feature with
             * width > 0 -- _sample_box's exact draw order. */
            for (i = 0; i < (int)count; i++) {
                for (f = 0; f < nf; f++) {
                    double w = hid[f] - lod[f];
                    pts[(size_t)i * (size_t)nf + f]
                        = (w > 0) ? lod[f] + Drand01() * w : lod[f];
                }
                idx[i] = i;
            }
            subtree = _ol_build(aTHX_ pts, idx, (int)count, nf, depth, limit,
                                eta, adaptive);
            free(lod);
            free(hid);
            free(pts);
            free(idx);
            return subtree;
        }
        return node_rv;
    }

    {
        int attr     = (int)SvIV(slots[OL_ATTR]);
        double split = SvNV(slots[OL_SPLIT]);
        int ci       = (x[attr] < split) ? OL_LEFT : OL_RIGHT;
        SV* child    = AvARRAY(node)[ci];
        SV* nc = _ol_node_learn(aTHX_ child, x, nf, depth + 1, limit, eta,
                                adaptive);
        if (nc != child) av_store(node, ci, nc);
        return node_rv;
    }
}

/* Union of two nodes' boxes into caller-provided arrays, matching
 * _box_union(): nodes without a box are skipped, the first boxed node
 * is copied and the second folded in.  Returns 0 when neither node has
 * a box. */
static int _ol_box_union(pTHX_ SV* a_rv, SV* b_rv, int nf,
                         double* lo, double* hi) {
    SV* boxed[2];
    int nb = 0, bi, f;

    if (SvOK(AvARRAY((AV*)SvRV(a_rv))[OL_LO])) boxed[nb++] = a_rv;
    if (SvOK(AvARRAY((AV*)SvRV(b_rv))[OL_LO])) boxed[nb++] = b_rv;
    if (nb == 0) return 0;

    for (bi = 0; bi < nb; bi++) {
        AV* node = (AV*)SvRV(boxed[bi]);
        AV* blo  = (AV*)SvRV(AvARRAY(node)[OL_LO]);
        AV* bhi  = (AV*)SvRV(AvARRAY(node)[OL_HI]);
        for (f = 0; f < nf; f++) {
            SV** lv  = av_fetch(blo, f, 0);
            SV** hv  = av_fetch(bhi, f, 0);
            double l = (lv && *lv && SvOK(*lv)) ? SvNV(*lv) : 0.0;
            double h = (hv && *hv && SvOK(*hv)) ? SvNV(*hv) : 0.0;
            if (bi == 0) {
                lo[f] = l;
                hi[f] = h;
            } else {
                if (l < lo[f]) lo[f] = l;
                if (h > hi[f]) hi[f] = h;
            }
        }
    }
    return 1;
}

/* Aggregate a subtree back into one leaf -- _collapse().  Children are
 * collapsed first so their boxes can be unioned; intermediate leaves
 * built while collapsing internal children are temporaries and dropped
 * here.  Returns a NEW leaf ref (refcount 1) for internal nodes, or the
 * node itself when it is already a leaf. */
static SV* _ol_collapse(pTHX_ SV* node_rv, int nf) {
    AV* node = (AV*)SvRV(node_rv);
    SV *l_rv, *r_rv, *cl, *cr, *leaf;
    SV *lo_rv = NULL, *hi_rv = NULL;
    double *lo, *hi;

    if (SvIV(AvARRAY(node)[OL_TYPE]) == 0) return node_rv;

    l_rv = AvARRAY(node)[OL_LEFT];
    r_rv = AvARRAY(node)[OL_RIGHT];
    cl   = _ol_collapse(aTHX_ l_rv, nf);
    cr   = _ol_collapse(aTHX_ r_rv, nf);

    lo = (double*)malloc(nf * sizeof(double));
    hi = (double*)malloc(nf * sizeof(double));
    if (_ol_box_union(aTHX_ cl, cr, nf, lo, hi)) {
        lo_rv = _ol_mk_box(aTHX_ lo, nf);
        hi_rv = _ol_mk_box(aTHX_ hi, nf);
    } else if (SvOK(AvARRAY(node)[OL_LO])) {
        /* Both children boxless: keep the node's own box (the Perl code
         * moves the same arrayrefs into the new leaf). */
        lo_rv = SvREFCNT_inc(AvARRAY(node)[OL_LO]);
        hi_rv = SvREFCNT_inc(AvARRAY(node)[OL_HI]);
    }
    free(lo);
    free(hi);

    leaf = _ol_mk_leaf(aTHX_ SvIV(AvARRAY(node)[OL_COUNT]), lo_rv, hi_rv);
    if (cl != l_rv) SvREFCNT_dec(cl);
    if (cr != r_rv) SvREFCNT_dec(cr);
    return leaf;
}

/* Route the forgotten point down, decrementing counts -- _node_unlearn().
 * An internal node whose count no longer justifies its split collapses;
 * otherwise its box is refreshed to the union of its children's. */
static SV* _ol_node_unlearn(pTHX_ SV* node_rv, const double* x, int nf,
                            int depth, int eta, int adaptive) {
    AV* node   = (AV*)SvRV(node_rv);
    SV** slots = AvARRAY(node);
    IV count   = SvIV(slots[OL_COUNT]) - 1;

    sv_setiv(slots[OL_COUNT], count);

    if (SvIV(slots[OL_TYPE]) == 0) return node_rv;
    if ((double)count < _ol_split_threshold(eta, adaptive, depth)) {
        return _ol_collapse(aTHX_ node_rv, nf);
    }

    {
        int attr     = (int)SvIV(slots[OL_ATTR]);
        double split = SvNV(slots[OL_SPLIT]);
        int ci       = (x[attr] < split) ? OL_LEFT : OL_RIGHT;
        SV* child    = AvARRAY(node)[ci];
        double *lo, *hi;
        SV* nc = _ol_node_unlearn(aTHX_ child, x, nf, depth + 1, eta,
                                  adaptive);
        if (nc != child) av_store(node, ci, nc);

        lo = (double*)malloc(nf * sizeof(double));
        hi = (double*)malloc(nf * sizeof(double));
        if (_ol_box_union(aTHX_ AvARRAY(node)[OL_LEFT],
                          AvARRAY(node)[OL_RIGHT], nf, lo, hi)) {
            av_store(node, OL_LO, _ol_mk_box(aTHX_ lo, nf));
            av_store(node, OL_HI, _ol_mk_box(aTHX_ hi, nf));
        }
        free(lo);
        free(hi);
        return node_rv;
    }
}

/* Read one sample row (arrayref) into a dense double buffer; undef -> 0,
 * matching the pure-Perl paths (learn rows are pre-densified anyway). */
static void _ol_read_row(pTHX_ SV* row_sv, double* x, int nf) {
    AV* row;
    int f;
    if (!SvROK(row_sv) || SvTYPE(SvRV(row_sv)) != SVt_PVAV)
        croak("online row must be an arrayref");
    row = (AV*)SvRV(row_sv);
    for (f = 0; f < nf; f++) {
        SV** v = av_fetch(row, f, 0);
        x[f] = (v && *v && SvOK(*v)) ? SvNV(*v) : 0.0;
    }
}

/* Fetch tree t of the trees arrayref as its underlying HV. */
static HV* _ol_tree_hv(pTHX_ AV* trees, int t) {
    SV** tp = av_fetch(trees, t, 0);
    if (!tp || !*tp || !SvROK(*tp) || SvTYPE(SvRV(*tp)) != SVt_PVHV)
        croak("online tree %d is not a hashref", t);
    return (HV*)SvRV(*tp);
}

/* online_learn_row_xs(trees_av, row_av, nf, eta, adaptive, subsample)
 *
 * The C image of _learn_row's per-tree loop: every tree (subject to the
 * subsample gate) learns the row, with count / depth_limit bookkeeping
 * on the tree hash.  Mutates the live trees in place. */
void online_learn_row_xs(SV* trees_av_sv, SV* row_sv, int nf, int eta,
                         int adaptive, double subsample) {
    dTHX;
    AV* trees;
    double* x;
    int t, n_trees;

    if (!SvROK(trees_av_sv) || SvTYPE(SvRV(trees_av_sv)) != SVt_PVAV)
        croak("online_learn_row_xs: trees must be an arrayref");
    trees   = (AV*)SvRV(trees_av_sv);
    n_trees = (int)av_len(trees) + 1;

    x = (double*)malloc(nf * sizeof(double));
    _ol_read_row(aTHX_ row_sv, x, nf);

    for (t = 0; t < n_trees; t++) {
        HV* tree;
        SV **csv, **dsv, **rsv;
        IV count;
        double limit;

        if (subsample < 1.0 && Drand01() >= subsample) continue;
        tree = _ol_tree_hv(aTHX_ trees, t);

        csv   = hv_fetch(tree, "count", 5, 1);
        count = (SvOK(*csv) ? SvIV(*csv) : 0) + 1;
        sv_setiv(*csv, count);
        limit = _ol_rpl((double)count, eta);
        dsv   = hv_fetch(tree, "depth_limit", 11, 1);
        sv_setnv(*dsv, limit);

        rsv = hv_fetch(tree, "root", 4, 1);
        if (!SvOK(*rsv)) {
            (void)hv_store(tree, "root", 4,
                _ol_mk_leaf(aTHX_ 1, _ol_mk_box(aTHX_ x, nf),
                            _ol_mk_box(aTHX_ x, nf)), 0);
        } else {
            SV* root = *rsv;
            SV* nr = _ol_node_learn(aTHX_ root, x, nf, 0, limit, eta,
                                    adaptive);
            if (nr != root) (void)hv_store(tree, "root", 4, nr, 0);
        }
    }
    free(x);
}

/* online_unlearn_row_xs(trees_av, row_av, nf, eta, adaptive, subsample)
 *
 * The C image of _learn_row's eviction loop (_tree_unlearn per tree,
 * behind the same independent subsample gate). */
void online_unlearn_row_xs(SV* trees_av_sv, SV* row_sv, int nf, int eta,
                           int adaptive, double subsample) {
    dTHX;
    AV* trees;
    double* x;
    int t, n_trees;

    if (!SvROK(trees_av_sv) || SvTYPE(SvRV(trees_av_sv)) != SVt_PVAV)
        croak("online_unlearn_row_xs: trees must be an arrayref");
    trees   = (AV*)SvRV(trees_av_sv);
    n_trees = (int)av_len(trees) + 1;

    x = (double*)malloc(nf * sizeof(double));
    _ol_read_row(aTHX_ row_sv, x, nf);

    for (t = 0; t < n_trees; t++) {
        HV* tree;
        SV **csv, **dsv, **rsv;
        IV count;

        if (subsample < 1.0 && Drand01() >= subsample) continue;
        tree = _ol_tree_hv(aTHX_ trees, t);

        csv   = hv_fetch(tree, "count", 5, 1);
        count = (SvOK(*csv) ? SvIV(*csv) : 0) - 1;
        sv_setiv(*csv, count);
        dsv = hv_fetch(tree, "depth_limit", 11, 1);
        sv_setnv(*dsv, _ol_rpl((double)count, eta));

        rsv = hv_fetch(tree, "root", 4, 0);
        if (rsv && *rsv && SvOK(*rsv)) {
            SV* root = *rsv;
            SV* nr = _ol_node_unlearn(aTHX_ root, x, nf, 0, eta, adaptive);
            if (nr != root) (void)hv_store(tree, "root", 4, nr, 0);
        }
    }
    free(x);
}

/* online_score_row_xs(trees_av, row_av, nf, eta)
 *
 * Depth sum of one row across the live trees (walk + per-leaf _rpl
 * adjustment) -- the C image of _score_row's loop, used by the
 * prequential score_learn path where trees mutate between rows and the
 * packed-snapshot scorer can never amortise.  Draws nothing. */
double online_score_row_xs(SV* trees_av_sv, SV* row_sv, int nf, int eta) {
    dTHX;
    AV* trees;
    double* x;
    double sum = 0.0;
    int t, n_trees;

    if (!SvROK(trees_av_sv) || SvTYPE(SvRV(trees_av_sv)) != SVt_PVAV)
        croak("online_score_row_xs: trees must be an arrayref");
    trees   = (AV*)SvRV(trees_av_sv);
    n_trees = (int)av_len(trees) + 1;

    x = (double*)malloc(nf * sizeof(double));
    _ol_read_row(aTHX_ row_sv, x, nf);

    for (t = 0; t < n_trees; t++) {
        HV* tree = _ol_tree_hv(aTHX_ trees, t);
        SV** rsv = hv_fetch(tree, "root", 4, 0);
        AV* node;
        SV** slots;
        int depth = 0;

        if (!rsv || !*rsv || !SvOK(*rsv)) continue;
        node  = (AV*)SvRV(*rsv);
        slots = AvARRAY(node);
        while (SvIV(slots[OL_TYPE]) != 0) {
            int attr     = (int)SvIV(slots[OL_ATTR]);
            double split = SvNV(slots[OL_SPLIT]);
            node  = (AV*)SvRV(slots[(x[attr] < split) ? OL_LEFT : OL_RIGHT]);
            slots = AvARRAY(node);
            depth++;
        }
        sum += (double)depth + _ol_rpl((double)SvIV(slots[OL_COUNT]), eta);
    }
    free(x);
    return sum;
}
__INLINE_C__

	# IF_NO_C=1 skips even attempting to set up the C backend -- useful for
	# forcing the pure-Perl path without touching every constructor call
	# (use_c => 0), e.g. to get a clean timing baseline or to avoid the
	# compile attempt's overhead/noise in a container known to lack a
	# compiler.  Everything below is skipped and $HAS_C stays 0.
	unless ( $ENV{IF_NO_C} ) {

		# Defaults recorded when `perl Makefile.PL` ran.  Makefile.PL generates
		# Algorithm::Classifier::IsolationForest::BuildFlags, capturing the
		# IF_* values active at configure time plus whether a prebuilt object
		# was scheduled for install (see "Compile at install time" in the POD
		# below).  From a plain source checkout the generated file is absent,
		# the hard defaults here apply, and no prebuilt object is looked for.
		my ( $def_opt, $def_arch, $def_no_omp, $prebuilt ) = ( '-O3', '', 0, 0 );
		{
			local $@;
			my $rec = eval {
				require Algorithm::Classifier::IsolationForest::BuildFlags;
				Algorithm::Classifier::IsolationForest::BuildFlags::flags();
			};
			if ( ref $rec eq 'HASH' ) {
				$def_opt    = $rec->{opt}  if defined $rec->{opt};
				$def_arch   = $rec->{arch} if defined $rec->{arch};
				$def_no_omp = $rec->{no_openmp} ? 1 : 0;
				$prebuilt   = $rec->{prebuilt}  ? 1 : 0;
			}
		}

		# -O3 is the usual default: it's safe to enable unconditionally and
		# matters here -- the extended-mode oblique dot product is wrapped in
		# `#pragma omp simd`, but without aggressive optimization the compiler
		# may still emit scalar code.  Use OPTIMIZE (not CCFLAGS) -- CCFLAGS is
		# prepended to the cc line and would be shadowed by Perl's own `-O2 -g`
		# that ExtUtils::MakeMaker appends afterward (last `-O` wins in gcc).
		# IF_OPT overrides the level itself (e.g. IF_OPT=-O2 to work around a
		# miscompile, or to shorten build time while developing); it's
		# validated against a fixed set of GCC/Clang -O flags rather than
		# interpolated as-is, since this string eventually reaches a shell
		# command line via ExtUtils::MakeMaker.
		my $opt = $def_opt;
		if ( defined $ENV{IF_OPT} ) {
			if ( $ENV{IF_OPT} =~ /\A-O[0123sgz]\z/ ) {
				$opt = $ENV{IF_OPT};
			} else {
				warn "Algorithm::Classifier::IsolationForest: ignoring invalid "
					. "IF_OPT value '$ENV{IF_OPT}' (expected one of -O0 -O1 -O2 "
					. "-O3 -Os -Og -Oz); using $opt\n";
			}
		}

		# -march=<value> lets the compiler target specific instruction-set
		# extensions (AVX2 gather + FMA, etc.) for the oblique dot product
		# and the fit-time min/max scan's `#pragma omp simd` loops.
		#
		# IF_ARCH=<value> sets it explicitly (e.g. "x86-64-v3", "skylake",
		# "znver3") -- validated against a conservative identifier charset
		# since, like IF_OPT, it flows into a compiler command line.
		# IF_NATIVE=1 remains as shorthand for IF_ARCH=native and is used
		# when IF_ARCH isn't set. Prefer a specific IF_ARCH value over
		# IF_NATIVE on a machine you don't control exclusively: blanket
		# -march=native pulls in whatever the build host has, including
		# AVX-512 on some Intel CPUs, which is known to trigger clock
		# throttling under sustained heavy use and can make throughput
		# *worse* than a conservative target like x86-64-v3 (AVX2, no
		# AVX-512). Either way, the cached artefact under _Inline/ is then
		# pinned to that instruction set, so leave both unset if the
		# directory is shared across machines with different CPUs.
		my $arch = $def_arch;
		if ( defined $ENV{IF_ARCH} ) {
			if ( $ENV{IF_ARCH} eq '' or $ENV{IF_ARCH} eq 'none' ) {

				# Explicit opt-out: overrides an arch recorded at configure
				# time (there is no other way to request a plain build on
				# an install configured with IF_ARCH).
				$arch = '';
			} elsif ( $ENV{IF_ARCH} =~ /\A[A-Za-z0-9_.+=-]+\z/ ) {
				$arch = $ENV{IF_ARCH};
			} else {
				warn "Algorithm::Classifier::IsolationForest: ignoring invalid " . "IF_ARCH value '$ENV{IF_ARCH}'\n";
			}
		} elsif ( $ENV{IF_NATIVE} ) {
			$arch = 'native';
		}
		# -ffp-contract=off rides along with any -march: once the target
		# has FMA (x86-64-v3, most -march=native hosts), the compiler may
		# otherwise contract a*b+c expressions into fused multiply-adds
		# whose different rounding breaks the documented guarantee that
		# use_c => 1 and use_c => 0 build bit-identical trees (one ulp in a
		# split value cascades into a structurally different tree).  The
		# -march speedup comes from AVX2 vectorization, not contraction,
		# so this costs little (verified against the fit-determinism and
		# scoring-parity tests).
		my $opt_level = $opt;
		$opt_level .= " -march=$arch -ffp-contract=off" if length $arch;

		# IF_NO_OPENMP=1 forces the serial C build: the OpenMP compile attempt
		# is skipped, so the object has no libgomp linkage and never starts an
		# OpenMP runtime in the process.  Distinct from OMP_NUM_THREADS=1,
		# which runs the parallel code on a single thread but still loads
		# libgomp.  An explicit IF_NO_OPENMP=0 re-enables OpenMP over a
		# no-openmp configure-time default.
		my $no_omp
			= defined $ENV{IF_NO_OPENMP}
			? ( $ENV{IF_NO_OPENMP} ? 1 : 0 )
			: $def_no_omp;

		# The prebuilt object is only trusted when the effective flags match
		# what it was compiled with; any difference -- or an explicit
		# IF_RUNTIME_BUILD=1 -- falls through to the classic runtime Inline::C
		# build below, which honours the requested flags via the MD5-keyed
		# _Inline/ cache exactly as before prebuilt support existed.
		# IF_INSTALL_BUILD is the `make` rule driving the install-time compile
		# (see Makefile.PL); it must never short-circuit into loading an
		# older object.
		my $use_prebuilt
			= $prebuilt
			&& !$ENV{IF_RUNTIME_BUILD}
			&& !$ENV{IF_INSTALL_BUILD}
			&& $opt eq $def_opt
			&& $arch eq $def_arch
			&& $no_omp == $def_no_omp;

		# Inline::C hashes the C source to decide whether to rebuild but
		# does NOT include CCFLAGS / OPTIMIZE in that hash.  Without the
		# tag below, toggling IF_NATIVE/IF_ARCH/IF_OPT (or editing the
		# optimisation flags here) would silently reuse a cached binary
		# built with stale flags.  Embedding the active flags as a leading
		# comment forces the hash to differ when they change.  The OpenMP
		# and serial builds get distinct tags so they cache to separate
		# artefacts.
		my $omp_tag    = "/* if_build: openmp $opt_level */\n";
		my $serial_tag = "/* if_build: serial $opt_level */\n";

		if ( $ENV{IF_INSTALL_BUILD} ) {

			# `make` is driving: the rule Makefile.PL appended runs this load
			# with IF_INSTALL_BUILD=1 and @ARGV = (version, INST_ARCHLIB),
			# which is where Inline's install mode reads them from.  _INSTALL_
			# makes Inline compile the backend and place the shared object
			# under blib/arch so `make install` ships it; NAME/VERSION give
			# the object a fixed identity XSLoader can find at run time
			# (Inline's install mode also requires both and checks VERSION
			# against $ARGV[0]).  Same OpenMP-then-serial fallback as the
			# runtime build below.
			my @install = (
				NAME      => __PACKAGE__,
				VERSION   => $VERSION,
				_INSTALL_ => 1,
			);
			unless ($no_omp) {
				local $@;
				eval {
					require Inline;
					Inline->import(
						C        => $omp_tag . $C_CODE,
						CCFLAGS  => '-fopenmp',
						OPTIMIZE => $opt_level,
						LIBS     => '-lm -lgomp',
						@install,
					);
					$HAS_C = 1;
				};
			} ## end unless ($no_omp)
			unless ($HAS_C) {
				local $@;
				eval {
					require Inline;
					Inline->import(
						C        => $serial_tag . $C_CODE,
						OPTIMIZE => $opt_level,
						LIBS     => '-lm',
						@install,
					);
					$HAS_C = 1;
				};
			} ## end unless ($HAS_C)
			$C_SOURCE = 'prebuilt' if $HAS_C;
		} else {

			# Fast path: the object compiled at `make` time was installed
			# under auto/ like any XS module, so plain XSLoader digs it out of
			# @INC with no Inline involvement -- no compiler, no _Inline/
			# directory, and a few ms instead of a first-run compile.  Any
			# failure (object deleted, different perl, version mismatch after
			# an upgrade, libgomp since removed) just falls through to the
			# runtime build.
			if ($use_prebuilt) {
				local $@;
				eval {
					require XSLoader;
					XSLoader::load( __PACKAGE__, $VERSION );
					$HAS_C    = 1;
					$C_SOURCE = 'prebuilt';
				};
			}

			# Classic runtime Inline::C build, MD5-cached under _Inline/.
			# Reached when there is no matching prebuilt object: a source
			# checkout, IF_RUNTIME_BUILD=1, or IF_* values differing from the
			# ones recorded at configure time.  Try compiling with OpenMP
			# first; on any failure (compiler doesn't accept -fopenmp, libgomp
			# missing, etc.) fall back to a serial build.
			unless ( $HAS_C or $no_omp ) {
				local $@;
				eval {
					require Inline;
					Inline->import(
						C        => $omp_tag . $C_CODE,
						CCFLAGS  => '-fopenmp',
						OPTIMIZE => $opt_level,
						LIBS     => '-lm -lgomp',
					);
					$HAS_C    = 1;
					$C_SOURCE = 'runtime';
				};
			} ## end unless ( $HAS_C or $no_omp )
			unless ($HAS_C) {
				local $@;
				eval {
					require Inline;
					Inline->import(
						C        => $serial_tag . $C_CODE,
						OPTIMIZE => $opt_level,
						LIBS     => '-lm',
					);
					$HAS_C    = 1;
					$C_SOURCE = 'runtime';
				};
			} ## end unless ($HAS_C)
		} ## end else [ if ( $ENV{IF_INSTALL_BUILD} ) ]
		$OPT_LEVEL = $opt_level if $HAS_C;

	} ## end unless ( $ENV{IF_NO_C} )
	$HAS_OPENMP = ( $HAS_C && defined &has_openmp_xs && has_openmp_xs() ) ? 1 : 0;
	$HAS_SIMD   = ( $HAS_C && defined &has_simd_xs   && has_simd_xs() )   ? 1 : 0;
}

=encoding UTF-8

=head1 NAME

Algorithm::Classifier::IsolationForest - unsupervised anomaly detection via Isolation Forest or Extended Isolation Forest

=head1 SYNOPSIS

    use Algorithm::Classifier::IsolationForest;

    my @data = ([0.1, -0.2], [0.0, 0.1], [5.0, 6.0], ...);

    # Classic, axis-parallel Isolation Forest
    my $iforest = Algorithm::Classifier::IsolationForest->new(
        n_trees     => 100,
        sample_size => 256,
        seed        => 42,
    );
    $iforest->fit(\@data);

    my $scores = $iforest->score_samples(\@data);  # arrayref, each in (0,1]
    my $flags  = $iforest->predict(\@data, 0.6);    # arrayref of 0/1

    # Save and reload
    $iforest->save('model.json');
    my $reloaded = Algorithm::Classifier::IsolationForest->load('model.json');

    # Extended Isolation Forest (oblique hyperplane splits)
    my $eif = Algorithm::Classifier::IsolationForest->new(
        mode => 'extended',
        seed => 42,
    );
    $eif->fit(\@data);

    # Parallel training (fork-based, Unix-like platforms): build the
    # n_trees across several worker processes.
    my $iforest = Algorithm::Classifier::IsolationForest->new(
        n_trees      => 200,
        sample_size  => 256,
        seed         => 42,
        parallel_fit => 4,        # 4 forked workers
    );
    $iforest->fit(\@data);

    # Pre-pack a dataset to skip the per-call input-walk cost when the
    # same data gets scored many times (interactive tuning, dashboards).
    my $packed = $iforest->pack_data(\@data);
    my $scores = $iforest->score_samples($packed);
    my $flags  = $iforest->predict($packed, 0.6);

    # Get scores and labels as two flat arrayrefs in one call -- cheaper
    # than score_predict_samples when you don't need the paired shape.
    my ($s, $l) = $iforest->score_predict_split(\@data, 0.6);

=head1 DESCRIPTION

Isolation Forest (Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua, 2008) detects anomalies by random
partitioning rather than by modelling normal points. Each tree repeatedly
splits the data. Points that get isolated after only a few splits are likely
anomalies. The score is the average isolation depth across many trees,
normalised so values approach 1 for anomalies and stay below 0.5 for normal
points.

In extended mode the module implements the Extended Isolation Forest
variant. Each split is a random hyperplane instead of an axis-aligned cut,
which removes the rectangular, axis-aligned bias in the score field and
tends to help on elongated or multi-modal data.

With C<< voting => 'majority' >> the module implements the Majority Voting
Isolation Forest (MVIForest) aggregation: each tree votes a sample
anomalous or normal against the decision threshold and the label is the
majority of the votes, with prediction stopping early once the majority is
reached.  Trees are built identically either way, so this composes with
both axis and extended mode, and an existing model can be flipped between
the two modes with L</set_voting> without refitting; see C<voting> under
L</new(%args)>.

For data that arrives as a stream and may drift over time, the companion
class L<Algorithm::Classifier::IsolationForest::Online> implements Online
Isolation Forest (Leveni et al. 2024): no C<fit()>, instead points are
learned as they arrive and forgotten once they age out of a sliding
window.  Models saved by either class can be loaded through L<load|/load($path)>,
which dispatches on the stored format tag.

Throughout these docs, B<psi> is the paper's ψ: the number of points each
tree is built from, which C<sample_size> sets and which other
implementations often call I<max samples>.  See L</REFERENCES>.

=head1 NATIVE ACCELERATION (Inline::C and OpenMP)

Both the scoring hot path (C<score_samples>, C<predict>, C<path_lengths>,
C<score_predict_samples>, and C<score_predict_split>) and the C<fit()>
tree builder are automatically accelerated through
L<Inline::C> when it is installed and a working C compiler is reachable.
If the toolchain also accepts C<-fopenmp> and can link against
C<libgomp>, the per-point tree walk runs in parallel across all
available CPU cores using OpenMP, and the extended-mode oblique dot
product is vectorised via C<#pragma omp simd> -- which on modern x86
compilers translates to an unrolled FMA / AVX gather chain that's
substantially faster for high-feature-count extended models.

C<fit()>'s tree builder (subsampling plus the recursive axis/oblique
split search) runs in C the same way when C<use_c> is on, replacing the
per-node Perl arrayref copying with plain int-array partitioning --
typically an order of magnitude faster, and dramatically more so at
higher feature counts where the pure-Perl per-cell loop dominates. Its
random draws go through the same generator C<rand()>/C<srand()> use
internally, in the same call order the pure-Perl builder uses, so a
given C<seed> produces bit-identical trees whether C<use_c> is on or
off -- switching backends changes only how fast the model is built, not
the model itself. On perls whose NV is wider than a C double
(C<-Duselongdouble> / C<-Dusequadmath>) the pure-Perl builder rounds
each stored value to double precision to preserve this parity; axis
mode matches exactly, while extended mode can still differ on rare
libm rounding ties (double vs long-double transcendentals).

By default this C builder is single-threaded per call, because Perl's
RNG state isn't safe to share across OpenMP threads. Two ways to scale
fit() across cores are available (see below for why they don't compose):

=over 4

=item * C<parallel_fit> forks N worker processes, each building its
share of the trees with the (still single-threaded) C builder. Fixed
IPC/serialisation overhead per worker means this can cost more than it
saves once a fit already completes in milliseconds; it's most useful
once a single-process fit is large enough that the fork/Storable
overhead is small relative to the work being split.

=item * C<use_openmp_fit> builds trees across OpenMP threads within a
single process (one tree per thread), using a separate, thread-safe
PRNG seeded per tree index instead of Perl's C<rand()>. This means
trees built with C<use_openmp_fit> are I<not> bit-identical to the
default C<use_c> path for the same seed -- but a fixed seed and
C<n_trees> still reproduce the same trees regardless of
C<OMP_NUM_THREADS> or how OpenMP schedules the work. It's off by
default (unlike C<use_c>/C<use_openmp>, which only ever change speed,
this changes which trees get built) and only takes effect when C<use_c>
is also on and OpenMP is linked in.

=back

These two do NOT compose, despite both existing to parallelise fit().
A process that has run any OpenMP region -- including plain
C<score_samples()>/C<predict()> with the default C<use_openmp> -- and
then C<fork()>s (as C<parallel_fit> does) hands each child a copy of
libgomp's thread pool whose worker threads did not survive the fork. A
child that then starts its own C<#pragma omp parallel> region (as
C<use_openmp_fit> would) tries to reuse that now-invalid pool and
hangs. This is a general limitation of combining C<fork()> with OpenMP,
not something fixable from Perl, so C<parallel_fit>'s forked workers
always use the single-threaded C builder regardless of
C<use_openmp_fit> -- setting both just means C<parallel_fit> wins and
C<use_openmp_fit> has no effect for that call.

Detection happens once when the module is loaded.  When the
distribution was installed with C<Inline::C> available, the C backend
was already compiled during C<make> and the installed object is loaded
directly (see L</Compile at install time (the prebuilt object)> below);
otherwise the backend is compiled on first load and the artefact is
cached under C<_Inline/> and reused on subsequent runs.  Five package
variables report what the load picked up:

    $Algorithm::Classifier::IsolationForest::HAS_C       # 0/1
    $Algorithm::Classifier::IsolationForest::HAS_OPENMP  # 0/1
    $Algorithm::Classifier::IsolationForest::HAS_SIMD    # 0/1 (OpenMP 4.0+)
    $Algorithm::Classifier::IsolationForest::OPT_LEVEL   # e.g. "-O3 -march=native", '' if HAS_C is 0
    $Algorithm::Classifier::IsolationForest::C_SOURCE    # 'prebuilt' / 'runtime', '' if HAS_C is 0

Neither dependency is required.  Without C<Inline::C> the module falls
back to a pure-Perl implementation that produces identical results, just
slower; without OpenMP the C backend runs single-threaded.

The bundled C<iforest accel> subcommand performs a tiny fit + score and
prints which backend is active (including the build flags below), which
is the recommended way to verify the build picked up the optional
dependencies on a given machine.

=head2 Compile at install time (the prebuilt object)

When C<Inline::C> is usable while the distribution itself is being
built, C<perl Makefile.PL> arranges for the C backend to be compiled
once during C<make> and installed alongside the module like any XS
object.  At run time that object is loaded directly through
L<XSLoader>: no C compiler, no C<Inline> modules, and no C<_Inline/>
cache directory are needed on the machine the module ends up running
on, and the first-load compile pause disappears entirely.

On x86-64 hardware from roughly the last decade,
C<IF_ARCH=x86-64-v3 perl Makefile.PL> is a reasonable configure line:
it bakes AVX2 + FMA (without AVX-512) into the prebuilt object, which
can speed up extended-mode scoring (how much is hardware-dependent --
benchmark with C<iforest bench> before assuming) while avoiding the
C<-march=native> caveats described under L</Tuning the C build>.
Bit-for-bit result parity with the pure-Perl backend is preserved
either way (see C<IF_ARCH> below).

The C<IF_*> build flags described below are captured when
C<perl Makefile.PL> runs -- set them in the environment of I<that>
command, not of C<make> -- and recorded in the generated
C<Algorithm::Classifier::IsolationForest::BuildFlags> module, which
thereby also fixes what the prebuilt object was compiled with.  At run
time the recorded values serve as the defaults, so a process started
with no C<IF_*> variables set uses the prebuilt object as-is.

Setting C<IF_*> variables at run time keeps working exactly as in
releases without prebuilt support: if the requested flags differ from
the recorded ones, the prebuilt object (compiled with the wrong flags
for the request) is skipped and the module compiles at first load into
C<_Inline/> -- which does need C<Inline::C> and a compiler on that
machine.  Two related knobs exist:

=over 4

=item * C<IF_RUNTIME_BUILD=1> -- ignore the prebuilt object
unconditionally and compile at first load even though the requested
flags match the recorded ones.  Useful when the installed object is
suspect (built on a different CPU than it now runs on, linked against a
libgomp that has since changed) or to A/B a fresh local build against
the shipped one.

=item * C<IF_INSTALL_BUILD=1> -- internal; set by the generated
Makefile rule that performs the install-time compile.  Not meant for
manual use.

=back

If the prebuilt object cannot be loaded for any reason (deleted, built
against a different perl, version mismatch after an upgrade), the
module quietly falls through the same chain as always: runtime
Inline::C build first, pure Perl last.

=head2 Tuning the C build

These environment variables are read once, the first time the module is
loaded, so they must be set before that -- e.g. in the shell before
running a script, not via C<%ENV> inside the script itself.  They are
also read by C<perl Makefile.PL> to pick the flags baked into the
prebuilt object (see above); at run time they override the recorded
configure-time values, at the price of a runtime compile.

=over 4

=item * C<IF_NO_C=1> -- skip attempting to build the C backend entirely.
Equivalent to constructing every instance with C<use_c =E<gt> 0>, but
without needing to touch every call site; useful for a clean pure-Perl
timing baseline, or to avoid the compile attempt's overhead/noise on a
host known to lack a C compiler (the attempt already fails gracefully
without this, so it's a convenience, not a correctness fix).

=item * C<IF_OPT=-O2> (or C<-O0>/C<-O1>/C<-Os>/C<-Og>/C<-Oz>) -- override
the default C<-O3>, e.g. to shorten build time while iterating, or work
around a miscompile on an unusual toolchain. Invalid values are ignored
with a warning rather than passed through, since this string reaches a
compiler command line.

=item * C<IF_ARCH=E<lt>valueE<gt>> -- adds C<-march=E<lt>valueE<gt>> so the
compiler can target specific instruction-set extensions (AVX2 gather +
FMA, etc.) for the extended-mode oblique dot product and the fit-time
min/max scan's C<#pragma omp simd> loops. Accepts values like
C<x86-64-v3>, C<skylake>, or C<znver3> -- whatever your compiler's
C<-march=> accepts. Also validated (a restricted character set, not
passed through as-is) for the same reason as C<IF_OPT>.  The special
value C<none> (or an empty string) opts out of any arch recorded at
configure time, yielding a plain build.  Whenever a C<-march> is in
effect the build also adds C<-ffp-contract=off>: with FMA available
the compiler would otherwise contract C<a*b+c> into fused
multiply-adds whose different rounding breaks the guarantee that
C<use_c =E<gt> 1> and C<use_c =E<gt> 0> build bit-identical trees (the
C<-march> speedup comes from vectorization, not contraction, so this
costs essentially nothing).

=item * C<IF_NATIVE=1> -- shorthand for C<IF_ARCH=native>; ignored if
C<IF_ARCH> is also set. Prefer a specific C<IF_ARCH> value over this on
a machine you don't control exclusively (a shared build host, a
container base image): blanket C<-march=native> pulls in whatever
instruction sets the build host happens to have, including AVX-512 on
some Intel CPUs -- which is known to trigger clock throttling under
sustained heavy use and can make throughput I<worse> than a
conservative target like C<x86-64-v3> (AVX2, no AVX-512). If in doubt,
benchmark both before committing to one.

=item * C<IF_NO_OPENMP=1> -- build (or select) the serial C backend: the
OpenMP compile attempt is skipped entirely, so the resulting object has
no libgomp linkage and never starts an OpenMP runtime inside the
process. This differs from C<OMP_NUM_THREADS=1>, which merely runs the
parallel code on one thread but still loads libgomp. Set at
C<perl Makefile.PL> time it yields a serial prebuilt object; set at run
time against an OpenMP prebuilt install it triggers a runtime serial
build (needing a compiler). An explicit C<IF_NO_OPENMP=0> re-enables
OpenMP over a serial configure-time default.

=back

Whichever of these are used, the cached artefact under C<_Inline/> is
pinned to that build's instruction set -- delete C<_Inline/> (or use a
separate one per host) if the directory is shared across machines with
different CPUs, or a stale binary built for a narrower instruction set
than the current host will simply keep being reused.

=head2 Tuning the OpenMP runtime

These are standard OpenMP environment variables libgomp already reads
at run time (set before running your script, no module-specific
handling needed) -- listed here because they matter most for exactly
the workloads this module has: C<score_all_xs>'s per-point parallel
loop and C<use_openmp_fit>'s per-tree parallel loop.

=over 4

=item * C<OMP_NUM_THREADS=N> -- caps how many threads a parallel region
uses. Useful to leave headroom for other work sharing the machine, or
to pin down C<use_openmp_fit> reproducibility checks (see its docs
above: results don't depend on this, but it's a natural thing to vary
when confirming that).

=item * C<OMP_PROC_BIND=close> / C<OMP_PLACES=cores> -- on multi-socket
or otherwise NUMA machines, pins each thread to a core near where its
data already lives instead of letting the OS scheduler migrate threads
across sockets mid-run. Both C<score_all_xs> (each thread scans its own
slice of the packed query buffer) and C<use_openmp_fit> (each thread
builds one tree from packed training data) benefit from this when the
input is large enough to not fit comfortably in one socket's cache.

=back

These cost nothing to try -- unlike C<IF_ARCH>/C<IF_NATIVE>, they're
read fresh every run, not baked into a cached binary, so there's no
downside to experimenting per invocation.

=head1 GENERAL METHODS

=head2 new(%args)

Inits the object.

  - n_trees :: number of isolation trees in the ensemble
      default :: 100

  - sample_size :: sub-sample size used to build each tree... max samples
      default :: 256

  - max_depth :: per-tree height limit... if not defined is set to ceil(log2(psi))
      default :: undef

  - seed :: optional integer to seed srand with for reproducible trees...
          see perldoc -f srand for more info. This number is processed via abs(int()).
      default :: undef

  - mode :: if it should be IF or EIF
       axis :: classic axis-parallel splits (IF)
       extended :: oblique hyperplane splits (EIF)
      default :: axis

  - extension_level :: extended mode only... how many features take partin each
          split. 0 behaves like a single-feature (axis) cut; the
          maximum (n_features - 1) uses every varying feature. undef
          => maximum. Clamped to [0, n_features - 1] at fit time.

  - contamination :: expected fraction of anomalies, in (0, 0.5]. When given,
        fit() learns a score threshold that flags this fraction of
        the training set, and predict() uses it by default. undef
        => no learned threshold (predict() falls back to 0.5).
      default :: undef

  - missing :: how fit() treats undef (missing) feature cells. Scoring always
        tolerates undef regardless of this setting; it governs fit().
          die    :: croak from fit() if the training data contains any
                    undef cell. Scoring still maps undef to 0 (the
                    long-standing behaviour), so a model fitted on clean
                    data can still score rows with missing features.
          zero   :: treat a missing cell as the value 0, at fit and score.
          impute :: replace a missing cell with the per-feature mean (or
                    median, see impute_with) learned from the present
                    values at fit time. The fill vector is stored on the
                    model and reused for scoring and persistence.
          nan    :: build feature ranges from present values only and route
                    a point missing the split feature to the right child,
                    consistently at fit and score time. Missingness is
                    preserved as signal rather than filled.
      default :: die

  - impute_with :: 'mean' or 'median'; the statistic used to compute the
        per-feature fill under missing => 'impute'. Ignored otherwise.
      default :: mean

  - voting :: how the per-tree results are aggregated at scoring time.
        Trees are built identically in both settings -- only aggregation
        changes -- so the knob composes with either mode (axis or
        extended) and an existing model may switch it after the fact with
        set_voting() (which relearns a contamination threshold for the
        new mode).
          mean     :: classic Isolation Forest: a sample's path lengths
                      across all trees are averaged and normalised into
                      one anomaly score; predict() thresholds that score.
          majority :: Majority Voting Isolation Forest (MVIForest;
                      Chabchoub, Togbe, Boly & Chiky 2022 -- see
                      REFERENCES). Each tree scores the sample on its own
                      (s_i = 2**(-h_i / c(psi))) and votes it anomalous
                      when s_i >= the decision threshold; predict() flags
                      the sample when more than half of the trees
                      (int(n_trees/2) + 1) vote anomalous, and stops
                      walking trees per sample as soon as the outcome is
                      decided. The threshold argument/default of the
                      predict methods is therefore the PER-TREE cutoff
                      here, not a forest-level score cutoff.
                      score_samples() returns the fraction of trees
                      voting anomalous -- still in [0, 1], but discrete
                      in steps of 1/n_trees. contamination composes: fit()
                      learns the per-tree cutoff that flags the requested
                      fraction of the training set.
      default :: mean

  - parallel_fit :: positive integer N => build the trees across N forked
        worker processes during fit(). Each worker gets a derived seed
        (parent seed + worker_id * 1009) so the parallel fit is
        reproducible across runs at fixed worker count -- but the trees
        produced are NOT bit-identical to a serial fit with the same
        seed, because the RNG draws happen in a different order.
        Inference is unaffected. Falls back silently to serial on
        platforms without a real fork() (e.g. Windows without Cygwin).
      default :: undef (serial)

  - use_c :: boolean, override whether the Inline::C backend is used for
        both scoring and fit()'s tree builder.  When false the instance
        falls back to pure Perl for both even if the C backend compiled
        successfully.  When true (or unset) the C backend is used if
        available ($HAS_C).  fit() with use_c on produces bit-identical
        trees to use_c off for the same seed -- only build speed differs.
      default :: $HAS_C

  - use_openmp :: boolean, override whether OpenMP parallel scoring is
        used inside score_all_xs().  When false the C tree walk runs
        single-threaded even if OpenMP was linked in.  Ignored when
        use_c is false (pure Perl has no OpenMP path).
      default :: $HAS_OPENMP

  - use_openmp_fit :: boolean, build fit()'s trees across OpenMP threads
        (one tree per thread) instead of the single-threaded C builder.
        Opt-in and off by default: unlike use_c/use_openmp, this changes
        which trees get built. Perl's RNG isn't safe to call from
        multiple OS threads sharing one interpreter, so this path seeds
        an independent PRNG per tree from the tree index rather than
        Drand01() -- trees differ from the use_c (single-threaded)
        and pure-Perl paths even with the same seed, though a fixed
        seed and n_trees still reproduce the same trees regardless of
        OMP_NUM_THREADS or scheduling. Does NOT compose with
        parallel_fit: a forked child starting its own OpenMP region
        after the parent process has used OpenMP for anything can
        hang (a general fork()+libgomp limitation), so parallel_fit's
        workers always use the single-threaded C builder regardless
        of this setting -- setting both just means parallel_fit wins.
        Ignored (clamped to 0) when use_c is false or OpenMP isn't
        linked in.
      default :: 0

  - feature_names :: optional arrayref of per-feature labels enabling the
        *_tagged methods (and required by mungers below).
      default :: undef

  - mungers :: optional hashref of declarative L<Algorithm::ToNumberMunger>
        specs, keyed as that module's compile() expects (scalar mungers by
        their output tag, expanding mungers by any label with an 'into'
        list, combining mungers by their output tag with a 'from' list).
        When set, every tagged row -- the *_tagged methods, fit_tagged,
        and tagged_row_to_array -- is munged from raw values (strings,
        timestamps, status codes, ...) into numbers through the compiled
        plan, and munge_rows() applies the scalar mungers to positional
        rows.  Requires feature_names; the plan compiles against them, so
        any spec error croaks here in new().  Algorithm::ToNumberMunger is
        an optional dependency, required only when a spec is given (or a
        loaded model carrying one is used with tagged data).  The spec is
        saved with the model, so a loaded model munges scoring input
        exactly as it did training input.  See L</MUNGERS> for details
        and caveats.
      default :: undef

  - schema_version :: optional opaque string identifying the revision of
        the variable schema this model was built against.  Never parsed
        or compared numerically; saved with the model and shown by
        `iforest info`.  Usually set from a prototype (see
        L</PROTOTYPES>) rather than passed directly.
      default :: undef

  - schema_description :: optional opaque free-text description of what
        the variable schema is.  Same handling as schema_version.
      default :: undef

  - feature_descriptions :: optional hashref of 'feature name => free
        text' describing individual features.  Requires feature_names;
        every key must name an entry there (a description for a feature
        that does not exist croaks -- it is either a typo or a stale
        leftover from a schema change).  Partial coverage is fine.
        Saved with the model and shown beside each tag by
        `iforest info`.
      default :: undef

Note: log2 under Perl is as below...

    log($psi) / log(2)


=cut

sub new {
	my ( $class, %args ) = @_;

	my $mode = $args{mode} // 'axis';
	croak "mode must be 'axis' or 'extended'"
		unless $mode eq 'axis' || $mode eq 'extended';

	# How fit() treats undef (missing) feature cells.  Scoring always
	# tolerates undef regardless of this setting -- it governs fit only.
	#   die    :: croak if the training data contains any undef cell (default)
	#   zero   :: treat a missing cell as the value 0
	#   impute :: replace a missing cell with the per-feature mean/median
	#             learned from the present values at fit time
	#   nan    :: build ranges over present values only and route a point
	#             missing the split feature consistently to one branch, at
	#             both fit and score time
	my $missing = $args{missing} // 'die';
	croak "missing must be one of: die, zero, impute, nan"
		unless $missing =~ /\A(?:die|zero|impute|nan)\z/;

	my $impute_with = $args{impute_with} // 'mean';
	croak "impute_with must be 'mean' or 'median'"
		unless $impute_with =~ /\A(?:mean|median)\z/;

	# How per-tree results are aggregated at scoring time.  Trees are
	# built identically either way -- this knob never touches fit()'s
	# forest, only how score/predict combine the per-tree path lengths.
	#   mean     :: classic IForest: average path length across trees,
	#               normalised into one score (the default)
	#   majority :: MVIForest (Chabchoub et al. 2022): each tree votes
	#               anomalous/normal against the decision threshold and
	#               the label is the majority of the tree votes
	my $voting = $args{voting} // 'mean';
	croak "voting must be 'mean' or 'majority'"
		unless $voting =~ /\A(?:mean|majority)\z/;

	if ( defined( $args{seed} ) ) {
		$args{seed} = abs( int( $args{seed} ) );
	}

	# Clamp the accel knobs against what the build actually has.  Passing
	# use_c => 1 on a machine where Inline::C never compiled would otherwise
	# leave score_samples() calling an undefined XS sub at first use.
	# OpenMP is meaningless without the C tree walk, so force it off
	# whenever the C backend is off -- matches the documented
	# "Ignored when use_c is false" semantics.
	my $use_c
		= defined $args{use_c}
		? ( $args{use_c} && $HAS_C ? 1 : 0 )
		: $HAS_C;
	my $use_openmp
		= defined $args{use_openmp}
		? ( $args{use_openmp} && $HAS_OPENMP ? 1 : 0 )
		: $HAS_OPENMP;
	$use_openmp = 0 unless $use_c;

	# Opt-in only (default 0, not $HAS_OPENMP): this path changes which
	# trees fit() builds (see docs above), unlike use_c/use_openmp which
	# only change speed.  Clamped the same way use_openmp is.
	my $use_openmp_fit = ( $args{use_openmp_fit} && $HAS_OPENMP && $use_c ) ? 1 : 0;

	my $self = {
		n_trees              => $args{n_trees}     // 100,
		sample_size          => $args{sample_size} // 256,
		max_depth            => $args{max_depth},              # undef => auto
		seed                 => $args{seed},                   # undef => non-deterministic
		mode                 => $mode,
		extension_level      => $args{extension_level},        # undef => max, resolved in fit()
		contamination        => $args{contamination},          # undef => no learned threshold
		parallel_fit         => $args{parallel_fit},           # undef/0/1 => serial; N>1 => fork
		missing              => $missing,                      # die|zero|impute|nan
		impute_with          => $impute_with,                  # mean|median (impute mode only)
		voting               => $voting,                       # mean|majority (scoring-time aggregation)
		missing_fill         => undef,                         # per-feature fill, learned in fit() if impute
		feature_baselines    => undef,                         # per-feature medians, learned in fit();
															   # the "typical row" ablation explanations
															   # substitute against -- see explain_samples
		_use_c               => $use_c,
		_use_openmp          => $use_openmp,
		_use_openmp_fit      => $use_openmp_fit,
		threshold            => undef,                         # learned in fit() if contamination set
		trees                => [],
		c_psi                => undef,                         # c(psi), set during fit()
		n_features           => undef,
		feature_names        => $args{feature_names},          # optional arrayref of per-feature labels
		mungers              => undef,                         # optional Algorithm::ToNumberMunger spec hash
															   # Opaque schema metadata, usually set via new_from_prototype and
															   # persisted with the model.  Never parsed -- documentation that
															   # travels with the model file.
		schema_version       => $args{schema_version},
		schema_description   => $args{schema_description},
		feature_descriptions => $args{feature_descriptions},
	};

	for my $doc (qw(schema_version schema_description)) {
		croak "$doc must be a plain string"
			if defined $self->{$doc} && ref $self->{$doc};
	}
	_validate_feature_descriptions( $self->{feature_names}, $self->{feature_descriptions} )
		if defined $self->{feature_descriptions};

	# Optional Algorithm::ToNumberMunger integration: a declarative spec
	# hash compiled into a plan that turns raw tagged values into numbers.
	# Compiled eagerly so every spec error surfaces here rather than at
	# first scoring; the module itself is only required when a spec is
	# actually given, keeping it an optional dependency.
	if ( defined $args{mungers} ) {
		croak "mungers must be a hashref of 'tag => munger spec'"
			unless ref $args{mungers} eq 'HASH';
		croak "mungers requires feature_names (the munger plan compiles against them)"
			unless ref $self->{feature_names} eq 'ARRAY' && @{ $self->{feature_names} };
		$self->{mungers}               = $args{mungers};
		$self->{_munger_plan}          = _compile_mungers( $self->{feature_names}, $self->{mungers} );
		$self->{munger_module_version} = $Algorithm::ToNumberMunger::VERSION;
	}

	croak "n_trees must be >= 1"     unless $self->{n_trees} >= 1;
	croak "sample_size must be >= 1" unless $self->{sample_size} >= 1;
	croak "extension_level must be >= 0"
		if defined $self->{extension_level} && $self->{extension_level} < 0;
	croak "contamination must be a number in (0, 0.5]"
		if defined $self->{contamination}
		&& !( $self->{contamination} > 0 && $self->{contamination} <= 0.5 );
	croak "parallel_fit must be a positive integer"
		if defined $self->{parallel_fit}
		&& ( $self->{parallel_fit} !~ /^\d+$/ || $self->{parallel_fit} < 1 );

	return bless $self, $class;
} ## end sub new

=head2 decision_threshold

The score cutoff C<predict> uses by default; undef unless C<contamination> was
set.

=cut

sub decision_threshold { return $_[0]->{threshold} }

=head2 set_voting

Switches the scoring-time aggregation between C<'mean'> and C<'majority'> on an
existing model and returns C<$self> (so it chains). The forest itself is
identical in both modes -- only the way per-tree results are combined changes
-- so this never rebuilds a single tree.

    $iforest->set_voting('majority');
    $iforest->set_voting('mean', \@training_data);

The one thing that does not carry over is a C<contamination>-learned
L</decision_threshold>. That cutoff is a quantile of whichever per-point
quantity the mode thresholds against -- the averaged anomaly score under
C<'mean'>, the per-tree majority pivot under C<'majority'> -- and those live in
different spaces, so a threshold learned in one mode flags the wrong fraction
in the other. When the model was fitted with C<contamination>, C<set_voting>
therefore relearns the threshold for the target mode, which requires the
original training data to be passed as the second argument (the model does not
retain it). Switching a model that had no C<contamination> needs no data:
C<predict> falls back to C<0.5>, which is meaningful in both modes.

Passing the current mode is a no-op (returns immediately, no data needed).
Calling this before L</fit> just records the mode for the eventual fit.

=cut

sub set_voting {
	my ( $self, $voting, $data ) = @_;

	croak "set_voting: voting must be 'mean' or 'majority'"
		unless defined $voting && $voting =~ /\A(?:mean|majority)\z/;

	return $self if $self->{voting} eq $voting;

	# A learned threshold only exists once a contamination-fitted model has
	# been fit(); that value is mode-specific and must be relearned against
	# the same training set (see _learn_contamination_threshold).  Everything
	# else -- pre-fit models, and fitted models without contamination -- just
	# flips the knob; predict()'s 0.5 fallback is valid in either mode.
	my $fitted      = ref $self->{trees} eq 'ARRAY' && @{ $self->{trees} };
	my $recalibrate = $fitted                       && defined $self->{contamination};
	if ($recalibrate) {
		croak "set_voting: switching a contamination-fitted model requires "
			. "the original training data as the second argument to "
			. "recalibrate the decision threshold"
			unless ref $data eq 'ARRAY' && @$data;
	}

	$self->{voting} = $voting;
	$self->_learn_contamination_threshold($data) if $recalibrate;

	return $self;
} ## end sub set_voting

=head2 feature_names

Returns the arrayref of feature name strings stored with the model, or undef
if none were provided at fit time.

    my $names = $iforest->feature_names;

=cut

sub feature_names { return $_[0]->{feature_names} }

=head2 schema_version

Returns the user-owned schema version string stored with the model
(usually via a prototype -- see L</PROTOTYPES>), or undef if none was
recorded.

    my $sv = $iforest->schema_version;

=cut

sub schema_version { return $_[0]->{schema_version} }

=head2 schema_description

Returns the free-text description of the variable schema stored with the
model, or undef if none was recorded.

=cut

sub schema_description { return $_[0]->{schema_description} }

=head2 feature_descriptions

Returns the hashref of per-feature description strings stored with the
model, or undef if none were recorded.  Keys are feature names; coverage
may be partial.

=cut

sub feature_descriptions { return $_[0]->{feature_descriptions} }

=head2 fit

Trains the model on the specified data.

The data taken is an array of arrays. Each sub-array is one sample and must
contain one or more numeric features. All samples must have the same number
of features. There is no upper limit on dimensionality.

    @training_data = (
        [ 3, 5 ],
        [ 2.3, 1 ],
        [ 5, 9 ],
        ...
    );

    # Three-feature example
    @training_data = (
        [ 1.0, 2.0, 3.0 ],
        [ 1.1, 1.9, 3.1 ],
        ...
    );

Below shows an example of building a gaussian cluster and using that for training.

    # so it is reproducible
    srand(7);

    # build a gaussian cluster and add a handful of outliers...

    use constant PI => 3.14159265358979;
    sub gaussian {
        my ($mu, $sigma) = @_;
        my $u1 = rand() || 1e-12;
        my $u2 = rand();
        my $z  = sqrt(-2 * log($u1)) * cos(2 * PI * $u2);
        return $mu + $sigma * $z;
    }

    # add some normal items
    for (1 .. 500) {
        push @data,  [ gaussian(0, 1), gaussian(0, 1) ];
        push @truth, 0;
    }
    # add some outliers
    for (1 .. 20) {
        my $angle  = rand() * 2 * PI;
        my $radius = 5 + rand() * 3;             # distance 5..8 from the origin
        push @data,  [ $radius * cos($angle), $radius * sin($angle) ];
        push @truth, 1;
    }

    $iforest->fit(\@data);

=cut

sub fit {
	my ( $self, $data ) = @_;

	croak "fit() expects a non-empty arrayref of samples"
		unless ref $data eq 'ARRAY' && @$data;
	croak "each sample must be an arrayref of features"
		unless ref $data->[0] eq 'ARRAY' && @{ $data->[0] };

	my $n_features = scalar @{ $data->[0] };
	$self->{n_features} = $n_features;

	# Apply the missing-value strategy before any tree is built.  Depending
	# on the strategy this either croaks (die), returns a dense copy with
	# undef cells filled (zero/impute), or passes the data through with
	# undef preserved for the split logic to route (nan).  Everything below
	# trains on $train, never the raw $data.
	my $train = $self->_prepare_fit_data($data);

	# Per-feature medians of the raw training data, stored for ablation
	# explanations (explain_samples).  From $data, not $train: the pure-
	# Perl path's densified $train would bake fill values into the
	# medians while the C path's raw pass-through would not, and the
	# baselines must not depend on use_c.
	$self->{feature_baselines} = $self->_compute_feature_baselines($data);

	my $n = scalar @$train;

	# Resolve sub-sample size, extension level and height limit against the
	# data's shape.  Shared with fit_from_csv(), which learns n from a census
	# pass before it ever holds the rows in RAM.
	my ( $psi, $limit ) = $self->_resolve_geometry( $n, $n_features );

	srand( $self->{seed} ) if defined $self->{seed};

	my $workers = $self->{parallel_fit};
	if (   defined $workers
		&& $workers > 1
		&& $self->{n_trees} > 1
		&& _fork_supported() )
	{
		$self->{trees} = $self->_fit_trees_parallel( $train, $psi, $limit, $workers );
	} elsif ( $self->{_use_c} && $self->{_use_openmp_fit} ) {
		$self->{trees} = $self->_build_forest_openmp( $train, $psi, $limit, $self->{n_trees} );
	} elsif ( $self->{_use_c} ) {
		$self->{trees}
			= $self->_build_forest_c( $train, $psi, $limit, $self->{n_trees} );
	} else {
		my @trees;
		for ( 1 .. $self->{n_trees} ) {
			my $sample = _subsample( $train, $psi );
			push @trees, $self->_build_tree( $sample, 0, $limit );
		}
		$self->{trees} = \@trees;
	}

	# On a re-fit, packed scoring buffers from the previous fit are still
	# sitting on the object; score_samples() below would pick them up and
	# learn the contamination threshold against the OLD forest.  Drop them
	# so the training-set scoring runs pure-Perl against the trees just
	# built; _rebuild_c_trees repacks from the new trees at the end.
	delete @$self{qw(_c_nodes _c_coef_idx _c_coef_val)};

	# If a contamination rate was requested, learn the score cutoff that flags
	# that fraction of the training set. The threshold lands midway inside a
	# real gap between flagged and unflagged training scores (ties at the
	# k-boundary shift the cut to the nearest gap -- see
	# _threshold_from_ranked), so it sits strictly between attainable values:
	# unambiguous and robust to the tiny float rounding introduced by JSON
	# serialisation.
	#
	# Under voting => 'majority' the value predict() thresholds against is
	# the PER-TREE score, so the quantity to rank is each training point's
	# majority pivot -- the per-tree cutoff at which that point loses its
	# majority (see _majority_pivot_scores).  A point is flagged iff its
	# pivot >= threshold, exactly the relation the mean-mode score has, so
	# the midpoint selection below serves both modes unchanged.
	$self->_learn_contamination_threshold($train)
		if defined $self->{contamination};

	$self->_rebuild_c_trees() if $self->{_use_c};
	return $self;
} ## end sub fit

=head2 fit_tagged(\@rows)

Trains the model on an arrayref of hashrefs of named feature values --
the tagged counterpart of L</fit>.  Each row goes through
L<tagged_row_to_array|/tagged_row_to_array(\%row, $caller)> (and
therefore through the munger plan when C<mungers> is configured, which is
the point: training data and scoring data are munged by the identical
plan), then the positional rows are handed to C<fit>.

    $iforest->fit_tagged([
        { cpu => 0.9, mem => 0.4, disk => 0.1 },
        { cpu => 0.2, mem => 0.3, disk => 0.2 },
        ...
    ]);

Requires stored C<feature_names>.  Croaks under the same conditions as
L<tagged_row_to_array|/tagged_row_to_array(\%row, $caller)>, naming the offending row by index.

=cut

sub fit_tagged {
	my ( $self, $data ) = @_;
	croak "fit_tagged() expects a non-empty arrayref of hashref samples"
		unless ref $data eq 'ARRAY' && @$data;
	my @rows;
	for my $i ( 0 .. $#$data ) {
		push @rows, $self->tagged_row_to_array( $data->[$i], "fit_tagged (row $i)" );
	}
	return $self->fit( \@rows );
} ## end sub fit_tagged

=head2 fit_from_csv($path, %opts)

Trains the model directly from a CSV file B<without loading it into RAM>,
for datasets too large to slurp.  An Isolation Forest never trains on more
than C<n_trees * sample_size> rows -- each tree uses one independent
sub-sample of C<sample_size> points -- so the working set is bounded by the
model's parameters, not the file size.

The file is read in two (or three) passes:

=over 4

=item 1.

B<Census> -- count the rows (this is the true C<n> that fixes C<psi =
min(sample_size, n)>) and pin the feature width.  By default this is an
I<index> pass (see C<index> below): a fast block-scan that also records each
data row's byte offset.

=item 2.

B<Gather> -- retain only the rows the trees actually sampled (chosen in
bounded memory via Floyd's algorithm), then build each tree from its
sub-sample exactly as L</fit> would.  With the offset table from pass 1 this
B<seeks straight to the sampled rows> instead of re-scanning the file.

=item 3.

B<Threshold> (only when C<contamination> is set) -- score every row against
the built forest and place the cut at the contamination boundary.  The cut
is B<exact>, not estimated: a single min-heap of the C<k+1> largest scores
(C<k = round(contamination * n)>) captures everything
L</decision_threshold> selection needs, with a rare extra pass to resolve a
tie block straddling the boundary.  Under C<< use_c => 1 >> (the default when
the C backend is present) this pass runs through the C scorer, so it stays
fast even over millions of rows.

=back

Neither census variant parses cells into numbers or checks for missing
values: only the rows that actually train (via gather) or are scored (the
threshold pass) are validated, so a malformed or missing cell in a
never-used row is not reported.  In particular, under C<< missing => 'die' >>
a missing cell is rejected exactly when it appears in a sampled training row.

Because rows are addressed by their position across passes, C<$path> must be
a stable, re-readable file (not a pipe or C<STDIN>).

The first line is skipped as a header when it holds any non-numeric text (a
feature-name row) or exactly matches the model's stored C<feature_names> --
data rows contain only numbers and empty cells.  Pass C<< header => 1 >> to
force the first line to be skipped even when it is all-numeric.

Options:

=over 4

=item * C<< header => 1 >> -- always skip the first line as a column header
(otherwise a header is auto-detected as described above).

=item * C<< index => 0 >> -- disable the offset-index pass and use the
streaming two-pass reader instead.  The index is on by default: it makes
gather a random-access read of just the sampled rows rather than a second
full scan, but costs an C<8 * n>-byte offset table.  When that table would
exceed C<index_max> it is dropped automatically and the fit falls back to
streaming.  (In index mode a blank line is one that is empty or contains only
whitespace, judged cheaply; pass C<< index => 0 >> for files where that
matters.)

=item * C<< index_max => bytes >> -- ceiling on the offset table (default
256 MiB).  Above it, the index is abandoned mid-scan and gather streams.

=item * C<< c_scan => 0 >> -- validate each scored cell with
C<looks_like_number> in the threshold pass instead of letting the C packer
coerce it.  C<c_scan> is on by default and takes effect only on the C
mean-voting scoring path, where it is a large saving over millions of rows;
it produces the identical result on valid data, but coerces a non-numeric
scored cell to C<0.0> (nudging the threshold) rather than dying on it.

=back

Every column is a feature; an empty cell is treated as a missing value and
handled by the model's C<missing> strategy.  The resulting model is
identical in shape to one built by L</fit> and is fully deterministic given
the same file, C<seed>, and parameters (though not bit-identical to
L</fit>, whose RNG stream interleaves sampling and tree-building
differently).

Current limitations: C<mungers> and tagged/named columns are not supported
(load such data through L<fit_tagged|/fit_tagged(\@rows)>), and the trees are always built
serially in pure Perl -- C<parallel_fit>/C<use_openmp_fit> are ignored for
the build, though scoring is still accelerated when C<use_c> is on.

    my $iforest = Algorithm::Classifier::IsolationForest->new(
        n_trees       => 100,
        sample_size   => 256,
        contamination => 0.01,
        seed          => 42,
    );
    $iforest->fit_from_csv('huge.csv', header => 1);

=cut

sub fit_from_csv {
	my ( $self, $path, %opt ) = @_;

	croak "fit_from_csv() requires a path to a CSV file"
		unless defined $path && length $path;
	croak "fit_from_csv(): '$path' is not a readable file"
		unless -f $path && -r _;
	croak "fit_from_csv() does not support munger models; " . "load the data through fit_tagged/fit instead"
		if _plan($self);

	# Decide once whether the first line is a header, so every pass skips the
	# same line and row indices stay aligned.  header => 1 forces it; otherwise
	# a first line carrying any non-numeric text (or matching stored
	# feature_names) is a header -- data rows hold only numbers and blanks.
	my $skip_first = $self->_detect_header( $path, $opt{header} );

	# ---- Pass 1: census.  Establish the true row count (which fixes psi) and
	# pin the feature width.  Neither census variant parses cells into numbers
	# or checks for missing values -- only the rows that actually train
	# (_numify_row, in gather) or get scored (the threshold pass) are validated,
	# so a malformed or missing cell in a never-sampled row is not seen.
	#
	# By default the census is an "index" pass: a block-scan that also records
	# each data row's byte offset, letting Pass 2 seek straight to the sampled
	# rows instead of re-scanning the whole file.  The offset table costs 8*n
	# bytes; when that would top index_max (or index => 0 was passed) it is not
	# built and both passes fall back to the streaming reader.
	my $use_index = exists $opt{index}      ? $opt{index}     : 1;
	my $index_max = defined $opt{index_max} ? $opt{index_max} : ( 256 * 1024 * 1024 );

	my ( $n, $n_features, $offsets );
	if ($use_index) {
		( $n, $n_features, $offsets ) = $self->_index_pass( $path, $skip_first, $index_max );
	} else {
		( $n, $n_features ) = $self->_census_stream( $path, $skip_first );
	}
	croak "fit_from_csv(): no data rows in '$path'" unless $n;

	# A stored feature_names schema fixes the expected column count.
	if ( ref $self->{feature_names} eq 'ARRAY' && @{ $self->{feature_names} } ) {
		my $want = scalar @{ $self->{feature_names} };
		croak "fit_from_csv(): $want feature_names but CSV has $n_features columns"
			unless $want == $n_features;
	}

	$self->{n_features} = $n_features;
	my ( $psi, $limit ) = $self->_resolve_geometry( $n, $n_features );

	# ---- Choose which row indices each tree trains on: an independent,
	# uniform psi-subset drawn without replacement.  Floyd's algorithm draws
	# each subset in O(psi) memory, never materialising the 0..n-1 index
	# vector _subsample() uses -- for an out-of-core n that vector would not
	# fit either.  %want maps each needed row index to the (tree, slot) pairs
	# awaiting it, so a row several trees picked is gathered once and shared.
	srand( $self->{seed} ) if defined $self->{seed};
	my @tree_idx;    # tree => [ chosen row indices ]
	my %want;        # row index => [ [tree, slot], ... ]
	for my $t ( 0 .. $self->{n_trees} - 1 ) {
		my @idx = _sample_indices_distinct( $n, $psi );
		$tree_idx[$t] = \@idx;
		push @{ $want{ $idx[$_] } }, [ $t, $_ ] for 0 .. $#idx;
	}

	# ---- Pass 2: gather the sampled rows (validated + coerced by _numify_row).
	# With an offset table this seeks straight to them; otherwise it re-scans.
	my $pool
		= $offsets
		? $self->_gather_indexed( $path, $offsets, \%want )
		: $self->_gather_stream( $path, $skip_first, \%want );

	# Baselines for ablation explanations, learned from the gathered
	# sub-sample -- like the impute fill below, the only rows bounded-
	# memory fitting ever holds.  Before _apply_missing_to_pool, which
	# densifies the pool in place (the medians must come from present
	# values only, matching fit()).  Median is an exact order statistic,
	# so the hash-order values() walk cannot change the result.
	$self->{feature_baselines} = $self->_compute_feature_baselines( [ values %$pool ] );

	# Apply the missing-value strategy to the retained rows (see fit()'s
	# _prepare_fit_data; the impute fill is learned from this training
	# sub-sample, the only value bounded-memory fitting can compute).
	$self->_apply_missing_to_pool($pool);

	# ---- Build. Each tree trains on its gathered sub-sample -- structurally
	# identical to fit()'s per-tree _build_tree(_subsample(...)).
	my @trees;
	for my $t ( 0 .. $self->{n_trees} - 1 ) {
		my $sample = [ @{$pool}{ @{ $tree_idx[$t] } } ];
		push @trees, $self->_build_tree( $sample, 0, $limit );
	}
	$self->{trees} = \@trees;

	# Repack the just-built trees for the C scorer up front.  fit() scores its
	# learned threshold pure-Perl because its training set is small; the
	# streaming contamination pass here may score millions of rows, so paying
	# one repack now lets that pass run through the C path instead (bit-
	# identical result, minutes -> seconds).  The delete first clears any stale
	# buffers from a prior fit so the repack reflects the new forest.
	delete @$self{qw(_c_nodes _c_coef_idx _c_coef_val)};
	$self->_rebuild_c_trees() if $self->{_use_c};

	# c_scan (default on): let the C scorer's packer coerce raw cells via SvNV
	# in the contamination pass instead of validating each with looks_like_number
	# in Perl -- a large saving over millions of rows.  It only takes effect on
	# the C mean-voting path; see _stream_scores.
	my $c_scan = exists $opt{c_scan} ? $opt{c_scan} : 1;
	$self->_learn_contamination_threshold_streaming( $path, $skip_first, $n, $c_scan )
		if defined $self->{contamination};

	return $self;
} ## end sub fit_from_csv

=head2 pack_data(\@data)

Returns an opaque, blessed wrapper around the input dataset that the
scoring methods can use directly, skipping the per-call work of walking
the arrayref-of-arrayrefs and converting each cell into a double.  At
high feature counts this is a meaningful win when the same dataset is
scored repeatedly (e.g. interactive threshold tuning, dashboards,
plotting that updates as parameters change).

Requires the Inline::C backend; croaks if C<use_c> is false.

    my $packed = $forest->pack_data(\@data);

    # Now any of these accept either an arrayref or the packed wrapper:
    my $scores = $forest->score_samples($packed);
    my $flags  = $forest->predict($packed, 0.6);
    my ($s, $l) = $forest->score_predict_split($packed);

The wrapper has C<n_pts> and C<n_feats> accessors for introspection.
The feature count is matched against the model on every call; passing a
packed dataset built for a different feature count is a fatal error.

=cut

=head2 path_lengths(\@data)

Returns an arrayref of the mean isolation depth per sample, for inspection.

    my $lengths = $forest->path_lengths(\@data);

    print "x, y, length\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$lengths->[$int]."\n";

        $int++;
    }

=cut

sub path_lengths {
	my ( $self, $data ) = @_;
	$self->_check_fitted;
	my $trees = $self->{trees};
	my $t     = scalar @$trees;

	if ( $self->{_use_c} && $self->{_c_nodes} ) {
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs(
			$self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,         $sums_packed,         $n_pts,
			$nf,               $t,                   $self->{_use_openmp}
		);
		my $result = [];
		finalize_path_lengths_xs( $sums_packed, $n_pts, $t + 0.0, $result );
		return $result;
	} ## end if ( $self->{_use_c} && $self->{_c_nodes} )

	$data = $self->_prepare_perl_input($data);
	my $nan = $self->{missing} eq 'nan' ? 1 : 0;

	# Pure-Perl fallback (tree-outer, sample-inner for cache locality).
	my @sums = (0) x @$data;
	for my $tree (@$trees) {
		for my $i ( 0 .. $#$data ) {
			$sums[$i] += _path_length( $data->[$i], $tree, 0, $nan );
		}
	}
	return [ map { $_ / $t } @sums ];
} ## end sub path_lengths

=head2 predict(\@data, $threshold)

Returns an arrayref of 0/1 labels for the specified data.

If threshold is not specified it uses the contamination-learned cutoff (if
C<fit> was called with C<contamination>), otherwise 0.5.

Under C<< voting => 'majority' >> the threshold is the per-tree score
cutoff each tree votes against, and a sample is labelled 1 when more than
half of the trees (C<int(n_trees/2) + 1>) vote it anomalous.  Tree walking
stops per sample as soon as the outcome is decided, so this is typically
cheaper than scoring.

    my $results = $forest->predict(\@data, $threshold);

    print "x, y, result\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$results->[$int]."\n";

        $int++;
    }

=cut

sub predict {
	my ( $self, $data, $threshold ) = @_;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;
	$self->_check_fitted;

	# Majority voting: $threshold is the PER-TREE score cutoff and the
	# label is the majority of the tree votes (int(t/2) + 1).  Both the C
	# and the Perl loop stop walking a sample's remaining trees as soon
	# as the outcome is decided -- MVIForest's "stop at majority" saving.
	if ( $self->{voting} eq 'majority' ) {
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $cut   = _depth_cut( $threshold, $self->{c_psi} );
		my $maj   = _min_votes($t);

		if ( $self->{_use_c} && $self->{_c_nodes} ) {
			my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
			my $labels_packed = "\0" x ( $n_pts * 8 );
			vote_all_xs( $self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
				$x_packed, $labels_packed, $n_pts, $nf, $t, $cut, $maj, $self->{_use_openmp} );
			my $result = [];
			vote_labels_xs( $labels_packed, $n_pts, $result );
			return $result;
		}

		my $rows = $self->_prepare_perl_input($data);
		my $nan  = $self->{missing} eq 'nan' ? 1 : 0;
		my @labels;
		for my $x (@$rows) {
			my $votes = 0;
			my $label = 0;
			for my $ti ( 0 .. $t - 1 ) {
				if ( _path_length( $x, $trees->[$ti], 0, $nan ) <= $cut ) {
					$votes++;
					if ( $votes >= $maj ) { $label = 1; last }
				}
				last if $votes + ( $t - 1 - $ti ) < $maj;
			}
			push @labels, $label;
		} ## end for my $x (@$rows)
		return \@labels;
	} ## end if ( $self->{voting} eq 'majority' )

	# Fast path: threshold the raw path-length sums directly, skipping the
	# per-point exp() and the intermediate scores arrayref.
	# Derivation: score = exp(-sum * log(2) / (c*t))
	#   so   score >= T   iff   sum <= -log(T) * c * t / log(2)
	# Only valid for a normal threshold in (0, 1) and a positive c.
	if (   $self->{_use_c}
		&& $self->{_c_nodes}
		&& $self->{c_psi} > 0
		&& $threshold > 0
		&& $threshold < 1 )
	{
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $c     = $self->{c_psi};
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs(
			$self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,         $sums_packed,         $n_pts,
			$nf,               $t,                   $self->{_use_openmp}
		);
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $result        = [];
		predict_sums_xs( $sums_packed, $n_pts, $sum_threshold, $result );
		return $result;
	} ## end if ( $self->{_use_c} && $self->{_c_nodes} ...)

	# Fallback: edge thresholds, c==0, or no C backend.
	my $scores = $self->score_samples( $self->_to_arrayref($data) );
	return [ map { $_ >= $threshold ? 1 : 0 } @$scores ];
} ## end sub predict

=head2 predict_tagged(\%row, $threshold)

Predicts whether a single sample is an anomaly using a hashref of named
feature values.  The model must have been fitted (or loaded from a model
that was fitted) with feature names stored via C<feature_names>.

C<$threshold> defaults the same way as in C<predict>.

Returns a scalar 1 (anomaly) or 0 (normal).

    my $label = $forest->predict_tagged(
        { cpu => 0.9, mem => 0.4, disk => 0.1 },
    );

Croaks if the model has no stored feature names, if the hashref contains a
key that is not a known feature name, or if a feature name is absent from the
hashref.

=cut

=head2 tagged_row_to_array(\%row, $caller)

Validates a hashref of named feature values against the model's stored
C<feature_names> and returns a positional arrayref ready to pass to any
of the scoring or prediction methods.

C<$caller> is a string used in error messages to identify which method
triggered the validation (pass the calling method's name).

    my $vec = $forest->tagged_row_to_array(\%row, 'my_method');
    # returns e.g. [0.9, 0.4, 0.1] ordered by feature_names

Croaks if:

=over 4

=item * C<$row> is not a hashref

=item * the model has no stored C<feature_names>

=item * the hashref contains a key that is not a known feature name

=item * a feature name is absent from the hashref

=back

=cut

sub tagged_row_to_array {
	my ( $self, $row, $caller ) = @_;
	croak "$caller requires a hashref"
		unless ref $row eq 'HASH';

	# With mungers configured the compiled plan owns the row assembly:
	# it knows the real input fields (munger 'from' sources included,
	# which need not be tags at all) and croaks on a missing one.  Extra
	# keys are ignored -- with expanders and combiners in play, "the
	# exact key set" is the plan's knowledge, not feature_names'.
	if ( my $plan = _plan($self) ) {
		my $vec = eval { $plan->apply_named($row) };
		croak "$caller: $@" if $@;
		return $vec;
	}

	croak "this model has no stored feature_names; " . "refit with -t tags or pass feature_names to new()"
		unless defined $self->{feature_names}
		&& ref $self->{feature_names} eq 'ARRAY'
		&& @{ $self->{feature_names} };

	my @names = @{ $self->{feature_names} };

	my @unknown = grep {
		my $k = $_;
		!grep { $_ eq $k } @names
	} keys %$row;
	croak "unknown feature name(s) in hashref: " . join( ', ', sort @unknown )
		if @unknown;

	my @missing = grep { !exists $row->{$_} } @names;
	croak "missing feature name(s) in hashref: " . join( ', ', @missing )
		if @missing;

	return [ map { $row->{$_} } @names ];
} ## end sub tagged_row_to_array

sub predict_tagged {
	my ( $self, $row, $threshold ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'predict_tagged' );
	my $result = $self->predict( [$vec], $threshold );
	return $result->[0];
}

=head2 munge_rows(\@rows)

Applies the model's scalar mungers to positional rows (arrayrefs in
C<feature_names> order), returning a new arrayref of munged rows.  A
model without C<mungers> returns the input unchanged, so callers such
as the CLI can pass every dataset through unconditionally.

Croaks if the munger set contains expanding or combining mungers --
their inputs are named source fields that positional rows cannot
express; use the tagged methods (or L<fit_tagged|/fit_tagged(\@rows)>) for those.

    my $numeric = $iforest->munge_rows(\@raw_rows);

=cut

sub munge_rows {
	my ( $self, $rows ) = @_;
	croak "munge_rows() expects an arrayref of rows"
		unless ref $rows eq 'ARRAY';
	my $plan = _plan($self);
	return $rows unless $plan;
	my @out;
	for my $i ( 0 .. $#$rows ) {
		my $munged = eval { $plan->apply_positional( $rows->[$i] ) };
		croak "munge_rows (row $i): $@" if $@;
		push @out, $munged;
	}
	return \@out;
} ## end sub munge_rows

=head2 score_samples(\@data)

Returns an arrayref of anomaly scores, between 0 and 1.

Scores near 1 are strong anomalies (isolated quickly).

Scores well below 0.5 are normal.

Scores ~0.5 means the points are hard to tell apart.

Under C<< voting => 'majority' >> the returned value is instead the
fraction of trees voting the sample anomalous at the model's decision
threshold (the contamination-learned cutoff if present, otherwise 0.5) --
still in [0, 1], but discrete in steps of C<1/n_trees>, with a majority
label corresponding to a fraction strictly above 0.5.

    my $scores = $forest->score_samples(\@data);

    print "x, y, score\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$scores->[$int]."\n";

        $int++;
    }

=cut

sub score_samples {
	my ( $self, $data ) = @_;
	$self->_check_fitted;
	my $c     = $self->{c_psi};
	my $trees = $self->{trees};
	my $t     = scalar @$trees;

	# Majority voting: the "score" is the fraction of trees voting the
	# sample anomalous at the model's decision threshold (contamination-
	# learned if present, else 0.5) -- discrete in steps of 1/t.
	if ( $self->{voting} eq 'majority' ) {
		my $theta = defined $self->{threshold} ? $self->{threshold} : 0.5;
		my $cut   = _depth_cut( $theta, $c );

		if ( $self->{_use_c} && $self->{_c_nodes} ) {
			my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
			my $votes_packed = "\0" x ( $n_pts * 8 );
			vote_all_xs( $self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
				$x_packed, $votes_packed, $n_pts, $nf, $t, $cut, 0, $self->{_use_openmp} );

			# votes/t is exactly the "divide the sum buffer by t" shape
			# finalize_path_lengths_xs implements, so reuse it.
			my $result = [];
			finalize_path_lengths_xs( $votes_packed, $n_pts, $t + 0.0, $result );
			return $result;
		} ## end if ( $self->{_use_c} && $self->{_c_nodes} )

		my $votes = $self->_vote_counts_perl( $self->_prepare_perl_input($data), $cut );
		return [ map { $_ / $t } @$votes ] if _NV_IS_DOUBLE;

		# Wide-NV perls: the C finalizers divide in double, so narrow the
		# vote fraction to match -- see _NV_IS_DOUBLE.
		return [ map { _to_double( $_ / $t ) } @$votes ];
	} ## end if ( $self->{voting} eq 'majority' )

	if ( $self->{_use_c} && $self->{_c_nodes} ) {
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs(
			$self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,         $sums_packed,         $n_pts,
			$nf,               $t,                   $self->{_use_openmp}
		);
		if ( $c > 0 ) {
			my $inv    = log(2) / ( $c * $t );
			my $result = [];
			finalize_scores_xs( $sums_packed, $n_pts, $inv, $result );
			return $result;
		}
		return [ (0.5) x $n_pts ];
	} ## end if ( $self->{_use_c} && $self->{_c_nodes} )

	$data = $self->_prepare_perl_input($data);
	my $nan = $self->{missing} eq 'nan' ? 1 : 0;

	# Pure-Perl fallback (tree-outer, sample-inner for cache locality).
	my @sums = (0) x @$data;
	for my $tree (@$trees) {
		for my $i ( 0 .. $#$data ) {
			$sums[$i] += _path_length( $data->[$i], $tree, 0, $nan );
		}
	}

	# Precompute the single normalising factor; exp() is a direct FPU
	# instruction and faster than Perl's general-purpose 2**x (pow).
	# Derivation: 2**(-avg/c) = 2**(-(sum/t)/c) = exp(-sum * log(2)/(c*t))
	if ( $c > 0 ) {
		my $inv = log(2) / ( $c * $t );
		return [ map { exp( -$_ * $inv ) } @sums ];
	}
	return [ (0.5) x @sums ];
} ## end sub score_samples

=head2 score_sample_tagged(\%row)

Scores a single sample supplied as a hashref of named feature values.
The model must have stored feature names (set via C<feature_names> in
C<new()> or the C<-t> CLI flag at fit time).

Returns a scalar anomaly score in (0, 1].

    my $score = $forest->score_sample_tagged({ cpu => 0.9, mem => 0.4 });

Croaks if the model has no stored feature names, if the hashref contains a
key that is not a known feature name, or if a feature name is absent from the
hashref.

=cut

sub score_sample_tagged {
	my ( $self, $row ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'score_sample_tagged' );
	my $result = $self->score_samples( [$vec] );
	return $result->[0];
}

=head2 explain_samples(\@data, %opts)

Explains, per sample, which features drove its anomaly score -- the
"why" to go with C<score_samples>' "how much".  Returns an arrayref
with one hashref per sample:

    my $explanations = $forest->explain_samples(\@data);

    for my $e (@$explanations) {
        my $top = $e->{features}[0];
        printf "score %.3f, mostly because of feature %s (weight %.2f)\n",
            $e->{score}, $top->{name} // $top->{index}, $top->{weight};
    }

Each hashref is

    {
        score    => 0.91,          # same value score_samples returns
        method   => 'ablation',    # which attribution method produced this
        features => [              # every feature, most responsible first
            { index => 1, name => 'bytes_log', weight => 0.62, value => 9.3,
              delta => 0.31, baseline => 4.1 },
            { index => 0, name => 'method',    weight => 0.21, value => 2.0,
              delta => 0.10, baseline => 1.0 },
            ...
        ],
    }

C<name> is taken from the model's stored C<feature_names> and is undef
when none were recorded.  C<weight> is each feature's normalised share
of the responsibility, in [0, 1] and summing to 1 (all weights are 0
in the degenerate case where no attribution information exists).
C<value> is the feature value the model actually scored.

Options:

  - method :: how per-feature responsibility is computed
        ablation :: (default) counterfactual substitution.  Each
            feature in turn is replaced by its baseline (the
            per-feature training-data median learned at fit time) and
            the sample is re-scored; the drop in anomaly score is that
            feature's C<delta>, and weights are the positive deltas
            normalised.  Features whose substitution does not
            de-anomalise the sample get 0.  Each feature entry
            additionally carries C<delta> (may be negative:
            substituting a correlated feature can make the sample MORE
            anomalous) and C<baseline> (the value swapped in).  Costs
            n_samples * (n_features + 1) rows through the ordinary
            scorer -- C-accelerated when available.
        path :: split attribution (local DIFFI; Carletti, Terzi &
            Susto -- see REFERENCES).  The sample walks every tree;
            each split node crossed credits its feature(s) with
            1/h_t - 1/h_max, where h_t is that tree's path length for
            the sample and h_max the longest across the forest -- so
            the trees that isolated the sample quickly speak loudest
            and trees that treated it as normal say nothing.  An
            oblique (extended-mode) split spreads its credit across
            its features in proportion to |coefficient * value|.
            Needs nothing stored beyond the trees (so it works on
            models saved before baseline support) and runs pure Perl
            over the tree walks.

Why ablation is the default: it directly answers "would this sample
still be an outlier with feature j at a normal value?", and that
question has an answer for ANY scored sample.  C<path> can only
apportion the splits the forest actually built, so it attributes well
for samples that were IN the training data (post-fit forensics of
flagged training rows) but degrades for unseen samples in the tails --
an out-of-range sample walks through boundary regions whose splits
mostly test OTHER features, and the attribution dilutes or even
misleads.  Prefer C<ablation> whenever the model has baselines;
C<path> is the fallback for old saved models and a second opinion on
training-set outliers.  Neither method untangles strongly correlated
features -- a sample anomalous only in the JOINT distribution of two
features may show weak attributions on both.

Under C<< voting => 'majority' >> the score (and ablation's deltas) are
in vote-fraction space, matching C<score_samples>' semantics in that
mode; the C<path> method is aggregation-independent and unchanged.

C<ablation> requires stored baselines: models fitted before explanation
support have none and croak (models with C<< missing => 'impute' >>
fall back to their stored fill vector); refitting stores them.

=cut

sub explain_samples {
	my ( $self, $data, %opts ) = @_;
	$self->_check_fitted;

	my $method = delete $opts{method} // 'ablation';
	croak "explain_samples: method must be 'path' or 'ablation'"
		unless $method =~ /\A(?:path|ablation)\z/;
	croak "explain_samples: unknown option(s): " . join( ', ', sort keys %opts )
		if %opts;

	my $rows = $self->_to_arrayref($data);
	croak "explain_samples() expects a non-empty arrayref of samples"
		unless @$rows;

	return $method eq 'ablation'
		? $self->_explain_ablation($rows)
		: $self->_explain_path($rows);
} ## end sub explain_samples

=head2 explain_sample_tagged(\%row, %opts)

Explains a single sample supplied as a hashref of named feature values
-- the tagged counterpart of
L<explain_samples|/explain_samples(\@data, %opts)>, taking the same
C<method> option and returning the single explanation hashref (with
C<name> filled from the stored feature names).

    my $e = $forest->explain_sample_tagged({ cpu => 0.9, mem => 0.4 });
    print "worst feature: $e->{features}[0]{name}\n";

Croaks under the same conditions as L<tagged_row_to_array|/tagged_row_to_array(\%row, $caller)>.

=cut

sub explain_sample_tagged {
	my ( $self, $row, %opts ) = @_;
	my $vec = $self->tagged_row_to_array( $row, 'explain_sample_tagged' );
	return $self->explain_samples( [$vec], %opts )->[0];
}

=head2 score_predict_samples

Returns an array ref of arrays. First value of each sub array is the score with the second being
0/1 for if it is a anomaly or not.

C<$threshold> defaults the same way as in C<predict>.

Under C<< voting => 'majority' >> the score is the anomaly vote fraction at
C<$threshold> (used as the per-tree cutoff) and the label is the majority
vote, matching C<score_samples>/C<predict> semantics in that mode.

    my $results = $forest->score_predict_samples(\@data, $threshold);

    print "x, y, score, result\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$results->[$int][0].', '.$results->[$int][1]."\n";

        $int++;
    }

=cut

sub score_predict_samples {
	my ( $self, $data, $threshold ) = @_;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;
	$self->_check_fitted;

	# Majority voting: [vote_fraction, majority_label] pairs.  Needs the
	# full vote counts (the fraction is part of the return shape), so no
	# early exit here -- that saving is predict()-only.
	if ( $self->{voting} eq 'majority' ) {
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $cut   = _depth_cut( $threshold, $self->{c_psi} );
		my $maj   = _min_votes($t);

		if ( $self->{_use_c} && $self->{_c_nodes} ) {
			my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
			my $votes_packed = "\0" x ( $n_pts * 8 );
			vote_all_xs( $self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
				$x_packed, $votes_packed, $n_pts, $nf, $t, $cut, 0, $self->{_use_openmp} );
			my $result = [];
			vote_score_predict_xs( $votes_packed, $n_pts, $t + 0.0, $maj + 0.0, $result );
			return $result;
		}

		my $votes = $self->_vote_counts_perl( $self->_prepare_perl_input($data), $cut );
		return [ map { [ $_ / $t, ( $_ >= $maj ? 1 : 0 ) ] } @$votes ] if _NV_IS_DOUBLE;

		# Wide-NV perls: match vote_score_predict_xs's double division --
		# see _NV_IS_DOUBLE.
		return [ map { [ _to_double( $_ / $t ), ( $_ >= $maj ? 1 : 0 ) ] } @$votes ];
	} ## end if ( $self->{voting} eq 'majority' )

	# Fast path: build [score, label] pairs straight from the sum buffer
	# in one C call.  Avoids the intermediate scores arrayref + Perl
	# foreach that allocates ~3*n_pts SVs.  Gated identically to predict()
	# so the threshold conversion is valid.
	if (   $self->{_use_c}
		&& $self->{_c_nodes}
		&& $self->{c_psi} > 0
		&& $threshold > 0
		&& $threshold < 1 )
	{
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $c     = $self->{c_psi};
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs(
			$self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,         $sums_packed,         $n_pts,
			$nf,               $t,                   $self->{_use_openmp}
		);
		my $inv           = log(2) / ( $c * $t );
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $result        = [];
		score_predict_xs( $sums_packed, $n_pts, $inv, $sum_threshold, $result );
		return $result;
	} ## end if ( $self->{_use_c} && $self->{_c_nodes} ...)

	# Fallback: edge thresholds, c==0, or no C backend.
	my $scores = $self->score_samples( $self->_to_arrayref($data) );

	my @to_return;
	foreach my $score ( @{$scores} ) {
		if ( $score >= $threshold ) {
			push @to_return, [ $score, 1 ];
		} else {
			push @to_return, [ $score, 0 ];
		}
	}

	return \@to_return;
} ## end sub score_predict_samples

=head2 score_predict_sample_tagged(\%row, $threshold)

Scores and classifies a single sample supplied as a hashref of named
feature values.  The model must have stored feature names.

C<$threshold> defaults the same way as in C<predict>.

Returns a two-element arrayref C<[$score, $label]>, matching the per-row
shape that C<score_predict_samples> returns for each row.

    my $pair = $forest->score_predict_sample_tagged({ cpu => 0.9, mem => 0.4 });
    printf "score %.4f  anomaly %d\n", $pair->[0], $pair->[1];

Croaks if the model has no stored feature names, if the hashref contains a
key that is not a known feature name, or if a feature name is absent from the
hashref.

=cut

sub score_predict_sample_tagged {
	my ( $self, $row, $threshold ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'score_predict_sample_tagged' );
	my $result = $self->score_predict_samples( [$vec], $threshold );
	return $result->[0];
}

=head2 score_predict_split(\@data, $threshold)

Same data as L</score_predict_samples> but returned as two flat arrayrefs
instead of an arrayref-of-pairs.  Allocates roughly half as many Perl
SVs per point (no inner AV, no RV per row), so it is meaningfully faster
when both scores and labels are wanted but the paired shape is not.

In list context returns C<($scores_aref, $labels_aref)>.

    my ($scores, $labels) = $forest->score_predict_split(\@data);

    for my $i (0 .. $#$scores) {
        printf "%s -> score %.4f, label %d\n",
            join(',', @{ $data[$i] }), $scores->[$i], $labels->[$i];
    }

C<$threshold> defaults to the contamination-learned cutoff (if C<fit>
was called with C<contamination>) or 0.5.

=cut

sub score_predict_split {
	my ( $self, $data, $threshold ) = @_;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;
	$self->_check_fitted;

	# Majority voting: same values as the majority branch in
	# score_predict_samples, returned as two flat arrayrefs.
	if ( $self->{voting} eq 'majority' ) {
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $cut   = _depth_cut( $threshold, $self->{c_psi} );
		my $maj   = _min_votes($t);

		if ( $self->{_use_c} && $self->{_c_nodes} ) {
			my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
			my $votes_packed = "\0" x ( $n_pts * 8 );
			vote_all_xs( $self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
				$x_packed, $votes_packed, $n_pts, $nf, $t, $cut, 0, $self->{_use_openmp} );
			my $scores = [];
			my $labels = [];
			vote_score_predict_split_xs( $votes_packed, $n_pts, $t + 0.0, $maj + 0.0, $scores, $labels );
			return ( $scores, $labels );
		} ## end if ( $self->{_use_c} && $self->{_c_nodes} )

		my $votes  = $self->_vote_counts_perl( $self->_prepare_perl_input($data), $cut );
		my @scores = _NV_IS_DOUBLE
			? map { $_ / $t }
			@$votes
			# Wide-NV perls: match vote_score_predict_split_xs's double
			# division -- see _NV_IS_DOUBLE.
			: map { _to_double( $_ / $t ) } @$votes;
		my @labels = map { $_ >= $maj ? 1 : 0 } @$votes;
		return ( \@scores, \@labels );
	} ## end if ( $self->{voting} eq 'majority' )

	# Fast path: fill two flat arrayrefs (scores + labels) directly from
	# the sum buffer in one C call.  Skips the inner AV + RV per point
	# that score_predict_samples has to allocate.
	if (   $self->{_use_c}
		&& $self->{_c_nodes}
		&& $self->{c_psi} > 0
		&& $threshold > 0
		&& $threshold < 1 )
	{
		my $trees = $self->{trees};
		my $t     = scalar @$trees;
		my $c     = $self->{c_psi};
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs(
			$self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,         $sums_packed,         $n_pts,
			$nf,               $t,                   $self->{_use_openmp}
		);
		my $inv           = log(2) / ( $c * $t );
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $scores        = [];
		my $labels        = [];
		score_predict_split_xs( $sums_packed, $n_pts, $inv, $sum_threshold, $scores, $labels );
		return ( $scores, $labels );
	} ## end if ( $self->{_use_c} && $self->{_c_nodes} ...)

	# Fallback: derive from score_samples.
	my $scores = $self->score_samples( $self->_to_arrayref($data) );
	my @labels = map { $_ >= $threshold ? 1 : 0 } @$scores;
	return ( $scores, \@labels );
} ## end sub score_predict_split

=head1 MUNGERS

With the optional L<Algorithm::ToNumberMunger> module, a model can carry
a declarative munger spec (see C<mungers> under L</new(%args)>) that
turns raw tagged values -- strings, timestamps, status codes, IPs --
into the numbers the forest needs, so callers hand the model the data
they actually have:

    my $forest = Algorithm::Classifier::IsolationForest->new(
        feature_names => [ 'method', 'bytes_log', 'host_entropy' ],
        mungers       => {
            method       => { munger => 'http_method_enum', default => -1 },
            bytes_log    => { munger => 'log', offset => 1, from => 'bytes' },
            host_entropy => { munger => 'entropy', from => 'host' },
        },
    );
    $forest->fit_tagged(\@raw_rows);
    my $score = $forest->score_sample_tagged(
        { method => 'POST', bytes => 51234, host => 'kq3xv9z2.example' } );

The spec is pure data and is B<saved with the model>, so a loaded model
munges scoring input exactly as it did training input -- the
consistency that makes munging part of the model rather than an
upstream preprocessing step.  Points worth knowing:

=over 4

=item * Only tagged input is munged.  Positional rows passed to C<fit>
or the scoring methods are taken as already numeric; L<munge_rows|/munge_rows(\@rows)>
applies the scalar mungers to positional rows for callers (like the
CLI) that want the same transformation there.  Packed datasets
(L</pack_data(\@data)>) are never munged.

=item * Under a munger plan, tagged-row validation is the plan's: a
missing input field croaks (including munger C<from> sources, which
need not be tags), while unknown extra keys are ignored rather than
rejected.

=item * Loading a model that carries mungers does not require
Algorithm::ToNumberMunger -- inspection and positional scoring work
without it; the first tagged call croaks with an install hint.  A
munger name unknown to an older installed Algorithm::ToNumberMunger
croaks naming it; the model records C<munger_module_version> (the
version that authored the spec) to make that diagnosable.

=item * Munging happens before the C<missing> strategy: for munged
columns the strategy sees the munger's output, and most mungers define
their own undef handling (C<length> counts undef as 0, C<enum> takes a
C<default>, ...).  Raw columns behave exactly as without mungers.

=item * Caveats inherited from the munger set: the C<eps> munger talks
to an external service, so a saved model using it needs that service
reachable wherever the model runs; C<frozen_freq_map>/C<ngram> count
tables are part of the spec and therefore of the model file.

=back

The munger spec composes with everything else -- modes, voting,
contamination, the C backend (munging is input-side; accelerated paths
are unchanged) -- and works identically on
L<Algorithm::Classifier::IsolationForest::Online>.

=head1 MODEL SAVE/LOAD METHODS

=head2 to_json

Returns a JSON representation of the model.

Requires fit to have been called.

    my $json = $iforest->to_json;

=cut

sub to_json {
	my ($self) = @_;
	$self->_check_fitted;
	my $payload = {
		format  => 'Algorithm::Classifier::IsolationForest',
		version => 1,
		params  => {
			n_trees               => $self->{n_trees},
			sample_size           => $self->{sample_size},
			mode                  => $self->{mode},
			extension_level       => $self->{extension_level_used},
			contamination         => $self->{contamination},
			threshold             => $self->{threshold},
			n_features            => $self->{n_features},
			psi_used              => $self->{psi_used},
			c_psi                 => $self->{c_psi},
			max_depth_used        => $self->{max_depth_used},
			missing               => $self->{missing},
			impute_with           => $self->{impute_with},
			missing_fill          => $self->{missing_fill},
			feature_baselines     => $self->{feature_baselines},
			feature_names         => $self->{feature_names},
			voting                => $self->{voting},
			mungers               => $self->{mungers},
			munger_module_version => $self->{munger_module_version},
			schema_version        => $self->{schema_version},
			schema_description    => $self->{schema_description},
			feature_descriptions  => $self->{feature_descriptions},
		},
		trees => $self->{trees},
	};
	return JSON::PP->new->canonical(1)->encode($payload);
} ## end sub to_json

=head2 from_json($json)

Init the object from the model in the specified JSON string.

    my $iforest = Algorithm::Classifier::IsolationForest->from_json($json);

=cut

sub from_json {
	my ( $class, $text ) = @_;
	my $payload = JSON::PP->new->decode($text);
	croak "not an IsolationForest model"
		unless ref $payload eq 'HASH'
		&& defined $payload->{format};

	# Online models carry their own format tag; hand them to the class
	# that knows their shape so callers can load either model type
	# through this one entry point.
	if ( $payload->{format} eq 'Algorithm::Classifier::IsolationForest::Online' ) {
		require Algorithm::Classifier::IsolationForest::Online;
		return Algorithm::Classifier::IsolationForest::Online->from_json($text);
	}

	croak "not an IsolationForest model"
		unless $payload->{format} eq 'Algorithm::Classifier::IsolationForest';

	my $p = $payload->{params} || {};

	# version 0 used hash-based nodes; version 1+ uses array-based nodes.
	# Convert old models on load so the rest of the code only sees arrays.
	my $trees = $payload->{trees} || [];
	if ( ( $payload->{version} // 0 ) < 1 ) {
		$trees = [ map { _hash_node_to_array($_) } @$trees ];
	}

	my $self = {
		n_trees              => $p->{n_trees},
		sample_size          => $p->{sample_size},
		max_depth            => undef,
		seed                 => undef,
		mode                 => $p->{mode} // 'axis',
		extension_level      => $p->{extension_level},
		extension_level_used => $p->{extension_level},
		contamination        => $p->{contamination},
		threshold            => $p->{threshold},
		n_features           => $p->{n_features},
		psi_used             => $p->{psi_used},
		c_psi                => $p->{c_psi},
		max_depth_used       => $p->{max_depth_used},
		# Models saved before missing-value support lack these keys; default
		# to 'zero', which reproduces the old undef -> 0 scoring behaviour.
		missing      => $p->{missing}     // 'zero',
		impute_with  => $p->{impute_with} // 'mean',
		missing_fill => $p->{missing_fill},
		# Absent in models saved before explanation support; ablation
		# explanations then fall back to missing_fill or croak with a
		# refit hint -- see _ablation_baselines.
		feature_baselines => $p->{feature_baselines},
		feature_names     => $p->{feature_names},
		# The munger plan is recompiled lazily on first tagged use, so a
		# munger-bearing model still loads (and scores positional data)
		# where Algorithm::ToNumberMunger is not installed.
		mungers               => $p->{mungers},
		munger_module_version => $p->{munger_module_version},
		# Opaque schema metadata; absent in models saved before prototype
		# support, which just means "none recorded".
		schema_version       => $p->{schema_version},
		schema_description   => $p->{schema_description},
		feature_descriptions => $p->{feature_descriptions},
		# Models saved before majority-voting support lack the key; 'mean'
		# reproduces their behaviour exactly.
		voting          => $p->{voting} // 'mean',
		trees           => $trees,
		_use_c          => $HAS_C,
		_use_openmp     => $HAS_OPENMP,
		_use_openmp_fit => 0,                        # opt-in only; loaded models never re-fit implicitly
	};
	croak "model contains no trees" unless @{ $self->{trees} };

	# Recompute the normalising constant from the (integer, exact) sub-sample
	# size rather than trusting the stored float, so a reloaded model's scores
	# are bit-for-bit identical to the original's.
	$self->{c_psi} = _c( $self->{psi_used} ) if defined $self->{psi_used};

	my $model = bless $self, $class;
	$model->_rebuild_c_trees() if $self->{_use_c};
	return $model;
} ## end sub from_json

=head2 save($path)

Saves the model to the specified path.

    $iforest->save($path);

=cut

sub save {
	my ( $self, $path ) = @_;
	write_file( $path, { 'atomic' => 1 }, $self->to_json );
}

=head2 load($path)

Init the object from the model in the specified file.

    my $iforest = Algorithm::Classifier::IsolationForest->load($path);

=cut

sub load {
	my ( $class, $path ) = @_;
	my $raw_model = read_file($path);
	return $class->from_json($raw_model);
}

=head1 PROTOTYPES

A prototype is a small JSON document that describes what a model should
be before any data exists: the variable schema (feature names in column
order, plus their munger specs, per-feature descriptions, and missing
policy), a user-owned C<schema_version> string, a human-readable
C<schema_description>, and optionally the tuning knobs.  Creating a
model from one -- L</new_from_prototype($proto, %overrides)> here, or
C<--prototype> on C<iforest fit> / C<iforest stream> -- stamps the
schema metadata into the model JSON, so every downstream consumer
(C<iforest info>, resumed streams, your own tooling) can tell which
revision of the input schema a model was built against.

    {
      "format": "Algorithm::Classifier::IsolationForest::Prototype",
      "version": 1,
      "class": "online",
      "schema_version": "2026.07.08-1",
      "schema_description": "HTTP request stream: method enum, path length, host entropy, raw byte count",
      "schema": {
        "feature_names": ["method", "path_len", "host_entropy", "bytes"],
        "feature_descriptions": {
          "method":       "HTTP request method, mapped via http_method_enum (-1 = unknown)",
          "path_len":     "character length of the request path",
          "host_entropy": "Shannon entropy of the Host header",
          "bytes":        "raw response byte count, passed through unmunged"
        },
        "mungers": {
          "method":       { "munger": "http_method_enum", "default": -1 },
          "path_len":     { "munger": "length",  "from": "path" },
          "host_entropy": { "munger": "entropy", "from": "host" }
        },
        "missing": "zero"
      },
      "params": {
        "n_trees": 150,
        "window_size": 4096,
        "max_leaf_samples": 32,
        "contamination": 0.02
      }
    }

The fields, top to bottom...

  - format :: required, always the string
        'Algorithm::Classifier::IsolationForest::Prototype'.  A prototype
        handed to load() (or a model handed to the prototype methods)
        dies with a clear message instead of half-working.

  - version :: the prototype format version; this release reads version 1.
      default :: 1

  - class :: required, 'batch' (this class) or 'online'
        (L<Algorithm::Classifier::IsolationForest::Online>).  Prototypes
        are self-describing; `iforest fit` refuses an online prototype
        and `iforest stream` refuses a batch one.  Two model types with
        the same variables means two prototype files.

  - schema_version :: required opaque string, never parsed or compared
        numerically.  User-owned: bump it when the variable schema
        changes.

  - schema_description :: required opaque free-text string describing
        what this variable schema is, so a model file explains itself
        months later.

  - schema :: required object holding the variable schema.
        feature_names is required (order = CSV column order); the
        optional keys are feature_descriptions ('feature name => free
        text', every key must name an entry in feature_names, partial
        coverage fine), mungers (see L</MUNGERS>), missing, and -- batch
        prototypes only -- impute_with.  Unknown keys croak.

  - params :: optional object of tuning knobs, whitelisted per class.
        Batch: n_trees, sample_size, max_depth, mode, extension_level,
        contamination, voting, seed.  Online: n_trees, window_size,
        max_leaf_samples, growth, subsample, contamination, seed.
        Unknown keys croak -- a typo'd knob silently falling back to its
        default is exactly the failure mode a prototype exists to
        prevent.  Machine-local knobs (use_c, use_openmp, use_openmp_fit,
        parallel_fit) are rejected: they describe the box the model runs
        on, not the model.

=cut

# Per-class whitelists for a prototype's params block (and
# new_from_prototype's %overrides) and its schema block.  Machine-local
# knobs are deliberately absent from the params lists.
my %PROTO_PARAM_KEYS = (
	batch  => { map { $_ => 1 } qw(n_trees sample_size max_depth mode extension_level contamination voting seed) },
	online => { map { $_ => 1 } qw(n_trees window_size max_leaf_samples growth subsample contamination seed) },
);
my %PROTO_SCHEMA_KEYS = (
	batch  => { map { $_ => 1 } qw(feature_names feature_descriptions mungers missing impute_with) },
	online => { map { $_ => 1 } qw(feature_names feature_descriptions mungers missing) },
);

=head2 validate_prototype($proto)

Structurally validates a prototype -- a hashref or a JSON string -- and
returns the decoded hashref; croaks describing the first problem found.
Validation is structural only (no munger compilation), so it does not
require Algorithm::ToNumberMunger even for a munger-bearing prototype.

    my $proto = Algorithm::Classifier::IsolationForest->validate_prototype($json);

=cut

sub validate_prototype {
	my ( $class, $proto ) = @_;

	if ( !ref $proto ) {
		my $decoded = eval { JSON::PP->new->decode($proto) };
		croak "prototype did not parse as JSON: $@" if $@;
		$proto = $decoded;
	}
	croak "not an IsolationForest prototype (expected a JSON object)"
		unless ref $proto eq 'HASH';
	croak "not an IsolationForest prototype (format is not " . "'Algorithm::Classifier::IsolationForest::Prototype')"
		unless defined $proto->{format}
		&& !ref $proto->{format}
		&& $proto->{format} eq 'Algorithm::Classifier::IsolationForest::Prototype';

	my $version = $proto->{version} // 1;
	croak "prototype format version '$version' is newer than this module understands (max 1)"
		if !ref $version && $version =~ /^\d+$/ && $version > 1;

	for my $k ( sort keys %$proto ) {
		croak "prototype has unknown top-level key '$k'"
			unless $k =~ /\A(?:format|version|class|schema_version|schema_description|schema|params)\z/;
	}

	my $which = $proto->{class};
	croak "prototype needs a class of 'batch' or 'online'"
		unless defined $which && !ref $which && $which =~ /\A(?:batch|online)\z/;

	for my $req (qw(schema_version schema_description)) {
		croak "prototype needs a non-empty $req string"
			unless defined $proto->{$req} && !ref $proto->{$req} && length $proto->{$req};
	}

	my $schema = $proto->{schema};
	croak "prototype needs a schema object" unless ref $schema eq 'HASH';
	for my $k ( sort keys %$schema ) {
		croak "prototype schema has unknown key '$k' for a $which prototype (allowed: "
			. join( ', ', sort keys %{ $PROTO_SCHEMA_KEYS{$which} } ) . ')'
			unless $PROTO_SCHEMA_KEYS{$which}{$k};
	}
	my $tags = $schema->{feature_names};
	croak "prototype schema needs a non-empty feature_names array"
		unless ref $tags eq 'ARRAY' && @$tags;
	for my $t (@$tags) {
		croak "prototype feature_names entries must be non-empty strings"
			unless defined $t && !ref $t && length $t;
	}
	_validate_feature_descriptions( $tags, $schema->{feature_descriptions} )
		if defined $schema->{feature_descriptions};
	croak "prototype schema mungers must be an object of 'tag => munger spec'"
		if defined $schema->{mungers} && ref $schema->{mungers} ne 'HASH';
	for my $str (qw(missing impute_with)) {
		croak "prototype schema $str must be a plain string"
			if defined $schema->{$str} && ref $schema->{$str};
	}

	my $params = $proto->{params};
	croak "prototype params must be an object of tuning knobs"
		if defined $params && ref $params ne 'HASH';
	for my $k ( sort keys %{ $params || {} } ) {
		croak "prototype params has unknown key '$k' for a $which prototype (allowed: "
			. join( ', ', sort keys %{ $PROTO_PARAM_KEYS{$which} } )
			. '; machine-local knobs like use_c are deliberately not allowed)'
			unless $PROTO_PARAM_KEYS{$which}{$k};
	}

	return $proto;
} ## end sub validate_prototype

=head2 new_from_prototype($proto, %overrides)

Creates a fresh, unfitted model from a prototype (a hashref or a JSON
string) and returns it -- an instance of whichever class the prototype's
C<class> field names, so like C<load()> this is a single entry point for
both model types.  Croaks on any validation failure; a munger-bearing
prototype compiles its plan here, so a bogus munger spec dies at
creation (and needs Algorithm::ToNumberMunger installed).

C<%overrides> merge over the prototype's C<params> block -- per-run
knobs like C<seed> -- and are held to the same per-class whitelist.
Overriding the schema itself (feature_names, feature_descriptions,
mungers, missing, impute_with, schema_version, schema_description)
croaks: the schema is the prototype's, full stop; edit the prototype.

    my $oif = Algorithm::Classifier::IsolationForest->new_from_prototype(
        $proto_json,
        seed => 42,
    );

=cut

sub new_from_prototype {
	my ( $class, $proto, %overrides ) = @_;

	$proto = $class->validate_prototype($proto);
	my $which  = $proto->{class};
	my $schema = $proto->{schema};

	for my $k ( sort keys %overrides ) {
		croak "new_from_prototype: '$k' is part of the prototype's schema and may not "
			. "be overridden; edit the prototype instead"
			if $k
			=~ /\A(?:feature_names|feature_descriptions|mungers|missing|impute_with|schema_version|schema_description)\z/;
		croak "new_from_prototype: unknown override '$k' for a $which prototype (allowed: "
			. join( ', ', sort keys %{ $PROTO_PARAM_KEYS{$which} } ) . ')'
			unless $PROTO_PARAM_KEYS{$which}{$k};
	}

	my %args = (
		%{ $proto->{params} || {} },
		%overrides,
		feature_names      => $schema->{feature_names},
		schema_version     => $proto->{schema_version},
		schema_description => $proto->{schema_description},
	);
	for my $k (qw(feature_descriptions mungers missing impute_with)) {
		$args{$k} = $schema->{$k} if defined $schema->{$k};
	}

	if ( $which eq 'online' ) {
		require Algorithm::Classifier::IsolationForest::Online;
		return Algorithm::Classifier::IsolationForest::Online->new(%args);
	}
	return Algorithm::Classifier::IsolationForest->new(%args);
} ## end sub new_from_prototype

=head2 load_prototype($path, %overrides)

L</new_from_prototype($proto, %overrides)> from a file.

    my $iforest = Algorithm::Classifier::IsolationForest->load_prototype(
        'proto.json', seed => 42 );

=cut

sub load_prototype {
	my ( $class, $path, %overrides ) = @_;
	my $raw = read_file($path);
	return $class->new_from_prototype( $raw, %overrides );
}

=head2 to_prototype

Returns a prototype JSON string extracted from this model: its variable
schema (feature_names, feature_descriptions, mungers, missing policy)
plus its current tuning knobs.  This closes the loop -- extract a
prototype from a good model and periodically create fresh models with an
identical schema, the natural retrain workflow -- and means hand-writing
a prototype is never mandatory.

Croaks when the model has no C<feature_names>: a prototype's variable
schema needs named variables.  A model with no recorded
C<schema_version> / C<schema_description> (fitted before prototype
support, or without the knobs) gets placeholder values, since both are
required in the file -- edit them in and bump from there.  C<seed> and
C<max_depth> resolved at fit time are not emitted; pass such per-run
knobs as overrides when creating from the prototype.

    my $proto_json = $iforest->to_prototype;

=cut

sub to_prototype {
	my ($self) = @_;
	croak "to_prototype: this model has no feature_names; a prototype's variable " . "schema needs named features"
		unless ref $self->{feature_names} eq 'ARRAY' && @{ $self->{feature_names} };

	my $schema = {
		feature_names => $self->{feature_names},
		missing       => $self->{missing},
	};
	$schema->{feature_descriptions} = $self->{feature_descriptions}
		if ref $self->{feature_descriptions} eq 'HASH' && %{ $self->{feature_descriptions} };
	$schema->{mungers} = $self->{mungers}
		if ref $self->{mungers} eq 'HASH' && %{ $self->{mungers} };
	$schema->{impute_with} = $self->{impute_with}
		if defined $self->{missing} && $self->{missing} eq 'impute';

	my $params = {
		n_trees     => $self->{n_trees},
		sample_size => $self->{sample_size},
		mode        => $self->{mode},
		voting      => $self->{voting},
	};
	$params->{max_depth}       = $self->{max_depth} if defined $self->{max_depth};
	$params->{extension_level} = $self->{extension_level_used} // $self->{extension_level}
		if defined( $self->{extension_level_used} // $self->{extension_level} );
	$params->{contamination} = $self->{contamination} if defined $self->{contamination};

	return JSON::PP->new->canonical(1)->encode(
		{
			format             => 'Algorithm::Classifier::IsolationForest::Prototype',
			version            => 1,
			class              => 'batch',
			schema_version     => $self->{schema_version} // '0',
			schema_description => $self->{schema_description}
				// '(none recorded; describe this schema and bump schema_version)',
			schema => $schema,
			params => $params,
		}
	);
} ## end sub to_prototype

=head1 REFERENCES

Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

L<https://ieeexplore.ieee.org/abstract/document/4781136>

Sahand Hariri, Matias Carrasco Kind, Robert J. Brunner (2020). Extended Isolation Forest. 1479 - 1489. 10.1109/TKDE.2019.2947676

L<https://ieeexplore.ieee.org/document/8888179>

Yousra Chabchoub, Maurras Ulbricht Togbe, Aliou Boly, Raja Chiky (2022). An In-Depth Study and Improvement of Isolation Forest. IEEE Access, vol. 10, 10219 - 10237. 10.1109/ACCESS.2022.3144425 (the Majority Voting Isolation Forest implemented by C<< voting => 'majority' >>)

L<https://ieeexplore.ieee.org/document/9684896>

Mattia Carletti, Matteo Terzi, Gian Antonio Susto (2023). Interpretable Anomaly Detection with DIFFI: Depth-based feature importance of Isolation Forest. Engineering Applications of Artificial Intelligence, vol. 119. 10.1016/j.engappai.2022.105730 (the depth-weighted split attribution of C<explain_samples>' C<path> method is inspired by local DIFFI)

L<https://arxiv.org/abs/2007.11117>

L<https://www.sciencedirect.com/science/article/pii/S0952197622007205>

Filippo Leveni, Guilherme Weigert Cassales, Bernhard Pfahringer, Albert Bifet, Giacomo Boracchi (2024). Online Isolation Forest. (the streaming variant implemented by L<Algorithm::Classifier::IsolationForest::Online>)

L<https://arxiv.org/abs/2505.09593>

L<https://github.com/ineveLoppiliF/Online-Isolation-Forest>

L<https://proceedings.mlr.press/v235/leveni24a.html>

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
General Public License for more details.

=cut

###
###
### internal stuff below
###
###

#-------------------------------------------------------------------------------
# c(n): the expected path length of an unsuccessful search in a binary search
# tree of n nodes. Isolation Forest uses it (a) to adjust the path length when a
# leaf still holds more than one point (depth limit reached), and (b) to
# normalise the average path length into a 0..1 anomaly score.
#
# Args:
#   $n :: a point count, non-negative integer.  Either a leaf's size or the
#         per-tree sub-sample size psi.
#
# Returns: the expected path length, a float.  0.0 for n <= 1 (nothing is
# left to search) and 1.0 for n == 2, both special-cased because the
# harmonic approximation is only accurate for larger n.
#
# Example:
#   _c(1);     # 0.0
#   _c(256);   # ~10.24 -- the normaliser for a default sample_size fit
#-------------------------------------------------------------------------------
sub _c {
	my ($n) = @_;
	return 0.0 if $n <= 1;
	return 1.0 if $n == 2;
	my $harmonic = log( $n - 1 ) + EULER;    # H(n-1) ~= ln(n-1) + gamma
	return 2.0 * $harmonic - ( 2.0 * ( $n - 1 ) / $n );
}

#-------------------------------------------------------------------------------
# Majority-voting (voting => 'majority') helpers.  MVIForest -- Chabchoub,
# Togbe, Boly & Chiky 2022 (see REFERENCES) -- has each tree vote a point
# anomalous when the tree's own score 2**(-h/c(psi)) clears the decision
# threshold, and takes the majority of the votes as the label.  Trees are
# untouched; only these scoring-time aggregation helpers differ from the
# classic mean-path-length pipeline.
#-------------------------------------------------------------------------------

# Depth-domain image of the per-tree score cutoff: a tree votes a point
# anomalous when 2**(-h/c) >= theta, i.e. h <= -c * log2(theta).  Doing the
# log once here keeps exp/log out of the per-point per-tree loops (both C
# and Perl compare raw path lengths against this cut).  Degenerate inputs
# pin the cut so `h <= cut` still behaves: theta <= 0 is cleared by every
# per-tree score (all in (0, 1]), so +inf lets every tree vote; c <= 0 only
# happens for psi <= 1 forests, whose score convention is a flat 0.5 (see
# score_samples), so all trees vote iff theta is at or below that pivot.
#
# Args:
#   $theta :: the per-tree score cutoff, normally in (0, 1].  Degenerate
#             values are handled rather than rejected.
#   $c :: c(psi) for this forest, i.e. $self->{c_psi}.  Only <= 0 for a
#         psi <= 1 forest.
#
# Returns: the path length at or below which a tree votes anomalous, a
# float.  +inf when every tree should vote, -1.0 when none should.
#
# Example:
#   _depth_cut( 0.6, 10.24 );   # ~7.55: isolate in <= 7.55 edges and vote
sub _depth_cut {
	my ( $theta, $c ) = @_;
	return ( $theta <= 0.5 ? 9**9**9 : -1.0 ) if $c <= 0;
	return 9**9**9                            if $theta <= 0;
	return -$c * log($theta) / log(2);
}

# Smallest number of per-tree anomaly votes that constitutes a majority:
# int(t/2) + 1, i.e. strictly more than half the trees for both odd and
# even tree counts (the paper's "t/2 + 1").
#
# Args:
#   $n_trees :: the forest's tree count, an integer >= 1.
#
# Returns: the required vote count, an integer in [1, $n_trees].
#
# Example:
#   _min_votes(100);   # 51
#   _min_votes(101);   # 51
sub _min_votes { return int( $_[0] / 2 ) + 1 }

#-------------------------------------------------------------------------------
# Contamination threshold selection: given the training scores ranked
# descending and the target flag count k, return a cutoff sitting midway
# inside the gap between the last flagged and the first unflagged score.
#
# Tied scores at the k-boundary make an exact count of k unattainable (the
# tie block can only go one way or the other) AND make the naive midpoint
# degenerate -- it equals the tied value, leaving predict()'s >= comparison
# balanced on exact float equality.  Mean-mode scores are continuous enough
# that this practically never happens, but majority-mode pivots are
# structurally quantized (path lengths at the depth cap take few distinct
# values -- see _majority_pivot_scores), so ties there are the norm, and
# the score <-> depth-cut conversion adds an exp/log round trip that needs
# real slack around the cutoff rather than exact-equality behaviour.  The
# whole tie block therefore goes to whichever side lands the flag count
# closest to k, preferring the flagging side on a dead heat.
#
# Args:
#   $desc :: arrayref of the per-point statistic sorted DESCENDING -- the
#            mean-mode anomaly scores, or the majority pivots under
#            voting => 'majority'.  Must be non-empty.
#   $k :: how many points the contamination rate wants flagged, an integer
#         in [1, scalar @$desc].
#
# Returns: the cutoff, a float positioned so that `statistic >= cutoff`
# selects the intended points.  Never equal to a value in $desc.
#
# Example:
#   _threshold_from_ranked( [ 0.71, 0.68, 0.52, 0.50 ], 2 );   # 0.60
#   _threshold_from_ranked( [ 0.71, 0.68, 0.68, 0.50 ], 2 );   # 0.59, tie
#-------------------------------------------------------------------------------
sub _threshold_from_ranked {
	my ( $desc, $k ) = @_;
	my $n = scalar @$desc;
	return $desc->[ $n - 1 ] - 1e-9 if $k >= $n;    # flag everything

	my $v = $desc->[ $k - 1 ];
	return ( $v + $desc->[$k] ) / 2.0 if $desc->[$k] < $v;    # clean gap at k

	# Tie block straddling the k-boundary: locate its edges.
	my $i = $k - 1;
	$i-- while $i > 0 && $desc->[ $i - 1 ] == $v;             # first index holding $v
	my $j = $k;
	$j++ while $j < $n && $desc->[$j] == $v;                  # first index below $v

	if ( $i > 0 && ( $k - $i ) < ( $j - $k ) ) {

		# Excluding the block lands closer to k: flag the $i points above it.
		return ( $desc->[ $i - 1 ] + $v ) / 2.0;
	}
	return $j < $n
		? ( $v + $desc->[$j] ) / 2.0                          # include the block: flag $j
		: $desc->[ $n - 1 ] - 1e-9;                           # block runs to the end
} ## end sub _threshold_from_ranked

# Pure-Perl vote counter: votes[i] = how many trees give point i a path
# length at or under the depth cut.  Tree-outer / sample-inner for cache
# locality, mirroring the mean-mode fallback loops.  $data must already
# be through _prepare_perl_input.
#
# Args:
#   $data :: arrayref of rows already through _prepare_perl_input -- dense
#            under impute, raw undef preserved under nan.
#   $cut :: the depth cut from _depth_cut.
#
# Returns: arrayref of per-point vote counts, integers in [0, n_trees],
# positionally matching $data.
#
# Example:
#   my $cut   = _depth_cut( 0.6, $self->{c_psi} );
#   my $votes = $self->_vote_counts_perl( $rows, $cut );   # [ 3, 97, 12, ... ]
sub _vote_counts_perl {
	my ( $self, $data, $cut ) = @_;
	my $trees = $self->{trees};
	my $nan   = $self->{missing} eq 'nan' ? 1 : 0;
	my @votes = (0) x @$data;
	for my $tree (@$trees) {
		for my $i ( 0 .. $#$data ) {
			$votes[$i]++ if _path_length( $data->[$i], $tree, 0, $nan ) <= $cut;
		}
	}
	return \@votes;
} ## end sub _vote_counts_perl

# Learn the contamination cutoff for the CURRENT voting mode from a training
# set.  Ranks the per-point quantity the active aggregation thresholds against
# -- the mean-mode anomaly score, or the majority pivot under
# voting => 'majority' -- and lands the cutoff midway inside a real gap between
# flagged and unflagged values (ties at the k-boundary shift it to the nearest
# gap; see _threshold_from_ranked), so it sits strictly between attainable
# values: unambiguous and robust to the float rounding JSON introduces.  A
# point is flagged iff its statistic >= threshold in either mode, so the
# midpoint selection serves both unchanged.  Shared by fit() (which passes the
# prepared training set after dropping any stale packed buffers) and
# set_voting() (which passes the caller-supplied training set against the
# live, fully packed forest); $data may hold raw undef cells either way, since
# the scorers below densify from missing_fill.
#
# Args:
#   $data :: the training set, an arrayref of feature-value arrayrefs.  Raw
#            undef cells are fine.
#
# Returns: nothing.  Sets $self->{threshold} as its whole purpose.
#
# Example:
#   $self->{contamination} = 0.05;
#   $self->_learn_contamination_threshold( \@training_rows );
#   $self->decision_threshold;   # the cutoff flagging ~5% of the training set
sub _learn_contamination_threshold {
	my ( $self, $data ) = @_;
	my $scores
		= $self->{voting} eq 'majority'
		? $self->_majority_pivot_scores($data)
		: $self->score_samples($data);
	my @desc  = sort { $b <=> $a } @$scores;
	my $n_pts = scalar @desc;
	my $k     = int( $self->{contamination} * $n_pts + 0.5 );
	$k                 = 1      if $k < 1;
	$k                 = $n_pts if $k > $n_pts;
	$self->{threshold} = _threshold_from_ranked( \@desc, $k );
	return;
} ## end sub _learn_contamination_threshold

#-------------------------------------------------------------------------------
# Contamination support for majority voting: each training point's majority
# pivot -- the per-tree score threshold at which the point loses its
# majority.  A point is flagged at cutoff theta iff at least min_votes of
# its per-tree path lengths h satisfy h <= -c*log2(theta), which holds iff
# its min_votes-th SMALLEST path length h_(maj) does, i.e. iff
# 2**(-h_(maj)/c) >= theta.  So the pivot m = 2**(-h_(maj)/c) relates to
# the majority-mode threshold exactly as the mean-mode score relates to
# its threshold, and fit()'s midpoint selection works on either unchanged.
#
# Pure Perl by necessity: the per-tree path lengths never cross the C
# boundary individually (score_all_xs/vote_all_xs only return per-point
# aggregates), and fit() has already dropped any stale packed buffers when
# this runs -- the same situation as mean mode's training-set scoring pass.
#
# Args:
#   $data :: arrayref of feature-value arrayrefs, raw or prepared -- it goes
#            through _prepare_perl_input here either way.
#
# Returns: arrayref of per-point pivots, each a float in (0, 1],
# positionally matching $data.
#
# Example:
#   my $pivots = $self->_majority_pivot_scores( \@training_rows );
#   # row i is flagged at per-tree cutoff theta exactly when
#   # $pivots->[$i] >= theta
#-------------------------------------------------------------------------------
sub _majority_pivot_scores {
	my ( $self, $data ) = @_;
	my $trees = $self->{trees};
	my $t     = scalar @$trees;
	my $c     = $self->{c_psi};
	my $maj   = _min_votes($t);
	my $rows  = $self->_prepare_perl_input($data);
	my $nan   = $self->{missing} eq 'nan' ? 1 : 0;

	# psi <= 1 degenerate forest: every per-tree score is pinned at 0.5
	# (matching score_samples' convention), so every pivot is too.
	return [ (0.5) x @$rows ] unless $c > 0;

	my $inv = log(2) / $c;
	my @pivots;
	for my $x (@$rows) {
		my @paths = sort { $a <=> $b } map { _path_length( $x, $_, 0, $nan ) } @$trees;
		push @pivots, exp( -$paths[ $maj - 1 ] * $inv );
	}
	return \@pivots;
} ## end sub _majority_pivot_scores

# One draw from the standard normal N(0,1) via Box-Muller. Used to pick the
# random hyperplane orientations in Extended Isolation Forest mode.
#
# Args: none.  Draws two uniforms from Perl's rand(), so the caller controls
# reproducibility through srand().
#
# Returns: one float from N(0,1), typically within +/-4.  Consumes exactly
# two rand() draws, which is what keeps the Perl and C builders in step.
#
# Example:
#   srand(42);
#   my $coef = _randn();   # a hyperplane coefficient for one feature
sub _randn {
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return sqrt( -2.0 * log($u1) ) * cos( TWO_PI * $u2 ) if _NV_IS_DOUBLE;

	# Wide-NV perls: round after every operation _c_randn() performs in
	# double, so both backends draw the same coefficient bit patterns
	# (up to libm's own double-vs-long-double disagreements on rare
	# rounding ties).
	my $s = _to_double( sqrt( -2.0 * _to_double( log($u1) ) ) );
	my $c = _to_double( cos( _to_double( TWO_PI * $u2 ) ) );
	return _to_double( $s * $c );
} ## end sub _randn

#-------------------------------------------------------------------------------
# Resolve the derived per-fit geometry from the sample count and feature width,
# storing it on the object and returning ($psi, $limit) for the build loop.
# Factored out of fit() so fit_from_csv() -- which learns n from a streaming
# census rather than an in-RAM array -- produces byte-identical psi/extension/
# depth values.  Pure arithmetic: consumes no randomness.
#
# Args:
#   $n :: total training rows available, a positive integer.  From
#         scalar @$data in fit(), or the census count in fit_from_csv().
#   $n_features :: the feature width, a positive integer.
#
# Returns: the two-element list ($psi, $limit) -- the per-tree sub-sample
# size and the tree height limit.  Also sets c_psi, psi_used,
# extension_level_used (undef outside extended mode) and max_depth_used on
# the object.
#
# Example:
#   my ( $psi, $limit ) = $self->_resolve_geometry( 10_000, 4 );
#   # ( 256, 8 ) at the default sample_size, since ceil(log2(256)) == 8
#-------------------------------------------------------------------------------
sub _resolve_geometry {
	my ( $self, $n, $n_features ) = @_;

	# The sub-sample cannot be larger than the data set itself.
	my $psi = min( $self->{sample_size}, $n );
	$self->{c_psi}    = _c($psi);
	$self->{psi_used} = $psi;

	# Resolve the extension level against the data's dimensionality.
	if ( $self->{mode} eq 'extended' ) {
		my $max_ext = $n_features - 1;
		my $ext
			= defined $self->{extension_level}
			? $self->{extension_level}
			: $max_ext;
		$ext                          = 0        if $ext < 0;
		$ext                          = $max_ext if $ext > $max_ext;
		$self->{extension_level_used} = $ext;
	} else {
		$self->{extension_level_used} = undef;
	}

	# Height limit: the average tree height ceil(log2(psi)). Past this depth the
	# remaining points are scored using the c(size) adjustment instead.
	my $limit
		= defined $self->{max_depth}
		? $self->{max_depth}
		: ceil( log($psi) / log(2) );
	$limit = 1 if $limit < 1;
	$self->{max_depth_used} = $limit;

	return ( $psi, $limit );
} ## end sub _resolve_geometry

#-------------------------------------------------------------------------------
# fit_from_csv() machinery.
#-------------------------------------------------------------------------------

# Inspect the first non-blank line and report whether it is a header to skip
# rather than train on.  $forced (the header => option) makes it unconditional;
# otherwise a line is a header when it carries any non-numeric text -- data rows
# hold only numbers and empty cells -- or exactly matches stored feature_names.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $forced :: the caller's header => option.  True skips detection and
#              answers yes; undef or false runs the heuristic.
#
# Returns: 1 when the first non-blank line is a header to skip, 0 otherwise.
# An empty file answers 0 and lets the census report the real problem.
#
# Example:
#   $self->_detect_header( 'train.csv', undef );   # 1 for "cpu,mem,disk"
#   $self->_detect_header( 'train.csv', undef );   # 0 for "0.9,0.4,0.1"
sub _detect_header {
	my ( $self, $path, $forced ) = @_;
	open my $fh, '<', $path
		or croak "fit_from_csv(): cannot open '$path': $!";
	my $first;
	while ( defined( my $line = <$fh> ) ) {
		$line =~ s/\r?\n\z//;
		next if $line =~ /^\s*$/;
		$first = $line;
		last;
	}
	close $fh;
	return 0 unless defined $first;    # empty file; the census will report it
	return 1 if $forced;

	my @f = split /,/, $first, -1;
	for my $x (@f) {
		next if !length $x;                       # empty cell: fine in data
		return 1 unless looks_like_number($x);    # text: it is a header
	}

	# All-numeric first line: only a header if it reproduces feature_names.
	my $names = $self->{feature_names};
	if ( ref $names eq 'ARRAY' && @$names == @f ) {
		my $match = grep { $f[$_] eq $names->[$_] } 0 .. $#f;
		return 1 if $match == @f;
	}
	return 0;
} ## end sub _detect_header

# Return a closure that yields ($row, $line_number) per non-blank CSV line and
# an empty list at EOF.  An empty cell becomes undef (the missing-value marker).
# With $parse true each non-empty cell is validated and coerced to a number (a
# non-numeric cell dies); with $parse false the cells are left as raw strings --
# the cheap mode the census uses, which needs only the column count and empties.
# When $skip_first is set the first non-blank line (a header) is dropped.  Blank
# lines are skipped, so a row's index is its position among the non-blank data
# lines -- stable across passes as long as the file does not change under us.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $skip_first :: true to drop the first non-blank line as a header.
#   $parse :: true to validate and numify each non-empty cell (croaking on a
#             non-numeric one), false to hand back raw strings.
#
# Returns: a closure.  Each call returns the two-element list
# (\@fields, $line_number) for the next data line, or the empty list at EOF
# (where it also closes the handle).  @fields holds numbers under
# $parse, strings otherwise, with undef for an empty cell.
#
# Example:
#   my $reader = $self->_csv_reader( 'train.csv', 1, 1 );
#   while ( my ( $row, $line ) = $reader->() ) {
#       # $row = [ 0.9, undef, 0.1 ] for "0.9,,0.1" on line $line
#   }
sub _csv_reader {
	my ( $self, $path, $skip_first, $parse ) = @_;
	open my $fh, '<', $path
		or croak "fit_from_csv(): cannot open '$path': $!";
	my $line_no = 0;
	my $skipped = 0;
	return sub {
		while ( defined( my $line = <$fh> ) ) {
			$line_no++;
			$line =~ s/\r?\n\z//;
			next if $line =~ /^\s*$/;
			if ( $skip_first && !$skipped ) { $skipped = 1; next; }
			my @fields = split /,/, $line, -1;
			for my $f (@fields) {
				if ( !length $f ) { $f = undef; next; }
				next unless $parse;
				croak "fit_from_csv(): line $line_no value '$f' is not a number"
					unless looks_like_number($f);
				$f += 0;
			}
			return ( \@fields, $line_no );
		} ## end while ( defined( my $line = <$fh> ) )
		close $fh;
		return;
	}; ## end sub
} ## end sub _csv_reader

# Validate and coerce a raw row (from a parse => 0 reader) into numbers in
# place: defined cells must look like numbers.  An undef cell (empty CSV marker)
# passes through for zero/impute/nan, but croaks under the 'die' strategy -- so
# 'die' rejects a missing value exactly when it lands in a sampled training row.
# $where names the row for error messages.  Only the rows a fit keeps are run
# through here, which is why a bad cell elsewhere is never reported.
#
# Args:
#   $row :: arrayref of raw cells from a parse => 0 reader -- strings, with
#           undef for the empty cells.  Modified in place.
#   $where :: a phrase naming the row for croak messages, e.g. "line 42" or
#             "sampled row 17".
#
# Returns: nothing.  $row's defined cells come back as numbers; undef cells
# stay undef unless missing => 'die', which croaks instead.
#
# Example:
#   my $row = [ '0.9', undef, '0.1' ];
#   $self->_numify_row( $row, 'line 42' );   # [ 0.9, undef, 0.1 ]
sub _numify_row {
	my ( $self, $row, $where ) = @_;
	my $die = $self->{missing} eq 'die';
	for my $f (@$row) {
		if ( !defined $f ) {
			croak "fit_from_csv(): missing value in $where; construct with "
				. "missing => 'zero', 'impute', or 'nan' to train on data "
				. "with missing values"
				if $die;
			next;
		}
		croak "fit_from_csv(): $where value '$f' is not a number"
			unless looks_like_number($f);
		$f += 0;
	} ## end for my $f (@$row)
	return;
} ## end sub _numify_row

# Streaming census (index => 0 or offset table over budget): count the data
# rows and pin the feature width via the cheap parse => 0 reader.  No cell
# validation -- that is deferred to the rows that train or get scored.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $skip_first :: true to drop the first non-blank line as a header.
#
# Returns: the two-element list ($n, $nf) -- the data row count and the
# feature width taken from the first data row.  Both undef-free, though $n
# is 0 and $nf undef for a file with no data rows.  Croaks on a row whose
# column count disagrees with the first row's.
#
# Example:
#   my ( $n, $nf ) = $self->_census_stream( 'train.csv', 1 );   # ( 1_000_000, 4 )
sub _census_stream {
	my ( $self, $path, $skip_first ) = @_;
	my $reader = $self->_csv_reader( $path, $skip_first, 0 );
	my ( $n, $nf ) = ( 0, undef );
	while ( my ( $row, $line ) = $reader->() ) {
		$nf //= scalar @$row;
		croak "fit_from_csv(): line $line of '$path' has " . scalar(@$row) . " columns but expected $nf"
			unless @$row == $nf;
		$n++;
	}
	return ( $n, $nf );
} ## end sub _census_stream

# Streaming gather (no offset table): re-scan the file, numifying only the
# sampled rows.  Companion to _census_stream.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $skip_first :: true to drop the first non-blank line as a header.
#   $want :: hashref used as a set -- its keys are the data row indices to
#            keep, counting from 0 over the non-blank data lines.
#
# Returns: hashref keyed by the same indices, each value the numified row as
# an arrayref.  Indices absent from the file simply do not appear.
#
# Example:
#   my $pool = $self->_gather_stream( 'train.csv', 1, { 0 => 1, 7 => 1 } );
#   # { 0 => [ 0.9, 0.4 ], 7 => [ 1.2, 0.3 ] }
sub _gather_stream {
	my ( $self, $path, $skip_first, $want ) = @_;
	my $reader = $self->_csv_reader( $path, $skip_first, 0 );
	my %pool;
	my $i = 0;
	while ( my ( $row, $line ) = $reader->() ) {
		if ( exists $want->{$i} ) {
			$self->_numify_row( $row, "line $line" );
			$pool{$i} = $row;
		}
		$i++;
	}
	return \%pool;
} ## end sub _gather_stream

# Index census: one block-scan that counts the data rows, pins the feature
# width, AND records each data row's byte offset so gather can seek straight to
# the sampled rows.  Blank lines are skipped and the header dropped exactly as
# the reader does, so offset i is the i-th data row.  The offset table costs
# 8*n bytes; once it would exceed $max_off it is dropped (returning undef) and
# only the count survives, so the caller falls back to the streaming gather.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $skip_first :: true to drop the first non-blank line as a header.
#   $max_off :: byte ceiling for the offset table.  0 disables the table
#               outright, making this a pure counting pass.
#
# Returns: the three-element list ($n, $nf, $offsets) -- the data row count,
# the feature width, and either an arrayref of per-row byte offsets (element
# i is data row i's start) or undef when the table was disabled or went over
# budget.
#
# Example:
#   my ( $n, $nf, $off ) = $self->_index_pass( 'train.csv', 1, 64 * 1024 * 1024 );
#   # ( 1_000_000, 4, [ 12, 31, 49, ... ] ), or $off undef past 8 MB of table
sub _index_pass {
	my ( $self, $path, $skip_first, $max_off ) = @_;
	open my $fh, '<', $path
		or croak "fit_from_csv(): cannot open '$path': $!";
	binmode $fh;

	my @off;
	my $store   = $max_off > 0 ? 1 : 0;
	my $cap     = int( $max_off / 8 );
	my $n       = 0;
	my $skipped = 0;
	my $nf;

	# Consider the line at ($$sref, $off .. $off+$len).  To stay fast we avoid
	# copying the line: a zero-length line is empty, and any line whose first
	# byte is a digit/sign/dot (>= '!') is non-blank without further checks --
	# only a line starting with whitespace (< '!') is materialised to apply the
	# reader's /^\s*$/ blank test.  $abs is its absolute byte offset.
	my $feed = sub {
		my ( $abs, $sref, $off, $len ) = @_;
		return if $len == 0;
		if ( substr( $$sref, $off, 1 ) lt '!' ) {    # leading whitespace: maybe blank
			return if substr( $$sref, $off, $len ) !~ /\S/;
		}
		if ( $skip_first && !$skipped ) { $skipped = 1; return; }
		$nf //= scalar( () = split /,/, substr( $$sref, $off, $len ), -1 );    # width from row 1
		$n++;
		return unless $store;
		push @off, $abs;
		if ( @off > $cap ) { $store = 0; @off = () }                           # over budget: abandon the table
	}; ## end $feed = sub

	my ( $carry, $file_pos ) = ( '', 0 );                                      # $file_pos = abs offset of $carry's start
	my $buf;
	while ( my $got = read( $fh, $buf, 1 << 20 ) ) {
		my $s = $carry . $buf;
		my $p = 0;
		my $nl;
		while ( ( $nl = index( $s, "\n", $p ) ) >= 0 ) {
			my $len = $nl - $p;
			$len-- if $len && substr( $s, $nl - 1, 1 ) eq "\r";    # exclude a CRLF's CR
			$feed->( $file_pos + $p, \$s, $p, $len );
			$p = $nl + 1;
		}
		$carry = substr( $s, $p );
		$file_pos += $p;
	} ## end while ( my $got = read( $fh, $buf, 1 << 20 ) )
	close $fh;
	$feed->( $file_pos, \$carry, 0, length $carry ) if length $carry;    # final unterminated line

	return ( $n, $nf, $store ? \@off : undef );
} ## end sub _index_pass

# Random-access gather: seek to each sampled row's recorded offset and numify
# it.  Indices are visited in order for sequential-ish disk access.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $offsets :: the arrayref of per-row byte offsets from _index_pass.
#   $want :: hashref used as a set -- its keys are the data row indices to
#            keep.
#
# Returns: hashref keyed by the same indices, each value the numified row as
# an arrayref.  Croaks on a short read or a row whose column count
# disagrees with the model's n_features, which is how a file changing
# underneath the passes gets caught.
#
# Example:
#   my $pool = $self->_gather_indexed( 'train.csv', $offsets, { 0 => 1, 7 => 1 } );
#   # { 0 => [ 0.9, 0.4 ], 7 => [ 1.2, 0.3 ] }
sub _gather_indexed {
	my ( $self, $path, $offsets, $want ) = @_;
	open my $fh, '<', $path
		or croak "fit_from_csv(): cannot open '$path': $!";
	my $nf = $self->{n_features};
	my %pool;
	for my $i ( sort { $a <=> $b } keys %$want ) {
		seek( $fh, $offsets->[$i], 0 )
			or croak "fit_from_csv(): seek failed for row $i: $!";
		my $line = <$fh>;
		croak "fit_from_csv(): row $i is past the end of '$path'" unless defined $line;
		$line =~ s/\r?\n\z//;
		my @f = split /,/, $line, -1;
		croak "fit_from_csv(): sampled row $i has " . scalar(@f) . " columns but expected $nf"
			unless @f == $nf;
		for my $x (@f) { $x = undef if !length $x }
		$self->_numify_row( \@f, "sampled row $i" );
		$pool{$i} = \@f;
	} ## end for my $i ( sort { $a <=> $b } keys %$want )
	close $fh;
	return \%pool;
} ## end sub _gather_indexed

# Draw $k distinct indices uniformly from [0, $n) via Floyd's algorithm --
# O($k) time and memory, so it never allocates the 0..n-1 vector _subsample()
# builds (the whole point: n may not fit in RAM).  Returns them sorted, which
# makes the per-tree sample order deterministic (independent of hash-key
# randomisation) even though tree structure does not depend on row order.
#
# Args:
#   $n :: the population size, a non-negative integer.
#   $k :: how many distinct indices to draw.  $k >= $n yields everything.
#
# Returns: the drawn indices as a sorted list (not a reference), each in
# [0, $n).
#
# Example:
#   srand(42);
#   my @idx = _sample_indices_distinct( 1_000_000, 256 );   # 256 sorted rows
sub _sample_indices_distinct {
	my ( $n, $k ) = @_;
	return ( 0 .. $n - 1 ) if $k >= $n;
	my %seen;
	for my $j ( $n - $k .. $n - 1 ) {
		my $t = int( rand( $j + 1 ) );    # uniform in [0, $j]
		$seen{ exists $seen{$t} ? $j : $t } = 1;
	}
	my @idx = sort { $a <=> $b } keys %seen;
	return @idx;
} ## end sub _sample_indices_distinct

# Apply the missing-value strategy to the gathered pool (hashref index => row),
# densifying in place so the pure-Perl _build_tree sees defined cells.  Mirrors
# _prepare_fit_data, except impute learns its fill from the training sub-sample
# rather than the full file -- the only fill bounded-memory fitting can form.
#
# Args:
#   $pool :: hashref of row index => arrayref of cells, as returned by
#            _gather_stream or _gather_indexed.  Rewritten in place.
#
# Returns: nothing.  Under zero/impute every row in $pool comes back dense;
# under impute the learned fill is also stored in $self->{missing_fill}.
# die and nan return untouched (die data is already dense, nan wants its
# undefs kept).
#
# Example:
#   my $pool = $self->_gather_indexed( $path, $offsets, $want );
#   $self->_apply_missing_to_pool($pool);   # undef cells now carry the fill
sub _apply_missing_to_pool {
	my ( $self, $pool ) = @_;
	my $m = $self->{missing};
	return if $m eq 'die' || $m eq 'nan';    # die: already dense; nan: keep undef

	my $nf = $self->{n_features};
	my $fill;
	if ( $m eq 'impute' ) {
		$fill = $self->_compute_impute_fill( [ values %$pool ] );
		$self->{missing_fill} = $fill;
		delete $self->{_fill_packed};
	} else {                                 # zero
		$fill = [ (0) x $nf ];
	}
	for my $i ( keys %$pool ) {
		my $r = $pool->{$i};
		$pool->{$i} = [ map { defined $r->[$_] ? $r->[$_] : $fill->[$_] } 0 .. $nf - 1 ];
	}
	return;
} ## end sub _apply_missing_to_pool

# Streaming counterpart of _learn_contamination_threshold: learn the exact
# score cutoff for the contamination rate without holding every score.  k+1
# largest scores are enough for _threshold_from_ranked's boundary logic; a
# min-heap keeps them in one scoring pass, and (only under a boundary tie) one
# extra pass resolves the tie block's edges.
#
# Args:
#   $path :: path to the CSV file the model was just fitted from.
#   $skip_first :: true to drop the first non-blank line as a header.
#   $n :: the census row count, which fixes how many rows k stands for.
#   $c_scan :: true to let the C packer coerce cells, skipping the Perl
#              numeric validation on the scoring passes.  See _stream_scores.
#
# Returns: nothing.  Sets $self->{threshold} to the same value the in-RAM
# _learn_contamination_threshold would have produced for this data.
#
# Example:
#   $self->_learn_contamination_threshold_streaming( 'train.csv', 1, 1_000_000, 1 );
sub _learn_contamination_threshold_streaming {
	my ( $self, $path, $skip_first, $n, $c_scan ) = @_;

	my $k = int( $self->{contamination} * $n + 0.5 );
	$k = 1  if $k < 1;
	$k = $n if $k > $n;

	# Whole set flagged: sit the cut just below the global minimum score.
	if ( $k >= $n ) {
		my $min;
		$self->_stream_scores( $path, $skip_first, sub { $min = $_[0] if !defined $min || $_[0] < $min }, $c_scan );
		$self->{threshold} = $min - 1e-9;
		return;
	}

	# One scoring pass keeps the k+1 largest scores (a min-heap rooted at the
	# smallest kept).  contamination <= 0.5 bounds k at n/2, so this tail is
	# always the smaller side of the split.
	my @heap;
	my $cap = $k + 1;
	$self->_stream_scores(
		$path,
		$skip_first,
		sub {
			my $s = $_[0];
			if    ( @heap < $cap )  { _heap_push( \@heap, $s ) }
			elsif ( $s > $heap[0] ) { _heap_replace_root( \@heap, $s ) }
		},
		$c_scan
	);

	my @desc = sort { $b <=> $a } @heap;    # k+1 largest, descending
	my $v    = $desc[ $k - 1 ];             # k-th largest
	my $lo   = $desc[$k];                   # (k+1)-th largest

	# Clean gap at the boundary: cut midway, exactly as _threshold_from_ranked.
	if ( $lo < $v ) {
		$self->{threshold} = ( $v + $lo ) / 2.0;
		return;
	}

	# A tie block of value $v straddles rank k.  Reproduce _threshold_from_ranked's
	# tie branch: locate the block's edges (i = first index at $v, j = first
	# index below it) and the neighbouring scores with one more pass.
	my ( $cnt_gt, $cnt_eq, $above, $below ) = ( 0, 0, undef, undef );
	$self->_stream_scores(
		$path,
		$skip_first,
		sub {
			my $s = $_[0];
			if ( $s > $v ) {
				$cnt_gt++;
				$above = $s if !defined $above || $s < $above;    # smallest > $v
			} elsif ( $s == $v ) {
				$cnt_eq++;
			} else {
				$below = $s if !defined $below || $s > $below;    # largest < $v
			}
		},
		$c_scan
	);

	my $i = $cnt_gt;              # first rank holding $v
	my $j = $cnt_gt + $cnt_eq;    # first rank below $v
	if ( $i > 0 && ( $k - $i ) < ( $j - $k ) ) {
		$self->{threshold} = ( $above + $v ) / 2.0;    # exclude the block
	} elsif ( $j < $n ) {
		$self->{threshold} = ( $v + $below ) / 2.0;    # include the block
	} else {
		$self->{threshold} = $v - 1e-9;                # block runs to the end
	}
	return;
} ## end sub _learn_contamination_threshold_streaming

# Stream the CSV, score rows in flat batches (through the same mean/majority
# path score_samples/predict use), and invoke $cb->($score) for each row.
# c_scan fast path: when scoring runs through the C packer (mean voting, use_c,
# trees packed) the packer coerces each cell via SvNV, so the reader can run
# raw (parse => 0) and skip the Perl looks_like_number validation.  Every other
# path parses (parse => 1) so its Perl scorer sees real numbers.
#
# Args:
#   $path :: path to the CSV file, which must be readable.
#   $skip_first :: true to drop the first non-blank line as a header.
#   $cb :: coderef invoked once per data row as $cb->($score), in file order.
#          The score is the mean-mode anomaly score, or the majority pivot
#          under voting => 'majority'.
#   $c_scan :: true to allow the raw-cell fast path described above.
#
# Returns: nothing; everything is delivered through $cb.
#
# Example:
#   my $max;
#   $self->_stream_scores( 'train.csv', 1,
#       sub { $max = $_[0] if !defined $max || $_[0] > $max }, 1 );
sub _stream_scores {
	my ( $self, $path, $skip_first, $cb, $c_scan ) = @_;
	my $majority = $self->{voting} eq 'majority' ? 1 : 0;
	my $c_coerce = $c_scan && $self->{_use_c} && $self->{_c_nodes} && !$majority;
	my $reader   = $self->_csv_reader( $path, $skip_first, $c_coerce ? 0 : 1 );

	# The c_coerce path lets the C packer turn any non-numeric cell into 0.0 via
	# SvNV; silence the per-cell "isn't numeric" warnings that intentional
	# coercion raises (clean data produces none).  Other warnings pass through.
	local $SIG{__WARN__};
	$SIG{__WARN__} = sub { $_[0] =~ /isn't numeric/ or warn $_[0] }
		if $c_coerce;

	my @batch;
	my $flush = sub {
		return unless @batch;
		my $scores
			= $majority
			? $self->_majority_pivot_scores( \@batch )
			: $self->score_samples( \@batch );
		$cb->($_) for @$scores;
		@batch = ();
	};
	while ( my ($row) = $reader->() ) {
		push @batch, $row;
		$flush->() if @batch >= 8192;
	}
	$flush->();
	return;
} ## end sub _stream_scores

# Minimal binary min-heap over a plain arrayref (root = smallest).  Paired
# with _heap_replace_root to keep the k+1 largest scores of a stream in
# bounded memory -- push until full, then replace the root whenever a
# bigger value turns up.
#
# Append a value and sift it up into place.
#
# Args:
#   $h :: the heap, an arrayref maintained by these two functions alone.
#         Modified in place.
#   $x :: the number to insert.
#
# Returns: nothing.  $h->[0] is the smallest value held afterwards.
#
# Example:
#   my @heap;
#   _heap_push( \@heap, $_ ) for 0.7, 0.2, 0.5;
#   $heap[0];   # 0.2
sub _heap_push {
	my ( $h, $x ) = @_;
	push @$h, $x;
	my $i = $#$h;
	while ( $i > 0 ) {
		my $p = ( $i - 1 ) >> 1;
		last if $h->[$p] <= $h->[$i];
		@{$h}[ $p, $i ] = @{$h}[ $i, $p ];
		$i = $p;
	}
	return;
} ## end sub _heap_push

# Overwrite the smallest value held and sift the replacement down.  Keeps
# the heap at a fixed size, which is how the scoring pass retains only the
# largest k+1 scores it has seen.
#
# Args:
#   $h :: the heap, a non-empty arrayref built by _heap_push.  Modified in
#         place.
#   $x :: the number to put in the root's place.  Callers only do this when
#         $x is larger than the current root, so the heap keeps the biggest
#         values.
#
# Returns: nothing.  $h->[0] is the smallest of the retained values
# afterwards.
#
# Example:
#   _heap_replace_root( \@heap, 0.9 ) if $score > $heap[0];
sub _heap_replace_root {
	my ( $h, $x ) = @_;
	$h->[0] = $x;
	my $n = scalar @$h;
	my $i = 0;
	while (1) {
		my $l = 2 * $i + 1;
		my $r = 2 * $i + 2;
		my $s = $i;
		$s = $l if $l < $n && $h->[$l] < $h->[$s];
		$s = $r if $r < $n && $h->[$r] < $h->[$s];
		last if $s == $i;
		@{$h}[ $s, $i ] = @{$h}[ $i, $s ];
		$i = $s;
	} ## end while (1)
	return;
} ## end sub _heap_replace_root

#-------------------------------------------------------------------------------
# Draw $k samples without replacement via a partial Fisher-Yates shuffle of the
# index array.
#
# Args:
#   $data :: the training set, an arrayref of feature-value arrayrefs.
#            Never modified.
#   $k :: how many samples to draw, an integer in [1, scalar @$data].
#
# Returns: an arrayref of $k row references.  The rows are SHARED with
# $data, not copied, so nothing downstream may mutate them -- _build_tree
# only ever reads.
#
# Example:
#   srand(42);
#   my $sample = _subsample( \@training_rows, 256 );
#   my $tree   = $self->_build_tree( $sample, 0, 8 );
#-------------------------------------------------------------------------------
sub _subsample {
	my ( $data, $k ) = @_;
	my $n   = scalar @$data;
	my @idx = ( 0 .. $n - 1 );
	for my $i ( 0 .. $k - 1 ) {
		my $j = $i + int( rand( $n - $i ) );
		@idx[ $i, $j ] = @idx[ $j, $i ];
	}
	my @chosen = @idx[ 0 .. $k - 1 ];
	return [ @{$data}[@chosen] ];
} ## end sub _subsample

#-------------------------------------------------------------------------------
# Recursively build one isolation tree.
#
# A node is one of:
#   leaf     { leaf => 1, size => N }
#   axis     { attr => A, split => S,            left => ..., right => ... }
#   oblique  { idx => [..], coef => [..], b => B, left => ..., right => ... }
#
# In both split styles the choice is restricted to features that actually vary
# across the points reaching the node: this avoids wasted levels on constant
# columns and lets a node leaf out exactly when its points are indistinguishable.
#
# Args:
#   $X :: the points reaching this node, an arrayref of feature-value
#         arrayrefs.  Read-only; undef cells only appear under
#         missing => 'nan'.
#   $depth :: this node's depth, 0 at the root.
#   $limit :: the height limit from _resolve_geometry.  At or past it the
#             node leafs out and c(size) covers the rest.
#
# Returns: the node as an arrayref in the layout above, with children
# already recursed into -- so calling it on the root returns the whole tree.
#
# Example:
#   my $tree = $self->_build_tree( _subsample( \@rows, 256 ), 0, 8 );
#   # [ 1, 2, 0.37, [ ... ], [ ... ] ] -- an axis split on feature 2
#-------------------------------------------------------------------------------
sub _build_tree {
	my ( $self, $X, $depth, $limit ) = @_;

	my $size = scalar @$X;
	return [ _NODE_LEAF, $size ]
		if $depth >= $limit || $size <= 1;

	my $nf  = $self->{n_features};
	my $nan = $self->{missing} eq 'nan';

	# Per-feature min and max within this node, in a single pass.  Missing
	# (undef) cells never reach here under die/zero/impute -- those fill the
	# data before fit -- so the "next unless defined" guard is only needed
	# in nan mode, where missing values must not constrain a feature's
	# range; every other strategy skips it since every cell is defined and
	# the check would never fire.
	my ( @lo, @hi );
	if ($nan) {
		for my $row (@$X) {
			for my $f ( 0 .. $nf - 1 ) {
				my $v = $row->[$f];
				next unless defined $v;
				$lo[$f] = $v if !defined $lo[$f] || $v < $lo[$f];
				$hi[$f] = $v if !defined $hi[$f] || $v > $hi[$f];
			}
		}
	} else {
		for my $row (@$X) {
			for my $f ( 0 .. $nf - 1 ) {
				my $v = $row->[$f];
				$lo[$f] = $v if !defined $lo[$f] || $v < $lo[$f];
				$hi[$f] = $v if !defined $hi[$f] || $v > $hi[$f];
			}
		}
	}

	# Features with spread are the only ones that can split the data.  A
	# feature whose values are all missing within this node has an undef
	# range and is excluded.
	my @varying = grep { defined $lo[$_] && $lo[$_] < $hi[$_] } 0 .. $nf - 1;

	# No spread on any feature => all points identical => cannot isolate.
	return [ _NODE_LEAF, $size ] unless @varying;

	my $node
		= $self->{mode} eq 'extended'
		? $self->_oblique_split( $X, \@varying, \@lo, \@hi, $nan )
		: _axis_split( $X, \@varying, \@lo, \@hi, $nan );

	# Split functions leave the raw point arrays at the child slots so that
	# _build_tree can recurse into them; the subtree refs replace them in-place.
	# Axis nodes:   left at [3], right at [4]
	# Oblique nodes: left at [4], right at [5]
	my ( $li, $ri ) = $node->[0] == _NODE_AXIS ? ( 3, 4 ) : ( 4, 5 );
	$node->[$li] = $self->_build_tree( $node->[$li], $depth + 1, $limit );
	$node->[$ri] = $self->_build_tree( $node->[$ri], $depth + 1, $limit );

	return $node;
} ## end sub _build_tree

# Axis-parallel cut: random varying feature, random threshold in its range.
#
# Args:
#   $X :: the points reaching this node, an arrayref of feature-value
#         arrayrefs.
#   $varying :: arrayref of the feature indices that actually vary here --
#               the only ones worth cutting on.  Must be non-empty.
#   $lo, $hi :: arrayrefs of per-feature minimum and maximum over $X,
#               indexed by feature number.  Entries for features that are
#               absent throughout are undef and never consulted.
#   $nan :: true under missing => 'nan', which routes a point missing the
#           split feature right.
#
# Returns: [ _NODE_AXIS, $attr, $split, \@left_pts, \@right_pts ].  Slots 3
# and 4 hold raw point arrays, which _build_tree overwrites with the
# recursed subtrees.
#
# Example:
#   my $node = _axis_split( $X, [ 0, 2 ], \@lo, \@hi, 0 );
#   # [ 1, 2, 0.37, [ ...pts < 0.37... ], [ ...pts >= 0.37... ] ]
sub _axis_split {
	my ( $X, $varying, $lo, $hi, $nan ) = @_;

	my $attr = $varying->[ int( rand( scalar @$varying ) ) ];
	my $split;
	if (_NV_IS_DOUBLE) {
		$split = $lo->[$attr] + rand() * ( $hi->[$attr] - $lo->[$attr] );
	} else {
		# Same value, but rounded to double after each of the three ops
		# exactly as the C builder computes it -- see _NV_IS_DOUBLE.
		$split = _to_double( $hi->[$attr] - $lo->[$attr] );
		$split = _to_double( rand() * $split );
		$split = _to_double( $lo->[$attr] + $split );
	}

	# A point missing the split feature (nan mode only) routes to the right
	# child -- the same side NaN reaches in the C scorer, where (NaN < split)
	# is false.  Under die/zero/impute every cell is defined, so the
	# "defined($v)" guard is dead weight there and skipped entirely.
	my ( @left, @right );
	if ($nan) {
		for my $row (@$X) {
			my $v = $row->[$attr];
			if   ( defined($v) && $v < $split ) { push @left,  $row }
			else                                { push @right, $row }
		}
	} else {
		for my $row (@$X) {
			if   ( $row->[$attr] < $split ) { push @left,  $row }
			else                            { push @right, $row }
		}
	}
	return [ _NODE_AXIS, $attr, $split, \@left, \@right ];
} ## end sub _axis_split

# Oblique cut (Extended Isolation Forest): a random hyperplane. We activate
# (extension_level + 1) of the varying features, give each a Gaussian
# coefficient, and place the plane through a random point in the bounding box.
# A point goes left when coef . x <= b, where b = coef . p.
#
# Args:
#   $X :: the points reaching this node, an arrayref of feature-value
#         arrayrefs.
#   $varying :: arrayref of the feature indices that actually vary here.
#               The active set is drawn from these.  Must be non-empty.
#   $lo, $hi :: arrayrefs of per-feature minimum and maximum over $X,
#               indexed by feature number.
#   $nan :: true under missing => 'nan', which routes a point missing any
#           feature on the hyperplane right.
#
# Returns: [ _NODE_OBLIQUE, \@idx, \@coef, $b, \@left_pts, \@right_pts ],
# where @idx names the participating features and @coef holds their
# coefficients one-for-one.  Slots 4 and 5 hold raw point arrays, which
# _build_tree overwrites with the recursed subtrees.
#
# Example:
#   my $node = $self->_oblique_split( $X, [ 0, 1, 2 ], \@lo, \@hi, 0 );
#   # [ 2, [ 0, 2 ], [ 0.81, -1.32 ], 0.44, [ ... ], [ ... ] ]
sub _oblique_split {
	my ( $self, $X, $varying, $lo, $hi, $nan ) = @_;

	my $active = $self->{extension_level_used} + 1;
	$active = scalar @$varying if $active > scalar @$varying;

	# Pick which varying features take part (partial shuffle of their indices).
	my @pool = @$varying;
	for my $i ( 0 .. $active - 1 ) {
		my $j = $i + int( rand( scalar(@pool) - $i ) );
		@pool[ $i, $j ] = @pool[ $j, $i ];
	}
	my @idx = @pool[ 0 .. $active - 1 ];

	my ( @coef, $b );
	$b = 0.0;
	for my $f (@idx) {
		my $c = _randn();
		if (_NV_IS_DOUBLE) {
			my $p = $lo->[$f] + rand() * ( $hi->[$f] - $lo->[$f] );    # point in the box
			push @coef, $c;
			$b += $c * $p;
		} else {
			# Round each op to double in the same order as the C builder's
			#   p = lo + rand() * (hi - lo);  b += c * p;
			# -- see _NV_IS_DOUBLE.
			my $p = _to_double( rand() * _to_double( $hi->[$f] - $lo->[$f] ) );
			$p = _to_double( $lo->[$f] + $p );
			push @coef, $c;
			$b = _to_double( $b + _to_double( $c * $p ) );
		}
	} ## end for my $f (@idx)

	# A point missing any feature on the hyperplane (nan mode only) routes
	# to the right child: in the C scorer the dot product becomes NaN and
	# (NaN <= b) is false, so this keeps fit and score consistent.  Under
	# die/zero/impute every cell is defined, so the per-feature "defined"
	# check and early-exit are dead weight there and skipped entirely.
	my ( @left, @right );
	if ($nan) {
		for my $row (@$X) {
			my $dot     = 0.0;
			my $missing = 0;
			for ( 0 .. $#idx ) {
				my $v = $row->[ $idx[$_] ];
				if ( !defined $v ) { $missing = 1; last }
				$dot += $coef[$_] * $v;
			}
			if   ( !$missing && $dot <= $b ) { push @left,  $row }
			else                             { push @right, $row }
		} ## end for my $row (@$X)
	} else {
		for my $row (@$X) {
			my $dot = 0.0;
			$dot += $coef[$_] * $row->[ $idx[$_] ] for 0 .. $#idx;
			if   ( $dot <= $b ) { push @left,  $row }
			else                { push @right, $row }
		}
	}
	return [ _NODE_OBLIQUE, \@idx, \@coef, $b, \@left, \@right ];
} ## end sub _oblique_split

#-------------------------------------------------------------------------------
# Path length of a single point in a single tree: edges traversed until a leaf,
# plus c(leaf size) when the leaf still holds several points.
#
# Node layout (arrayref, slot 0 = type):
#   _NODE_LEAF    [0, size]
#   _NODE_AXIS    [1, attr, split, left, right]
#   _NODE_OBLIQUE [2, \@idx, \@coef, b, left, right]
#
# The type tag is also used as a loop sentinel: 0 (_NODE_LEAF) is falsy.
# No $self argument -- the node type encodes everything needed.
#-------------------------------------------------------------------------------
# The optional $nan flag selects the nan-strategy routing: a point missing
# the split feature goes to the right child (matching the C scorer, where
# the NaN comparison is false).  Without it, undef is coerced to 0 -- the
# behaviour the die/zero/impute strategies rely on (their data is dense by
# the time it reaches here, so the "// 0" is normally a no-op).
#
# Args:
#   $x :: one sample, an arrayref of feature values.  undef cells are
#         allowed and handled per $nan.
#   $node :: the node to start walking from, normally a tree root.
#   $depth :: the depth credited to $node, 0 for a root.  Callers only pass
#             anything else to resume a partial walk.
#   $nan :: true to use the nan-strategy routing described above; false or
#           omitted to coerce undef to 0.
#
# Returns: the path length, a float -- edges walked plus c(leaf size), so
# it is not an integer whenever the walk ends in a multi-point leaf.
#
# Example:
#   _path_length( [ 0.9, 0.4 ], $tree, 0, 0 );   # e.g. 3.51
sub _path_length {
	my ( $x, $node, $depth, $nan ) = @_;
	while ( $node->[0] ) {    # false only for leaf (type 0)
		if ( $node->[0] == _NODE_AXIS ) {    # [1, attr, split, left, right]
			if ($nan) {
				my $v = $x->[ $node->[1] ];
				$node = ( defined($v) && $v < $node->[2] ) ? $node->[3] : $node->[4];
			} else {
				$node = ( $x->[ $node->[1] ] // 0 ) < $node->[2] ? $node->[3] : $node->[4];
			}
		} else {                             # [2, \@idx, \@coef, b, left, right]
			my ( $idx, $coef, $b ) = ( $node->[1], $node->[2], $node->[3] );
			if ($nan) {
				my $dot     = 0.0;
				my $missing = 0;
				for ( 0 .. $#$idx ) {
					my $v = $x->[ $idx->[$_] ];
					if ( !defined $v ) { $missing = 1; last }
					$dot += $coef->[$_] * $v;
				}
				$node = ( !$missing && $dot <= $b ) ? $node->[4] : $node->[5];
			} else {
				my $dot = 0.0;
				$dot += $coef->[$_] * ( $x->[ $idx->[$_] ] // 0 ) for 0 .. $#$idx;
				$node = $dot <= $b ? $node->[4] : $node->[5];
			}
		} ## end else [ if ( $node->[0] == _NODE_AXIS ) ]
		$depth++;
	} ## end while ( $node->[0] )
	return $depth + _c( $node->[1] );    # leaf size at slot 1
} ## end sub _path_length

#-------------------------------------------------------------------------------
# Explanation (explain_samples) internals.
#-------------------------------------------------------------------------------

# Instrumented twin of _path_length: routes $x through one tree with
# EXACTLY _path_length's split logic while recording which feature(s)
# each crossed node tested.  Returns (path_length, \@pairs) where
# path_length carries the usual c(leaf size) adjustment and each pair
# is [feature_index, share] -- an axis node contributes one pair with
# share 1, an oblique node one pair per participating feature with
# shares proportional to |coef_k * x_k| (each feature's part of the
# dot product), falling back to an even split when every term is 0.
#
# The caller (_explain_path) turns these walks into local-DIFFI credit
# (Carletti, Terzi & Susto, see REFERENCES): every node of a tree's
# walk is credited w_t = 1/h_t - 1/h_max, where h_t is this tree's
# (adjusted) path length and h_max the longest walk any tree gave the
# same sample -- so trees that isolated the sample quickly speak
# loudest, trees that treated it as normal say nothing, and the credit
# is a cross-TREE statistic.  Within-tree positional weightings were
# tried and rejected: root-anchored credit (1/(depth+1)) mostly
# rediscovers the RNG (the root split's feature is drawn uniformly at
# random regardless of the sample), and leaf-anchored credit
# (1/(h-depth)) is diluted by the trees that never isolated the sample
# at all.
#
# Args:
#   $x :: one sample, an arrayref of feature values.  undef cells are
#         allowed and handled per $nan.
#   $node :: the node to start walking from, normally a tree root.
#   $nan :: true to use the nan-strategy routing, matching _path_length.
#
# Returns: the two-element list ($path_length, $pairs).  $path_length is
# the same float _path_length would return for this sample and tree.
# $pairs is an arrayref of [ feature_index, share ] entries, one per axis
# node crossed and one per participating feature at each oblique node, with
# the shares at any one node summing to 1.
#
# Example:
#   my ( $h, $pairs ) = _path_length_explain( [ 0.9, 0.4 ], $tree, 0 );
#   # ( 3.51, [ [ 1, 1 ], [ 0, 1 ], [ 1, 1 ] ] ) for an axis-mode tree
sub _path_length_explain {
	my ( $x, $node, $nan ) = @_;
	my $depth = 0;
	my @pairs;                # [feature, share] for every crossed node
	while ( $node->[0] ) {    # false only for leaf (type 0)
		if ( $node->[0] == _NODE_AXIS ) {    # [1, attr, split, left, right]
			push @pairs, [ $node->[1], 1 ];
			if ($nan) {
				my $v = $x->[ $node->[1] ];
				$node = ( defined($v) && $v < $node->[2] ) ? $node->[3] : $node->[4];
			} else {
				$node = ( $x->[ $node->[1] ] // 0 ) < $node->[2] ? $node->[3] : $node->[4];
			}
		} else {                             # [2, \@idx, \@coef, b, left, right]
			my ( $idx, $coef, $b ) = ( $node->[1], $node->[2], $node->[3] );

			my @parts      = map { abs( $coef->[$_] * ( $x->[ $idx->[$_] ] // 0 ) ) } 0 .. $#$idx;
			my $part_total = 0;
			$part_total += $_ for @parts;
			push @pairs, $part_total > 0
				? ( map { [ $idx->[$_], $parts[$_] / $part_total ] } 0 .. $#$idx )
				: ( map { [ $idx->[$_], 1 / scalar @$idx ] } 0 .. $#$idx );

			if ($nan) {
				my $dot     = 0.0;
				my $missing = 0;
				for ( 0 .. $#$idx ) {
					my $v = $x->[ $idx->[$_] ];
					if ( !defined $v ) { $missing = 1; last }
					$dot += $coef->[$_] * $v;
				}
				$node = ( !$missing && $dot <= $b ) ? $node->[4] : $node->[5];
			} else {
				my $dot = 0.0;
				$dot += $coef->[$_] * ( $x->[ $idx->[$_] ] // 0 ) for 0 .. $#$idx;
				$node = $dot <= $b ? $node->[4] : $node->[5];
			}
		} ## end else [ if ( $node->[0] == _NODE_AXIS ) ]
		$depth++;
	} ## end while ( $node->[0] )
	return ( $depth + _c( $node->[1] ), \@pairs );    # leaf size at slot 1
} ## end sub _path_length_explain

# Turn one sample's per-tree walks into local-DIFFI feature credit --
# see _path_length_explain's comment for the weighting and what was
# tried instead.  A plain function so the Online class can reuse it on
# its own walks.
#
# Args:
#   $walks :: arrayref of one [ $path_length, $pairs ] per tree, exactly as
#             _path_length_explain returns them.  Trees that contributed no
#             walk are simply absent.
#   $nf :: the model's feature count, which fixes the returned width.
#
# Returns: arrayref of $nf raw credit totals, indexed by feature.  These
# are unnormalised -- _credit_to_features turns them into shares.  All
# zeroes when no tree isolated the sample faster than the slowest one.
#
# Example:
#   my @walks  = map { [ _path_length_explain( $x, $_, 0 ) ] } @$trees;
#   my $credit = _walks_to_credit( \@walks, 2 );   # [ 0.51, 0.09 ]
sub _walks_to_credit {
	my ( $walks, $nf ) = @_;
	my $hmax = 0;
	for (@$walks) { $hmax = $_->[0] if $_->[0] > $hmax }
	my $credit = [ (0) x $nf ];
	for my $walk (@$walks) {
		my ( $h, $pairs ) = @$walk;
		next unless @$pairs && $h > 0 && $hmax > 0;
		my $w = 1.0 / $h - 1.0 / $hmax;
		next if $w <= 0;
		$credit->[ $_->[0] ] += $w * $_->[1] for @$pairs;
	}
	return $credit;
} ## end sub _walks_to_credit

# Turn one sample's accumulated per-feature path credit into the sorted
# features list explain_samples returns.  Weights are the credit shares
# (summing to 1); a sample that never crossed a split node (all-leaf
# trees) carries no information, so every weight stays 0 rather than
# inventing a uniform split.  A plain function, not a method: the
# Online class shapes its explanations through this too.
#
# Args:
#   $names :: the model's feature_names arrayref, or undef when the model
#             has none -- then every name comes back undef.
#   $credit :: the raw per-feature credit from _walks_to_credit.  Its
#              length fixes how many features are reported.
#   $row :: the sample being explained, an arrayref, so each feature can
#           report the value it actually had.
#
# Returns: arrayref of hashrefs, one per feature, sorted by descending
# weight with the feature index breaking ties.  Each holds index, name,
# weight (a share in [0, 1], summing to 1 unless every credit was 0) and
# value.
#
# Example:
#   _credit_to_features( [ 'cpu', 'mem' ], [ 0.51, 0.09 ], [ 0.9, 0.4 ] );
#   # [ { index => 0, name => 'cpu', weight => 0.85, value => 0.9 },
#   #   { index => 1, name => 'mem', weight => 0.15, value => 0.4 } ]
sub _credit_to_features {
	my ( $names, $credit, $row ) = @_;
	my $total = 0;
	$total += $_ for @$credit;
	my @features = map {
		{
			index  => $_,
			name   => $names     ? $names->[$_]           : undef,
			weight => $total > 0 ? $credit->[$_] / $total : 0,
			value  => $row->[$_],
		}
	} 0 .. $#$credit;
	return [ sort { $b->{weight} <=> $a->{weight} || $a->{index} <=> $b->{index} } @features ];
} ## end sub _credit_to_features

# Ablation counterpart of _credit_to_features: deltas are score drops
# (score(original) - score(feature substituted with its baseline));
# weight is each positive delta's share of the positive total, keeping
# weights in [0, 1] like the path method's.  A negative delta -- the
# substitution made the sample MORE anomalous, possible with correlated
# features -- keeps its sign in delta but contributes weight 0.
#
# Args:
#   $names :: the model's feature_names arrayref, or undef when the model
#             has none -- then every name comes back undef.
#   $deltas :: arrayref of per-feature score drops.  Its length fixes how
#              many features are reported.
#   $row :: the sample being explained, an arrayref, so each feature can
#           report the value it actually had.
#   $baselines :: the per-feature substitution values the deltas were
#                 measured against, reported alongside them.
#
# Returns: arrayref of hashrefs, one per feature, sorted by descending
# weight with the feature index breaking ties.  Each holds index, name,
# delta (signed), weight (a share in [0, 1]), value and baseline.
#
# Example:
#   _deltas_to_features( [ 'cpu', 'mem' ], [ 0.21, -0.02 ],
#                        [ 0.9, 0.4 ], [ 0.5, 0.5 ] );
#   # cpu first with weight 1; mem keeps delta -0.02 but weight 0
sub _deltas_to_features {
	my ( $names, $deltas, $row, $baselines ) = @_;
	my $pos_total = 0;
	for (@$deltas) { $pos_total += $_ if $_ > 0 }
	my @features = map {
		{
			index    => $_,
			name     => $names ? $names->[$_] : undef,
			delta    => $deltas->[$_],
			weight   => ( $pos_total > 0 && $deltas->[$_] > 0 ) ? $deltas->[$_] / $pos_total : 0,
			value    => $row->[$_],
			baseline => $baselines->[$_],
		}
	} 0 .. $#$deltas;
	return [ sort { $b->{weight} <=> $a->{weight} || $a->{index} <=> $b->{index} } @features ];
} ## end sub _deltas_to_features

# The path-credit explanation: one pure-Perl instrumented walk per tree
# per sample.  The reported score still comes from score_samples so it
# is bit-identical to what the user saw when the sample got flagged
# (and carries the right semantics under voting => 'majority').
#
# Args:
#   $rows :: the samples to explain, an arrayref of feature-value
#            arrayrefs.  Raw undef cells are fine.
#
# Returns: arrayref of one hashref per row, in input order, each holding
# score, method (always 'path') and features -- the sorted per-feature
# list _credit_to_features builds.
#
# Example:
#   my $out = $self->_explain_path( [ [ 8.1, 0.2 ] ] );
#   $out->[0]{features}[0]{name};   # the feature most responsible
sub _explain_path {
	my ( $self, $rows ) = @_;
	my $scores   = $self->score_samples($rows);
	my $prepared = $self->_prepare_perl_input($rows);
	my $nan      = $self->{missing} eq 'nan' ? 1 : 0;
	my $nf       = $self->{n_features};
	my $names    = $self->{feature_names};
	my $trees    = $self->{trees};

	my @out;
	for my $i ( 0 .. $#$prepared ) {
		my @walks = map { [ _path_length_explain( $prepared->[$i], $_, $nan ) ] } @$trees;
		push @out,
			{
				score    => $scores->[$i],
				method   => 'path',
				features => _credit_to_features( $names, _walks_to_credit( \@walks, $nf ), $prepared->[$i] ),
			};
	}
	return \@out;
} ## end sub _explain_path

# The counterfactual explanation: every row followed by its n_features
# single-feature baseline substitutions, all scored as ONE batch so the
# whole thing runs through score_samples once (C-accelerated when
# available) instead of n_features+1 separate scoring calls.
#
# Args:
#   $rows :: the samples to explain, an arrayref of feature-value
#            arrayrefs.  Raw undef cells are fine.
#
# Returns: arrayref of one hashref per row, in input order, each holding
# score, method (always 'ablation') and features -- the sorted per-feature
# list _deltas_to_features builds.  Croaks by way of _ablation_baselines
# when the model has no stored baselines.
#
# Example:
#   my $out = $self->_explain_ablation( [ [ 8.1, 0.2 ] ] );
#   $out->[0]{features}[0]{delta};   # score drop from neutralising it
sub _explain_ablation {
	my ( $self, $rows ) = @_;
	my $nf        = $self->{n_features};
	my $names     = $self->{feature_names};
	my $baselines = $self->_ablation_baselines;

	my @batch;
	for my $row (@$rows) {
		push @batch, $row;
		for my $f ( 0 .. $nf - 1 ) {
			my @variant = @$row;
			$variant[$f] = $baselines->[$f];
			push @batch, \@variant;
		}
	}
	my $scores = $self->score_samples( \@batch );

	my @out;
	for my $i ( 0 .. $#$rows ) {
		my $base   = $i * ( $nf + 1 );
		my $score  = $scores->[$base];
		my @deltas = map { $score - $scores->[ $base + 1 + $_ ] } 0 .. $nf - 1;
		push @out,
			{
				score    => $score,
				method   => 'ablation',
				features => _deltas_to_features( $names, \@deltas, $rows->[$i], $baselines ),
			};
	} ## end for my $i ( 0 .. $#$rows )
	return \@out;
} ## end sub _explain_ablation

# The per-feature substitution values ablation uses: the training-data
# medians fit() stores, falling back to the impute fill for models
# saved before baseline support (better than refusing outright -- the
# fill IS a typical value, just impute_with's statistic rather than
# always-median).
#
# Args: none beyond the model itself.
#
# Returns: an arrayref of n_features baseline values.  Croaks when neither
# the stored baselines nor an impute fill of the right width is available,
# pointing the caller at method => 'path' or a refit.
#
# Example:
#   my $baselines = $self->_ablation_baselines;   # [ 0.5, 0.5, 1.0 ]
sub _ablation_baselines {
	my ($self) = @_;
	my $nf = $self->{n_features};
	for my $candidate ( $self->{feature_baselines}, $self->{missing_fill} ) {
		return $candidate if ref $candidate eq 'ARRAY' && @$candidate == $nf;
	}
	croak "explain_samples: this model has no stored feature baselines "
		. "(saved by a version before ablation explanation support?); "
		. "refit to enable method => 'ablation', or explain with "
		. "method => 'path'";
} ## end sub _ablation_baselines

# Recursively convert a version-0 hash-based tree node to the version-1
# array format.  Called by from_json when loading an old saved model.
#
# Args:
#   $node :: a version-0 node hashref.  A leaf carries leaf and size; an
#            axis node attr, split, left and right; an oblique node idx,
#            coef, b, left and right.
#
# Returns: the same subtree in the version-1 arrayref layout -- [0, size],
# [1, attr, split, left, right] or [2, \@idx, \@coef, b, left, right].
#
# Example:
#   _hash_node_to_array( { leaf => 1, size => 3 } );   # [ 0, 3 ]
sub _hash_node_to_array {
	my ($node) = @_;
	if ( $node->{leaf} ) {
		return [ _NODE_LEAF, $node->{size} ];
	} elsif ( exists $node->{attr} ) {
		return [
			_NODE_AXIS,     $node->{attr},
			$node->{split}, _hash_node_to_array( $node->{left} ),
			_hash_node_to_array( $node->{right} ),
		];
	} else {
		return [
			_NODE_OBLIQUE, $node->{idx}, $node->{coef}, $node->{b},
			_hash_node_to_array( $node->{left} ),
			_hash_node_to_array( $node->{right} ),
		];
	}
} ## end sub _hash_node_to_array

# ---------------------------------------------------------------------------
# _pack_tree($root) -- flatten one tree into three packed buffers.
#
# Returns ($nodes_packed, $idx_packed, $val_packed) where:
#   nodes_packed: 6 doubles per node (see score_all_xs comment above)
#   idx_packed:   int32 feature indices for every oblique-node coefficient
#   val_packed:   double values matching idx_packed one-for-one
#
# Storing idx and val in separate buffers (SoA) instead of interleaved
# doubles lets the oblique dot product's SIMD inner loop run over a
# contiguous val[] stream without a per-iteration (int) cast, and
# halves the index bandwidth (int32 vs double).  The same `coff`
# offset addresses paired entries in both buffers.
#
# Nodes are numbered in DFS pre-order: the root is always index 0 and
# children always get indices larger than their parent's.
#
# The C backend does this walk in pack_tree_xs, which is what actually
# runs whenever it is available -- the Perl body below is the fallback
# (no C backend, or a wide-NV perl, where the two would disagree on
# c(size) in the last ulp; see _NV_IS_DOUBLE).  Both produce byte-
# identical buffers on an nvsize == 8 perl.
#
# Args:
#   $root :: the tree's root node, in the nested arrayref layout
#            _build_tree produces.
#   $n_features :: the model's feature count, or undef.  Only used to spot
#                  the dense-pack opportunity described above; passing
#                  undef just skips that optimisation.
#
# Returns: the three-element list ($nodes_packed, $idx_packed,
# $val_packed) -- a 'd*' string of 6 doubles per node, an 'l*' string of
# int32 feature indices, and a 'd*' string of the matching coefficients.
# The latter two are empty strings for an axis-mode tree.
#
# Example:
#   my ( $np, $ip, $vp ) = _pack_tree( $self->{trees}[0], $self->{n_features} );
#   length($np) / ( 6 * 8 );   # node count
# ---------------------------------------------------------------------------
sub _pack_tree {
	my ( $root, $n_features ) = @_;

	if ( $HAS_C && _NV_IS_DOUBLE ) {
		my ( $nodes_packed, $idx_packed, $val_packed ) = ( '', '', '' );
		pack_tree_xs( $root, $n_features // -1, $nodes_packed, $idx_packed, $val_packed );
		return ( $nodes_packed, $idx_packed, $val_packed );
	}

	my ( @node_data, @coef_idx, @coef_val );

	my $assign;
	$assign = sub {
		my ($node) = @_;
		my $my_idx = scalar @node_data;
		push @node_data, undef;    # reserve slot; filled in after children

		if ( $node->[0] == _NODE_LEAF ) {

			# Slot 2 carries c(size) precomputed, so the C scoring loop
			# adds it straight to the depth instead of paying a log()
			# per point per tree at every leaf hit.  _c is the same
			# function the pure-Perl scorer uses, so both backends keep
			# producing bit-identical path lengths.
			$node_data[$my_idx] = [ 0.0, $node->[1] + 0.0, _c( $node->[1] ), 0.0, 0.0, 0.0 ];
		} elsif ( $node->[0] == _NODE_AXIS ) {
			my $li = $assign->( $node->[3] );
			my $ri = $assign->( $node->[4] );
			$node_data[$my_idx] = [
				1.0,
				$node->[1] + 0.0,    # attr
				$node->[2] + 0.0,    # split
				$li + 0.0,
				$ri + 0.0,
				0.0,
			];
		} else {    # _NODE_OBLIQUE
			my ( $idx_arr, $coef_arr, $b ) = ( $node->[1], $node->[2], $node->[3] );
			my $coef_off = scalar @coef_idx;
			my $num      = scalar @$idx_arr;

			# Dense-pack opportunity: when this oblique split uses
			# every feature (extension_level == n_features - 1 and
			# all features vary), pack the coefficients in feature
			# order so val[k] is the coefficient for feature k.  The
			# C scoring path then detects `nf == n_feats` and switches
			# to a no-gather inner loop (dot += val[k] * xi[k]) that
			# auto-vectorizes cleanly with FMA.
			if ( defined $n_features && $num == $n_features ) {
				my %coef_for;
				@coef_for{@$idx_arr} = @$coef_arr;
				for my $k ( 0 .. $n_features - 1 ) {
					push @coef_idx, $k;
					push @coef_val, $coef_for{$k} + 0.0;
				}
			} else {
				for my $i ( 0 .. $num - 1 ) {
					push @coef_idx, int( $idx_arr->[$i] );
					push @coef_val, $coef_arr->[$i] + 0.0;
				}
			}

			my $li = $assign->( $node->[4] );
			my $ri = $assign->( $node->[5] );
			$node_data[$my_idx] = [ 2.0, $coef_off + 0.0, $num + 0.0, $li + 0.0, $ri + 0.0, $b + 0.0, ];
		} ## end else [ if ( $node->[0] == _NODE_LEAF ) ]
		return $my_idx;
	}; ## end $assign = sub
	$assign->($root);

	my $nodes_packed = pack( 'd*', map { @$_ } @node_data );
	my $idx_packed   = @coef_idx ? pack( 'l*', @coef_idx ) : pack('l*');
	my $val_packed   = @coef_val ? pack( 'd*', @coef_val ) : pack('d*');
	return ( $nodes_packed, $idx_packed, $val_packed );
} ## end sub _pack_tree

# Build packed C-ready representations for all trees and store them in
# $self->{_c_nodes}, $self->{_c_coef_idx}, $self->{_c_coef_val}.
# Called after fit() and from_json() when _use_c is true.  n_features is
# threaded through so _pack_tree can spot the dense-pack opportunity.
#
# Args: none beyond the model itself, which must already hold its trees.
#
# Returns: nothing.  Leaves _c_nodes, _c_coef_idx and _c_coef_val holding
# one packed string per tree, in tree order -- the form score_all_xs and
# friends expect.
#
# Example:
#   $self->{trees} = $self->_build_forest_c( $train, $psi, $limit, 100 );
#   $self->_rebuild_c_trees;   # scoring can now take the C path
sub _rebuild_c_trees {
	my ($self) = @_;
	my ( @c_nodes, @c_coef_idx, @c_coef_val );
	for my $tree ( @{ $self->{trees} } ) {
		my ( $np, $ip, $vp ) = _pack_tree( $tree, $self->{n_features} );
		push @c_nodes,    $np;
		push @c_coef_idx, $ip;
		push @c_coef_val, $vp;
	}
	$self->{_c_nodes}    = \@c_nodes;
	$self->{_c_coef_idx} = \@c_coef_idx;
	$self->{_c_coef_val} = \@c_coef_val;
} ## end sub _rebuild_c_trees

# Guard for every method that needs a forest to work with.  Called at the
# top of the scoring and packing entry points so an unfitted model fails
# with one clear message instead of an obscure error deeper in.
#
# Args: none beyond the model itself.
#
# Returns: nothing on success.  Croaks when the model holds no trees --
# either never fitted, or constructed but not yet loaded from JSON.
#
# Example:
#   $self->_check_fitted;   # croaks with "model is not fitted yet"
sub _check_fitted {
	my ($self) = @_;
	croak "model is not fitted yet; call fit() first"
		unless ref $self->{trees} eq 'ARRAY' && @{ $self->{trees} };
}

# ---------------------------------------------------------------------------
# Optional Algorithm::ToNumberMunger integration -- see the MUNGERS POD
# section.  Both helpers are plain functions (not methods) so the Online
# class's delegating methods can hand them their own $self: the plan and
# spec live in the same hash slots on either class.
# ---------------------------------------------------------------------------

# Validate a feature_descriptions hash against the feature names: every
# described feature must exist (a description for one that does not is
# either a typo or a stale leftover from a schema change) and every
# description must be a plain string.  Partial coverage is fine.  A plain
# function, like the munger helpers, so both classes and the prototype
# validator can call it.
#
# Args:
#   $tags :: the model's feature_names, an arrayref of strings.  Must be
#            non-empty -- there is nothing to validate against otherwise.
#   $fd :: the feature_descriptions hashref, keyed by feature name with
#          plain strings as values.
#
# Returns: 1 when the descriptions are usable.  Croaks naming the offending
# key when one is not a known feature, when a value is a reference, or when
# either argument is the wrong shape.
#
# Example:
#   _validate_feature_descriptions( [ 'cpu', 'mem' ],
#       { cpu => 'load average over 1m' } );   # 1; partial coverage is fine
sub _validate_feature_descriptions {
	my ( $tags, $fd ) = @_;
	croak "feature_descriptions must be a hashref of 'feature name => description'"
		unless ref $fd eq 'HASH';
	croak "feature_descriptions requires feature_names to validate against"
		unless ref $tags eq 'ARRAY' && @$tags;
	my %known = map { $_ => 1 } @$tags;
	for my $k ( sort keys %$fd ) {
		croak "feature_descriptions describes '$k', which is not in feature_names"
			unless $known{$k};
		croak "feature_descriptions entry for '$k' must be a plain string"
			if ref $fd->{$k};
	}
	return 1;
} ## end sub _validate_feature_descriptions

# Compile a munger spec against the model's feature names.  Requires
# Algorithm::ToNumberMunger on demand -- it is an optional dependency --
# and lets its compile() croak on any spec problem.
#
# Args:
#   $tags :: the model's feature_names, an arrayref of strings in column
#            order.  Must be non-empty.
#   $mungers :: the munger spec hashref, shaped as
#               Algorithm::ToNumberMunger->compile expects it.
#
# Returns: the compiled plan object.  Croaks when feature_names are
# missing, when the module cannot be loaded, or when compile() rejects the
# spec.
#
# Example:
#   my $plan = _compile_mungers( [ 'method', 'path_len' ],
#       { method => { munger => 'http_method_enum', default => -1 } } );
sub _compile_mungers {
	my ( $tags, $mungers ) = @_;
	croak "this model has mungers but no feature_names to compile them against"
		unless ref $tags eq 'ARRAY' && @$tags;
	local $@;
	eval { require Algorithm::ToNumberMunger; 1 }
		or croak "this model has mungers configured but Algorithm::ToNumberMunger "
		. "could not be loaded; install it to use tagged data with this model: $@";
	return Algorithm::ToNumberMunger->compile(
		tags    => $tags,
		mungers => $mungers,
	);
} ## end sub _compile_mungers

# The compiled plan for this model, or undef when no mungers are
# configured.  Compiled lazily (memoised in _munger_plan) so from_json
# does not need Algorithm::ToNumberMunger installed unless tagged data
# is actually used; new() populates the slot eagerly instead, surfacing
# spec errors at construction.
#
# A plain function rather than a method, like the two helpers above, so the
# Online class can hand it its own $self.
#
# Args: none beyond the model, which is passed positionally.
#
# Returns: the compiled Algorithm::ToNumberMunger plan, or undef when the
# model carries no munger spec.  The plan is memoised in _munger_plan, so
# the compile happens at most once per model.
#
# Example:
#   if ( my $plan = _plan($self) ) {
#       my $vec = $plan->apply_named( { method => 'GET', host => 'h' } );
#   }
sub _plan {
	my ($self) = @_;
	return undef unless $self->{mungers};
	$self->{_munger_plan} //= _compile_mungers( $self->{feature_names}, $self->{mungers} );
	return $self->{_munger_plan};
}

# Memoised "does this perl have a real fork()?".  False on Windows
# without Cygwin; true on every Unix-like platform.  fit() consults it
# before honouring parallel_fit, which is how that option degrades to a
# serial fit instead of failing.
#
# Args: none.
#
# Returns: 1 when Config's d_fork is defined, 0 otherwise.  Config is
# loaded on the first call only and the answer cached for the process.
#
# Example:
#   $self->_fit_trees_parallel(...) if $workers > 1 && _fork_supported();
{
	my $cached;

	sub _fork_supported {
		return $cached if defined $cached;
		require Config;
		$cached
			= ( ( $Config::Config{d_fork} || '' ) eq 'define' ) ? 1 : 0;
		return $cached;
	}
}

#-------------------------------------------------------------------------------
# Fork-based parallel tree builder.  Used by fit() when parallel_fit > 1
# and the platform has a real fork().  Divides n_trees evenly among
# workers; each child seeds its own RNG ($seed + worker_id * 1009 so
# fixed-worker-count runs are reproducible), builds its share (via the
# C builder when _use_c is on, same as the non-parallel path), and
# returns the trees to the parent via Storable on a one-shot pipe.
#
# The trees that come back differ from a serial fit with the same seed
# because the RNG draws happen in a different order -- this is documented
# as part of the parallel_fit contract.
#
# Args:
#   $data :: the prepared training set, an arrayref of feature-value
#            arrayrefs.  Each worker inherits it through the fork, so it is
#            never serialised.
#   $psi :: the per-tree sub-sample size from _resolve_geometry.
#   $limit :: the tree height limit from _resolve_geometry.
#   $workers :: how many children to fork.  Clamped down to n_trees, since
#               a worker with no trees to build is pure overhead.
#
# Returns: an arrayref of all n_trees trees in worker order -- worker 0's
# share first, then worker 1's, and so on, which is what makes the forest
# reproducible.  Croaks when a fork or pipe fails, when a worker exits
# non-zero, or when its trees come back unreadable.
#
# Example:
#   $self->{trees} = $self->_fit_trees_parallel( $train, 256, 8, 4 );
#-------------------------------------------------------------------------------
sub _fit_trees_parallel {
	my ( $self, $data, $psi, $limit, $workers ) = @_;
	require Storable;
	require POSIX;

	my $n_trees = $self->{n_trees};
	$workers = $n_trees if $workers > $n_trees;

	# Divide n_trees as evenly as possible across workers.
	my @shares;
	{
		my $base   = int( $n_trees / $workers );
		my $extras = $n_trees - $base * $workers;
		for my $w ( 0 .. $workers - 1 ) {
			push @shares, $base + ( $w < $extras ? 1 : 0 );
		}
	}

	my @procs;    # { pid, rh, share }
	for my $w ( 0 .. $workers - 1 ) {
		my $share = $shares[$w];
		next unless $share > 0;

		pipe( my $rh, my $wh ) or croak "pipe failed: $!";
		my $pid = fork();
		croak "fork failed: $!" unless defined $pid;

		if ( $pid == 0 ) {
			# child
			close $rh;
			binmode $wh;
			if ( defined $self->{seed} ) {
				srand( $self->{seed} + $w * 1009 );
			}
			# Deliberately never _build_forest_openmp here, even when
			# use_openmp_fit is on: if this process (or the parent that
			# fork()ed us) already ran any OpenMP region before this
			# fork -- including plain score_samples()/predict() with
			# the default use_openmp -- libgomp's thread pool exists
			# but its worker threads didn't survive the fork. A child
			# starting its own #pragma omp parallel region then tries
			# to reuse that now-invalid pool and hangs. This is a
			# general fork()+libgomp limitation, not fixable from here,
			# so forked workers always use the single-threaded C
			# builder (or pure Perl) instead. See t/03-fit-determinism.t
			# and the NATIVE ACCELERATION docs for the observed hang and
			# why parallel_fit + use_openmp_fit isn't composed for real.
			my $trees;
			if ( $self->{_use_c} ) {
				$trees = $self->_build_forest_c( $data, $psi, $limit, $share );
			} else {
				my @t;
				for ( 1 .. $share ) {
					my $sample = _subsample( $data, $psi );
					push @t, $self->_build_tree( $sample, 0, $limit );
				}
				$trees = \@t;
			}
			print $wh Storable::freeze($trees);
			close $wh;
			# _exit so we don't run parent END/DESTROY in the child.
			POSIX::_exit(0);
		} ## end if ( $pid == 0 )

		close $wh;
		binmode $rh;
		push @procs, { pid => $pid, rh => $rh, share => $share };
	} ## end for my $w ( 0 .. $workers - 1 )

	# Collect from each pipe in worker order so the canonical tree
	# ordering is deterministic (worker 0's trees first, then 1's, ...).
	my @all_trees;
	for my $p (@procs) {
		my $buf;
		{
			local $/;
			$buf = readline( $p->{rh} );
		}
		close $p->{rh};
		waitpid( $p->{pid}, 0 );
		my $exit = $? >> 8;
		croak "parallel_fit worker $p->{pid} exited with status $exit"
			if $exit != 0;
		my $trees = eval { Storable::thaw($buf) };
		croak "parallel_fit worker $p->{pid} returned unparseable trees: $@"
			if $@ || ref $trees ne 'ARRAY';
		push @all_trees, @$trees;
	} ## end for my $p (@procs)

	return \@all_trees;
} ## end sub _fit_trees_parallel

#-------------------------------------------------------------------------------
# C-accelerated fit(): builds $n_trees trees against $data (a subset or
# the full training set) via build_forest_xs, which does its own
# per-tree subsampling internally.  Random draws inside the C builder
# go through Drand01() -- the same generator Perl's rand() uses -- in
# the same call order _subsample/_build_tree used, so the returned
# trees are bit-identical to what the pure-Perl path would build from
# the same RNG state.  That's what lets fit() switch backends on the
# existing `use_c` knob instead of a new one.
#
# Args:
#   $data :: the prepared training set, an arrayref of feature-value
#            arrayrefs.  Packed into a flat double buffer here, so undef
#            cells are resolved through _pack_args.
#   $psi :: the per-tree sub-sample size from _resolve_geometry.
#   $limit :: the tree height limit from _resolve_geometry.
#   $n_trees :: how many trees to build.  A forked worker passes its own
#               share rather than the model's full n_trees.
#
# Returns: an arrayref of $n_trees trees in the nested arrayref layout
# _build_tree produces, so callers cannot tell which backend built them.
#
# Example:
#   $self->{trees} = $self->_build_forest_c( $train, 256, 8, 100 );
#-------------------------------------------------------------------------------
sub _build_forest_c {
	my ( $self, $data, $psi, $limit, $n_trees ) = @_;
	my $n        = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n * $nf * 8 );
	my ( $mode, $fill ) = $self->_pack_args;
	pack_input_xs( $data, $x_packed, $n, $nf, $mode, $fill );

	my $mode_flag = $self->{mode} eq 'extended' ? 1 : 0;
	my $ext_level = $self->{extension_level_used} // 0;

	my $trees = [];
	build_forest_xs( $x_packed, $n, $nf, $n_trees, $psi, $limit, $mode_flag, $ext_level, $trees );
	return $trees;
} ## end sub _build_forest_c

#-------------------------------------------------------------------------------
# OpenMP-parallel fit(): builds $n_trees trees across OpenMP threads (one
# tree per thread) via build_forest_openmp_xs.  Unlike _build_forest_c,
# random draws come from a thread-private PRNG seeded per tree index
# rather than Drand01() -- Perl's RNG state can't be shared safely
# across OpenMP threads -- so the resulting trees are NOT bit-identical
# to the use_c (serial) or pure-Perl paths for the same seed, though a
# fixed seed + n_trees still reproduce the same trees regardless of
# OMP_NUM_THREADS.  This is why it's gated by the separate, opt-in
# use_openmp_fit knob rather than reusing use_c/use_openmp.
#
# Only called from fit()'s non-forked branch.  _fit_trees_parallel's
# workers never call this, even when use_openmp_fit is on: a forked
# child starting its own OpenMP region after the parent process has
# used OpenMP for anything (this includes plain score_samples()) can
# hang -- see the comment above that branch for the fork()+libgomp
# hazard this avoids.
#
# build_forest_openmp_xs hands back three arrayrefs of per-tree packed
# buffers (the same SoA layout _pack_tree produces) instead of Perl tree
# structures -- that's how it avoids any Perl API call inside its
# parallel region.  _unpack_forest converts them back into the ordinary
# nested-arrayref tree shape so to_json/from_json/_rebuild_c_trees don't
# need to know this path exists.
#
# Args:
#   $data :: the prepared training set, an arrayref of feature-value
#            arrayrefs.  Packed into a flat double buffer here, so undef
#            cells are resolved through _pack_args.
#   $psi :: the per-tree sub-sample size from _resolve_geometry.
#   $limit :: the tree height limit from _resolve_geometry.
#   $n_trees :: how many trees to build.
#
# Returns: an arrayref of $n_trees trees in the same nested arrayref layout
# _build_forest_c returns -- identical in shape, though not in content, to
# what the other backends would have built for this seed.
#
# Example:
#   $self->{trees} = $self->_build_forest_openmp( $train, 256, 8, 100 );
#-------------------------------------------------------------------------------
sub _build_forest_openmp {
	my ( $self, $data, $psi, $limit, $n_trees ) = @_;
	my $n        = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n * $nf * 8 );
	my ( $mode, $fill ) = $self->_pack_args;
	pack_input_xs( $data, $x_packed, $n, $nf, $mode, $fill );

	my $mode_flag = $self->{mode} eq 'extended' ? 1 : 0;
	my $ext_level = $self->{extension_level_used} // 0;

	my ( @nodes, @idx, @val );
	build_forest_openmp_xs( $x_packed, $n, $nf, $n_trees, $psi, $limit,
		$mode_flag, $ext_level, \@nodes, \@idx, \@val, 1 );

	return _unpack_forest( \@nodes, \@idx, \@val );
} ## end sub _build_forest_openmp

# Inverse of _pack_tree's SoA layout: given one tree's packed node
# buffer plus the shared idx/val coefficient buffers, reconstructs the
# ordinary nested-arrayref tree structure _build_tree/_build_node_c
# produce.  li/ri fields hold the child's absolute node index, so this
# just follows them recursively from whatever index the caller says the
# root lives at.  NOTE: _pack_tree numbers nodes DFS pre-order (root at
# 0), but build_forest_openmp_xs appends nodes post-order (children
# before parent), putting the root LAST -- the caller must pass the
# right root index for the buffer's origin.
#
# Args:
#   $nodes :: arrayref of the tree's node doubles, already unpacked, 6 per
#             node.
#   $idx :: arrayref of the unpacked int32 coefficient feature indices.
#   $val :: arrayref of the unpacked coefficient values, matching $idx
#           one-for-one.
#   $node_i :: which node record to treat as this subtree's root, counting
#              in nodes not doubles.
#
# Returns: the subtree as a nested arrayref in _build_tree's layout.
#
# Example:
#   my $root = @nodes / 6 - 1;   # post-order buffer: root is last
#   my $tree = _unpack_node( \@nodes, \@idx, \@val, $root );
sub _unpack_node {
	my ( $nodes, $idx, $val, $node_i ) = @_;
	my $off  = $node_i * 6;
	my $type = $nodes->[$off];

	if ( $type == 0 ) {
		return [ _NODE_LEAF, int( $nodes->[ $off + 1 ] ) ];
	} elsif ( $type == 1 ) {
		my ( $attr, $split, $li, $ri )
			= @{$nodes}[ $off + 1 .. $off + 4 ];
		return [
			_NODE_AXIS, int($attr), $split,
			_unpack_node( $nodes, $idx, $val, int($li) ),
			_unpack_node( $nodes, $idx, $val, int($ri) ),
		];
	} else {
		my ( $coff, $num, $li, $ri, $b ) = @{$nodes}[ $off + 1 .. $off + 5 ];
		$coff = int($coff);
		$num  = int($num);
		return [
			_NODE_OBLIQUE,
			[ @{$idx}[ $coff .. $coff + $num - 1 ] ],
			[ @{$val}[ $coff .. $coff + $num - 1 ] ],
			$b,
			_unpack_node( $nodes, $idx, $val, int($li) ),
			_unpack_node( $nodes, $idx, $val, int($ri) ),
		];
	} ## end else [ if ( $type == 0 ) ]
} ## end sub _unpack_node

# Unpacks every tree in the three per-tree packed-buffer arrayrefs
# build_forest_openmp_xs returns into the ordinary nested tree shape.
# The C builder pushes nodes post-order (a node is recorded after both
# of its children), so each tree's root is the LAST node record, not
# index 0 as in _pack_tree's pre-order layout.
#
# Args:
#   $nodes_list :: arrayref of one packed 'd*' node buffer per tree.
#   $idx_list :: arrayref of one packed 'l*' coefficient index buffer per
#                tree, positionally matching $nodes_list.
#   $val_list :: arrayref of one packed 'd*' coefficient value buffer per
#                tree, positionally matching $nodes_list.
#
# Returns: an arrayref of trees in the nested arrayref layout, in the same
# order as the input buffers.
#
# Example:
#   build_forest_openmp_xs( ..., \@nodes, \@idx, \@val, 1 );
#   my $trees = _unpack_forest( \@nodes, \@idx, \@val );
sub _unpack_forest {
	my ( $nodes_list, $idx_list, $val_list ) = @_;
	my @trees;
	for my $i ( 0 .. $#$nodes_list ) {
		my @nodes = unpack( 'd*', $nodes_list->[$i] );
		my @idx   = unpack( 'l*', $idx_list->[$i] );
		my @val   = unpack( 'd*', $val_list->[$i] );
		my $root  = @nodes / 6 - 1;
		push @trees, _unpack_node( \@nodes, \@idx, \@val, $root );
	}
	return \@trees;
} ## end sub _unpack_forest

#-------------------------------------------------------------------------------
# Packed input wrapper.  pack_data() returns one of these so callers can
# score the same dataset many times without re-walking the AV/AV refs on
# every call -- a meaningful win at high feature counts where
# pack_input_xs is a non-trivial slice of total scoring time.
#
# It's a minimal blessed hashref: { packed, n_pts, n_feats }.  The C
# scoring functions only need the packed bytes + dimensions.
#-------------------------------------------------------------------------------
sub pack_data {
	my ( $self, $data ) = @_;
	$self->_check_fitted;
	croak "pack_data requires the Inline::C backend; install Inline::C"
		unless $self->{_use_c};
	croak "pack_data() expects an arrayref of samples"
		unless ref $data eq 'ARRAY';
	my $n_pts    = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n_pts * $nf * 8 );
	my ( $mode, $fill ) = $self->_pack_args;
	pack_input_xs( $data, $x_packed, $n_pts, $nf, $mode, $fill );
	return bless {
		packed  => $x_packed,
		n_pts   => $n_pts,
		n_feats => $nf,
		},
		'Algorithm::Classifier::IsolationForest::PackedData';
} ## end sub pack_data

# Internal helper: given $data that may be a raw arrayref OR a PackedData
# instance, return the triple ready for score_all_xs.  Called from every
# scoring fast path, which is what lets those methods accept either shape
# without each of them knowing about packing.
#
# Args:
#   $data :: either an arrayref of feature-value arrayrefs (packed here,
#            undef cells resolved through _pack_args) or a PackedData
#            instance from pack_data (used as-is, no repacking).
#
# Returns: the three-element list ($n_pts, $n_feats, $x_packed) -- the row
# count, the feature width and the row-major 'd*' buffer.  Croaks when a
# PackedData's width disagrees with the model's.
#
# Example:
#   my ( $n_pts, $nf, $x ) = $self->_resolve_input($data);
#   score_all_xs( $self->{_c_nodes}, ..., $x, $sums, $n_pts, $nf, ... );
sub _resolve_input {
	my ( $self, $data ) = @_;
	if ( ref $data eq 'Algorithm::Classifier::IsolationForest::PackedData' ) {
		croak "PackedData has $data->{n_feats} features but model expects " . $self->{n_features}
			unless $data->{n_feats} == $self->{n_features};
		return ( $data->{n_pts}, $data->{n_feats}, $data->{packed} );
	}
	my $n_pts    = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n_pts * $nf * 8 );
	my ( $mode, $fill ) = $self->_pack_args;
	pack_input_xs( $data, $x_packed, $n_pts, $nf, $mode, $fill );
	return ( $n_pts, $nf, $x_packed );
} ## end sub _resolve_input

# Helper used by the pure-Perl fallback paths: convert either form back
# to an arrayref-of-arrayrefs.  Slow on PackedData -- the whole point of
# packing is to keep things in C -- but lets the fallback path be
# uniformly arrayref-driven.
#
# Args:
#   $data :: either an arrayref of feature-value arrayrefs (returned
#            unchanged, not copied) or a PackedData instance (unpacked into
#            fresh rows).
#
# Returns: an arrayref of feature-value arrayrefs.  Rows unpacked from
# PackedData hold plain doubles, so a NaN packed for a missing cell comes
# back as NaN rather than undef.  Croaks on anything else.
#
# Example:
#   my $rows = $self->_to_arrayref($data);
#   _path_length( $rows->[0], $tree, 0, 0 );
sub _to_arrayref {
	my ( $self, $data ) = @_;
	return $data if ref $data eq 'ARRAY';
	if ( ref $data eq 'Algorithm::Classifier::IsolationForest::PackedData' ) {
		my $n_pts   = $data->{n_pts};
		my $nf      = $data->{n_feats};
		my @doubles = unpack( 'd*', $data->{packed} );
		my @rows;
		for my $i ( 0 .. $n_pts - 1 ) {
			push @rows, [ @doubles[ $i * $nf .. ( $i + 1 ) * $nf - 1 ] ];
		}
		return \@rows;
	} ## end if ( ref $data eq 'Algorithm::Classifier::IsolationForest::PackedData')
	croak "expected arrayref or PackedData, got " . ( ref($data) || 'scalar' );
} ## end sub _to_arrayref

# ---------------------------------------------------------------------------
# Missing-value handling.
#
# The `missing` strategy chosen at new() decides how undef feature cells are
# treated.  Scoring always tolerates undef; the strategy governs fit() and
# how undef is represented for the scorer:
#
#   die    -- croak from fit() if the training data holds any undef cell.
#             Scoring still maps undef -> 0 (the long-standing behaviour).
#   zero   -- undef counts as the value 0, at fit and score time.
#   impute -- undef is replaced by a learned per-feature mean/median; the
#             fill vector is stored on the model and reused at score time.
#   nan    -- ranges are built over present values only and a point missing
#             the split feature is routed to the right child, consistently
#             at fit (Perl) and score (C packs NaN; `<`/`<=` send it right).
# ---------------------------------------------------------------------------

# Returns the training data to actually build trees on, after applying the
# missing-value strategy.
#
# Args:
#   $data :: the caller's raw training set, an arrayref of feature-value
#            arrayrefs.  Never modified -- zero/impute build a copy rather
#            than densifying in place.
#
# Returns: the arrayref of rows to build trees from.  That is $data itself
# under die (already dense) and nan (undef is meaningful there), and a
# dense copy under zero/impute -- except on the C tree-building path, which
# fills from missing_fill itself and so also gets $data through unchanged.
# Under die it croaks instead, naming the first missing cell's row and
# column.  Under impute it also sets $self->{missing_fill}.
#
# Example:
#   my $train = $self->_prepare_fit_data($data);
#   my $tree  = $self->_build_tree( _subsample( $train, $psi ), 0, $limit );
sub _prepare_fit_data {
	my ( $self, $data ) = @_;
	my $m  = $self->{missing};
	my $nf = $self->{n_features};

	if ( $m eq 'die' ) {

		# Locate the first missing cell, then report it.  The scan is over
		# every cell of the training set, so with the C backend on it goes
		# through first_missing_xs -- same row-major order, same cell
		# reported, without the per-cell Perl loop overhead.  Both paths
		# read a row that is not an arrayref as missing at column 0, which
		# is how pack_input_xs treats one downstream.
		my $where = [];
		if ( $self->{_use_c} ) {
			first_missing_xs( $data, scalar @$data, $nf, $where );
		} else {
			my $i = 0;
			for my $row (@$data) {
				if ( ref $row ne 'ARRAY' ) { $where = [ $i, 0 ]; last }
				my $f = 0;
				$f++ while $f < $nf && defined $row->[$f];
				if ( $f < $nf ) { $where = [ $i, $f ]; last }
				$i++;
			}
		} ## end else [ if ( $self->{_use_c} ) ]
		croak "fit(): undef feature value at sample $where->[0], column $where->[1]; "
			. "construct with missing => 'zero', 'impute', or 'nan' "
			. "to train on data with missing values"
			if @$where;

		return $data;
	} ## end if ( $m eq 'die' )

	# nan: leave undef in place -- _build_tree / the split routers handle it.
	return $data if $m eq 'nan';

	# zero / impute: undef has to become a real number somewhere before a
	# split can look at it.  The fill vector is computed either way (it's
	# needed for persistence and for scoring later), but densifying $data
	# into a second, fully separate Perl array here is only necessary for
	# the pure-Perl tree builder (_build_tree assumes every cell is
	# defined once missing != 'nan' -- see its lo/hi scan).  The C
	# tree-building path -- _build_forest_c/_build_forest_openmp, and
	# every parallel_fit worker, all of which go through pack_input_xs --
	# already fills undef cells itself from this same fill vector, so
	# skip the redundant whole-dataset copy when that's the path fit()
	# will actually take.  Scoring the training set for a learned
	# contamination threshold (below, in fit()) is unaffected: it always
	# runs through the pure-Perl scorer regardless of use_c (fit() drops
	# any previous fit's packed buffers before that scoring, and
	# _rebuild_c_trees runs after), and that path already tolerates raw
	# undef cells
	# for both zero (_path_length's "// 0") and impute (_prepare_perl_input
	# densifies on demand from missing_fill).
	my $fill
		= $m eq 'impute'
		? $self->_compute_impute_fill($data)
		: [ (0) x $nf ];
	$self->{missing_fill} = $fill if $m eq 'impute';
	delete $self->{_fill_packed};

	return $data if $self->{_use_c};
	return _densify( $data, $fill );
} ## end sub _prepare_fit_data

# Per-feature fill value (mean or median of the present values) for impute
# mode.  Croaks if a feature has no present value to learn from.  The
# optional $how_override selects the statistic independently of the
# model's impute_with knob (used by _compute_feature_baselines, which
# always wants the median).
#
# Args:
#   $data :: the rows to learn from, an arrayref of feature-value
#            arrayrefs.  undef cells are skipped rather than counted.
#   $how_override :: 'mean' or 'median' to force the statistic, or undef to
#                    follow the model's impute_with.
#
# Returns: an arrayref of n_features fill values.  Croaks naming the column
# when a feature has no present value anywhere in $data.
#
# Example:
#   $self->_compute_impute_fill( \@rows );              # per impute_with
#   $self->_compute_impute_fill( \@rows, 'median' );    # forced median
sub _compute_impute_fill {
	my ( $self, $data, $how_override ) = @_;
	my $nf  = $self->{n_features};
	my $how = $how_override // $self->{impute_with};

	# C fast path: walks the raw data directly and finds the median via
	# quickselect (O(n) average) instead of the Perl fallback's full sort
	# (O(n log n)).  Produces the same fill values either way -- see
	# impute_fill_xs's file-top comment -- so use_c only changes speed
	# here, matching the rest of the module.
	if ( $self->{_use_c} ) {
		my $n        = scalar @$data;
		my $how_flag = $how eq 'median' ? 1 : 0;
		my $fill     = [];
		impute_fill_xs( $data, $n, $nf, $how_flag, $fill );
		return $fill;
	}

	my @fill;
	for my $f ( 0 .. $nf - 1 ) {
		my @vals = grep { defined } map { $_->[$f] } @$data;
		croak "impute: feature column $f has no present values"
			unless @vals;
		if ( $how eq 'median' ) {
			my @s = sort { $a <=> $b } @vals;
			my $k = scalar @s;
			$fill[$f]
				= $k % 2
				? $s[ int( $k / 2 ) ]
				: ( $s[ $k / 2 - 1 ] + $s[ $k / 2 ] ) / 2.0;
		} else {    # mean
			my $sum = 0;
			if (_NV_IS_DOUBLE) {
				$sum += $_ for @vals;
			} else {
				# impute_fill_xs accumulates the sum in double (over
				# SvNV-truncated cells); match its rounding step for step.
				$sum = _to_double( $sum + _to_double($_) ) for @vals;
			}
			$fill[$f] = $sum / scalar @vals;
		} ## end else [ if ( $how eq 'median' ) ]

		# The fill crosses into the C backend as a double (pack 'd' /
		# SvNV), so on wide-NV perls store it already narrowed and both
		# builders densify with the identical value.
		$fill[$f] = _to_double( $fill[$f] ) unless _NV_IS_DOUBLE;
	} ## end for my $f ( 0 .. $nf - 1 )
	return \@fill;
} ## end sub _compute_impute_fill

# Per-feature median of the present values of the training data -- the
# "typical row" that ablation explanations (explain_samples with
# method => 'ablation') substitute against, one feature at a time.
# Always the median (not impute_with's statistic): a baseline should be
# a robustly central value, and outliers in the training data drag a
# mean around far more than a median.
#
# Computed from the RAW rows, never a densified copy, so the stored
# baselines are identical whether use_c is on or off (the pure-Perl fit
# path densifies $train before the trees are built; the C path does
# not).  A column with no present value at all -- legal under
# missing => 'zero'/'nan' -- cannot yield a median, so the fast path's
# croak falls back to a tolerant pure-Perl pass that gives such columns
# the fill value scoring maps their undefs to anyway (0).
#
# Args:
#   $data :: the raw training rows, an arrayref of feature-value
#            arrayrefs.  Must be the caller's data, never a densified copy.
#
# Returns: an arrayref of n_features medians.  A column with no present
# value at all gets 0 rather than causing a croak.
#
# Example:
#   $self->{feature_baselines} = $self->_compute_feature_baselines($data);
#   # later: explain_samples( \@rows, method => 'ablation' )
sub _compute_feature_baselines {
	my ( $self, $data ) = @_;
	my $baselines = eval { $self->_compute_impute_fill( $data, 'median' ) };
	return $baselines if ref $baselines eq 'ARRAY';

	my $nf = $self->{n_features};
	my @fallback;
	for my $f ( 0 .. $nf - 1 ) {
		my @vals = sort { $a <=> $b } grep { defined } map { $_->[$f] } @$data;
		my $k    = scalar @vals;
		if ( $k == 0 ) {
			$fallback[$f] = 0;
			next;
		}
		$fallback[$f]
			= $k % 2
			? $vals[ int( $k / 2 ) ]
			: ( $vals[ $k / 2 - 1 ] + $vals[ $k / 2 ] ) / 2.0;
		$fallback[$f] = _to_double( $fallback[$f] ) unless _NV_IS_DOUBLE;
	} ## end for my $f ( 0 .. $nf - 1 )
	return \@fallback;
} ## end sub _compute_feature_baselines

# Return a dense copy of $data with every undef cell replaced by the
# matching per-feature fill value.  Leaves present cells untouched.
#
# Args:
#   $data :: the rows to densify, an arrayref of feature-value arrayrefs.
#            Never modified.
#   $fill :: the per-feature fill values, an arrayref.  Its length fixes
#            the output width, so a row longer than $fill is truncated and
#            a shorter one padded.
#
# Returns: a fresh arrayref of fresh rows -- nothing is shared with $data,
# so the caller may mutate either independently.
#
# Example:
#   _densify( [ [ 0.9, undef ] ], [ 0, 0.5 ] );   # [ [ 0.9, 0.5 ] ]
sub _densify {
	my ( $data, $fill ) = @_;
	my $nf = scalar @$fill;
	return [
		map {
			my $r = $_;
			[ map { defined $r->[$_] ? $r->[$_] : $fill->[$_] } 0 .. $nf - 1 ]
		} @$data
	];
} ## end sub _densify

# (miss_mode, fill_packed) pair for pack_input_xs, per the active strategy.
# die/zero -> 0 (undef becomes 0.0); impute -> 1 (undef becomes fill[k]);
# nan -> 2 (undef becomes NaN, which the C scorer routes right).
#
# Args: none beyond the model itself.
#
# Returns: the two-element list ($miss_mode, $fill_packed) -- the mode flag
# above, and a 'd*' string of the per-feature fills under impute or the
# empty string otherwise.  The packed fill is memoised in _fill_packed, so
# repeated scoring calls pack it once.  Croaks when an impute model has
# lost its fill vector.
#
# Example:
#   my ( $mode, $fill ) = $self->_pack_args;
#   pack_input_xs( $data, $x_packed, $n_pts, $nf, $mode, $fill );
sub _pack_args {
	my ($self) = @_;
	my $m = $self->{missing};
	return ( 2, '' ) if $m eq 'nan';
	if ( $m eq 'impute' ) {
		my $fill = $self->{missing_fill};
		croak "impute model is missing its fill vector"
			unless ref $fill eq 'ARRAY' && @$fill == $self->{n_features};
		$self->{_fill_packed} //= pack( 'd*', @$fill );
		return ( 1, $self->{_fill_packed} );
	}
	return ( 0, '' );    # die, zero
} ## end sub _pack_args

# Pure-Perl fallback input prep: arrayref-ify, then fill for impute so the
# tree walk sees dense rows.  zero/die rely on _path_length's "// 0"; nan
# keeps undef in place for _path_length to route.
#
# Args:
#   $data :: either an arrayref of feature-value arrayrefs or a PackedData
#            instance -- _to_arrayref normalises it either way.
#
# Returns: an arrayref of rows ready for _path_length.  Under impute these
# are a fresh dense copy; otherwise the rows are handed back as they came,
# so the caller must not mutate them.  The nan flag is NOT part of this --
# callers pass it to _path_length themselves.  Croaks when an impute model
# has lost its fill vector.
#
# Example:
#   my $rows = $self->_prepare_perl_input($data);
#   my $nan  = $self->{missing} eq 'nan' ? 1 : 0;
#   _path_length( $rows->[0], $tree, 0, $nan );
sub _prepare_perl_input {
	my ( $self, $data ) = @_;
	my $rows = $self->_to_arrayref($data);
	if ( $self->{missing} eq 'impute' ) {
		croak "impute model is missing its fill vector"
			unless ref $self->{missing_fill} eq 'ARRAY';
		$rows = _densify( $rows, $self->{missing_fill} );
	}
	return $rows;
} ## end sub _prepare_perl_input

# Minimal PackedData package: opaque token returned by pack_data().  The
# scoring methods recognise it and hand its buffer straight to the C
# scorer; the two accessors exist so callers holding one can still ask
# what is in it without unpacking.
{

	package Algorithm::Classifier::IsolationForest::PackedData;

	# How many samples the buffer holds.
	#
	# Args: none.
	#
	# Returns: the row count as an integer, fixed when pack_data built the
	# object.
	#
	# Example:
	#   my $packed = $iforest->pack_data(\@data);
	#   $packed->n_pts;     # scalar @data
	sub n_pts { $_[0]->{n_pts} }

	# How wide each packed sample is.
	#
	# Args: none.
	#
	# Returns: the feature count as an integer, always the n_features of
	# the model that packed the data.
	#
	# Example:
	#   $packed->n_feats;   # 2 for two-feature rows
	sub n_feats { $_[0]->{n_feats} }
}

1;
