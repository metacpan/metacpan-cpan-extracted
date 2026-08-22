/*
 * AVX-512 vectorized batch binning implementations for uniform histograms.
 */

#include "simd.h"
#include "internal.h"
#ifdef LIBHISTO_ENABLE_AVX512
#include <immintrin.h>
#include <math.h>

bool histo_fill_uniform_avx512(histo_t *h, const double *x, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double min_val = h->min;
    double max_val = h->max;
    double inv_binsize = h->inv_binsize > 0.0 ? h->inv_binsize : 1.0 / h->binsize;
    uint32_t nbins = h->nbins;
    
    __m512d v_min = _mm512_set1_pd(min_val);
    __m512d v_max = _mm512_set1_pd(max_val);
    __m512d v_inv_binsize = _mm512_set1_pd(inv_binsize);
    __m512d v_nbins_minus_1 = _mm512_set1_pd((double)(nbins - 1));
    __m512d v_zero = _mm512_setzero_pd();

    for (; i + 7 < n; i += 8) {
        __m512d v_x = _mm512_loadu_pd(&x[i]);
        
        __mmask8 mask_under = _mm512_cmp_pd_mask(v_x, v_min, _CMP_LT_OQ);
        __mmask8 mask_over = _mm512_cmp_pd_mask(v_x, v_max, _CMP_GE_OQ);
        __mmask8 mask_nan = _mm512_cmp_pd_mask(v_x, v_x, _CMP_NEQ_UQ); // true if NaN
        
        __mmask8 bad_mask = mask_under | mask_over | mask_nan;
        
        if (bad_mask != 0) {
            for (size_t j = 0; j < 8; ++j) {
                double val = x[i + j];
                if (isnan(val)) { h->n_nan++; had_non_finite = true; }
                else if (val < h->min) {
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
            __m512d v_idx = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_x, v_min), v_inv_binsize));
            v_idx = _mm512_max_pd(v_idx, v_zero);
            v_idx = _mm512_min_pd(v_idx, v_nbins_minus_1);
            
            double idx_arr[8];
            _mm512_storeu_pd(idx_arr, v_idx);
            
            for(int j=0; j<8; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                h->bins[idx] += 1.0;
                h->total_weight += 1.0;
                if (h->sum_w2) h->total_sum_w2 += 1.0;
                h->n_fills++;
            }
        }
    }
    
    // tail
    for (; i < n; ++i) {
        double val = x[i];
        if (isnan(val)) { h->n_nan++; had_non_finite = true; }
        else if (val < h->min) {
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

bool histo_fill_uniform_w2_avx512(histo_t *h, const double *x, const double *weights, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double min_val = h->min;
    double max_val = h->max;
    double inv_binsize = h->inv_binsize > 0.0 ? h->inv_binsize : 1.0 / h->binsize;
    uint32_t nbins = h->nbins;
    bool has_w2 = (h->sum_w2 != NULL);

    __m512d v_min = _mm512_set1_pd(min_val);
    __m512d v_max = _mm512_set1_pd(max_val);
    __m512d v_inv_binsize = _mm512_set1_pd(inv_binsize);
    __m512d v_nbins_minus_1 = _mm512_set1_pd((double)(nbins - 1));
    __m512d v_zero = _mm512_setzero_pd();

    for (; i + 7 < n; i += 8) {
        __m512d v_x = _mm512_loadu_pd(&x[i]);
        __m512d v_w = _mm512_loadu_pd(&weights[i]);

        __mmask8 mask_under = _mm512_cmp_pd_mask(v_x, v_min, _CMP_LT_OQ);
        __mmask8 mask_over  = _mm512_cmp_pd_mask(v_x, v_max, _CMP_GE_OQ);
        __mmask8 mask_nan_x = _mm512_cmp_pd_mask(v_x, v_x, _CMP_NEQ_UQ);

        __m512d v_w_sub     = _mm512_sub_pd(v_w, v_w);
        __mmask8 mask_bad_w = _mm512_cmp_pd_mask(v_w_sub, v_w_sub, _CMP_NEQ_UQ);

        __mmask8 bad_mask = mask_under | mask_over | mask_nan_x | mask_bad_w;

        if (bad_mask != 0) {
            for (size_t j = 0; j < 8; ++j) {
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
            __m512d v_w2 = _mm512_mul_pd(v_w, v_w);
            __m512d v_idx = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_x, v_min), v_inv_binsize));
            v_idx = _mm512_max_pd(v_idx, v_zero);
            v_idx = _mm512_min_pd(v_idx, v_nbins_minus_1);

            double idx_arr[8];
            double w_arr[8];
            double w2_arr[8];
            _mm512_storeu_pd(idx_arr, v_idx);
            _mm512_storeu_pd(w_arr, v_w);
            _mm512_storeu_pd(w2_arr, v_w2);

            double sum_w = 0.0;
            double sum_w2 = 0.0;
            for (int j = 0; j < 8; ++j) {
                int64_t idx = (int64_t)idx_arr[j];
                double val = x[i + j];
                if (idx + 1 < (int64_t)h->nbins && val >= h->min + (double)(idx + 1) * h->binsize) idx++;
                if (idx > 0 && val < h->min + (double)idx * h->binsize) idx--;
                double w = w_arr[j];
                double w2 = w2_arr[j];
                h->bins[idx] += w;
                if (has_w2) h->sum_w2[idx] += w2;
                sum_w += w;
                sum_w2 += w2;
            }
            h->total_weight += sum_w;
            if (has_w2) h->total_sum_w2 += sum_w2;
            h->n_fills += 8;
        }
    }

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

#include "histo/histo2d.h"
#include "internal_2d.h"

#ifdef LIBHISTO_ENABLE_AVX512
bool histo2d_fill_uniform_avx512(histo2d_t *h, const double *x, const double *y, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double inv_dx = h->x_axis.inv_binsize > 0.0 ? h->x_axis.inv_binsize : 1.0 / h->x_axis.binsize;
    double inv_dy = h->y_axis.inv_binsize > 0.0 ? h->y_axis.inv_binsize : 1.0 / h->y_axis.binsize;
    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;
    double min_x = h->x_axis.min;
    double max_x = h->x_axis.max;
    double min_y = h->y_axis.min;
    double max_y = h->y_axis.max;

    __m512d v_min_x = _mm512_set1_pd(min_x);
    __m512d v_max_x = _mm512_set1_pd(max_x);
    __m512d v_inv_dx = _mm512_set1_pd(inv_dx);
    __m512d v_nx_minus_1 = _mm512_set1_pd((double)(nx - 1));

    __m512d v_min_y = _mm512_set1_pd(min_y);
    __m512d v_max_y = _mm512_set1_pd(max_y);
    __m512d v_inv_dy = _mm512_set1_pd(inv_dy);
    __m512d v_ny_minus_1 = _mm512_set1_pd((double)(ny - 1));

    __m512d v_zero = _mm512_setzero_pd();

    for (; i + 7 < n; i += 8) {
        __m512d v_x = _mm512_loadu_pd(&x[i]);
        __m512d v_y = _mm512_loadu_pd(&y[i]);

        __mmask8 mask_under_x = _mm512_cmp_pd_mask(v_x, v_min_x, _CMP_LT_OQ);
        __mmask8 mask_over_x = _mm512_cmp_pd_mask(v_x, v_max_x, _CMP_GE_OQ);
        __mmask8 mask_nan_x = _mm512_cmp_pd_mask(v_x, v_x, _CMP_NEQ_UQ);

        __mmask8 mask_under_y = _mm512_cmp_pd_mask(v_y, v_min_y, _CMP_LT_OQ);
        __mmask8 mask_over_y = _mm512_cmp_pd_mask(v_y, v_max_y, _CMP_GE_OQ);
        __mmask8 mask_nan_y = _mm512_cmp_pd_mask(v_y, v_y, _CMP_NEQ_UQ);

        __mmask8 bad_mask = mask_under_x | mask_over_x | mask_nan_x | mask_under_y | mask_over_y | mask_nan_y;

        if (bad_mask != 0) {
            for (size_t j = 0; j < 8; ++j) {
                if (histo2d_fill(h, x[i + j], y[i + j]) == HISTO_ERR_NON_FINITE) {
                    had_non_finite = true;
                }
            }
        } else {
            __m512d v_idx_x = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_x, v_min_x), v_inv_dx));
            v_idx_x = _mm512_max_pd(v_idx_x, v_zero);
            v_idx_x = _mm512_min_pd(v_idx_x, v_nx_minus_1);

            __m512d v_idx_y = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_y, v_min_y), v_inv_dy));
            v_idx_y = _mm512_max_pd(v_idx_y, v_zero);
            v_idx_y = _mm512_min_pd(v_idx_y, v_ny_minus_1);

            double idx_arr_x[8];
            double idx_arr_y[8];
            _mm512_storeu_pd(idx_arr_x, v_idx_x);
            _mm512_storeu_pd(idx_arr_y, v_idx_y);

            for(int j=0; j<8; ++j) {
                int64_t ix = (int64_t)idx_arr_x[j];
                int64_t iy = (int64_t)idx_arr_y[j];
                double vx = x[i + j];
                double vy = y[i + j];

                if (ix + 1 < (int64_t)nx && vx >= min_x + (double)(ix + 1) * h->x_axis.binsize) ix++;
                if (ix > 0 && vx < min_x + (double)ix * h->x_axis.binsize) ix--;
                
                if (iy + 1 < (int64_t)ny && vy >= min_y + (double)(iy + 1) * h->y_axis.binsize) iy++;
                if (iy > 0 && vy < min_y + (double)iy * h->y_axis.binsize) iy--;

                size_t idx = histo2d_linear_index((uint32_t)ix, (uint32_t)iy, ny);
                h->bins[idx] += 1.0;
                if (h->sum_w2) h->sum_w2[idx] += 1.0;
                h->total_weight += 1.0;
                h->total_sum_w2 += 1.0;
                h->n_fills++;
                
            }
            h->guards[HISTO2D_REGION_CENTER].weight += 8.0;
            h->guards[HISTO2D_REGION_CENTER].sum_w2 += 8.0;
            h->guards[HISTO2D_REGION_CENTER].count += 8;
        }
    }
    for (; i < n; ++i) {
        if (histo2d_fill(h, x[i], y[i]) == HISTO_ERR_NON_FINITE) {
            had_non_finite = true;
        }
    }
    return had_non_finite;
}

bool histo2d_fill_uniform_w2_avx512(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n) {
    size_t i = 0;
    bool had_non_finite = false;
    double inv_dx = h->x_axis.inv_binsize > 0.0 ? h->x_axis.inv_binsize : 1.0 / h->x_axis.binsize;
    double inv_dy = h->y_axis.inv_binsize > 0.0 ? h->y_axis.inv_binsize : 1.0 / h->y_axis.binsize;
    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;
    double min_x = h->x_axis.min;
    double max_x = h->x_axis.max;
    double min_y = h->y_axis.min;
    double max_y = h->y_axis.max;
    bool has_w2 = (h->sum_w2 != NULL);

    __m512d v_min_x = _mm512_set1_pd(min_x);
    __m512d v_max_x = _mm512_set1_pd(max_x);
    __m512d v_inv_dx = _mm512_set1_pd(inv_dx);
    __m512d v_nx_minus_1 = _mm512_set1_pd((double)(nx - 1));

    __m512d v_min_y = _mm512_set1_pd(min_y);
    __m512d v_max_y = _mm512_set1_pd(max_y);
    __m512d v_inv_dy = _mm512_set1_pd(inv_dy);
    __m512d v_ny_minus_1 = _mm512_set1_pd((double)(ny - 1));

    __m512d v_zero = _mm512_setzero_pd();

    for (; i + 7 < n; i += 8) {
        __m512d v_x = _mm512_loadu_pd(&x[i]);
        __m512d v_y = _mm512_loadu_pd(&y[i]);
        __m512d v_w = _mm512_loadu_pd(&weights[i]);

        __mmask8 mask_under_x = _mm512_cmp_pd_mask(v_x, v_min_x, _CMP_LT_OQ);
        __mmask8 mask_over_x  = _mm512_cmp_pd_mask(v_x, v_max_x, _CMP_GE_OQ);
        __mmask8 mask_nan_x   = _mm512_cmp_pd_mask(v_x, v_x, _CMP_NEQ_UQ);

        __mmask8 mask_under_y = _mm512_cmp_pd_mask(v_y, v_min_y, _CMP_LT_OQ);
        __mmask8 mask_over_y  = _mm512_cmp_pd_mask(v_y, v_max_y, _CMP_GE_OQ);
        __mmask8 mask_nan_y   = _mm512_cmp_pd_mask(v_y, v_y, _CMP_NEQ_UQ);

        __m512d v_w_sub       = _mm512_sub_pd(v_w, v_w);
        __mmask8 mask_bad_w   = _mm512_cmp_pd_mask(v_w_sub, v_w_sub, _CMP_NEQ_UQ);

        __mmask8 bad_mask = mask_under_x | mask_over_x | mask_nan_x |
                            mask_under_y | mask_over_y | mask_nan_y |
                            mask_bad_w;

        if (bad_mask != 0) {
            for (size_t j = 0; j < 8; ++j) {
                if (histo2d_fill_w(h, x[i + j], y[i + j], weights[i + j]) == HISTO_ERR_NON_FINITE) {
                    had_non_finite = true;
                }
            }
        } else {
            __m512d v_w2 = _mm512_mul_pd(v_w, v_w);

            __m512d v_idx_x = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_x, v_min_x), v_inv_dx));
            v_idx_x = _mm512_max_pd(v_idx_x, v_zero);
            v_idx_x = _mm512_min_pd(v_idx_x, v_nx_minus_1);

            __m512d v_idx_y = _mm512_floor_pd(_mm512_mul_pd(_mm512_sub_pd(v_y, v_min_y), v_inv_dy));
            v_idx_y = _mm512_max_pd(v_idx_y, v_zero);
            v_idx_y = _mm512_min_pd(v_idx_y, v_ny_minus_1);

            double idx_arr_x[8];
            double idx_arr_y[8];
            double w_arr[8];
            double w2_arr[8];
            _mm512_storeu_pd(idx_arr_x, v_idx_x);
            _mm512_storeu_pd(idx_arr_y, v_idx_y);
            _mm512_storeu_pd(w_arr, v_w);
            _mm512_storeu_pd(w2_arr, v_w2);

            double sum_w = 0.0;
            double sum_w2 = 0.0;

            for (int j = 0; j < 8; ++j) {
                int64_t ix = (int64_t)idx_arr_x[j];
                int64_t iy = (int64_t)idx_arr_y[j];
                double vx = x[i + j];
                double vy = y[i + j];

                if (ix + 1 < (int64_t)nx && vx >= min_x + (double)(ix + 1) * h->x_axis.binsize) ix++;
                if (ix > 0 && vx < min_x + (double)ix * h->x_axis.binsize) ix--;

                if (iy + 1 < (int64_t)ny && vy >= min_y + (double)(iy + 1) * h->y_axis.binsize) iy++;
                if (iy > 0 && vy < min_y + (double)iy * h->y_axis.binsize) iy--;

                size_t idx = histo2d_linear_index((uint32_t)ix, (uint32_t)iy, ny);
                double w = w_arr[j];
                double w2 = w2_arr[j];

                h->bins[idx] += w;
                if (has_w2) {
                    h->sum_w2[idx] += w2;
                }
                sum_w += w;
                sum_w2 += w2;
            }
            h->total_weight += sum_w;
            h->total_sum_w2 += sum_w2;
            h->n_fills += 8;
            h->guards[HISTO2D_REGION_CENTER].weight += sum_w;
            h->guards[HISTO2D_REGION_CENTER].sum_w2 += sum_w2;
            h->guards[HISTO2D_REGION_CENTER].count += 8;
        }
    }
    for (; i < n; ++i) {
        if (histo2d_fill_w(h, x[i], y[i], weights[i]) == HISTO_ERR_NON_FINITE) {
            had_non_finite = true;
        }
    }
    return had_non_finite;
}
#endif
#endif
