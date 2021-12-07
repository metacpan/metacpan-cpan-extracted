#include <cstdlib>
#include <panda/time.h>
#include <panda/date.h>
#include <panda/unordered_string_map.h>
#include <catch2/catch_test_macros.hpp>

using namespace panda;
using namespace panda::date;
using namespace panda::time;

#define X64ONLY if (sizeof(ptime_t) < 8) return

static inline void is_approx (double testv, double v) {
    CHECK(abs(testv - v) < (double)0.000001);
}

struct TestMoment {
    ptime_t  epoch;
    datetime dt;
};

unordered_string_map<string, std::vector<TestMoment>> get_dates (string_view dataset);

void CHECK_DATETIME (const datetime&, const datetime&);
void CHECK_DATETIME (const datetime&, int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst = -1, int32_t wday = -1, int32_t yday = -1);
void CHECK_LOCALTIME (ptime_t epoch, const datetime&);
void CHECK_LOCALTIME (ptime_t epoch, int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst = -1, int32_t wday = -1, int32_t yday = -1);

inline datetime mkdt (int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst = -1, int32_t wday = -1, int32_t yday = -1) {
    datetime ret;
    ret.year = year;
    ret.mon = mon;
    ret.mday = mday;
    ret.hour = hour;
    ret.min = min;
    ret.sec = sec;
    ret.isdst = isdst;
    ret.wday = wday;
    ret.yday = yday;
    ret.n_zone = 0;
    return ret;
}

inline bool operator== (const datetime& d1, const datetime& d2) {
    return d1.sec == d2.sec && d1.min == d2.min && d1.hour == d2.hour && d1.mday == d2.mday && d1.mon == d2.mon && d1.year == d2.year &&
           d1.wday == d2.wday && d1.yday == d2.yday && d1.isdst == d2.isdst && d1.n_zone == d2.n_zone;
}
