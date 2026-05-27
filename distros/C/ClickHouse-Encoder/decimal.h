#ifndef CHE_DECIMAL_H
#define CHE_DECIMAL_H

#include <stdint.h>

/* Powers of 10. The first table fits in uint64 (1 .. 1e19). The second
 * is in double precision (1 .. 1e38) for fast float-path scaling. */
extern const uint64_t pow10_u64[20];

double      decimal_pow10  (int n);
long double decimal_pow10l (int n);

/* limbs[0..3] += digit. Returns the final carry (0 = no overflow).
 * Used by the Decimal256 negate-in-place sequence in encode_scalar. */
int add_digit_256(uint64_t limbs[4], uint64_t digit);

/* Parse "[+-]?digits[.digits]?" into 128/256-bit two's-complement
 * integers scaled by 10^scale. Return 1 on success, 0 if malformed
 * or out-of-range. */
int parse_decimal128_str   (const char *s, STRLEN len, int scale,
                            uint64_t *hi_out, uint64_t *lo_out);
int parse_decimal256_str   (const char *s, STRLEN len, int scale,
                            uint64_t limbs_out[4]);
int parse_decimal_int64_str(const char *s, STRLEN len, int scale,
                            int64_t *out);

#endif
