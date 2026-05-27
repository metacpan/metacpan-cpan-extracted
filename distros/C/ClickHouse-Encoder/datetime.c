#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdint.h>

#include "datetime.h"
#include "decimal.h"
#include "scalar_kind.h"

static const int days_in_month[] = {31,28,31,30,31,30,31,31,30,31,30,31};

static int is_leap_year(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

int32_t parse_date_string(pTHX_ const char *s, STRLEN len) {
    if (!looks_like_date(s, len))
        croak("Invalid date string (expected YYYY-MM-DD): %.*s",
              (int)(len > 30 ? 30 : len), s);

    int year = (s[0]-'0')*1000 + (s[1]-'0')*100 + (s[2]-'0')*10 + (s[3]-'0');
    int month = (s[5]-'0')*10 + (s[6]-'0');
    int day = (s[8]-'0')*10 + (s[9]-'0');

    /* looks_like_date only validates the digit shape; reject out-of-range
     * components so the days_in_month loop can't read past the array, and
     * reject impossible day-of-month combinations (e.g. 2024-04-31). */
    if (month < 1 || month > 12 || day < 1 || day > 31)
        croak("Invalid date '%.*s': month/day out of range",
              (int)(len > 30 ? 30 : len), s);
    int max_day = days_in_month[month-1]
                + (month == 2 && is_leap_year(year) ? 1 : 0);
    if (day > max_day)
        croak("Invalid date '%.*s': day %d exceeds month %d's length (%d)",
              (int)(len > 30 ? 30 : len), s, day, month, max_day);

    int32_t days = 0;
    int y, m;

    for (y = 1970; y < year; y++) days += is_leap_year(y) ? 366 : 365;
    for (y = year; y < 1970; y++) days -= is_leap_year(y) ? 366 : 365;

    for (m = 1; m < month; m++) {
        days += days_in_month[m-1];
        if (m == 2 && is_leap_year(year)) days++;
    }

    days += day - 1;
    return days;
}

static void parse_time_part(pTHX_ const char *s, STRLEN len,
                            int *h, int *mi, int *se) {
    if (len < 19) { *h = *mi = *se = 0; return; }
    #define IS_DIGIT(c) ((c) >= '0' && (c) <= '9')
    if ((s[10] != ' ' && s[10] != 'T') || s[13] != ':' || s[16] != ':'
        || !IS_DIGIT(s[11]) || !IS_DIGIT(s[12])
        || !IS_DIGIT(s[14]) || !IS_DIGIT(s[15])
        || !IS_DIGIT(s[17]) || !IS_DIGIT(s[18]))
        croak("Invalid datetime string: %.*s", (int)(len > 30 ? 30 : len), s);
    #undef IS_DIGIT
    *h  = (s[11]-'0')*10 + (s[12]-'0');
    *mi = (s[14]-'0')*10 + (s[15]-'0');
    *se = (s[17]-'0')*10 + (s[18]-'0');
}

static int parse_tz_offset(pTHX_ const char *s, STRLEN len, STRLEN pos) {
    if (pos >= len) return 0;
    char c = s[pos];
    if (c == 'Z' || c == 'z') return 0;
    if (c != '+' && c != '-') return 0;
    int sign = (c == '-') ? -1 : 1;
    pos++;
    if (pos + 2 > len
        || s[pos]   < '0' || s[pos]   > '9'
        || s[pos+1] < '0' || s[pos+1] > '9')
        croak("Invalid datetime timezone: %.*s",
              (int)(len > 30 ? 30 : len), s);
    int hh = (s[pos]-'0')*10 + (s[pos+1]-'0');
    pos += 2;
    int mm = 0;
    if (pos < len && s[pos] == ':') pos++;
    if (pos + 2 <= len
        && s[pos]   >= '0' && s[pos]   <= '9'
        && s[pos+1] >= '0' && s[pos+1] <= '9') {
        mm = (s[pos]-'0')*10 + (s[pos+1]-'0');
    }
    return sign * (hh * 3600 + mm * 60);
}

uint32_t parse_datetime_string(pTHX_ const char *s, STRLEN len) {
    int32_t days = parse_date_string(aTHX_ s, len);
    int h, mi, se;
    parse_time_part(aTHX_ s, len, &h, &mi, &se);
    int64_t epoch = (int64_t)days * 86400 + h * 3600 + mi * 60 + se;
    /* Optional ISO 8601 zone marker at position 19 (after HH:MM:SS). */
    if (len > 19) epoch -= parse_tz_offset(aTHX_ s, len, 19);
    /* DateTime is UInt32 on the wire (1970-01-01 .. 2106-02-07). Reject
     * out-of-range epochs explicitly rather than silently wrapping. */
    if (epoch < 0 || epoch > 0xFFFFFFFFLL)
        croak("DateTime out of UInt32 range "
              "(1970-01-01 .. 2106-02-07 06:28:15): %.*s",
              (int)(len > 30 ? 30 : len), s);
    return (uint32_t)epoch;
}

/* Multiply a Perl double by 10^precision, croak on Inf/NaN/overflow,
 * return the rounded int64. Shared by the SvNOK and string-number
 * branches of the T_DATETIME64 encode path. */
int64_t dt64_double_to_int64(pTHX_ double v, int precision) {
    double d = v * decimal_pow10(precision);
    /* Same bound as the T_DECIMAL64 path: 2^63 in double form. Strict
     * inequality so 2^63 itself (which would overflow int64_t after
     * llround) is rejected. */
    if (!(isfinite(d) && d > -9.223372036854776e18 && d < 9.223372036854776e18))
        croak("DateTime64 overflow (or non-finite value)");
    return (int64_t)llround(d);
}

int64_t parse_datetime64_string(pTHX_ const char *s, STRLEN len, int precision) {
    int32_t days = parse_date_string(aTHX_ s, len);
    int h, mi, se;
    parse_time_part(aTHX_ s, len, &h, &mi, &se);

    int64_t base = (int64_t)days * 86400 + h * 3600 + mi * 60 + se;
    int64_t frac = 0;
    STRLEN tz_pos = 19;

    if (len > 20 && s[19] == '.') {
        int i;
        for (i = 0; i < precision && (20 + i) < (int)len; i++) {
            char c = s[20 + i];
            if (c < '0' || c > '9') break;
            frac = frac * 10 + (c - '0');
        }
        for (; i < precision; i++) frac *= 10;
        /* Skip any extra fractional digits beyond the column's precision. */
        tz_pos = 20;
        while (tz_pos < len && s[tz_pos] >= '0' && s[tz_pos] <= '9') tz_pos++;
    }

    if (tz_pos < len) base -= parse_tz_offset(aTHX_ s, len, tz_pos);

    uint64_t scale = (precision >= 0 && precision <= 19) ? pow10_u64[precision] : 1;
    return base * (int64_t)scale + frac;
}
