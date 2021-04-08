#include <xs.h>
#include <xs/date.h>
#include <xs/Scope.h>
#include <panda/date.h>
#include <cstring>

using namespace xs;
using namespace panda::date;
using panda::string;
using panda::string_view;

#if !defined(_WIN32) && !defined(sun) && !defined(__sun)
    #define DATE_TEST_SYS
#endif


MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

void bench_parse (string_view str) {
    Date date;
    for (int i = 0; i < 1000; ++i) date.set(str);
}

void bench_rparse (string_view str) {
    DateRel rel;
    for (int i = 0; i < 1000; ++i) rel = str;
}

uint64_t bench_strftime (string_view format) {
    auto date = Date::now();
    RETVAL = 0;
    
    for (int i = 0; i < 1000; ++i) {
        auto res = date.strftime(format);
        RETVAL += res.length();
    }
}

uint64_t bench_tzget (string_view tz) {
    RETVAL = 0;
    for (int i = 0; i < 1000; ++i) RETVAL += (uint64_t)panda::time::tzget(tz).get();
}

void bench_hints_get () {
    for (int i = 0; i < 1000; ++i) Scope::Hints::exists(xs::date::strict_hint_name);
}

bool get_strict_hint () {
    RETVAL = Scope::Hints::exists(xs::date::strict_hint_name);
}

#ifdef DATE_TEST_SYS

Array gmtime_bench (ptime_t epoch) : ALIAS(localtime_bench=1) {
    datetime date;
    ptime_t max_epoch = epoch + 10000;
    if      (ix == 0) while(epoch++ < max_epoch) gmtime(epoch, &date);
    else if (ix == 1) while(epoch++ < max_epoch) localtime(epoch, &date);
    
    RETVAL = Array::create();
    RETVAL.push(Simple(date.sec));
    RETVAL.push(Simple(date.min));
    RETVAL.push(Simple(date.hour));
    RETVAL.push(Simple(date.mday));
    RETVAL.push(Simple(date.mon));
    RETVAL.push(Simple(date.year));
    RETVAL.push(Simple(date.wday));
    RETVAL.push(Simple(date.yday));
    RETVAL.push(Simple(date.isdst));
    RETVAL.push(Simple(date.gmtoff));
    RETVAL.push(Simple(date.zone));
}

Array posix_gmtime_bench (time_t epoch) : ALIAS(posix_localtime_bench=1) {
    struct tm date;
    time_t max_epoch = epoch + 10000;
    if      (ix == 0) while(epoch++ < max_epoch) gmtime_r(&epoch, &date);
    else if (ix == 1) while(epoch++ < max_epoch) localtime_r(&epoch, &date);

    RETVAL = Array::create();
    RETVAL.push(Simple(date.tm_sec));
    RETVAL.push(Simple(date.tm_min));
    RETVAL.push(Simple(date.tm_hour));
    RETVAL.push(Simple(date.tm_mday));
    RETVAL.push(Simple(date.tm_mon));
    RETVAL.push(Simple(date.tm_year));
    RETVAL.push(Simple(date.tm_wday));
    RETVAL.push(Simple(date.tm_yday));
    RETVAL.push(Simple(date.tm_isdst));
    RETVAL.push(Simple(date.tm_gmtoff));
    RETVAL.push(Simple(date.tm_zone));
}

ptime_t timegm_bench (ptime_t sec, ptime_t min, ptime_t hour, ptime_t mday, ptime_t mon, ptime_t year) : ALIAS(timegml_bench=1, timelocal_bench=2, timelocall_bench=3) {
    datetime date;
    date.sec = sec;
    date.min = min;
    date.hour = hour;
    date.mday = mday;
    date.mon = mon;
    date.year = year;
    date.isdst = -1;
    
    int i = 0;
    int cnt = 10000;
    RETVAL = 0;
    
    if      (ix == 0) while (i++ < cnt) RETVAL += timegm(&date);
    else if (ix == 1) while (i++ < cnt) RETVAL += timegml(&date);
    else if (ix == 2) while (i++ < cnt) RETVAL += timelocal(&date);
    else if (ix == 3) while (i++ < cnt) RETVAL += timelocall(&date);
}

time_t posix_timegm_bench (int64_t sec, int64_t min, int64_t hour, int64_t mday, int64_t mon, int64_t year) : ALIAS(posix_timelocal_bench=1) {
    struct tm date;
    date.tm_sec = sec;
    date.tm_min = min;
    date.tm_hour = hour;
    date.tm_mday = mday;
    date.tm_mon = mon;
    date.tm_year = year-1900;
    date.tm_isdst = -1;
    
    int i = 0;
    int cnt = 10000;
    RETVAL = 0;
    
    if      (ix == 0) while (i++ < cnt) RETVAL += timegm(&date);
    else if (ix == 1) while (i++ < cnt) RETVAL += timelocal(&date);
}

#endif
