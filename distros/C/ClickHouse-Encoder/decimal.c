#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdint.h>

#if defined(__SIZEOF_INT128__) && __SIZEOF_INT128__ == 16
#define HAVE_INT128 1
typedef unsigned __int128 u128_t;
#endif

#include "decimal.h"

const uint64_t pow10_u64[20] = {
    1ULL, 10ULL, 100ULL, 1000ULL, 10000ULL, 100000ULL,
    1000000ULL, 10000000ULL, 100000000ULL, 1000000000ULL,
    10000000000ULL, 100000000000ULL, 1000000000000ULL,
    10000000000000ULL, 100000000000000ULL, 1000000000000000ULL,
    10000000000000000ULL, 100000000000000000ULL,
    1000000000000000000ULL, 10000000000000000000ULL
};

static const double decimal_pow10_table[] = {
    1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,  1e8,  1e9,
    1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
    1e20, 1e21, 1e22, 1e23, 1e24, 1e25, 1e26, 1e27, 1e28, 1e29,
    1e30, 1e31, 1e32, 1e33, 1e34, 1e35, 1e36, 1e37, 1e38
};

double decimal_pow10(int n) {
    if (n >= 0 && n <= 38) return decimal_pow10_table[n];
    return pow(10.0, n);
}

/* Long-double powers of 10 for Decimal128/256 float-path multiplication.
 * Computed at extended precision so the scale doesn't double-round. */
long double decimal_pow10l(int n) {
    if (n < 0) return powl(10.0L, n);
    long double r = 1.0L;
    int i;
    for (i = 0; i < n; i++) r *= 10.0L;
    return r;
}

static int mul10_128(uint64_t *hi, uint64_t *lo) {
#ifdef HAVE_INT128
    u128_t prod_lo = (u128_t)*lo * 10;
    u128_t prod_hi = (u128_t)*hi * 10 + (uint64_t)(prod_lo >> 64);
    *lo = (uint64_t)prod_lo;
    *hi = (uint64_t)prod_hi;
    return (prod_hi >> 64) == 0;
#else
    /* 32-bit limb fallback. */
    uint64_t lo_lo = *lo & 0xFFFFFFFFULL;
    uint64_t lo_hi = *lo >> 32;
    uint64_t p_lo  = lo_lo * 10;
    uint64_t p_hi  = lo_hi * 10 + (p_lo >> 32);
    uint64_t carry = p_hi >> 32;
    *lo = (p_hi << 32) | (p_lo & 0xFFFFFFFFULL);

    uint64_t hi_lo  = *hi & 0xFFFFFFFFULL;
    uint64_t hi_hi  = *hi >> 32;
    uint64_t q_lo   = hi_lo * 10 + (carry & 0xFFFFFFFFULL);
    uint64_t q_hi   = hi_hi * 10 + (q_lo >> 32) + (carry >> 32);
    *hi = (q_hi << 32) | (q_lo & 0xFFFFFFFFULL);
    return (q_hi >> 32) == 0;
#endif
}

static int mul10_256(uint64_t limbs[4]) {
    uint64_t carry = 0;
    int i;
    for (i = 0; i < 4; i++) {
#ifdef HAVE_INT128
        u128_t prod = (u128_t)limbs[i] * 10 + carry;
        limbs[i] = (uint64_t)prod;
        carry    = (uint64_t)(prod >> 64);
#else
        uint64_t lo_lo = limbs[i] & 0xFFFFFFFFULL;
        uint64_t lo_hi = limbs[i] >> 32;
        uint64_t p_lo  = lo_lo * 10 + (carry & 0xFFFFFFFFULL);
        uint64_t p_hi  = lo_hi * 10 + (p_lo >> 32) + (carry >> 32);
        limbs[i] = (p_hi << 32) | (p_lo & 0xFFFFFFFFULL);
        carry    = p_hi >> 32;
#endif
    }
    return carry == 0;
}

int add_digit_256(uint64_t limbs[4], uint64_t digit) {
    uint64_t carry = digit;
    int i;
    for (i = 0; i < 4 && carry; i++) {
        uint64_t old = limbs[i];
        limbs[i] = old + carry;
        carry = (limbs[i] < old) ? 1 : 0;
    }
    return (int)carry;
}

int parse_decimal128_str(const char *s, STRLEN len, int scale,
                         uint64_t *hi_out, uint64_t *lo_out) {
    STRLEN i = 0;
    int neg = 0, seen_digit = 0, seen_dot = 0, frac_used = 0;
    uint64_t lo = 0, hi = 0;

    while (i < len && (s[i] == ' ' || s[i] == '\t')) i++;
    if (i < len && (s[i] == '+' || s[i] == '-')) {
        if (s[i] == '-') neg = 1;
        i++;
    }

    while (i < len) {
        char c = s[i++];
        if (c == '.') {
            if (seen_dot) return 0;
            seen_dot = 1;
            continue;
        }
        if (c < '0' || c > '9') return 0;
        seen_digit = 1;
        if (seen_dot) {
            if (frac_used >= scale) continue;  /* truncate */
            frac_used++;
        }
        if (!mul10_128(&hi, &lo)) return 0;
        uint64_t digit = (uint64_t)(c - '0');
        /* (hi:lo) + digit overflows iff hi == UINT64_MAX and lo wraps. */
        if (hi == 0xFFFFFFFFFFFFFFFFULL && lo > 0xFFFFFFFFFFFFFFFFULL - digit)
            return 0;
        uint64_t newlo = lo + digit;
        if (newlo < lo) hi++;
        lo = newlo;
    }

    if (!seen_digit) return 0;

    while (frac_used < scale) {
        if (!mul10_128(&hi, &lo)) return 0;
        frac_used++;
    }

    /* Reject magnitudes that don't fit signed 128-bit (Decimal128 storage).
     * The asymmetric extreme -2^127 has hi=0x80..., lo=0 with neg=1; allow it. */
    if (hi > 0x8000000000000000ULL) return 0;
    if (hi == 0x8000000000000000ULL && (!neg || lo != 0)) return 0;

    if (neg) {
        lo = ~lo + 1;
        hi = ~hi + (lo == 0 ? 1 : 0);
    }

    *lo_out = lo;
    *hi_out = hi;
    return 1;
}

int parse_decimal256_str(const char *s, STRLEN len, int scale,
                         uint64_t limbs_out[4]) {
    STRLEN i = 0;
    int neg = 0, seen_digit = 0, seen_dot = 0, frac_used = 0;
    uint64_t limbs[4] = {0,0,0,0};

    while (i < len && (s[i] == ' ' || s[i] == '\t')) i++;
    if (i < len && (s[i] == '+' || s[i] == '-')) {
        if (s[i] == '-') neg = 1;
        i++;
    }
    while (i < len) {
        char c = s[i++];
        if (c == '.') {
            if (seen_dot) return 0;
            seen_dot = 1;
            continue;
        }
        if (c < '0' || c > '9') return 0;
        seen_digit = 1;
        if (seen_dot) {
            if (frac_used >= scale) continue;
            frac_used++;
        }
        if (!mul10_256(limbs)) return 0;
        if (add_digit_256(limbs, (uint64_t)(c - '0'))) return 0;
    }
    if (!seen_digit) return 0;
    while (frac_used < scale) {
        if (!mul10_256(limbs)) return 0;
        frac_used++;
    }
    /* Reject magnitudes that don't fit signed 256-bit. Allow only the
     * asymmetric extreme -2^255 (top bit set, rest zero, negative). */
    if (limbs[3] > 0x8000000000000000ULL) return 0;
    if (limbs[3] == 0x8000000000000000ULL
        && (!neg || limbs[0] != 0 || limbs[1] != 0 || limbs[2] != 0))
        return 0;
    if (neg) {
        int j;
        for (j = 0; j < 4; j++) limbs[j] = ~limbs[j];
        add_digit_256(limbs, 1);
    }
    limbs_out[0] = limbs[0];
    limbs_out[1] = limbs[1];
    limbs_out[2] = limbs[2];
    limbs_out[3] = limbs[3];
    return 1;
}

int parse_decimal_int64_str(const char *s, STRLEN len, int scale,
                            int64_t *out) {
    uint64_t lo, hi;
    if (!parse_decimal128_str(s, len, scale, &hi, &lo)) return 0;
    /* Fits in int64 iff hi is sign extension of lo's high bit. */
    if (hi == 0 && (lo & 0x8000000000000000ULL) == 0) {
        *out = (int64_t)lo;
        return 1;
    }
    if (hi == ~(uint64_t)0 && (lo & 0x8000000000000000ULL)) {
        *out = (int64_t)lo;
        return 1;
    }
    return 0;
}
