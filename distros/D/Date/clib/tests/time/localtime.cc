#include "../test.h"

#define TEST(name) TEST_CASE("time-localtime: " name, "[time-localtime]")

TEST("from data") {
    auto data = get_dates("local");
    for (auto& row : data) {
        tzset(row.first);
        auto& dates = row.second;
        for (auto& row : dates) CHECK_LOCALTIME(row.epoch, row.dt);
    }
}

TEST("past") {
    X64ONLY;
    CHECK_LOCALTIME(-2940149821, 1876,9,30,14,13,16,0,1,303);
}

TEST("past before first transition") {
    CHECK_LOCALTIME(-1688265018, 1916,6,2,23,59,59,0,0,183);
}

TEST("first transition") {
    CHECK_LOCALTIME(-1688265017, 1916,6,3,0,1,2,0,1,184);
    CHECK_LOCALTIME(-1688265016, 1916,6,3,0,1,3,0,1,184);
}

TEST("transition jump forward") {
    CHECK_LOCALTIME(1206831599, 2008,2,30,1,59,59,0,0,89);
    CHECK_LOCALTIME(1206831600, 2008,2,30,3,0,0,1,0,89);
}

TEST("non-standart jump forward (DST + change zone, 2hrs)") {
    CHECK_LOCALTIME(-1627965080, 1918,4,31,21,59,59,0,5,150);
    CHECK_LOCALTIME(-1627965079, 1918,5,1,0,0,0,1,6,151);
}

TEST("transition jump backward") {
    CHECK_LOCALTIME(1193525999, 2007,9,28,2,59,59,1,0,300);
    CHECK_LOCALTIME(1193526000, 2007,9,28,2,0,0,0,0,300);
    CHECK_LOCALTIME(1193529599, 2007,9,28,2,59,59,0,0,300);
    CHECK_LOCALTIME(1193529600, 2007,9,28,3,0,0,0,0,300);
}

TEST("future static rules") {
    CHECK_LOCALTIME(1401180400, 2014,4,27,12,46,40,0,2,146);
}

TEST("future dynamic rules for northern hemisphere") {
    X64ONLY;
    tzset("America/New_York");
    SECTION("jump forward") {
        CHECK_LOCALTIME(3635132399, 2085,2,11,1,59,59,0,0,69);
        CHECK_LOCALTIME(3635132400, 2085,2,11,3,0,0,1,0,69);
    }
    SECTION("jump backward") {
        CHECK_LOCALTIME(3655691999, 2085,10,4,1,59,59,1,0,307);
        CHECK_LOCALTIME(3655692000, 2085,10,4,1,0,0,0,0,307);
        CHECK_LOCALTIME(3655695599, 2085,10,4,1,59,59,0,0,307);
        CHECK_LOCALTIME(3655695600, 2085,10,4,2,0,0,0,0,307);
    }
}

TEST("future dynamic rules for southern hemisphere") {
    X64ONLY;
    tzset("Australia/Melbourne");
    SECTION("jump backward") {
        CHECK_LOCALTIME(2563977599, 2051,3,2,2,59,59,1,0,91);
        CHECK_LOCALTIME(2563977600, 2051,3,2,2,0,0,0,0,91);
        CHECK_LOCALTIME(2563981199, 2051,3,2,2,59,59,0,0,91);
        CHECK_LOCALTIME(2563981200, 2051,3,2,3,0,0,0,0,91);
    }
    SECTION("jump forward") {
        CHECK_LOCALTIME(2579702399, 2051,9,1,1,59,59,0,0,273);
        CHECK_LOCALTIME(2579702400, 2051,9,1,3,0,0,1,0,273);
    }
}

TEST("virtual zones") {
    tzset("GMT-9");
    CHECK(tzlocal()->name == "GMT-9");
    CHECK_LOCALTIME(1389860280, 2014,0,16,17,18,0,0,4,15);
    tzset("GMT9");
    CHECK_LOCALTIME(1389925080, 2014,0,16,17,18,0,0,4,15);
    tzset("GMT+9");
    CHECK_LOCALTIME(1389925080, 2014,0,16,17,18,0,0,4,15);
}
