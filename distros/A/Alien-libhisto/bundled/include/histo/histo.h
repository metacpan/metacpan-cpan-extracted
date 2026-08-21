#ifndef LIBHISTO_HISTO_H
#define LIBHISTO_HISTO_H

/**
 * @file histo.h
 * @brief Public C API for libhisto (1D high-performance histogramming library).
 */

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "types.h"
#include "version.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* Status & Error Strings                                                    */
/* ========================================================================= */

/**
 * @brief Returns a constant human-readable description of a status code.
 *
 * @param[in] status Status code to convert.
 * @return Null-terminated string description.
 */
const char* histo_status_str(histo_status_t status);

/* ========================================================================= */
/* Lifecycle & Memory Management                                             */
/* ========================================================================= */

/**
 * @brief Creates a new uniform-bin histogram over the range [min, max].
 *
 * @param[in] nbins Number of equidistant bins (1 <= nbins <= HISTO_MAX_NBINS).
 * @param[in] min   Lower boundary coordinate (finite, min < max).
 * @param[in] max   Upper boundary coordinate (finite, max > min).
 * @param[in] flags Bitwise OR of feature flags (e.g. HISTO_FLAG_TRACK_SUMW2).
 * @return Pointer to initialized histogram handle, or NULL on error.
 */
histo_t* histo_create_uniform(uint32_t nbins, double min, double max, uint32_t flags);

/**
 * @brief Creates a new variable-bin histogram from an array of monotonic edges.
 *
 * @param[in] nbins Number of bins (1 <= nbins <= HISTO_MAX_NBINS).
 * @param[in] edges Array of (nbins + 1) strictly increasing edge values.
 * @param[in] flags Bitwise OR of feature flags.
 * @return Pointer to initialized histogram handle, or NULL on error.
 */
histo_t* histo_create_variable(uint32_t nbins, const double *edges, uint32_t flags);

/**
 * @brief Destroys a histogram and releases all allocated memory.
 *
 * Safe to call with NULL.
 *
 * @param[in,out] h Histogram handle to destroy.
 */
void histo_destroy(histo_t *h);

/**
 * @brief Creates an exact clone or empty schema copy of a histogram.
 *
 * @param[in] src   Source histogram to clone.
 * @param[in] empty If true, allocate same binning structure but clear all counts.
 * @return Pointer to new cloned histogram handle, or NULL on error.
 */
histo_t* histo_clone(const histo_t *src, bool empty);

/**
 * @brief Resets all bin contents, weights, moments, and out-of-range counters to zero.
 *
 * @param[in,out] h Histogram handle to reset.
 * @return HISTO_OK on success, or HISTO_ERR_INVALID_ARG if h is NULL.
 */
histo_status_t histo_reset(histo_t *h);

/* ========================================================================= */
/* Ingestion / Filling                                                       */
/* ========================================================================= */

/**
 * @brief Fills a single value into the histogram with unit weight (1.0).
 *
 * @param[in,out] h Histogram handle.
 * @param[in]     x Sample coordinate.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x is NaN/Inf.
 */
histo_status_t histo_fill(histo_t *h, double x);

/**
 * @brief Fills a single value into the histogram with a specified weight.
 *
 * @param[in,out] h      Histogram handle.
 * @param[in]     x      Sample coordinate.
 * @param[in]     weight Real-valued event weight.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x/weight is NaN/Inf.
 */
histo_status_t histo_fill_w(histo_t *h, double x, double weight);

/**
 * @brief Batch fills N contiguous values with optional weights.
 *
 * @param[in,out] h       Histogram handle.
 * @param[in]     n       Number of samples to ingest.
 * @param[in]     x       Contiguous array of sample coordinates.
 * @param[in]     weights Optional contiguous array of weights (NULL for unit weights).
 * @return HISTO_OK on success, or HISTO_WARN_NON_FINITE if non-finite samples were skipped.
 */
histo_status_t histo_fill_n(histo_t *h, size_t n, const double *x, const double *weights);

/**
 * @brief Strided batch fill for Array-of-Structs (AoS) data layouts.
 *
 * @param[in,out] h               Histogram handle.
 * @param[in]     n               Number of samples to ingest.
 * @param[in]     x               Pointer to first sample coordinate.
 * @param[in]     x_stride_bytes  Byte stride between consecutive sample coordinates.
 * @param[in]     weights         Optional pointer to first sample weight (NULL for unit).
 * @param[in]     w_stride_bytes  Byte stride between consecutive weights.
 * @return HISTO_OK on success, or HISTO_WARN_NON_FINITE if non-finite samples were skipped.
 */
histo_status_t histo_fill_strided(histo_t *h, size_t n,
                                 const double *x, size_t x_stride_bytes,
                                 const double *weights, size_t w_stride_bytes);

/**
 * @brief Directly accumulates weight into a specific bin index.
 *
 * @param[in,out] h         Histogram handle.
 * @param[in]     bin_index Target bin index [0, nbins - 1].
 * @param[in]     weight    Weight to add.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if bin_index >= nbins.
 */
histo_status_t histo_fill_bin(histo_t *h, uint32_t bin_index, double weight);

/* ========================================================================= */
/* Geometry & Bin Query                                                      */
/* ========================================================================= */

/**
 * @brief Returns the number of in-range active bins.
 *
 * @param[in] h Histogram handle.
 * @return Number of bins, or 0 if h is NULL.
 */
uint32_t histo_nbins(const histo_t *h);

/**
 * @brief Returns the binning model type.
 *
 * @param[in] h Histogram handle.
 * @return HISTO_BIN_UNIFORM or HISTO_BIN_VARIABLE.
 */
histo_bin_type_t histo_bin_type(const histo_t *h);

/**
 * @brief Retrieves the overall range limits [min, max].
 *
 * @param[in]  h       Histogram handle.
 * @param[out] out_min Output pointer for lower range limit.
 * @param[out] out_max Output pointer for upper range limit.
 * @return HISTO_OK on success, or HISTO_ERR_INVALID_ARG if any pointer is NULL.
 */
histo_status_t histo_range(const histo_t *h, double *out_min, double *out_max);

/**
 * @brief Locates the bin index for coordinate x using boundary-guarded lookup.
 *
 * @param[in]  h       Histogram handle.
 * @param[in]  x       Coordinate to locate.
 * @param[out] out_bin Output pointer: [0, nbins-1] on hit, -1 for underflow, nbins for overflow.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if x is NaN.
 */
histo_status_t histo_find_bin(const histo_t *h, double x, int64_t *out_bin);

/**
 * @brief Retrieves the boundary interval [lower, upper] for a specific bin.
 *
 * @param[in]  h         Histogram handle.
 * @param[in]  bin_index Target bin index [0, nbins - 1].
 * @param[out] out_lower Output pointer for lower bin boundary.
 * @param[out] out_upper Output pointer for upper bin boundary.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if bin_index >= nbins.
 */
histo_status_t histo_bin_bounds(const histo_t *h, uint32_t bin_index, double *out_lower, double *out_upper);

/**
 * @brief Computes the midpoint center of a specific bin.
 *
 * @param[in]  h          Histogram handle.
 * @param[in]  bin_index  Target bin index [0, nbins - 1].
 * @param[out] out_center Output pointer for midpoint coordinate.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if bin_index >= nbins.
 */
histo_status_t histo_bin_center(const histo_t *h, uint32_t bin_index, double *out_center);

/**
 * @brief Retrieves the accumulated content (weight sum) of a bin.
 *
 * @param[in]  h           Histogram handle.
 * @param[in]  bin_index   Target bin index [0, nbins - 1].
 * @param[out] out_content Output pointer for bin content.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if bin_index >= nbins.
 */
histo_status_t histo_bin_content(const histo_t *h, uint32_t bin_index, double *out_content);

/**
 * @brief Calculates the statistical uncertainty (error) of a bin.
 *
 * Returns sqrt(sum_w2) if tracked, or Poisson sqrt(N) for unweighted bins.
 *
 * @param[in]  h         Histogram handle.
 * @param[in]  bin_index Target bin index [0, nbins - 1].
 * @param[out] out_error Output pointer for calculated uncertainty.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if bin_index >= nbins.
 */
histo_status_t histo_bin_error(const histo_t *h, uint32_t bin_index, double *out_error);

/**
 * @brief Retrieves the sum of squared weights (sum_w2) for a bin.
 *
 * @param[in]  h          Histogram handle.
 * @param[in]  bin_index  Target bin index [0, nbins - 1].
 * @param[out] out_sum_w2 Output pointer for sum_w2.
 * @return HISTO_OK on success, or HISTO_ERR_INVALID_ARG if sum_w2 is not tracked.
 */
histo_status_t histo_bin_sum_w2(const histo_t *h, uint32_t bin_index, double *out_sum_w2);

/**
 * @brief Retrieves total accumulated weight across all bins (excluding underflow/overflow).
 *
 * @param[in] h Histogram handle.
 * @return Total weight, or 0.0 if h is NULL.
 */
double histo_total_weight(const histo_t *h);

/**
 * @brief Retrieves total number of fill operations performed.
 *
 * @param[in] h Histogram handle.
 * @return Total fill count, or 0 if h is NULL.
 */
uint64_t histo_num_entries(const histo_t *h);

/**
 * @brief Retrieves total accumulated underflow weight.
 *
 * @param[in] h Histogram handle.
 * @return Underflow weight sum, or 0.0 if h is NULL.
 */
double histo_underflow(const histo_t *h);

/**
 * @brief Retrieves total accumulated overflow weight.
 *
 * @param[in] h Histogram handle.
 * @return Overflow weight sum, or 0.0 if h is NULL.
 */
double histo_overflow(const histo_t *h);

/**
 * @brief Retrieves total number of non-finite (NaN / Inf) rejected samples.
 *
 * @param[in] h Histogram handle.
 * @return Non-finite sample count, or 0 if h is NULL.
 */
uint64_t histo_nan_count(const histo_t *h);


/* ========================================================================= */
/* Statistical Moments & Quantiles                                           */
/* ========================================================================= */

/**
 * @brief Computes the distribution mean.
 *
 * @param[in]  h        Histogram handle.
 * @param[out] out_mean Output pointer for mean.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_mean(const histo_t *h, double *out_mean);

/**
 * @brief Computes the distribution variance.
 *
 * @param[in]  h            Histogram handle.
 * @param[out] out_variance Output pointer for variance.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_variance(const histo_t *h, double *out_variance);

/**
 * @brief Computes the distribution standard deviation.
 *
 * @param[in]  h           Histogram handle.
 * @param[out] out_std_dev Output pointer for standard deviation.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_std_dev(const histo_t *h, double *out_std_dev);

/**
 * @brief Computes the k-th central statistical moment M_k = sum(w_i * (x_i - mean)^k) / total_weight.
 *
 * @param[in]  h          Histogram handle.
 * @param[in]  k          Order of the central moment (k >= 0).
 * @param[out] out_moment Output pointer for calculated moment.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_central_moment(const histo_t *h, uint32_t k, double *out_moment);

/**
 * @brief Computes the distribution skewness (gamma_1 = M_3 / M_2^(3/2)).
 *
 * @param[in]  h            Histogram handle.
 * @param[out] out_skewness Output pointer for skewness.
 * @return HISTO_OK on success, HISTO_ERR_DIV_BY_ZERO if variance is zero, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_skewness(const histo_t *h, double *out_skewness);

/**
 * @brief Computes the distribution kurtosis (beta_2 = M_4 / M_2^2).
 *
 * @param[in]  h            Histogram handle.
 * @param[out] out_kurtosis Output pointer for kurtosis.
 * @return HISTO_OK on success, HISTO_ERR_DIV_BY_ZERO if variance is zero, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_kurtosis(const histo_t *h, double *out_kurtosis);

/**
 * @brief Computes the distribution excess kurtosis (gamma_2 = beta_2 - 3.0).
 *
 * For a normal distribution, excess kurtosis is 0.
 *
 * @param[in]  h                Histogram handle.
 * @param[out] out_exc_kurtosis Output pointer for excess kurtosis.
 * @return HISTO_OK on success, HISTO_ERR_DIV_BY_ZERO if variance is zero, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_excess_kurtosis(const histo_t *h, double *out_exc_kurtosis);

/**
 * @brief Identifies the index of the bin with the highest accumulated weight (mode bin).
 *
 * If multiple bins share the maximum weight, the lowest index is returned.
 *
 * @param[in]  h           Histogram handle.
 * @param[out] out_bin_idx Output pointer for mode bin index.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_mode_bin(const histo_t *h, uint32_t *out_bin_idx);

/**
 * @brief Estimates the continuous peak mode coordinate via 3-point parabolic interpolation.
 *
 * Uses vertex interpolation around the mode bin for uniform histograms.
 *
 * @param[in]  h        Histogram handle.
 * @param[out] out_mode Output pointer for continuous mode coordinate.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_mode_continuous(const histo_t *h, double *out_mode);

/**
 * @brief Computes the Full Width at Half Maximum (FWHM) of the dominant peak.
 *
 * @param[in]  h        Histogram handle.
 * @param[out] out_fwhm Output pointer for calculated FWHM.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_fwhm(const histo_t *h, double *out_fwhm);

/**
 * @brief Computes the Root Mean Square (RMS) of the distribution: sqrt(M_2 + mean^2).
 *
 * @param[in]  h       Histogram handle.
 * @param[out] out_rms Output pointer for calculated RMS.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_rms(const histo_t *h, double *out_rms);

/**
 * @brief Computes the quantile coordinate for probability p in [0.0, 1.0].
 *
 * Uses continuous piecewise linear inverse CDF interpolation.
 *
 * @param[in]  h            Histogram handle.
 * @param[in]  p            Cumulative probability in [0.0, 1.0].
 * @param[out] out_quantile Output pointer for calculated quantile coordinate.
 * @return HISTO_OK on success, HISTO_ERR_OUT_OF_RANGE if p not in [0,1], or HISTO_ERR_EMPTY.
 */
histo_status_t histo_quantile(const histo_t *h, double p, double *out_quantile);

/**
 * @brief Computes the median coordinate (50th percentile).
 *
 * @param[in]  h          Histogram handle.
 * @param[out] out_median Output pointer for median coordinate.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_median(const histo_t *h, double *out_median);

/**
 * @brief Computes the Interquartile Range (IQR = Q75 - Q25).
 *
 * @param[in]  h       Histogram handle.
 * @param[out] out_iqr Output pointer for calculated IQR.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_iqr(const histo_t *h, double *out_iqr);

/**
 * @brief Computes the Median Absolute Deviation (MAD = median(|x - median|)).
 *
 * @param[in]  h       Histogram handle.
 * @param[out] out_mad Output pointer for calculated MAD.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_mad(const histo_t *h, double *out_mad);

/**
 * @brief Computes the trimmed mean excluding tails below lower_p and above upper_p.
 *
 * @param[in]  h        Histogram handle.
 * @param[in]  lower_p  Lower percentile bound in [0.0, 1.0).
 * @param[in]  upper_p  Upper percentile bound in (lower_p, 1.0].
 * @param[out] out_mean Output pointer for calculated trimmed mean.
 * @return HISTO_OK on success, HISTO_ERR_OUT_OF_RANGE if bounds are invalid, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_trimmed_mean(const histo_t *h, double lower_p, double upper_p, double *out_mean);

/**
 * @brief Computes the Winsorized mean replacing tails with quantile threshold values.
 *
 * @param[in]  h        Histogram handle.
 * @param[in]  lower_p  Lower percentile bound in [0.0, 1.0).
 * @param[in]  upper_p  Upper percentile bound in (lower_p, 1.0].
 * @param[out] out_mean Output pointer for calculated Winsorized mean.
 * @return HISTO_OK on success, HISTO_ERR_OUT_OF_RANGE if bounds are invalid, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_winsorized_mean(const histo_t *h, double lower_p, double upper_p, double *out_mean);

/**
 * @brief Computes the integral (sum of bin contents) over bin range [start_bin, end_bin].
 *
 * @param[in]  h            Histogram handle.
 * @param[in]  start_bin    First bin index of range.
 * @param[in]  end_bin      Last bin index of range (inclusive).
 * @param[out] out_integral Output pointer for integrated sum.
 * @return HISTO_OK on success, or HISTO_ERR_OUT_OF_RANGE if end_bin >= nbins.
 */
histo_status_t histo_integral(const histo_t *h, uint32_t start_bin, uint32_t end_bin, double *out_integral);

/**
 * @brief Computes complete summary statistics container in a single call.
 *
 * @param[in]  h         Histogram handle.
 * @param[out] out_stats Pointer to destination statistics struct.
 * @return HISTO_OK on success, or HISTO_ERR_EMPTY if histogram has zero weight.
 */
histo_status_t histo_get_stats(const histo_t *h, histo_stats_t *out_stats);

/* ========================================================================= */
/* Two-Histogram Comparison & Distance Metrics                              */
/* ========================================================================= */

/**
 * @brief Computes the Chi-Square (chi^2) test of compatibility between two histograms.
 *
 * @param[in]  h1       First histogram.
 * @param[in]  h2       Second histogram (must have identical binning geometry).
 * @param[out] out_chi2 Output pointer for calculated chi-square sum.
 * @param[out] out_ndf  Output pointer for degrees of freedom (number of non-empty bins).
 * @return HISTO_OK on success, HISTO_ERR_INCOMPATIBLE if geometries mismatch, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_cmp_chi2(const histo_t *h1, const histo_t *h2, double *out_chi2, uint32_t *out_ndf);

/**
 * @brief Computes the Kolmogorov-Smirnov (KS) test statistic D between two histograms.
 *
 * Returns the maximum vertical distance between the two normalized empirical CDFs.
 *
 * @param[in]  h1          First histogram.
 * @param[in]  h2          Second histogram.
 * @param[out] out_ks_stat Output pointer for calculated KS statistic D in [0.0, 1.0].
 * @return HISTO_OK on success, HISTO_ERR_INCOMPATIBLE if geometries mismatch, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_cmp_ks(const histo_t *h1, const histo_t *h2, double *out_ks_stat);

/**
 * @brief Computes the 1D Wasserstein distance (Earth Mover's Distance) between two histograms.
 *
 * @param[in]  h1           First histogram.
 * @param[in]  h2           Second histogram.
 * @param[out] out_distance Output pointer for 1D Wasserstein distance.
 * @return HISTO_OK on success, HISTO_ERR_INCOMPATIBLE if geometries mismatch, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_cmp_wasserstein_1d(const histo_t *h1, const histo_t *h2, double *out_distance);

/**
 * @brief Computes the Kullback-Leibler (KL) divergence D_KL(h1 || h2).
 *
 * @param[in]  h1             First histogram (reference distribution P).
 * @param[in]  h2             Second histogram (approximate distribution Q).
 * @param[out] out_divergence Output pointer for calculated KL divergence in nats.
 * @return HISTO_OK on success, HISTO_ERR_INCOMPATIBLE if geometries mismatch, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_cmp_kl_divergence(const histo_t *h1, const histo_t *h2, double *out_divergence);

/**
 * @brief Computes the Bhattacharyya distance -ln(sum(sqrt(P_i * Q_i))) between two histograms.
 *
 * @param[in]  h1           First histogram.
 * @param[in]  h2           Second histogram.
 * @param[out] out_distance Output pointer for Bhattacharyya distance (>= 0.0).
 * @return HISTO_OK on success, HISTO_ERR_INCOMPATIBLE if geometries mismatch, or HISTO_ERR_EMPTY.
 */
histo_status_t histo_cmp_bhattacharyya(const histo_t *h1, const histo_t *h2, double *out_distance);

/* ========================================================================= */
/* Arithmetic Operations & Transformations                                   */
/* ========================================================================= */

/**
 * @brief Performs element-wise addition: target += other.
 *
 * @param[in,out] target Destination histogram to accumulate into.
 * @param[in]     other  Source histogram to add.
 * @return HISTO_OK on success, or HISTO_ERR_INCOMPATIBLE if geometries mismatch.
 */
histo_status_t histo_add(histo_t *target, const histo_t *other);

/**
 * @brief Performs element-wise subtraction: target -= other.
 *
 * @param[in,out] target Destination histogram.
 * @param[in]     other  Source histogram to subtract.
 * @return HISTO_OK on success, or HISTO_ERR_INCOMPATIBLE if geometries mismatch.
 */
histo_status_t histo_subtract(histo_t *target, const histo_t *other);

/**
 * @brief Performs element-wise multiplication: target *= other.
 *
 * @param[in,out] target Destination histogram.
 * @param[in]     other  Source histogram to multiply by.
 * @return HISTO_OK on success, or HISTO_ERR_INCOMPATIBLE if geometries mismatch.
 */
histo_status_t histo_multiply(histo_t *target, const histo_t *other);

/**
 * @brief Performs element-wise division: target /= other.
 *
 * @param[in,out] target Destination histogram.
 * @param[in]     other  Source histogram to divide by.
 * @return HISTO_OK on success, or HISTO_ERR_INCOMPATIBLE if geometries mismatch.
 */
histo_status_t histo_divide(histo_t *target, const histo_t *other);

/**
 * @brief Scales all bin contents and weights by a scalar factor.
 *
 * @param[in,out] h      Histogram handle to scale.
 * @param[in]     factor Scalar multiplier (finite).
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if factor is NaN/Inf.
 */
histo_status_t histo_scale(histo_t *h, double factor);

/**
 * @brief Normalizes the histogram such that total in-range weight equals target_area.
 *
 * @param[in,out] h           Histogram handle to normalize.
 * @param[in]     target_area Desired integrated area (finite, target_area > 0.0).
 * @return HISTO_OK on success, HISTO_ERR_EMPTY if zero weight, or HISTO_ERR_INVALID_ARG.
 */
histo_status_t histo_normalize(histo_t *h, double target_area);

/**
 * @brief Merges adjacent uniform bins by an integer rebinning factor.
 *
 * @param[in] src    Source uniform histogram.
 * @param[in] factor Positive integer rebinning factor (nbins must be divisible by factor).
 * @return Pointer to newly allocated rebinned histogram, or NULL on error.
 */
histo_t* histo_rebin(const histo_t *src, uint32_t factor);

/**
 * @brief Extracts a subset slice of bins [start_bin, end_bin].
 *
 * @param[in] src       Source histogram.
 * @param[in] start_bin First bin index to include.
 * @param[in] end_bin   Last bin index to include (inclusive).
 * @param[in] empty     If true, allocate new sliced structure with zero counts.
 * @return Pointer to newly allocated sliced histogram, or NULL on error.
 */
histo_t* histo_slice(const histo_t *src, uint32_t start_bin, uint32_t end_bin, bool empty);

/**
 * @brief Generates a Cumulative Distribution Function (CDF) histogram.
 *
 * @param[in] src             Source histogram.
 * @param[in] prenormalization Normalization target (e.g. 1.0 or 100.0).
 * @return Pointer to newly allocated CDF histogram, or NULL on error.
 */
histo_t* histo_cdf(const histo_t *src, double prenormalization);

/* ========================================================================= */
/* Serialization & Deserialization                                           */
/* ========================================================================= */

/**
 * @brief Calculates exact byte capacity required for canonical binary serialization.
 *
 * @param[in] h Histogram handle.
 * @return Total byte length required (256-byte header + Little-Endian payloads).
 */
size_t histo_serialize_binary_size(const histo_t *h);

/**
 * @brief Serializes histogram into a caller-allocated binary buffer.
 *
 * @param[in]  h        Histogram handle to serialize.
 * @param[out] buf      Caller-allocated destination buffer.
 * @param[in]  capacity Byte capacity of buf.
 * @return HISTO_OK on success, or HISTO_ERR_SERIALIZATION if capacity too small.
 */
histo_status_t histo_serialize_binary_into(const histo_t *h, void *buf, size_t capacity);

/**
 * @brief Serializes histogram into a newly heap-allocated binary buffer.
 *
 * Buffer must be freed with histo_free_buffer().
 *
 * @param[in]  h        Histogram handle to serialize.
 * @param[out] out_buf  Pointer receiving address of newly allocated buffer.
 * @param[out] out_size Pointer receiving serialized byte size.
 * @return HISTO_OK on success, or HISTO_ERR_NOMEM on allocation failure.
 */
histo_status_t histo_serialize_binary(const histo_t *h, void **out_buf, size_t *out_size);

/**
 * @brief Deserializes a histogram from a canonical binary byte buffer.
 *
 * @param[in]  buf   Pointer to serialized binary buffer.
 * @param[in]  size  Byte length of buffer.
 * @param[out] out_h Pointer receiving address of newly deserialized histogram.
 * @return HISTO_OK on success, or HISTO_ERR_DESERIALIZATION on format corruption.
 */
histo_status_t histo_deserialize_binary(const void *buf, size_t size, histo_t **out_h);

/**
 * @brief Serializes a histogram into a newly allocated JSON string.
 *
 * Buffer must be freed with histo_free_buffer().
 *
 * @param[in]  h        Histogram handle to serialize.
 * @param[out] out_json Pointer receiving address of newly allocated null-terminated JSON string.
 * @return HISTO_OK on success, or appropriate error code.
 */
histo_status_t histo_serialize_json(const histo_t *h, char **out_json);

/**
 * @brief Deserializes a histogram from a JSON string.
 *
 * @param[in]  json_str Null-terminated JSON string.
 * @param[out] out_h    Pointer receiving address of newly deserialized histogram.
 * @return HISTO_OK on success, or HISTO_ERR_DESERIALIZATION on format corruption.
 */
histo_status_t histo_deserialize_json(const char *json_str, histo_t **out_h);

/**
 * @brief Frees a heap buffer allocated by serialization routines. Safe with NULL.
 *
 * @param[in] buf Buffer pointer to free.
 */
void histo_free_buffer(void *buf);

/**
 * @brief Migrates a binary serialized histogram to the current format version.
 *
 * If the input buffer is already at the current format version, it allocates
 * an exact copy. The returned buffer must be freed with histo_free_buffer().
 *
 * @param[in]  in_buf   Pointer to serialized binary buffer.
 * @param[in]  in_size  Byte length of input buffer.
 * @param[out] out_buf  Pointer receiving address of newly allocated migrated buffer.
 * @param[out] out_size Pointer receiving byte length of migrated buffer.
 * @return HISTO_OK on success, or appropriate error code.
 */
histo_status_t histo_migrate_binary(const void *in_buf, size_t in_size, void **out_buf, size_t *out_size);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_HISTO_H */
