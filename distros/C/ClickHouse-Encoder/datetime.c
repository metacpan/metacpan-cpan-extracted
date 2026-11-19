#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdint.h>

#include "types.h"
#include "datetime.h"
#include "decimal.h"
#include "scalar_kind.h"

typedef struct {
    int kind, month, week, day, seconds, clock;
} TZRule;

struct CHTimezone {
    CHTimezone *next;
    char *name;
    int64_t *transitions;
    unsigned char *indices;
    uint32_t count, type_count;
    int32_t offsets[256];
    int footer, has_dst, standard, daylight;
    TZRule start, end;
};

static const int days_in_month[] = {31,28,31,30,31,30,31,31,30,31,30,31};

static int is_leap_year(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

static int64_t year_days(int year) {
    int y = year - 1;
    return 365LL * (year - 1970) + y / 4 - y / 100 + y / 400 - 477;
}

static int epoch_year(int64_t epoch) {
    int year = 1970 + (int)(epoch / 31556952);
    while (epoch < year_days(year) * 86400) year--;
    while (epoch >= year_days(year + 1) * 86400) year++;
    return year;
}

static int64_t rule_epoch(const TZRule *rule, int year, int standard, int before) {
    int day = rule->day, month;
    int64_t days = year_days(year);
    if (rule->kind == 'M') {
        int weekday, length;
        for (month = 1; month < rule->month; month++)
            days += days_in_month[month - 1] + (month == 2 && is_leap_year(year));
        weekday = (int)((days + 4) % 7);
        if (weekday < 0) weekday += 7;
        day = (rule->day - weekday + 7) % 7 + 7 * (rule->week - 1);
        length = days_in_month[rule->month - 1]
               + (rule->month == 2 && is_leap_year(year));
        if (day >= length) day -= 7;
    } else if (rule->kind == 'J') {
        day--;
        if (is_leap_year(year) && rule->day >= 60) day++;
    }
    return (days + day) * 86400 + rule->seconds
         - (rule->clock == 'u' ? 0 : rule->clock == 's' ? standard : before);
}

int timezone_offset(const CHTimezone *tz, int64_t epoch) {
    uint32_t lo = 0, hi;
    if (!tz) return 0;
    if (tz->footer && (!tz->count || epoch > tz->transitions[tz->count - 1])) {
        int year, y, offset = tz->standard;
        int64_t latest = INT64_MIN;
        if (!tz->has_dst) return tz->standard;
        year = epoch_year(epoch);
        for (y = year - 1; y <= year + 1; y++) {
            int64_t start = rule_epoch(&tz->start, y, tz->standard, tz->standard);
            int64_t end = rule_epoch(&tz->end, y, tz->standard, tz->daylight);
            /* >= so a year-round DST rule (end(y) == start(y+1)) stays in DST */
            if (start <= epoch && start >= latest) { latest = start; offset = tz->daylight; }
            if (end <= epoch && end > latest) { latest = end; offset = tz->standard; }
        }
        return offset;
    }
    hi = tz->count;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2;
        if (tz->transitions[mid] <= epoch) lo = mid + 1;
        else hi = mid;
    }
    return tz->offsets[lo ? tz->indices[lo - 1] : 0];
}

static int tz_number(const char **p, int limit) {
    int n = 0;
    if (**p < '0' || **p > '9') return -1;
    while (**p >= '0' && **p <= '9') {
        int d = *(*p)++ - '0';
        if (n > (limit - d) / 10) return -1;
        n = n * 10 + d;
    }
    return n <= limit ? n : -1;
}

static int tz_abbreviation(const char **p) {
    const char *start = *p;
    if (**p == '<') {
        (*p)++;
        while (**p && **p != '>') (*p)++;
        if (**p != '>') return 0;
        (*p)++;
        return *p - start >= 3;
    }
    while ((**p >= 'A' && **p <= 'Z') || (**p >= 'a' && **p <= 'z')) (*p)++;
    return *p - start >= 3;
}

static int tz_seconds(const char **p, int *out) {
    int sign = 1, h, m = 0, s = 0;
    if (**p == '-' || **p == '+') sign = *(*p)++ == '-' ? -1 : 1;
    h = tz_number(p, 167);
    if (h < 0) return 0;
    if (**p == ':') { (*p)++; m = tz_number(p, 59); }
    if (**p == ':') { (*p)++; s = tz_number(p, 59); }
    if (m < 0 || s < 0) return 0;
    *out = sign * (h * 3600 + m * 60 + s);
    return 1;
}

static int tz_rule(const char **p, TZRule *rule) {
    rule->clock = 'w';
    rule->seconds = 7200;
    if (**p == 'M') {
        rule->kind = *(*p)++;
        rule->month = tz_number(p, 12);
        if (rule->month < 1 || *(*p)++ != '.') return 0;
        rule->week = tz_number(p, 5);
        if (rule->week < 1 || *(*p)++ != '.') return 0;
        rule->day = tz_number(p, 6);
    } else {
        rule->kind = **p == 'J' ? *(*p)++ : 'n';
        rule->day = tz_number(p, 365);
        if (rule->kind == 'J' && rule->day == 0) return 0;
    }
    if (rule->day < 0) return 0;
    if (**p == '/') {
        (*p)++;
        if (!tz_seconds(p, &rule->seconds)) return 0;
        if (**p == 's' || **p == 'w') rule->clock = *(*p)++;
        else if (**p == 'u' || **p == 'g' || **p == 'z') { rule->clock = 'u'; (*p)++; }
    }
    return 1;
}

static int tz_footer(CHTimezone *tz, const char *p) {
    int offset;
    if (!tz_abbreviation(&p) || !tz_seconds(&p, &offset)) return 0;
    tz->standard = -offset;
    tz->footer = 1;
    if (!*p) return 1;
    if (!tz_abbreviation(&p)) return 0;
    tz->has_dst = 1;
    tz->daylight = tz->standard + 3600;
    if (*p != ',') {
        if (!tz_seconds(&p, &offset)) return 0;
        tz->daylight = -offset;
    }
    if (*p++ != ',' || !tz_rule(&p, &tz->start)) return 0;
    if (*p++ != ',' || !tz_rule(&p, &tz->end)) return 0;
    return !*p;
}

static uint32_t tz_u32(const unsigned char *p) {
    return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16
         | (uint32_t)p[2] << 8 | p[3];
}

static uint64_t tz_section_size(const unsigned char *h, int width) {
    return (uint64_t)tz_u32(h + 32) * (width + 1)
         + (uint64_t)tz_u32(h + 36) * 6 + tz_u32(h + 40)
         + (uint64_t)tz_u32(h + 28) * (width + 4)
         + tz_u32(h + 20) + tz_u32(h + 24);
}

void timezone_free(pTHX_ CHTimezone *tz) {
    while (tz) {
        CHTimezone *next = tz->next;
        Safefree(tz->name);
        Safefree(tz->transitions);
        Safefree(tz->indices);
        Safefree(tz);
        tz = next;
    }
}

CHTimezone *timezone_load(pTHX_ CHTimezone **zones, const char *name) {
    static const char *dirs[] = {"/usr/share/zoneinfo", "/usr/lib/zoneinfo", "/usr/share/lib/zoneinfo"};
    CHTimezone *tz;
    PerlIO *file = NULL;
    SV *data;
    const unsigned char *h, *p;
    STRLEN length;
    uint64_t size;
    uint32_t i;
    int width = 4, d;
    const char *tzdir = PerlEnv_getenv("TZDIR");
    for (tz = *zones; tz; tz = tz->next)
        if (!strcmp(tz->name, name)) return tz;
    if (!strcmp(name, "UTC") || !strcmp(name, "Etc/UTC") || !strcmp(name, "GMT")) {
        Newxz(tz, 1, CHTimezone);
        goto loaded;
    }
    if (!*name || *name == '/' || strstr(name, "..") || strchr(name, '\\'))
        croak("Invalid timezone '%s'", name);
    for (d = 0; d < (tzdir ? 1 : 3); d++) {
        SV *path = sv_2mortal(newSVpvf("%s/%s", tzdir ? tzdir : dirs[d], name));
        file = PerlIO_open(SvPV_nolen(path), "rb");
        if (file) break;
    }
    if (!file) croak("Unknown timezone '%s' or missing timezone database", name);
    data = sv_2mortal(newSVpvs(""));
    for (;;) {
        char chunk[4096];
        SSize_t n = PerlIO_read(file, chunk, sizeof(chunk));
        if (n <= 0) {
            int failed = n < 0 || PerlIO_error(file);
            PerlIO_close(file);
            if (failed) croak("Cannot read timezone '%s'", name);
            break;
        }
        sv_catpvn(data, chunk, n);
        if (SvCUR(data) > 16777216) {
            PerlIO_close(file);
            croak("Timezone '%s' TZif file is too large", name);
        }
    }
    h = (const unsigned char *)SvPV(data, length);
    if (length < 44 || memcmp(h, "TZif", 4)) goto invalid;
    size = tz_section_size(h, width);
    if (size > length - 44) goto invalid;
    if (h[4] == '2' || h[4] == '3') {
        h += 44 + (STRLEN)size;
        length -= 44 + (STRLEN)size;
        if (length < 44 || memcmp(h, "TZif", 4)) goto invalid;
        width = 8;
        size = tz_section_size(h, width);
        if (size > length - 44) goto invalid;
    } else if (h[4] != 0) goto invalid;
    Newxz(tz, 1, CHTimezone);
    tz->count = tz_u32(h + 32);
    tz->type_count = tz_u32(h + 36);
    if (!tz->type_count || tz->type_count > 256) goto invalid;
    p = h + 44;
    if (tz->count) {
        Newx(tz->transitions, tz->count, int64_t);
        Newx(tz->indices, tz->count, unsigned char);
    }
    for (i = 0; i < tz->count; i++, p += width) {
        uint64_t v = tz_u32(p);
        tz->transitions[i] = width == 8 ? (int64_t)((v << 32) | tz_u32(p + 4))
                                       : (int64_t)(int32_t)v;
        if (i && tz->transitions[i] <= tz->transitions[i - 1]) goto invalid;
    }
    for (i = 0; i < tz->count; i++) {
        if (p[i] >= tz->type_count) goto invalid;
        tz->indices[i] = p[i];
    }
    p += tz->count;
    for (i = 0; i < tz->type_count; i++, p += 6) {
        tz->offsets[i] = (int32_t)tz_u32(p);
        if (tz->offsets[i] < -604800 || tz->offsets[i] > 604800) goto invalid;
    }
    if (width == 8 && length > 44 + size) {
        STRLEN footer_len = length - 44 - (STRLEN)size;
        const char *footer = (const char *)h + 44 + (STRLEN)size;
        if (footer_len < 2 || footer[0] != '\n' || footer[footer_len - 1] != '\n') goto invalid;
        if (footer_len > 2) {
            SV *text = sv_2mortal(newSVpvn(footer + 1, footer_len - 2));
            if (memchr(SvPVX(text), 0, SvCUR(text)) || !tz_footer(tz, SvPVX(text))) goto invalid;
        }
    }
loaded:
    tz->name = savepv(name);
    tz->next = *zones;
    *zones = tz;
    return tz;
invalid:
    timezone_free(aTHX_ tz);
    croak("Invalid timezone '%s' TZif data or POSIX rule", name);
    return NULL;
}

static const CHTimezone *column_timezone(pTHX_ TypeInfo *t) {
    if (t->zones) {
        t->tz = timezone_load(aTHX_ t->zones, t->timezone);
        t->zones = NULL;
    }
    return t->tz;
}

static int64_t wall_to_epoch(const CHTimezone *tz, int64_t wall) {
    int offsets[258], count = 0, i;
    int64_t best = INT64_MAX;
    uint32_t j;
    if (!tz) return wall;
    for (j = 0; j < tz->type_count; j++) offsets[count++] = tz->offsets[j];
    if (tz->footer) {
        offsets[count++] = tz->standard;
        if (tz->has_dst) offsets[count++] = tz->daylight;
    }
    for (i = 0; i < count; i++) {
        int64_t candidate = wall - offsets[i];
        if (timezone_offset(tz, candidate) == offsets[i] && candidate < best) best = candidate;
    }
    if (best != INT64_MAX) return best;
    /* ClickHouse resolves gaps using the offset after the forward jump. */
    for (j = 0; j < tz->count; j++) {
        int before = tz->offsets[j ? tz->indices[j - 1] : 0];
        int after = tz->offsets[tz->indices[j]];
        if (after > before && wall >= tz->transitions[j] + before
                           && wall < tz->transitions[j] + after) return wall - after;
    }
    if (tz->footer && tz->has_dst) {
        int year = epoch_year(wall), y;
        for (y = year - 1; y <= year + 1; y++) {
            int64_t start = rule_epoch(&tz->start, y, tz->standard, tz->standard);
            int64_t end = rule_epoch(&tz->end, y, tz->standard, tz->daylight);
            if (tz->daylight > tz->standard && wall >= start + tz->standard
                                          && wall < start + tz->daylight) return wall - tz->daylight;
            if (tz->standard > tz->daylight && wall >= end + tz->daylight
                                          && wall < end + tz->standard) return wall - tz->standard;
        }
    }
    return wall - timezone_offset(tz, wall);
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

#define IS_DIGIT(c) ((c) >= '0' && (c) <= '9')

static void invalid_datetime(pTHX_ const char *s, STRLEN len) {
    croak("Invalid datetime string: %.*s", (int)(len > 30 ? 30 : len), s);
}

/* Parses " HH:MM[:SS]" after the date; returns the position just past it. */
static STRLEN parse_time_part(pTHX_ const char *s, STRLEN len, int64_t *seconds) {
    STRLEN pos = 10;
    *seconds = 0;
    while (pos < len && s[pos] == ' ') pos++;
    if (pos == len || s[10] == 'Z' || s[10] == 'z' || s[10] == '+' || s[10] == '-')
        return 10;
    if ((s[10] != ' ' && s[10] != 'T') || len < 16 || s[13] != ':'
        || !IS_DIGIT(s[11]) || !IS_DIGIT(s[12])
        || !IS_DIGIT(s[14]) || !IS_DIGIT(s[15]))
        invalid_datetime(aTHX_ s, len);
    *seconds = ((s[11]-'0')*10 + (s[12]-'0')) * 3600
             + ((s[14]-'0')*10 + (s[15]-'0')) * 60;
    if (len == 16 || s[16] != ':') return 16;
    if (len < 19 || !IS_DIGIT(s[17]) || !IS_DIGIT(s[18]))
        invalid_datetime(aTHX_ s, len);
    *seconds += (s[17]-'0')*10 + (s[18]-'0');
    return 19;
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

static int64_t zone_wall_time(pTHX_ const char *s, STRLEN len, STRLEN pos,
                              int64_t wall, TypeInfo *t) {
    if (pos < len && (s[pos] == 'Z' || s[pos] == 'z' || s[pos] == '+' || s[pos] == '-'))
        return wall - parse_tz_offset(aTHX_ s, len, pos);
    while (pos < len && s[pos] == ' ') pos++;
    if (pos != len) invalid_datetime(aTHX_ s, len);
    return wall_to_epoch(column_timezone(aTHX_ t), wall);
}

uint32_t parse_datetime_string(pTHX_ const char *s, STRLEN len, TypeInfo *t) {
    int32_t days = parse_date_string(aTHX_ s, len);
    int64_t seconds, epoch;
    STRLEN pos = parse_time_part(aTHX_ s, len, &seconds);
    if (pos == 19 && pos < len && s[pos] == '.') {
        pos++;
        while (pos < len && IS_DIGIT(s[pos])) pos++;
    }
    epoch = zone_wall_time(aTHX_ s, len, pos, (int64_t)days * 86400 + seconds, t);
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

int64_t parse_datetime64_string(pTHX_ const char *s, STRLEN len, int precision, TypeInfo *t) {
    int32_t days = parse_date_string(aTHX_ s, len);
    int64_t seconds, base, frac = 0;
    STRLEN tz_pos = parse_time_part(aTHX_ s, len, &seconds);

    if (tz_pos == 19 && tz_pos < len && s[tz_pos] == '.') {
        int i;
        for (i = 0; i < precision && (20 + i) < (int)len; i++) {
            char c = s[20 + i];
            if (!IS_DIGIT(c)) break;
            frac = frac * 10 + (c - '0');
        }
        for (; i < precision; i++) frac *= 10;
        tz_pos = 20;
        while (tz_pos < len && IS_DIGIT(s[tz_pos])) tz_pos++;
    }
    base = zone_wall_time(aTHX_ s, len, tz_pos, (int64_t)days * 86400 + seconds, t);

    /* precision is capped at 0..9, so scale fits int64 comfortably - but
     * base * scale does not, and would wrap to a negative tick count
     * (signed overflow being undefined besides). Check before the
     * multiply, not after. */
    int64_t scale = (precision >= 0 && precision <= 18)
                  ? (int64_t)pow10_u64[precision] : 1;
    if (scale > 1 && (base > INT64_MAX / scale || base < INT64_MIN / scale))
        croak("DateTime64(%d) out of range (value overflows 64-bit ticks): "
              "%.*s", precision, (int)(len > 30 ? 30 : len), s);
    int64_t ticks = base * scale;
    if (frac > 0 && ticks > INT64_MAX - frac)
        croak("DateTime64(%d) out of range (value overflows 64-bit ticks): "
              "%.*s", precision, (int)(len > 30 ? 30 : len), s);
    return ticks + frac;
}
