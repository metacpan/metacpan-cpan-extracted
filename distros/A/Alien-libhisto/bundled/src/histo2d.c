/*
 * 2D histogram implementation: creation, filling, projections, and 2D moments.
 */

#include "histo/histo2d.h"
#include "internal_2d.h"
#include "simd.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

/* -------------------------------------------------------------------------
 * Internal Axis Validation & Setup Helpers
 * ------------------------------------------------------------------------- */

static bool validate_axis_spec(const histo2d_axis_t *axis) {
    if (!axis) return false;
    if (axis->nbins == 0 || axis->nbins > HISTO_MAX_NBINS) return false;

    if (axis->type == HISTO_BIN_UNIFORM) {
        if (!isfinite(axis->min) || !isfinite(axis->max)) return false;
        if (axis->min >= axis->max) return false;
    } else if (axis->type == HISTO_BIN_VARIABLE) {
        if (!axis->edges) return false;
        for (uint32_t i = 0; i <= axis->nbins; ++i) {
            if (!isfinite(axis->edges[i])) return false;
        }
        for (uint32_t i = 0; i < axis->nbins; ++i) {
            if (axis->edges[i + 1] <= axis->edges[i]) return false;
        }
    } else {
        return false;
    }
    return true;
}

static bool init_axis_internal(histo2d_axis_internal_t *dst, const histo2d_axis_t *src) {
    dst->bin_type = src->type;
    dst->nbins = src->nbins;

    if (src->type == HISTO_BIN_UNIFORM) {
        dst->min = src->min;
        dst->max = src->max;
        dst->width = src->max - src->min;
        dst->binsize = dst->width / (double)src->nbins;
        dst->inv_binsize = (double)src->nbins / dst->width;
        dst->bin_edges = NULL;
    } else {
        dst->min = src->edges[0];
        dst->max = src->edges[src->nbins];
        dst->width = dst->max - dst->min;
        dst->binsize = 0.0;
        dst->inv_binsize = 0.0;
        dst->bin_edges = (double*)malloc((src->nbins + 1) * sizeof(double));
        if (!dst->bin_edges) return false;
        memcpy(dst->bin_edges, src->edges, (src->nbins + 1) * sizeof(double));
    }
    return true;
}

/* -------------------------------------------------------------------------
 * Lifecycle & Memory Management
 * ------------------------------------------------------------------------- */

histo2d_t* histo2d_create(const histo2d_axis_t *x_axis,
                          const histo2d_axis_t *y_axis,
                          uint32_t flags)
{
    if (!validate_axis_spec(x_axis) || !validate_axis_spec(y_axis)) {
        return NULL;
    }

    uint64_t total_cells = (uint64_t)x_axis->nbins * (uint64_t)y_axis->nbins;
    if (total_cells > HISTO_MAX_NBINS) {
        return NULL;
    }

    histo2d_t *h = (histo2d_t*)calloc(1, sizeof(histo2d_t));
    if (!h) return NULL;

    h->flags = flags;
    if (!init_axis_internal(&h->x_axis, x_axis) ||
        !init_axis_internal(&h->y_axis, y_axis))
    {
        histo2d_destroy(h);
        return NULL;
    }

    size_t data_bytes = (size_t)total_cells * sizeof(double);
    h->bins = (double*)histo2d_alloc_aligned(data_bytes);
    if (!h->bins) {
        histo2d_destroy(h);
        return NULL;
    }

    if (flags & HISTO_FLAG_TRACK_SUMW2) {
        h->sum_w2 = (double*)histo2d_alloc_aligned(data_bytes);
        if (!h->sum_w2) {
            histo2d_destroy(h);
            return NULL;
        }
    }

    h->stats_min_x = DBL_MAX;
    h->stats_max_x = -DBL_MAX;
    h->stats_min_y = DBL_MAX;
    h->stats_max_y = -DBL_MAX;

    return h;
}

histo2d_t* histo2d_create_uniform(uint32_t nx, double xmin, double xmax,
                                  uint32_t ny, double ymin, double ymax,
                                  uint32_t flags)
{
    histo2d_axis_t x_axis = { HISTO_BIN_UNIFORM, nx, xmin, xmax, NULL };
    histo2d_axis_t y_axis = { HISTO_BIN_UNIFORM, ny, ymin, ymax, NULL };
    return histo2d_create(&x_axis, &y_axis, flags);
}

histo2d_t* histo2d_create_variable(uint32_t nx, const double *xedges,
                                   uint32_t ny, const double *yedges,
                                   uint32_t flags)
{
    if (!xedges || !yedges) return NULL;
    histo2d_axis_t x_axis = { HISTO_BIN_VARIABLE, nx, xedges[0], xedges[nx], xedges };
    histo2d_axis_t y_axis = { HISTO_BIN_VARIABLE, ny, yedges[0], yedges[ny], yedges };
    return histo2d_create(&x_axis, &y_axis, flags);
}

histo2d_t* histo2d_create_uniform_variable(uint32_t nx, double xmin, double xmax,
                                           uint32_t ny, const double *yedges,
                                           uint32_t flags)
{
    if (!yedges) return NULL;
    histo2d_axis_t x_axis = { HISTO_BIN_UNIFORM, nx, xmin, xmax, NULL };
    histo2d_axis_t y_axis = { HISTO_BIN_VARIABLE, ny, yedges[0], yedges[ny], yedges };
    return histo2d_create(&x_axis, &y_axis, flags);
}

histo2d_t* histo2d_create_variable_uniform(uint32_t nx, const double *xedges,
                                           uint32_t ny, double ymin, double ymax,
                                           uint32_t flags)
{
    if (!xedges) return NULL;
    histo2d_axis_t x_axis = { HISTO_BIN_VARIABLE, nx, xedges[0], xedges[nx], xedges };
    histo2d_axis_t y_axis = { HISTO_BIN_UNIFORM, ny, ymin, ymax, NULL };
    return histo2d_create(&x_axis, &y_axis, flags);
}

void histo2d_destroy(histo2d_t *h) {
    if (!h) return;
    histo2d_free_aligned(h->bins);
    histo2d_free_aligned(h->sum_w2);
    free(h->x_axis.bin_edges);
    free(h->y_axis.bin_edges);
    free(h);
}

histo2d_t* histo2d_clone(const histo2d_t *src, bool empty) {
    if (!src) return NULL;

    histo2d_axis_t x_axis = {
        src->x_axis.bin_type,
        src->x_axis.nbins,
        src->x_axis.min,
        src->x_axis.max,
        src->x_axis.bin_edges
    };
    histo2d_axis_t y_axis = {
        src->y_axis.bin_type,
        src->y_axis.nbins,
        src->y_axis.min,
        src->y_axis.max,
        src->y_axis.bin_edges
    };

    histo2d_t *dst = histo2d_create(&x_axis, &y_axis, src->flags);
    if (!dst) return NULL;

    if (!empty) {
        size_t total_cells = (size_t)src->x_axis.nbins * (size_t)src->y_axis.nbins;
        memcpy(dst->bins, src->bins, total_cells * sizeof(double));
        if (src->sum_w2 && dst->sum_w2) {
            memcpy(dst->sum_w2, src->sum_w2, total_cells * sizeof(double));
        }
        dst->total_weight = src->total_weight;
        dst->total_sum_w2 = src->total_sum_w2;
        dst->n_fills = src->n_fills;
        dst->n_nan = src->n_nan;
        memcpy(dst->guards, src->guards, sizeof(src->guards));

        dst->stats_min_x = src->stats_min_x;
        dst->stats_max_x = src->stats_max_x;
        dst->stats_min_y = src->stats_min_y;
        dst->stats_max_y = src->stats_max_y;
        dst->stats_mean_x = src->stats_mean_x;
        dst->stats_mean_y = src->stats_mean_y;
        dst->stats_M2_x = src->stats_M2_x;
        dst->stats_M2_y = src->stats_M2_y;
        dst->stats_C_xy = src->stats_C_xy;
    }

    return dst;
}

histo_status_t histo2d_reset(histo2d_t *h) {
    if (!h) return HISTO_ERR_INVALID_ARG;

    size_t total_cells = (size_t)h->x_axis.nbins * (size_t)h->y_axis.nbins;
    memset(h->bins, 0, total_cells * sizeof(double));
    if (h->sum_w2) {
        memset(h->sum_w2, 0, total_cells * sizeof(double));
    }

    h->total_weight = 0.0;
    h->total_sum_w2 = 0.0;
    h->n_fills = 0;
    h->n_nan = 0;
    memset(h->guards, 0, sizeof(h->guards));

    h->stats_min_x = DBL_MAX;
    h->stats_max_x = -DBL_MAX;
    h->stats_min_y = DBL_MAX;
    h->stats_max_y = -DBL_MAX;
    h->stats_mean_x = 0.0;
    h->stats_mean_y = 0.0;
    h->stats_M2_x = 0.0;
    h->stats_M2_y = 0.0;
    h->stats_C_xy = 0.0;

    return HISTO_OK;
}

/* -------------------------------------------------------------------------
 * Ingestion & 2D Welford Updating
 * ------------------------------------------------------------------------- */

static inline void histo2d_update_online_moments(histo2d_t *h, double x, double y, double w) {
    if (w <= 0.0) return;

    if (x < h->stats_min_x) h->stats_min_x = x;
    if (x > h->stats_max_x) h->stats_max_x = x;
    if (y < h->stats_min_y) h->stats_min_y = y;
    if (y > h->stats_max_y) h->stats_max_y = y;

    double prev_w = h->total_weight - w;
    if (prev_w <= 0.0) {
        h->stats_mean_x = x;
        h->stats_mean_y = y;
        h->stats_M2_x = 0.0;
        h->stats_M2_y = 0.0;
        h->stats_C_xy = 0.0;
    } else {
        double dx = x - h->stats_mean_x;
        double dy = y - h->stats_mean_y;
        double rx = (w / h->total_weight) * dx;
        double ry = (w / h->total_weight) * dy;

        h->stats_mean_x += rx;
        h->stats_mean_y += ry;

        h->stats_M2_x += prev_w * dx * rx;
        h->stats_M2_y += prev_w * dy * ry;
        h->stats_C_xy += prev_w * dx * ry;
    }
}

histo_status_t histo2d_fill(histo2d_t *h, double x, double y) {
    return histo2d_fill_w(h, x, y, 1.0);
}

histo_status_t histo2d_fill_w(histo2d_t *h, double x, double y, double weight) {
    if (!h) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(x) || !isfinite(y) || !isfinite(weight)) {
        h->n_nan++;
        return HISTO_ERR_NON_FINITE;
    }

    histo2d_region_t region = histo2d_classify_region(&h->x_axis, &h->y_axis, x, y);
    h->guards[region].weight += weight;
    h->guards[region].sum_w2 += weight * weight;
    h->guards[region].count++;

    if (region == HISTO2D_REGION_CENTER) {
        int64_t ix = histo2d_axis_find_bin(&h->x_axis, x);
        int64_t iy = histo2d_axis_find_bin(&h->y_axis, y);
        if (ix >= 0 && ix < (int64_t)h->x_axis.nbins &&
            iy >= 0 && iy < (int64_t)h->y_axis.nbins)
        {
            size_t idx = histo2d_linear_index((uint32_t)ix, (uint32_t)iy, h->y_axis.nbins);
            h->bins[idx] += weight;
            if (h->sum_w2) {
                h->sum_w2[idx] += weight * weight;
            }
            h->total_weight += weight;
            h->total_sum_w2 += weight * weight;
            h->n_fills++;

            if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
                histo2d_update_online_moments(h, x, y, weight);
            }
        }
    }

    return HISTO_OK;
}

histo_status_t histo2d_fill_n(histo2d_t *h, size_t n,
                              const double *x, const double *y,
                              const double *weights)
{
    if (!h || (n > 0 && (!x || !y))) return HISTO_ERR_INVALID_ARG;
    if (n == 0) return HISTO_OK;

    bool had_nan = false;

    if (h->x_axis.bin_type == HISTO_BIN_UNIFORM && h->y_axis.bin_type == HISTO_BIN_UNIFORM &&
        !(h->flags & HISTO_FLAG_EXACT_MOMENTS)) {
        if (weights) {
#ifdef LIBHISTO_ENABLE_AVX512
            if (histo_simd_has_avx512()) {
                had_nan = histo2d_fill_uniform_w2_avx512(h, x, y, weights, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_AVX2
            if (histo_simd_has_avx2()) {
                had_nan = histo2d_fill_uniform_w2_avx2(h, x, y, weights, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_NEON
            if (histo_simd_has_neon()) {
                had_nan = histo2d_fill_uniform_w2_neon(h, x, y, weights, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
        } else {
#ifdef LIBHISTO_ENABLE_AVX512
            if (histo_simd_has_avx512()) {
                had_nan = histo2d_fill_uniform_avx512(h, x, y, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_AVX2
            if (histo_simd_has_avx2()) {
                had_nan = histo2d_fill_uniform_avx2(h, x, y, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
#ifdef LIBHISTO_ENABLE_NEON
            if (histo_simd_has_neon()) {
                had_nan = histo2d_fill_uniform_neon(h, x, y, n);
                return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
            }
#endif
        }
    }



    for (size_t i = 0; i < n; ++i) {
        double xi = x[i];
        double yi = y[i];
        double w = weights ? weights[i] : 1.0;

        if (!isfinite(xi) || !isfinite(yi) || !isfinite(w)) {
            h->n_nan++;
            had_nan = true;
            continue;
        }

        histo2d_fill_w(h, xi, yi, w);
    }

    return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
}

histo_status_t histo2d_fill_strided(histo2d_t *h, size_t n,
                                    const double *x, size_t x_stride_bytes,
                                    const double *y, size_t y_stride_bytes,
                                    const double *weights, size_t w_stride_bytes)
{
    if (!h || (n > 0 && (!x || !y))) return HISTO_ERR_INVALID_ARG;
    if (n == 0) return HISTO_OK;

    const char *px = (const char*)x;
    const char *py = (const char*)y;
    const char *pw = (const char*)weights;
    bool had_nan = false;

    for (size_t i = 0; i < n; ++i) {
        double xi = *(const double*)(const void*)px;
        double yi = *(const double*)(const void*)py;
        double w = weights ? *(const double*)(const void*)pw : 1.0;

        if (!isfinite(xi) || !isfinite(yi) || !isfinite(w)) {
            h->n_nan++;
            had_nan = true;
        } else {
            histo2d_fill_w(h, xi, yi, w);
        }

        px += x_stride_bytes;
        py += y_stride_bytes;
        if (weights) pw += w_stride_bytes;
    }

    return had_nan ? HISTO_WARN_NON_FINITE : HISTO_OK;
}

histo_status_t histo2d_fill_bin(histo2d_t *h, uint32_t ix, uint32_t iy, double weight) {
    if (!h) return HISTO_ERR_INVALID_ARG;
    if (ix >= h->x_axis.nbins || iy >= h->y_axis.nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }
    if (!isfinite(weight)) {
        h->n_nan++;
        return HISTO_ERR_NON_FINITE;
    }

    size_t idx = histo2d_linear_index(ix, iy, h->y_axis.nbins);
    h->bins[idx] += weight;
    if (h->sum_w2) {
        h->sum_w2[idx] += weight * weight;
    }
    h->total_weight += weight;
    h->total_sum_w2 += weight * weight;
    h->n_fills++;
    h->guards[HISTO2D_REGION_CENTER].weight += weight;
    h->guards[HISTO2D_REGION_CENTER].sum_w2 += weight * weight;
    h->guards[HISTO2D_REGION_CENTER].count++;

    return HISTO_OK;
}

/* -------------------------------------------------------------------------
 * Geometry & Queries
 * ------------------------------------------------------------------------- */

uint32_t histo2d_nbins_x(const histo2d_t *h) {
    return h ? h->x_axis.nbins : 0;
}

uint32_t histo2d_nbins_y(const histo2d_t *h) {
    return h ? h->y_axis.nbins : 0;
}

histo_status_t histo2d_axis_x(const histo2d_t *h, histo2d_axis_t *out_axis) {
    if (!h || !out_axis) return HISTO_ERR_INVALID_ARG;
    out_axis->type = h->x_axis.bin_type;
    out_axis->nbins = h->x_axis.nbins;
    out_axis->min = h->x_axis.min;
    out_axis->max = h->x_axis.max;
    out_axis->edges = h->x_axis.bin_edges;
    return HISTO_OK;
}

histo_status_t histo2d_axis_y(const histo2d_t *h, histo2d_axis_t *out_axis) {
    if (!h || !out_axis) return HISTO_ERR_INVALID_ARG;
    out_axis->type = h->y_axis.bin_type;
    out_axis->nbins = h->y_axis.nbins;
    out_axis->min = h->y_axis.min;
    out_axis->max = h->y_axis.max;
    out_axis->edges = h->y_axis.bin_edges;
    return HISTO_OK;
}

histo_status_t histo2d_find_bin(const histo2d_t *h, double x, double y,
                                int64_t *out_ix, int64_t *out_iy)
{
    if (!h || !out_ix || !out_iy) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(x) || !isfinite(y)) return HISTO_ERR_NON_FINITE;

    *out_ix = histo2d_axis_find_bin(&h->x_axis, x);
    *out_iy = histo2d_axis_find_bin(&h->y_axis, y);
    return HISTO_OK;
}

histo_status_t histo2d_find_region(const histo2d_t *h, double x, double y,
                                   histo2d_region_t *out_region)
{
    if (!h || !out_region) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(x) || !isfinite(y)) return HISTO_ERR_NON_FINITE;

    *out_region = histo2d_classify_region(&h->x_axis, &h->y_axis, x, y);
    return HISTO_OK;
}

histo_status_t histo2d_bin_content(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                   double *out_weight)
{
    if (!h || !out_weight) return HISTO_ERR_INVALID_ARG;
    if (ix >= h->x_axis.nbins || iy >= h->y_axis.nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }
    *out_weight = h->bins[histo2d_linear_index(ix, iy, h->y_axis.nbins)];
    return HISTO_OK;
}

histo_status_t histo2d_bin_error(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                 double *out_error)
{
    if (!h || !out_error) return HISTO_ERR_INVALID_ARG;
    if (ix >= h->x_axis.nbins || iy >= h->y_axis.nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    size_t idx = histo2d_linear_index(ix, iy, h->y_axis.nbins);
    if (h->sum_w2) {
        *out_error = sqrt(h->sum_w2[idx]);
    } else {
        double c = h->bins[idx];
        *out_error = (c > 0.0) ? sqrt(c) : 0.0;
    }
    return HISTO_OK;
}

histo_status_t histo2d_bin_sum_w2(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_sum_w2)
{
    if (!h || !out_sum_w2) return HISTO_ERR_INVALID_ARG;
    if (ix >= h->x_axis.nbins || iy >= h->y_axis.nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }
    if (!h->sum_w2) {
        return HISTO_ERR_INVALID_ARG;
    }
    *out_sum_w2 = h->sum_w2[histo2d_linear_index(ix, iy, h->y_axis.nbins)];
    return HISTO_OK;
}

histo_status_t histo2d_bin_bounds(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_xmin, double *out_xmax,
                                  double *out_ymin, double *out_ymax)
{
    if (!h || !out_xmin || !out_xmax || !out_ymin || !out_ymax) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (ix >= h->x_axis.nbins || iy >= h->y_axis.nbins) {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    if (h->x_axis.bin_type == HISTO_BIN_UNIFORM) {
        *out_xmin = h->x_axis.min + (double)ix * h->x_axis.binsize;
        *out_xmax = *out_xmin + h->x_axis.binsize;
    } else {
        *out_xmin = h->x_axis.bin_edges[ix];
        *out_xmax = h->x_axis.bin_edges[ix + 1];
    }

    if (h->y_axis.bin_type == HISTO_BIN_UNIFORM) {
        *out_ymin = h->y_axis.min + (double)iy * h->y_axis.binsize;
        *out_ymax = *out_ymin + h->y_axis.binsize;
    } else {
        *out_ymin = h->y_axis.bin_edges[iy];
        *out_ymax = h->y_axis.bin_edges[iy + 1];
    }

    return HISTO_OK;
}

histo_status_t histo2d_bin_center(const histo2d_t *h, uint32_t ix, uint32_t iy,
                                  double *out_cx, double *out_cy)
{
    if (!h || !out_cx || !out_cy) return HISTO_ERR_INVALID_ARG;
    double xmin, xmax, ymin, ymax;
    histo_status_t status = histo2d_bin_bounds(h, ix, iy, &xmin, &xmax, &ymin, &ymax);
    if (status != HISTO_OK) return status;

    *out_cx = 0.5 * (xmin + xmax);
    *out_cy = 0.5 * (ymin + ymax);
    return HISTO_OK;
}

histo_status_t histo2d_region_content(const histo2d_t *h, histo2d_region_t region,
                                      double *out_weight, uint64_t *out_count)
{
    if (!h || (int)region < 0 || region >= HISTO2D_REGION_COUNT) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (out_weight) *out_weight = h->guards[region].weight;
    if (out_count)  *out_count  = h->guards[region].count;
    return HISTO_OK;
}

uint64_t histo2d_nan_count(const histo2d_t *h) {
    return h ? h->n_nan : 0;
}

double histo2d_total_weight(const histo2d_t *h) {
    return h ? h->total_weight : 0.0;
}

uint64_t histo2d_num_entries(const histo2d_t *h) {
    return h ? h->n_fills : 0;
}

/* -------------------------------------------------------------------------
 * Moments & Bivariate Statistics
 * ------------------------------------------------------------------------- */

static void histo2d_compute_grid_moments(const histo2d_t *h,
                                         double *out_mean_x, double *out_mean_y,
                                         double *out_var_x, double *out_var_y,
                                         double *out_cov)
{
    double sum_w = 0.0;
    double sum_wx = 0.0;
    double sum_wy = 0.0;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    for (uint32_t ix = 0; ix < nx; ++ix) {
        for (uint32_t iy = 0; iy < ny; ++iy) {
            double w = h->bins[histo2d_linear_index(ix, iy, ny)];
            if (w <= 0.0) continue;

            double cx = 0.0, cy = 0.0;
            histo2d_bin_center(h, ix, iy, &cx, &cy);

            sum_w += w;
            sum_wx += w * cx;
            sum_wy += w * cy;
        }
    }

    if (sum_w <= 0.0) {
        if (out_mean_x) *out_mean_x = 0.0;
        if (out_mean_y) *out_mean_y = 0.0;
        if (out_var_x)  *out_var_x = 0.0;
        if (out_var_y)  *out_var_y = 0.0;
        if (out_cov)    *out_cov = 0.0;
        return;
    }

    double mx = sum_wx / sum_w;
    double my = sum_wy / sum_w;

    double sum_wxx = 0.0;
    double sum_wyy = 0.0;
    double sum_wxy = 0.0;

    for (uint32_t ix = 0; ix < nx; ++ix) {
        for (uint32_t iy = 0; iy < ny; ++iy) {
            double w = h->bins[histo2d_linear_index(ix, iy, ny)];
            if (w <= 0.0) continue;

            double cx = 0.0, cy = 0.0;
            histo2d_bin_center(h, ix, iy, &cx, &cy);


            double dx = cx - mx;
            double dy = cy - my;

            sum_wxx += w * dx * dx;
            sum_wyy += w * dy * dy;
            sum_wxy += w * dx * dy;
        }
    }

    if (out_mean_x) *out_mean_x = mx;
    if (out_mean_y) *out_mean_y = my;
    if (out_var_x)  *out_var_x = sum_wxx / sum_w;
    if (out_var_y)  *out_var_y = sum_wyy / sum_w;
    if (out_cov)    *out_cov = sum_wxy / sum_w;
}

histo_status_t histo2d_mean_x(const histo2d_t *h, double *out_mean_x) {
    if (!h || !out_mean_x) return HISTO_ERR_INVALID_ARG;
    if (h->total_weight <= 0.0) {
        *out_mean_x = 0.0;
        return HISTO_ERR_EMPTY;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_mean_x = h->stats_mean_x;
    } else {
        histo2d_compute_grid_moments(h, out_mean_x, NULL, NULL, NULL, NULL);
    }
    return HISTO_OK;
}

histo_status_t histo2d_mean_y(const histo2d_t *h, double *out_mean_y) {
    if (!h || !out_mean_y) return HISTO_ERR_INVALID_ARG;
    if (h->total_weight <= 0.0) {
        *out_mean_y = 0.0;
        return HISTO_ERR_EMPTY;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_mean_y = h->stats_mean_y;
    } else {
        histo2d_compute_grid_moments(h, NULL, out_mean_y, NULL, NULL, NULL);
    }
    return HISTO_OK;
}

histo_status_t histo2d_variance_x(const histo2d_t *h, double *out_var_x) {
    if (!h || !out_var_x) return HISTO_ERR_INVALID_ARG;
    if (h->total_weight <= 0.0) {
        *out_var_x = 0.0;
        return HISTO_ERR_EMPTY;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_var_x = (h->total_weight > 0.0) ? (h->stats_M2_x / h->total_weight) : 0.0;
    } else {
        histo2d_compute_grid_moments(h, NULL, NULL, out_var_x, NULL, NULL);
    }
    return HISTO_OK;
}

histo_status_t histo2d_variance_y(const histo2d_t *h, double *out_var_y) {
    if (!h || !out_var_y) return HISTO_ERR_INVALID_ARG;
    if (h->total_weight <= 0.0) {
        *out_var_y = 0.0;
        return HISTO_ERR_EMPTY;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_var_y = (h->total_weight > 0.0) ? (h->stats_M2_y / h->total_weight) : 0.0;
    } else {
        histo2d_compute_grid_moments(h, NULL, NULL, NULL, out_var_y, NULL);
    }
    return HISTO_OK;
}

histo_status_t histo2d_std_dev_x(const histo2d_t *h, double *out_std_x) {
    if (!h || !out_std_x) return HISTO_ERR_INVALID_ARG;
    double var;
    histo_status_t status = histo2d_variance_x(h, &var);
    if (status != HISTO_OK) return status;
    *out_std_x = (var > 0.0) ? sqrt(var) : 0.0;
    return HISTO_OK;
}

histo_status_t histo2d_std_dev_y(const histo2d_t *h, double *out_std_y) {
    if (!h || !out_std_y) return HISTO_ERR_INVALID_ARG;
    double var;
    histo_status_t status = histo2d_variance_y(h, &var);
    if (status != HISTO_OK) return status;
    *out_std_y = (var > 0.0) ? sqrt(var) : 0.0;
    return HISTO_OK;
}

histo_status_t histo2d_covariance(const histo2d_t *h, double *out_cov) {
    if (!h || !out_cov) return HISTO_ERR_INVALID_ARG;
    if (h->total_weight <= 0.0) {
        *out_cov = 0.0;
        return HISTO_ERR_EMPTY;
    }
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) {
        *out_cov = h->stats_C_xy / h->total_weight;
    } else {
        histo2d_compute_grid_moments(h, NULL, NULL, NULL, NULL, out_cov);
    }
    return HISTO_OK;
}

histo_status_t histo2d_correlation(const histo2d_t *h, double *out_rho) {
    if (!h || !out_rho) return HISTO_ERR_INVALID_ARG;
    double var_x, var_y, cov;
    histo_status_t sx = histo2d_variance_x(h, &var_x);
    histo_status_t sy = histo2d_variance_y(h, &var_y);
    histo_status_t sc = histo2d_covariance(h, &cov);

    if (sx != HISTO_OK || sy != HISTO_OK || sc != HISTO_OK) {
        *out_rho = 0.0;
        return (sx != HISTO_OK) ? sx : ((sy != HISTO_OK) ? sy : sc);
    }

    double denom = sqrt(var_x * var_y);
    if (denom <= 1e-15) {
        *out_rho = 0.0;
        return HISTO_OK;
    }

    double rho = cov / denom;
    if (rho > 1.0) rho = 1.0;
    if (rho < -1.0) rho = -1.0;
    *out_rho = rho;
    return HISTO_OK;
}

histo_status_t histo2d_integral(const histo2d_t *h, double *out_integral) {
    if (!h || !out_integral) return HISTO_ERR_INVALID_ARG;
    *out_integral = h->total_weight;
    return HISTO_OK;
}

histo_status_t histo2d_integral_range(const histo2d_t *h,
                                      uint32_t ix_min, uint32_t ix_max,
                                      uint32_t iy_min, uint32_t iy_max,
                                      double *out_integral)
{
    if (!h || !out_integral) return HISTO_ERR_INVALID_ARG;
    if (ix_min > ix_max || ix_max >= h->x_axis.nbins ||
        iy_min > iy_max || iy_max >= h->y_axis.nbins)
    {
        return HISTO_ERR_OUT_OF_RANGE;
    }

    double sum = 0.0;
    uint32_t ny = h->y_axis.nbins;
    for (uint32_t ix = ix_min; ix <= ix_max; ++ix) {
        for (uint32_t iy = iy_min; iy <= iy_max; ++iy) {
            sum += h->bins[histo2d_linear_index(ix, iy, ny)];
        }
    }

    *out_integral = sum;
    return HISTO_OK;
}

histo_status_t histo2d_get_stats(const histo2d_t *h, histo2d_stats_t *out_stats) {
    if (!h || !out_stats) return HISTO_ERR_INVALID_ARG;

    out_stats->n_entries = h->n_fills;
    out_stats->total_weight = h->total_weight;
    out_stats->min_x = h->x_axis.min;
    out_stats->max_x = h->x_axis.max;
    out_stats->min_y = h->y_axis.min;
    out_stats->max_y = h->y_axis.max;

    histo2d_mean_x(h, &out_stats->mean_x);
    histo2d_mean_y(h, &out_stats->mean_y);
    histo2d_variance_x(h, &out_stats->variance_x);
    histo2d_variance_y(h, &out_stats->variance_y);
    histo2d_std_dev_x(h, &out_stats->std_dev_x);
    histo2d_std_dev_y(h, &out_stats->std_dev_y);
    histo2d_covariance(h, &out_stats->covariance);
    histo2d_correlation(h, &out_stats->correlation);

    return HISTO_OK;
}

histo_status_t histo2d_project_x(const histo2d_t *h, histo_t **out_h1d) {
    if (!h || !out_h1d) return HISTO_ERR_INVALID_ARG;

    histo_t *h1 = NULL;
    if (h->x_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->x_axis.nbins, h->x_axis.min, h->x_axis.max, h->flags);
    } else {
        h1 = histo_create_variable(h->x_axis.nbins, h->x_axis.bin_edges, h->flags);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    double *proj_w = (double *)malloc(nx * sizeof(double));
    double *proj_w2 = (double *)malloc(nx * sizeof(double));
    if (!proj_w || !proj_w2) {
        free(proj_w);
        free(proj_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t ix = 0; ix < nx; ++ix) {
        double sum_w = 0.0;
        double sum_w2 = 0.0;
        for (uint32_t iy = 0; iy < ny; ++iy) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            sum_w += h->bins[idx];
            if (h->sum_w2) sum_w2 += h->sum_w2[idx];
        }
        proj_w[ix] = sum_w;
        proj_w2[ix] = sum_w2;
    }

    histo_set_raw_bin_contents(h1, proj_w, proj_w2);
    free(proj_w);
    free(proj_w2);

    *out_h1d = h1;
    return HISTO_OK;
}

histo_status_t histo2d_project_y(const histo2d_t *h, histo_t **out_h1d) {
    if (!h || !out_h1d) return HISTO_ERR_INVALID_ARG;

    histo_t *h1 = NULL;
    if (h->y_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->y_axis.nbins, h->y_axis.min, h->y_axis.max, h->flags);
    } else {
        h1 = histo_create_variable(h->y_axis.nbins, h->y_axis.bin_edges, h->flags);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    double *proj_w = (double *)malloc(ny * sizeof(double));
    double *proj_w2 = (double *)malloc(ny * sizeof(double));
    if (!proj_w || !proj_w2) {
        free(proj_w);
        free(proj_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t iy = 0; iy < ny; ++iy) {
        double sum_w = 0.0;
        double sum_w2 = 0.0;
        for (uint32_t ix = 0; ix < nx; ++ix) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            sum_w += h->bins[idx];
            if (h->sum_w2) sum_w2 += h->sum_w2[idx];
        }
        proj_w[iy] = sum_w;
        proj_w2[iy] = sum_w2;
    }

    histo_set_raw_bin_contents(h1, proj_w, proj_w2);
    free(proj_w);
    free(proj_w2);

    *out_h1d = h1;
    return HISTO_OK;
}

histo_status_t histo2d_slice_x(const histo2d_t *h, uint32_t iy_min, uint32_t iy_max,
                               histo_t **out_h1d)
{
    if (!h || !out_h1d) return HISTO_ERR_INVALID_ARG;
    if (iy_min > iy_max || iy_max >= h->y_axis.nbins) return HISTO_ERR_OUT_OF_RANGE;

    histo_t *h1 = NULL;
    if (h->x_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->x_axis.nbins, h->x_axis.min, h->x_axis.max, h->flags);
    } else {
        h1 = histo_create_variable(h->x_axis.nbins, h->x_axis.bin_edges, h->flags);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    double *slice_w = (double *)malloc(nx * sizeof(double));
    double *slice_w2 = (double *)malloc(nx * sizeof(double));
    if (!slice_w || !slice_w2) {
        free(slice_w);
        free(slice_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t ix = 0; ix < nx; ++ix) {
        double sum_w = 0.0;
        double sum_w2 = 0.0;
        for (uint32_t iy = iy_min; iy <= iy_max; ++iy) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            sum_w += h->bins[idx];
            if (h->sum_w2) sum_w2 += h->sum_w2[idx];
        }
        slice_w[ix] = sum_w;
        slice_w2[ix] = sum_w2;
    }

    histo_set_raw_bin_contents(h1, slice_w, slice_w2);
    free(slice_w);
    free(slice_w2);

    *out_h1d = h1;
    return HISTO_OK;
}

histo_status_t histo2d_slice_y(const histo2d_t *h, uint32_t ix_min, uint32_t ix_max,
                               histo_t **out_h1d)
{
    if (!h || !out_h1d) return HISTO_ERR_INVALID_ARG;
    if (ix_min > ix_max || ix_max >= h->x_axis.nbins) return HISTO_ERR_OUT_OF_RANGE;

    histo_t *h1 = NULL;
    if (h->y_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->y_axis.nbins, h->y_axis.min, h->y_axis.max, h->flags);
    } else {
        h1 = histo_create_variable(h->y_axis.nbins, h->y_axis.bin_edges, h->flags);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t ny = h->y_axis.nbins;

    double *slice_w = (double *)malloc(ny * sizeof(double));
    double *slice_w2 = (double *)malloc(ny * sizeof(double));
    if (!slice_w || !slice_w2) {
        free(slice_w);
        free(slice_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t iy = 0; iy < ny; ++iy) {
        double sum_w = 0.0;
        double sum_w2 = 0.0;
        for (uint32_t ix = ix_min; ix <= ix_max; ++ix) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            sum_w += h->bins[idx];
            if (h->sum_w2) sum_w2 += h->sum_w2[idx];
        }
        slice_w[iy] = sum_w;
        slice_w2[iy] = sum_w2;
    }

    histo_set_raw_bin_contents(h1, slice_w, slice_w2);
    free(slice_w);
    free(slice_w2);

    *out_h1d = h1;
    return HISTO_OK;
}

histo_status_t histo2d_profile_x(const histo2d_t *h, histo_t **out_profile_1d) {
    if (!h || !out_profile_1d) return HISTO_ERR_INVALID_ARG;

    histo_t *h1 = NULL;
    if (h->x_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->x_axis.nbins, h->x_axis.min, h->x_axis.max, HISTO_FLAG_TRACK_SUMW2);
    } else {
        h1 = histo_create_variable(h->x_axis.nbins, h->x_axis.bin_edges, HISTO_FLAG_TRACK_SUMW2);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    double *prof_w = (double *)malloc(nx * sizeof(double));
    double *prof_w2 = (double *)malloc(nx * sizeof(double));
    if (!prof_w || !prof_w2) {
        free(prof_w);
        free(prof_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t ix = 0; ix < nx; ++ix) {
        double sum_w = 0.0;
        double sum_wy = 0.0;

        for (uint32_t iy = 0; iy < ny; ++iy) {
            double w = h->bins[histo2d_linear_index(ix, iy, ny)];
            if (w <= 0.0) continue;

            double cx, cy;
            histo2d_bin_center(h, ix, iy, &cx, &cy);
            (void)cx;

            sum_w += w;
            sum_wy += w * cy;
        }

        if (sum_w <= 0.0) {
            prof_w[ix] = 0.0;
            prof_w2[ix] = 0.0;
            continue;
        }

        double mean_y = sum_wy / sum_w;
        double sum_w_dy2 = 0.0;
        double sum_w2 = 0.0;

        for (uint32_t iy = 0; iy < ny; ++iy) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            double w = h->bins[idx];
            if (w <= 0.0) continue;

            double cx, cy;
            histo2d_bin_center(h, ix, iy, &cx, &cy);
            (void)cx;

            double dy = cy - mean_y;
            sum_w_dy2 += w * dy * dy;
            sum_w2 += (h->sum_w2 ? h->sum_w2[idx] : (w * w));
        }

        double var_y = sum_w_dy2 / sum_w;
        double n_eff = (sum_w2 > 0.0) ? ((sum_w * sum_w) / sum_w2) : sum_w;
        double sem = (n_eff > 1.0) ? sqrt(var_y / n_eff) : sqrt(var_y);

        prof_w[ix] = mean_y;
        prof_w2[ix] = sem * sem;
    }

    histo_set_raw_bin_contents(h1, prof_w, prof_w2);
    free(prof_w);
    free(prof_w2);

    *out_profile_1d = h1;
    return HISTO_OK;
}

histo_status_t histo2d_profile_y(const histo2d_t *h, histo_t **out_profile_1d) {
    if (!h || !out_profile_1d) return HISTO_ERR_INVALID_ARG;

    histo_t *h1 = NULL;
    if (h->y_axis.bin_type == HISTO_BIN_UNIFORM) {
        h1 = histo_create_uniform(h->y_axis.nbins, h->y_axis.min, h->y_axis.max, HISTO_FLAG_TRACK_SUMW2);
    } else {
        h1 = histo_create_variable(h->y_axis.nbins, h->y_axis.bin_edges, HISTO_FLAG_TRACK_SUMW2);
    }
    if (!h1) return HISTO_ERR_NOMEM;

    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;

    double *prof_w = (double *)malloc(ny * sizeof(double));
    double *prof_w2 = (double *)malloc(ny * sizeof(double));
    if (!prof_w || !prof_w2) {
        free(prof_w);
        free(prof_w2);
        histo_destroy(h1);
        return HISTO_ERR_NOMEM;
    }

    for (uint32_t iy = 0; iy < ny; ++iy) {
        double sum_w = 0.0;
        double sum_wx = 0.0;

        for (uint32_t ix = 0; ix < nx; ++ix) {
            double w = h->bins[histo2d_linear_index(ix, iy, ny)];
            if (w <= 0.0) continue;

            double cx, cy;
            histo2d_bin_center(h, ix, iy, &cx, &cy);
            (void)cy;

            sum_w += w;
            sum_wx += w * cx;
        }

        if (sum_w <= 0.0) {
            prof_w[iy] = 0.0;
            prof_w2[iy] = 0.0;
            continue;
        }

        double mean_x = sum_wx / sum_w;
        double sum_w_dx2 = 0.0;
        double sum_w2 = 0.0;

        for (uint32_t ix = 0; ix < nx; ++ix) {
            size_t idx = histo2d_linear_index(ix, iy, ny);
            double w = h->bins[idx];
            if (w <= 0.0) continue;

            double cx, cy;
            histo2d_bin_center(h, ix, iy, &cx, &cy);
            (void)cy;

            double dx = cx - mean_x;
            sum_w_dx2 += w * dx * dx;
            sum_w2 += (h->sum_w2 ? h->sum_w2[idx] : (w * w));
        }

        double var_x = sum_w_dx2 / sum_w;
        double n_eff = (sum_w2 > 0.0) ? ((sum_w * sum_w) / sum_w2) : sum_w;
        double sem = (n_eff > 1.0) ? sqrt(var_x / n_eff) : sqrt(var_x);

        prof_w[iy] = mean_x;
        prof_w2[iy] = sem * sem;
    }

    histo_set_raw_bin_contents(h1, prof_w, prof_w2);
    free(prof_w);
    free(prof_w2);

    *out_profile_1d = h1;
    return HISTO_OK;
}



/* -------------------------------------------------------------------------
 * Transformations & Arithmetic
 * ------------------------------------------------------------------------- */

histo_status_t histo2d_scale(histo2d_t *h, double factor) {
    if (!h) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(factor)) return HISTO_ERR_NON_FINITE;

    size_t total_cells = (size_t)h->x_axis.nbins * (size_t)h->y_axis.nbins;
    double f2 = factor * factor;

    for (size_t i = 0; i < total_cells; ++i) {
        h->bins[i] *= factor;
        if (h->sum_w2) {
            h->sum_w2[i] *= f2;
        }
    }

    h->total_weight *= factor;
    h->total_sum_w2 *= f2;

    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        h->guards[r].weight *= factor;
        h->guards[r].sum_w2 *= f2;
    }

    h->stats_M2_x *= factor;
    h->stats_M2_y *= factor;
    h->stats_C_xy *= factor;

    return HISTO_OK;
}

histo_status_t histo2d_normalize(histo2d_t *h, double target_integral) {
    if (!h) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(target_integral) || target_integral <= 0.0) {
        return HISTO_ERR_INVALID_ARG;
    }
    if (h->total_weight <= 0.0) {
        return HISTO_ERR_EMPTY;
    }

    double factor = target_integral / h->total_weight;
    return histo2d_scale(h, factor);
}

histo_status_t histo2d_rebin(const histo2d_t *src, uint32_t factor_x, uint32_t factor_y,
                             histo2d_t **out_rebinned)
{
    if (!src || !out_rebinned || factor_x == 0 || factor_y == 0) {
        return HISTO_ERR_INVALID_ARG;
    }

    uint32_t nx = src->x_axis.nbins;
    uint32_t ny = src->y_axis.nbins;

    if (nx % factor_x != 0 || ny % factor_y != 0) {
        return HISTO_ERR_INVALID_ARG;
    }

    uint32_t new_nx = nx / factor_x;
    uint32_t new_ny = ny / factor_y;

    histo2d_axis_t new_x_axis, new_y_axis;
    double *new_xedges = NULL;
    double *new_yedges = NULL;

    if (src->x_axis.bin_type == HISTO_BIN_UNIFORM) {
        new_x_axis.type = HISTO_BIN_UNIFORM;
        new_x_axis.nbins = new_nx;
        new_x_axis.min = src->x_axis.min;
        new_x_axis.max = src->x_axis.max;
        new_x_axis.edges = NULL;
    } else {
        new_xedges = (double*)malloc((new_nx + 1) * sizeof(double));
        if (!new_xedges) return HISTO_ERR_NOMEM;
        for (uint32_t i = 0; i <= new_nx; ++i) {
            new_xedges[i] = src->x_axis.bin_edges[i * factor_x];
        }
        new_x_axis.type = HISTO_BIN_VARIABLE;
        new_x_axis.nbins = new_nx;
        new_x_axis.min = new_xedges[0];
        new_x_axis.max = new_xedges[new_nx];
        new_x_axis.edges = new_xedges;
    }

    if (src->y_axis.bin_type == HISTO_BIN_UNIFORM) {
        new_y_axis.type = HISTO_BIN_UNIFORM;
        new_y_axis.nbins = new_ny;
        new_y_axis.min = src->y_axis.min;
        new_y_axis.max = src->y_axis.max;
        new_y_axis.edges = NULL;
    } else {
        new_yedges = (double*)malloc((new_ny + 1) * sizeof(double));
        if (!new_yedges) {
            free(new_xedges);
            return HISTO_ERR_NOMEM;
        }
        for (uint32_t j = 0; j <= new_ny; ++j) {
            new_yedges[j] = src->y_axis.bin_edges[j * factor_y];
        }
        new_y_axis.type = HISTO_BIN_VARIABLE;
        new_y_axis.nbins = new_ny;
        new_y_axis.min = new_yedges[0];
        new_y_axis.max = new_yedges[new_ny];
        new_y_axis.edges = new_yedges;
    }

    histo2d_t *dst = histo2d_create(&new_x_axis, &new_y_axis, src->flags);
    free(new_xedges);
    free(new_yedges);

    if (!dst) return HISTO_ERR_NOMEM;

    for (uint32_t ix = 0; ix < new_nx; ++ix) {
        for (uint32_t iy = 0; iy < new_ny; ++iy) {
            double sum_w = 0.0;
            double sum_w2 = 0.0;

            for (uint32_t fx = 0; fx < factor_x; ++fx) {
                for (uint32_t fy = 0; fy < factor_y; ++fy) {
                    size_t src_idx = histo2d_linear_index(ix * factor_x + fx, iy * factor_y + fy, ny);
                    sum_w += src->bins[src_idx];
                    if (src->sum_w2) sum_w2 += src->sum_w2[src_idx];
                }
            }

            size_t dst_idx = histo2d_linear_index(ix, iy, new_ny);
            dst->bins[dst_idx] = sum_w;
            if (dst->sum_w2) dst->sum_w2[dst_idx] = sum_w2;
        }
    }

    dst->total_weight = src->total_weight;
    dst->total_sum_w2 = src->total_sum_w2;
    dst->n_fills = src->n_fills;
    dst->n_nan = src->n_nan;
    memcpy(dst->guards, src->guards, sizeof(src->guards));

    dst->stats_min_x = src->stats_min_x;
    dst->stats_max_x = src->stats_max_x;
    dst->stats_min_y = src->stats_min_y;
    dst->stats_max_y = src->stats_max_y;
    dst->stats_mean_x = src->stats_mean_x;
    dst->stats_mean_y = src->stats_mean_y;
    dst->stats_M2_x = src->stats_M2_x;
    dst->stats_M2_y = src->stats_M2_y;
    dst->stats_C_xy = src->stats_C_xy;

    *out_rebinned = dst;
    return HISTO_OK;
}

static bool histo2d_compatible_axes(const histo2d_t *a, const histo2d_t *b) {
    if (!a || !b) return false;
    if (a->x_axis.nbins != b->x_axis.nbins || a->y_axis.nbins != b->y_axis.nbins) return false;
    if (a->x_axis.bin_type != b->x_axis.bin_type || a->y_axis.bin_type != b->y_axis.bin_type) return false;
    if (fabs(a->x_axis.min - b->x_axis.min) > 1e-12 || fabs(a->x_axis.max - b->x_axis.max) > 1e-12) return false;
    if (fabs(a->y_axis.min - b->y_axis.min) > 1e-12 || fabs(a->y_axis.max - b->y_axis.max) > 1e-12) return false;

    if (a->x_axis.bin_type == HISTO_BIN_VARIABLE) {
        for (uint32_t i = 0; i <= a->x_axis.nbins; ++i) {
            if (fabs(a->x_axis.bin_edges[i] - b->x_axis.bin_edges[i]) > 1e-12) return false;
        }
    }
    if (a->y_axis.bin_type == HISTO_BIN_VARIABLE) {
        for (uint32_t j = 0; j <= a->y_axis.nbins; ++j) {
            if (fabs(a->y_axis.bin_edges[j] - b->y_axis.bin_edges[j]) > 1e-12) return false;
        }
    }

    return true;
}

histo_status_t histo2d_add(histo2d_t *dst, const histo2d_t *src, double scale) {
    if (!dst || !src) return HISTO_ERR_INVALID_ARG;
    if (!histo2d_compatible_axes(dst, src)) return HISTO_ERR_INCOMPATIBLE;
    if (!isfinite(scale)) return HISTO_ERR_NON_FINITE;

    size_t total_cells = (size_t)dst->x_axis.nbins * (size_t)dst->y_axis.nbins;
    double scale2 = scale * scale;

    for (size_t i = 0; i < total_cells; ++i) {
        dst->bins[i] += scale * src->bins[i];
        if (dst->sum_w2) {
            double src_w2 = src->sum_w2 ? src->sum_w2[i] : (src->bins[i] * src->bins[i]);
            dst->sum_w2[i] += scale2 * src_w2;
        }
    }

    dst->total_weight += scale * src->total_weight;
    dst->total_sum_w2 += scale2 * src->total_sum_w2;
    dst->n_fills += src->n_fills;
    dst->n_nan += src->n_nan;

    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        dst->guards[r].weight += scale * src->guards[r].weight;
        dst->guards[r].sum_w2 += scale2 * src->guards[r].sum_w2;
        dst->guards[r].count += src->guards[r].count;
    }

    return HISTO_OK;
}

histo_status_t histo2d_subtract(histo2d_t *dst, const histo2d_t *src) {
    return histo2d_add(dst, src, -1.0);
}

histo_status_t histo2d_multiply(histo2d_t *dst, const histo2d_t *src) {
    if (!dst || !src) return HISTO_ERR_INVALID_ARG;
    if (!histo2d_compatible_axes(dst, src)) return HISTO_ERR_INCOMPATIBLE;

    size_t total_cells = (size_t)dst->x_axis.nbins * (size_t)dst->y_axis.nbins;
    double new_total_weight = 0.0;
    double new_total_sum_w2 = 0.0;

    for (size_t i = 0; i < total_cells; ++i) {
        double a = dst->bins[i];
        double b = src->bins[i];
        double prod = a * b;

        if (dst->sum_w2) {
            double var_a = dst->sum_w2[i];
            double var_b = src->sum_w2 ? src->sum_w2[i] : (b * b);
            /* Error propagation for multiplication: sigma^2(AB) = b^2 sigma_a^2 + a^2 sigma_b^2 */
            dst->sum_w2[i] = b * b * var_a + a * a * var_b;
            new_total_sum_w2 += dst->sum_w2[i];
        }

        dst->bins[i] = prod;
        new_total_weight += prod;
    }

    dst->total_weight = new_total_weight;
    dst->total_sum_w2 = new_total_sum_w2;
    return HISTO_OK;
}

histo_status_t histo2d_divide(histo2d_t *dst, const histo2d_t *src) {
    if (!dst || !src) return HISTO_ERR_INVALID_ARG;
    if (!histo2d_compatible_axes(dst, src)) return HISTO_ERR_INCOMPATIBLE;

    size_t total_cells = (size_t)dst->x_axis.nbins * (size_t)dst->y_axis.nbins;
    double new_total_weight = 0.0;
    double new_total_sum_w2 = 0.0;

    for (size_t i = 0; i < total_cells; ++i) {
        double a = dst->bins[i];
        double b = src->bins[i];

        if (fabs(b) <= 1e-15) {
            dst->bins[i] = 0.0;
            if (dst->sum_w2) dst->sum_w2[i] = 0.0;
            continue;
        }

        double quot = a / b;
        if (dst->sum_w2) {
            double var_a = dst->sum_w2[i];
            double var_b = src->sum_w2 ? src->sum_w2[i] : (b * b);
            /* Error propagation for division: sigma^2(A/B) = (var_a + quot^2 * var_b) / b^2 */
            dst->sum_w2[i] = (var_a + quot * quot * var_b) / (b * b);
            new_total_sum_w2 += dst->sum_w2[i];
        }

        dst->bins[i] = quot;
        new_total_weight += quot;
    }

    dst->total_weight = new_total_weight;
    dst->total_sum_w2 = new_total_sum_w2;
    return HISTO_OK;
}
