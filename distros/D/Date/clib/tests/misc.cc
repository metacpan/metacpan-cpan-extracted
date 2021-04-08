#include "test.h"

#define TEST(name) TEST_CASE("misc: " name, "[misc]")

TEST("range check") {
    CHECK(!Date::range_check());
    Date date("2001-02-31");
    CHECK(!date.error());
    CHECK(date.to_string() == "2001-03-03 00:00:00");

    Date::range_check(true);
    CHECK(Date::range_check());

    date = Date("2001-02-31");
    CHECK(date.error() == errc::out_of_range);
    CHECK(!date.to_string());
}
