#include "../test.h"
#include <regex>

#define TEST(name) TEST_CASE("format-iso: " name, "[format-iso]")

static void test (string oname, string ostr, double epoch, string_view tzabbr) {
    for (auto c : {"-", "/"}) {
        string name = oname, str = ostr;
        for (auto i : {1,1}) name.replace(name.find("-"), i, c);
        for (auto i : {1,1}) str.replace(str.find("-"), i, c);
        SECTION(name) {
            Date d(str);
            is_approx(d.epoch_mks(), epoch);
            CHECK(d.tzabbr() == tzabbr);
        }
    }
}

TEST("parse") {
    // all tests for YYYY/MM/DD as well
    test("YYYY-MM-DD",                  "2019-01-01",                   1546290000,         "MSK");
    test("YYYY-MM-DD HH:MM",            "2019-02-03 04:05",             1549155900,         "MSK");
    test("YYYY-MM-DD HH:MM:SS",         "2019-02-03 04:05:06",          1549155906,         "MSK");
    test("YYYY-MM-DD HH:MM:SS.s",       "2019-02-03 04:05:06.1",        1549155906.1,       "MSK");
    test("YYYY-MM-DD HH:MM:SS.ss",      "2019-02-03 04:05:06.22",       1549155906.22,      "MSK");
    test("YYYY-MM-DD HH:MM:SS.sss",     "2019-02-03 04:05:06.333",      1549155906.333,     "MSK");
    test("YYYY-MM-DD HH:MM:SS.ssss",    "2019-02-03 04:05:06.4444",     1549155906.4444,    "MSK");
    test("YYYY-MM-DD HH:MM:SS.sssss",   "2019-02-03 04:05:06.55555",    1549155906.55555,   "MSK");
    test("YYYY-MM-DD HH:MM:SS.ssssss",  "2019-02-03 04:05:06.666666",   1549155906.666666,  "MSK");
    test("YYYY-MM-DD HH:MM:SS.s+hh",    "2019-02-03 04:05:06.1+01",     1549163106.1,       "+01:00");
    test("YYYY-MM-DD HH:MM:SS.s-hh",    "2019-02-03 04:05:06.1-01",     1549170306.1,       "-01:00");
    test("YYYY-MM-DD HH:MM:SS.s+hh:mm", "2019-02-03 04:05:06.1+01:30",  1549161306.1,       "+01:30");
    test("YYYY-MM-DD HH:MM:SS.s-hh:mm", "2019-02-03 04:05:06.1-01:30",  1549172106.1,       "-01:30");
    test("YYYY-MM-DD HH:MM:SS.sZ",      "2019-02-03 04:05:06.1Z",       1549166706.1,       "GMT");

    SECTION("bad") {
        Date d("pizdets");
        CHECK(d.error() == errc::parser_error);

        d = Date("2017-07-HELLO");
        CHECK(d.error());
        CHECK(!d.to_string());
    }
}

TEST("stringify") {
    Date dateh(2019, 12, 9, 20, 47, 30, 55);
    Date date(2019, 12, 9, 20, 47, 30);

    SECTION("Format iso") {
        CHECK(date.to_string(Date::Format::iso) == "2019-12-09 20:47:30");
        CHECK(dateh.to_string(Date::Format::iso) == "2019-12-09 20:47:30.000055");
        CHECK(date.to_string() == date.to_string(Date::Format::iso)); // this is the default format
    }

    SECTION("Format iso_date") {
        CHECK(date.to_string(Date::Format::iso_date) == "2019-12-09");
    }

    SECTION("Format iso_tz") {
        CHECK(date.to_string(Date::Format::iso_tz) == "2019-12-09 20:47:30+03");
        CHECK(dateh.to_string(Date::Format::iso_tz) == "2019-12-09 20:47:30.000055+03");

        Date date(2019, 12, 9, 20, 47, 30, 0, -1, tzget("GMT+5:30"));
        CHECK(date.to_string(Date::Format::iso_tz) == "2019-12-09 20:47:30-05:30");
    }

    SECTION("Format ymd") {
        CHECK(date.to_string(Date::Format::ymd) == "2019/12/09");
    }

    SECTION("Format hms") {
        CHECK(dateh.to_string(Date::Format::hms) == "20:47:30");
    }
};
