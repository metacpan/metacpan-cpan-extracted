/*
 * Kernel Density Estimation: kernel evaluators, CDF, quantiles, and sampling.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

#include "histo/kde.h"
#include "histo/histo.h"
#include "internal_common.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifndef M_SQRT2
#define M_SQRT2 1.41421356237309504880
#endif

#define INV_SQRT_2PI 0.39894228040143267794

struct histo_kde {
    histo_kde_kernel_t kernel;
    double             bandwidth;
    size_t             n_points;
    double            *coords;
    double            *weights;       /* Normalized to sum to 1.0 */
    double            *cum_weights;   /* Cumulative normalized weights for O(log N) sampling */
    double             total_weight;
    double             min_x;
    double             max_x;
    double             mean;
    double             std_dev;
};

histo_kde_options_t histo_kde_default_options(void) {
    histo_kde_options_t opts;
    opts.kernel    = HISTO_KDE_KERNEL_GAUSSIAN;
    opts.bw_method = HISTO_KDE_BANDWIDTH_SILVERMAN;
    opts.bandwidth = 0.0;
    opts.bw_adjust = 1.0;
    return opts;
}

/* ========================================================================= */
/* Kernel Evaluation & CDF Helpers                                           */
/* ========================================================================= */

static inline double kernel_eval(histo_kde_kernel_t k, double u) {
    double abs_u = fabs(u);
    switch (k) {
        case HISTO_KDE_KERNEL_GAUSSIAN:
            return INV_SQRT_2PI * exp(-0.5 * u * u);
        case HISTO_KDE_KERNEL_EPANECHNIKOV:
            return (abs_u <= 1.0) ? 0.75 * (1.0 - u * u) : 0.0;
        case HISTO_KDE_KERNEL_UNIFORM:
            return (abs_u <= 1.0) ? 0.5 : 0.0;
        case HISTO_KDE_KERNEL_TRIANGULAR:
            return (abs_u <= 1.0) ? (1.0 - abs_u) : 0.0;
        case HISTO_KDE_KERNEL_BIWEIGHT:
            if (abs_u <= 1.0) {
                double t = 1.0 - u * u;
                return 0.9375 * t * t; /* 15/16 = 0.9375 */
            }
            return 0.0;
        case HISTO_KDE_KERNEL_COSINE:
            return (abs_u <= 1.0) ? (0.25 * M_PI * cos(0.5 * M_PI * u)) : 0.0;
        default:
            return INV_SQRT_2PI * exp(-0.5 * u * u);
    }
}

static inline double kernel_cdf(histo_kde_kernel_t k, double u) {
    if (k == HISTO_KDE_KERNEL_GAUSSIAN) {
        return 0.5 * (1.0 + erf(u / M_SQRT2));
    }
    if (u <= -1.0) return 0.0;
    if (u >= 1.0) return 1.0;

    switch (k) {
        case HISTO_KDE_KERNEL_EPANECHNIKOV:
            return 0.5 + 0.75 * u - 0.25 * u * u * u;
        case HISTO_KDE_KERNEL_UNIFORM:
            return 0.5 * (u + 1.0);
        case HISTO_KDE_KERNEL_TRIANGULAR:
            if (u <= 0.0) {
                return 0.5 * (u + 1.0) * (u + 1.0);
            } else {
                return 1.0 - 0.5 * (1.0 - u) * (1.0 - u);
            }
        case HISTO_KDE_KERNEL_BIWEIGHT: {
            double u2 = u * u;
            return 0.5 + 0.9375 * u - 0.625 * u * u2 + 0.1875 * u2 * u2 * u;
        }
        case HISTO_KDE_KERNEL_COSINE:
            return 0.5 * (1.0 + sin(0.5 * M_PI * u));
        default:
            return 0.5 * (1.0 + erf(u / M_SQRT2));
    }
}

/* Comparison helper for qsort */
typedef struct {
    double val;
    double weight;
} sample_item_t;

static int compare_sample_items(const void *a, const void *b) {
    const sample_item_t *ia = (const sample_item_t*)a;
    const sample_item_t *ib = (const sample_item_t*)b;
    if (ia->val < ib->val) return -1;
    if (ia->val > ib->val) return 1;
    return 0;
}

/* ========================================================================= */
/* PRNG for Sampling                                                         */
/* ========================================================================= */

static inline uint64_t splitmix64(uint64_t *state) {
    uint64_t z = (*state += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

static inline double prng_uniform(uint64_t *state) {
    return (splitmix64(state) >> 11) * (1.0 / 9007199254740992.0);
}

static inline double prng_gaussian(uint64_t *state) {
    double u1 = prng_uniform(state);
    double u2 = prng_uniform(state);
    if (u1 <= 1e-15) u1 = 1e-15;
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}

static inline double sample_kernel(histo_kde_kernel_t k, uint64_t *state) {
    switch (k) {
        case HISTO_KDE_KERNEL_GAUSSIAN:
            return prng_gaussian(state);
        case HISTO_KDE_KERNEL_UNIFORM:
            return 2.0 * prng_uniform(state) - 1.0;
        case HISTO_KDE_KERNEL_TRIANGULAR: {
            double u1 = prng_uniform(state);
            double u2 = prng_uniform(state);
            return u1 + u2 - 1.0;
        }
        case HISTO_KDE_KERNEL_EPANECHNIKOV: {
            /* Rejection sampling on [-1, 1] */
            while (1) {
                double u = 2.0 * prng_uniform(state) - 1.0;
                double y = prng_uniform(state) * 0.75;
                if (y <= 0.75 * (1.0 - u * u)) return u;
            }
        }
        case HISTO_KDE_KERNEL_BIWEIGHT: {
            while (1) {
                double u = 2.0 * prng_uniform(state) - 1.0;
                double y = prng_uniform(state) * 0.9375;
                double t = 1.0 - u * u;
                if (y <= 0.9375 * t * t) return u;
            }
        }
        case HISTO_KDE_KERNEL_COSINE: {
            while (1) {
                double u = 2.0 * prng_uniform(state) - 1.0;
                double y = prng_uniform(state) * (0.25 * M_PI);
                if (y <= 0.25 * M_PI * cos(0.5 * M_PI * u)) return u;
            }
        }
        default:
            return prng_gaussian(state);
    }
}

/* ========================================================================= */
/* Creation & Destruction                                                    */
/* ========================================================================= */

histo_kde_t* histo_kde_create(size_t n, const double *samples, const double *weights, const histo_kde_options_t *opts) {
    if (n == 0 || !samples) return NULL;

    histo_kde_options_t opt = opts ? *opts : histo_kde_default_options();
    if (opt.bw_adjust <= 0.0) opt.bw_adjust = 1.0;

    sample_item_t *items = (sample_item_t*)malloc(n * sizeof(sample_item_t));
    if (!items) return NULL;

    double sum_w = 0.0;
    double sum_xw = 0.0;
    size_t valid_n = 0;
    double min_x = DBL_MAX;
    double max_x = -DBL_MAX;

    for (size_t i = 0; i < n; i++) {
        double x = samples[i];
        if (!isfinite(x)) continue;
        double w = weights ? weights[i] : 1.0;
        if (!isfinite(w) || w <= 0.0) continue;

        items[valid_n].val = x;
        items[valid_n].weight = w;
        sum_w += w;
        sum_xw += x * w;
        if (x < min_x) min_x = x;
        if (x > max_x) max_x = x;
        valid_n++;
    }

    if (valid_n == 0 || sum_w <= 0.0) {
        free(items);
        return NULL;
    }

    qsort(items, valid_n, sizeof(sample_item_t), compare_sample_items);

    double mean = sum_xw / sum_w;
    double sum_var = 0.0;
    for (size_t i = 0; i < valid_n; i++) {
        double diff = items[i].val - mean;
        sum_var += items[i].weight * diff * diff;
    }
    double variance = (sum_w > 0.0) ? (sum_var / sum_w) : 0.0;
    double std_dev = sqrt(variance);

    /* Calculate weighted IQR */
    double q25_target = 0.25 * sum_w;
    double q75_target = 0.75 * sum_w;
    double q25 = items[0].val;
    double q75 = items[valid_n - 1].val;
    double cum = 0.0;

    for (size_t i = 0; i < valid_n; i++) {
        cum += items[i].weight;
        if (cum >= q25_target && q25 == items[0].val) {
            q25 = items[i].val;
        }
        if (cum >= q75_target) {
            q75 = items[i].val;
            break;
        }
    }
    double iqr = (q75 >= q25) ? (q75 - q25) : 0.0;

    /* Compute Bandwidth h */
    double h = 0.0;
    if (opt.bw_method == HISTO_KDE_BANDWIDTH_MANUAL && opt.bandwidth > 0.0) {
        h = opt.bandwidth;
    } else {
        double n_eff = (double)valid_n;
        double n_pow = pow(n_eff, -0.2);

        if (opt.bw_method == HISTO_KDE_BANDWIDTH_SCOTT) {
            h = 1.059 * (std_dev > 0.0 ? std_dev : 1.0) * n_pow;
        } else {
            /* Silverman's rule of thumb */
            double spread = std_dev;
            if (iqr > 0.0) {
                double iqr_norm = iqr / 1.34;
                if (std_dev > 0.0 && iqr_norm < spread) {
                    spread = iqr_norm;
                } else if (spread <= 0.0) {
                    spread = iqr_norm;
                }
            }
            if (spread <= 0.0) spread = 1.0;
            h = 0.9 * spread * n_pow;
        }
    }

    h *= opt.bw_adjust;
    if (h <= 1e-12) h = 1.0; /* Robust minimum guard */

    histo_kde_t *kde = (histo_kde_t*)calloc(1, sizeof(histo_kde_t));
    if (!kde) {
        free(items);
        return NULL;
    }

    kde->coords = (double*)malloc(valid_n * sizeof(double));
    kde->weights = (double*)malloc(valid_n * sizeof(double));
    kde->cum_weights = (double*)malloc(valid_n * sizeof(double));
    if (!kde->coords || !kde->weights || !kde->cum_weights) {
        free(kde->coords);
        free(kde->weights);
        free(kde->cum_weights);
        free(kde);
        free(items);
        return NULL;
    }

    double running_cum = 0.0;
    for (size_t i = 0; i < valid_n; i++) {
        kde->coords[i] = items[i].val;
        double norm_w = items[i].weight / sum_w;
        kde->weights[i] = norm_w;
        running_cum += norm_w;
        kde->cum_weights[i] = running_cum;
    }
    kde->cum_weights[valid_n - 1] = 1.0; /* Ensure exact upper bound */

    kde->kernel = opt.kernel;
    kde->bandwidth = h;
    kde->n_points = valid_n;
    kde->total_weight = sum_w;
    kde->min_x = min_x;
    kde->max_x = max_x;
    kde->mean = mean;
    kde->std_dev = std_dev;

    free(items);
    return kde;
}

histo_kde_t* histo_kde_create_from_histo(const histo_t *h, const histo_kde_options_t *opts) {
    if (!h) return NULL;

    uint32_t nbins = histo_nbins(h);
    if (nbins == 0) return NULL;

    double total_weight = histo_total_weight(h);
    if (total_weight <= 0.0) return NULL;

    double *centers = (double*)malloc(nbins * sizeof(double));
    double *weights = (double*)malloc(nbins * sizeof(double));
    if (!centers || !weights) {
        free(centers);
        free(weights);
        return NULL;
    }

    size_t count = 0;
    for (uint32_t i = 0; i < nbins; i++) {
        double w = 0.0;
        double center = 0.0;
        histo_bin_content(h, i, &w);
        histo_bin_center(h, i, &center);
        if (w > 0.0) {
            centers[count] = center;
            weights[count] = w;
            count++;
        }
    }

    if (count == 0) {
        free(centers);
        free(weights);
        return NULL;
    }

    histo_kde_t *kde = histo_kde_create(count, centers, weights, opts);
    free(centers);
    free(weights);

    if (kde && opts && opts->bw_method != HISTO_KDE_BANDWIDTH_MANUAL) {
        /* Apply Sheppard's variance correction for binned discretization: Var_corr = Var - dx^2 / 12 */
        double min_v = 0.0, max_v = 0.0;
        histo_range(h, &min_v, &max_v);
        double dx = (max_v - min_v) / (double)nbins;
        double var_dx = (dx * dx) / 12.0;
        double orig_h = kde->bandwidth;
        if (orig_h * orig_h > var_dx) {
            kde->bandwidth = sqrt(orig_h * orig_h - var_dx);
        }
    }

    return kde;
}

void histo_kde_destroy(histo_kde_t *kde) {
    if (!kde) return;
    free(kde->coords);
    free(kde->weights);
    free(kde->cum_weights);
    free(kde);
}

/* ========================================================================= */
/* Evaluation & Operations                                                   */
/* ========================================================================= */

double histo_kde_eval(const histo_kde_t *kde, double x) {
    if (!kde || kde->n_points == 0 || kde->bandwidth <= 0.0 || !isfinite(x)) return 0.0;

    double inv_h = 1.0 / kde->bandwidth;
    double sum = 0.0;
    histo_kde_kernel_t k = kde->kernel;

    for (size_t i = 0; i < kde->n_points; i++) {
        double u = (x - kde->coords[i]) * inv_h;
        sum += kde->weights[i] * kernel_eval(k, u);
    }

    double result = sum * inv_h;
    return (result >= 0.0) ? result : 0.0;
}

histo_status_t histo_kde_eval_n(const histo_kde_t *kde, size_t n, const double *x_in, double *pdf_out) {
    if (!kde || !x_in || !pdf_out) return HISTO_ERR_INVALID_ARG;
    if (n == 0) return HISTO_OK;

    for (size_t i = 0; i < n; i++) {
        pdf_out[i] = histo_kde_eval(kde, x_in[i]);
    }
    return HISTO_OK;
}

double histo_kde_cdf(const histo_kde_t *kde, double x) {
    if (!kde || kde->n_points == 0 || kde->bandwidth <= 0.0) return 0.0;
    if (!isfinite(x)) {
        if (x < 0.0) return 0.0; /* -Inf */
        return 1.0;              /* +Inf */
    }

    double inv_h = 1.0 / kde->bandwidth;
    double sum = 0.0;
    histo_kde_kernel_t k = kde->kernel;

    for (size_t i = 0; i < kde->n_points; i++) {
        double u = (x - kde->coords[i]) * inv_h;
        sum += kde->weights[i] * kernel_cdf(k, u);
    }

    if (sum < 0.0) sum = 0.0;
    if (sum > 1.0) sum = 1.0;
    return sum;
}

histo_status_t histo_kde_quantile(const histo_kde_t *kde, double q, double *out_val) {
    if (!kde || !out_val) return HISTO_ERR_INVALID_ARG;
    if (q < 0.0 || q > 1.0 || !isfinite(q)) return HISTO_ERR_INVALID_ARG;

    if (q == 0.0) {
        *out_val = kde->min_x - 5.0 * kde->bandwidth;
        return HISTO_OK;
    }
    if (q == 1.0) {
        *out_val = kde->max_x + 5.0 * kde->bandwidth;
        return HISTO_OK;
    }

    /* Bracket root within [min_x - 6h, max_x + 6h] */
    double low = kde->min_x - 6.0 * kde->bandwidth;
    double high = kde->max_x + 6.0 * kde->bandwidth;

    /* Bisection + Newton-Raphson hybrid root finder */
    double x = kde->mean;
    if (x < low || x > high) x = 0.5 * (low + high);

    for (int iter = 0; iter < 100; iter++) {
        double f = histo_kde_cdf(kde, x) - q;
        if (fabs(f) < 1e-10) {
            *out_val = x;
            return HISTO_OK;
        }

        if (f < 0.0) {
            low = x;
        } else {
            high = x;
        }

        double df = histo_kde_eval(kde, x);
        double step = (df > 1e-12) ? (f / df) : 0.0;
        double next_x = x - step;

        if (next_x > low && next_x < high && fabs(step) < (high - low)) {
            x = next_x;
        } else {
            x = 0.5 * (low + high);
        }

        if ((high - low) < 1e-12) {
            *out_val = x;
            return HISTO_OK;
        }
    }

    *out_val = x;
    return HISTO_OK;
}

histo_status_t histo_kde_sample(const histo_kde_t *kde, size_t n, double *out_samples, uint64_t seed) {
    if (!kde || !out_samples) return HISTO_ERR_INVALID_ARG;
    if (n == 0) return HISTO_OK;

    uint64_t state = (seed != 0) ? seed : 0x853c49e6748fea9bULL;

    for (size_t i = 0; i < n; i++) {
        double u = prng_uniform(&state);

        /* Binary search on cumulative weights */
        size_t low = 0;
        size_t high = kde->n_points - 1;
        size_t idx = 0;

        while (low <= high) {
            size_t mid = low + (high - low) / 2;
            if (kde->cum_weights[mid] >= u) {
                idx = mid;
                if (mid == 0) break;
                high = mid - 1;
            } else {
                low = mid + 1;
            }
        }

        double center = kde->coords[idx];
        double noise = sample_kernel(kde->kernel, &state);
        out_samples[i] = center + kde->bandwidth * noise;
    }

    return HISTO_OK;
}

double histo_kde_get_bandwidth(const histo_kde_t *kde) {
    return kde ? kde->bandwidth : 0.0;
}

histo_kde_kernel_t histo_kde_get_kernel(const histo_kde_t *kde) {
    return kde ? kde->kernel : HISTO_KDE_KERNEL_GAUSSIAN;
}

size_t histo_kde_num_points(const histo_kde_t *kde) {
    return kde ? kde->n_points : 0;
}
