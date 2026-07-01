package Algorithm::Classifier::IsolationForest;

use strict;
use warnings;
use Carp        qw(croak);
use List::Util  qw(min);
use POSIX       qw(ceil);
use JSON::PP    ();
use File::Slurp qw(read_file write_file);

our $VERSION = '0.2.1';

use constant EULER  => 0.5772156649015329;
use constant TWO_PI => 6.283185307179586;

# Node-type tags stored in index 0 of every tree node arrayref.
# 0 is falsy, so  while ($node->[0])  acts as  while (!leaf).
use constant _NODE_LEAF    => 0;
use constant _NODE_AXIS    => 1;
use constant _NODE_OBLIQUE => 2;

# ---------------------------------------------------------------------------
# Optional Inline::C accelerator for the scoring hot path.
#
# pack_input_xs(data_sv, out_sv, n_pts, n_feats)
#     Walks the Perl arrayref-of-arrayrefs and writes a packed double buffer
#     into out_sv.  Replaces the dominant per-call Perl map-pack loop.
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
# Node layout (6 doubles per node, "IF_NZ = 6"):
#   leaf:    [0, size, 0,   0,  0, 0]
#   axis:    [1, attr, split, li, ri, 0]
#   oblique: [2, coff, nf,  li, ri, b]
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
{
    my $C_CODE = <<'__INLINE_C__';
#include <math.h>
#ifdef _OPENMP
#include <omp.h>
#endif
#define IF_NZ 6
static double _ifc(double n){
    if(n<=1.0)return 0.0;
    if(n<2.5) return 1.0;
    double h=log(n-1.0)+0.5772156649015329;
    return 2.0*h-2.0*(n-1.0)/n;
}

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

/* pack_input_xs(data_sv, out_sv, n_pts, n_feats)
 *
 * Walks a Perl arrayref-of-arrayrefs (n_pts rows of n_feats doubles each)
 * directly in C and writes the packed double buffer into out_sv (which the
 * caller pre-allocates with "\0" x (n_pts*n_feats*8)).  Replaces
 *
 *   pack('d*', map { my $r=$_; map { $r->[$_] // 0 } 0..$nf-1 } @$data)
 *
 * which was the dominant per-call overhead for high feature counts.
 * Undef cells (and missing rows) are coerced to 0.0 with no warning. */
void pack_input_xs(SV* data_sv, SV* out_sv, int n_pts, int n_feats){
    STRLEN tl;
    double* out;
    AV* outer;
    int i, k;

    if (!SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
        croak("pack_input_xs: data must be an arrayref");
    }
    outer = (AV*)SvRV(data_sv);
    out   = (double*)SvPVbyte_force(out_sv, tl);

    for (i = 0; i < n_pts; i++) {
        SV** row_pp = av_fetch(outer, i, 0);
        double* dst = out + (size_t)i * (size_t)n_feats;
        if (!row_pp || !*row_pp || !SvROK(*row_pp) ||
            SvTYPE(SvRV(*row_pp)) != SVt_PVAV) {
            for (k = 0; k < n_feats; k++) dst[k] = 0.0;
            continue;
        }
        {
            AV* row = (AV*)SvRV(*row_pp);
            for (k = 0; k < n_feats; k++) {
                SV** v = av_fetch(row, k, 0);
                if (v && *v && SvOK(*v)) {
                    dst[k] = SvNV(*v);
                } else {
                    dst[k] = 0.0;
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

/* score_all_xs(nodes_av, idx_av, val_av, x_sv, sm_sv,
 *              n_pts, n_feats, n_trees, use_openmp)
 *
 * Scores all points across all trees in one C call.  See header comment
 * above for the bigger picture.  Writes sm[i] = sum_over_trees(path_len),
 * not accumulating, so the caller need not zero-init sm.
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

    for (ti = 0; ti < n_trees; ti++) {
        SV** np = av_fetch(nodes_av, ti, 0);
        SV** ip = av_fetch(idx_av,   ti, 0);
        SV** vp = av_fetch(val_av,   ti, 0);
        if (!np || !*np || !ip || !*ip || !vp || !*vp) {
            croak("score_all_xs: missing tree %d", ti);
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
    /* Invariant: every feature index stored in a tree node is in
     * [0, n_feats).  fit() builds trees against n_features columns and
     * pack_input_xs writes exactly that many doubles per row, and
     * _resolve_input rejects PackedData with a mismatched feature
     * count.  So the inner loop can omit per-iteration bounds checks
     * on attr / fi -- this is what lets the oblique dot product
     * vectorize cleanly under the omp-simd reduction below. */
    for (int i = 0; i < n_pts; i++) {
        double sum = 0.0;
        const double *xi = xd + (size_t)i * (size_t)n_feats;
        for (int t = 0; t < n_trees; t++) {
            const double *nd  = node_ptrs[t];
            const int    *ico = idx_ptrs[t];
            const double *vco = val_ptrs[t];
            int ni = 0, depth = 0;
            for (;;) {
                const double *node = nd + (size_t)ni * IF_NZ;
                int type = (int)node[0];
                if (type == 0) {
                    sum += depth + _ifc(node[1]);
                    break;
                }
                if (type == 1) {
                    double fv = xi[(int)node[1]];
                    ni = (fv < node[2]) ? (int)node[3] : (int)node[4];
                } else {
                    int coff = (int)node[1], nf = (int)node[2];
                    double b = node[5], dot = 0.0;
                    const double *val_p = vco + (size_t)coff;
                    if (nf == n_feats) {
                        /* Dense oblique split: this node uses every
                         * feature, so _pack_tree laid the coefficients
                         * out in feature order.  No gather -- the
                         * inner loop is a textbook FMA-vectorizable
                         * dot product over two contiguous double
                         * streams.  Common case in extended mode at
                         * the default extension_level (== n_feats-1). */
                        #ifdef _OPENMP
                        #pragma omp simd reduction(+:dot)
                        #endif
                        for (int k = 0; k < n_feats; k++) {
                            dot += val_p[k] * xi[k];
                        }
                    } else {
                        /* Sparse oblique split: only nf < n_feats
                         * features participate, so we still need the
                         * gather on xi[idx_p[k]].  Storing idx as
                         * contiguous int32 (rather than interleaved
                         * doubles) keeps the gather pattern clean and
                         * the val[] load contiguous. */
                        const int *idx_p = ico + (size_t)coff;
                        #ifdef _OPENMP
                        #pragma omp simd reduction(+:dot)
                        #endif
                        for (int k = 0; k < nf; k++) {
                            dot += val_p[k] * xi[idx_p[k]];
                        }
                    }
                    ni = (dot <= b) ? (int)node[3] : (int)node[4];
                }
                depth++;
            }
        }
        sm[i] = sum;
    }
}
__INLINE_C__

    # -O3 is safe to enable unconditionally and matters here: the
    # extended-mode oblique dot product is wrapped in `#pragma omp simd`,
    # but without aggressive optimization the compiler may still emit
    # scalar code.  Use OPTIMIZE (not CCFLAGS) -- CCFLAGS is prepended
    # to the cc line and would be shadowed by Perl's own `-O2 -g` that
    # ExtUtils::MakeMaker appends afterward (last `-O` wins in gcc).
    #
    # -march=native lets the compiler pick AVX2 gather + FMA tuned to
    # the build host; it's opt-in via IF_NATIVE=1 because the cached
    # artefact under _Inline/ would otherwise refuse to run on a CPU
    # without the same instruction set extensions.
    my $opt_level = '-O3';
    $opt_level .= ' -march=native' if $ENV{IF_NATIVE};

    # Inline::C hashes the C source to decide whether to rebuild but
    # does NOT include CCFLAGS / OPTIMIZE in that hash.  Without the
    # tag below, toggling IF_NATIVE (or editing the optimisation flags
    # here) would silently reuse a cached binary built with stale
    # flags.  Embedding the active flags as a leading comment forces
    # the hash to differ when they change.  The OpenMP and serial
    # builds get distinct tags so they cache to separate artefacts.
    my $omp_tag    = "/* if_build: openmp $opt_level */\n";
    my $serial_tag = "/* if_build: serial $opt_level */\n";

    # Try compiling with OpenMP first; on any failure (compiler doesn't
    # accept -fopenmp, libgomp missing, etc.) fall back to a serial build.
    {
        local $@;
        eval {
            require Inline;
            Inline->import(
                C        => $omp_tag . $C_CODE,
                CCFLAGS  => '-fopenmp',
                OPTIMIZE => $opt_level,
                LIBS     => '-lm -lgomp',
            );
            $HAS_C = 1;
        };
    }
    unless ($HAS_C) {
        local $@;
        eval {
            require Inline;
            Inline->import(
                C        => $serial_tag . $C_CODE,
                OPTIMIZE => $opt_level,
                LIBS     => '-lm',
            );
            $HAS_C = 1;
        };
    }
    $HAS_OPENMP = ( $HAS_C && defined &has_openmp_xs && has_openmp_xs() )
        ? 1 : 0;
    $HAS_SIMD = ( $HAS_C && defined &has_simd_xs && has_simd_xs() )
        ? 1 : 0;
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
    my $eif = IsolationForest->new(mode => 'extended', seed => 42);
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

psi refernced below is ψ or the pitchfork math symbol refrenced in paper,
Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

... or max samples.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

=head1 NATIVE ACCELERATION (Inline::C and OpenMP)

The scoring hot path (C<score_samples>, C<predict>, C<path_lengths>,
C<score_predict_samples>, and C<score_predict_split>) is automatically
accelerated through
L<Inline::C> when it is installed and a working C compiler is reachable.
If the toolchain also accepts C<-fopenmp> and can link against
C<libgomp>, the per-point tree walk runs in parallel across all
available CPU cores using OpenMP, and the extended-mode oblique dot
product is vectorised via C<#pragma omp simd> -- which on modern x86
compilers translates to an unrolled FMA / AVX gather chain that's
substantially faster for high-feature-count extended models.

Detection happens once when the module is loaded; the compiled artefact
is cached under C<_Inline/> and reused on subsequent runs.  Three
package variables report what the build picked up:

    $Algorithm::Classifier::IsolationForest::HAS_C       # 0/1
    $Algorithm::Classifier::IsolationForest::HAS_OPENMP  # 0/1
    $Algorithm::Classifier::IsolationForest::HAS_SIMD    # 0/1 (OpenMP 4.0+)

Neither dependency is required.  Without C<Inline::C> the module falls
back to a pure-Perl implementation that produces identical results, just
slower; without OpenMP the C backend runs single-threaded.

The bundled C<iforest accel> subcommand performs a tiny fit + score and
prints which backend is active, which is the recommended way to verify
the build picked up the optional dependencies on a given machine.

The C backend is compiled with C<-O3> by default.  Set the environment
variable C<IF_NATIVE=1> before first load to add C<-march=native>, which
lets the compiler emit AVX2/AVX-512 gather and FMA instructions tuned
to the build host.  This typically gives a meaningful speedup on the
extended-mode oblique dot product at high feature counts.  The cached
artefact under C<_Inline/> is pinned to the host CPU, so leave
C<IF_NATIVE> unset if the directory is shared across machines with
different instruction-set support.

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

    - parallel_fit :: positive integer N => build the trees across N forked
          worker processes during fit(). Each worker gets a derived seed
          (parent seed + worker_id * 1009) so the parallel fit is
          reproducible across runs at fixed worker count -- but the trees
          produced are NOT bit-identical to a serial fit with the same
          seed, because the RNG draws happen in a different order.
          Inference is unaffected. Falls back silently to serial on
          platforms without a real fork() (e.g. Windows without Cygwin).
        default :: undef (serial)

    - use_c :: boolean, override whether the Inline::C scoring backend is
          used.  When false the instance falls back to pure Perl even if
          the C backend compiled successfully.  When true (or unset) the
          C backend is used if available ($HAS_C).
        default :: $HAS_C

    - use_openmp :: boolean, override whether OpenMP parallel scoring is
          used inside score_all_xs().  When false the C tree walk runs
          single-threaded even if OpenMP was linked in.  Ignored when
          use_c is false (pure Perl has no OpenMP path).
        default :: $HAS_OPENMP

Note: log2 under Perl is as below...

    log($psi) / log(2)

=cut

sub new {
	my ( $class, %args ) = @_;

	my $mode = $args{mode} // 'axis';
	croak "mode must be 'axis' or 'extended'"
		unless $mode eq 'axis' || $mode eq 'extended';

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

	my $self = {
		n_trees         => $args{n_trees}     // 100,
		sample_size     => $args{sample_size} // 256,
		max_depth       => $args{max_depth},          # undef => auto
		seed            => $args{seed},               # undef => non-deterministic
		mode            => $mode,
		extension_level => $args{extension_level},    # undef => max, resolved in fit()
		contamination   => $args{contamination},      # undef => no learned threshold
		parallel_fit    => $args{parallel_fit},       # undef/0/1 => serial; N>1 => fork
		_use_c          => $use_c,
		_use_openmp     => $use_openmp,
		threshold       => undef,                     # learned in fit() if contamination set
		trees           => [],
		c_psi           => undef,                     # c(psi), set during fit()
		n_features      => undef,
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

Below shows a example of building a gausing cluster and using that for training.

    # so it is reproducible
    srand(7);

    # build a gaussian cluster and add a handful out outliers...

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

    $iforest->fit(\@training_data);

=cut

sub fit {
	my ( $self, $data ) = @_;

	croak "fit() expects a non-empty arrayref of samples"
		unless ref $data eq 'ARRAY' && @$data;
	croak "each sample must be an arrayref of features"
		unless ref $data->[0] eq 'ARRAY' && @{ $data->[0] };

	my $n          = scalar @$data;
	my $n_features = scalar @{ $data->[0] };
	$self->{n_features} = $n_features;

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
		$self->{trees}
			= $self->_fit_trees_parallel( $data, $psi, $limit, $workers );
	}
	else {
		my @trees;
		for ( 1 .. $self->{n_trees} ) {
			my $sample = _subsample( $data, $psi );
			push @trees, $self->_build_tree( $sample, 0, $limit );
		}
		$self->{trees} = \@trees;
	}

	# If a contamination rate was requested, learn the score cutoff that flags
	# that fraction of the training set. We place the threshold midway between
	# the k-th and (k+1)-th highest training scores, so it sits in the gap
	# between flagged and unflagged points -- unambiguous and robust to the
	# tiny float rounding introduced by JSON serialisation.
	if ( defined $self->{contamination} ) {
		my $scores = $self->score_samples($data);
		my @desc   = sort { $b <=> $a } @$scores;
		my $n_pts  = scalar @desc;
		my $k      = int( $self->{contamination} * $n_pts + 0.5 );
		$k                 = 1      if $k < 1;
		$k                 = $n_pts if $k > $n_pts;
		$self->{threshold} = $k < $n_pts
			? ( $desc[ $k - 1 ] + $desc[$k] ) / 2.0    # midpoint of the boundary
			: $desc[ $n_pts - 1 ] - 1e-9;              # k == n: flag everything
	} ## end if ( defined $self->{contamination} )

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

Returns the mean isolation depth per sample, for inspection.

    my @lenghts = $forest->path_lengths(\@data);

    print "x, y, length\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$lenghts[$int]."\n";

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
		score_all_xs( $self->{_c_nodes},
			$self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed, $sums_packed, $n_pts, $nf, $t,
			$self->{_use_openmp} );
		my $result = [];
		finalize_path_lengths_xs( $sums_packed, $n_pts, $t + 0.0, $result );
		return $result;
	}

	$data = $self->_to_arrayref($data);

	# Pure-Perl fallback (tree-outer, sample-inner for cache locality).
	my @sums = (0) x @$data;
	for my $tree (@$trees) {
		for my $i ( 0 .. $#$data ) {
			$sums[$i] += _path_length( $data->[$i], $tree, 0 );
		}
	}
	return [ map { $_ / $t } @sums ];
} ## end sub path_lengths

=head2 predict(\@data, $threshold)

Returns an arrayref of 0/1 labels for the specified data.

If theshold is not specified it uses whatever the set default.

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
		score_all_xs( $self->{_c_nodes},
			$self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed, $sums_packed, $n_pts, $nf, $t,
			$self->{_use_openmp} );
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $result        = [];
		predict_sums_xs( $sums_packed, $n_pts, $sum_threshold, $result );
		return $result;
	}

	# Fallback: edge thresholds, c==0, or no C backend.
	my $scores = $self->score_samples( $self->_to_arrayref($data) );
	return [ map { $_ >= $threshold ? 1 : 0 } @$scores ];
}

=head2 score_samples(\@data)

Returns an arrayref of anomaly scores, between 0 and 1.

Scores near 1 are strong anomalies (isolated quickly).

Scores well below 0.5 are normal.

Scores ~0.5 means the points are hard to tell apart.

    my $scores = $forest->path_lengths(\@data);

    print "x, y, length\n";

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

	if ( $self->{_use_c} && $self->{_c_nodes} ) {
		my ( $n_pts, $nf, $x_packed ) = $self->_resolve_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		score_all_xs( $self->{_c_nodes},
			$self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed, $sums_packed, $n_pts, $nf, $t,
			$self->{_use_openmp} );
		if ( $c > 0 ) {
			my $inv    = log(2) / ( $c * $t );
			my $result = [];
			finalize_scores_xs( $sums_packed, $n_pts, $inv, $result );
			return $result;
		}
		return [ (0.5) x $n_pts ];
	}

	$data = $self->_to_arrayref($data);

	# Pure-Perl fallback (tree-outer, sample-inner for cache locality).
	my @sums = (0) x @$data;
	for my $tree (@$trees) {
		for my $i ( 0 .. $#$data ) {
			$sums[$i] += _path_length( $data->[$i], $tree, 0 );
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

=head2 score_predict_samples

Returns a array ref of arrays. First value of each sub array is the score with the second being
0/1 for if it is a anomaly or not.

    my $results = $forest->predict(\@data, $threshold);

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
		score_all_xs( $self->{_c_nodes},
			$self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed, $sums_packed, $n_pts, $nf, $t,
			$self->{_use_openmp} );
		my $inv           = log(2) / ( $c * $t );
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $result        = [];
		score_predict_xs( $sums_packed, $n_pts, $inv, $sum_threshold,
			$result );
		return $result;
	}

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
		score_all_xs( $self->{_c_nodes},
			$self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed, $sums_packed, $n_pts, $nf, $t,
			$self->{_use_openmp} );
		my $inv           = log(2) / ( $c * $t );
		my $sum_threshold = -log($threshold) * $c * $t / log(2);
		my $scores        = [];
		my $labels        = [];
		score_predict_split_xs( $sums_packed, $n_pts, $inv, $sum_threshold,
			$scores, $labels );
		return ( $scores, $labels );
	}

	# Fallback: derive from score_samples.
	my $scores = $self->score_samples( $self->_to_arrayref($data) );
	my @labels = map { $_ >= $threshold ? 1 : 0 } @$scores;
	return ( $scores, \@labels );
}

=head1 MODEL SAVE/LOAD METHODS

=head2 to_json

Returns a JSON representation of the module.

Required being fit having to be called.

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
		trees                => $trees,
		_use_c               => $HAS_C,
		_use_openmp          => $HAS_OPENMP,
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

=head2 load($path);

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

# One draw from the standard normal N(0,1) via Box-Muller. Used to pick the
# random hyperplane orientations in Extended Isolation Forest mode.
sub _randn {
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return sqrt( -2.0 * log($u1) ) * cos( TWO_PI * $u2 );
}

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

	my $nf = $self->{n_features};

	# Per-feature min and max within this node, in a single pass.
	my ( @lo, @hi );
	for my $row (@$X) {
		for my $f ( 0 .. $nf - 1 ) {
			my $v = $row->[$f];
			$lo[$f] = $v if !defined $lo[$f] || $v < $lo[$f];
			$hi[$f] = $v if !defined $hi[$f] || $v > $hi[$f];
		}
	}

	# Features with spread are the only ones that can split the data.
	my @varying = grep { $lo[$_] < $hi[$_] } 0 .. $nf - 1;

	# No spread on any feature => all points identical => cannot isolate.
	return [ _NODE_LEAF, $size ] unless @varying;

	my $node
		= $self->{mode} eq 'extended'
		? $self->_oblique_split( $X, \@varying, \@lo, \@hi )
		: _axis_split( $X, \@varying, \@lo, \@hi );

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
	my ( $X, $varying, $lo, $hi ) = @_;

	my $attr  = $varying->[ int( rand( scalar @$varying ) ) ];
	my $split = $lo->[$attr] + rand() * ( $hi->[$attr] - $lo->[$attr] );

	my ( @left, @right );
	for my $row (@$X) {
		if   ( $row->[$attr] < $split ) { push @left,  $row }
		else                            { push @right, $row }
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
	my ( $self, $X, $varying, $lo, $hi ) = @_;

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
		my $p = $lo->[$f] + rand() * ( $hi->[$f] - $lo->[$f] );    # point in the box
		push @coef, $c;
		$b += $c * $p;
	}

	my ( @left, @right );
	for my $row (@$X) {
		my $dot = 0.0;
		$dot += $coef[$_] * $row->[ $idx[$_] ] for 0 .. $#idx;
		if   ( $dot <= $b ) { push @left,  $row }
		else                { push @right, $row }
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
sub _path_length {
	my ( $x, $node, $depth ) = @_;
	while ( $node->[0] ) {                       # false only for leaf (type 0)
		if ( $node->[0] == _NODE_AXIS ) {        # [1, attr, split, left, right]
			$node = ( $x->[ $node->[1] ] // 0 ) < $node->[2]
				? $node->[3] : $node->[4];
		} else {                                 # [2, \@idx, \@coef, b, left, right]
			my ( $idx, $coef, $b ) = ( $node->[1], $node->[2], $node->[3] );
			my $dot = 0.0;
			$dot += $coef->[$_] * ( $x->[ $idx->[$_] ] // 0 ) for 0 .. $#$idx;
			$node = $dot <= $b ? $node->[4] : $node->[5];
		}
		$depth++;
	}
	return $depth + _c( $node->[1] );            # leaf size at slot 1
} ## end sub _path_length

# Recursively convert a version-0 hash-based tree node to the version-1
# array format.  Called by from_json when loading an old saved model.
sub _hash_node_to_array {
	my ($node) = @_;
	if ( $node->{leaf} ) {
		return [ _NODE_LEAF, $node->{size} ];
	} elsif ( exists $node->{attr} ) {
		return [
			_NODE_AXIS,
			$node->{attr},
			$node->{split},
			_hash_node_to_array( $node->{left} ),
			_hash_node_to_array( $node->{right} ),
		];
	} else {
		return [
			_NODE_OBLIQUE,
			$node->{idx},
			$node->{coef},
			$node->{b},
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
			$node_data[$my_idx] = [ 0.0, $node->[1] + 0.0, 0.0, 0.0, 0.0, 0.0 ];
		}
		elsif ( $node->[0] == _NODE_AXIS ) {
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
		}
		else {                       # _NODE_OBLIQUE
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
				@coef_for{ @$idx_arr } = @$coef_arr;
				for my $k ( 0 .. $n_features - 1 ) {
					push @coef_idx, $k;
					push @coef_val, $coef_for{$k} + 0.0;
				}
			}
			else {
				for my $i ( 0 .. $num - 1 ) {
					push @coef_idx, int( $idx_arr->[$i] );
					push @coef_val, $coef_arr->[$i] + 0.0;
				}
			}

			my $li = $assign->( $node->[4] );
			my $ri = $assign->( $node->[5] );
			$node_data[$my_idx] = [
				2.0,
				$coef_off + 0.0,
				$num + 0.0,
				$li + 0.0,
				$ri + 0.0,
				$b + 0.0,
			];
		}
		return $my_idx;
	};
	$assign->($root);

	my $nodes_packed = pack( 'd*', map { @$_ } @node_data );
	my $idx_packed   = @coef_idx ? pack( 'l*', @coef_idx ) : pack( 'l*' );
	my $val_packed   = @coef_val ? pack( 'd*', @coef_val ) : pack( 'd*' );
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
# fixed-worker-count runs are reproducible), builds its share, and
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
			my @trees;
			for ( 1 .. $share ) {
				my $sample = _subsample( $data, $psi );
				push @trees, $self->_build_tree( $sample, 0, $limit );
			}
			print $wh Storable::freeze( \@trees );
			close $wh;
			# _exit so we don't run parent END/DESTROY in the child.
			POSIX::_exit(0);
		}

		close $wh;
		binmode $rh;
		push @procs, { pid => $pid, rh => $rh, share => $share };
	}

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
	}

	return \@all_trees;
}

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
	pack_input_xs( $data, $x_packed, $n_pts, $nf );
	return bless {
		packed  => $x_packed,
		n_pts   => $n_pts,
		n_feats => $nf,
	}, 'Algorithm::Classifier::IsolationForest::PackedData';
}

# Internal helper: given $data that may be a raw arrayref OR a PackedData
# instance, return the (n_pts, n_feats, x_packed) triple ready for
# score_all_xs.  Called from every scoring fast path.
sub _resolve_input {
	my ( $self, $data ) = @_;
	if ( ref $data eq 'Algorithm::Classifier::IsolationForest::PackedData' ) {
		croak "PackedData has $data->{n_feats} features but model expects "
			. $self->{n_features}
			unless $data->{n_feats} == $self->{n_features};
		return ( $data->{n_pts}, $data->{n_feats}, $data->{packed} );
	}
	my $n_pts    = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n_pts * $nf * 8 );
	pack_input_xs( $data, $x_packed, $n_pts, $nf );
	return ( $n_pts, $nf, $x_packed );
}

# Helper used by the pure-Perl fallback paths: convert either form back
# to an arrayref-of-arrayrefs.  Slow on PackedData -- the whole point of
# packing is to keep things in C -- but lets the fallback path be
# uniformly arrayref-driven.
sub _to_arrayref {
	my ( $self, $data ) = @_;
	return $data if ref $data eq 'ARRAY';
	if ( ref $data eq 'Algorithm::Classifier::IsolationForest::PackedData' ) {
		my $n_pts = $data->{n_pts};
		my $nf    = $data->{n_feats};
		my @doubles = unpack( 'd*', $data->{packed} );
		my @rows;
		for my $i ( 0 .. $n_pts - 1 ) {
			push @rows, [ @doubles[ $i * $nf .. ( $i + 1 ) * $nf - 1 ] ];
		}
		return \@rows;
	}
	croak "expected arrayref or PackedData, got " . ( ref($data) || 'scalar' );
}

# Minimal PackedData package: opaque token returned by pack_data().
# Exposes n_pts and n_feats accessors for users who want to introspect.
{
	package Algorithm::Classifier::IsolationForest::PackedData;
	sub n_pts   { $_[0]->{n_pts} }
	sub n_feats { $_[0]->{n_feats} }
}

1;
