/**
 * @file kde.h
 * @brief Public C API for 1D Kernel Density Estimation and bandwidth rules.
 */

#ifndef LIBHISTO_KDE_H
#define LIBHISTO_KDE_H

/**
 * @file kde.h
 * @brief Kernel Density Estimation (KDE) engine for libhisto.
 *
 * Provides 1-dimensional non-parametric continuous density estimation over raw samples
 * or discrete histogram bins with multiple kernel types, automatic bandwidth selection,
 * cumulative distribution evaluation, and random sampling.
 */

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "types.h"
#include "histo.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Kernel weighting functions supported by the KDE engine.
 */
typedef enum histo_kde_kernel {
    HISTO_KDE_KERNEL_GAUSSIAN     = 0,  /**< Gaussian kernel: K(u) = (1/sqrt(2pi)) * exp(-u^2 / 2) [Default] */
    HISTO_KDE_KERNEL_EPANECHNIKOV = 1,  /**< Epanechnikov kernel: K(u) = 3/4 * (1 - u^2) for |u| <= 1 */
    HISTO_KDE_KERNEL_UNIFORM      = 2,  /**< Uniform / Boxcar kernel: K(u) = 1/2 for |u| <= 1 */
    HISTO_KDE_KERNEL_TRIANGULAR   = 3,  /**< Triangular kernel: K(u) = 1 - |u| for |u| <= 1 */
    HISTO_KDE_KERNEL_BIWEIGHT     = 4,  /**< Biweight / Quartic kernel: K(u) = 15/16 * (1 - u^2)^2 for |u| <= 1 */
    HISTO_KDE_KERNEL_COSINE       = 5   /**< Cosine kernel: K(u) = (pi/4) * cos(pi/2 * u) for |u| <= 1 */
} histo_kde_kernel_t;

/**
 * @brief Automated bandwidth selection rules.
 */
typedef enum histo_kde_bandwidth_method {
    HISTO_KDE_BANDWIDTH_SILVERMAN = 0,  /**< Silverman's rule of thumb: 0.9 * min(std, IQR/1.34) * n^(-1/5) [Default] */
    HISTO_KDE_BANDWIDTH_SCOTT     = 1,  /**< Scott's rule: 1.059 * std * n^(-1/5) */
    HISTO_KDE_BANDWIDTH_MANUAL    = 2   /**< Explicit user-provided bandwidth parameter */
} histo_kde_bandwidth_method_t;

/**
 * @brief Configuration options for KDE construction.
 */
typedef struct histo_kde_options {
    histo_kde_kernel_t           kernel;     /**< Kernel weighting function (default: GAUSSIAN) */
    histo_kde_bandwidth_method_t bw_method;  /**< Bandwidth calculation rule (default: SILVERMAN) */
    double                       bandwidth;  /**< Explicit bandwidth if bw_method == MANUAL (must be > 0) */
    double                       bw_adjust;  /**< Multiplicative bandwidth modifier (default: 1.0) */
} histo_kde_options_t;

/**
 * @brief Opaque KDE model handle.
 */
typedef struct histo_kde histo_kde_t;

/**
 * @brief Returns the default KDE configuration options.
 *
 * Defaults: Gaussian kernel, Silverman bandwidth selector, bw_adjust = 1.0.
 *
 * @return Initialized histo_kde_options_t structure.
 */
histo_kde_options_t histo_kde_default_options(void);

/**
 * @brief Constructs a KDE model from an array of sample values and optional weights.
 *
 * @param[in] n       Number of samples (n >= 1).
 * @param[in] samples Array of finite sample values.
 * @param[in] weights Optional array of positive sample weights (NULL for unit weights).
 * @param[in] opts    Optional configuration options (NULL uses defaults).
 * @return Pointer to initialized KDE handle, or NULL on failure.
 */
histo_kde_t* histo_kde_create(size_t n, const double *samples, const double *weights, const histo_kde_options_t *opts);

/**
 * @brief Constructs a KDE model directly from an existing histogram.
 *
 * Places kernel masses at bin centers weighted by bin contents, incorporating
 * Sheppard's variance correction for discretization.
 *
 * @param[in] h    Input histogram handle.
 * @param[in] opts Optional configuration options (NULL uses defaults).
 * @return Pointer to initialized KDE handle, or NULL on failure.
 */
histo_kde_t* histo_kde_create_from_histo(const histo_t *h, const histo_kde_options_t *opts);

/**
 * @brief Destroys a KDE model and releases all associated memory.
 *
 * Safe to call with NULL.
 *
 * @param[in] kde Pointer to KDE handle.
 */
void histo_kde_destroy(histo_kde_t *kde);

/**
 * @brief Evaluates the estimated probability density function (PDF) at coordinate x.
 *
 * @param[in] kde KDE handle.
 * @param[in] x   Evaluation coordinate.
 * @return Estimated probability density value f(x) >= 0, or 0.0 on error.
 */
double histo_kde_eval(const histo_kde_t *kde, double x);

/**
 * @brief Evaluates the estimated probability density function (PDF) across an array of coordinates.
 *
 * @param[in]  kde     KDE handle.
 * @param[in]  n       Number of coordinates to evaluate.
 * @param[in]  x_in    Input coordinates array.
 * @param[out] pdf_out Output array for evaluated density values.
 * @return HISTO_OK on success, or error status code.
 */
histo_status_t histo_kde_eval_n(const histo_kde_t *kde, size_t n, const double *x_in, double *pdf_out);

/**
 * @brief Evaluates the estimated cumulative distribution function (CDF) at coordinate x.
 *
 * Computes F(x) = P(X <= x) = integral_{-inf}^x f(t) dt.
 *
 * @param[in] kde KDE handle.
 * @param[in] x   Evaluation coordinate.
 * @return Estimated cumulative probability in [0.0, 1.0], or 0.0 on error.
 */
double histo_kde_cdf(const histo_kde_t *kde, double x);

/**
 * @brief Computes the estimated quantile value for probability q in [0, 1].
 *
 * Solves F(x) = q via numerical root finding over the continuous CDF.
 *
 * @param[in]  kde     KDE handle.
 * @param[in]  q       Quantile probability in [0.0, 1.0].
 * @param[out] out_val Pointer to store the computed quantile value.
 * @return HISTO_OK on success, or error status code.
 */
histo_status_t histo_kde_quantile(const histo_kde_t *kde, double q, double *out_val);

/**
 * @brief Generates pseudo-random synthetic samples drawn from the KDE density.
 *
 * @param[in]  kde         KDE handle.
 * @param[in]  n           Number of synthetic samples to generate.
 * @param[out] out_samples Output array to store generated samples.
 * @param[in]  seed        PRNG seed (0 uses non-deterministic or default seed).
 * @return HISTO_OK on success, or error status code.
 */
histo_status_t histo_kde_sample(const histo_kde_t *kde, size_t n, double *out_samples, uint64_t seed);

/**
 * @brief Returns the effective smoothing bandwidth h used by the model.
 *
 * @param[in] kde KDE handle.
 * @return Smoothing bandwidth h > 0, or 0.0 on error.
 */
double histo_kde_get_bandwidth(const histo_kde_t *kde);

/**
 * @brief Returns the kernel function used by the model.
 *
 * @param[in] kde KDE handle.
 * @return Kernel type enum value.
 */
histo_kde_kernel_t histo_kde_get_kernel(const histo_kde_t *kde);

/**
 * @brief Returns the number of sample points or bin centers in the model.
 *
 * @param[in] kde KDE handle.
 * @return Number of data points.
 */
size_t histo_kde_num_points(const histo_kde_t *kde);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_KDE_H */
