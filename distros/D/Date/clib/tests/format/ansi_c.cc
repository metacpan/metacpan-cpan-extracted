#include "../test.h"

#define TEST(name) TEST_CASE("format-ansi_c: " name, "[format-ansi_c]")

static void test (std::string name, string_view str, ptime_t epoch, string_view tzabbr) {
    SECTION(name) {
        Date d(str);
        CHECK(!d.error());
        CHECK(d.epoch() == epoch);
        CHECK(d.tzabbr() == tzabbr);
    }
}

TEST("parse") {
    test("Jan", "Tue Jan 01 03:04:00 2019", Date("2019-01-01 03:04").epoch(), "MSK");
    test("Feb", "Fri Feb 01 03:04:00 2019", Date("2019-02-01 03:04").epoch(), "MSK");
    test("Mar", "Fri Mar 01 03:04:00 2019", Date("2019-03-01 03:04").epoch(), "MSK");
    test("Apr", "Mon Apr 01 03:04:00 2019", Date("2019-04-01 03:04").epoch(), "MSK");
    test("May", "Wed May 01 03:04:00 2019", Date("2019-05-01 03:04").epoch(), "MSK");
    test("Jun", "Sat Jun 01 03:04:00 2019", Date("2019-06-01 03:04").epoch(), "MSK");
    test("Jul", "Mon Jul  1 03:04:00 2019", Date("2019-07-01 03:04").epoch(), "MSK");
    test("Aug", "Thu Aug  1 03:04:00 2019", Date("2019-08-01 03:04").epoch(), "MSK");
    test("Sep", "Sun Sep  1 03:04:00 2019", Date("2019-09-01 03:04").epoch(), "MSK");
    test("Oct", "Tue Oct  1 03:04:00 2019", Date("2019-10-01 03:04").epoch(), "MSK");
    test("Nov", "Fri Nov  1 03:04:00 2019", Date("2019-11-01 03:04").epoch(), "MSK");
    test("Dec", "Sun Dec  1 03:04:00 2019", Date("2019-12-01 03:04").epoch(), "MSK");

    SECTION("bad") {
        CHECK(Date("Wed Jan 01 03:04:00 2019").error()); // wrong wday
        CHECK(Date("Huy Jan 01 03:04:00 2019").error()); // unknown wday
        CHECK(Date("Tue Jac 01 03:04:00 2019").error()); // unknown month
        CHECK(Date("Tue Jan 01 03:04:00 201").error());  // 3-digit year
        CHECK(Date("Tue Jan 01 03:04 2019").error());    // no seconds
        CHECK(Date("Jan 01 03:04:00 2019").error());     // no wday name
    }
}

TEST("stringify") {
    CHECK(Date(2019, 12, 9, 22, 7, 6).to_string(Date::Format::ansi_c) == "Mon Dec  9 22:07:06 2019");
}
