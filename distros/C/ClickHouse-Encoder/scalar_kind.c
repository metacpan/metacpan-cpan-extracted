#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "scalar_kind.h"

int looks_stringy(SV *val) {
    return SvOK(val) && SvPOK(val) && !SvIOK(val) && !SvNOK(val);
}

/* "[+-]?digits" (no exponent, no decimal point). */
int looks_like_int_str(const char *s, STRLEN len) {
    STRLEN i = 0;
    if (len == 0) return 0;
    if (s[0] == '+' || s[0] == '-') i = 1;
    if (i >= len) return 0;
    for (; i < len; i++) if (s[i] < '0' || s[i] > '9') return 0;
    return 1;
}

/* "[+-]?digits[.digits]?" - no exponent, integer-with-dot allowed. */
int looks_like_number_str(const char *s, STRLEN len) {
    STRLEN i = 0;
    int seen_digit = 0, seen_dot = 0;
    if (len == 0) return 0;
    if (s[0] == '+' || s[0] == '-') i = 1;
    for (; i < len; i++) {
        if (s[i] == '.') {
            if (seen_dot) return 0;
            seen_dot = 1;
        } else if (s[i] >= '0' && s[i] <= '9') {
            seen_digit = 1;
        } else return 0;
    }
    return seen_digit;
}

/* YYYY-MM-DD prefix - validates digit shape only; range checks happen
 * in parse_date_string so out-of-range components produce informative
 * messages with the offending value. */
int looks_like_date(const char *s, STRLEN len) {
    int i;
    if (len < 10) return 0;
    for (i = 0; i < 4; i++) if (s[i] < '0' || s[i] > '9') return 0;
    if (s[4] != '-') return 0;
    if (s[5] < '0' || s[5] > '9' || s[6] < '0' || s[6] > '9') return 0;
    if (s[7] != '-') return 0;
    if (s[8] < '0' || s[8] > '9' || s[9] < '0' || s[9] > '9') return 0;
    return 1;
}
