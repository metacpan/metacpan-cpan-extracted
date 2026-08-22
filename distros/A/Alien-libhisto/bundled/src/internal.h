/*
 * Internal struct layouts and private macros for 1D histograms.
 */

#ifndef LIBHISTO_INTERNAL_H
#define LIBHISTO_INTERNAL_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "histo/histo.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Core histogram structure */
struct histo {
    /* --- Cache Line 0: Hot-Path Ingestion Variables (64 bytes) --- */
    double          *bins;           /* Array of (nbins) doubles: accumulated bin weights */
    double          *sum_w2;         /* Array of (nbins) doubles: accumulated sum of squared weights (NULL if disabled) */
    double           min;            /* Lower bound of bin 0 (finite) */
    double           max;            /* Upper bound of bin N-1 (max > min, finite) */
    double           inv_binsize;    /* Fast reciprocal (nbins / width) for 3-cycle FMUL lookup */
    double           total_weight;   /* Total in-range accumulated weight */
    uint64_t         n_fills;        /* Total in-range fill events */
    uint32_t         nbins;          /* Number of in-range bins (N >= 1) */
    histo_bin_type_t bin_type;       /* Uniform or Variable */

    /* --- Cache Line 1+: Remaining Geometry & Data --- */
    uint32_t         flags;          /* Configuration flags (HISTO_FLAG_*) */
    uint32_t         reserved_pad;   /* Explicit padding for strict 8-byte alignment */

    double           width;          /* Range width: (max - min) */
    double           binsize;        /* Width per bin: (width / nbins) for UNIFORM; 0.0 for VARIABLE */
    double          *bin_edges;      /* Pointer to (nbins + 1) strictly monotonic doubles for VARIABLE; NULL for UNIFORM */

    /* --- Out-of-Range & Exception Accumulators --- */
    double           underflow_weight;   /* Accumulated weight for x < min */
    double           overflow_weight;    /* Accumulated weight for x >= max */
    double           underflow_sum_w2;   /* Accumulated sum(w^2) for underflow */
    double           overflow_sum_w2;    /* Accumulated sum(w^2) for overflow */
    uint64_t         n_underflow;        /* Fill count for underflow */
    uint64_t         n_overflow;         /* Fill count for overflow */
    uint64_t         n_nan;              /* Count of rejected NaN / non-finite samples */

    /* --- In-Range Global Aggregates --- */
    double           total_sum_w2;       /* Total in-range accumulated sum of squared weights */

    /* --- Exact Online Sample Statistics (Updated if HISTO_FLAG_EXACT_MOMENTS is set) --- */
    double           stats_min;          /* Exact minimum sample value observed */
    double           stats_max;          /* Exact maximum sample value observed */
    double           stats_mean;         /* Online running mean (Welford) */
    double           stats_M2;           /* Online running sum of squared differences (Welford) */
};
#include "internal_common.h"

/**
 * @brief Safely populates raw bin contents and uncertainties for a newly allocated histogram.
 *
 * Used by 2D projection, slice, profile, and transformation routines.
 */
histo_status_t histo_set_raw_bin_contents(histo_t *h, const double *bins, const double *sum_w2);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_INTERNAL_H */

