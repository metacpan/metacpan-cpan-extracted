#ifndef CHE_DATETIME_H
#define CHE_DATETIME_H

#include <stdint.h>

/* Parse a "YYYY-MM-DD" date string into the number of days since
 * 1970-01-01 (negative for pre-epoch dates). Croaks on malformed
 * or out-of-range input. */
int32_t parse_date_string(pTHX_ const char *s, STRLEN len);

/* Full DateTime parse: croaks if the result doesn't fit UInt32. */
uint32_t parse_datetime_string(pTHX_ const char *s, STRLEN len);

/* DateTime64 helpers: int64 = v * 10^precision, with overflow check. */
int64_t dt64_double_to_int64(pTHX_ double v, int precision);
int64_t parse_datetime64_string(pTHX_ const char *s, STRLEN len, int precision);

#endif
