#include "simd.h"
#include "internal.h"
#include "internal_2d.h"
#include "simd_neon_bridge.h"
#include <math.h>

#ifdef LIBHISTO_ENABLE_NEON

bool histo_fill_uniform_neon(histo_t *h, const double *x, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double min_val = h->min;
    double max_val = h->max;
    double inv_binsize = h->inv_binsize > 0.0 ? h->inv_binsize : 1.0 / h->binsize;
    uint32_t nbins = h->nbins;

    float64x2_t v_min = vdupq_n_f64(min_val);
    float64x2_t v_max = vdupq_n_f64(max_val);
    float64x2_t v_inv_binsize = vdupq_n_f64(inv_binsize);
    float64x2_t v_nbins_minus_1 = vdupq_n_f64((double)(nbins - 1));
    float64x2_t v_zero = vdupq_n_f64(0.0);

    /* Process 4 doubles per loop iteration (2x 128-bit NEON vectors) */
    for (; i + 3 < n; i += 4) {
        float64x2_t v_x0 = vld1q_f64(&x[i]);
        float64x2_t v_x1 = vld1q_f64(&x[i + 2]);

        /* Out-of-bounds checks */
        uint64x2_t mask_under0 = vcltq_f64(v_x0, v_min);
        uint64x2_t mask_over0  = vcgeq_f64(v_x0, v_max);
        uint64x2_t mask_nan0   = vmvnq_u64(vceqq_f64(v_x0, v_x0));

        uint64x2_t mask_under1 = vcltq_f64(v_x1, v_min);
        uint64x2_t mask_over1  = vcgeq_f64(v_x1, v_max);
        uint64x2_t mask_nan1   = vmvnq_u64(vceqq_f64(v_x1, v_x1));

        uint64x2_t bad0 = vorrq_u64(vorrq_u64(mask_under0, mask_over0), mask_nan0);
        uint64x2_t bad1 = vorrq_u64(vorrq_u64(mask_under1, mask_over1), mask_nan1);
        uint64x2_t bad_combined = vorrq_u64(bad0, bad1);

        uint64_t bad_any = vgetq_lane_u64(bad_combined, 0) | vgetq_lane_u64(bad_combined, 1);

        if (bad_any != 0) {
            /* Fallback to scalar for these 4 elements */
            for (size_t j = 0; j < 4; ++j) {
                double val = x[i + j];
                if (isnan(val)) {
                    h->n_nan++;
                    had_non_finite = true;
                } else if (val < h->min) {
                    h->underflow_weight += 1.0;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += 1.0;
                    h->n_overflow++;
                } else {
                    int64_t idx = (int64_t)((val - h->min) * inv_binsize);
                    if (idx < 0) idx = 0;
                    else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
                    if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                    if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                    h->bins[idx] += 1.0;
                    h->total_weight += 1.0;
                    h->n_fills++;
                }
            }
        } else {
            /* All 4 elements in range and finite */
            float64x2_t v_idx0 = vrndmq_f64(vmulq_f64(vsubq_f64(v_x0, v_min), v_inv_binsize));
            v_idx0 = vmaxq_f64(v_idx0, v_zero);
            v_idx0 = vminq_f64(v_idx0, v_nbins_minus_1);

            float64x2_t v_idx1 = vrndmq_f64(vmulq_f64(vsubq_f64(v_x1, v_min), v_inv_binsize));
            v_idx1 = vmaxq_f64(v_idx1, v_zero);
            v_idx1 = vminq_f64(v_idx1, v_nbins_minus_1);

            double idx_arr[4];
            vst1q_f64(&idx_arr[0], v_idx0);
            vst1q_f64(&idx_arr[2], v_idx1);

            for (size_t j = 0; j < 4; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                h->bins[idx] += 1.0;
                h->total_weight += 1.0;
                h->n_fills++;
            }
        }
    }

    /* Process 2 doubles if remaining */
    for (; i + 1 < n; i += 2) {
        float64x2_t v_x = vld1q_f64(&x[i]);
        uint64x2_t mask_under = vcltq_f64(v_x, v_min);
        uint64x2_t mask_over  = vcgeq_f64(v_x, v_max);
        uint64x2_t mask_nan   = vmvnq_u64(vceqq_f64(v_x, v_x));
        uint64x2_t bad = vorrq_u64(vorrq_u64(mask_under, mask_over), mask_nan);
        uint64_t bad_any = vgetq_lane_u64(bad, 0) | vgetq_lane_u64(bad, 1);

        if (bad_any != 0) {
            for (size_t j = 0; j < 2; ++j) {
                double val = x[i + j];
                if (isnan(val)) {
                    h->n_nan++;
                    had_non_finite = true;
                } else if (val < h->min) {
                    h->underflow_weight += 1.0;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += 1.0;
                    h->n_overflow++;
                } else {
                    int64_t idx = (int64_t)((val - h->min) * inv_binsize);
                    if (idx < 0) idx = 0;
                    else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
                    if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                    if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                    h->bins[idx] += 1.0;
                    h->total_weight += 1.0;
                    h->n_fills++;
                }
            }
        } else {
            float64x2_t v_idx = vrndmq_f64(vmulq_f64(vsubq_f64(v_x, v_min), v_inv_binsize));
            v_idx = vmaxq_f64(v_idx, v_zero);
            v_idx = vminq_f64(v_idx, v_nbins_minus_1);

            double idx_arr[2];
            vst1q_f64(idx_arr, v_idx);

            for (size_t j = 0; j < 2; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                h->bins[idx] += 1.0;
                h->total_weight += 1.0;
                h->n_fills++;
            }
        }
    }

    /* Scalar remainder tail */
    for (; i < n; ++i) {
        double val = x[i];
        if (isnan(val)) {
            h->n_nan++;
            had_non_finite = true;
        } else if (val < h->min) {
            h->underflow_weight += 1.0;
            h->n_underflow++;
        } else if (val >= h->max) {
            h->overflow_weight += 1.0;
            h->n_overflow++;
        } else {
            int64_t idx = (int64_t)((val - h->min) * inv_binsize);
            if (idx < 0) idx = 0;
            else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
            if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
            if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
            h->bins[idx] += 1.0;
            h->total_weight += 1.0;
            h->n_fills++;
        }
    }

    return had_non_finite;
}

bool histo_fill_uniform_w2_neon(histo_t *h, const double *x, const double *weights, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double min_val = h->min;
    double max_val = h->max;
    double inv_binsize = h->inv_binsize > 0.0 ? h->inv_binsize : 1.0 / h->binsize;
    uint32_t nbins = h->nbins;
    bool has_w2 = (h->sum_w2 != NULL);

    float64x2_t v_min = vdupq_n_f64(min_val);
    float64x2_t v_max = vdupq_n_f64(max_val);
    float64x2_t v_inv_binsize = vdupq_n_f64(inv_binsize);
    float64x2_t v_nbins_minus_1 = vdupq_n_f64((double)(nbins - 1));
    float64x2_t v_zero = vdupq_n_f64(0.0);

    /* Process 4 items per unrolled loop */
    for (; i + 3 < n; i += 4) {
        float64x2_t v_x0 = vld1q_f64(&x[i]);
        float64x2_t v_x1 = vld1q_f64(&x[i + 2]);
        float64x2_t v_w0 = vld1q_f64(&weights[i]);
        float64x2_t v_w1 = vld1q_f64(&weights[i + 2]);

        /* Out-of-bounds / NaN check for x */
        uint64x2_t mask_under0 = vcltq_f64(v_x0, v_min);
        uint64x2_t mask_over0  = vcgeq_f64(v_x0, v_max);
        uint64x2_t mask_nan0   = vmvnq_u64(vceqq_f64(v_x0, v_x0));

        uint64x2_t mask_under1 = vcltq_f64(v_x1, v_min);
        uint64x2_t mask_over1  = vcgeq_f64(v_x1, v_max);
        uint64x2_t mask_nan1   = vmvnq_u64(vceqq_f64(v_x1, v_x1));

        /* Non-finite check for weights (w != w) */
        uint64x2_t mask_wnan0  = vmvnq_u64(vceqq_f64(v_w0, v_w0));
        uint64x2_t mask_wnan1  = vmvnq_u64(vceqq_f64(v_w1, v_w1));

        uint64x2_t bad0 = vorrq_u64(vorrq_u64(vorrq_u64(mask_under0, mask_over0), mask_nan0), mask_wnan0);
        uint64x2_t bad1 = vorrq_u64(vorrq_u64(vorrq_u64(mask_under1, mask_over1), mask_nan1), mask_wnan1);
        uint64x2_t bad_combined = vorrq_u64(bad0, bad1);

        uint64_t bad_any = vgetq_lane_u64(bad_combined, 0) | vgetq_lane_u64(bad_combined, 1);

        if (bad_any != 0 || !isfinite(weights[i]) || !isfinite(weights[i + 1]) || !isfinite(weights[i + 2]) || !isfinite(weights[i + 3])) {
            for (size_t j = 0; j < 4; ++j) {
                double val = x[i + j];
                double w = weights[i + j];
                if (isnan(val) || !isfinite(w)) {
                    h->n_nan++;
                    had_non_finite = true;
                } else if (val < h->min) {
                    h->underflow_weight += w;
                    if (has_w2) h->underflow_sum_w2 += w * w;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += w;
                    if (has_w2) h->overflow_sum_w2 += w * w;
                    h->n_overflow++;
                } else {
                    int64_t idx = (int64_t)((val - h->min) * inv_binsize);
                    if (idx < 0) idx = 0;
                    else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
                    if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                    if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                    h->bins[idx] += w;
                    if (has_w2) h->sum_w2[idx] += w * w;
                    h->total_weight += w;
                    if (has_w2) h->total_sum_w2 += w * w;
                    h->n_fills++;
                }
            }
        } else {
            float64x2_t v_idx0 = vrndmq_f64(vmulq_f64(vsubq_f64(v_x0, v_min), v_inv_binsize));
            v_idx0 = vmaxq_f64(v_idx0, v_zero);
            v_idx0 = vminq_f64(v_idx0, v_nbins_minus_1);

            float64x2_t v_idx1 = vrndmq_f64(vmulq_f64(vsubq_f64(v_x1, v_min), v_inv_binsize));
            v_idx1 = vmaxq_f64(v_idx1, v_zero);
            v_idx1 = vminq_f64(v_idx1, v_nbins_minus_1);

            double idx_arr[4];
            vst1q_f64(&idx_arr[0], v_idx0);
            vst1q_f64(&idx_arr[2], v_idx1);

            for (size_t j = 0; j < 4; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                double w = weights[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                h->bins[idx] += w;
                if (has_w2) h->sum_w2[idx] += w * w;
                h->total_weight += w;
                if (has_w2) h->total_sum_w2 += w * w;
                h->n_fills++;
            }
        }
    }

    /* Process 2 elements */
    for (; i + 1 < n; i += 2) {
        float64x2_t v_x = vld1q_f64(&x[i]);
        float64x2_t v_w = vld1q_f64(&weights[i]);

        uint64x2_t mask_under = vcltq_f64(v_x, v_min);
        uint64x2_t mask_over  = vcgeq_f64(v_x, v_max);
        uint64x2_t mask_nan   = vmvnq_u64(vceqq_f64(v_x, v_x));
        uint64x2_t mask_wnan  = vmvnq_u64(vceqq_f64(v_w, v_w));
        uint64x2_t bad = vorrq_u64(vorrq_u64(vorrq_u64(mask_under, mask_over), mask_nan), mask_wnan);
        uint64_t bad_any = vgetq_lane_u64(bad, 0) | vgetq_lane_u64(bad, 1);

        if (bad_any != 0 || !isfinite(weights[i]) || !isfinite(weights[i + 1])) {
            for (size_t j = 0; j < 2; ++j) {
                double val = x[i + j];
                double w = weights[i + j];
                if (isnan(val) || !isfinite(w)) {
                    h->n_nan++;
                    had_non_finite = true;
                } else if (val < h->min) {
                    h->underflow_weight += w;
                    if (has_w2) h->underflow_sum_w2 += w * w;
                    h->n_underflow++;
                } else if (val >= h->max) {
                    h->overflow_weight += w;
                    if (has_w2) h->overflow_sum_w2 += w * w;
                    h->n_overflow++;
                } else {
                    int64_t idx = (int64_t)((val - h->min) * inv_binsize);
                    if (idx < 0) idx = 0;
                    else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
                    if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                    if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                    h->bins[idx] += w;
                    if (has_w2) h->sum_w2[idx] += w * w;
                    h->total_weight += w;
                    if (has_w2) h->total_sum_w2 += w * w;
                    h->n_fills++;
                }
            }
        } else {
            float64x2_t v_idx = vrndmq_f64(vmulq_f64(vsubq_f64(v_x, v_min), v_inv_binsize));
            v_idx = vmaxq_f64(v_idx, v_zero);
            v_idx = vminq_f64(v_idx, v_nbins_minus_1);

            double idx_arr[2];
            vst1q_f64(idx_arr, v_idx);

            for (size_t j = 0; j < 2; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                double w = weights[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                h->bins[idx] += w;
                if (has_w2) h->sum_w2[idx] += w * w;
                h->total_weight += w;
                if (has_w2) h->total_sum_w2 += w * w;
                h->n_fills++;
            }
        }
    }

    /* Scalar remainder tail */
    for (; i < n; ++i) {
        double val = x[i];
        double w = weights[i];
        if (isnan(val) || !isfinite(w)) {
            h->n_nan++;
            had_non_finite = true;
        } else if (val < h->min) {
            h->underflow_weight += w;
            if (has_w2) h->underflow_sum_w2 += w * w;
            h->n_underflow++;
        } else if (val >= h->max) {
            h->overflow_weight += w;
            if (has_w2) h->overflow_sum_w2 += w * w;
            h->n_overflow++;
        } else {
            int64_t idx = (int64_t)((val - h->min) * inv_binsize);
            if (idx < 0) idx = 0;
            else if ((uint32_t)idx >= h->nbins) idx = h->nbins - 1;
            if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
            if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
            h->bins[idx] += w;
            if (has_w2) h->sum_w2[idx] += w * w;
            h->total_weight += w;
            if (has_w2) h->total_sum_w2 += w * w;
            h->n_fills++;
        }
    }

    return had_non_finite;
}

bool histo2d_fill_uniform_neon(histo2d_t *h, const double *x, const double *y, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double min_x = h->x_axis.min;
    double max_x = h->x_axis.max;
    double inv_dx = h->x_axis.inv_binsize;
    uint32_t nx = h->x_axis.nbins;

    double min_y = h->y_axis.min;
    double max_y = h->y_axis.max;
    double inv_dy = h->y_axis.inv_binsize;
    uint32_t ny = h->y_axis.nbins;

    float64x2_t v_min_x = vdupq_n_f64(min_x);
    float64x2_t v_max_x = vdupq_n_f64(max_x);
    float64x2_t v_inv_dx = vdupq_n_f64(inv_dx);
    float64x2_t v_nx_minus_1 = vdupq_n_f64((double)(nx - 1));

    float64x2_t v_min_y = vdupq_n_f64(min_y);
    float64x2_t v_max_y = vdupq_n_f64(max_y);
    float64x2_t v_inv_dy = vdupq_n_f64(inv_dy);
    float64x2_t v_ny_minus_1 = vdupq_n_f64((double)(ny - 1));

    float64x2_t v_zero = vdupq_n_f64(0.0);

    /* Process 4 coordinate pairs per iteration (2x 128-bit NEON vectors) */
    for (; i + 3 < n; i += 4) {
        float64x2_t v_x0 = vld1q_f64(&x[i]);
        float64x2_t v_x1 = vld1q_f64(&x[i + 2]);
        float64x2_t v_y0 = vld1q_f64(&y[i]);
        float64x2_t v_y1 = vld1q_f64(&y[i + 2]);

        /* Boundary and NaN checks */
        uint64x2_t bad_x0 = vorrq_u64(vorrq_u64(vcltq_f64(v_x0, v_min_x), vcgeq_f64(v_x0, v_max_x)), vmvnq_u64(vceqq_f64(v_x0, v_x0)));
        uint64x2_t bad_x1 = vorrq_u64(vorrq_u64(vcltq_f64(v_x1, v_min_x), vcgeq_f64(v_x1, v_max_x)), vmvnq_u64(vceqq_f64(v_x1, v_x1)));
        uint64x2_t bad_y0 = vorrq_u64(vorrq_u64(vcltq_f64(v_y0, v_min_y), vcgeq_f64(v_y0, v_max_y)), vmvnq_u64(vceqq_f64(v_y0, v_y0)));
        uint64x2_t bad_y1 = vorrq_u64(vorrq_u64(vcltq_f64(v_y1, v_min_y), vcgeq_f64(v_y1, v_max_y)), vmvnq_u64(vceqq_f64(v_y1, v_y1)));

        uint64x2_t bad0 = vorrq_u64(bad_x0, bad_y0);
        uint64x2_t bad1 = vorrq_u64(bad_x1, bad_y1);
        uint64x2_t bad_comb = vorrq_u64(bad0, bad1);

        uint64_t bad_any = vgetq_lane_u64(bad_comb, 0) | vgetq_lane_u64(bad_comb, 1);

        if (bad_any != 0) {
            for (size_t j = 0; j < 4; ++j) {
                if (histo2d_fill(h, x[i + j], y[i + j]) == HISTO_ERR_NON_FINITE) {
                    had_non_finite = true;
                }
            }
        } else {
            float64x2_t v_idx_x0 = vminq_f64(vmaxq_f64(vrndmq_f64(vmulq_f64(vsubq_f64(v_x0, v_min_x), v_inv_dx)), v_zero), v_nx_minus_1);
            float64x2_t v_idx_x1 = vminq_f64(vmaxq_f64(vrndmq_f64(vmulq_f64(vsubq_f64(v_x1, v_min_x), v_inv_dx)), v_zero), v_nx_minus_1);
            float64x2_t v_idx_y0 = vminq_f64(vmaxq_f64(vrndmq_f64(vmulq_f64(vsubq_f64(v_y0, v_min_y), v_inv_dy)), v_zero), v_ny_minus_1);
            float64x2_t v_idx_y1 = vminq_f64(vmaxq_f64(vrndmq_f64(vmulq_f64(vsubq_f64(v_y1, v_min_y), v_inv_dy)), v_zero), v_ny_minus_1);

            double idx_x_arr[4];
            double idx_y_arr[4];
            vst1q_f64(&idx_x_arr[0], v_idx_x0);
            vst1q_f64(&idx_x_arr[2], v_idx_x1);
            vst1q_f64(&idx_y_arr[0], v_idx_y0);
            vst1q_f64(&idx_y_arr[2], v_idx_y1);

            for (size_t j = 0; j < 4; ++j) {
                int64_t ix = (int64_t)idx_x_arr[j];
                int64_t iy = (int64_t)idx_y_arr[j];
                double vx = x[i + j];
                double vy = y[i + j];

                if (ix + 1 < (int64_t)nx && vx >= min_x + (double)(ix + 1) * h->x_axis.binsize) ix++;
                if (ix > 0 && vx < min_x + (double)ix * h->x_axis.binsize) ix--;

                if (iy + 1 < (int64_t)ny && vy >= min_y + (double)(iy + 1) * h->y_axis.binsize) iy++;
                if (iy > 0 && vy < min_y + (double)iy * h->y_axis.binsize) iy--;

                size_t idx = histo2d_linear_index((uint32_t)ix, (uint32_t)iy, ny);
                h->bins[idx] += 1.0;
                h->total_weight += 1.0;
                h->n_fills++;
            }
            h->guards[HISTO2D_REGION_CENTER].weight += 4.0;
            h->guards[HISTO2D_REGION_CENTER].count += 4;
        }
    }

    /* Remainder tail */
    for (; i < n; ++i) {
        if (histo2d_fill(h, x[i], y[i]) == HISTO_ERR_NON_FINITE) {
            had_non_finite = true;
        }
    }
    return had_non_finite;
}

bool histo2d_fill_uniform_w2_neon(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    for (; i < n; ++i) {
        if (histo2d_fill_w(h, x[i], y[i], weights[i]) == HISTO_ERR_NON_FINITE) {
            had_non_finite = true;
        }
    }
    return had_non_finite;
}

#endif /* LIBHISTO_ENABLE_NEON */

