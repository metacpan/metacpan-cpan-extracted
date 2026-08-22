/*
 * Internal declarations for SIMD vectorized batch ingestion routines.
 */

#ifndef HISTO_SIMD_H
#define HISTO_SIMD_H

#include "histo/histo.h"
#include "histo/histo2d.h"
#include <stdbool.h>
#include <stddef.h>

bool histo2d_fill_uniform_avx2(histo2d_t *h, const double *x, const double *y, size_t n);
bool histo2d_fill_uniform_avx512(histo2d_t *h, const double *x, const double *y, size_t n);
bool histo2d_fill_uniform_neon(histo2d_t *h, const double *x, const double *y, size_t n);
bool histo2d_fill_uniform_w2_avx2(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n);
bool histo2d_fill_uniform_w2_avx512(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n);
bool histo2d_fill_uniform_w2_neon(histo2d_t *h, const double *x, const double *y, const double *weights, size_t n);

#ifdef __cplusplus
extern "C" {
#endif

/* Runtime detection */
bool histo_simd_has_avx2(void);
bool histo_simd_has_avx512(void);
bool histo_simd_has_neon(void);

/* Vectorized fill for uniform bins */
bool histo_fill_uniform_avx2(histo_t *h, const double *x, size_t n);
bool histo_fill_uniform_avx512(histo_t *h, const double *x, size_t n);
bool histo_fill_uniform_neon(histo_t *h, const double *x, size_t n);

/* Vectorized fill for uniform bins with weights and w2 */
bool histo_fill_uniform_w2_avx2(histo_t *h, const double *x, const double *weights, size_t n);
bool histo_fill_uniform_w2_avx512(histo_t *h, const double *x, const double *weights, size_t n);
bool histo_fill_uniform_w2_neon(histo_t *h, const double *x, const double *weights, size_t n);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_SIMD_H */
