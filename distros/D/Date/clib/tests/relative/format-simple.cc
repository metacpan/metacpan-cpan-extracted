#include "../test.h"

#define TEST(name) TEST_CASE("relative-format-simple: " name, "[relative-format-simple]")

static const auto fmt = DateRel::Format::simple;

TEST("s") {
    DateRel rel("6s");
    CHECK(rel.sec() == 6);
    CHECK(rel.to_secs() == 6);
    is_approx(rel.to_mins(), 0.1);
    CHECK(rel.to_string(fmt) == "6s");
    CHECK(rel.to_string(fmt) == rel.to_string());
};

TEST("m") {
    DateRel rel("5m");
    CHECK(rel.min() == 5);
    CHECK(rel.to_secs() == 300);
    CHECK(rel.to_string(fmt) == "5m");
};

TEST("h") {
    DateRel rel("2h");
    CHECK(rel.hour() == 2);
    CHECK(rel.to_secs() == 7200);
    CHECK(rel.to_string(fmt) == "2h");
};

TEST("hms") {
    DateRel rel("1s 1m 1h");
    CHECK(rel.sec() == 1);
    CHECK(rel.min() == 1);
    CHECK(rel.hour() == 1);
    CHECK(rel.to_secs() == 3661);
    CHECK(rel.to_string(fmt) == "1h 1m 1s");
};

TEST("M") {
    DateRel rel("-9999M");
    CHECK(rel.month() == -9999);
    CHECK(rel.to_string(fmt) == "-9999M");
};

TEST("Y") {
    DateRel rel("12Y");
    CHECK(rel.year() == 12);
    CHECK(rel.to_string(fmt) == "12Y");
};

TEST("W") {
    DateRel rel("2W");
    CHECK(rel.day() == 14);
    CHECK(rel.to_string(fmt) == "14D");
};

TEST("YMDhms") {
    DateRel rel("1Y 2M 3D 4h 5m 6s");
    CHECK(rel.sec() == 6);
    CHECK(rel.min() == 5);
    CHECK(rel.hour() == 4);
    CHECK(rel.day() == 3);
    CHECK(rel.month() == 2);
    CHECK(rel.year() == 1);
    CHECK(rel.to_string(fmt) == "1Y 2M 3D 4h 5m 6s");
};

TEST("negative YMDhms") {
    DateRel rel("-1Y 2M -3D -4h -5m -6s");
    CHECK(rel.sec() == -6);
    CHECK(rel.min() == -5);
    CHECK(rel.hour() == -4);
    CHECK(rel.day() == -3);
    CHECK(rel.month() == 2);
    CHECK(rel.year() == -1);
    CHECK(rel.to_string(fmt) == "-1Y 2M -3D -4h -5m -6s");
};

TEST("not changed when bound to date") {
    DateRel rel("1M");
    rel.from(Date::now());
    CHECK(rel.to_string(fmt) == "1M");
};
