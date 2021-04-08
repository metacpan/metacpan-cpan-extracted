#include "time.h"
#include <ctype.h>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#include <panda/endian.h>

namespace panda { namespace time {

static const char   FTZ_MAGIC[]    = "TZif";
static const size_t FTZ_MAX_TIMES  = 1200;
static const size_t FTZ_MAX_TYPES  = 256;
static const size_t FTZ_MAX_CHARS  = 50;  /* Maximum number of abbreviation characters */
static const size_t FTZ_MAX_LEAPS  = 50;  /* Maximum number of leap second corrections */

#pragma pack(push,1)

struct ftz_head {
    char     tzh_magic[4];     /* TZ_MAGIC */
    char     tzh_version[1];   /* '\0' or '2' as of 2005 */
    char     tzh_reserved[15]; /* reserved--must be zero */
    uint32_t tzh_ttisgmtcnt;   /* coded number of trans. time flags */
    uint32_t tzh_ttisstdcnt;   /* coded number of trans. time flags */
    uint32_t tzh_leapcnt;      /* coded number of leap seconds */
    uint32_t tzh_timecnt;      /* coded number of transition times */
    uint32_t tzh_typecnt;      /* coded number of local time types */
    uint32_t tzh_charcnt;      /* coded number of abbr. chars */
};

typedef int32_t ftz_transtimeV1;
typedef int64_t ftz_transtimeV2;
typedef uint8_t ftz_ilocaltype;
typedef uint8_t ftz_abbrev_offset;
typedef uint8_t ftz_isstd;
typedef uint8_t ftz_isgmt;

struct ftz_localtype {
    int32_t           offset;
    uint8_t           isdst;
    ftz_abbrev_offset abbrev_offset;
};

struct ftz_leapsecV1 {
    ftz_transtimeV1 time;
    uint32_t        correction;
};

struct ftz_leapsecV2 {
    ftz_transtimeV2 time;
    uint32_t        correction;
};

#pragma pack(pop)

/*
** . . .followed by. . .
**
**  tzh_timecnt (char [4])s     coded transition times a la time(2)
**  tzh_timecnt (unsigned char)s    types of local time starting at above
**  tzh_typecnt repetitions of
**      one (char [4])      coded UTC offset in seconds
**      one (unsigned char) used to set tm_isdst
**      one (unsigned char) that's an abbreviation list index
**  tzh_charcnt (char)s     '\0'-terminated zone abbreviations
**  tzh_leapcnt repetitions of
**      one (char [4])      coded leap second transition times
**      one (char [4])      total correction after above
**  tzh_ttisstdcnt (char)s      indexed by type; if TRUE, transition
**                  time is standard time, if FALSE,
**                  transition time is wall clock time
**                  if absent, transition times are
**                  assumed to be wall clock time
**  tzh_ttisgmtcnt (char)s      indexed by type; if TRUE, transition
**                  time is UTC, if FALSE,
**                  transition time is local time
**                  if absent, transition times are
**                  assumed to be local time
*/

/*
** If tzh_version is '2' or greater, the above is followed by a second instance
** of tzhead and a second instance of the data in which each coded transition
** time uses 8 rather than 4 chars,
** then a POSIX-TZ-environment-variable-style string for use in handling
** instants after the last transition time stored in the file
** (with nothing between the newlines if there is no POSIX representation for
** such instants).
*/

enum class ParseResult { OK, ABSENT, ERROR };

static ParseResult tzparse_rule_abbrev (const char*& str, char* dest) {
    const char* st = str;
    switch (*str) {
        case ':': return ParseResult::ERROR;
        case '<':
            str++; st = str;
            while (*str && *str != '>') str++;
            if (*str != '>') return ParseResult::ERROR;
            break;
        default:
            char c;
            while ((c = *str) && !isdigit(c) && c != ',' && c != '+' && c != '-') str++;
    }

    size_t len = str - st;
    if (*str == '>') str++;

    if (!len) return ParseResult::ABSENT;
    if (len < ZONE_ABBR_MIN) return ParseResult::ERROR;

    strncpy(dest, st, len);
    dest[len] = '\0';

    return ParseResult::OK;
}

static ParseResult tzparse_rule_time (const char*& str, int32_t* dest) {
    const char* st = str;
    *dest = - (int32_t) strtol(st, (char**)&str, 10) * 3600;
    if (str == st) return ParseResult::ABSENT;
    int sign = (*dest >= 0 ? 1 : -1);
    if (*str == ':') {
        str++; st = str;
        *dest += sign * (int32_t) strtol(st, (char**)&str, 10) * 60;
        if (str == st) return ParseResult::ERROR;
        if (*str == ':') {
            str++; st = str;
            *dest += sign * (int32_t) strtol(st, (char**)&str, 10);
            if (str == st) return ParseResult::ERROR;
        }
    }

    return ParseResult::OK;
}

static ParseResult tzparse_rule_switch (const char*& str, Timezone::Rule::Zone::Switch* swtype, datetime* swdate) {
    std::memset(swdate, 0, sizeof(*swdate));
    const char* st = str;

    if (*str == 'M') {
        str++; st = str;
        *swtype = Timezone::Rule::Zone::Switch::DATE;
        swdate->mon  = (ptime_t) strtol(st, (char**)&str, 10) - 1;
        if (st == str || swdate->mon < 0 || swdate->mon > 11 || *str != '.') return ParseResult::ERROR;
        str++; st = str;
        swdate->yday = (int32_t) strtol(st, (char**)&str, 10); // yday holds week number
        if (st == str || swdate->yday < 1 || swdate->yday > 5 || *str != '.') return ParseResult::ERROR;
        str++; st = str;
        swdate->wday = (int32_t) strtol(st, (char**)&str, 10);
        if (st == str || swdate->wday < 0 || swdate->wday > 6) return ParseResult::ERROR;
    }
    else if (*str == 'J') {
        *swtype = Timezone::Rule::Zone::Switch::JDAY;
        str++; st = str;
        swdate->yday = (int32_t) strtol(st, (char**)&str, 10);
        if (st == str || swdate->yday < 1 || swdate->yday > 365) return ParseResult::ERROR;
    } else {
        *swtype = Timezone::Rule::Zone::Switch::DAY;
        swdate->yday = (int32_t) strtol(st, (char**)&str, 10);
        if (st == str || swdate->yday < 0 || swdate->yday > 365) return ParseResult::ERROR;
    }

    if (*str == '/') {
        str++;
        int32_t when;
        if (tzparse_rule_time(str, &when) != ParseResult::OK) return ParseResult::ERROR;
        when = -when; // revert reverse behaviour of parsing rule time
        if (when < -604799 || when > 604799) return ParseResult::ERROR;
        int sign = when >= 0 ? 1 : -1;
        when *= sign;
        swdate->hour = when / 3600;
        when %= 3600;
        swdate->min = when / 60;
        swdate->sec = when % 60;
        swdate->hour *= sign;
        swdate->min *= sign;
        swdate->sec *= sign;
    } else {
        swdate->hour = 2;
        swdate->min  = 0;
        swdate->sec  = 0;
    }

    return ParseResult::OK;
}

bool tzparse_rule (const string_view& sv, Timezone::Rule* rule) {
    char buf[sv.length()+1]; // null-terminate
    std::memcpy(buf, sv.data(), sv.length());
    buf[sv.length()] = 0;
    const char* rulestr = buf;

    if (tzparse_rule_abbrev(rulestr, rule->outer.abbrev) != ParseResult::OK) return false;
    if (tzparse_rule_time(rulestr, &rule->outer.gmt_offset) != ParseResult::OK) return false;
    rule->outer.isdst = 0;

    rule->hasdst = 0;
    ParseResult result;
    if ((result = tzparse_rule_abbrev(rulestr, rule->inner.abbrev)) == ParseResult::ERROR) return false;
    if (result == ParseResult::ABSENT) return *rulestr == '\0';
    
    if ((result = tzparse_rule_time(rulestr, &rule->inner.gmt_offset)) == ParseResult::ERROR) return false;
    if (result == ParseResult::ABSENT) rule->inner.gmt_offset = rule->outer.gmt_offset + 3600;
    
    if (*rulestr == ',') {
        rulestr++;
        rule->hasdst = 1;
        rule->inner.isdst = 1;
        
        if (tzparse_rule_switch(rulestr, &rule->outer.type, &rule->outer.end) != ParseResult::OK) return false;
        if (*rulestr != ',') return false;
        rulestr++;
        if (tzparse_rule_switch(rulestr, &rule->inner.type, &rule->inner.end) != ParseResult::OK) return false;
        
        if (rule->outer.type != Timezone::Rule::Zone::Switch::DATE || rule->inner.type != Timezone::Rule::Zone::Switch::DATE) {
            //fprintf(stderr, "ptime: tz switch rules other than Mm.w.d (i.e. 'n' or 'Jn') are not supported (will consider no DST in this zone)\n");
            rule->hasdst = 0;
        }
        else if (rule->outer.end.mon > rule->inner.end.mon) {
            std::swap(rule->outer, rule->inner);
        }
    }
    
    return *rulestr == '\0';
}

#undef PTIME_TZPARSE_V1
#undef PTIME_TZPARSE_V2
#define PTIME_TZPARSE_V1
#include <panda/time/tzparse_format.icc>
#undef PTIME_TZPARSE_V1
#define PTIME_TZPARSE_V2
#include <panda/time/tzparse_format.icc>

bool tzparse (const string_view& content, Timezone* zone) {
    const char* ptr = content.data();
    const char* end = ptr + content.length();

    ftz_head head;
    int      version;
    int bodyV1_size = tzparse_headerV1(ptr, end, head, &version);
    if (bodyV1_size == -1) return false;

    bool result;
    if (version >= 2) {
        ptr += bodyV1_size;
        if (tzparse_headerV2(ptr, end, head, &version) == -1) return false;
        result = tzparse_bodyV2(ptr, end, head, zone);
    } else {
        result = tzparse_bodyV1(ptr, end, head, zone);
    }

    return result;
}

}};
