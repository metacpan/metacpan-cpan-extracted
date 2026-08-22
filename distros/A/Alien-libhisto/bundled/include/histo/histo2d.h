/**
 * @file histo2d.h
 * @brief Public C API for 2D bivariate histograms, projections, and 2D stats.
 */

#ifndef LIBHISTO_HISTO2D_H
#define LIBHISTO_HISTO2D_H

/**
 * @file histo2d.h
 * @brief Public C API for 2-Dimensional Histograms (libhisto).
 *
 * Provides high-performance, cache-aligned 2D histogramming with support for
 * all 4 binning combinations (Uniform-Uniform, Uniform-Variable, Variable-Uniform,
 * Variable-Variable), exact online 2D Welford covariance tracking, 9-region
 * guard boundary accumulation, 1D projections, slices, profile histograms,
 * SIMD-ready batch ingestion, and little-endian wire serialization.
 */

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "histo/types.h"
#include "histo/histo.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 2D Types, Enumerations & Structures                                       */
/* ========================================================================= */

/** @brief Opaque 2D histogram handle */
typedef struct histo2d histo2d_t;

/**
 * @brief 9-Region Geometric Partitioning for Out-of-Bounds & Guard Tracking.
 */
typedef enum histo2d_region {
    HISTO2D_REGION_CENTER     = 0,  /**< In-range: [xmin, xmax) x [ymin, ymax) */
    HISTO2D_REGION_EAST       = 1,  /**< x >= xmax, ymin <= y < ymax */
    HISTO2D_REGION_NORTH      = 2,  /**< xmin <= x < xmax, y >= ymax */
    HISTO2D_REGION_SOUTH      = 3,  /**< xmin <= x < xmax, y < ymin */
    HISTO2D_REGION_WEST       = 4,  /**< x < xmin, ymin <= y < ymax */
    HISTO2D_REGION_SOUTH_WEST = 5,  /**< x < xmin, y < ymin */
    HISTO2D_REGION_SOUTH_EAST = 6,  /**< x >= xmax, y < ymin */
    HISTO2D_REGION_NORTH_WEST = 7,  /**< x < xmin, y >= ymax */
    HISTO2D_REGION_NORTH_EAST = 8,  /**< x >= xmax, y >= ymax */
    HISTO2D_REGION_COUNT      = 9   /**< Total number of distinct 2D regions */
} histo2d_region_t;

/**
 * @brief Axis specification structure for 2D histogram configuration.
 */
typedef struct histo2d_axis {
    histo_bin_type_t type;    /**< HISTO_BIN_UNIFORM or HISTO_BIN_VARIABLE */
    uint32_t         nbins;   /**< Number of bins (1 <= nbins <= HISTO_MAX_NBINS) */
    double           min;     /**< Lower boundary (finite, min < max) */
    double           max;     /**< Upper boundary (finite, max > min) */
    const double    *edges;   /**< Pointer to (nbins + 1) monotonic doubles (NULL if uniform) */
} histo2d_axis_t;

/**
 * @brief 2D summary statistics container returned by histo2d_get_stats().
 */
typedef struct histo2d_stats {
    uint64_t n_entries;       /**< Total number of in-range fill events */
    double   total_weight;    /**< Total in-range accumulated weight */
    double   mean_x;          /**< Sample mean along X axis */
    double   mean_y;          /**< Sample mean along Y axis */
    double   variance_x;      /**< Sample variance along X axis */
    double   variance_y;      /**< Sample variance along Y axis */
    double   std_dev_x;       /**< Sample standard deviation along X */
    double   std_dev_y;       /**< Sample standard deviation along Y */
    double   covariance;      /**< Sample covariance Cov(X, Y) */
    double   correlation;     /**< Pearson correlation coefficient rho_xy */
    double   min_x;           /**< Lower boundary of X axis */
    double   max_x;           /**< Upper boundary of X axis */
    double   min_y;           /**< Lower boundary of Y axis */
    double   max_y;           /**< Upper boundary of Y axis */
} histo2d_stats_t;

/* ========================================================================= */
/* Lifecycle & Memory Management                                             */
/* ========================================================================= */

/**
 * @brief Creates a 2D histogram from explicit X and Y axis specifications.
 *
 * @param[in] x_axis Pointer to X-axis definition.
 * @param[in] y_axis Pointer to Y-axis definition.
 * @param[in] flags  Bitwise OR of feature flags (e.g. HISTO_FLAG_TRACK_SUMW2).
 * @return Pointer to initialized 2D histogram handle, or NULL on failure.
 */
histo2d_t* histo2d_create(const histo2d_axis_t *x_axis,
                          const histo2d_axis_t *y_axis,
                          uint32_t flags);

/**
 * @brief Creates a Uniform-Uniform 2D histogram.
 *
 * @param[in] nx    Number of equidistant X bins.
 * @param[in] xmin  Lower bound along X (xmin < xmax).
 * @param[in] xmax  Upper bound along X.
 * @param[in] ny    Number of equidistant Y bins.
 * @param[in] ymin  Lower bound along Y (ymin < ymax).
 * @param[in] ymax  Upper bound along Y.
 * @param[in] flags Feature flags.
 * @return Initialized handle, or NULL on error.
 */
histo2d_t* histo2d_create_uniform(uint32_t nx, double xmin, double xmax,
                                  uint32_t ny, double ymin, double ymax,
                                  uint32_t flags);

/**
 * @brief Creates a Variable-Variable 2D histogram from monotonic edge arrays.
 *
 * @param[in] nx     Number of bins along X.
 * @param[in] xedges Array of (nx + 1) strictly monotonic edge values.
 * @param[in] ny     Number of bins along Y.
 * @param[in] yedges Array of (ny + 1) strictly monotonic edge values.
 * @param[in] flags  Feature flags.
 * @return Initialized handle, or NULL on error.
 */
histo2d_t* histo2d_create_variable(uint32_t nx, const double *xedges,
                                   uint32_t ny, const double *yedges,
                                   uint32_t flags);

/**
 * @brief Creates a Uniform-Variable 2D histogram (Uniform X, Variable Y).
 *
 * @param[in] nx     Number of equidistant X bins.
 * @param[in] xmin   Lower bound along X.
 * @param[in] xmax   Upper bound along X.
 * @param[in] ny     Number of bins along Y.
 * @param[in] yedges Array of (ny + 1) monotonic edge values.
 * @param[in] flags  Feature flags.
 * @return Initialized handle, or NULL on error.
 */
histo2d_t* histo2d_create_uniform_variable(uint32_t nx, double xmin, double xmax,
                                           uint32_t ny, const double *yedges,
                                           uint32_t flags);

/**
 * @brief Creates a Variable-Uniform 2D histogram (Variable X, Uniform Y).
 *
 * @param[in] nx     Number of bins along X.
 * @param[in] xedges Array of (nx + 1) monotonic edge values.
 * @param[in] ny     Number of equidistant Y bins.
 * @param[in] ymin   Lower bound along Y.
 * @param[in] ymax   Upper bound along Y.
 * @param[in] flags  Feature flags.
 * @return Initialized handle, or NULL on error.
 */
histo2d_t* histo2d_create_variable_uniform(uint32_t nx, const double *xedges,
                                           uint32_t ny, double ymin, double ymax,
                                           uint32_t flags);

/**
 * @brief Destroys a 2D histogram and releases all allocated memory.
 * Safe to call with NULL.
 *
 * @param[in,out] h 2D histogram handle to destroy.
 */
void histo2d_destroy(histo2d_t *h);

/**
 * @brief Clones a 2D histogram, optionally zeroing bin contents and moments.
 *
 * @param[in] src   Source 2D histogram to clone.
 * @param[in] empty If true, allocate identical axis geometry with cleared bins.
 * @return Cloned handle, or NULL on error.
 */
histo2d_t* histo2d_clone(const histo2d_t *src, bool empty);

/**
 * @brief Resets all bin contents, guard region counters, and moments to zero.
 *
 * @param[in,out] h 2D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_reset(histo2d_t *h);

/* ========================================================================= */
/* Ingestion / Filling                                                       */
/* ========================================================================= */

/**
 * @brief Fills a single coordinate pair (x, y) with unit weight (1.0).
 *
 * @param[in,out] h 2D histogram handle.
 * @param[in]     x Sample X coordinate.
 * @param[in]     y Sample Y coordinate.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x or y is NaN/Inf.
 */
histo_status_t histo2d_fill(histo2d_t *h, double x, double y);

/**
 * @brief Fills a single coordinate pair (x, y) with specified weight.
 *
 * @param[in,out] h      2D histogram handle.
 * @param[in]     x      Sample X coordinate.
 * @param[in]     y      Sample Y coordinate.
 * @param[in]     weight Event weight.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x, y, or weight is NaN/Inf.
 */
histo_status_t histo2d_fill_w(histo2d_t *h, double x, double y, double weight);

/**
 * @brief Batch fills N coordinate pairs with optional weights (SoA format).
 *
 * @param[in,out] h       2D histogram handle.
 * @param[in]     n       Number of samples to ingest.
 * @param[in]     x       Contiguous array of X coordinates.
 * @param[in]     y       Contiguous array of Y coordinates.
 * @param[in]     weights Optional contiguous array of weights (NULL for unit weights).
 * @return HISTO_OK on success, or HISTO_WARN_NON_FINITE if non-finite samples skipped.
 */
histo_status_t histo2d_fill_n(histo2d_t *h, size_t n,
                              const double *x, const double *y,
                              const double *weights);

/**
 * @brief Strided batch fill for Array-of-Structs (AoS) data layouts.
 *
 * @param[in,out] h               2D histogram handle.
 * @param[in]     n               Number of samples.
 * @param[in]     x               Pointer to first sample X coordinate.
 * @param[in]     x_stride_bytes  Byte stride between consecutive X values.
 * @param[in]     y               Pointer to first sample Y coordinate.
 * @param[in]     y_stride_bytes  Byte stride between consecutive Y values.
 * @param[in]     weights         Optional pointer to first weight (NULL for unit weights).
 * @param[in]     w_stride_bytes  Byte stride between consecutive weights.
 * @return HISTO_OK on success, or HISTO_WARN_NON_FINITE if non-finite samples skipped.
 */
histo_status_t histo2d_fill_strided(histo2d_t *h, size_t n,
                                    const double *x, size_t x_stride_bytes,
                                    const double *y, size_t y_stride_bytes,
                                    const double *weights, size_t w_stride_bytes);

/**
 * @brief Directly accumulates weight into a specific 2D bin cell (ix, iy).
 *
 * @param[in,out] h      2D histogram handle.
 * @param[in]     ix     X bin index [0, nx - 1].
 * @param[in]     iy     Y bin index [0, ny - 1].
 * @param[in]     weight Weight to accumulate.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if indices out of bounds.
 */
histo_status_t histo2d_fill_bin(histo2d_t *h, uint32_t ix, uint32_t iy, double weight);

/* ========================================================================= */
/* Geometry & Bin Query                                                      */
/* ========================================================================= */

/** @brief Returns the number of X bins */
uint32_t histo2d_nbins_x(const histo2d_t *h);

/** @brief Returns the number of Y bins */
uint32_t histo2d_nbins_y(const histo2d_t *h);

/** @brief Retrieves X axis description */
histo_status_t histo2d_axis_x(const histo2d_t *h, histo2d_axis_t *out_axis);

/** @brief Retrieves Y axis description */
histo_status_t histo2d_axis_y(const histo2d_t *h, histo2d_axis_t *out_axis);

/**
 * @brief Locates the (ix, iy) bin indices for coordinate pair (x, y).
 *
 * @param[in]  h      2D histogram handle.
 * @param[in]  x      X coordinate.
 * @param[in]  y      Y coordinate.
 * @param[out] out_ix Output X bin index ([0, nx-1] on hit, -1 underflow, nx overflow).
 * @param[out] out_iy Output Y bin index ([0, ny-1] on hit, -1 underflow, ny overflow).
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x or y is NaN.
 */
histo_status_t histo2d_find_bin(const histo2d_t *h, double x, double y,
                                int64_t *out_ix, int64_t *out_iy);

/**
 * @brief Identifies which of the 9 geometric regions (x, y) belongs to.
 *
 * @param[in]  h          2D histogram handle.
 * @param[in]  x          X coordinate.
 * @param[in]  y          Y coordinate.
 * @param[out] out_region Output region classification enum.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x or y is NaN.
 */
histo_status_t histo2d_find_region(const histo2d_t *h, double x, double y,
                                   histo2d_region_t *out_region);

/**
 * @brief Retrieves the accumulated weight in cell (ix, iy).
 *
 * @param[in]  h          2D histogram handle.
 * @param[in]  ix         X bin index [0, nx - 1].
 * @param[in]  iy         Y bin index [0, ny - 1].
 * @param[out] out_weight Output pointer for accumulated weight.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_bin_content(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                   double *out_weight);

/**
 * @brief Retrieves statistical uncertainty (standard error) in cell (ix, iy).
 *
 * @param[in]  h         2D histogram handle.
 * @param[in]  ix        X bin index [0, nx - 1].
 * @param[in]  iy        Y bin index [0, ny - 1].
 * @param[out] out_error Output pointer for uncertainty.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_bin_error(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                 double *out_error);

/**
 * @brief Retrieves the sum of squared weights sum(w^2) in cell (ix, iy).
 *
 * @param[in]  h          2D histogram handle.
 * @param[in]  ix         X bin index [0, nx - 1].
 * @param[in]  iy         Y bin index [0, ny - 1].
 * @param[out] out_sum_w2 Output pointer for sum_w2.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_bin_sum_w2(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_sum_w2);

/**
 * @brief Retrieves the 2D bounding box [xmin, xmax] x [ymin, ymax] of cell (ix, iy).
 *
 * @param[in]  h        2D histogram handle.
 * @param[in]  ix       X bin index [0, nx - 1].
 * @param[in]  iy       Y bin index [0, ny - 1].
 * @param[out] out_xmin Output pointer for X lower edge.
 * @param[out] out_xmax Output pointer for X upper edge.
 * @param[out] out_ymin Output pointer for Y lower edge.
 * @param[out] out_ymax Output pointer for Y upper edge.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_bin_bounds(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_xmin, double *out_xmax,
                                  double *out_ymin, double *out_ymax);

/**
 * @brief Retrieves the midpoint center (cx, cy) of cell (ix, iy).
 *
 * @param[in]  h      2D histogram handle.
 * @param[in]  ix     X bin index [0, nx - 1].
 * @param[in]  iy     Y bin index [0, ny - 1].
 * @param[out] out_cx Output pointer for X center.
 * @param[out] out_cy Output pointer for Y center.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_bin_center(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_cx, double *out_cy);

/**
 * @brief Retrieves the accumulated weight and count for a specific guard region.
 *
 * @param[in]  h          2D histogram handle.
 * @param[in]  region     Target region enum.
 * @param[out] out_weight Output pointer for accumulated weight.
 * @param[out] out_count  Output pointer for fill count.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_region_content(const histo2d_t *h, histo2d_region_t region,
                                      double *out_weight, uint64_t *out_count);

/**
 * @brief Retrieves total number of rejected non-finite (NaN/Inf) fill samples.
 *
 * @param[in] h 2D histogram handle.
 * @return Count of non-finite events.
 */
uint64_t histo2d_nan_count(const histo2d_t *h);

/**
 * @brief Retrieves total in-range accumulated weight.
 *
 * @param[in] h 2D histogram handle.
 * @return Total weight across all in-range cells.
 */
double histo2d_total_weight(const histo2d_t *h);

/**
 * @brief Retrieves total in-range fill entries.
 *
 * @param[in] h 2D histogram handle.
 * @return In-range entry count.
 */
uint64_t histo2d_num_entries(const histo2d_t *h);

/* ========================================================================= */
/* Statistical Moments & Analysis                                            */
/* ========================================================================= */

/** @brief Retrieves the mean along the X axis */
histo_status_t histo2d_mean_x(const histo2d_t *h, double *out_mean_x);

/** @brief Retrieves the mean along the Y axis */
histo_status_t histo2d_mean_y(const histo2d_t *h, double *out_mean_y);

/** @brief Retrieves the sample variance along the X axis */
histo_status_t histo2d_variance_x(const histo2d_t *h, double *out_var_x);

/** @brief Retrieves the sample variance along the Y axis */
histo_status_t histo2d_variance_y(const histo2d_t *h, double *out_var_y);

/** @brief Retrieves the sample standard deviation along the X axis */
histo_status_t histo2d_std_dev_x(const histo2d_t *h, double *out_std_x);

/** @brief Retrieves the sample standard deviation along the Y axis */
histo_status_t histo2d_std_dev_y(const histo2d_t *h, double *out_std_y);

/**
 * @brief Retrieves sample covariance Cov(X, Y).
 *
 * @param[in]  h       2D histogram handle.
 * @param[out] out_cov Output pointer for covariance.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_covariance(const histo2d_t *h, double *out_cov);

/**
 * @brief Retrieves Pearson correlation coefficient rho_xy = Cov(X,Y)/(sigma_x * sigma_y).
 *
 * @param[in]  h       2D histogram handle.
 * @param[out] out_rho Output pointer for correlation coefficient.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_correlation(const histo2d_t *h, double *out_rho);

/**
 * @brief Computes total in-range 2D integral (sum of all cell weights).
 *
 * @param[in]  h            2D histogram handle.
 * @param[out] out_integral Output pointer for integral.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_integral(const histo2d_t *h, double *out_integral);

/**
 * @brief Computes 2D integral over a sub-grid of bins [ix_min, ix_max] x [iy_min, iy_max].
 *
 * @param[in]  h            2D histogram handle.
 * @param[in]  ix_min       Lower X bin index (inclusive).
 * @param[in]  ix_max       Upper X bin index (inclusive).
 * @param[in]  iy_min       Lower Y bin index (inclusive).
 * @param[in]  iy_max       Upper Y bin index (inclusive).
 * @param[out] out_integral Output pointer for range integral.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_integral_range(const histo2d_t *h,
                                      uint32_t ix_min, uint32_t ix_max,
                                      uint32_t iy_min, uint32_t iy_max,
                                      double *out_integral);

/**
 * @brief Retrieves comprehensive 2D statistical summary.
 *
 * @param[in]  h         2D histogram handle.
 * @param[out] out_stats Output statistics structure pointer.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_get_stats(const histo2d_t *h, histo2d_stats_t *out_stats);

/* ========================================================================= */
/* Projections, Slices & Profiles                                            */
/* ========================================================================= */

/**
 * @brief Projects 2D histogram onto X-axis, integrating over all Y bins.
 *
 * Allocates and populates a new 1D histogram matching the X-axis geometry.
 * Caller owns the returned *out_h1d and must free it via histo_destroy().
 *
 * @param[in]  h       Source 2D histogram.
 * @param[out] out_h1d Pointer to output 1D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_project_x(const histo2d_t *h, histo_t **out_h1d);

/**
 * @brief Projects 2D histogram onto Y-axis, integrating over all X bins.
 *
 * Allocates and populates a new 1D histogram matching the Y-axis geometry.
 * Caller owns the returned *out_h1d and must free it via histo_destroy().
 *
 * @param[in]  h       Source 2D histogram.
 * @param[out] out_h1d Pointer to output 1D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_project_y(const histo2d_t *h, histo_t **out_h1d);

/**
 * @brief Slices 2D histogram along X across a specified Y-bin interval [iy_min, iy_max].
 *
 * @param[in]  h       Source 2D histogram.
 * @param[in]  iy_min  Lower Y bin index (inclusive).
 * @param[in]  iy_max  Upper Y bin index (inclusive).
 * @param[out] out_h1d Output 1D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_slice_x(const histo2d_t *h, uint32_t iy_min, uint32_t iy_max,
                               histo_t **out_h1d);

/**
 * @brief Slices 2D histogram along Y across a specified X-bin interval [ix_min, ix_max].
 *
 * @param[in]  h       Source 2D histogram.
 * @param[in]  ix_min  Lower X bin index (inclusive).
 * @param[in]  ix_max  Upper X bin index (inclusive).
 * @param[out] out_h1d Output 1D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_slice_y(const histo2d_t *h, uint32_t ix_min, uint32_t ix_max,
                               histo_t **out_h1d);

/**
 * @brief Computes 1D Profile along X: mean of Y in each X bin with standard error.
 *
 * @param[in]  h              Source 2D histogram.
 * @param[out] out_profile_1d Pointer to output 1D histogram containing profile means and errors.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_profile_x(const histo2d_t *h, histo_t **out_profile_1d);

/**
 * @brief Computes 1D Profile along Y: mean of X in each Y bin with standard error.
 *
 * @param[in]  h              Source 2D histogram.
 * @param[out] out_profile_1d Pointer to output 1D histogram containing profile means and errors.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_profile_y(const histo2d_t *h, histo_t **out_profile_1d);

/* ========================================================================= */
/* Transformations & Arithmetic                                              */
/* ========================================================================= */

/**
 * @brief Scales all bin weights, uncertainties, and moments by scalar factor.
 *
 * @param[in,out] h      2D histogram handle.
 * @param[in]     factor Multiplicative scaling factor.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_scale(histo2d_t *h, double factor);

/**
 * @brief Normalizes 2D histogram such that total volume/integral equals target_integral.
 *
 * @param[in,out] h               2D histogram handle.
 * @param[in]     target_integral Desired integral sum.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_normalize(histo2d_t *h, double target_integral);

/**
 * @brief Rebins 2D histogram by integer grouping factors (factor_x, factor_y).
 *
 * @param[in]  src          Source 2D histogram.
 * @param[in]  factor_x     Integer grouping factor along X (nx must be divisible by factor_x).
 * @param[in]  factor_y     Integer grouping factor along Y (ny must be divisible by factor_y).
 * @param[out] out_rebinned Pointer to newly allocated rebinned 2D histogram.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_rebin(const histo2d_t *src, uint32_t factor_x, uint32_t factor_y,
                             histo2d_t **out_rebinned);

/**
 * @brief Adds source histogram scaled by factor into destination: dst += scale * src.
 *
 * @param[in,out] dst   Destination 2D histogram.
 * @param[in]     src   Source 2D histogram.
 * @param[in]     scale Multiplier for source histogram.
 * @return HISTO_OK on success, or HISTO_ERR_INCOMPATIBLE if geometries differ.
 */
histo_status_t histo2d_add(histo2d_t *dst, const histo2d_t *src, double scale);

/**
 * @brief Subtracts source histogram from destination: dst -= src.
 *
 * @param[in,out] dst Destination 2D histogram.
 * @param[in]     src Source 2D histogram.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_subtract(histo2d_t *dst, const histo2d_t *src);

/**
 * @brief Cell-by-cell multiplication: dst *= src.
 *
 * @param[in,out] dst Destination 2D histogram.
 * @param[in]     src Source 2D histogram.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_multiply(histo2d_t *dst, const histo2d_t *src);

/**
 * @brief Cell-by-cell division: dst /= src.
 *
 * @param[in,out] dst Destination 2D histogram.
 * @param[in]     src Source 2D histogram.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_divide(histo2d_t *dst, const histo2d_t *src);

/* ========================================================================= */
/* Serialization & Wire Formats                                              */
/* ========================================================================= */

/**
 * @brief Serializes 2D histogram to preallocated buffer in Canonical Little-Endian V3 format.
 *
 * @param[in]  h        2D histogram handle.
 * @param[out] buf      Destination preallocated memory buffer.
 * @param[in]  buf_size Size of destination buffer in bytes.
 * @param[out] out_size Actual bytes written (or required size if buffer too small).
 * @return HISTO_OK on success, or HISTO_ERR_SERIALIZATION.
 */
histo_status_t histo2d_serialize_binary(const histo2d_t *h, void *buf,
                                        size_t buf_size, size_t *out_size);

/**
 * @brief Serializes 2D histogram, allocating buffer dynamically.
 * Caller owns *out_buf and must free it with histo_free_buffer().
 *
 * @param[in]  h        2D histogram handle.
 * @param[out] out_buf  Pointer to allocated binary buffer.
 * @param[out] out_size Number of bytes allocated and written.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_serialize_binary_alloc(const histo2d_t *h, void **out_buf,
                                              size_t *out_size);

/**
 * @brief Deserializes 2D histogram from Canonical Little-Endian binary blob.
 *
 * @param[in]  buf   Input binary buffer.
 * @param[in]  size  Size of input buffer in bytes.
 * @param[out] out_h Pointer to output 2D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_deserialize_binary(const void *buf, size_t size,
                                          histo2d_t **out_h);

/**
 * @brief Serializes 2D histogram to JSON formatted string in preallocated buffer.
 *
 * @param[in]  h        2D histogram handle.
 * @param[out] buf      Destination char buffer.
 * @param[in]  buf_size Size of buffer in bytes.
 * @param[out] out_size Bytes written (or required size).
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_serialize_json(const histo2d_t *h, char *buf,
                                      size_t buf_size, size_t *out_size);

/**
 * @brief Serializes 2D histogram to newly allocated JSON string.
 * Caller owns *out_str and must free it with histo_free_buffer().
 *
 * @param[in]  h       2D histogram handle.
 * @param[out] out_str Output JSON string pointer.
 * @param[out] out_size Number of bytes in string.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_serialize_json_alloc(const histo2d_t *h, char **out_str,
                                            size_t *out_size);


/**
 * @brief Deserializes 2D histogram from JSON string.
 *
 * @param[in]  json_str Input JSON string.
 * @param[out] out_h    Pointer to output 2D histogram handle.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo2d_deserialize_json(const char *json_str, histo2d_t **out_h);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_HISTO2D_H */
