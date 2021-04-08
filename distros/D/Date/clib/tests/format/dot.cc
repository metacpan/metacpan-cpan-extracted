#include "../test.h"

#define TEST(name) TEST_CASE("format-dot: " name, "[format-dot]")

TEST("parse") {
    SECTION("DD.MM.YYYY") {
        Date d("05.12.2019");
        CHECK(!d.error());
        CHECK(d.epoch() == 1575493200);
    }

    SECTION("bad") {
        CHECK(Date("2019.12.05").error());
        CHECK(Date("20.12.05").error());
    }
}

TEST("stringify") {
    CHECK(Date(2019, 12, 9, 1, 1, 1).to_string(Date::Format::dot) == "09.12.2019");
}
