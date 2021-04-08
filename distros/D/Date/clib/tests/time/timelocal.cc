#include "../test.h"

#define TEST(name) TEST_CASE("time-timelocal: " name, "[time-timelocal]")

static ptime_t _timelocall (int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst = -1) {
    auto dt = mkdt(year, mon, mday, hour, min, sec, isdst);
    return timelocall(&dt);
}

TEST("from data") {
    auto data = get_dates("local");
    for (auto& row : data) {
        tzset(row.first);
        auto& dates = row.second;
        for (auto& row : dates) {
            auto dt = row.dt;
            CHECK(timelocal(&dt)      == row.epoch);
            CHECK(timelocall(&row.dt) == row.epoch);
        }
    }
}

TEST("past") {
    CHECK(_timelocall(1876,9,30,14,13,16) == -2940149821);
}

TEST("past within first transition") {
    CHECK(_timelocall(1916,6,2,23,59,59) == -1688265018); // Auto-dst should always choose later time by default
    CHECK(_timelocall(1916,6,3,0,1,2) == -1688265017);
    CHECK(_timelocall(1916,6,3,0,1,3) == -1688265016);
}

TEST("forcing earlier/later time doesn\"t matter when no ambiguity") {
    CHECK(_timelocall(1916,6,3,0,1,2,0) == -1688265017);
    CHECK(_timelocall(1916,6,3,0,1,3,1) == -1688265016);
}

TEST("transitions") {
    CHECK(_timelocall(2004,10,21,4,20,0) == 1101000000); // standart time
    CHECK(_timelocall(2005,5,5,23,33,20) == 1118000000); // dst
}

TEST("transition jump forward") {
    CHECK(_timelocall(2005,2,27,1,59,59) == 1111877999);
    CHECK(_timelocall(2005,2,27,3,0,0) == 1111878000);
}

TEST("normalize impossible time (should be 3:30:00)") {
    auto dt = mkdt(2005,2,27,2,30,0,0);
    CHECK(timelocall(&dt) == 1111879800);
    CHECK_DATETIME(dt, 2005,2,27,2,30,0,0);
    CHECK(timelocal(&dt) == 1111879800);
    CHECK_DATETIME(dt, 2005,2,27,3,30,0,1);
    dt = mkdt(2005,2,27,3,0,-1,0);
    CHECK(timelocall(&dt) == 1111881599);
    CHECK(timelocal(&dt) == 1111881599);
    CHECK_DATETIME(dt, 2005,2,27,3,59,59,1);
}

TEST("non-standart jump forward (DST + change zone, 2hrs)") {
    auto dt = mkdt(1918,4,31,21,59,59);
    CHECK(timelocal(&dt) == -1627965080);
    dt = mkdt(1918,5,1,0,0,0);
    CHECK(timelocal(&dt) == -1627965079);
    dt = mkdt(1918,4,31,22,0,0,0);
    CHECK(timelocal(&dt) == -1627965079);
    CHECK_DATETIME(dt, 1918,5,1,0,0,0,1);
    dt = mkdt(1918,4,31,23,30,0,0);
    CHECK(timelocal(&dt) == -1627959679);
    CHECK_DATETIME(dt, 1918,5,1,1,30,0,1);
}

TEST("transition jump backward") {
    CHECK(_timelocall(2005,9,30,1,59,59) == 1130623199); // no ambiguity
    CHECK(_timelocall(2005,9,30,2,0,0) == 1130626800); // ambiguity resolved as later time
    CHECK(_timelocall(2005,9,30,2,0,0,0) == 1130626800); // ambiguity resolved as later time
    CHECK(_timelocall(2005,9,30,2,0,0,-1) == 1130626800); // ambiguity resolved as later time
    CHECK(_timelocall(2005,9,30,2,0,0,1) == 1130623200); // ambiguity resolved as ealier time
    CHECK(_timelocall(2005,9,30,2,59,59) == 1130630399); // ambiguity resolved as later time
    CHECK(_timelocall(2005,9,30,2,59,59,1) == 1130626799); // ambiguity resolved as ealier time
    CHECK(_timelocall(2005,9,30,3,0,0) == 1130630400); // no ambiguity
    CHECK(_timelocall(2005,9,30,3,0,0,1) == 1130630400); // no ambiguity
}

TEST("future static rules") {
    CHECK(_timelocall(2033,4,18,7,33,20) == 2000003600);
}

TEST("normalize") {
    X64ONLY;
    auto dt = mkdt(2070,-123,-1234,-12345,-123456,133456789,1);
    CHECK(timelocal(&dt) == 2807084629);
    CHECK(timelocall(&dt) == 2807084629);
    CHECK_DATETIME(dt, 2058,11,14,12,43,49,0);
}

TEST("future dynamic rules for northern hemisphere") {
    X64ONLY;
    tzset("America/New_York");
    datetime dt;
    SECTION("jump forward") {
        CHECK(_timelocall(2085,2,11,1,59,59) == 3635132399);
        CHECK(_timelocall(2085,2,11,1,59,59,1) == 3635132399);
        dt = mkdt(2085,2,11,2,0,0,0);
        CHECK(timelocal(&dt) == 3635132400);
        CHECK_DATETIME(dt, 2085,2,11,3,0,0,1);
        dt = mkdt(2085,2,11,2,30,0,0);
        CHECK(timelocal(&dt) == 3635134200);
        CHECK_DATETIME(dt, 2085,2,11,3,30,0,1);
        CHECK(_timelocall(2085,2,11,3,0,0) == 3635132400);
        CHECK(_timelocall(2085,2,11,3,0,0,1) == 3635132400);
    }
    SECTION("jump backward") {
        CHECK(_timelocall(2085,10,4,0,59,59) == 3655688399);
        CHECK(_timelocall(2085,10,4,0,59,59,1) == 3655688399);
        CHECK(_timelocall(2085,10,4,1,0,0) == 3655692000); // later time
        CHECK(_timelocall(2085,10,4,1,0,0,0) == 3655692000); // later time
        CHECK(_timelocall(2085,10,4,1,0,0,-1) == 3655692000); // later time
        CHECK(_timelocall(2085,10,4,1,0,0,1) == 3655688400); // earlier time
        CHECK(_timelocall(2085,10,4,1,59,59) == 3655695599); // later time
        CHECK(_timelocall(2085,10,4,1,59,59,1) == 3655691999); // earlier time
        CHECK(_timelocall(2085,10,4,2,0,0) == 3655695600);
        CHECK(_timelocall(2085,10,4,2,0,0,1) == 3655695600);
    }
    SECTION("normalize") {
        dt = mkdt(2070,-123,-1234,-12345,-123456,133456789,1);
        CHECK(timelocall(&dt) == 2807113429);
        CHECK(timelocal(&dt) == 2807113429);
        CHECK_DATETIME(dt, 2058,11,14,12,43,49,0);
    }
}

TEST("future dynamic rules for southern hemisphere") {
    X64ONLY;
    tzset("Australia/Melbourne");
    datetime dt;
    SECTION("jump backward") {
        CHECK(_timelocall(2051,3,2,1,59,59) == 2563973999);
        CHECK(_timelocall(2051,3,2,1,59,59,1) == 2563973999);
        CHECK(_timelocall(2051,3,2,2,0,0) == 2563977600); // later time
        CHECK(_timelocall(2051,3,2,2,0,0,0) == 2563977600); // later time
        CHECK(_timelocall(2051,3,2,2,0,0,-1) == 2563977600); // later time
        CHECK(_timelocall(2051,3,2,2,0,0,1) == 2563974000); // earlier time
        CHECK(_timelocall(2051,3,2,2,59,59) == 2563981199); // later time
        CHECK(_timelocall(2051,3,2,2,59,59,1) == 2563977599); // earlier time
        CHECK(_timelocall(2051,3,2,3,0,0) == 2563981200);
        CHECK(_timelocall(2051,3,2,3,0,0,1) == 2563981200);
    }
    SECTION("jump forward") {
        CHECK(_timelocall(2051,9,1,1,59,59) == 2579702399);
        CHECK(_timelocall(2051,9,1,1,59,59,1) == 2579702399);
        dt = mkdt(2051,9,1,2,0,0,0);
        CHECK(timelocall(&dt) == 2579702400);
        CHECK(timelocal(&dt) == 2579702400);
        CHECK_DATETIME(dt, 2051,9,1,3,0,0,1);
        dt = mkdt(2051,9,1,2,30,0,0);
        CHECK(timelocall(&dt) == 2579704200);
        CHECK(timelocal(&dt) == 2579704200);
        CHECK_DATETIME(dt, 2051,9,1,3,30,0,1);
        CHECK(_timelocall(2051,9,1,3,0,0) == 2579702400);
        CHECK(_timelocall(2051,9,1,3,0,0,1) == 2579702400);
    }
    SECTION("normalize") {
        dt = mkdt(2070,-123,-1234,-12345,-123456,133456789,0);
        CHECK(timelocall(&dt) == 2807055829);
        CHECK(timelocal(&dt) == 2807055829);
        CHECK_DATETIME(dt, 2058,11,14,12,43,49,1);
    }
}

TEST("virtual zones") {
    auto dt = mkdt(2014,0,16,17,18,0);
    tzset("GMT-9");
    CHECK(timelocal(&dt) == 1389860280);
    tzset("GMT9");
    CHECK(timelocal(&dt) == 1389925080);
    tzset("GMT+9");
    CHECK(timelocal(&dt) == 1389925080);
}
