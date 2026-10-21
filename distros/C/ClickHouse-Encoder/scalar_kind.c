#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "scalar_kind.h"

SV **fetch_named_value(pTHX_ HV *hv, const char *name, STRLEN len) {
    SV **value = hv_fetch(hv, name, (I32)len, 0);
    if (!value && len && is_utf8_string((const U8 *)name, len))
        value = hv_fetch(hv, name, -(I32)len, 0);
    return value;
}

const char *hash_key_bytes(pTHX_ HE *he, STRLEN *len) {
    if (HeKLEN(he) == HEf_SVKEY) return SvPV(HeKEY_sv(he), *len);
    if (HeKWASUTF8(he)) return SvPVutf8(hv_iterkeysv(he), *len);
    *len = (STRLEN)HeKLEN(he);
    return HeKEY(he);
}

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
