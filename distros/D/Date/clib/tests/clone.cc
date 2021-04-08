#include "test.h"

#define TEST(name) TEST_CASE("clone: " name, "[clone]")

TEST("clone()") {
    Date date("2014-01-01 00:00:00");
    CHECK(date.timezone() == tzlocal());

    auto date2 = date;
    CHECK(date2 == date);
    CHECK(date2.timezone() == tzlocal());

    date2 = date.clone(-1, -1, -1, -1, -1, -1, -1, -1, tzget("Australia/Melbourne"));
    CHECK(date2.epoch() != date.epoch());
    CHECK(date2.to_string() == date.to_string());
    CHECK(!date2.timezone()->is_local);
    CHECK(date2.timezone()->name == "Australia/Melbourne");

    auto date3 = date2.clone(-1, -1, -1, 1, 2, 3);
    CHECK(date3.to_string() == "2014-01-01 01:02:03");
    CHECK(date3.timezone() == date2.timezone());

    date3 = date3.clone(2013, 2, 10, -1, -1, -1, -1, -1, tzget(""));
    CHECK(date3.to_string() == "2013-02-10 01:02:03");
    CHECK(date3.timezone() != date2.timezone());
    CHECK(date3.timezone() == tzlocal());

    date2 = date.clone(1700, -1, -1, -1, -1, -1, -1, -1, tzget("Europe/Kiev"));
    CHECK(date2.to_string() == "1700-01-01 00:00:00");
    CHECK(!date2.timezone()->is_local);
    CHECK(date2.timezone()->name == "Europe/Kiev");
}

TEST("newfrom") {
    Date date("2014-01-01 00:00:00", tzget("America/New_York"));
    auto date2 = Date(date);
    CHECK(date2.epoch() == date.epoch());
    CHECK(date2.to_string() == date.to_string());
    CHECK(date2.timezone() == date.timezone());
}
