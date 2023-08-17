#include "../test.h"

#define TEST(name) TEST_CASE("format-rfc822_1123: " name, "[format-rfc822_1123]")

void test (std::string name, string_view str, ptime_t epoch, string_view tzabbr) {
    SECTION(name) {
        Date d(str);
        CHECK(!d.error());
        CHECK(d.epoch() == epoch);
        CHECK(d.tzabbr() == tzabbr);
    };
}

TEST("parse") {
    SECTION("DD Mon YYYY HH:MM ZZZ") {
        test("Jan", "01 Jan 2019 03:04 GMT", Date("2019-01-01 03:04Z").epoch(), "GMT");
        test("Feb", "01 Feb 2019 03:04 GMT", Date("2019-02-01 03:04Z").epoch(), "GMT");
        test("Mar", "01 Mar 2019 03:04 GMT", Date("2019-03-01 03:04Z").epoch(), "GMT");
        test("Apr", "01 Apr 2019 03:04 GMT", Date("2019-04-01 03:04Z").epoch(), "GMT");
        test("May", "01 May 2019 03:04 GMT", Date("2019-05-01 03:04Z").epoch(), "GMT");
        test("Jun", "01 Jun 2019 03:04 GMT", Date("2019-06-01 03:04Z").epoch(), "GMT");
        test("Jul", "01 Jul 2019 03:04 GMT", Date("2019-07-01 03:04Z").epoch(), "GMT");
        test("Aug", "01 Aug 2019 03:04 GMT", Date("2019-08-01 03:04Z").epoch(), "GMT");
        test("Sep", "01 Sep 2019 03:04 GMT", Date("2019-09-01 03:04Z").epoch(), "GMT");
        test("Oct", "01 Oct 2019 03:04 GMT", Date("2019-10-01 03:04Z").epoch(), "GMT");
        test("Nov", "01 Nov 2019 03:04 GMT", Date("2019-11-01 03:04Z").epoch(), "GMT");
        test("Dec", "01 Dec 2019 03:04 GMT", Date("2019-12-01 03:04Z").epoch(), "GMT");
    }

    test("DD Mon YYYY HH:MM:SS ZZZ", "24 Oct 1983 14:20:19 Z", Date("1983-10-24 14:20:19Z").epoch(), "GMT");

    SECTION("DD Mon YY HH:MM ZZZ") {
        test(">50", "24 Oct 83 00:00 UT", Date("1983-10-24 00:00:00Z").epoch(), "GMT");
        test("=50", "24 Oct 50 00:00 UT", Date("2050-10-24 00:00:00Z").epoch(), "GMT");
        test("<50", "24 Oct 49 00:00 UT", Date("2049-10-24 00:00:00Z").epoch(), "GMT");
    }

    // rfc822 does not support arbitrary tz abbrev, only limited number of values
    SECTION("zones") {
        test("Z",   "01 Jul 2019 00:00 Z",     Date("2019-07-01 00:00Z").epoch(), "GMT");
        test("UT",  "01 Jul 2019 00:00 UT",    Date("2019-07-01 00:00Z").epoch(), "GMT");
        test("GMT", "01 Jul 2019 00:00 GMT",   Date("2019-07-01 00:00Z").epoch(), "GMT");
        test("EST", "01 Dec 2019 00:00 EST",   Date("2019-12-01 00:00", tzget("EST5EDT")).epoch(), "EST");
        test("EDT", "01 Jul 2019 00:00 EDT",   Date("2019-07-01 00:00", tzget("EST5EDT")).epoch(), "EDT");
        test("CST", "01 Dec 2019 00:00 CST",   Date("2019-12-01 00:00", tzget("CST6CDT")).epoch(), "CST");
        test("CDT", "01 Jul 2019 00:00 CDT",   Date("2019-07-01 00:00", tzget("CST6CDT")).epoch(), "CDT");
        test("MST", "01 Dec 2019 00:00 MST",   Date("2019-12-01 00:00", tzget("MST7MDT")).epoch(), "MST");
        test("MDT", "01 Jul 2019 00:00 MDT",   Date("2019-07-01 00:00", tzget("MST7MDT")).epoch(), "MDT");
        test("PST", "01 Dec 2019 00:00 PST",   Date("2019-12-01 00:00", tzget("PST8PDT")).epoch(), "PST");
        test("PDT", "01 Jul 2019 00:00 PDT",   Date("2019-07-01 00:00", tzget("PST8PDT")).epoch(), "PDT");
        test("A",   "01 Jul 2019 00:00 A",     Date("2019-07-01 01:00Z").epoch(), "-01:00");
        test("M",   "01 Jul 2019 00:00 M",     Date("2019-07-01 12:00Z").epoch(), "-12:00");
        test("N",   "01 Jul 2019 00:00 N",     Date("2019-06-30 23:00Z").epoch(), "+01:00");
        test("Y",   "01 Jul 2019 00:00 Y",     Date("2019-06-30 12:00Z").epoch(), "+12:00");
        test("+xx", "01 Jul 2019 00:00 +0101", Date("2019-06-30 22:59Z").epoch(), "+01:01");
        test("-xx", "01 Jul 2019 00:00 -0101", Date("2019-07-01 01:01Z").epoch(), "-01:01");
    }

    SECTION("Wday, DD Mon YYYY HH:MM ZZZ") {
        test("Mon", "Mon, 09 Dec 2019 00:00 Z", Date("2019-12-09 00:00Z").epoch(), "GMT");
        test("Tue", "Tue, 10 Dec 2019 00:00 Z", Date("2019-12-10 00:00Z").epoch(), "GMT");
        test("Wed", "Wed, 11 Dec 2019 00:00 Z", Date("2019-12-11 00:00Z").epoch(), "GMT");
        test("Thu", "Thu, 12 Dec 2019 00:00 Z", Date("2019-12-12 00:00Z").epoch(), "GMT");
        test("Fri", "Fri, 13 Dec 2019 00:00 Z", Date("2019-12-13 00:00Z").epoch(), "GMT");
        test("Sat", "Sat, 14 Dec 2019 00:00 Z", Date("2019-12-14 00:00Z").epoch(), "GMT");
        test("Sun", "Sun, 15 Dec 2019 00:00 Z", Date("2019-12-15 00:00Z").epoch(), "GMT");
    }

    SECTION("bad") {
        CHECK(Date("01 J 2019 00:00:00 GMT").error());      // unknown month
        CHECK(Date("01 Ja 2019 00:00:00 GMT").error());     // unknown month
        CHECK(Date("01 Jak 2019 00:00:00 GMT").error());    // unknown month
        CHECK(Date("01 Jann 2019 00:00:00 GMT").error());   // unknown month
        CHECK(Date("01 Jan 2019 00:00:00 NAH").error());    // unparsable zone
        CHECK(Date("01 Jan 2019 00:00:00 +01:30").error()); // colon between tzoff hour and min
        CHECK(Date("01 Jan 2019 00:00:00 +130").error());   // 4-digit required for tzoff
        CHECK(Date("Tue, 09 Dec 2019 00:00 Z").error());    // wrong wday
        CHECK(Date("Ept, 09 Dec 2019 00:00 Z").error());    // unknown wday
        CHECK(Date("01 Jan 2019 00 GMT").error());          // no minutes
        CHECK(Date("01 Jan 201 00:00 GMT").error());        // 3-digit year
    }
}

TEST("stringify") {
    CHECK(Date(2019, 12, 9, 22, 7, 6).to_string(Date::Format::rfc1123) == "Mon, 09 Dec 2019 22:07:06 +0300");
    CHECK(Date(2019, 12, 9, 22, 7, 6, 0, -1, tzget("GMT")).to_string(Date::Format::rfc1123)== "Mon, 09 Dec 2019 22:07:06 GMT");
}
