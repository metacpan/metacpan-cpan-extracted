#include "../test.h"

#define TEST(name) TEST_CASE("format-clf: " name, "[format-clf]")

TEST("parse") {
    SECTION("with brackets") {
        Date d("[10/Oct/1999:21:15:05 +0500]");
        CHECK(!d.error());
        CHECK(d.epoch() == 939572105);
    }

    SECTION("without brackets") {
        Date d("10/Oct/1999:21:15:05 +0500");
        CHECK(!d.error());
        CHECK(d.epoch() == 939572105);
    }
}

TEST("stringify") {
    CHECK(Date(1999, 10, 10, 21, 15, 5, 0, 0, tzget("GMT-5:00")).to_string(Date::Format::clf) == "10/Oct/1999:21:15:05 +0500");
    CHECK(Date(1999, 10, 10, 21, 15, 5, 0, 0, tzget("GMT-5:00")).to_string(Date::Format::clfb) == "[10/Oct/1999:21:15:05 +0500]");
}
