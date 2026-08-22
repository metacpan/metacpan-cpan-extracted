/*
 * 1D histogram implementation: creation, weighted filling, moments, and stats.
 */

#include "internal.h"
#include "simd.h"
#include <float.h>

/* ========================================================================= */
/* Status & Error Strings                                                    */
/* ========================================================================= */

const char* histo_status_str(histo_status_t status) {
    switch (status) {
        case HISTO_WARN_NON_FINITE:
            return "Non-finite sample(s) skipped";
        case HISTO_OK:
            return "Success";
        case HISTO_ERR_INVALID_ARG:
            return "Invalid argument";
        case HISTO_ERR_NOMEM:
            return "Out of memory";
        case HISTO_ERR_INCOMPATIBLE:
            return "Incompatible histogram geometry";
        case HISTO_ERR_OUT_OF_RANGE:
            return "Index or range out of bounds";
        case HISTO_ERR_NON_FINITE:
            return "Non-finite floating-point value";
        case HISTO_ERR_EMPTY:
            return "Histogram is empty";
        case HISTO_ERR_DIV_BY_ZERO:
            return "Division by zero";
        case HISTO_ERR_SERIALIZATION:
            return "Serialization failed";
        case HISTO_ERR_DESERIALIZATION:
            return "Deserialization failed";
        default:
            return "Unknown status";
    }
}

/* ========================================================================= */
/* Lifecycle & Memory Management                                             */
/* ========================================================================= */

histo_t* histo_create_uniform(uint32_t nbins, double min, double max, uint32_t flags) {
    if (nbins == 0 || nbins > HISTO_MAX_NBINS) {
        return NULL;
    }
    if (!isfinite(min) || !isfinite(max) || min >= max || !isfinite(max - min)) {
        return NULL;
    }

    histo_t *h = (histo_t *)calloc(1, sizeof(histo_t));
    if (!h) {
        return NULL;
    }

    h->bin_type = HISTO_BIN_UNIFORM;
    h->flags = flags;
    h->nbins = nbins;
    h->reserved_pad = 0;
    h->min = min;
    h->max = max;
    h->width = max - min;
    h->binsize = h->width / (double)nbins;
    double inv = (double)nbins / h->width;
    h->inv_binsize = isfinite(inv) ? inv : 0.0;
    h->bin_edges = NULL;

    h->bins = (double *)histo_alloc_aligned(nbins * sizeof(double));
    if (!h->bins) {
        free(h);
        return NULL;
    }

    if (flags & HISTO_FLAG_TRACK_SUMW2) {
        h->sum_w2 = (double *)histo_alloc_aligned(nbins * sizeof(double));
        if (!h->sum_w2) {
            histo_free_aligned(h->bins);
            free(h);
            return NULL;
        }
    } else {
        h->sum_w2 = NULL;
    }

    h->stats_min = INFINITY;
    h->stats_max = -INFINITY;

    return h;
}

histo_t* histo_create_variable(uint32_t nbins, const double *edges, uint32_t flags) {
    if (nbins == 0 || nbins > HISTO_MAX_NBINS || !edges) {
        return NULL;
    }

    /* Verify strict monotonicity of edges: edges[0] < edges[1] < ... < edges[nbins] */
    for (uint32_t i = 0; i < nbins; ++i) {
        if (!isfinite(edges[i]) || !isfinite(edges[i + 1]) || edges[i] >= edges[i + 1]) {
            return NULL;
        }
    }
    if (!isfinite(edges[nbins] - edges[0])) {
        return NULL;
    }

    histo_t *h = (histo_t *)calloc(1, sizeof(histo_t));
    if (!h) {
        return NULL;
    }

    h->bin_type = HISTO_BIN_VARIABLE;
    h->flags = flags;
    h->nbins = nbins;
    h->reserved_pad = 0;
    h->min = edges[0];
    h->max = edges[nbins];
    h->width = h->max - h->min;
    h->binsize = 0.0;
    h->inv_binsize = 0.0;

    h->bin_edges = (double *)malloc((nbins + 1) * sizeof(double));
    if (!h->bin_edges) {
        free(h);
        return NULL;
    }
    memcpy(h->bin_edges, edges, (nbins + 1) * sizeof(double));

    h->bins = (double *)histo_alloc_aligned(nbins * sizeof(double));
    if (!h->bins) {
        free(h->bin_edges);
        free(h);
        return NULL;
    }

    if (flags & HISTO_FLAG_TRACK_SUMW2) {
        h->sum_w2 = (double *)histo_alloc_aligned(nbins * sizeof(double));
        if (!h->sum_w2) {
            histo_free_aligned(h->bins);
            free(h->bin_edges);
            free(h);
            return NULL;
        }
    } else {
        h->sum_w2 = NULL;
    }

    h->stats_min = INFINITY;
    h->stats_max = -INFINITY;

    return h;
}

void histo_destroy(histo_t *h) {
    if (!h) {
        return;
    }
    if (h->bins) {
        histo_free_aligned(h->bins);
    }
    if (h->sum_w2) {
        histo_free_aligned(h->sum_w2);
    }
    if (h->bin_edges) {
        free(h->bin_edges);
    }
    free(h);
}


histo_t* histo_clone(const histo_t *src, bool empty) {
    if (!src) {
        return NULL;
    }

    histo_t *dst = NULL;
    if (src->bin_type == HISTO_BIN_UNIFORM) {
        dst = histo_create_uniform(src->nbins, src->min, src->max, src->flags);
    } else {
        dst = histo_create_variable(src->nbins, src->bin_edges, src->flags);
    }

    if (!dst) {
        return NULL;
    }

    if (!empty) {
        memcpy(dst->bins, src->bins, src->nbins * sizeof(double));
        if (src->sum_w2 && dst->sum_w2) {
            memcpy(dst->sum_w2, src->sum_w2, src->nbins * sizeof(double));
        }
        dst->underflow_weight = src->underflow_weight;
        dst->overflow_weight = src->overflow_weight;
        dst->underflow_sum_w2 = src->underflow_sum_w2;
        dst->overflow_sum_w2 = src->overflow_sum_w2;
        dst->n_underflow = src->n_underflow;
        dst->n_overflow = src->n_overflow;
        dst->n_nan = src->n_nan;
        dst->n_fills = src->n_fills;
        dst->total_weight = src->total_weight;
        dst->total_sum_w2 = src->total_sum_w2;
        dst->stats_min = src->stats_min;
        dst->stats_max = src->stats_max;
        dst->stats_mean = src->stats_mean;
        dst->stats_M2 = src->stats_M2;
    }

    return dst;
}

histo_status_t histo_reset(histo_t *h) {
    if (!h) {
        return HISTO_ERR_INVALID_ARG;
    }

    if (h->bins) {
        memset(h->bins, 0, h->nbins * sizeof(double));
    }
    if (h->sum_w2) {
        memset(h->sum_w2, 0, h->nbins * sizeof(double));
    }

    h->underflow_weight = 0.0;
    h->overflow_weight = 0.0;
    h->underflow_sum_w2 = 0.0;
    h->overflow_sum_w2 = 0.0;
    h->n_underflow = 0;
    h->n_overflow = 0;
    h->n_nan = 0;
    h->n_fills = 0;
    h->total_weight = 0.0;
    h->total_sum_w2 = 0.0;
    h->stats_min = INFINITY;
    h->stats_max = -INFINITY;
    h->stats_mean = 0.0;
    h->stats_M2 = 0.0;

    return HISTO_OK;
}

/* ========================================================================= */
/* Bin Lookup & Ingestion                                                    */
/* ========================================================================= */

static inline void histo_update_welford(histo_t *h, double x, double w) {
    if (w == 0.0 || h->total_weight <= 0.0) {
        return;
    }
    if (x < h->stats_min) h->stats_min = x;
    if (x > h->stats_max) h->stats_max = x;

    double delta = x - h->stats_mean;
    h->stats_mean += (w / h->total_weight) * delta;
    h->stats_M2 += w * delta * (x - h->stats_mean);
    if (h->stats_M2 < 0.0) {
        h->stats_M2 = 0.0;
    }
}


static inline void histo_fill_uniform_unchecked(histo_t *h, double x, double w, bool has_w2) {
    int64_t idx = histo_lookup_uniform_bin(x, h->min, h->max, h->nbins, h->binsize, h->inv_binsize);
    if (idx < 0) idx = 0;
    else if ((uint32_t)idx >= h->nbins) idx = (int64_t)h->nbins - 1;

    h->bins[idx] += w;
    h->total_weight += w;
    h->n_fills++;
    if (has_w2) {
        h->sum_w2[idx] += w * w;
        h->total_sum_w2 += w * w;
    }
}

histo_status_t histo_find_bin(const histo_t *h, double x, int64_t *out_bin) {
    if (!h || !out_bin) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (isnan(x)) {
        *out_bin = -1;
        return HISTO_ERR_NON_FINITE;
    }

    if (h->bin_type == HISTO_BIN_UNIFORM) {
        *out_bin = histo_lookup_uniform_bin(x, h->min, h->max, h->nbins, h->binsize, h->inv_binsize);
        return HISTO_OK;
    } else {
        *out_bin = histo_lookup_variable_bin(x, h->bin_edges, h->nbins);
        return HISTO_OK;
    }
}

histo_status_t histo_set_raw_bin_contents(histo_t *h, const double *bins, const double *sum_w2) {
    if (!h || !bins) return HISTO_ERR_INVALID_ARG;

    double tot_w = 0.0;
    double tot_w2 = 0.0;

    for (uint32_t i = 0; i < h->nbins; ++i) {
        h->bins[i] = bins[i];
        tot_w += bins[i];
        if (h->sum_w2 && sum_w2) {
            h->sum_w2[i] = sum_w2[i];
            tot_w2 += sum_w2[i];
        }
    }

    h->total_weight = tot_w;
    if (h->sum_w2) {
        h->total_sum_w2 = tot_w2;
    }
    h->n_fills = h->nbins;

    return HISTO_OK;
}


histo_status_t histo_fill_w(histo_t *h, double x, double weight) {
    if (!h) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (isnan(x) || !isfinite(weight)) {
        h->n_nan++;
        return HISTO_ERR_NON_FINITE;
    }

    if (x < h->min) {
        h->underflow_weight += weight;
        if (h->sum_w2) h->underflow_sum_w2 += weight * weight;
        h->n_underflow++;
        return HISTO_OK;
    }
    if (x >= h->max) {
        h->overflow_weight += weight;
        if (h->sum_w2) h->overflow_sum_w2 += weight * weight;
        h->n_overflow++;
        return HISTO_OK;
    }

    int64_t idx = 0;
    histo_find_bin(h, x, &idx);

    h->bins[idx] += weight;
    if (h->sum_w2) {
        h->sum_w2[idx] += weight * weight;
    }
    h->total_weight += weight;
    if (h->sum_w2) {
        h->total_sum_w2 += weight * weight;
    }
    h->n_fills++;

    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        histo_update_welford(h, x, weight);
    }

    return HISTO_OK;
}

histo_status_t histo_fill(histo_t *h, double x) {
    return histo_fill_w(h, x, 1.0);
}

histo_status_t histo_fill_bin(histo_t *h, uint32_t bin_index, double weight) {
    if (!h) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!isfinite(weight)) {
        h->n_nan++;
        return HISTO_ERR_NON_FINITE;
    }
    if (bin_index >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    h->bins[bin_index] += weight;
    if (h->sum_w2) {
        h->sum_w2[bin_index] += weight * weight;
    }
    h->total_weight += weight;
    if (h->sum_w2) {
        h->total_sum_w2 += weight * weight;
    }
    h->n_fills++;

    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        double center = 0.0;
        histo_bin_center(h, bin_index, &center);
        histo_update_welford(h, center, weight);
    }

    return HISTO_OK;
}


histo_status_t histo_fill_strided(histo_t *h, size_t n,
                                  const double *x, size_t x_stride_bytes,
                                  const double *weights, size_t w_stride_bytes) {
    if (!h || (!x && n > 0)) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (n == 0) {
        return HISTO_OK;
    }

    if (x_stride_bytes == 0) x_stride_bytes = sizeof(double);
    if (weights && w_stride_bytes == 0) w_stride_bytes = sizeof(double);

    if (x_stride_bytes == sizeof(double) && (!weights || w_stride_bytes == sizeof(double))) {
        return histo_fill_n(h, n, x, weights);
    }

    bool had_non_finite = false;
    const uint8_t *x_ptr = (const uint8_t *)x;
    const uint8_t *w_ptr = (const uint8_t *)weights;

    for (size_t i = 0; i < n; ++i) {
        double val = 0.0;
        memcpy(&val, x_ptr + i * x_stride_bytes, sizeof(double));
        double w = 1.0;
        if (weights) {
            memcpy(&w, w_ptr + i * w_stride_bytes, sizeof(double));
        }

        if (isnan(val) || !isfinite(w)) {
            h->n_nan++;
            had_non_finite = true;
            continue;
        }

        histo_status_t st = histo_fill_w(h, val, w);
        if (st == HISTO_ERR_NON_FINITE || st == HISTO_WARN_NON_FINITE) {
            had_non_finite = true;
        }
    }

    return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
}

histo_status_t histo_fill_n(histo_t *h, size_t n, const double *x, const double *weights) {
    if (!h || (!x && n > 0)) return HISTO_ERR_INVALID_ARG;
    if (n == 0) return HISTO_OK;

    bool had_non_finite = false;
    bool has_w2 = (h->sum_w2 != NULL);
    bool exact = (h->flags & HISTO_FLAG_EXACT_MOMENTS);

    if (h->bin_type == HISTO_BIN_UNIFORM) {
        if (!weights && !exact) {
#ifdef LIBHISTO_ENABLE_AVX512
            if (histo_simd_has_avx512() && !has_w2) {
                had_non_finite = histo_fill_uniform_avx512(h, x, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_AVX2
            if (histo_simd_has_avx2() && !has_w2) {
                had_non_finite = histo_fill_uniform_avx2(h, x, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_NEON
            if (histo_simd_has_neon() && !has_w2) {
                had_non_finite = histo_fill_uniform_neon(h, x, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
            for (size_t i = 0; i < n; ++i) {
                double val = x[i];
                if (isnan(val)) {
                    h->n_nan++;
                    had_non_finite = true;
                    continue;
                }
                if (val < h->min) {
                    h->underflow_weight += 1.0;
                    if (has_w2) h->underflow_sum_w2 += 1.0;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += 1.0;
                    if (has_w2) h->overflow_sum_w2 += 1.0;
                    h->n_overflow++;
                } else {
                    histo_fill_uniform_unchecked(h, val, 1.0, has_w2);
                }
            }
        } else if (weights && !exact) {
#ifdef LIBHISTO_ENABLE_AVX512
            if (histo_simd_has_avx512()) {
                had_non_finite = histo_fill_uniform_w2_avx512(h, x, weights, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_AVX2
            if (histo_simd_has_avx2()) {
                had_non_finite = histo_fill_uniform_w2_avx2(h, x, weights, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_NEON
            if (histo_simd_has_neon()) {
                had_non_finite = histo_fill_uniform_w2_neon(h, x, weights, n);
                return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
            for (size_t i = 0; i < n; ++i) {
                double val = x[i];
                double w = weights[i];
                if (isnan(val) || !isfinite(w)) {
                    h->n_nan++;
                    had_non_finite = true;
                    continue;
                }
                if (val < h->min) {
                    h->underflow_weight += w;
                    if (has_w2) h->underflow_sum_w2 += w * w;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += w;
                    if (has_w2) h->overflow_sum_w2 += w * w;
                    h->n_overflow++;
                } else {
                    histo_fill_uniform_unchecked(h, val, w, has_w2);
                }
            }
        } else {
            for (size_t i = 0; i < n; ++i) {
                double val = x[i];
                double w = weights ? weights[i] : 1.0;
                if (isnan(val) || !isfinite(w)) {
                    h->n_nan++;
                    had_non_finite = true;
                    continue;
                }
                if (val < h->min) {
                    h->underflow_weight += w;
                    if (has_w2) h->underflow_sum_w2 += w * w;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += w;
                    if (has_w2) h->overflow_sum_w2 += w * w;
                    h->n_overflow++;
                } else {
                    histo_fill_uniform_unchecked(h, val, w, has_w2);
                    histo_update_welford(h, val, w);
                }
            }
        }
    } else {
        for (size_t i = 0; i < n; ++i) {
            double val = x[i];
            double w = weights ? weights[i] : 1.0;
            if (isnan(val) || !isfinite(w)) {
                h->n_nan++;
                had_non_finite = true;
                continue;
            }
            if (val < h->min) {
                h->underflow_weight += w;
                if (has_w2) h->underflow_sum_w2 += w * w;
                h->n_underflow++;
            } else if (val >= h->max) {
                h->overflow_weight += w;
                if (has_w2) h->overflow_sum_w2 += w * w;
                h->n_overflow++;
            } else {
                int64_t bin_idx = 0;
                histo_find_bin(h, val, &bin_idx);
                h->bins[bin_idx] += w;
                if (has_w2) {
                    h->sum_w2[bin_idx] += w * w;
                }
                h->total_weight += w;
                if (has_w2) {
                    h->total_sum_w2 += w * w;
                }
                h->n_fills++;
                if (exact) {
                    histo_update_welford(h, val, w);
                }
            }
        }
    }

    return had_non_finite ? HISTO_WARN_NON_FINITE : HISTO_OK;
}

/* ========================================================================= */
/* Geometry & Bin Queries                                                    */
/* ========================================================================= */

uint32_t histo_nbins(const histo_t *h) {
    return h ? h->nbins : 0;
}

histo_bin_type_t histo_bin_type(const histo_t *h) {
    return h ? h->bin_type : HISTO_BIN_UNIFORM;
}

histo_status_t histo_range(const histo_t *h, double *out_min, double *out_max) {
    if (!h || !out_min || !out_max) {
        return HISTO_ERR_INVALID_ARG;
    }
    *out_min = h->min;
    *out_max = h->max;
    return HISTO_OK;
}

histo_status_t histo_bin_bounds(const histo_t *h, uint32_t bin_index, double *out_lower, double *out_upper) {
    if (!h || !out_lower || !out_upper) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (bin_index >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    if (h->bin_type == HISTO_BIN_UNIFORM) {
        *out_lower = h->min + (double)bin_index * h->binsize;
        *out_upper = (bin_index + 1 == h->nbins) ? h->max : (h->min + (double)(bin_index + 1) * h->binsize);
    } else {
        *out_lower = h->bin_edges[bin_index];
        *out_upper = h->bin_edges[bin_index + 1];
    }
    return HISTO_OK;
}

histo_status_t histo_bin_center(const histo_t *h, uint32_t bin_index, double *out_center) {
    if (!h || !out_center) {
        return HISTO_ERR_INVALID_ARG;
    }
    double lower = 0.0, upper = 0.0;
    histo_status_t st = histo_bin_bounds(h, bin_index, &lower, &upper);
    if (st != HISTO_OK) {
        return st;
    }
    *out_center = lower + 0.5 * (upper - lower);
    return HISTO_OK;
}


histo_status_t histo_bin_content(const histo_t *h, uint32_t bin_index, double *out_content) {
    if (!h || !out_content) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (bin_index >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }
    *out_content = h->bins[bin_index];
    return HISTO_OK;
}

histo_status_t histo_bin_error(const histo_t *h, uint32_t bin_index, double *out_error) {
    if (!h || !out_error) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (bin_index >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    if (h->sum_w2) {
        *out_error = sqrt(h->sum_w2[bin_index]);
    } else {
        double c = h->bins[bin_index];
        *out_error = (c > 0.0) ? sqrt(c) : 0.0;
    }
    return HISTO_OK;
}

histo_status_t histo_bin_sum_w2(const histo_t *h, uint32_t bin_index, double *out_sum_w2) {
    if (!h || !out_sum_w2) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (bin_index >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }
    if (!h->sum_w2) {
        return HISTO_ERR_INVALID_ARG;
    }
    *out_sum_w2 = h->sum_w2[bin_index];
    return HISTO_OK;
}

double histo_underflow(const histo_t *h) {
    return h ? h->underflow_weight : 0.0;
}

double histo_overflow(const histo_t *h) {
    return h ? h->overflow_weight : 0.0;
}

uint64_t histo_nan_count(const histo_t *h) {
    return h ? h->n_nan : 0;
}

double histo_total_weight(const histo_t *h) {
    return h ? h->total_weight : 0.0;
}

uint64_t histo_num_entries(const histo_t *h) {
    return h ? h->n_fills : 0;
}

/* ========================================================================= */
/* Statistical Analysis                                                      */
/* ========================================================================= */

histo_status_t histo_integral(const histo_t *h, uint32_t start_bin, uint32_t end_bin, double *out_integral) {
    if (!h || !out_integral) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (start_bin > end_bin || end_bin >= h->nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    double sum = 0.0;
    for (uint32_t i = start_bin; i <= end_bin; ++i) {
        sum += h->bins[i];
    }
    *out_integral = sum;
    return HISTO_OK;
}

histo_status_t histo_mean(const histo_t *h, double *out_mean) {
    if (!h || !out_mean) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_mean = h->stats_mean;
        return HISTO_OK;
    }

    /* Two-pass / bin-center estimator */
    double sum = 0.0;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        double center = 0.0;
        histo_bin_center(h, i, &center);
        sum += h->bins[i] * center;
    }
    *out_mean = sum / h->total_weight;
    return HISTO_OK;
}

histo_status_t histo_variance(const histo_t *h, double *out_variance) {
    if (!h || !out_variance) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        double var_val = h->stats_M2 / h->total_weight;
        *out_variance = (var_val > 0.0) ? var_val : 0.0;
        return HISTO_OK;
    }

    /* Two-pass numerically stable bin-center variance */
    double mean_val = 0.0;
    histo_status_t st = histo_mean(h, &mean_val);
    if (st != HISTO_OK) {
        return st;
    }

    double sum_sq_diff = 0.0;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        double center = 0.0;
        histo_bin_center(h, i, &center);
        double diff = center - mean_val;
        sum_sq_diff += h->bins[i] * (diff * diff);
    }
    double var_val = sum_sq_diff / h->total_weight;
    *out_variance = (var_val > 0.0) ? var_val : 0.0;
    return HISTO_OK;
}

histo_status_t histo_std_dev(const histo_t *h, double *out_std_dev) {
    if (!h || !out_std_dev) {
        return HISTO_ERR_INVALID_ARG;
    }
    double var = 0.0;
    histo_status_t st = histo_variance(h, &var);
    if (st != HISTO_OK) {
        return st;
    }
    *out_std_dev = (var > 0.0) ? sqrt(var) : 0.0;
    return HISTO_OK;
}

histo_status_t histo_central_moment(const histo_t *h, uint32_t k, double *out_moment) {
    if (!h || !out_moment) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }
    if (k == 0) {
        *out_moment = 1.0;
        return HISTO_OK;
    }
    if (k == 1) {
        *out_moment = 0.0;
        return HISTO_OK;
    }
    if (k == 2) {
        return histo_variance(h, out_moment);
    }

    double mean_val = 0.0;
    histo_status_t st = histo_mean(h, &mean_val);
    if (st != HISTO_OK) {
        return st;
    }

    double sum_k = 0.0;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        double w = h->bins[i];
        if (w == 0.0) continue;
        double center = 0.0;
        histo_bin_center(h, i, &center);
        double diff = center - mean_val;
        sum_k += w * pow(diff, (double)k);
    }

    *out_moment = sum_k / h->total_weight;
    return HISTO_OK;
}

histo_status_t histo_skewness(const histo_t *h, double *out_skewness) {
    if (!h || !out_skewness) {
        return HISTO_ERR_INVALID_ARG;
    }
    double var = 0.0;
    histo_status_t st = histo_variance(h, &var);
    if (st != HISTO_OK) {
        return st;
    }
    if (var <= 0.0) {
        return HISTO_ERR_DIV_BY_ZERO;
    }

    double m3 = 0.0;
    st = histo_central_moment(h, 3, &m3);
    if (st != HISTO_OK) {
        return st;
    }

    *out_skewness = m3 / (var * sqrt(var));
    return HISTO_OK;
}

histo_status_t histo_kurtosis(const histo_t *h, double *out_kurtosis) {
    if (!h || !out_kurtosis) {
        return HISTO_ERR_INVALID_ARG;
    }
    double var = 0.0;
    histo_status_t st = histo_variance(h, &var);
    if (st != HISTO_OK) {
        return st;
    }
    if (var <= 0.0) {
        return HISTO_ERR_DIV_BY_ZERO;
    }

    double m4 = 0.0;
    st = histo_central_moment(h, 4, &m4);
    if (st != HISTO_OK) {
        return st;
    }

    *out_kurtosis = m4 / (var * var);
    return HISTO_OK;
}

histo_status_t histo_excess_kurtosis(const histo_t *h, double *out_exc_kurtosis) {
    if (!h || !out_exc_kurtosis) {
        return HISTO_ERR_INVALID_ARG;
    }
    double kurt = 0.0;
    histo_status_t st = histo_kurtosis(h, &kurt);
    if (st != HISTO_OK) {
        return st;
    }
    *out_exc_kurtosis = kurt - 3.0;
    return HISTO_OK;
}

histo_status_t histo_mode_bin(const histo_t *h, uint32_t *out_bin_idx) {
    if (!h || !out_bin_idx) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    uint32_t max_idx = 0;
    double max_weight = h->bins[0];

    for (uint32_t i = 1; i < h->nbins; ++i) {
        if (h->bins[i] > max_weight) {
            max_weight = h->bins[i];
            max_idx = i;
        }
    }

    if (max_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    *out_bin_idx = max_idx;
    return HISTO_OK;
}

histo_status_t histo_mode_continuous(const histo_t *h, double *out_mode) {
    if (!h || !out_mode) {
        return HISTO_ERR_INVALID_ARG;
    }
    uint32_t mode_idx = 0;
    histo_status_t st = histo_mode_bin(h, &mode_idx);
    if (st != HISTO_OK) {
        return st;
    }

    /* Boundary bins or variable binning -> return bin center */
    if (mode_idx == 0 || mode_idx == h->nbins - 1 || h->bin_type == HISTO_BIN_VARIABLE) {
        return histo_bin_center(h, mode_idx, out_mode);
    }

    double y_prev = h->bins[mode_idx - 1];
    double y_curr = h->bins[mode_idx];
    double y_next = h->bins[mode_idx + 1];

    double denom = 2.0 * y_curr - y_prev - y_next;
    if (denom <= 0.0) {
        return histo_bin_center(h, mode_idx, out_mode);
    }

    double delta = 0.5 * (y_next - y_prev) / denom;
    if (delta < -0.5) delta = -0.5;
    if (delta > 0.5) delta = 0.5;

    double center = 0.0;
    histo_bin_center(h, mode_idx, &center);
    *out_mode = center + delta * h->binsize;
    return HISTO_OK;
}

histo_status_t histo_fwhm(const histo_t *h, double *out_fwhm) {
    if (!h || !out_fwhm) {
        return HISTO_ERR_INVALID_ARG;
    }
    uint32_t mode_idx = 0;
    histo_status_t st = histo_mode_bin(h, &mode_idx);
    if (st != HISTO_OK) {
        return st;
    }

    double peak_val = h->bins[mode_idx];
    double half_max = peak_val / 2.0;
    if (half_max <= 0.0) {
        *out_fwhm = 0.0;
        return HISTO_OK;
    }

    /* Left half-maximum crossing */
    double x_left = 0.0;
    bool found_left = false;
    for (int64_t i = (int64_t)mode_idx - 1; i >= 0; --i) {
        if (h->bins[i] < half_max) {
            double c_low = 0.0, c_high = 0.0;
            histo_bin_center(h, (uint32_t)i, &c_low);
            histo_bin_center(h, (uint32_t)(i + 1), &c_high);
            double y_low = h->bins[i];
            double y_high = h->bins[i + 1];
            double frac = (y_high > y_low) ? ((half_max - y_low) / (y_high - y_low)) : 0.5;
            x_left = c_low + frac * (c_high - c_low);
            found_left = true;
            break;
        }
    }
    if (!found_left) {
        double low = 0.0, high = 0.0;
        histo_bin_bounds(h, 0, &low, &high);
        x_left = low;
    }

    /* Right half-maximum crossing */
    double x_right = 0.0;
    bool found_right = false;
    for (uint32_t i = mode_idx + 1; i < h->nbins; ++i) {
        if (h->bins[i] < half_max) {
            double c_low = 0.0, c_high = 0.0;
            histo_bin_center(h, i - 1, &c_low);
            histo_bin_center(h, i, &c_high);
            double y_high = h->bins[i - 1];
            double y_low = h->bins[i];
            double frac = (y_high > y_low) ? ((y_high - half_max) / (y_high - y_low)) : 0.5;
            x_right = c_low + frac * (c_high - c_low);
            found_right = true;
            break;
        }
    }
    if (!found_right) {
        double low = 0.0, high = 0.0;
        histo_bin_bounds(h, h->nbins - 1, &low, &high);
        x_right = high;
    }

    *out_fwhm = (x_right > x_left) ? (x_right - x_left) : 0.0;
    return HISTO_OK;
}

histo_status_t histo_rms(const histo_t *h, double *out_rms) {
    if (!h || !out_rms) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    double mean_val = 0.0, var_val = 0.0;
    histo_status_t st = histo_mean(h, &mean_val);
    if (st != HISTO_OK) return st;

    st = histo_variance(h, &var_val);
    if (st != HISTO_OK) return st;

    *out_rms = sqrt(var_val + mean_val * mean_val);
    return HISTO_OK;
}

histo_status_t histo_quantile(const histo_t *h, double p, double *out_quantile) {
    if (!h || !out_quantile) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }
    if (!isfinite(p) || p < 0.0 || p > 1.0) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    /* Find first and last non-empty bins */
    int64_t first_non_empty = -1;
    int64_t last_non_empty = -1;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        if (h->bins[i] > 0.0) {
            if (first_non_empty == -1) {
                first_non_empty = (int64_t)i;
            }
            last_non_empty = (int64_t)i;
        }
    }

    if (first_non_empty == -1) {
        return HISTO_ERR_EMPTY;
    }

    /* Boundary target cases */
    if (p == 0.0) {
        if ((h->flags & HISTO_FLAG_EXACT_MOMENTS) && isfinite(h->stats_min)) {
            *out_quantile = h->stats_min;
        } else {
            double low = 0.0, high = 0.0;
            histo_bin_bounds(h, (uint32_t)first_non_empty, &low, &high);
            *out_quantile = low;
        }
        return HISTO_OK;
    }

    if (p == 1.0) {
        if ((h->flags & HISTO_FLAG_EXACT_MOMENTS) && isfinite(h->stats_max)) {
            *out_quantile = h->stats_max;
        } else {
            double low = 0.0, high = 0.0;
            histo_bin_bounds(h, (uint32_t)last_non_empty, &low, &high);
            *out_quantile = high;
        }
        return HISTO_OK;
    }

    double target = p * h->total_weight;
    double cum_weight = 0.0;

    for (uint32_t i = 0; i < h->nbins; ++i) {
        double w = h->bins[i];
        if (w <= 0.0) {
            continue;
        }

        double prev_cum = cum_weight;
        cum_weight += w;

        if (target <= cum_weight || (int64_t)i == last_non_empty) {
            double low = 0.0, high = 0.0;
            histo_bin_bounds(h, i, &low, &high);
            double theta = (target - prev_cum) / w;
            if (theta < 0.0) theta = 0.0;
            if (theta > 1.0) theta = 1.0;
            *out_quantile = low + theta * (high - low);
            return HISTO_OK;
        }
    }

    /* Fallback */
    double low = 0.0, high = 0.0;
    histo_bin_bounds(h, (uint32_t)last_non_empty, &low, &high);
    *out_quantile = high;
    return HISTO_OK;
}

histo_status_t histo_median(const histo_t *h, double *out_median) {
    return histo_quantile(h, 0.5, out_median);
}

histo_status_t histo_iqr(const histo_t *h, double *out_iqr) {
    if (!h || !out_iqr) {
        return HISTO_ERR_INVALID_ARG;
    }
    double q25 = 0.0, q75 = 0.0;
    histo_status_t st = histo_quantile(h, 0.25, &q25);
    if (st != HISTO_OK) return st;

    st = histo_quantile(h, 0.75, &q75);
    if (st != HISTO_OK) return st;

    *out_iqr = (q75 >= q25) ? (q75 - q25) : 0.0;
    return HISTO_OK;
}

histo_status_t histo_mad(const histo_t *h, double *out_mad) {
    if (!h || !out_mad) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    double med = 0.0;
    histo_status_t st = histo_median(h, &med);
    if (st != HISTO_OK) return st;

    /* Locate the bin index containing the median */
    int64_t med_bin = 0;
    if (histo_find_bin(h, med, &med_bin) != HISTO_OK || med_bin < 0) {
        med_bin = 0;
    } else if ((uint32_t)med_bin >= h->nbins) {
        med_bin = (int64_t)h->nbins - 1;
    }

    /* Two-pointer merge over pre-sorted histogram bins:
     * Deviations |center - med| are monotonically increasing to the left and right of med_bin.
     * We merge both halves in O(N) time using O(1) auxiliary space without comparisons/sort. */
    int64_t left = med_bin - 1;
    int64_t right = med_bin;
    double cum_weight = 0.0;
    double target_weight = 0.5 * h->total_weight;
    double result = 0.0;

    while (left >= 0 || right < (int64_t)h->nbins) {
        double d_left = INFINITY;
        double d_right = INFINITY;

        if (left >= 0) {
            double c_left = 0.0;
            histo_bin_center(h, (uint32_t)left, &c_left);
            d_left = fabs(c_left - med);
        }
        if (right < (int64_t)h->nbins) {
            double c_right = 0.0;
            histo_bin_center(h, (uint32_t)right, &c_right);
            d_right = fabs(c_right - med);
        }

        if (d_left <= d_right) {
            cum_weight += h->bins[left];
            result = d_left;
            left--;
        } else {
            cum_weight += h->bins[right];
            result = d_right;
            right++;
        }

        if (cum_weight >= target_weight) {
            *out_mad = result;
            return HISTO_OK;
        }
    }

    *out_mad = result;
    return HISTO_OK;
}

histo_status_t histo_trimmed_mean(const histo_t *h, double lower_p, double upper_p, double *out_mean) {
    if (!h || !out_mean) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }
    if (!isfinite(lower_p) || !isfinite(upper_p) || lower_p < 0.0 || upper_p > 1.0 || lower_p >= upper_p) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    double t_low = lower_p * h->total_weight;
    double t_high = upper_p * h->total_weight;

    double cum_w = 0.0;
    double sum_wx = 0.0;
    double eff_weight = 0.0;

    for (uint32_t i = 0; i < h->nbins; ++i) {
        double w = h->bins[i];
        if (w <= 0.0) continue;

        double b_start = cum_w;
        double b_end = cum_w + w;
        cum_w = b_end;

        double overlap_start = (b_start > t_low) ? b_start : t_low;
        double overlap_end = (b_end < t_high) ? b_end : t_high;

        if (overlap_end > overlap_start) {
            double w_eff = overlap_end - overlap_start;
            double center = 0.0;
            histo_bin_center(h, i, &center);
            sum_wx += w_eff * center;
            eff_weight += w_eff;
        }
    }

    if (eff_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    *out_mean = sum_wx / eff_weight;
    return HISTO_OK;
}

histo_status_t histo_winsorized_mean(const histo_t *h, double lower_p, double upper_p, double *out_mean) {
    if (!h || !out_mean) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }
    if (!isfinite(lower_p) || !isfinite(upper_p) || lower_p < 0.0 || upper_p > 1.0 || lower_p >= upper_p) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    double x_low = 0.0, x_high = 0.0;
    histo_status_t st = histo_quantile(h, lower_p, &x_low);
    if (st != HISTO_OK) return st;

    st = histo_quantile(h, upper_p, &x_high);
    if (st != HISTO_OK) return st;

    double sum_wx = 0.0;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        double w = h->bins[i];
        if (w <= 0.0) continue;

        double center = 0.0;
        histo_bin_center(h, i, &center);

        double clamped = center;
        if (clamped < x_low) clamped = x_low;
        if (clamped > x_high) clamped = x_high;

        sum_wx += w * clamped;
    }

    *out_mean = sum_wx / h->total_weight;
    return HISTO_OK;
}

histo_status_t histo_get_stats(const histo_t *h, histo_stats_t *out_stats) {
    if (!h || !out_stats) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    out_stats->n_entries = h->n_fills;
    out_stats->total_weight = h->total_weight;

    histo_mean(h, &out_stats->mean);
    histo_variance(h, &out_stats->variance);
    out_stats->std_dev = sqrt(out_stats->variance);

    if ((h->flags & HISTO_FLAG_EXACT_MOMENTS) && isfinite(h->stats_min) && isfinite(h->stats_max)) {
        out_stats->min = h->stats_min;
        out_stats->max = h->stats_max;
    } else {
        histo_quantile(h, 0.0, &out_stats->min);
        histo_quantile(h, 1.0, &out_stats->max);
    }

    histo_median(h, &out_stats->median);

    return HISTO_OK;
}

/* ========================================================================= */
/* Two-Histogram Comparison & Distance Metrics                              */
/* ========================================================================= */

static bool histo_are_compatible(const histo_t *a, const histo_t *b) {
    if (!a || !b) return false;
    if (a->bin_type != b->bin_type || a->nbins != b->nbins) return false;
    if (fabs(a->min - b->min) > 1e-12 || fabs(a->max - b->max) > 1e-12) return false;

    if (a->bin_type == HISTO_BIN_VARIABLE) {
        for (uint32_t i = 0; i <= a->nbins; ++i) {
            if (fabs(a->bin_edges[i] - b->bin_edges[i]) > 1e-12) return false;
        }
    }
    return true;
}

histo_status_t histo_cmp_chi2(const histo_t *h1, const histo_t *h2, double *out_chi2, uint32_t *out_ndf) {
    if (!h1 || !h2 || !out_chi2 || !out_ndf) return HISTO_ERR_INVALID_ARG;
    if (!histo_are_compatible(h1, h2)) return HISTO_ERR_INCOMPATIBLE;
    if (h1->total_weight <= 0.0 || h2->total_weight <= 0.0) return HISTO_ERR_EMPTY;

    double chi2_sum = 0.0;
    uint32_t ndf = 0;

    for (uint32_t i = 0; i < h1->nbins; ++i) {
        double w1 = h1->bins[i];
        double w2 = h2->bins[i];
        double err1_sq = (h1->sum_w2 != NULL) ? h1->sum_w2[i] : (w1 > 0.0 ? w1 : 0.0);
        double err2_sq = (h2->sum_w2 != NULL) ? h2->sum_w2[i] : (w2 > 0.0 ? w2 : 0.0);
        double var_tot = err1_sq + err2_sq;
        if (var_tot > 0.0) {
            double diff = w1 - w2;
            chi2_sum += (diff * diff) / var_tot;
            ndf++;
        }
    }

    *out_chi2 = chi2_sum;
    *out_ndf = ndf;
    return HISTO_OK;
}

histo_status_t histo_cmp_ks(const histo_t *h1, const histo_t *h2, double *out_ks_stat) {
    if (!h1 || !h2 || !out_ks_stat) return HISTO_ERR_INVALID_ARG;
    if (!histo_are_compatible(h1, h2)) return HISTO_ERR_INCOMPATIBLE;
    if (h1->total_weight <= 0.0 || h2->total_weight <= 0.0) return HISTO_ERR_EMPTY;

    double s1 = 1.0 / h1->total_weight;
    double s2 = 1.0 / h2->total_weight;
    double cdf1 = 0.0, cdf2 = 0.0;
    double max_diff = 0.0;

    for (uint32_t i = 0; i < h1->nbins; ++i) {
        cdf1 += h1->bins[i] * s1;
        cdf2 += h2->bins[i] * s2;
        double diff = fabs(cdf1 - cdf2);
        if (diff > max_diff) {
            max_diff = diff;
        }
    }

    *out_ks_stat = max_diff;
    return HISTO_OK;
}

histo_status_t histo_cmp_wasserstein_1d(const histo_t *h1, const histo_t *h2, double *out_distance) {
    if (!h1 || !h2 || !out_distance) return HISTO_ERR_INVALID_ARG;
    if (!histo_are_compatible(h1, h2)) return HISTO_ERR_INCOMPATIBLE;
    if (h1->total_weight <= 0.0 || h2->total_weight <= 0.0) return HISTO_ERR_EMPTY;

    double s1 = 1.0 / h1->total_weight;
    double s2 = 1.0 / h2->total_weight;
    double cdf1 = 0.0, cdf2 = 0.0;
    double dist = 0.0;

    for (uint32_t i = 0; i < h1->nbins; ++i) {
        cdf1 += h1->bins[i] * s1;
        cdf2 += h2->bins[i] * s2;
        double dx = 0.0;
        if (h1->bin_type == HISTO_BIN_UNIFORM) {
            dx = h1->binsize;
        } else {
            dx = h1->bin_edges[i + 1] - h1->bin_edges[i];
        }
        dist += fabs(cdf1 - cdf2) * dx;
    }

    *out_distance = dist;
    return HISTO_OK;
}

histo_status_t histo_cmp_kl_divergence(const histo_t *h1, const histo_t *h2, double *out_divergence) {
    if (!h1 || !h2 || !out_divergence) return HISTO_ERR_INVALID_ARG;
    if (!histo_are_compatible(h1, h2)) return HISTO_ERR_INCOMPATIBLE;
    if (h1->total_weight <= 0.0 || h2->total_weight <= 0.0) return HISTO_ERR_EMPTY;

    double s1 = 1.0 / h1->total_weight;
    double s2 = 1.0 / h2->total_weight;
    const double eps = 1e-12;
    double div = 0.0;

    for (uint32_t i = 0; i < h1->nbins; ++i) {
        double p = h1->bins[i] * s1;
        if (p <= 0.0) continue;
        double q = h2->bins[i] * s2;
        if (q <= 0.0) q = eps;
        div += p * log(p / q);
    }

    *out_divergence = (div >= 0.0) ? div : 0.0;
    return HISTO_OK;
}

histo_status_t histo_cmp_bhattacharyya(const histo_t *h1, const histo_t *h2, double *out_distance) {
    if (!h1 || !h2 || !out_distance) return HISTO_ERR_INVALID_ARG;
    if (!histo_are_compatible(h1, h2)) return HISTO_ERR_INCOMPATIBLE;
    if (h1->total_weight <= 0.0 || h2->total_weight <= 0.0) return HISTO_ERR_EMPTY;

    double s1 = 1.0 / h1->total_weight;
    double s2 = 1.0 / h2->total_weight;
    double bc = 0.0;

    for (uint32_t i = 0; i < h1->nbins; ++i) {
        double p = h1->bins[i] * s1;
        double q = h2->bins[i] * s2;
        if (p > 0.0 && q > 0.0) {
            bc += sqrt(p * q);
        }
    }

    if (bc <= 0.0) {
        *out_distance = INFINITY;
    } else if (bc >= 1.0) {
        *out_distance = 0.0;
    } else {
        *out_distance = -log(bc);
    }
    return HISTO_OK;
}

/* ========================================================================= */
/* Arithmetic & Transformations                                              */
/* ========================================================================= */

histo_status_t histo_add(histo_t *target, const histo_t *other) {
    if (!target || !other) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!histo_are_compatible(target, other)) {
        return HISTO_ERR_INCOMPATIBLE;
    }

    uint32_t n = target->nbins;
    for (uint32_t i = 0; i < n; ++i) {
        target->bins[i] += other->bins[i];
        if (target->sum_w2 && other->sum_w2) {
            target->sum_w2[i] += other->sum_w2[i];
        }
    }

    target->total_weight += other->total_weight;
    if (target->sum_w2 && other->sum_w2) {
        target->total_sum_w2 += other->total_sum_w2;
    }
    target->underflow_weight += other->underflow_weight;
    target->overflow_weight += other->overflow_weight;
    if (target->sum_w2 && other->sum_w2) {
        target->underflow_sum_w2 += other->underflow_sum_w2;
        target->overflow_sum_w2 += other->overflow_sum_w2;
    }
    target->n_fills += other->n_fills;
    target->n_underflow += other->n_underflow;
    target->n_overflow += other->n_overflow;
    target->n_nan += other->n_nan;

    /* Merge exact moments if both histograms track them */
    if ((target->flags & HISTO_FLAG_EXACT_MOMENTS) && (other->flags & HISTO_FLAG_EXACT_MOMENTS)) {
        if (other->total_weight > 0.0) {
            double w1 = target->total_weight - other->total_weight;
            double w2 = other->total_weight;
            if (w1 > 0.0) {
                double delta = other->stats_mean - target->stats_mean;
                target->stats_mean += (w2 / target->total_weight) * delta;
                target->stats_M2 += other->stats_M2 + (w1 * w2 / target->total_weight) * (delta * delta);
                if (target->stats_M2 < 0.0) target->stats_M2 = 0.0;
            } else {
                target->stats_mean = other->stats_mean;
                target->stats_M2 = other->stats_M2;
            }
            if (other->stats_min < target->stats_min) target->stats_min = other->stats_min;
            if (other->stats_max > target->stats_max) target->stats_max = other->stats_max;
        }
    }

    return HISTO_OK;
}

histo_status_t histo_subtract(histo_t *target, const histo_t *other) {
    if (!target || !other) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!histo_are_compatible(target, other)) {
        return HISTO_ERR_INCOMPATIBLE;
    }

    uint32_t n = target->nbins;
    for (uint32_t i = 0; i < n; ++i) {
        target->bins[i] -= other->bins[i];
        if (target->sum_w2 && other->sum_w2) {
            target->sum_w2[i] += other->sum_w2[i]; /* Errors add in quadrature */
        }
    }

    target->total_weight -= other->total_weight;
    if (target->sum_w2 && other->sum_w2) {
        target->total_sum_w2 += other->total_sum_w2;
    }
    target->underflow_weight -= other->underflow_weight;
    target->overflow_weight -= other->overflow_weight;
    if (target->sum_w2 && other->sum_w2) {
        target->underflow_sum_w2 += other->underflow_sum_w2;
        target->overflow_sum_w2 += other->overflow_sum_w2;
    }
    target->n_fills += other->n_fills;
    target->n_underflow += other->n_underflow;
    target->n_overflow += other->n_overflow;
    target->n_nan += other->n_nan;

    /* Recalculate exact moments after subtraction */
    if ((target->flags & HISTO_FLAG_EXACT_MOMENTS) && (other->flags & HISTO_FLAG_EXACT_MOMENTS)) {
        double w1 = target->total_weight + other->total_weight; /* previous total weight of target */
        double w2 = other->total_weight;
        double w_new = target->total_weight;
        if (w_new > 0.0 && w1 > 0.0) {
            double delta = other->stats_mean - target->stats_mean;
            target->stats_mean -= (w2 / w_new) * delta;
            target->stats_M2 -= other->stats_M2 + (w1 * w2 / w_new) * (delta * delta);
            if (target->stats_M2 < 0.0) target->stats_M2 = 0.0;
        } else {
            target->stats_mean = 0.0;
            target->stats_M2 = 0.0;
        }
    } else if (target->flags & HISTO_FLAG_EXACT_MOMENTS) {
        if (target->total_weight > 0.0) {
            double sum = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                sum += target->bins[i] * c;
            }
            target->stats_mean = sum / target->total_weight;
            double m2 = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                double diff = c - target->stats_mean;
                m2 += target->bins[i] * diff * diff;
            }
            target->stats_M2 = (m2 > 0.0) ? m2 : 0.0;
        } else {
            target->stats_mean = 0.0;
            target->stats_M2 = 0.0;
        }
    }

    return HISTO_OK;
}



histo_status_t histo_multiply(histo_t *target, const histo_t *other) {
    if (!target || !other) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!histo_are_compatible(target, other)) {
        return HISTO_ERR_INCOMPATIBLE;
    }

    uint32_t n = target->nbins;
    double new_total = 0.0;
    double new_total_w2 = 0.0;

    for (uint32_t i = 0; i < n; ++i) {
        double h1 = target->bins[i];
        double h2 = other->bins[i];

        if (target->sum_w2 && other->sum_w2) {
            double w1_sq = target->sum_w2[i];
            double w2_sq = other->sum_w2[i];
            /* Division-free error propagation */
            target->sum_w2[i] = h2 * h2 * w1_sq + h1 * h1 * w2_sq;
            new_total_w2 += target->sum_w2[i];
        }

        target->bins[i] = h1 * h2;
        new_total += target->bins[i];
    }

    target->total_weight = new_total;
    if (target->sum_w2) target->total_sum_w2 = new_total_w2;
    target->underflow_weight *= other->underflow_weight;
    target->overflow_weight *= other->overflow_weight;
    target->n_fills += other->n_fills;

    if (target->flags & HISTO_FLAG_EXACT_MOMENTS) {
        if (target->total_weight > 0.0) {
            double sum = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                sum += target->bins[i] * c;
            }
            target->stats_mean = sum / target->total_weight;
            double m2 = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                double diff = c - target->stats_mean;
                m2 += target->bins[i] * diff * diff;
            }
            target->stats_M2 = (m2 > 0.0) ? m2 : 0.0;
        } else {
            target->stats_mean = 0.0;
            target->stats_M2 = 0.0;
        }
    }

    return HISTO_OK;
}

histo_status_t histo_divide(histo_t *target, const histo_t *other) {
    if (!target || !other) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!histo_are_compatible(target, other)) {
        return HISTO_ERR_INCOMPATIBLE;
    }

    uint32_t n = target->nbins;
    double new_total = 0.0;
    double new_total_w2 = 0.0;

    for (uint32_t i = 0; i < n; ++i) {
        double h1 = target->bins[i];
        double h2 = other->bins[i];

        if (h2 == 0.0) {
            target->bins[i] = 0.0;
            if (target->sum_w2) target->sum_w2[i] = 0.0;
        } else {
            if (target->sum_w2 && other->sum_w2) {
                double w1_sq = target->sum_w2[i];
                double w2_sq = other->sum_w2[i];
                double h2_sq = h2 * h2;
                double h2_four = h2_sq * h2_sq;
                target->sum_w2[i] = (w1_sq * h2_sq + w2_sq * (h1 * h1)) / h2_four;
                new_total_w2 += target->sum_w2[i];
            }
            target->bins[i] = h1 / h2;
            new_total += target->bins[i];
        }
    }

    target->total_weight = new_total;
    if (target->sum_w2) target->total_sum_w2 = new_total_w2;
    if (other->underflow_weight != 0.0) target->underflow_weight /= other->underflow_weight;
    else target->underflow_weight = 0.0;
    if (other->overflow_weight != 0.0) target->overflow_weight /= other->overflow_weight;
    else target->overflow_weight = 0.0;
    target->n_fills += other->n_fills;

    if (target->flags & HISTO_FLAG_EXACT_MOMENTS) {
        if (target->total_weight > 0.0) {
            double sum = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                sum += target->bins[i] * c;
            }
            target->stats_mean = sum / target->total_weight;
            double m2 = 0.0;
            for (uint32_t i = 0; i < target->nbins; ++i) {
                double c = 0.0;
                histo_bin_center(target, i, &c);
                double diff = c - target->stats_mean;
                m2 += target->bins[i] * diff * diff;
            }
            target->stats_M2 = (m2 > 0.0) ? m2 : 0.0;
        } else {
            target->stats_mean = 0.0;
            target->stats_M2 = 0.0;
        }
    }

    return HISTO_OK;
}

histo_status_t histo_scale(histo_t *h, double factor) {
    if (!h) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!isfinite(factor)) {
        return HISTO_ERR_NON_FINITE;
    }

    double factor_sq = factor * factor;
    for (uint32_t i = 0; i < h->nbins; ++i) {
        h->bins[i] *= factor;
        if (h->sum_w2) {
            h->sum_w2[i] *= factor_sq;
        }
    }

    h->total_weight *= factor;
    if (h->sum_w2) h->total_sum_w2 *= factor_sq;
    h->underflow_weight *= factor;
    h->overflow_weight *= factor;
    if (h->sum_w2) {
        h->underflow_sum_w2 *= factor_sq;
        h->overflow_sum_w2 *= factor_sq;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        h->stats_M2 *= factor;
        if (h->stats_M2 < 0.0) {
            h->stats_M2 = 0.0;
        }
    }

    return HISTO_OK;
}

histo_status_t histo_normalize(histo_t *h, double target_area) {
    if (!h) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (!isfinite(target_area) || target_area <= 0.0) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    double factor = target_area / h->total_weight;
    return histo_scale(h, factor);
}

histo_t* histo_rebin(const histo_t *src, uint32_t factor) {
    if (!src || factor == 0 || factor > src->nbins || (src->nbins % factor != 0)) {
        return NULL;
    }

    uint32_t nbins_out = src->nbins / factor;
    histo_t *dst = NULL;

    if (src->bin_type == HISTO_BIN_UNIFORM) {
        dst = histo_create_uniform(nbins_out, src->min, src->max, src->flags);
    } else {
        double *new_edges = (double *)malloc((nbins_out + 1) * sizeof(double));
        if (!new_edges) return NULL;
        for (uint32_t i = 0; i <= nbins_out; ++i) {
            new_edges[i] = src->bin_edges[i * factor];
        }
        dst = histo_create_variable(nbins_out, new_edges, src->flags);
        free(new_edges);
    }

    if (!dst) return NULL;

    for (uint32_t i = 0; i < nbins_out; ++i) {
        double bin_sum = 0.0;
        double w2_sum = 0.0;
        uint32_t start = i * factor;
        uint32_t end = start + factor;
        for (uint32_t j = start; j < end; ++j) {
            bin_sum += src->bins[j];
            if (src->sum_w2) w2_sum += src->sum_w2[j];
        }
        dst->bins[i] = bin_sum;
        if (dst->sum_w2) dst->sum_w2[i] = w2_sum;
    }

    dst->total_weight = src->total_weight;
    dst->total_sum_w2 = src->total_sum_w2;
    dst->underflow_weight = src->underflow_weight;
    dst->overflow_weight = src->overflow_weight;
    dst->underflow_sum_w2 = src->underflow_sum_w2;
    dst->overflow_sum_w2 = src->overflow_sum_w2;
    dst->n_fills = src->n_fills;
    dst->n_underflow = src->n_underflow;
    dst->n_overflow = src->n_overflow;
    dst->n_nan = src->n_nan;
    dst->stats_min = src->stats_min;
    dst->stats_max = src->stats_max;
    dst->stats_mean = src->stats_mean;
    dst->stats_M2 = src->stats_M2;

    return dst;
}

histo_t* histo_slice(const histo_t *src, uint32_t start_bin, uint32_t end_bin, bool empty) {
    if (!src || start_bin > end_bin || end_bin >= src->nbins) {
        return NULL;
    }

    uint32_t nbins_new = end_bin - start_bin + 1;
    double lower_edge = 0.0, upper_edge = 0.0;
    histo_bin_bounds(src, start_bin, &lower_edge, &upper_edge);
    double start_min = lower_edge;
    histo_bin_bounds(src, end_bin, &lower_edge, &upper_edge);
    double end_max = upper_edge;

    histo_t *dst = NULL;
    if (src->bin_type == HISTO_BIN_UNIFORM) {
        dst = histo_create_uniform(nbins_new, start_min, end_max, src->flags);
    } else {
        double *new_edges = (double *)malloc((nbins_new + 1) * sizeof(double));
        if (!new_edges) return NULL;
        for (uint32_t i = 0; i <= nbins_new; ++i) {
            new_edges[i] = src->bin_edges[start_bin + i];
        }
        dst = histo_create_variable(nbins_new, new_edges, src->flags);
        free(new_edges);
    }

    if (!dst) return NULL;

    if (!empty) {
        double slice_total = 0.0;
        double slice_total_w2 = 0.0;
        for (uint32_t i = 0; i < nbins_new; ++i) {
            dst->bins[i] = src->bins[start_bin + i];
            slice_total += dst->bins[i];
            if (dst->sum_w2 && src->sum_w2) {
                dst->sum_w2[i] = src->sum_w2[start_bin + i];
                slice_total_w2 += dst->sum_w2[i];
            }
        }
        dst->total_weight = slice_total;
        if (dst->sum_w2) dst->total_sum_w2 = slice_total_w2;

        /* All bins before start_bin accumulate into underflow */
        double underflow_accum = src->underflow_weight;
        double underflow_w2_accum = src->underflow_sum_w2;
        for (uint32_t i = 0; i < start_bin; ++i) {
            underflow_accum += src->bins[i];
            if (src->sum_w2) underflow_w2_accum += src->sum_w2[i];
        }
        dst->underflow_weight = underflow_accum;
        if (dst->sum_w2) dst->underflow_sum_w2 = underflow_w2_accum;

        /* All bins after end_bin accumulate into overflow */
        double overflow_accum = src->overflow_weight;
        double overflow_w2_accum = src->overflow_sum_w2;
        for (uint32_t i = end_bin + 1; i < src->nbins; ++i) {
            overflow_accum += src->bins[i];
            if (src->sum_w2) overflow_w2_accum += src->sum_w2[i];
        }
        dst->overflow_weight = overflow_accum;
        if (dst->sum_w2) dst->overflow_sum_w2 = overflow_w2_accum;

        dst->n_fills = src->n_fills;
        dst->n_underflow = src->n_underflow;
        dst->n_overflow = src->n_overflow;
        dst->n_nan = src->n_nan;
    }

    return dst;
}

histo_t* histo_cdf(const histo_t *src, double prenormalization) {
    if (!src || src->total_weight <= 0.0) {
        return NULL;
    }

    histo_t *dst = histo_clone(src, true);
    if (!dst) return NULL;

    double scale = (prenormalization > 0.0) ? (prenormalization / src->total_weight) : (1.0 / src->total_weight);
    double running_sum = 0.0;

    for (uint32_t i = 0; i < src->nbins; ++i) {
        running_sum += src->bins[i] * scale;
        dst->bins[i] = running_sum;
    }
    dst->total_weight = running_sum;
    dst->n_fills = src->n_fills;

    return dst;
}

void histo_free_buffer(void *buf) {
    if (buf) {
        free(buf);
    }
}

/* ========================================================================= */
/* Automated Optimal Bin Width Heuristics                                    */
/* ========================================================================= */

static int compare_doubles(const void *a, const void *b) {
    double da = *(const double*)a;
    double db = *(const double*)b;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

static histo_status_t compute_sample_stats_sorted(
    size_t n, const double *values,
    double **out_sorted, size_t *out_valid_n,
    double *out_min, double *out_max,
    double *out_mean, double *out_std,
    double *out_skew, double *out_iqr
) {
    if (n == 0 || !values || !out_sorted || !out_valid_n || !out_min || !out_max) {
        return HISTO_ERR_INVALID_ARG;
    }

    double *sorted = (double*)malloc(n * sizeof(double));
    if (!sorted) return HISTO_ERR_NOMEM;

    size_t valid_n = 0;
    double min_v = DBL_MAX;
    double max_v = -DBL_MAX;
    double sum = 0.0;

    for (size_t i = 0; i < n; i++) {
        double v = values[i];
        if (isfinite(v)) {
            sorted[valid_n++] = v;
            sum += v;
            if (v < min_v) min_v = v;
            if (v > max_v) max_v = v;
        }
    }

    if (valid_n == 0) {
        free(sorted);
        return HISTO_ERR_EMPTY;
    }

    qsort(sorted, valid_n, sizeof(double), compare_doubles);

    double mean = sum / (double)valid_n;
    double sum_sq = 0.0;
    double sum_cub = 0.0;

    for (size_t i = 0; i < valid_n; i++) {
        double diff = sorted[i] - mean;
        sum_sq += diff * diff;
        sum_cub += diff * diff * diff;
    }

    double variance = (valid_n > 1) ? (sum_sq / (double)(valid_n - 1)) : 0.0;
    double std_dev = sqrt(variance);
    double skewness = 0.0;
    if (valid_n >= 3 && std_dev > 1e-12) {
        double m3 = sum_cub / (double)valid_n;
        skewness = m3 / (std_dev * std_dev * std_dev);
    }

    /* Compute IQR: Q75 - Q25 */
    double q25 = sorted[0];
    double q75 = sorted[valid_n - 1];
    if (valid_n >= 4) {
        size_t idx25 = (size_t)(0.25 * (double)(valid_n - 1));
        size_t idx75 = (size_t)(0.75 * (double)(valid_n - 1));
        q25 = sorted[idx25];
        q75 = sorted[idx75];
    }
    double iqr = (q75 >= q25) ? (q75 - q25) : 0.0;

    *out_sorted = sorted;
    *out_valid_n = valid_n;
    *out_min = min_v;
    *out_max = max_v;
    if (out_mean) *out_mean = mean;
    if (out_std) *out_std = std_dev;
    if (out_skew) *out_skew = skewness;
    if (out_iqr) *out_iqr = iqr;

    return HISTO_OK;
}

histo_status_t histo_estimate_bins_fd(size_t n, const double *values, uint32_t *out_nbins, double *out_min, double *out_max) {
    if (!out_nbins || !out_min || !out_max) return HISTO_ERR_INVALID_ARG;

    double *sorted = NULL;
    size_t valid_n = 0;
    double min_v = 0.0, max_v = 0.0, mean = 0.0, std_dev = 0.0, skewness = 0.0, iqr = 0.0;

    histo_status_t st = compute_sample_stats_sorted(n, values, &sorted, &valid_n, &min_v, &max_v, &mean, &std_dev, &skewness, &iqr);
    if (st != HISTO_OK) return st;
    free(sorted);

    double range = max_v - min_v;
    if (range <= 0.0) {
        *out_nbins = 1;
        *out_min = min_v - 0.5;
        *out_max = max_v + 0.5;
        return HISTO_OK;
    }

    double n_pow = pow((double)valid_n, -1.0 / 3.0);
    double h = 2.0 * iqr * n_pow;

    /* Fallback to Scott if IQR is 0 (e.g. large median cluster) */
    if (h <= 0.0 && std_dev > 0.0) {
        h = 3.49 * std_dev * n_pow;
    }

    uint32_t nbins = 10;
    if (h > 0.0) {
        double calc = ceil(range / h);
        nbins = (calc >= 1.0) ? (uint32_t)calc : 1;
    } else {
        /* Fallback to Sturges */
        double calc = ceil(log2((double)valid_n) + 1.0);
        nbins = (calc >= 1.0) ? (uint32_t)calc : 1;
    }

    if (nbins > 100000) nbins = 100000;
    if (nbins < 1) nbins = 1;

    *out_nbins = nbins;
    *out_min = min_v;
    *out_max = max_v;
    return HISTO_OK;
}

histo_status_t histo_estimate_bins_scott(size_t n, const double *values, uint32_t *out_nbins, double *out_min, double *out_max) {
    if (!out_nbins || !out_min || !out_max) return HISTO_ERR_INVALID_ARG;

    double *sorted = NULL;
    size_t valid_n = 0;
    double min_v = 0.0, max_v = 0.0, mean = 0.0, std_dev = 0.0, skewness = 0.0, iqr = 0.0;

    histo_status_t st = compute_sample_stats_sorted(n, values, &sorted, &valid_n, &min_v, &max_v, &mean, &std_dev, &skewness, &iqr);
    if (st != HISTO_OK) return st;
    free(sorted);

    double range = max_v - min_v;
    if (range <= 0.0) {
        *out_nbins = 1;
        *out_min = min_v - 0.5;
        *out_max = max_v + 0.5;
        return HISTO_OK;
    }

    double n_pow = pow((double)valid_n, -1.0 / 3.0);
    double h = 3.49 * std_dev * n_pow;

    uint32_t nbins = 10;
    if (h > 0.0) {
        double calc = ceil(range / h);
        nbins = (calc >= 1.0) ? (uint32_t)calc : 1;
    } else {
        double calc = ceil(log2((double)valid_n) + 1.0);
        nbins = (calc >= 1.0) ? (uint32_t)calc : 1;
    }

    if (nbins > 100000) nbins = 100000;
    if (nbins < 1) nbins = 1;

    *out_nbins = nbins;
    *out_min = min_v;
    *out_max = max_v;
    return HISTO_OK;
}

histo_status_t histo_estimate_bins_sturges(size_t n, const double *values, uint32_t *out_nbins, double *out_min, double *out_max) {
    if (!out_nbins || !out_min || !out_max) return HISTO_ERR_INVALID_ARG;

    double *sorted = NULL;
    size_t valid_n = 0;
    double min_v = 0.0, max_v = 0.0;

    histo_status_t st = compute_sample_stats_sorted(n, values, &sorted, &valid_n, &min_v, &max_v, NULL, NULL, NULL, NULL);
    if (st != HISTO_OK) return st;
    free(sorted);

    double range = max_v - min_v;
    if (range <= 0.0) {
        *out_nbins = 1;
        *out_min = min_v - 0.5;
        *out_max = max_v + 0.5;
        return HISTO_OK;
    }

    double calc = ceil(log2((double)valid_n) + 1.0);
    uint32_t nbins = (calc >= 1.0) ? (uint32_t)calc : 1;

    *out_nbins = nbins;
    *out_min = min_v;
    *out_max = max_v;
    return HISTO_OK;
}

histo_status_t histo_estimate_bins_doane(size_t n, const double *values, uint32_t *out_nbins, double *out_min, double *out_max) {
    if (!out_nbins || !out_min || !out_max) return HISTO_ERR_INVALID_ARG;

    double *sorted = NULL;
    size_t valid_n = 0;
    double min_v = 0.0, max_v = 0.0, mean = 0.0, std_dev = 0.0, skewness = 0.0, iqr = 0.0;

    histo_status_t st = compute_sample_stats_sorted(n, values, &sorted, &valid_n, &min_v, &max_v, &mean, &std_dev, &skewness, &iqr);
    if (st != HISTO_OK) return st;
    free(sorted);

    double range = max_v - min_v;
    if (range <= 0.0) {
        *out_nbins = 1;
        *out_min = min_v - 0.5;
        *out_max = max_v + 0.5;
        return HISTO_OK;
    }

    uint32_t nbins = 10;
    if (valid_n >= 3) {
        double nv = (double)valid_n;
        double sigma_g1 = sqrt((6.0 * (nv - 2.0)) / ((nv + 1.0) * (nv + 3.0)));
        double arg = 1.0 + fabs(skewness) / sigma_g1;
        double calc = ceil(1.0 + log2(nv) + log2(arg > 1.0 ? arg : 1.0));
        nbins = (calc >= 1.0) ? (uint32_t)calc : 1;
    } else {
        nbins = 1;
    }

    if (nbins > 100000) nbins = 100000;
    *out_nbins = nbins;
    *out_min = min_v;
    *out_max = max_v;
    return HISTO_OK;
}

histo_status_t histo_estimate_bins_knuth(size_t n, const double *values, uint32_t *out_nbins, double *out_min, double *out_max) {
    if (!out_nbins || !out_min || !out_max) return HISTO_ERR_INVALID_ARG;

    double *sorted = NULL;
    size_t valid_n = 0;
    double min_v = 0.0, max_v = 0.0;

    histo_status_t st = compute_sample_stats_sorted(n, values, &sorted, &valid_n, &min_v, &max_v, NULL, NULL, NULL, NULL);
    if (st != HISTO_OK) return st;

    double range = max_v - min_v;
    if (range <= 0.0) {
        free(sorted);
        *out_nbins = 1;
        *out_min = min_v - 0.5;
        *out_max = max_v + 0.5;
        return HISTO_OK;
    }

    /* Max candidate bins to evaluate */
    size_t max_m = 500;
    if (max_m > valid_n) max_m = valid_n;
    if (max_m < 1) max_m = 1;

    uint32_t best_m = 1;
    double best_log_p = -DBL_MAX;

    uint32_t *counts = (uint32_t*)calloc(max_m, sizeof(uint32_t));
    if (!counts) {
        free(sorted);
        return HISTO_ERR_NOMEM;
    }

    double log_gamma_half = lgamma(0.5);
    double nv = (double)valid_n;

    for (size_t m = 1; m <= max_m; m++) {
        memset(counts, 0, m * sizeof(uint32_t));
        double inv_dx = (double)m / range;

        for (size_t i = 0; i < valid_n; i++) {
            size_t idx = (size_t)((sorted[i] - min_v) * inv_dx);
            if (idx >= m) idx = m - 1;
            counts[idx]++;
        }

        double sum_lg = 0.0;
        for (size_t k = 0; k < m; k++) {
            sum_lg += lgamma((double)counts[k] + 0.5);
        }

        double half_m = 0.5 * (double)m;
        double log_p = nv * log((double)m) + lgamma(half_m) - (double)m * log_gamma_half - lgamma(nv + half_m) + sum_lg;

        if (log_p > best_log_p) {
            best_log_p = log_p;
            best_m = (uint32_t)m;
        }
    }

    free(counts);
    free(sorted);

    *out_nbins = best_m;
    *out_min = min_v;
    *out_max = max_v;
    return HISTO_OK;
}

histo_status_t histo_estimate_bins(size_t n, const double *values, histo_bin_rule_t rule, uint32_t *out_nbins, double *out_min, double *out_max) {
    switch (rule) {
        case HISTO_BIN_RULE_AUTO:
        case HISTO_BIN_RULE_FD:
            return histo_estimate_bins_fd(n, values, out_nbins, out_min, out_max);
        case HISTO_BIN_RULE_SCOTT:
            return histo_estimate_bins_scott(n, values, out_nbins, out_min, out_max);
        case HISTO_BIN_RULE_STURGES:
            return histo_estimate_bins_sturges(n, values, out_nbins, out_min, out_max);
        case HISTO_BIN_RULE_DOANE:
            return histo_estimate_bins_doane(n, values, out_nbins, out_min, out_max);
        case HISTO_BIN_RULE_KNUTH:
            return histo_estimate_bins_knuth(n, values, out_nbins, out_min, out_max);
        default:
            return histo_estimate_bins_fd(n, values, out_nbins, out_min, out_max);
    }
}

histo_t* histo_create_auto(size_t n, const double *values, histo_bin_rule_t rule, uint32_t flags) {
    if (n == 0 || !values) return NULL;

    uint32_t nbins = 0;
    double min_v = 0.0;
    double max_v = 0.0;

    histo_status_t st = histo_estimate_bins(n, values, rule, &nbins, &min_v, &max_v);
    if (st != HISTO_OK || nbins == 0) return NULL;

    double range = max_v - min_v;
    double eps = (range > 0.0) ? ((range / (double)nbins) * 1e-6) : 1e-6;

    histo_t *h = histo_create_uniform(nbins, min_v, max_v + eps, flags);
    if (!h) return NULL;

    histo_fill_n(h, n, values, NULL);
    return h;
}



