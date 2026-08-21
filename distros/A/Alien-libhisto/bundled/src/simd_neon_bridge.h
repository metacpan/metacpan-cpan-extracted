#ifndef HISTO_SIMD_NEON_BRIDGE_H
#define HISTO_SIMD_NEON_BRIDGE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#if defined(__aarch64__) || defined(_M_ARM64) || defined(__ARM_NEON)

#include <arm_neon.h>

#else
/* NEON bridge / emulation layer for x86_64 / other host targets */

#if defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && _M_IX86_FP >= 2)
#include <emmintrin.h>
#if defined(__SSE4_1__) || defined(__AVX__) || defined(__AVX2__)
#include <smmintrin.h>
#endif
#endif

typedef __m128d float64x2_t;
typedef __m128i uint64x2_t;
typedef __m128i int64x2_t;

static inline float64x2_t vdupq_n_f64(double val) {
    return _mm_set1_pd(val);
}

static inline float64x2_t vld1q_f64(const double *ptr) {
    return _mm_loadu_pd(ptr);
}

static inline void vst1q_f64(double *ptr, float64x2_t val) {
    _mm_storeu_pd(ptr, val);
}

static inline float64x2_t vaddq_f64(float64x2_t a, float64x2_t b) {
    return _mm_add_pd(a, b);
}

static inline float64x2_t vsubq_f64(float64x2_t a, float64x2_t b) {
    return _mm_sub_pd(a, b);
}

static inline float64x2_t vmulq_f64(float64x2_t a, float64x2_t b) {
    return _mm_mul_pd(a, b);
}

static inline float64x2_t vmaxq_f64(float64x2_t a, float64x2_t b) {
    return _mm_max_pd(a, b);
}

static inline float64x2_t vminq_f64(float64x2_t a, float64x2_t b) {
    return _mm_min_pd(a, b);
}

static inline float64x2_t vrndmq_f64(float64x2_t a) {
#if defined(__SSE4_1__) || defined(__AVX__) || defined(__AVX2__)
    return _mm_floor_pd(a);
#else
    double arr[2];
    _mm_storeu_pd(arr, a);
    arr[0] = floor(arr[0]);
    arr[1] = floor(arr[1]);
    return _mm_loadu_pd(arr);
#endif
}

static inline uint64x2_t vcltq_f64(float64x2_t a, float64x2_t b) {
    return _mm_castpd_si128(_mm_cmplt_pd(a, b));
}

static inline uint64x2_t vcgeq_f64(float64x2_t a, float64x2_t b) {
    return _mm_castpd_si128(_mm_cmpge_pd(a, b));
}

static inline uint64x2_t vceqq_f64(float64x2_t a, float64x2_t b) {
    return _mm_castpd_si128(_mm_cmpeq_pd(a, b));
}

static inline uint64x2_t vorrq_u64(uint64x2_t a, uint64x2_t b) {
    return _mm_or_si128(a, b);
}

static inline uint64x2_t vandq_u64(uint64x2_t a, uint64x2_t b) {
    return _mm_and_si128(a, b);
}

static inline uint64x2_t vmvnq_u64(uint64x2_t a) {
    __m128i ones = _mm_set1_epi32(-1);
    return _mm_xor_si128(a, ones);
}

static inline uint64_t vgetq_lane_u64(uint64x2_t v, int lane) {
    uint64_t arr[2];
    _mm_storeu_si128((__m128i *)arr, v);
    return arr[lane & 1];
}

static inline double vgetq_lane_f64(float64x2_t v, int lane) {
    double arr[2];
    _mm_storeu_pd(arr, v);
    return arr[lane & 1];
}

#endif /* !__ARM_NEON */

#endif /* HISTO_SIMD_NEON_BRIDGE_H */
