#include "../test.h"

#define TEST(name) TEST_CASE("format-rfc850: " name, "[format-rfc850]")

static void test (string name, string_view str, ptime_t epoch, string_view tzabbr) {
    SECTION(name) {
        Date d(str);
        CHECK(!d.error());
        CHECK(d.epoch() == epoch);
        CHECK(d.tzabbr() == tzabbr);
    }
}

TEST("parse") {
    test("Jan", "Tuesday, 01-Jan-19 03:04:00 GMT",   Date("2019-01-01 03:04Z").epoch(), "GMT");
    test("Feb", "Friday, 01-Feb-19 03:04:00 GMT",    Date("2019-02-01 03:04Z").epoch(), "GMT");
    test("Mar", "Friday, 01-Mar-19 03:04:00 GMT",    Date("2019-03-01 03:04Z").epoch(), "GMT");
    test("Apr", "Monday, 01-Apr-19 03:04:00 GMT",    Date("2019-04-01 03:04Z").epoch(), "GMT");
    test("May", "Wednesday, 01-May-19 03:04:00 GMT", Date("2019-05-01 03:04Z").epoch(), "GMT");
    test("Jun", "Saturday, 01-Jun-19 03:04:00 GMT",  Date("2019-06-01 03:04Z").epoch(), "GMT");
    test("Jul", "Monday, 01-Jul-19 03:04:00 GMT",    Date("2019-07-01 03:04Z").epoch(), "GMT");
    test("Aug", "Thursday, 01-Aug-19 03:04:00 GMT",  Date("2019-08-01 03:04Z").epoch(), "GMT");
    test("Sep", "Sunday, 01-Sep-19 03:04:00 GMT",    Date("2019-09-01 03:04Z").epoch(), "GMT");
    test("Oct", "Tuesday, 01-Oct-19 03:04:00 GMT",   Date("2019-10-01 03:04Z").epoch(), "GMT");
    test("Nov", "Friday, 01-Nov-19 03:04:00 GMT",    Date("2019-11-01 03:04Z").epoch(), "GMT");
    test("Dec", "Sunday, 01-Dec-19 03:04:00 GMT",    Date("2019-12-01 03:04Z").epoch(), "GMT");


    SECTION("bad") {
        CHECK(Date("Monday, 01-Jan-19 03:04:00 GMT").error());      // wrong wday
        CHECK(Date("Epta, 01-Jan-19 03:04:00 GMT").error());        // unknown wday
        CHECK(Date("Tuesday, 01-J-2019 00:00:00 GMT").error());     // unknown month
        CHECK(Date("Tuesday, 01-Ja-2019 00:00:00 GMT").error());    // unknown month
        CHECK(Date("Tuesday, 01-Jak-2019 00:00:00 GMT").error());   // unknown month
        CHECK(Date("Tuesday, 01-Jann-2019 00:00:00 GMT").error());  // unknown month
        CHECK(Date("Tuesday, 01-Jan-2019 03:04:00 GMT").error());   // 4-digit year
        CHECK(Date("Tuesday, 01-Jan-19 03:04 GMT").error());        // no seconds
        CHECK(Date("01-Jan-2019 03:04:00 GMT").error());            // no wday name
    }
}

TEST("stringify") {
    CHECK(Date(2019, 12, 9, 22, 7, 6).to_string(Date::Format::rfc850) == "Monday, 09-Dec-19 22:07:06 +0300");
    CHECK(Date(2019, 12, 9, 22, 7, 6, 0, -1, tzget("GMT")).to_string(Date::Format::rfc850) == "Monday, 09-Dec-19 22:07:06 GMT");
}
