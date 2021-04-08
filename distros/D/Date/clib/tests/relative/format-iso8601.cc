#include "../test.h"

#define TEST(name) TEST_CASE("relative-format-iso8601: " name, "[relative-format-iso8601]")

TEST("iso8601 duration") {
    auto fmt = DateRel::Format::iso8601d;

    SECTION("s") {
        DateRel rel("PT6S");
        CHECK(rel.sec() == 6);
        CHECK(rel.to_secs() == 6);
        is_approx(rel.to_mins(), 0.1);
        CHECK(rel.to_string(fmt) == "PT6S");
    }

    SECTION("m") {
        DateRel rel("PT5M");
        CHECK(rel.min() == 5);
        CHECK(rel.to_secs() == 300);
        CHECK(rel.to_string(fmt) == "PT5M");
    }

    SECTION("h") {
        DateRel rel("PT2H");
        CHECK(rel.hour() == 2);
        CHECK(rel.to_secs() == 7200);
        CHECK(rel.to_string(fmt) == "PT2H");
    }

    SECTION("hms") {
        DateRel rel("PT1H1M1S");
        CHECK(rel.sec() == 1);
        CHECK(rel.min() == 1);
        CHECK(rel.hour() == 1);
        CHECK(rel.to_secs() == 3661);
        CHECK(rel.to_string(fmt) == "PT1H1M1S");
    }

    SECTION("M") {
        DateRel rel("P-9999M");
        CHECK(rel.month() == -9999);
        CHECK(rel.to_string(fmt) == "P-9999M");
    }

    SECTION("Y") {
        DateRel rel("P12Y");
        CHECK(rel.year() == 12);
        CHECK(rel.to_string(fmt) == "P12Y");
    }

    SECTION("YMDhms") {
        DateRel rel("P1Y2M3DT4H5M6S");
        CHECK(rel.sec() == 6);
        CHECK(rel.min() == 5);
        CHECK(rel.hour() ==  4);
        CHECK(rel.day() == 3);
        CHECK(rel.month() == 2);
        CHECK(rel.year() == 1);
        CHECK(rel.to_string(fmt) == "P1Y2M3DT4H5M6S");
    }

    SECTION("negative YMDhms") {
        DateRel rel("P-1Y2M-3DT-4H-5M-6S");
        CHECK(rel.sec() == -6);
        CHECK(rel.min() == -5);
        CHECK(rel.hour() == -4);
        CHECK(rel.day() == -3);
        CHECK(rel.month() == 2);
        CHECK(rel.year() == -1);
        CHECK(rel.to_string(fmt) == "P-1Y2M-3DT-4H-5M-6S");
    }

    SECTION("does not depend on from date") {
        DateRel rel("10s");
        rel.from(Date::now());
        CHECK(rel.to_string(fmt) == "PT10S");
    }
}

TEST("iso8601 interval") {
    auto fmt = DateRel::Format::iso8601i;

    SECTION("normal") {
        DateRel rel("2019-12-31T23:59:59/PT10S");
        CHECK(rel.to_string() == "10s");
        CHECK(rel.from() == Date("2019-12-31 23:59:59"));
        CHECK(rel.to_string(DateRel::Format::iso8601d) == "PT10S");
        CHECK(rel.to_string(fmt) == "2019-12-31T23:59:59+03/PT10S");
    }

    SECTION("fallbacks to duration format when no date") {
        DateRel rel("10s");
        CHECK(rel.to_string(fmt) == "PT10S");
    }
}
