/**
 * @file internal_common.h
 * @brief Common internal primitives, aligned allocators, endianness, and bin lookup math.
 */

#ifndef LIBHISTO_INTERNAL_COMMON_H
#define LIBHISTO_INTERNAL_COMMON_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* Endian Conversion Primitives (Single-cycle BSWAP Builtins)                */
/* ========================================================================= */

static inline uint16_t histo_htole16(uint16_t val) {
#if defined(__BYTE_ORDER__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#  if defined(__GNUC__) || defined(__clang__)
    return __builtin_bswap16(val);
#  elif defined(_MSC_VER)
    return _byteswap_ushort(val);
#  else
    return (uint16_t)((val << 8) | (val >> 8));
#  endif
#else
    return val;
#endif
}

static inline uint32_t histo_htole32(uint32_t val) {
#if defined(__BYTE_ORDER__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#  if defined(__GNUC__) || defined(__clang__)
    return __builtin_bswap32(val);
#  elif defined(_MSC_VER)
    return _byteswap_ulong(val);
#  else
    return (uint32_t)(((val & 0x000000FFu) << 24) |
                      ((val & 0x0000FF00u) << 8)  |
                      ((val & 0x00FF0000u) >> 8)  |
                      ((val & 0xFF000000u) >> 24));
#  endif
#else
    return val;
#endif
}

static inline uint64_t histo_htole64(uint64_t val) {
#if defined(__BYTE_ORDER__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#  if defined(__GNUC__) || defined(__clang__)
    return __builtin_bswap64(val);
#  elif defined(_MSC_VER)
    return _byteswap_uint64(val);
#  else
    return (((val & 0x00000000000000FFULL) << 56) |
            ((val & 0x000000000000FF00ULL) << 40) |
            ((val & 0x0000000000FF0000ULL) << 24) |
            ((val & 0x00000000FF000000ULL) << 8)  |
            ((val & 0x000000FF00000000ULL) >> 8)  |
            ((val & 0x0000FF0000000000ULL) >> 24) |
            ((val & 0x00FF000000000000ULL) >> 40) |
            ((val & 0xFF00000000000000ULL) >> 56));
#  endif
#else
    return val;
#endif
}

static inline uint16_t histo_le16toh(uint16_t val) { return histo_htole16(val); }
static inline uint32_t histo_le32toh(uint32_t val) { return histo_htole32(val); }
static inline uint64_t histo_le64toh(uint64_t val) { return histo_htole64(val); }

static inline uint64_t histo_double_to_bits(double d) {
    uint64_t bits;
    memcpy(&bits, &d, sizeof(bits));
    return bits;
}

static inline double histo_bits_to_double(uint64_t bits) {
    double d;
    memcpy(&d, &bits, sizeof(d));
    return d;
}

static inline double histo_dtole(double d) {
    uint64_t bits = histo_htole64(histo_double_to_bits(d));
    return histo_bits_to_double(bits);
}

static inline double histo_letoh_d(double d) {
    uint64_t bits = histo_le64toh(histo_double_to_bits(d));
    return histo_bits_to_double(bits);
}

/* ========================================================================= */
/* 64-Byte Cache-Line Aligned Memory Allocators                              */
/* ========================================================================= */

static inline void* histo_alloc_aligned(size_t size) {
    if (size == 0) return NULL;
    void *ptr = NULL;
#if defined(_POSIX_C_SOURCE) && (_POSIX_C_SOURCE >= 200112L)
    if (posix_memalign(&ptr, 64, size) != 0) {
        return NULL;
    }
#elif defined(_MSC_VER)
    ptr = _aligned_malloc(size, 64);
#else
    ptr = malloc(size);
#endif
    if (ptr) {
        memset(ptr, 0, size);
    }
    return ptr;
}

static inline void histo_free_aligned(void *ptr) {
    if (!ptr) return;
#if defined(_MSC_VER)
    _aligned_free(ptr);
#else
    free(ptr);
#endif
}

/* ========================================================================= */
/* Guarded Coordinate Bin Lookup Routines                                    */
/* ========================================================================= */

/**
 * @brief High-precision uniform bin lookup with secondary boundary guards.
 *
 * Corrects for IEEE-754 precision wobble at exact bin boundaries.
 * Returns [0, nbins - 1] for in-range, -1 for underflow (x < min), and nbins for overflow (x >= max).
 */
static inline int64_t histo_lookup_uniform_bin(double x, double min, double max,
                                              uint32_t nbins, double binsize,
                                              double inv_binsize)
{
    if (isnan(x)) return -2;
    if (x < min) return -1;
    if (x >= max) return (int64_t)nbins;

    int64_t idx;
    if (inv_binsize > 0.0) {
        idx = (int64_t)((x - min) * inv_binsize);
    } else if (binsize > 0.0) {
        idx = (int64_t)((x - min) / binsize);
    } else {
        return 0;
    }

    if (idx < 0) {
        idx = 0;
    } else if ((uint32_t)idx >= nbins) {
        idx = (int64_t)nbins - 1;
    }

    /* Boundary Guard 1: Verify against upper neighboring bin boundary */
    if (idx + 1 < (int64_t)nbins) {
        double next_lower = min + (double)(idx + 1) * binsize;
        if (x >= next_lower) {
            idx++;
        }
    }

    /* Boundary Guard 2: Verify against lower current bin boundary */
    if (idx > 0) {
        double curr_lower = min + (double)idx * binsize;
        if (x < curr_lower) {
            idx--;
        }
    }

    return idx;
}

/**
 * @brief High-precision variable-width bin lookup using monotonic binary search.
 *
 * Returns [0, nbins - 1] for in-range, -1 for underflow (x < edges[0]), and nbins for overflow (x >= edges[nbins]).
 */
static inline int64_t histo_lookup_variable_bin(double x, const double *edges, uint32_t nbins) {
    if (!edges || nbins == 0) return -2;
    if (isnan(x)) return -2;
    if (x < edges[0]) return -1;
    if (x >= edges[nbins]) return (int64_t)nbins;

    uint32_t low = 0;
    uint32_t high = nbins;

    while (low < high) {
        uint32_t mid = low + ((high - low) >> 1);
        if (x >= edges[mid + 1]) {
            low = mid + 1;
        } else if (x < edges[mid]) {
            high = mid;
        } else {
            return (int64_t)mid;
        }
    }

    return (int64_t)(low < nbins ? low : nbins - 1);
}

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_INTERNAL_COMMON_H */
