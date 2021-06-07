#include "../test.h"

#define TEST(name) TEST_CASE("time-tz: " name, "[time-tz]")

#ifdef _WIN32
  #define TEST_NO_SETENV
#endif

#ifdef __FreeBSD__
  #include <osreldate.h>
  #if __FreeBSD_version <= 1201000
    #define TEST_NO_SETENV
  #endif
#endif


TEST("available timezones(embed)") {
    auto list = available_timezones();
    CHECK(list.size() == 1212);
}

TEST("available timezones(system)") {
    if (!getenv("TEST_FULL")) return;
    auto old = tzdir();
    use_system_timezones();

    auto list = available_timezones();
    CHECK(list.size() > 0);

    tzdir(old);
}

TEST("rule parsing") {
    auto wrong = [](string_view zone) {
        SECTION(string("check bad virtual zone: ") + zone) {
            CHECK(tzget(zone)->name == "GMT0");
        }
    };

    struct CheckTzRule {
        int gmt_offset = 999999;
        string_view abbrev = "";
        std::vector<int> end = {}; // <mon>, <week>, <wday>, <hour>, <min>, <sec>
        int isdst = -1;
    };

    auto check_tzrulezone = [](const Timezone::Rule::Zone& info, const CheckTzRule& chk) {
        CHECK(info.gmt_offset == chk.gmt_offset);

        if (chk.abbrev.size()) CHECK(info.abbrev == chk.abbrev);

        switch (chk.end.size()) {
            case 6 : CHECK(info.end.sec  == chk.end[5]);
            case 5 : CHECK(info.end.min  == chk.end[4]);
            case 4 : CHECK(info.end.hour == chk.end[3]);
            case 3 : CHECK(info.end.wday == chk.end[2]);
            case 2 : CHECK(info.end.yday == chk.end[1]);
            case 1 : CHECK(info.end.mon  == chk.end[0]);
            default: break;
        }

        if (chk.isdst == 1)  CHECK(info.isdst);
        else if (!chk.isdst) CHECK(!info.isdst);
    };

    auto check = [&check_tzrulezone](string_view zname, int hasdst = -1, const CheckTzRule& outer = {}, const CheckTzRule& inner = {}) {
        SECTION(string("check virtual zone: ") + zname) {
            auto zone = tzget(zname);
            CHECK(zone->name == zname);
            CHECK(!zone->is_local);

            if (hasdst == 1)  CHECK(zone->future.hasdst);
            else if (!hasdst) CHECK(!zone->future.hasdst);

            if (outer.gmt_offset != 999999) check_tzrulezone(zone->future.outer, outer);
            if (inner.gmt_offset != 999999) check_tzrulezone(zone->future.inner, inner);
        }
    };

    wrong("A");
    wrong("MSK");
    check("MSK-1", 0, {3600});
    check("MSK2", 0, {-7200});
    check("MSK+3", 0, {-10800});
    check("MSK-4MSD", 0, {14400});
    wrong("MSK-4:");
    check("MSK-4:20", 0, {15600});
    wrong("MSK-4:20:");
    check("MSK-4:20:08", 0, {15608});
    wrong("MSK-4:20:01:");
    check("MSK-4:20:08MSA", 0, {15608});
    wrong("MSK-4MSD,");
    wrong("MSK-4MSD,asdfdasfds");
    wrong("MSK-4MSD,M3.1.0");
    wrong("MSK-4MSD,M3.1.0,M10.5.0,");
    check("MSK-4MSD,M3.1.0,M10.5.0", 1, {14400, "MSK", {2,1,0,2,0,0}, 0}, {18000, "MSD", {9,5,0,2,0,0}, 1});
    check("MSK-4MSD,M3.1.0,M10.5.0/3", 1, {14400, "MSK", {2,1,0,2,0,0}, 0}, {18000, "MSD", {9,5,0,3,0,0}, 1});
    check("MSK-4MSD,M3.1.0,M10.5.0/3:15", 1, {14400, "MSK", {2,1,0,2,0,0}, 0}, {18000, "MSD", {9,5,0,3,15,0}, 1});
    check("MSK-4MSD,M3.1.0,M10.5.0/3:15:02", 1, {14400, "MSK", {2,1,0,2,0,0}, 0}, {18000, "MSD", {9,5,0,3,15,2}, 1});
    check("MSK-4MSD,M3.1.0/1,M10.5.0/3:15:02", 1, {14400, "MSK", {2,1,0,1,0,0}, 0}, {18000, "MSD", {9,5,0,3,15,2}, 1});
    check("MSK-4MSD,M3.1.0/1:59,M10.5.0/3:15:02", 1, {14400, "MSK", {2,1,0,1,59,0}, 0}, {18000, "MSD", {9,5,0,3,15,2}, 1});
    check("MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:02", 1, {14400, "MSK", {2,1,0,1,59,58}, 0}, {18000, "MSD", {9,5,0,3,15,2}, 1});
    wrong("MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:02:");
    wrong("MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:");
    wrong("MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:");
    wrong("MSK-4MSD,M3.1.0/1:59:58,M10.5.0/");
    wrong("MSK-4MSD,M3.1.0/1:59:,M10.5.0");
    wrong("MSK-4MSD,M3.1.0/1:,M10.5.0");
    wrong("MSK-4MSD,M3.1.0/,M10.5.0");
    check("MSK-4MSD,M3.1.0/-1,M10.5.0");
    wrong("MSK-4MSD,M3.0.0,M10.5.0");
    wrong("MSK-4MSD,M3.6.0,M10.5.0");
    wrong("MSK-4MSD,M3.0.0,M13.5.0");
    wrong("MSK-4MSD,M3.0.0,M0.5.0");
    wrong("MSK-4MSD,M3.1.-1,M0.5.0");
    wrong("MSK-4MSD,M3.1.7,M0.5.0");
    wrong("MSK-4-5");
    check("<MSK-4>-5", 0, {18000, "MSK-4"});
    wrong(":MSK-4");
    wrong("MS1K-4");
    wrong("SK-4");
}

TEST("timezones parsing") {
    auto list = available_timezones();
    for (auto& zname : list) {
        auto zone = tzget(zname);
        CHECK(zone);
        CHECK(zone->name == zname);
    }
}

TEST("tzset") {
    tzset("Europe/Moscow");
    CHECK(tzlocal()->name == "Europe/Moscow");

    tzset(tzget("America/New_York"));
    CHECK(tzlocal()->name == "America/New_York");
}

#ifndef TEST_NO_SETENV 
    TEST("tzset via ENV{TZ}") {
        setenv("TZ", "Europe/Moscow", 1);
        panda::time::tzset();
        CHECK(tzlocal()->name == "Europe/Moscow");

        setenv("TZ", "America/New_York", 1);
        panda::time::tzset();
        CHECK(tzlocal()->name == "America/New_York");

        unsetenv("TZ");
        panda::time::tzset();
        CHECK(tzlocal()->name);
    }
#endif


TEST("tzdir") {
    auto now = ::time(NULL);
    tzset("Europe/Moscow");
    CHECK(tzlocal()->name == "Europe/Moscow");
    auto date1 = localtime(now);
    tzset("America/New_York");
    CHECK(tzlocal()->name == "America/New_York");
    auto date2 = localtime(now);

    auto old = tzdir();
    tzdir("tests/time/testzones");

    CHECK(available_timezones().size() == 2);

    tzset("Moscow");
    CHECK(tzlocal()->name == "Moscow");
    CHECK_DATETIME(localtime(now), date1);
    CHECK(timelocal(&date1) == now);

    tzset("New_York");
    CHECK(tzlocal()->name == "New_York");
    CHECK_DATETIME(localtime(now), date2);
    CHECK(timelocal(&date2) == now);

    tzdir(old);
}
