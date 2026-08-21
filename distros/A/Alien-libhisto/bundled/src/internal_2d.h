#ifndef LIBHISTO_INTERNAL_2D_H
#define LIBHISTO_INTERNAL_2D_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "histo/histo2d.h"
#include "histo/histo.h"
#include "internal.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Internal axis descriptor structure.
 */
typedef struct histo2d_axis_internal {
    histo_bin_type_t bin_type;       /**< Uniform or Variable */
    uint32_t         nbins;          /**< Number of in-range bins */
    double           min;            /**< Lower edge */
    double           max;            /**< Upper edge */
    double           width;          /**< max - min */
    double           binsize;        /**< width / nbins for uniform, 0.0 for variable */
    double           inv_binsize;    /**< nbins / width for fast uniform arithmetic lookup */
    double          *bin_edges;      /**< Pointer to (nbins + 1) strictly monotonic doubles for variable */
} histo2d_axis_internal_t;

/**
 * @brief Guard accumulator for each of the 9 regions.
 */
typedef struct histo2d_guard {
    double   weight;    /**< Accumulated weight */
    double   sum_w2;    /**< Accumulated sum of squared weights */
    uint64_t count;     /**< Fill count */
} histo2d_guard_t;

/**
 * @brief Internal 2D histogram representation.
 */
struct histo2d {
    /* Contiguous 64-byte aligned Structure of Arrays */
    double                  *bins;           /**< Array of (nx * ny) doubles: accumulated cell weights */
    double                  *sum_w2;         /**< Array of (nx * ny) doubles: sum(w^2) per cell (NULL if disabled) */

    uint32_t                 flags;          /**< Feature flags (HISTO_FLAG_TRACK_SUMW2, etc.) */
    uint32_t                 reserved_pad;   /**< Explicit 8-byte alignment padding */

    histo2d_axis_internal_t  x_axis;         /**< X axis geometry */
    histo2d_axis_internal_t  y_axis;         /**< Y axis geometry */

    double                   total_weight;   /**< Total in-range accumulated weight */
    double                   total_sum_w2;   /**< Total in-range sum(w^2) */
    uint64_t                 n_fills;        /**< Total in-range fill events */

    histo2d_guard_t          guards[HISTO2D_REGION_COUNT]; /**< 9-Region boundary accumulators */
    uint64_t                 n_nan;          /**< Count of rejected non-finite (NaN/Inf) samples */

    /* Exact Online 2D Welford Bivariate Accumulators */
    double                   stats_min_x;    /**< Exact minimum X observed */
    double                   stats_max_x;    /**< Exact maximum X observed */
    double                   stats_min_y;    /**< Exact minimum Y observed */
    double                   stats_max_y;    /**< Exact maximum Y observed */
    double                   stats_mean_x;   /**< Running sample mean of X */
    double                   stats_mean_y;   /**< Running sample mean of Y */
    double                   stats_M2_x;     /**< Running sum of squared deviations for X */
    double                   stats_M2_y;     /**< Running sum of squared deviations for Y */
    double                   stats_C_xy;     /**< Running sum of co-deviations for (X, Y) */
};

/* 64-byte aligned memory allocation helpers */
static inline void* histo2d_alloc_aligned(size_t size) {
    return histo_alloc_aligned(size);
}

static inline void histo2d_free_aligned(void *ptr) {
    histo_free_aligned(ptr);
}

/**
 * @brief Linear row-major index mapping: i = ix * ny + iy.
 */
static inline size_t histo2d_linear_index(uint32_t ix, uint32_t iy, uint32_t ny) {
    return (size_t)ix * (size_t)ny + (size_t)iy;
}

/**
 * @brief Axis bin lookup: returns [0, nbins - 1] for in-range, -1 for underflow, nbins for overflow, -2 for non-finite.
 */
static inline int64_t histo2d_axis_find_bin(const histo2d_axis_internal_t *axis, double val) {
    if (!axis) return -2;
    if (axis->bin_type == HISTO_BIN_UNIFORM) {
        return histo_lookup_uniform_bin(val, axis->min, axis->max, axis->nbins,
                                        axis->binsize, axis->inv_binsize);
    } else {
        return histo_lookup_variable_bin(val, axis->bin_edges, axis->nbins);
    }
}


/**
 * @brief Classifies a 2D coordinate (x, y) into one of the 9 regions.
 */
static inline histo2d_region_t histo2d_classify_region(
    const histo2d_axis_internal_t *x_axis,
    const histo2d_axis_internal_t *y_axis,
    double x, double y)
{
    bool x_under = (x < x_axis->min);
    bool x_over  = (x >= x_axis->max);
    bool y_under = (y < y_axis->min);
    bool y_over  = (y >= y_axis->max);

    if (!x_under && !x_over && !y_under && !y_over) return HISTO2D_REGION_CENTER;
    if (x_under && y_under) return HISTO2D_REGION_SOUTH_WEST;
    if (x_under && y_over)  return HISTO2D_REGION_NORTH_WEST;
    if (x_under)            return HISTO2D_REGION_WEST;
    if (x_over && y_under)  return HISTO2D_REGION_SOUTH_EAST;
    if (x_over && y_over)   return HISTO2D_REGION_NORTH_EAST;
    if (x_over)             return HISTO2D_REGION_EAST;
    if (y_under)            return HISTO2D_REGION_SOUTH;
    return HISTO2D_REGION_NORTH;
}

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_INTERNAL_2D_H */
