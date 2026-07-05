package Algorithm::Classifier::IsolationForest;

use strict;
use warnings;
use Carp        qw(croak);
use Config      ();
use List::Util  qw(min);
use POSIX       qw(ceil);
use JSON::PP    ();
use File::Slurp qw(read_file write_file);

our $VERSION = '0.5.0';

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

psi referenced below is ψ or the pitchfork math symbol referenced in the paper,
Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

... or max samples.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

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
		n_trees         => $args{n_trees}     // 100,
		sample_size     => $args{sample_size} // 256,
		max_depth       => $args{max_depth},          # undef => auto
		seed            => $args{seed},               # undef => non-deterministic
		mode            => $mode,
		extension_level => $args{extension_level},    # undef => max, resolved in fit()
		contamination   => $args{contamination},      # undef => no learned threshold
		parallel_fit    => $args{parallel_fit},       # undef/0/1 => serial; N>1 => fork
		missing         => $missing,                  # die|zero|impute|nan
		impute_with     => $impute_with,              # mean|median (impute mode only)
		voting          => $voting,                   # mean|majority (scoring-time aggregation)
		missing_fill    => undef,                     # per-feature fill, learned in fit() if impute
		_use_c          => $use_c,
		_use_openmp     => $use_openmp,
		_use_openmp_fit => $use_openmp_fit,
		threshold       => undef,                     # learned in fit() if contamination set
		trees           => [],
		c_psi           => undef,                     # c(psi), set during fit()
		n_features      => undef,
		feature_names   => $args{feature_names},      # optional arrayref of per-feature labels
	};

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

	my $n = scalar @$train;

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
			n_trees         => $self->{n_trees},
			sample_size     => $self->{sample_size},
			mode            => $self->{mode},
			extension_level => $self->{extension_level_used},
			contamination   => $self->{contamination},
			threshold       => $self->{threshold},
			n_features      => $self->{n_features},
			psi_used        => $self->{psi_used},
			c_psi           => $self->{c_psi},
			max_depth_used  => $self->{max_depth_used},
			missing         => $self->{missing},
			impute_with     => $self->{impute_with},
			missing_fill    => $self->{missing_fill},
			feature_names   => $self->{feature_names},
			voting          => $self->{voting},
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
		&& defined $payload->{format}
		&& $payload->{format} eq 'Algorithm::Classifier::IsolationForest';

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
		missing       => $p->{missing}     // 'zero',
		impute_with   => $p->{impute_with} // 'mean',
		missing_fill  => $p->{missing_fill},
		feature_names => $p->{feature_names},
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

=head1 REFERENCES

Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

L<https://ieeexplore.ieee.org/abstract/document/4781136>

Sahand Hariri, Matias Carrasco Kind, Robert J. Brunner (2020). Extended Isolation Forest. 1479 - 1489. 10.1109/TKDE.2019.2947676

L<https://ieeexplore.ieee.org/document/8888179>

Yousra Chabchoub, Maurras Ulbricht Togbe, Aliou Boly, Raja Chiky (2022). An In-Depth Study and Improvement of Isolation Forest. IEEE Access, vol. 10, 10219 - 10237. 10.1109/ACCESS.2022.3144425 (the Majority Voting Isolation Forest implemented by C<< voting => 'majority' >>)

L<https://ieeexplore.ieee.org/document/9684896>

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
sub _depth_cut {
	my ( $theta, $c ) = @_;
	return ( $theta <= 0.5 ? 9**9**9 : -1.0 ) if $c <= 0;
	return 9**9**9                            if $theta <= 0;
	return -$c * log($theta) / log(2);
}

# Smallest number of per-tree anomaly votes that constitutes a majority:
# int(t/2) + 1, i.e. strictly more than half the trees for both odd and
# even tree counts (the paper's "t/2 + 1").
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
#-------------------------------------------------------------------------------
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
# Draw $k samples without replacement via a partial Fisher-Yates shuffle of the
# index array. Returns an arrayref of (shared, read-only) sample refs.
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
# Returns [_NODE_AXIS, attr, split, \@left_pts, \@right_pts].
# _build_tree overwrites slots 3 and 4 with the recursed subtrees.
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
# Returns [_NODE_OBLIQUE, \@idx, \@coef, $b, \@left_pts, \@right_pts].
# _build_tree overwrites slots 4 and 5 with the recursed subtrees.
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

# Recursively convert a version-0 hash-based tree node to the version-1
# array format.  Called by from_json when loading an old saved model.
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
# ---------------------------------------------------------------------------
sub _pack_tree {
	my ( $root, $n_features ) = @_;
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

sub _check_fitted {
	my ($self) = @_;
	croak "model is not fitted yet; call fit() first"
		unless ref $self->{trees} eq 'ARRAY' && @{ $self->{trees} };
}

# Memoised "does this perl have a real fork()?".  False on Windows
# without Cygwin; true on every Unix-like platform.
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
# instance, return the (n_pts, n_feats, x_packed) triple ready for
# score_all_xs.  Called from every scoring fast path.
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
# missing-value strategy.  May croak (die), return a dense filled copy
# (zero/impute), or pass $data through unchanged (nan).
sub _prepare_fit_data {
	my ( $self, $data ) = @_;
	my $m  = $self->{missing};
	my $nf = $self->{n_features};

	if ( $m eq 'die' ) {
		for my $i ( 0 .. $#$data ) {
			my $row = $data->[$i];
			for my $f ( 0 .. $nf - 1 ) {
				next if defined $row->[$f];
				croak "fit(): undef feature value at sample $i, column $f; "
					. "construct with missing => 'zero', 'impute', or 'nan' "
					. "to train on data with missing values";
			}
		}
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
# mode.  Croaks if a feature has no present value to learn from.
sub _compute_impute_fill {
	my ( $self, $data ) = @_;
	my $nf  = $self->{n_features};
	my $how = $self->{impute_with};

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

# Return a dense copy of $data with every undef cell replaced by the
# matching per-feature fill value.  Leaves present cells untouched.
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
# keeps undef in place for _path_length to route.  Returns the rows; the
# caller passes the nan flag to _path_length separately.
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

# Minimal PackedData package: opaque token returned by pack_data().
# Exposes n_pts and n_feats accessors for users who want to introspect.
{

	package Algorithm::Classifier::IsolationForest::PackedData;
	sub n_pts   { $_[0]->{n_pts} }
	sub n_feats { $_[0]->{n_feats} }
}

1;
