#include "../test.h"
#include <unordered_set>

static ptime_t epoch_from (int32_t year, ptime_t mon = 1, ptime_t mday = 1, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0) {
    auto dt = mkdt(year, mon-1, mday, hour, min, sec);
    return timegm(&dt);
}

// if step == 0 => random check, from is DIA (+- from 1970), till is ITERS COUNT
static bool test_forward (ptime_t step, ptime_t from, ptime_t till, string_view tzname, bool (*libfunc)(ptime_t, datetime*), struct tm* (*sysfunc)(const time_t*, struct tm*)) {
    datetime date1;
    struct tm date2;

    char* hstr = getenv("VERBOSE");
    bool verbose = (hstr != NULL && strlen(hstr) > 0);

    static bool sranded = false;
    if (!sranded) {
        srand(::time(NULL));
        sranded = true;
    }

    bool isrand = false;
    ptime_t disperse = 0, epoch;
    if (step == 0) {
        isrand = true;
        disperse = from;
        step = 1;
        from = 0;
    }

    int cnt = 0;
    for (ptime_t i = from; i < till; i += step) {
        cnt++;
        memset(&date1, 0, sizeof(date1));
        memset(&date2, 0, sizeof(date2));

        if (isrand) epoch = (((uint64_t)rand())*((uint64_t)rand())) % (2*disperse) - disperse;
        else epoch = i;
        time_t sys_epoch = (time_t) epoch;


        libfunc(epoch, &date1);
        sysfunc(&sys_epoch, &date2);

        if (verbose && !(cnt % 100000)) printf("TESTED #%d, last %04i-%02i-%02i %02i:%02i:%02i (off:%ld, dst=%d, zone=%s)\n", cnt, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec, date2.tm_gmtoff, date2.tm_isdst, date2.tm_zone);

        if (date1.year != (date2.tm_year + 1900) || date1.mon != date2.tm_mon || date1.mday != date2.tm_mday ||
            date1.hour != date2.tm_hour || date1.min != date2.tm_min || date1.sec != date2.tm_sec ||
            date1.isdst != date2.tm_isdst || date1.gmtoff != date2.tm_gmtoff || strcmp(date1.zone, date2.tm_zone) != 0) {
            fprintf(stderr,
                "zone=%.*s, epoch=%lli\n"
                "got       %d-%02lld-%02lld %02lld:%02lld:%02lld %d %d %d %d %s\n"
                "should be %d-%02d-%02d %02d:%02d:%02d %d %d %d %ld %s\n",
                (int)tzname.length(), tzname.data(), (long long)epoch,
                date1.year, (long long)date1.mon+1, (long long)date1.mday, (long long)date1.hour, (long long)date1.min, (long long)date1.sec,
                date1.wday, date1.yday, date1.isdst, date1.gmtoff, date1.zone,
                date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec,
                date2.tm_wday, date2.tm_yday, date2.tm_isdst, date2.tm_gmtoff, date2.tm_zone
            );
            return false;
        }
    }

    if (verbose) printf("TESTED %d TIMES\n", cnt);

    return true;
}

// if step == 0 => random check, from is DIA years (from 1910), till is ITERS COUNT
static bool test_backward (ptime_t step, ptime_t from, ptime_t till, bool (*libfuncF)(ptime_t, datetime*), ptime_t (*libfunc)(datetime*), time_t (*sysfunc)(struct tm*), bool rand_denorm) {
    datetime date1;
    struct tm date2;

    char* hstr = getenv("VERBOSE");
    bool verbose = (hstr != NULL && strlen(hstr) > 0);

    static bool sranded = false;
    if (!sranded) {
        srand(::time(NULL));
        sranded = true;
    }

    bool isrand = false;
    ptime_t disperce_years;
    if (step == 0) {
        isrand = true;
        step = 1;
        disperce_years = from;
        if (disperce_years > 200) disperce_years = 200;
        from = 0;
    }

    int cnt = 0;
    for (ptime_t i = from; step > 0 ? (i < till) : (i > till); i += step) {
        cnt++;
        memset(&date1, 0, sizeof(date1));
        memset(&date2, 0, sizeof(date2));

        if (isrand) {
            if (rand_denorm) {
                int rnum = rand();
                date1.sec = rnum % 10000 - 5000;
                rnum /= 1000;
                date1.min = rnum % 10000 - 5000;
                rnum /= 1000;
                date1.hour = rnum % 100 - 50;
                rnum = rand();
                date1.mday = rnum % 100 - 50;
                rnum /= 100;
                date1.mon = rnum % 100 - 50;
                rnum /= 100;
                date1.year = (rnum % disperce_years) + 1910;
            } else {
                int rnum = rand();
                date1.sec = rnum % 60;
                rnum /= 1000;
                date1.min = rnum % 60;
                rnum /= 1000;
                date1.hour = rnum % 24;
                rnum = rand();
                date1.mday = rnum % 31 + 1;
                rnum /= 100;
                date1.mon = rnum % 11;
                rnum /= 100;
                date1.year = (rnum % disperce_years) + 1910;
            }
        }
        else {
            libfuncF(i, &date1);
        }

        date1.isdst = -1;

        auto dt2tm = [](tm& to, const datetime& from) {
            to.tm_sec    = from.sec;
            to.tm_min    = from.min;
            to.tm_hour   = from.hour;
            to.tm_mday   = from.mday;
            to.tm_mon    = from.mon;
            to.tm_year   = from.year-1900;
            to.tm_isdst  = from.isdst;
            to.tm_wday   = from.wday;
            to.tm_yday   = from.yday;
            to.tm_gmtoff = from.gmtoff;
            to.tm_zone   = const_cast<char*>(from.zone);
        };
        dt2tm(date2, date1);

        datetime copy1 = date1;
        struct tm copy2 = date2;

        auto mytime   = libfunc(&date1);
        auto truetime = sysfunc(&date2);

        if (verbose && !(cnt % 100000)) printf("TESTED #%d, last %04d-%02d-%02d %02d:%02d:%02d\n", cnt, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec);

        bool same_ymdhms = (date1.year != (date2.tm_year + 1900) || date1.mon != date2.tm_mon || date1.mday != date2.tm_mday || date1.hour != date2.tm_hour || date1.min != date2.tm_min || date1.sec != date2.tm_sec) ? false : true;
        bool same_zone = (date1.isdst != date2.tm_isdst || date1.gmtoff != date2.tm_gmtoff || strcmp(date1.zone, date2.tm_zone) != 0) ? false : true;
        bool same_date = same_ymdhms && same_zone;

        if (mytime != truetime || !same_date) {
            if (truetime == -1) continue; // OS cannot handle such dates

            if (same_ymdhms) { // if ambiguity, OS may return unpredicted results. Lets handle that.
                datetime tmpdate = date1;
                tmpdate.isdst = 1;
                mytime = libfunc(&tmpdate);
                if (mytime == truetime) continue;
            }

            fprintf(stderr,
                "MY: epoch=%lli (%04d/%02lld/%02lld %02lld:%02lld:%02lld %4s %d) from %04d/%02lld/%02lld %02lld:%02lld:%02lld DST=%d (%.*s)\n",
                (long long)mytime,
                date1.year, (long long)date1.mon+1, (long long)date1.mday, (long long)date1.hour, (long long)date1.min, (long long)date1.sec,
                date1.zone, date1.gmtoff,
                copy1.year, (long long)copy1.mon+1, (long long)copy1.mday, (long long)copy1.hour, (long long)copy1.min, (long long)copy1.sec,
                copy1.isdst, (int)tzlocal()->name.length(), tzlocal()->name.data()
            );
            fprintf(stderr,
                "OS: epoch=%li (%04d/%02d/%02d %02d:%02d:%02d %4s %ld) from %04d/%02d/%02d %02d:%02d:%02d DST=%d (%.*s)\n",
                truetime, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec, date2.tm_zone, date2.tm_gmtoff,
                copy2.tm_year+1900, copy2.tm_mon+1, copy2.tm_mday, copy2.tm_hour, copy2.tm_min, copy2.tm_sec, copy2.tm_isdst, (int)tzlocal()->name.length(), tzlocal()->name.data()
            );
            fprintf(stderr, "diff is %lli", (long long)(mytime - truetime));
            return false;
        }
    }

    if (verbose) printf("TESTED %d TIMES\n", cnt);

    return true;
}

static bool test_gmtime    (ptime_t step, ptime_t from, ptime_t till) { return test_forward(step, from, till, "GMT", &panda::time::gmtime, &::gmtime_r); }
static bool test_timegm    (ptime_t step, ptime_t from, ptime_t till) { return test_backward(step, from, till, &panda::time::gmtime, &panda::time::timegm, &::timegm, true); }
static bool test_localtime (ptime_t step, ptime_t from, ptime_t till) { return test_forward(step, from, till, tzlocal()->name, &panda::time::localtime, &::localtime_r); }
// dont test denormalized values (LINUX has bugs with them + when using leap seconds zone, our normalization may differ with OS)
static bool test_timelocal (ptime_t step, ptime_t from, ptime_t till) { return test_backward(step, from, till, &panda::time::localtime, &panda::time::timelocal, &::timelocal, false); }

struct Dia {
    ptime_t step;
    ptime_t from;
    ptime_t till;
};
using Dias = std::vector<Dia>;

TEST_CASE("full-gmtime", "[.]") {
    X64ONLY;
    CHECK(test_gmtime(  299, epoch_from( 2005),       epoch_from(2008,12,30))); // check normal times
    CHECK(test_gmtime(    1, epoch_from( 2004,12,31), epoch_from(2005)));       // check QUAD YEARS threshold
    CHECK(test_gmtime(    1, epoch_from( 1900,12,31), epoch_from(1901)));       // check CENT YEARS threshold
    CHECK(test_gmtime(    1, epoch_from( 2000,12,31), epoch_from(2001)));       // check QUAD CENT YEARS threshold
    CHECK(test_gmtime(86399, epoch_from(-1000),       epoch_from(2014)));       // negative check
    // random check
    CHECK(test_gmtime(0,  1500000000, 1000000));
    CHECK(test_gmtime(0, 20000000000, 1000000));
}

TEST_CASE("full-timegm", "[.]") {
    X64ONLY;
    CHECK(test_timegm( 299, epoch_from(2005),       epoch_from(2008,12,30))); // check normal times
    CHECK(test_timegm(   1, epoch_from(2004,12,31), epoch_from(2005)));       // check QUAD YEARS threshold
    CHECK(test_timegm(   1, epoch_from(1900,12,31), epoch_from(1901)));       // check CENT YEARS threshold
    CHECK(test_timegm(   1, epoch_from(2000,12,31), epoch_from(2001)));       // check QUAD CENT YEARS threshold
    CHECK(test_timegm(9999, epoch_from(1900),       epoch_from(2014)));       // negative check, system's timegm cannot handle 1899-12-31 23:59:59 and earlier
    // random check
    CHECK(test_timegm(0, 200, 200000));
    CHECK(test_timegm(0, 200, 200000));
}

TEST_CASE("full-localtime", "[.]") {
    X64ONLY;
    auto old = tzdir();
    use_system_timezones();

    for (auto tzname : {"Europe/Moscow", "America/New_York", "Australia/Melbourne"}) {
        setenv("TZ", tzname, 1);
        panda::time::tzset();
        ::tzset();

        // check past
        CHECK(test_localtime(39, epoch_from(1879), epoch_from(1881)));
        // check transitions
        CHECK(test_localtime(299, epoch_from(1980), epoch_from(1986)));
        CHECK(test_localtime(299, epoch_from(2000), epoch_from(2006)));
        CHECK(test_localtime(59, epoch_from(2000), epoch_from(2001)));
        // check near future
        CHECK(test_localtime(59, epoch_from(2016), epoch_from(2022)));
        // check far future
        CHECK(test_localtime(299, epoch_from(2060), epoch_from(2066)));
        CHECK(test_localtime(59, epoch_from(2066), epoch_from(2067)));
        // negative check
        CHECK(test_localtime(59, epoch_from(-1000), epoch_from(-999)));
        // random check
        CHECK(test_localtime(0, 1500000000, 1000000));
        CHECK(test_localtime(0, 20000000000, 1000000));
    }

    unsetenv("TZ");
    tzdir(old);
}

TEST_CASE("full-timelocal", "[.]") {
    X64ONLY;
    auto old = tzdir();
    use_system_timezones();

    // Europe/Moscow disabled - system's timelocal has a lot of bugs with non-standart transitions which occur in Moscow
    for (auto tzname : {"America/New_York", "Australia/Melbourne"}) {
        setenv("TZ", tzname, 1);
        panda::time::tzset();
        ::tzset();

        // check past - unavailable, system's timelocal cannot work with these dates
        // check transitions
        CHECK(test_timelocal(86399, epoch_from(1910), epoch_from(1986)));
        CHECK(test_timelocal(3599, epoch_from(1980), epoch_from(1986)));
        CHECK(test_timelocal(3599, epoch_from(2000), epoch_from(2006)));
        CHECK(test_timelocal(3599, epoch_from(2006), epoch_from(2011)));
        // check near future
        CHECK(test_timelocal(3599, epoch_from(2016), epoch_from(2022)));
        // check far future
        CHECK(test_timelocal(3599, epoch_from(2060), epoch_from(2066)));
        // random check
        CHECK(test_timelocal(0, 200, 400000));
    }

    unsetenv("TZ");
    tzdir(old);
}

TEST_CASE("full-leapzone", "[.]") {
    X64ONLY;
    auto old = tzdir();
    use_system_timezones();

    Dias dias = {
        // check past - unavailable, OS's timelocal cannot work with these dates
        // check transitions
        {86399, epoch_from(1910), epoch_from(1970)},
        {3599, epoch_from(1980), epoch_from(1986)},
        {3599, epoch_from(2000), epoch_from(2006)},
        {3599, epoch_from(2006), epoch_from(2011)},
        // check near future
        {3599, epoch_from(2016), epoch_from(2022)},
        // check far future
        {3599, epoch_from(2060), epoch_from(2066)},
        // leap moments
        {1, epoch_from(1981,06,30,12,00,00), epoch_from(1981,07,01,12,00,00)},
        {1, epoch_from(1982,06,30,12,00,00), epoch_from(1982,07,01,12,00,00)},
        {1, epoch_from(1983,06,30,12,00,00), epoch_from(1983,07,01,12,00,00)},
        {1, epoch_from(1985,06,30,12,00,00), epoch_from(1985,07,01,12,00,00)},
        {1, epoch_from(1987,12,31,12,00,00), epoch_from(1988,01,01,12,00,00)},
        {1, epoch_from(1989,12,31,12,00,00), epoch_from(1990,01,01,12,00,00)},
        {1, epoch_from(1990,12,31,12,00,00), epoch_from(1991,01,01,12,00,00)},
        {1, epoch_from(1992,06,30,12,00,00), epoch_from(1992,07,01,12,00,00)},
        {1, epoch_from(1993,06,30,12,00,00), epoch_from(1993,07,01,12,00,00)},
        {1, epoch_from(1994,06,30,12,00,00), epoch_from(1994,07,01,12,00,00)},
        {1, epoch_from(1995,12,31,12,00,00), epoch_from(1996,01,01,12,00,00)},
        {1, epoch_from(1997,06,30,12,00,00), epoch_from(1997,07,01,12,00,00)},
        {1, epoch_from(1998,12,31,12,00,00), epoch_from(1999,01,01,12,00,00)},
        {1, epoch_from(2005,12,31,12,00,00), epoch_from(2006,01,01,12,00,00)},
        {1, epoch_from(2008,12,31,12,00,00), epoch_from(2009,01,01,12,00,00)},
        {1, epoch_from(2012,06,30,12,00,00), epoch_from(2012,07,01,12,00,00)}
    };

    for (auto tzname : {"right/UTC", "right/America/New_York", "right/Australia/Melbourne"}) {
        DYNAMIC_SECTION(tzname) {
            setenv("TZ", tzname, 1);
            panda::time::tzset();
            ::tzset();
            if (tzlocal()->name != tzname) {
                WARN("SKIPPED, leap zone " << tzname << " not found in system");
                continue;
            }

            for (auto& dia : dias) {
                INFO("step=" << dia.step << ", from=" << dia.from << ", till=" << dia.till);
                CHECK(test_localtime(dia.step, dia.from, dia.till));
                CHECK(test_timelocal(dia.step, dia.from, dia.till));
            }

            // random check
            CHECK(test_localtime(0, 1500000000, 5000000));
            CHECK(test_timelocal(0, 120, 1000000));
        }
    }

    unsetenv("TZ");
    tzdir(old);
}

static void test_all_zones (int part) {
    const int parts = 9;
    X64ONLY;
    auto old = tzdir();
    use_system_timezones();

    // many OS have bugs in localtime/timelocal implementations which prevent them from working correctly with listed time zones in our time periods
    std::unordered_set<string> buggy_zones {
        "America/Anchorage", "Australia/Lord_Howe", "America/Scoresbysund", "America/Nome", "Asia/Choibalsan", "Asia/Ust-Nera",
        "Asia/Tehran", "posix/Iran", "posix/Asia/Tehran", "Iran"
    };

    auto tzlist = available_timezones();
    std::sort(tzlist.begin(), tzlist.end(), [](auto a, auto b) { return a < b; });

    for (size_t i = part-1; i < tzlist.size(); i += parts) {
        auto tzname = tzlist[i];
        if (buggy_zones.count(tzname)) continue;
        if (tzname.find("posix") == 0) continue;
        bool leapzone = tzname.find("right") == 0;

        setenv("TZ", tzname.c_str(), 1);
        panda::time::tzset();
        ::tzset();

        DYNAMIC_SECTION(tzname) {
            // check past
            CHECK(test_localtime(3599, epoch_from(1980), epoch_from(1986)));
            CHECK(test_timelocal(3599, epoch_from(1980), epoch_from(1986)));
            // check transitions
            CHECK(test_localtime(3599, epoch_from(2000), epoch_from(2006)));
            CHECK(test_timelocal(3599, epoch_from(2000), epoch_from(2006)));
            // check near future
            CHECK(test_localtime(3599, epoch_from(2016), epoch_from(2022)));
            CHECK(test_timelocal(3599, epoch_from(2016), epoch_from(2022)));

            // check far future
            if (!leapzone) { // skip testing future in leap second zones (OS has bugs)
                CHECK(test_localtime(3599, epoch_from(2060), epoch_from(2066)));
                CHECK(test_timelocal(3599, epoch_from(2060), epoch_from(2066)));
            }
        }
    }

    unsetenv("TZ");
    tzdir(old);
}

TEST_CASE("full-zones-1", "[.]") { test_all_zones(1); }
TEST_CASE("full-zones-2", "[.]") { test_all_zones(2); }
TEST_CASE("full-zones-3", "[.]") { test_all_zones(3); }
TEST_CASE("full-zones-4", "[.]") { test_all_zones(4); }
TEST_CASE("full-zones-5", "[.]") { test_all_zones(5); }
TEST_CASE("full-zones-6", "[.]") { test_all_zones(6); }
TEST_CASE("full-zones-7", "[.]") { test_all_zones(7); }
TEST_CASE("full-zones-8", "[.]") { test_all_zones(8); }
TEST_CASE("full-zones-9", "[.]") { test_all_zones(9); }
