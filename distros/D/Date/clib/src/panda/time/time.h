#pragma once
#include <limits>
#include <time.h>
#include <vector>
#include <stdint.h>
#include <stddef.h>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/string_view.h>

namespace panda { namespace time {

using ptime_t = int64_t;

constexpr const size_t ZONE_ABBR_MAX = 7;   // max length of local type abbrev name (MSK, EST, EDT, ...)
constexpr const size_t ZONE_ABBR_MIN = 3;

static constexpr const ptime_t EPOCH_MAX    =  67767976233446399l; // calculated for gmtime(s=59,m=59,h=23,mday=31,y=2**31-1) - 24 hours for possible tz offsets
static constexpr const ptime_t EPOCH_MIN    = -67768100567884800l; // calculated for gmtime(s=00,m=00,h=00,mday=01,y=-2**31)  + 24 hours for possible tz offsets
static constexpr const ptime_t EPOCH_NEGINF = std::numeric_limits<ptime_t>::min();

extern const int         DAYS_IN_MONTH[2][12];
extern const int         MON2YDAY[2][12];
extern const string_view MONTH_NAMES[12];
extern const string_view WDAY_NAMES[7];

static constexpr const char GMT_FALLBACK[] = "GMT0";

struct datetime {
    ptime_t sec;
    ptime_t min;
    ptime_t hour;
    ptime_t mday;
    ptime_t mon;
    int32_t yday;
    int32_t wday;
    int32_t year;
    int32_t isdst;
    int32_t gmtoff;
    union {
        char    zone[ZONE_ABBR_MAX+1];
        int64_t n_zone;
    };
};

struct Timezone;
using TimezoneSP = panda::iptr<const Timezone>;

TimezoneSP        tzget      (const string_view& zonename);
TimezoneSP        tzget_abbr (const string_view& zoneabbr);
const TimezoneSP& tzlocal    ();

void tzset (const string_view& zonename);
void tzset (const TimezoneSP& = {});

const string& tzdir    ();
void          tzdir    (const string&);
const string& tzsysdir ();

const string& tzembededdir();
void          tzembededdir(const string&);

void use_system_timezones ();
void use_embed_timezones();
std::vector<string> available_timezones ();

bool     gmtime   (ptime_t epoch, datetime* result);
datetime gmtime   (ptime_t epoch);
ptime_t  timegm   (datetime* date);
ptime_t  timegml  (datetime* date);
ptime_t  timegmll (const datetime* date);

bool     anytime  (ptime_t epoch, datetime* result, const TimezoneSP& zone);
datetime anytime  (ptime_t epoch, const TimezoneSP& zone);
ptime_t  timeany  (datetime* date, const TimezoneSP& zone);
ptime_t  timeanyl (datetime* date, const TimezoneSP& zone);

inline bool     localtime  (ptime_t epoch, datetime* result) { return anytime(epoch, result, tzlocal()); }
inline datetime localtime  (ptime_t epoch)                   { return anytime(epoch, tzlocal()); }
inline ptime_t  timelocal  (datetime* date)                  { return timeany(date, tzlocal()); }
inline ptime_t  timelocall (datetime* date)                  { return timeanyl(date, tzlocal()); }

string strftime (string_view format, const datetime&);

inline int is_leap_year  (int32_t year)                { return (year % 4) == 0 && ((year % 25) != 0 || (year % 16) == 0); }
inline int days_in_month (int32_t year, uint8_t month) { return DAYS_IN_MONTH[is_leap_year(year)][month]; }

inline string_view month_name  (int mon)  { return MONTH_NAMES[mon]; }
inline string_view month_sname (int mon)  { return MONTH_NAMES[mon].substr(0,3); }
inline string_view wday_name   (int wday) { return WDAY_NAMES[wday]; }
inline string_view wday_sname  (int wday) { return WDAY_NAMES[wday].substr(0,3); }

// DAYS PASSED SINCE 1 Jan 0001 00:00:00 TILL 1 Jan <year> 00:00:00
inline ptime_t christ_days (int32_t year) {
    ptime_t yearpos = (ptime_t)year + 2147483999U;
    ptime_t ret = yearpos*365;
    yearpos >>= 2;
    ret += yearpos;
    yearpos /= 25;
    ret -= yearpos - (yearpos >> 2) + (ptime_t)146097*5368710;
    return ret;
}

// DAYS PASSED SINCE 1 Jan 0001 00:00:00 TILL supplied date
inline ptime_t christ_days (int32_t year, uint8_t month, uint8_t mday) {
    return christ_days(year) + MON2YDAY[is_leap_year(year)][month] + mday - 1;
}

// returns week day number for supplied date (0=Sun, 6=Sat), only for dates later than 0000y
inline uint8_t wday (int32_t year, uint8_t month, uint8_t mday) {
    return (1 + christ_days(year, month, mday)) % 7; // "1" because 1 Jan 0001 was monday :)
}

struct Timezone : panda::AtomicRefcnt {
    struct Transition {
        ptime_t start;        // time of transition
        ptime_t local_start;  // local time of transition (epoch+offset).
        ptime_t local_end;    // local time of transition's end (next transition epoch + MY offset).
        ptime_t local_lower;  // local_start or prev transition's local_end
        ptime_t local_upper;  // local_start or prev transition's local_end
        int32_t offset;       // offset from non-leap GMT
        int32_t gmt_offset;   // offset from leap GMT
        int32_t delta;        // offset minus previous transition's offset
        int32_t isdst;        // is DST in effect after this transition
        int32_t leap_corr;    // summary leap seconds correction at the moment
        int32_t leap_delta;   // delta leap seconds correction (0 if it's just a transition, != 0 if it's a leap correction)
        ptime_t leap_end;     // end of leap period (not including last second) = start + leap_delta
        ptime_t leap_lend;    // local_start + 2*leap_delta
        union {
            char    abbrev[ZONE_ABBR_MAX+1]; // transition (zone) abbreviation
            int64_t n_abbrev;                // abbrev as int64_t
        };
    };

    struct Rule {
        // rule for future (beyond transition list) dates and for abstract timezones
        // http://www.gnu.org/software/libc/manual/html_node/TZ-Variable.html
        // --------------------------------------------------------------------------------------------
        // 1 Jan   OUTER ZONE   OUTER END        INNER ZONE        INNER END     OUTER ZONE      31 Dec
        // --------------------------------------------------------------------------------------------
        struct Zone {
            enum class Switch { DATE, JDAY, DAY };
            union {
                char    abbrev[ZONE_ABBR_MAX+1]; // zone abbreviation
                int64_t n_abbrev;                // abbrev as int64_t
            };
            int32_t  offset;                     // offset from non-leap GMT
            int32_t  gmt_offset;                 // offset from leap GMT
            int32_t  isdst;                      // true if zone represents DST time
            Switch   type;                       // type of 'end' field
            datetime end;                        // dynamic date when this zone ends (only if hasdst=1)
        };

        uint32_t hasdst;       // does this rule have DST switching
        Zone     outer;        // always present
        Zone     inner;        // only present if hasdst=1
        int32_t  max_offset;   // max(outer.offset, inner.offset)
        int32_t  delta;        // inner.offset - outer.offset
    };

    struct Leap {
        ptime_t  time;
        uint32_t correction;
    };

    string      name;
    Transition* trans;
    uint32_t    trans_cnt;
    Transition  ltrans;              // trans[trans_cnt-1]
    Leap*       leaps;
    uint32_t    leaps_cnt;
    Rule        future;
    mutable bool is_local; // if timezone is set as local at the moment

    Timezone () {}

    void clear () {
        delete[] this->trans;
        if (this->leaps_cnt > 0) delete[] this->leaps;
    }

    ~Timezone () { clear(); }
};

}}

