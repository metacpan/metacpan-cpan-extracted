/**
 * @file fit.c
 * @brief Curve Fitting & Non-Linear Regression implementation for libhisto.
 */

#include "histo/fit.h"
#include "internal.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* -------------------------------------------------------------------------
 * Mathematical Helper: Regularized Incomplete Gamma Function Q(a, z)
 * Used to compute Chi-Square CDF upper tail p-value: P(X >= chi2 | ndf)
 * ------------------------------------------------------------------------- */

#define GAMMA_MAX_ITER 200
#define GAMMA_EPS      1.0e-14
#define GAMMA_FPMIN    1.0e-30

/**
 * @brief Series expansion of lower incomplete gamma P(a, z).
 */
static double gamma_ser(double a, double z) {
    double sum, del, ap;
    double gln = lgamma(a);
    ap = a;
    del = sum = 1.0 / a;
    for (int n = 1; n <= GAMMA_MAX_ITER; ++n) {
        ap += 1.0;
        del *= z / ap;
        sum += del;
        if (fabs(del) < fabs(sum) * GAMMA_EPS) {
            return sum * exp(-z + a * log(z) - gln);
        }
    }
    return sum * exp(-z + a * log(z) - gln);
}

/**
 * @brief Continued fraction evaluation of upper incomplete gamma Q(a, z).
 */
static double gamma_cf(double a, double z) {
    double gln = lgamma(a);
    double b = z + 1.0 - a;
    double c = 1.0 / GAMMA_FPMIN;
    double d = 1.0 / b;
    double h = d;
    for (int i = 1; i <= GAMMA_MAX_ITER; ++i) {
        double an = -i * (i - a);
        b += 2.0;
        d = an * d + b;
        if (fabs(d) < GAMMA_FPMIN) d = GAMMA_FPMIN;
        c = b + an / c;
        if (fabs(c) < GAMMA_FPMIN) c = GAMMA_FPMIN;
        d = 1.0 / d;
        double del = d * c;
        h *= del;
        if (fabs(del - 1.0) <= GAMMA_EPS) break;
    }
    return exp(-z + a * log(z) - gln) * h;
}

double histo_fit_chi2_p_value(double chi2, int ndf) {
    if (ndf <= 0 || !isfinite(chi2) || chi2 < 0.0) {
        return NAN;
    }
    if (chi2 == 0.0) {
        return 1.0;
    }
    double a = 0.5 * (double)ndf;
    double z = 0.5 * chi2;
    if (z < a + 1.0) {
        double p = gamma_ser(a, z);
        double q = 1.0 - p;
        if (q < 0.0) q = 0.0;
        if (q > 1.0) q = 1.0;
        return q;
    } else {
        double q = gamma_cf(a, z);
        if (q < 0.0) q = 0.0;
        if (q > 1.0) q = 1.0;
        return q;
    }
}

/* -------------------------------------------------------------------------
 * Options and Parameter Utilities
 * ------------------------------------------------------------------------- */

histo_status_t histo_fit_options_init(histo_fit_options_t *opts) {
    if (!opts) {
        return HISTO_ERR_INVALID_ARG;
    }
    opts->max_iterations = 500;
    opts->ftol           = 1.0e-8;
    opts->xtol           = 1.0e-8;
    opts->gtol           = 1.0e-8;
    opts->initial_lambda = 1.0e-3;
    opts->loss_type      = HISTO_FIT_LOSS_CHI2;
    opts->algo           = HISTO_FIT_ALGO_AUTO;
    opts->poly_degree    = 1;
    opts->range_min      = 0.0;
    opts->range_max      = 0.0;
    opts->lower_bounds   = NULL;
    opts->upper_bounds   = NULL;
    opts->fixed_params   = NULL;
    opts->grad_fn        = NULL;
    opts->userdata       = NULL;
    return HISTO_OK;
}

size_t histo_fit_model_num_params(histo_fit_model_t model, uint32_t poly_degree) {
    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN:
            return 3;
        case HISTO_FIT_MODEL_EXPONENTIAL:
            return 3;
        case HISTO_FIT_MODEL_POLYNOMIAL:
            if (poly_degree > HISTO_FIT_MAX_POLY_DEGREE) {
                return 0;
            }
            return (size_t)poly_degree + 1;
        case HISTO_FIT_MODEL_BREIT_WIGNER:
            return 3;
        case HISTO_FIT_MODEL_POWER_LAW:
            return 3;
        case HISTO_FIT_MODEL_CUSTOM:
        default:
            return 0;
    }
}

void histo_fit_result_destroy(histo_fit_result_t *res) {
    if (!res) return;
    free(res->params);
    free(res->param_errors);
    free(res->cov_matrix);
    free(res->cor_matrix);
    free(res);
}

/* -------------------------------------------------------------------------
 * Parametric Model Evaluation & Analytical Gradients
 * ------------------------------------------------------------------------- */

double histo_fit_eval(
    histo_fit_model_t model,
    const double     *params,
    size_t            num_params,
    double            x
) {
    if (!params || !isfinite(x)) {
        return 0.0;
    }
    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN: {
            if (num_params < 3) return 0.0;
            double A     = params[0];
            double mu    = params[1];
            double sigma = params[2];
            if (fabs(sigma) < 1.0e-15 || !isfinite(sigma) || !isfinite(A) || !isfinite(mu)) {
                return 0.0;
            }
            double z = (x - mu) / sigma;
            if (fabs(z) > 40.0) return 0.0;
            return A * exp(-0.5 * z * z);
        }
        case HISTO_FIT_MODEL_EXPONENTIAL: {
            if (num_params < 3) return 0.0;
            double A      = params[0];
            double lambda = params[1];
            double C      = params[2];
            if (!isfinite(A) || !isfinite(lambda) || !isfinite(C)) return 0.0;
            double arg = -lambda * x;
            if (arg > 700.0) return A > 0 ? DBL_MAX : -DBL_MAX;
            if (arg < -700.0) return C;
            return A * exp(arg) + C;
        }
        case HISTO_FIT_MODEL_POLYNOMIAL: {
            if (num_params == 0 || num_params > HISTO_FIT_MAX_POLY_DEGREE + 1) return 0.0;
            double val = params[num_params - 1];
            for (int j = (int)num_params - 2; j >= 0; --j) {
                val = val * x + params[j];
            }
            return isfinite(val) ? val : 0.0;
        }
        case HISTO_FIT_MODEL_BREIT_WIGNER: {
            if (num_params < 3) return 0.0;
            double A     = params[0];
            double M     = params[1];
            double Gamma = params[2];
            if (fabs(Gamma) < 1.0e-15 || !isfinite(Gamma) || !isfinite(A) || !isfinite(M)) {
                return 0.0;
            }
            double gamma_half = 0.5 * fabs(Gamma);
            double diff = x - M;
            double denom = diff * diff + gamma_half * gamma_half;
            if (denom < 1.0e-30) return 0.0;
            return (A / M_PI) * (gamma_half / denom);
        }
        case HISTO_FIT_MODEL_POWER_LAW: {
            if (num_params < 3) return 0.0;
            double A  = params[0];
            double k  = params[1];
            double x0 = params[2];
            if (!isfinite(A) || !isfinite(k) || !isfinite(x0)) return 0.0;
            double dx = x - x0;
            if (dx <= 1.0e-15) return 0.0;
            double val = A * pow(dx, k);
            return isfinite(val) ? val : 0.0;
        }
        default:
            return 0.0;
    }
}

double histo_fit_eval_custom(
    histo_fit_fn  fn,
    const double *params,
    double        x,
    void         *userdata
) {
    if (!fn || !params || !isfinite(x)) {
        return 0.0;
    }
    double val = fn(x, params, userdata);
    return isfinite(val) ? val : 0.0;
}

/* Evaluate model dispatch helper */
static double model_eval_dispatch(
    histo_fit_model_t  model,
    histo_fit_fn       custom_fn,
    const double      *params,
    size_t             num_params,
    double             x,
    void              *userdata
) {
    if (model == HISTO_FIT_MODEL_CUSTOM) {
        return histo_fit_eval_custom(custom_fn, params, x, userdata);
    }
    return histo_fit_eval(model, params, num_params, x);
}

/* Analytical gradient helper */
static bool model_eval_analytical_grad(
    histo_fit_model_t  model,
    const double      *params,
    size_t             num_params,
    double             x,
    double            *grad
) {
    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN: {
            double A     = params[0];
            double mu    = params[1];
            double sigma = params[2];
            if (fabs(sigma) < 1.0e-15) {
                grad[0] = grad[1] = grad[2] = 0.0;
                return true;
            }
            double z = (x - mu) / sigma;
            if (fabs(z) > 40.0) {
                grad[0] = grad[1] = grad[2] = 0.0;
                return true;
            }
            double exp_factor = exp(-0.5 * z * z);
            double f = A * exp_factor;
            grad[0] = exp_factor;
            grad[1] = f * (x - mu) / (sigma * sigma);
            grad[2] = f * (x - mu) * (x - mu) / (sigma * sigma * sigma);
            return true;
        }
        case HISTO_FIT_MODEL_EXPONENTIAL: {
            double A      = params[0];
            double lambda = params[1];
            double arg = -lambda * x;
            if (arg > 700.0 || arg < -700.0) {
                grad[0] = grad[1] = 0.0;
                grad[2] = 1.0;
                return true;
            }
            double exp_val = exp(arg);
            grad[0] = exp_val;
            grad[1] = -A * x * exp_val;
            grad[2] = 1.0;
            return true;
        }
        case HISTO_FIT_MODEL_POLYNOMIAL: {
            double x_pow = 1.0;
            for (size_t j = 0; j < num_params; ++j) {
                grad[j] = x_pow;
                x_pow *= x;
            }
            return true;
        }
        case HISTO_FIT_MODEL_BREIT_WIGNER: {
            double A     = params[0];
            double M     = params[1];
            double Gamma = params[2];
            if (fabs(Gamma) < 1.0e-15) {
                grad[0] = grad[1] = grad[2] = 0.0;
                return true;
            }
            double gamma_half = 0.5 * fabs(Gamma);
            double diff = x - M;
            double denom = diff * diff + gamma_half * gamma_half;
            if (denom < 1.0e-30) {
                grad[0] = grad[1] = grad[2] = 0.0;
                return true;
            }
            double f = (A / M_PI) * (gamma_half / denom);
            grad[0] = (1.0 / M_PI) * (gamma_half / denom);
            grad[1] = f * 2.0 * diff / denom;
            grad[2] = (A / (2.0 * M_PI)) * (diff * diff - gamma_half * gamma_half) / (denom * denom);
            return true;
        }
        case HISTO_FIT_MODEL_POWER_LAW: {
            double A  = params[0];
            double k  = params[1];
            double x0 = params[2];
            double dx = x - x0;
            if (dx <= 1.0e-15) {
                grad[0] = grad[1] = grad[2] = 0.0;
                return true;
            }
            double dx_k = pow(dx, k);
            double f = A * dx_k;
            grad[0] = dx_k;
            grad[1] = f * log(dx);
            grad[2] = (dx > 1.0e-15) ? -A * k * pow(dx, k - 1.0) : 0.0;
            return true;
        }
        default:
            return false;
    }
}

/**
 * @brief Evaluate model gradient at coordinate x (either analytical or finite difference).
 */
static void model_eval_grad(
    histo_fit_model_t          model,
    histo_fit_fn               custom_fn,
    const double              *params,
    size_t                     num_params,
    double                     x,
    const histo_fit_options_t *opts,
    double                    *grad
) {
    if (opts && opts->grad_fn) {
        opts->grad_fn(x, params, grad, opts->userdata);
        return;
    }
    if (model != HISTO_FIT_MODEL_CUSTOM) {
        if (model_eval_analytical_grad(model, params, num_params, x, grad)) {
            return;
        }
    }

    /* Robust finite-difference fallback */
    double temp_p[HISTO_FIT_MAX_POLY_DEGREE + 1];
    double *p_work = (num_params <= HISTO_FIT_MAX_POLY_DEGREE + 1) ? temp_p : (double*)malloc(num_params * sizeof(double));
    if (!p_work) {
        for (size_t j = 0; j < num_params; ++j) grad[j] = 0.0;
        return;
    }
    memcpy(p_work, params, num_params * sizeof(double));

    for (size_t j = 0; j < num_params; ++j) {
        double pj = params[j];
        double h = fabs(pj) * 1.0e-6;
        if (h < 1.0e-8) h = 1.0e-8;

        double lb = (opts && opts->lower_bounds) ? opts->lower_bounds[j] : -DBL_MAX;
        double ub = (opts && opts->upper_bounds) ? opts->upper_bounds[j] : DBL_MAX;

        if (pj + h <= ub && pj - h >= lb) {
            p_work[j] = pj + h;
            double f_plus = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            p_work[j] = pj - h;
            double f_minus = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            grad[j] = (f_plus - f_minus) / (2.0 * h);
        } else if (pj + h <= ub) {
            p_work[j] = pj + h;
            double f_plus = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            p_work[j] = pj;
            double f_curr = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            grad[j] = (f_plus - f_curr) / h;
        } else if (pj - h >= lb) {
            p_work[j] = pj - h;
            double f_minus = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            p_work[j] = pj;
            double f_curr = model_eval_dispatch(model, custom_fn, p_work, num_params, x, opts ? opts->userdata : NULL);
            grad[j] = (f_curr - f_minus) / h;
        } else {
            grad[j] = 0.0;
        }
        p_work[j] = pj;
    }

    if (p_work != temp_p) {
        free(p_work);
    }
}

/* -------------------------------------------------------------------------
 * Automatic Initial Parameter Guess Estimation
 * ------------------------------------------------------------------------- */

histo_status_t histo_fit_estimate_initial_params(
    const histo_t             *h,
    histo_fit_model_t          model,
    const histo_fit_options_t *opts,
    double                    *initial_params
) {
    if (!h || !initial_params) {
        return HISTO_ERR_INVALID_ARG;
    }
    uint32_t nbins = histo_nbins(h);
    if (nbins == 0 || (histo_num_entries(h) == 0 && histo_total_weight(h) == 0.0)) {
        return HISTO_ERR_EMPTY;
    }

    double r_min = 0.0, r_max = 0.0;
    histo_range(h, &r_min, &r_max);
    if (opts && opts->range_min < opts->range_max) {
        r_min = opts->range_min;
        r_max = opts->range_max;
    }

    /* Compute weighted statistics in the fit window */
    double sum_w = 0.0, sum_wx = 0.0, sum_wx2 = 0.0;
    double max_y = -DBL_MAX, min_y = DBL_MAX;
    double x_at_max = r_min, x_at_min = r_min;
    size_t valid_bins = 0;

    for (uint32_t i = 0; i < nbins; ++i) {
        double xc = 0.0, y = 0.0;
        if (histo_bin_center(h, i, &xc) != HISTO_OK) continue;
        if (xc < r_min || xc > r_max) continue;
        if (histo_bin_content(h, i, &y) != HISTO_OK) continue;
        if (!isfinite(y)) continue;

        valid_bins++;
        if (y > max_y) {
            max_y = y;
            x_at_max = xc;
        }
        if (y < min_y) {
            min_y = y;
            x_at_min = xc;
        }
        if (y > 0.0) {
            sum_w += y;
            sum_wx += y * xc;
            sum_wx2 += y * xc * xc;
        }
    }

    if (valid_bins == 0 || sum_w == 0.0) {
        return HISTO_ERR_EMPTY;
    }

    double mean = (sum_w > 0.0) ? (sum_wx / sum_w) : (0.5 * (r_min + r_max));
    double variance = (sum_w > 0.0) ? (sum_wx2 / sum_w - mean * mean) : 1.0;
    if (variance <= 0.0 || !isfinite(variance)) {
        variance = pow((r_max - r_min) / 6.0, 2.0);
    }
    double sigma = sqrt(variance);
    if (sigma <= 1.0e-12) sigma = (r_max - r_min) / 6.0;

    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN: {
            initial_params[0] = (max_y > 0.0) ? max_y : 1.0; /* Amplitude */
            initial_params[1] = (sum_w > 0.0) ? mean : x_at_max; /* Mean */
            initial_params[2] = sigma; /* Sigma */
            return HISTO_OK;
        }
        case HISTO_FIT_MODEL_EXPONENTIAL: {
            double baseline = (min_y >= 0.0 && min_y < max_y) ? min_y : 0.0;
            double amp = (max_y > baseline) ? (max_y - baseline) : 1.0;
            double lambda = 1.0 / (r_max - r_min > 0.0 ? (r_max - r_min) : 1.0);
            initial_params[0] = amp;
            initial_params[1] = lambda;
            initial_params[2] = baseline;
            return HISTO_OK;
        }
        case HISTO_FIT_MODEL_POLYNOMIAL: {
            uint32_t deg = opts ? opts->poly_degree : 1;
            if (deg > HISTO_FIT_MAX_POLY_DEGREE) return HISTO_ERR_INVALID_ARG;
            for (uint32_t j = 0; j <= deg; ++j) {
                initial_params[j] = 0.0;
            }
            initial_params[0] = (sum_w > 0.0) ? (sum_w / valid_bins) : 0.0;
            if (deg >= 1 && (r_max > r_min)) {
                initial_params[1] = (max_y - min_y) / (x_at_max != x_at_min ? (x_at_max - x_at_min) : (r_max - r_min));
                if (!isfinite(initial_params[1])) initial_params[1] = 0.0;
            }
            return HISTO_OK;
        }
        case HISTO_FIT_MODEL_BREIT_WIGNER: {
            double bin_w = (r_max - r_min) / valid_bins;
            double total_area = (sum_w > 0.0) ? sum_w * bin_w : max_y * (r_max - r_min);
            initial_params[0] = total_area > 0.0 ? total_area : 1.0; /* Amplitude / Area */
            initial_params[1] = x_at_max; /* Resonance mass / center */
            initial_params[2] = 2.0 * sigma; /* Gamma (FWHM) */
            return HISTO_OK;
        }
        case HISTO_FIT_MODEL_POWER_LAW: {
            initial_params[0] = (max_y > 0.0) ? max_y : 1.0; /* Amplitude */
            initial_params[1] = -1.0; /* Exponent */
            initial_params[2] = r_min - 0.1 * (r_max - r_min); /* x0 */
            return HISTO_OK;
        }
        case HISTO_FIT_MODEL_CUSTOM:
        default:
            return HISTO_ERR_INVALID_ARG;
    }
}

/* -------------------------------------------------------------------------
 * Linear Algebra Helpers (Matrix Inversion, Cholesky, System Solve)
 * ------------------------------------------------------------------------- */

/**
 * @brief Solve linear system A * x = b via Cholesky decomposition L * L^T * x = b.
 * Adds diagonal ridge damping if necessary.
 */
static bool solve_cholesky(size_t n, const double *A, const double *b, double *x) {
    if (n == 0) return true;
    double *L = (double*)calloc(n * n, sizeof(double));
    if (!L) return false;

    /* Copy A and add tiny regularization to ensure strict positive-definiteness */
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            L[i * n + j] = A[i * n + j];
        }
        if (L[i * n + i] <= 0.0) {
            L[i * n + i] = 1.0e-12;
        }
    }

    /* Cholesky factorization */
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j <= i; ++j) {
            double sum = L[i * n + j];
            for (size_t k = 0; k < j; ++k) {
                sum -= L[i * n + k] * L[j * n + k];
            }
            if (i == j) {
                if (sum <= 1.0e-15) {
                    /* Not positive definite, add diagonal boost */
                    sum = 1.0e-12;
                }
                L[i * n + j] = sqrt(sum);
            } else {
                L[i * n + j] = sum / L[j * n + j];
            }
        }
    }

    /* Forward substitution: L * y = b */
    double *y = (double*)malloc(n * sizeof(double));
    if (!y) {
        free(L);
        return false;
    }
    for (size_t i = 0; i < n; ++i) {
        double sum = b[i];
        for (size_t k = 0; k < i; ++k) {
            sum -= L[i * n + k] * y[k];
        }
        y[i] = sum / L[i * n + i];
    }

    /* Backward substitution: L^T * x = y */
    for (int i = (int)n - 1; i >= 0; --i) {
        double sum = y[i];
        for (size_t k = (size_t)i + 1; k < n; ++k) {
            sum -= L[k * n + i] * x[k];
        }
        x[i] = sum / L[i * n + i];
    }

    free(y);
    free(L);
    return true;
}

/**
 * @brief Invert a symmetric positive semi-definite matrix A using Gauss-Jordan with partial pivoting.
 */
static bool invert_matrix(size_t n, const double *A, double *A_inv) {
    if (n == 0) return true;
    double *aug = (double*)calloc(n * (2 * n), sizeof(double));
    if (!aug) return false;

    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            aug[i * (2 * n) + j] = A[i * n + j];
        }
        aug[i * (2 * n) + (n + i)] = 1.0;
    }

    for (size_t i = 0; i < n; ++i) {
        /* Find pivot */
        size_t max_row = i;
        double max_val = fabs(aug[i * (2 * n) + i]);
        for (size_t k = i + 1; k < n; ++k) {
            double val = fabs(aug[k * (2 * n) + i]);
            if (val > max_val) {
                max_val = val;
                max_row = k;
            }
        }
        if (max_val < 1.0e-16) {
            /* Singular matrix, regularize diagonal */
            aug[i * (2 * n) + i] += 1.0e-12;
        } else if (max_row != i) {
            for (size_t j = 0; j < 2 * n; ++j) {
                double tmp = aug[i * (2 * n) + j];
                aug[i * (2 * n) + j] = aug[max_row * (2 * n) + j];
                aug[max_row * (2 * n) + j] = tmp;
            }
        }

        double pivot = aug[i * (2 * n) + i];
        for (size_t j = 0; j < 2 * n; ++j) {
            aug[i * (2 * n) + j] /= pivot;
        }

        for (size_t k = 0; k < n; ++k) {
            if (k != i) {
                double factor = aug[k * (2 * n) + i];
                for (size_t j = 0; j < 2 * n; ++j) {
                    aug[k * (2 * n) + j] -= factor * aug[i * (2 * n) + j];
                }
            }
        }
    }

    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            A_inv[i * n + j] = aug[i * (2 * n) + (n + j)];
        }
    }

    free(aug);
    return true;
}

/* -------------------------------------------------------------------------
 * Loss & Residual Evaluation
 * ------------------------------------------------------------------------- */

typedef struct fit_data_point {
    double x;
    double y;
    double w;     /* Weight = 1.0 / (sigma^2) */
    double sigma;
} fit_data_point_t;

static double compute_loss(
    histo_fit_model_t       model,
    histo_fit_fn            custom_fn,
    const double           *params,
    size_t                  num_params,
    const fit_data_point_t *data,
    size_t                  n_points,
    histo_fit_loss_t        loss_type,
    void                   *userdata
) {
    double total = 0.0;
    for (size_t i = 0; i < n_points; ++i) {
        double f = model_eval_dispatch(model, custom_fn, params, num_params, data[i].x, userdata);
        if (!isfinite(f)) return DBL_MAX;

        if (loss_type == HISTO_FIT_LOSS_POISSON_MLE) {
            double y = data[i].y;
            double f_safe = f > 1.0e-12 ? f : 1.0e-12;
            if (y > 0.0) {
                total += 2.0 * (f - y + y * log(y / f_safe));
            } else {
                total += 2.0 * f;
            }
        } else {
            double r = data[i].y - f;
            total += data[i].w * r * r;
        }
    }
    return total;
}

/* -------------------------------------------------------------------------
 * Direct Linear Least Squares for Polynomial Models
 * ------------------------------------------------------------------------- */

static histo_status_t fit_polynomial_linear(
    const fit_data_point_t    *data,
    size_t                     n_points,
    uint32_t                   poly_degree,
    const histo_fit_options_t *opts,
    histo_fit_result_t        *res
) {
    size_t num_params = (size_t)poly_degree + 1;
    res->num_params = num_params;
    res->params = (double*)calloc(num_params, sizeof(double));
    res->param_errors = (double*)calloc(num_params, sizeof(double));
    res->cov_matrix = (double*)calloc(num_params * num_params, sizeof(double));
    res->cor_matrix = (double*)calloc(num_params * num_params, sizeof(double));
    if (!res->params || !res->param_errors || !res->cov_matrix || !res->cor_matrix) {
        return HISTO_ERR_NOMEM;
    }

    /* Construct normal equations: (X^T W X) c = X^T W y */
    double *AtA = (double*)calloc(num_params * num_params, sizeof(double));
    double *Atb = (double*)calloc(num_params, sizeof(double));
    if (!AtA || !Atb) {
        free(AtA);
        free(Atb);
        return HISTO_ERR_NOMEM;
    }

    size_t max_pow = 2 * num_params;
    double *x_pows = (double*)malloc(max_pow * sizeof(double));
    if (!x_pows) {
        free(AtA);
        free(Atb);
        return HISTO_ERR_NOMEM;
    }

    for (size_t i = 0; i < n_points; ++i) {
        double xi = data[i].x;
        double yi = data[i].y;
        double wi = data[i].w;

        x_pows[0] = 1.0;
        for (size_t p = 1; p < max_pow; ++p) {
            x_pows[p] = x_pows[p - 1] * xi;
        }

        for (size_t j = 0; j < num_params; ++j) {
            Atb[j] += wi * yi * x_pows[j];
            for (size_t k = 0; k < num_params; ++k) {
                AtA[j * num_params + k] += wi * x_pows[j + k];
            }
        }
    }
    free(x_pows);

    if (!solve_cholesky(num_params, AtA, Atb, res->params)) {
        free(AtA);
        free(Atb);
        res->status = HISTO_FIT_ERR_SINGULAR;
        res->stop_reason = "Singular normal equations matrix in linear least squares";
        return HISTO_ERR_INVALID_ARG;
    }

    invert_matrix(num_params, AtA, res->cov_matrix);
    free(AtA);
    free(Atb);

    /* Compute Chi2 and residual stats */
    double chi2 = 0.0;
    for (size_t i = 0; i < n_points; ++i) {
        double f = histo_fit_eval(HISTO_FIT_MODEL_POLYNOMIAL, res->params, num_params, data[i].x);
        double r = data[i].y - f;
        chi2 += data[i].w * r * r;
    }

    int ndf = (int)n_points - (int)num_params;
    res->chi2 = chi2;
    res->ndf = ndf;
    res->reduced_chi2 = (ndf > 0) ? (chi2 / ndf) : NAN;
    res->p_value = (ndf > 0) ? histo_fit_chi2_p_value(chi2, ndf) : NAN;

    /* Scale covariance if unweighted */
    if (opts && opts->loss_type == HISTO_FIT_LOSS_UNWEIGHTED_LS && ndf > 0) {
        double s2 = chi2 / (double)ndf;
        for (size_t i = 0; i < num_params * num_params; ++i) {
            res->cov_matrix[i] *= s2;
        }
    }

    /* Calculate standard errors and correlation matrix */
    for (size_t j = 0; j < num_params; ++j) {
        double var = res->cov_matrix[j * num_params + j];
        res->param_errors[j] = (var > 0.0) ? sqrt(var) : 0.0;
    }
    for (size_t j = 0; j < num_params; ++j) {
        for (size_t k = 0; k < num_params; ++k) {
            if (j == k) {
                res->cor_matrix[j * num_params + k] = 1.0;
            } else {
                double denom = res->param_errors[j] * res->param_errors[k];
                res->cor_matrix[j * num_params + k] = (denom > 0.0) ? (res->cov_matrix[j * num_params + k] / denom) : 0.0;
            }
        }
    }

    /* Log-likelihood, AIC, BIC */
    double lnL = -0.5 * chi2;
    for (size_t i = 0; i < n_points; ++i) {
        lnL -= 0.5 * log(2.0 * M_PI * data[i].sigma * data[i].sigma);
    }
    res->log_likelihood = lnL;
    res->aic = 2.0 * (double)num_params - 2.0 * lnL;
    res->bic = (double)num_params * log((double)n_points) - 2.0 * lnL;

    res->iterations = 1;
    res->converged = true;
    res->status = HISTO_FIT_CONVERGED_EXACT;
    res->stop_reason = "Exact linear least squares solution obtained";
    return HISTO_OK;
}

/* -------------------------------------------------------------------------
 * Levenberg-Marquardt Non-Linear Optimization Engine
 * ------------------------------------------------------------------------- */

static histo_status_t fit_levenberg_marquardt(
    histo_fit_model_t          model,
    histo_fit_fn               custom_fn,
    size_t                     num_params,
    const double              *initial_params,
    const fit_data_point_t    *data,
    size_t                     n_points,
    const histo_fit_options_t *opts,
    histo_fit_result_t        *res
) {
    res->num_params = num_params;
    res->params = (double*)calloc(num_params, sizeof(double));
    res->param_errors = (double*)calloc(num_params, sizeof(double));
    res->cov_matrix = (double*)calloc(num_params * num_params, sizeof(double));
    res->cor_matrix = (double*)calloc(num_params * num_params, sizeof(double));
    if (!res->params || !res->param_errors || !res->cov_matrix || !res->cor_matrix) {
        return HISTO_ERR_NOMEM;
    }

    /* Copy initial parameters */
    memcpy(res->params, initial_params, num_params * sizeof(double));

    /* Apply initial box constraints */
    if (opts) {
        for (size_t j = 0; j < num_params; ++j) {
            if (opts->lower_bounds && res->params[j] < opts->lower_bounds[j]) {
                res->params[j] = opts->lower_bounds[j];
            }
            if (opts->upper_bounds && res->params[j] > opts->upper_bounds[j]) {
                res->params[j] = opts->upper_bounds[j];
            }
        }
    }

    /* Identify active (free) parameters */
    size_t n_free = 0;
    size_t active_map[HISTO_FIT_MAX_POLY_DEGREE + 1];
    size_t *map = (num_params <= HISTO_FIT_MAX_POLY_DEGREE + 1) ? active_map : (size_t*)malloc(num_params * sizeof(size_t));
    if (!map) return HISTO_ERR_NOMEM;

    for (size_t j = 0; j < num_params; ++j) {
        bool is_fixed = (opts && opts->fixed_params && opts->fixed_params[j]);
        if (!is_fixed) {
            map[n_free++] = j;
        }
    }

    if (n_free == 0) {
        /* All parameters fixed */
        if (map != active_map) free(map);
        res->chi2 = compute_loss(model, custom_fn, res->params, num_params, data, n_points, opts ? opts->loss_type : HISTO_FIT_LOSS_CHI2, opts ? opts->userdata : NULL);
        res->ndf = (int)n_points;
        res->reduced_chi2 = (n_points > 0) ? (res->chi2 / n_points) : NAN;
        res->p_value = (n_points > 0) ? histo_fit_chi2_p_value(res->chi2, (int)n_points) : NAN;
        res->iterations = 0;
        res->converged = true;
        res->status = HISTO_FIT_CONVERGED_XTOL;
        res->stop_reason = "All parameters fixed; evaluated baseline loss";
        return HISTO_OK;
    }

    uint32_t max_iter = opts ? opts->max_iterations : 500;
    double ftol = opts ? opts->ftol : 1.0e-8;
    double xtol = opts ? opts->xtol : 1.0e-8;
    double gtol = opts ? opts->gtol : 1.0e-8;
    double lambda = opts ? opts->initial_lambda : 1.0e-3;
    histo_fit_loss_t loss_type = opts ? opts->loss_type : HISTO_FIT_LOSS_CHI2;
    void *userdata = opts ? opts->userdata : NULL;

    double current_loss = compute_loss(model, custom_fn, res->params, num_params, data, n_points, loss_type, userdata);
    if (!isfinite(current_loss)) {
        if (map != active_map) free(map);
        res->status = HISTO_FIT_ERR_DIVERGENCE;
        res->stop_reason = "Initial parameter evaluation produced non-finite loss";
        return HISTO_ERR_NON_FINITE;
    }

    /* Working memory for LM iterations */
    double *J = (double*)malloc(n_points * n_free * sizeof(double));
    double *grad_point = (double*)malloc(num_params * sizeof(double));
    double *A = (double*)malloc(n_free * n_free * sizeof(double));
    double *A_damped = (double*)malloc(n_free * n_free * sizeof(double));
    double *b = (double*)malloc(n_free * sizeof(double));
    double *delta_p = (double*)malloc(n_free * sizeof(double));
    double *trial_p = (double*)malloc(num_params * sizeof(double));

    if (!J || !grad_point || !A || !A_damped || !b || !delta_p || !trial_p) {
        free(J); free(grad_point); free(A); free(A_damped); free(b); free(delta_p); free(trial_p);
        if (map != active_map) free(map);
        return HISTO_ERR_NOMEM;
    }

    uint32_t iter = 0;
    bool converged = false;
    histo_fit_status_t status = HISTO_FIT_MAX_ITERATIONS;
    const char *stop_reason = "Maximum iterations reached";

    while (iter < max_iter) {
        iter++;

        /* 1. Build Jacobian J and normal matrix A = J^T W J, and RHS vector b = J^T W r */
        memset(A, 0, n_free * n_free * sizeof(double));
        memset(b, 0, n_free * sizeof(double));

        for (size_t i = 0; i < n_points; ++i) {
            double xi = data[i].x;
            double yi = data[i].y;
            double wi = data[i].w;
            double fi = model_eval_dispatch(model, custom_fn, res->params, num_params, xi, userdata);

            model_eval_grad(model, custom_fn, res->params, num_params, xi, opts, grad_point);

            for (size_t k = 0; k < n_free; ++k) {
                J[i * n_free + k] = grad_point[map[k]];
            }

            if (loss_type == HISTO_FIT_LOSS_POISSON_MLE) {
                double f_safe = fi > 1.0e-12 ? fi : 1.0e-12;
                double weight_poisson = 1.0 / f_safe;
                double diff_poisson = (yi / f_safe) - 1.0;
                for (size_t j = 0; j < n_free; ++j) {
                    double gj = J[i * n_free + j];
                    b[j] += diff_poisson * gj;
                    for (size_t k = j; k < n_free; ++k) {
                        A[j * n_free + k] += weight_poisson * gj * J[i * n_free + k];
                    }
                }
            } else {
                double ri = yi - fi;
                for (size_t j = 0; j < n_free; ++j) {
                    double gj = J[i * n_free + j];
                    b[j] += wi * ri * gj;
                    for (size_t k = j; k < n_free; ++k) {
                        A[j * n_free + k] += wi * gj * J[i * n_free + k];
                    }
                }
            }
        }

        /* Fill symmetric half of A */
        for (size_t j = 0; j < n_free; ++j) {
            for (size_t k = 0; k < j; ++k) {
                A[j * n_free + k] = A[k * n_free + j];
            }
        }

        /* Check gradient tolerance */
        double max_g = 0.0;
        for (size_t j = 0; j < n_free; ++j) {
            if (fabs(b[j]) > max_g) max_g = fabs(b[j]);
        }
        if (max_g <= gtol) {
            converged = true;
            status = HISTO_FIT_CONVERGED_GTOL;
            stop_reason = "Gradient norm below tolerance (gtol)";
            break;
        }

        /* 2. Inner damping loop */
        bool step_accepted = false;
        for (int damp_iter = 0; damp_iter < 12; ++damp_iter) {
            /* Damped normal matrix: A_damped = A + lambda * diag(A) */
            for (size_t j = 0; j < n_free; ++j) {
                for (size_t k = 0; k < n_free; ++k) {
                    A_damped[j * n_free + k] = A[j * n_free + k];
                }
                double diag_val = fabs(A[j * n_free + j]);
                if (diag_val < 1.0e-6) diag_val = 1.0e-6;
                A_damped[j * n_free + j] += lambda * diag_val;
            }

            if (!solve_cholesky(n_free, A_damped, b, delta_p)) {
                lambda *= 10.0;
                continue;
            }

            /* Propose trial step with box constraints */
            memcpy(trial_p, res->params, num_params * sizeof(double));
            for (size_t k = 0; k < n_free; ++k) {
                size_t param_idx = map[k];
                double new_val = res->params[param_idx] + delta_p[k];
                if (opts && opts->lower_bounds && new_val < opts->lower_bounds[param_idx]) {
                    new_val = opts->lower_bounds[param_idx];
                }
                if (opts && opts->upper_bounds && new_val > opts->upper_bounds[param_idx]) {
                    new_val = opts->upper_bounds[param_idx];
                }
                trial_p[param_idx] = new_val;
            }

            double trial_loss = compute_loss(model, custom_fn, trial_p, num_params, data, n_points, loss_type, userdata);

            /* Check step reduction */
            if (isfinite(trial_loss) && trial_loss < current_loss) {
                /* Gain ratio */
                double linear_reduction = 0.0;
                for (size_t k = 0; k < n_free; ++k) {
                    double diag_k = fabs(A[k * n_free + k]);
                    if (diag_k < 1.0e-6) diag_k = 1.0e-6;
                    linear_reduction += delta_p[k] * (b[k] + lambda * diag_k * delta_p[k]);
                }
                double rho = (linear_reduction > 1.0e-15) ? ((current_loss - trial_loss) / linear_reduction) : 1.0;

                /* Check convergence */
                double rel_loss_change = fabs(current_loss - trial_loss) / (current_loss > 1.0 ? current_loss : 1.0);
                double step_norm = 0.0, p_norm = 0.0;
                for (size_t k = 0; k < n_free; ++k) {
                    step_norm += delta_p[k] * delta_p[k];
                    p_norm += res->params[map[k]] * res->params[map[k]];
                }
                double rel_step = (p_norm > 1.0e-12) ? sqrt(step_norm / p_norm) : sqrt(step_norm);

                /* Accept step */
                memcpy(res->params, trial_p, num_params * sizeof(double));
                current_loss = trial_loss;
                step_accepted = true;

                /* Adapt lambda */
                if (rho > 0.75) {
                    lambda = (lambda > 1.0e-12) ? (lambda * 0.3) : 1.0e-12;
                } else if (rho < 0.25) {
                    lambda *= 2.0;
                }

                if (rel_loss_change <= ftol) {
                    converged = true;
                    status = HISTO_FIT_CONVERGED_FTOL;
                    stop_reason = "Relative reduction in loss below tolerance (ftol)";
                } else if (rel_step <= xtol) {
                    converged = true;
                    status = HISTO_FIT_CONVERGED_XTOL;
                    stop_reason = "Relative parameter step below tolerance (xtol)";
                }
                break;
            } else {
                /* Step rejected, increase damping */
                lambda = (lambda < 1.0e16) ? (lambda * 10.0) : 1.0e16;
            }
        }

        if (converged) break;
        if (!step_accepted && lambda >= 1.0e16) {
            status = HISTO_FIT_MAX_ITERATIONS;
            stop_reason = "Damping parameter exceeded maximum bound";
            break;
        }
    }

    /* 3. Compute final covariance matrix and statistics */
    /* Recompute curvature matrix A at optimal parameters */
    memset(A, 0, n_free * n_free * sizeof(double));
    for (size_t i = 0; i < n_points; ++i) {
        double xi = data[i].x;
        double wi = data[i].w;
        double fi = model_eval_dispatch(model, custom_fn, res->params, num_params, xi, userdata);
        model_eval_grad(model, custom_fn, res->params, num_params, xi, opts, grad_point);

        double w_cur = wi;
        if (loss_type == HISTO_FIT_LOSS_POISSON_MLE) {
            double f_safe = fi > 1.0e-12 ? fi : 1.0e-12;
            w_cur = 1.0 / f_safe;
        }
        for (size_t j = 0; j < n_free; ++j) {
            double gj = grad_point[map[j]];
            for (size_t k = j; k < n_free; ++k) {
                A[j * n_free + k] += w_cur * gj * grad_point[map[k]];
            }
        }
    }
    for (size_t j = 0; j < n_free; ++j) {
        for (size_t k = 0; k < j; ++k) {
            A[j * n_free + k] = A[k * n_free + j];
        }
    }

    double *A_inv = (double*)calloc(n_free * n_free, sizeof(double));
    if (A_inv) {
        invert_matrix(n_free, A, A_inv);
        /* Embed into full num_params x num_params covariance matrix */
        for (size_t j = 0; j < n_free; ++j) {
            for (size_t k = 0; k < n_free; ++k) {
                res->cov_matrix[map[j] * num_params + map[k]] = A_inv[j * n_free + k];
            }
        }
        free(A_inv);
    }

    /* Compute standard Chi-Square */
    double final_chi2 = 0.0;
    for (size_t i = 0; i < n_points; ++i) {
        double f = model_eval_dispatch(model, custom_fn, res->params, num_params, data[i].x, userdata);
        double r = data[i].y - f;
        final_chi2 += data[i].w * r * r;
    }

    int ndf = (int)n_points - (int)n_free;
    res->chi2 = (loss_type == HISTO_FIT_LOSS_POISSON_MLE) ? current_loss : final_chi2;
    res->ndf = ndf;
    res->reduced_chi2 = (ndf > 0) ? (final_chi2 / ndf) : NAN;
    res->p_value = (ndf > 0) ? histo_fit_chi2_p_value(final_chi2, ndf) : NAN;

    /* Scale covariance if unweighted */
    if (opts && opts->loss_type == HISTO_FIT_LOSS_UNWEIGHTED_LS && ndf > 0) {
        double s2 = final_chi2 / (double)ndf;
        for (size_t i = 0; i < num_params * num_params; ++i) {
            res->cov_matrix[i] *= s2;
        }
    }

    /* Standard errors & Correlation matrix */
    for (size_t j = 0; j < num_params; ++j) {
        double var = res->cov_matrix[j * num_params + j];
        res->param_errors[j] = (var > 0.0) ? sqrt(var) : 0.0;
    }
    for (size_t j = 0; j < num_params; ++j) {
        for (size_t k = 0; k < num_params; ++k) {
            if (j == k) {
                res->cor_matrix[j * num_params + k] = 1.0;
            } else {
                double denom = res->param_errors[j] * res->param_errors[k];
                res->cor_matrix[j * num_params + k] = (denom > 0.0) ? (res->cov_matrix[j * num_params + k] / denom) : 0.0;
            }
        }
    }

    /* Log-likelihood, AIC, BIC */
    double lnL = -0.5 * final_chi2;
    for (size_t i = 0; i < n_points; ++i) {
        lnL -= 0.5 * log(2.0 * M_PI * data[i].sigma * data[i].sigma);
    }
    res->log_likelihood = lnL;
    res->aic = 2.0 * (double)n_free - 2.0 * lnL;
    res->bic = (double)n_free * log((double)n_points) - 2.0 * lnL;

    res->iterations = iter;
    res->converged = converged;
    res->status = status;
    res->stop_reason = stop_reason;

    /* Cleanup */
    free(J); free(grad_point); free(A); free(A_damped); free(b); free(delta_p); free(trial_p);
    if (map != active_map) free(map);

    return HISTO_OK;
}

/* -------------------------------------------------------------------------
 * Public Fitting Orchestration
 * ------------------------------------------------------------------------- */

static histo_status_t fit_execute(
    const histo_t             *h,
    histo_fit_model_t          model,
    histo_fit_fn               custom_fn,
    size_t                     num_params,
    const double              *initial_params,
    const histo_fit_options_t *opts,
    histo_fit_result_t       **result
) {
    if (!h || !result || num_params == 0) {
        return HISTO_ERR_INVALID_ARG;
    }
    *result = NULL;

    uint32_t nbins = histo_nbins(h);
    if (nbins == 0 || (histo_num_entries(h) == 0 && histo_total_weight(h) == 0.0)) {
        return HISTO_ERR_EMPTY;
    }

    double r_min = 0.0, r_max = 0.0;
    histo_range(h, &r_min, &r_max);
    if (opts && opts->range_min < opts->range_max) {
        r_min = opts->range_min;
        r_max = opts->range_max;
    }

    /* Extract valid data points */
    fit_data_point_t *data = (fit_data_point_t*)malloc(nbins * sizeof(fit_data_point_t));
    if (!data) {
        return HISTO_ERR_NOMEM;
    }

    size_t n_points = 0;
    histo_fit_loss_t loss_type = opts ? opts->loss_type : HISTO_FIT_LOSS_CHI2;

    for (uint32_t i = 0; i < nbins; ++i) {
        double xc = 0.0, y = 0.0, err = 1.0;
        if (histo_bin_center(h, i, &xc) != HISTO_OK) continue;
        if (xc < r_min || xc > r_max) continue;
        if (histo_bin_content(h, i, &y) != HISTO_OK) continue;
        if (!isfinite(y)) continue;

        double sigma = 1.0;
        if (loss_type == HISTO_FIT_LOSS_UNWEIGHTED_LS) {
            sigma = 1.0;
        } else {
            if (histo_bin_error(h, i, &err) == HISTO_OK && err > 0.0) {
                sigma = err;
            } else {
                sigma = (y > 0.0) ? sqrt(y) : 1.0;
            }
        }
        if (sigma < 1.0e-9) sigma = 1.0e-9;

        data[n_points].x = xc;
        data[n_points].y = y;
        data[n_points].sigma = sigma;
        data[n_points].w = 1.0 / (sigma * sigma);
        n_points++;
    }

    if (n_points == 0) {
        free(data);
        return HISTO_ERR_EMPTY;
    }

    /* Allocate result container */
    histo_fit_result_t *res = (histo_fit_result_t*)calloc(1, sizeof(histo_fit_result_t));
    if (!res) {
        free(data);
        return HISTO_ERR_NOMEM;
    }

    /* Decide initial parameters if not provided */
    double temp_initial[HISTO_FIT_MAX_POLY_DEGREE + 1];
    const double *p0 = initial_params;
    if (!p0 && model != HISTO_FIT_MODEL_CUSTOM) {
        histo_status_t est_status = histo_fit_estimate_initial_params(h, model, opts, temp_initial);
        if (est_status != HISTO_OK) {
            free(data);
            free(res);
            return est_status;
        }
        p0 = temp_initial;
    } else if (!p0) {
        free(data);
        free(res);
        return HISTO_ERR_INVALID_ARG;
    }

    /* Dispatch to Linear LS or LM */
    histo_status_t status = HISTO_OK;
    bool has_fixed = (opts && opts->fixed_params != NULL);
    bool has_bounds = (opts && (opts->lower_bounds != NULL || opts->upper_bounds != NULL));
    bool is_linear_poly = (model == HISTO_FIT_MODEL_POLYNOMIAL) &&
                          (loss_type != HISTO_FIT_LOSS_POISSON_MLE) &&
                          !has_fixed && !has_bounds &&
                          (!opts || opts->algo == HISTO_FIT_ALGO_AUTO || opts->algo == HISTO_FIT_ALGO_LINEAR_LS);

    if (is_linear_poly) {
        uint32_t poly_deg = opts ? opts->poly_degree : 1;
        status = fit_polynomial_linear(data, n_points, poly_deg, opts, res);
    } else {
        status = fit_levenberg_marquardt(model, custom_fn, num_params, p0, data, n_points, opts, res);
    }

    free(data);
    if (status != HISTO_OK && !res->params) {
        free(res);
        return status;
    }

    *result = res;
    return HISTO_OK;
}

histo_status_t histo_fit_model(
    const histo_t             *h,
    histo_fit_model_t          model,
    const double              *initial_params,
    const histo_fit_options_t *opts,
    histo_fit_result_t       **result
) {
    if (!h || !result || model == HISTO_FIT_MODEL_CUSTOM) {
        return HISTO_ERR_INVALID_ARG;
    }
    uint32_t poly_deg = (opts) ? opts->poly_degree : 1;
    size_t num_params = histo_fit_model_num_params(model, poly_deg);
    if (num_params == 0) {
        return HISTO_ERR_INVALID_ARG;
    }
    return fit_execute(h, model, NULL, num_params, initial_params, opts, result);
}

histo_status_t histo_fit_custom(
    const histo_t             *h,
    histo_fit_fn               fn,
    size_t                     num_params,
    const double              *initial_params,
    const histo_fit_options_t *opts,
    histo_fit_result_t       **result
) {
    if (!h || !fn || !result || num_params == 0 || !initial_params) {
        return HISTO_ERR_INVALID_ARG;
    }
    return fit_execute(h, HISTO_FIT_MODEL_CUSTOM, fn, num_params, initial_params, opts, result);
}
