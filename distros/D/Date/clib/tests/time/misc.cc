#include "../test.h"

#define TEST(name) TEST_CASE("time-misc: " name, "[time-misc]")

TEST("some border cases") {
    auto utc_tz = tzget("UTC");
    SECTION("28-Dec-2018") {
        datetime date;
        REQUIRE(anytime(1545987968, &date, utc_tz));
        REQUIRE(date.sec == 8);
        REQUIRE(date.min == 6);
        REQUIRE(date.hour == 9);
        REQUIRE(date.mday == 28);
        REQUIRE(date.mon == 11);
        REQUIRE(date.yday == 361);
        REQUIRE(date.year == 2018);
    }

    SECTION("negative boundary") {
        datetime date;
        REQUIRE(anytime(EPOCH_MIN - 1, &date, utc_tz) == false);
        REQUIRE(anytime(EPOCH_MIN, &date, utc_tz) == true);
        REQUIRE(date.sec == 0);
        REQUIRE(date.min == 0);
        REQUIRE(date.hour == 0);
        REQUIRE(date.mday == 2);
        REQUIRE(date.mon == 0);
        REQUIRE(date.year == -2147483648);
    }

    SECTION("positive boundary") {
        datetime date;
        REQUIRE(anytime(EPOCH_MAX + 1, &date, utc_tz) == false);
        REQUIRE(anytime(EPOCH_MAX, &date, utc_tz) == true);
        REQUIRE(date.sec == 59);
        REQUIRE(date.min == 59);
        REQUIRE(date.hour == 23);
        REQUIRE(date.mday == 30);
        REQUIRE(date.mon == 11);
        REQUIRE(date.year == 2147483647);
    }
}

TEST("tzget_abbr") {
    SECTION("MSK") {
        auto tz = tzget_abbr("MSK");
        CHECK(tz->name == "<+03:00>-03:00");
        CHECK(tz->future.outer.gmt_offset == 3 * 3600);
    }
    SECTION("EEST") {
        auto tz = tzget_abbr("EEST");
        CHECK(tz->name == "<+02:00>-02:00");
        CHECK(tz->future.outer.gmt_offset == 2 * 3600);
    }
    SECTION("non-existing tz") {
        auto tz = tzget_abbr("zzzzz");
        CHECK(tz->name == "GMT0");
        CHECK(tz->future.outer.offset >= 0);
    }
}
