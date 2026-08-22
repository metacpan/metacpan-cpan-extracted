/**
 * @file fit.h
 * @brief Non-linear regression, curve fitting engine, and parametric models.
 */

#ifndef LIBHISTO_FIT_H
#define LIBHISTO_FIT_H

/**
 * @file fit.h
 * @brief Curve Fitting & Non-Linear Regression engine for libhisto.
 *
 * Provides high-performance parameter estimation and curve fitting for 1D histograms.
 * Supports:
 * - Built-in models: Gaussian, Exponential Decay, Polynomial (up to degree 10),
 *   Breit-Wigner / Cauchy-Lorentz, and Power Law.
 * - Arbitrary user-defined parametric models with finite-difference or analytical gradients.
 * - Levenberg-Marquardt (LM) non-linear least squares with adaptive damping.
 * - Direct Linear Least Squares (Normal equations / QR factorization) for polynomials.
 * - Weighted Chi-Square minimization and Poisson Maximum Likelihood Estimation (Cash / Baker-Cousins).
 * - Parameter box constraints (lower/upper bounds) and fixed/frozen parameter masks.
 * - Automatic moment-based initial parameter guess estimation.
 * - Comprehensive fit diagnostics: full covariance/correlation matrices, parameter standard errors,
 *   chi-square, degrees of freedom, p-values (Chi2 CDF upper tail), AIC, and BIC.
 */

#include "histo/histo.h"
#include "histo/types.h"
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @brief Maximum supported polynomial degree */
#define HISTO_FIT_MAX_POLY_DEGREE 10

/**
 * @brief Built-in parametric model types.
 */
typedef enum histo_fit_model {
    /**
     * @brief Gaussian / Normal distribution peak.
     * f(x; A, mu, sigma) = A * exp(-(x - mu)^2 / (2 * sigma^2))
     * Parameters (3):
     *   params[0] = A     (amplitude / peak height)
     *   params[1] = mu    (mean / center)
     *   params[2] = sigma (standard deviation / width, > 0)
     */
    HISTO_FIT_MODEL_GAUSSIAN = 0,

    /**
     * @brief Exponential decay with constant baseline.
     * f(x; A, lambda, C) = A * exp(-lambda * x) + C
     * Parameters (3):
     *   params[0] = A      (amplitude)
     *   params[1] = lambda (decay rate)
     *   params[2] = C      (constant baseline)
     */
    HISTO_FIT_MODEL_EXPONENTIAL = 1,

    /**
     * @brief Polynomial of degree d (0 <= d <= 10).
     * f(x; c0, c1, ..., cd) = c0 + c1*x + c2*x^2 + ... + cd*x^d
     * Parameters (degree + 1):
     *   params[j] = c_j (coefficient of x^j)
     */
    HISTO_FIT_MODEL_POLYNOMIAL = 2,

    /**
     * @brief Breit-Wigner / Cauchy-Lorentz resonance peak.
     * f(x; A, M, Gamma) = (A / pi) * (Gamma / 2) / ((x - M)^2 + (Gamma / 2)^2)
     * Parameters (3):
     *   params[0] = A     (scale / total area)
     *   params[1] = M     (resonance peak position / mass)
     *   params[2] = Gamma (full width at half maximum / FWHM, > 0)
     */
    HISTO_FIT_MODEL_BREIT_WIGNER = 3,

    /**
     * @brief Power law with origin offset.
     * f(x; A, k, x0) = A * (x - x0)^k   for x > x0
     * Parameters (3):
     *   params[0] = A  (amplitude)
     *   params[1] = k  (power exponent)
     *   params[2] = x0 (origin shift / threshold)
     */
    HISTO_FIT_MODEL_POWER_LAW = 4,

    /**
     * @brief Log-Normal distribution.
     * f(x; A, mu, sigma) = (A / (x * sigma * sqrt(2*pi))) * exp(-(ln(x) - mu)^2 / (2 * sigma^2))  for x > 0
     * Parameters (3):
     *   params[0] = A     (scale / total area)
     *   params[1] = mu    (log-scale location / mean of ln(x))
     *   params[2] = sigma (log-scale scale / std dev of ln(x), > 0)
     */
    HISTO_FIT_MODEL_LOG_NORMAL = 5,

    /**
     * @brief Gaussian peak with linear baseline background.
     * f(x; A, mu, sigma, c0, c1) = A * exp(-(x - mu)^2 / (2 * sigma^2)) + c0 + c1 * x
     * Parameters (5):
     *   params[0] = A     (peak amplitude)
     *   params[1] = mu    (peak mean / center)
     *   params[2] = sigma (peak standard deviation, > 0)
     *   params[3] = c0    (background intercept)
     *   params[4] = c1    (background slope)
     */
    HISTO_FIT_MODEL_GAUSSIAN_PLUS_LINEAR = 6,

    /**
     * @brief Weibull distribution.
     * f(x; A, k, lambda) = A * (k / lambda) * (x / lambda)^(k - 1) * exp(-(x / lambda)^k)  for x > 0
     * Parameters (3):
     *   params[0] = A      (scale / total area)
     *   params[1] = k      (shape parameter, > 0)
     *   params[2] = lambda (scale parameter, > 0)
     */
    HISTO_FIT_MODEL_WEIBULL = 7,

    /**
     * @brief Gamma / Erlang distribution.
     * f(x; A, k, theta) = A * (x^(k - 1) * exp(-x / theta)) / (Gamma(k) * theta^k)  for x > 0
     * Parameters (3):
     *   params[0] = A     (scale / total area)
     *   params[1] = k     (shape parameter, > 0)
     *   params[2] = theta (scale parameter, > 0)
     */
    HISTO_FIT_MODEL_GAMMA = 8,

    /**
     * @brief Poisson distribution (continuous Gamma formulation).
     * f(x; A, lambda) = A * (lambda^x * exp(-lambda)) / Gamma(x + 1)  for x >= 0
     * Parameters (2):
     *   params[0] = A      (scale / amplitude)
     *   params[1] = lambda (rate / expected count, > 0)
     */
    HISTO_FIT_MODEL_POISSON = 9,

    /**
     * @brief Laplace / Double Exponential distribution.
     * f(x; A, mu, b) = (A / (2 * b)) * exp(-|x - mu| / b)
     * Parameters (3):
     *   params[0] = A  (scale / amplitude)
     *   params[1] = mu (location / median)
     *   params[2] = b  (scale / diversity, > 0)
     */
    HISTO_FIT_MODEL_LAPLACE = 10,

    /**
     * @brief Custom user-defined callback function.
     */
    HISTO_FIT_MODEL_CUSTOM = 11
} histo_fit_model_t;

/**
 * @brief Objective loss function / statistic to minimize.
 */
typedef enum histo_fit_loss {
    /**
     * @brief Pearson/Neyman Chi-Square weighted by bin variances.
     * Chi2 = sum_i (y_i - f(x_i))^2 / sigma_i^2
     * Variance sigma_i^2 is taken from sum_w2 if tracked, else max(y_i, 1.0).
     */
    HISTO_FIT_LOSS_CHI2 = 0,

    /**
     * @brief Binned Poisson Maximum Likelihood Estimation (Cash / Baker-Cousins deviance).
     * -2 ln L = 2 * sum_i [ f(x_i) - y_i + y_i * ln(y_i / f(x_i)) ]
     * Highly recommended for low-count, Poisson, or sparse histograms.
     */
    HISTO_FIT_LOSS_POISSON_MLE = 1,

    /**
     * @brief Unweighted Least Squares (assumes uniform unit variance).
     * SS = sum_i (y_i - f(x_i))^2
     */
    HISTO_FIT_LOSS_UNWEIGHTED_LS = 2
} histo_fit_loss_t;

/**
 * @brief Fitting algorithm strategy.
 */
typedef enum histo_fit_algo {
    /** @brief Automatically choose best algorithm (Linear LS for polynomials with Chi2/LS, LM otherwise) */
    HISTO_FIT_ALGO_AUTO = 0,

    /** @brief Levenberg-Marquardt non-linear least squares with adaptive damping */
    HISTO_FIT_ALGO_LEVENBERG_MARQUARDT = 1,

    /** @brief Direct Linear Least Squares via Normal Equations / QR factorization */
    HISTO_FIT_ALGO_LINEAR_LS = 2
} histo_fit_algo_t;

/**
 * @brief Fitting convergence and status return codes.
 */
typedef enum histo_fit_status {
    HISTO_FIT_CONVERGED_FTOL     =  0, /**< Converged: relative reduction in sum of squares <= ftol */
    HISTO_FIT_CONVERGED_XTOL     =  1, /**< Converged: relative step size in parameters <= xtol */
    HISTO_FIT_CONVERGED_GTOL     =  2, /**< Converged: orthogonal gradient norm <= gtol */
    HISTO_FIT_CONVERGED_EXACT    =  3, /**< Converged: direct exact linear solution obtained */
    HISTO_FIT_MAX_ITERATIONS     = -1, /**< Exceeded maximum allowed iterations without convergence */
    HISTO_FIT_ERR_INVALID_ARG    = -2, /**< Invalid parameter, NULL pointer, or illegal range */
    HISTO_FIT_ERR_SINGULAR       = -3, /**< Singular or rank-deficient Hessian/Jacobian matrix */
    HISTO_FIT_ERR_DIVERGENCE     = -4, /**< Objective function diverged or encountered NaN/Inf */
    HISTO_FIT_ERR_NO_DATA        = -5, /**< Insufficient non-empty bins in fitting range */
    HISTO_FIT_ERR_NOMEM          = -6  /**< Memory allocation failed */
} histo_fit_status_t;

/**
 * @brief Function pointer signature for custom parametric models.
 *
 * @param x Coordinate value (bin center).
 * @param params Array of model parameters.
 * @param userdata User context pointer.
 * @return Evaluated model value f(x; params).
 */
typedef double (*histo_fit_fn)(double x, const double *params, void *userdata);

/**
 * @brief Optional analytical gradient callback for custom parametric models.
 *
 * @param x Coordinate value (bin center).
 * @param params Array of model parameters.
 * @param grad Output array of size num_params to store partial derivatives [df/dp_0, df/dp_1, ...].
 * @param userdata User context pointer.
 */
typedef void (*histo_fit_grad_fn)(double x, const double *params, double *grad, void *userdata);

/**
 * @brief Configuration options and constraints for curve fitting.
 */
typedef struct histo_fit_options {
    uint32_t           max_iterations; /**< Maximum number of LM iterations (default: 500) */
    double             ftol;           /**< Relative reduction tolerance in loss (default: 1e-8) */
    double             xtol;           /**< Relative parameter step tolerance (default: 1e-8) */
    double             gtol;           /**< Orthogonal gradient tolerance (default: 1e-8) */
    double             initial_lambda; /**< Initial Marquardt damping parameter (default: 1e-3) */
    histo_fit_loss_t   loss_type;      /**< Loss statistic to minimize (default: HISTO_FIT_LOSS_CHI2) */
    histo_fit_algo_t   algo;           /**< Algorithm choice (default: HISTO_FIT_ALGO_AUTO) */
    uint32_t           poly_degree;    /**< Degree for polynomial models (0 to 10, default: 1) */
    double             range_min;      /**< Lower bound of fit range (default: 0.0) */
    double             range_max;      /**< Upper bound of fit range (default: 0.0, if min >= max: full range) */
    const double      *lower_bounds;   /**< Optional array of lower box constraints (or NULL) */
    const double      *upper_bounds;   /**< Optional array of upper box constraints (or NULL) */
    const bool        *fixed_params;   /**< Optional array of flags indicating frozen parameters (or NULL) */
    histo_fit_grad_fn  grad_fn;        /**< Optional analytical gradient callback (or NULL for finite differences) */
    void              *userdata;       /**< Optional context pointer passed to callbacks */
} histo_fit_options_t;

/**
 * @brief Comprehensive curve fitting results structure.
 */
typedef struct histo_fit_result {
    size_t             num_params;     /**< Number of model parameters */
    double            *params;         /**< Array of optimal fitted parameters */
    double            *param_errors;   /**< Array of estimated parameter standard errors (sqrt(Cov_ii)) */
    double            *cov_matrix;     /**< Covariance matrix (num_params x num_params, row-major) */
    double            *cor_matrix;     /**< Correlation matrix (num_params x num_params, row-major) */
    double             chi2;           /**< Final Chi-Square (or Poisson deviance) */
    int                ndf;            /**< Number of degrees of freedom (N_bins - N_free_params) */
    double             reduced_chi2;   /**< Reduced Chi-Square (chi2 / ndf) */
    double             p_value;        /**< Goodness-of-fit p-value: P(Chi2 >= chi2_obs | ndf) */
    double             log_likelihood; /**< Maximized log-likelihood ln(L) */
    double             aic;            /**< Akaike Information Criterion (2k - 2 ln L) */
    double             bic;            /**< Bayesian Information Criterion (k ln N - 2 ln L) */
    uint32_t           iterations;     /**< Total iterations performed */
    bool               converged;      /**< True if fitting successfully converged */
    histo_fit_status_t status;         /**< Convergence status code */
    const char        *stop_reason;    /**< Human-readable description of convergence / stop reason */
} histo_fit_result_t;

/**
 * @brief Initialize a fitting options structure with standard default values.
 *
 * Defaults:
 *   max_iterations = 500
 *   ftol = 1e-8, xtol = 1e-8, gtol = 1e-8
 *   initial_lambda = 1e-3
 *   loss_type = HISTO_FIT_LOSS_CHI2
 *   algo = HISTO_FIT_ALGO_AUTO
 *   poly_degree = 1 (linear)
 *   range_min = 0.0, range_max = 0.0 (full histogram range)
 *   lower_bounds = NULL, upper_bounds = NULL, fixed_params = NULL
 *   grad_fn = NULL, userdata = NULL
 *
 * @param opts Pointer to options structure to initialize.
 * @return HISTO_OK on success, or HISTO_ERR_INVALID_ARG if opts is NULL.
 */
histo_status_t histo_fit_options_init(histo_fit_options_t *opts);

/**
 * @brief Get the number of parameters required for a built-in model.
 *
 * @param model Built-in model type.
 * @param poly_degree Degree if model is HISTO_FIT_MODEL_POLYNOMIAL (ignored otherwise).
 * @return Number of parameters, or 0 on error / invalid model.
 */
size_t histo_fit_model_num_params(histo_fit_model_t model, uint32_t poly_degree);

/**
 * @brief Automatically estimate initial parameter guesses from histogram statistics and shape.
 *
 * Employs moment analysis (mean, variance, integral), mode detection, logarithmic slope
 * estimation, and baseline analysis to generate robust initial starting points.
 *
 * @param h Pointer to histogram.
 * @param model Built-in model type.
 * @param opts Optional fit configuration (e.g. range window, poly_degree) or NULL for defaults.
 * @param initial_params Output array to receive estimated parameters (must hold histo_fit_model_num_params()).
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo_fit_estimate_initial_params(
    const histo_t             *h,
    histo_fit_model_t          model,
    const histo_fit_options_t *opts,
    double                    *initial_params
);

/**
 * @brief Fit a built-in parametric model to a histogram.
 *
 * @param h Pointer to histogram to fit.
 * @param model Built-in parametric model (Gaussian, Exponential, Polynomial, Breit-Wigner, Power Law).
 * @param initial_params Initial parameter guess array, or NULL to use automatic moment-based estimation.
 * @param opts Optional fit configuration (bounds, fixed parameters, loss type) or NULL for defaults.
 * @param result Output pointer to receive allocated fit results. Must be freed with histo_fit_result_destroy().
 * @return HISTO_OK on success (or convergence warning/status), or error code.
 */
histo_status_t histo_fit_model(
    const histo_t             *h,
    histo_fit_model_t          model,
    const double              *initial_params,
    const histo_fit_options_t *opts,
    histo_fit_result_t       **result
);

/**
 * @brief Fit an arbitrary user-defined custom parametric model to a histogram.
 *
 * @param h Pointer to histogram to fit.
 * @param fn Custom model evaluation function callback.
 * @param num_params Number of parameters required by fn.
 * @param initial_params Initial parameter guess array (must not be NULL for custom models).
 * @param opts Optional fit configuration (bounds, fixed parameters, grad_fn, loss type) or NULL.
 * @param result Output pointer to receive allocated fit results. Must be freed with histo_fit_result_destroy().
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo_fit_custom(
    const histo_t             *h,
    histo_fit_fn               fn,
    size_t                     num_params,
    const double              *initial_params,
    const histo_fit_options_t *opts,
    histo_fit_result_t       **result
);

/**
 * @brief Evaluate a built-in parametric model at a given coordinate x.
 *
 * @param model Built-in model type.
 * @param params Array of model parameters.
 * @param num_params Number of parameters.
 * @param x Coordinate value.
 * @return Evaluated model value f(x; params).
 */
double histo_fit_eval(
    histo_fit_model_t model,
    const double     *params,
    size_t            num_params,
    double            x
);

/**
 * @brief Evaluate the analytical parameter gradient of a built-in parametric model at coordinate x.
 *
 * @param model Built-in model type.
 * @param params Array of model parameters.
 * @param num_params Number of parameters.
 * @param x Coordinate value.
 * @param grad Output array to receive partial derivatives [df/dp0, df/dp1, ...]. Must hold num_params doubles.
 * @return HISTO_OK on success, or error code.
 */
histo_status_t histo_fit_eval_gradient(
    histo_fit_model_t model,
    const double     *params,
    size_t            num_params,
    double            x,
    double           *grad
);

/**
 * @brief Evaluate a custom parametric model callback at a given coordinate x.
 *
 * @param fn Custom model function pointer.
 * @param params Array of model parameters.
 * @param x Coordinate value.
 * @param userdata User context pointer.
 * @return Evaluated model value f(x; params).
 */
double histo_fit_eval_custom(
    histo_fit_fn  fn,
    const double *params,
    double        x,
    void         *userdata
);

/**
 * @brief Free all memory associated with a fit result structure.
 *
 * Safe to call with NULL.
 *
 * @param res Pointer to fit result structure to destroy.
 */
void histo_fit_result_destroy(histo_fit_result_t *res);

/**
 * @brief Compute the upper-tail cumulative probability p-value for a Chi-Square distribution.
 *
 * Calculates P(X >= chi2 | ndf) = Gamma(ndf/2, chi2/2) / Gamma(ndf/2).
 *
 * @param chi2 Observed Chi-Square value (>= 0).
 * @param ndf Degrees of freedom (> 0).
 * @return Upper tail p-value in [0, 1], or NAN on invalid arguments.
 */
double histo_fit_chi2_p_value(double chi2, int ndf);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_FIT_H */
