#include "../test.h"

#define TEST(name) TEST_CASE("strptime: " name, "[strptime]")

static void test (string name, string_view str, string_view format,  string_view expected, string_view tz = "") {
    SECTION(name) {
        TimezoneSP zone;
        if (!tz.empty()) {zone = tzget(tz) ; }

        Date d2(expected, zone);
        Date d1 = Date::strptime(str, format);
        CHECK(d1 == d2);
        CHECK(d1.epoch() == d2.epoch());
    }
}

static void test_err(string name, string_view str, string_view format) {
    SECTION(name) {
        auto d = Date::strptime(str, format);
        CHECK(d.error());
    }
}

TEST("parse") {
    test_err("simple/error", "aaa", "bbb");

    test("simple",                   "03:04:00 2019-02-02",    "%H:%M:%S %Y-%m-%d" ,    "2019-02-02 03:04:00");
    test("simple/AM",                "03:04:00 AM 2019-02-02", "%H:%M:%S %p %Y-%m-%d",  "2019-02-02 03:04:00");
    test("simple/PM",                "03:04:00 PM 2019-02-02", "%H:%M:%S %p %Y-%m-%d",  "2019-02-02 15:04:00");
    test("simple/pm",                "03:04:00 pm 2019-02-02", "%H:%M:%S %P %Y-%m-%d",  "2019-02-02 15:04:00");
    test("simple/space",             "03:04:00 2019-02-02",    "%H:%M:%S%n%Y-%m-%d",    "2019-02-02 03:04:00");
    test("simple/no-spaces",         "03:04:002019-02-02",     "%H:%M:%S%Y-%m-%d",      "2019-02-02 03:04:00");
    test("simple/multi-spaces",      "03:04:00    2019-02-02", "%H:%M:%S %Y-%m-%d",     "2019-02-02 03:04:00");
    test("simple/%k",                "03:04:00 2019-02-02",    "%k:%M:%S%n%Y-%m-%d",    "2019-02-02 03:04:00");
    test("simple/%l",                "03:04:00 2019-02-02",    "%l:%M:%S%n%Y-%m-%d",    "2019-02-02 03:04:00");
    test("simple/%e",                "2019-02- 2",             "%Y-%m-%e" ,             "2019-02-02");
    test("percent",                  "%03:04:00 2019-02-02",   "%%%H:%M:%S %Y-%m-%d",   "2019-02-02 03:04:00");
    test("%R aka %H:%M",             "03:04:00 2019-02-02",    "%R:%S %Y-%m-%d",        "2019-02-02 03:04:00");
    test("%T aka %H:%M:%S and %y",   "03:04:00 99-02-02",      "%T %y-%m-%d",           "1999-02-02 03:04:00");
    test("%D aka %m/%d/%y",          "03:04:00 02/02/99",      "%T %D",                 "1999-02-02 03:04:00");
    test("%c aka %m/%d/%y %H:%M:%S", "02/02/99 03:04:00",      "%c",                    "1999-02-02 03:04:00");
    test("%r aka %I:%M:%S %p",       "02/02/99 03:04:00 PM",   "%D %r",                 "1999-02-02 15:04:00");
    test("%C century",               "15 02-03",               "%C %m-%d",              "1500-02-03");
    test("%j day of the year",       "032 99",                 "%j %y",                 "1999-02-01");
    test("%w week day",              "2-06-99",                "%w-%m-%y",              "1999-06-01");
    test("%A week name",             "Tue-06-99",              "%A-%m-%y",              "1999-06-01");
    //test("%A week name/2",         "Wed-06-99",              "%A-%m-%y",              "1999-06-02");
    test("%b month name",            "02-March-99",            "%d-%b-%y",              "1999-03-02");
    test("%V ISO8601 week number",   "2017-W01-5",             "%Y-W%V-%w",             "2017-01-06");
    test("%u shifted week number",   "2017-W01-5",             "%Y-W%V-%u",             "2017-01-05");
    test("%F ISO8601 %Y-%m-%d",      "2017-02-02",             "%F",                    "2017-02-02");
    test("%s epoch",                 "500000000",              "%s",                    "1985-11-05 03:53:20");

    SECTION("%W week number, Monday first day of the first week") {
        test("sunday",   "2017-W01-1",  "%Y-W%W-%w", "2017-01-02");
        test("monday",    "2018-W01-1", "%Y-W%W-%w", "2018-01-01");
        test("tuesday",   "2019-W01-1", "%Y-W%W-%w", "2019-01-07");
        test("wednesday", "2014-W01-1", "%Y-W%W-%w", "2014-01-06");
        test("thursday",  "2015-W01-1", "%Y-W%W-%w", "2015-01-05");
        test("friday",    "2016-W01-1", "%Y-W%W-%w", "2016-01-04");
        test("saturday",  "2022-W01-1", "%Y-W%W-%w", "2022-01-03");

        test("sunday+2",  "2017-W01-3", "%Y-W%W-%w", "2017-01-04");
        test("w50+5",     "2017-W50-5", "%Y-W%W-%w", "2017-12-15");
        test("w0",        "2024-W00-6", "%Y-W%W-%w", "2023-12-30");
    }

    SECTION("%U week number, Sunday first day of the first week") {
        test("sunday",   "2017-W01-1",  "%Y-W%U-%w", "2017-01-02");
        test("monday",    "2018-W01-1", "%Y-W%U-%w", "2018-01-08");
        test("tuesday",   "2019-W01-1", "%Y-W%U-%w", "2019-01-07");
        test("wednesday", "2014-W01-1", "%Y-W%U-%w", "2014-01-06");
        test("thursday",  "2015-W01-1", "%Y-W%U-%w", "2015-01-05");
        test("friday",    "2016-W01-1", "%Y-W%U-%w", "2016-01-04");
        test("saturday",  "2022-W01-1", "%Y-W%U-%w", "2022-01-03");

        test("sunday+2",  "2017-W01-3", "%Y-W%U-%w", "2017-01-04");
        test("w50+5",     "2017-W50-5", "%Y-W%U-%w", "2017-12-15");
        test("w0",        "2024-W00-6", "%Y-W%U-%w", "2024-01-06");
    }

    SECTION("%z timezone number") {
        test("+", "2021-06-10 18:19:01 +0230", "%Y-%m-%d %H:%M:%S %z", "2021-06-10 18:19:01+02:30", "+02:30");
        test("-", "2021-06-10 18:19:01 -0230", "%Y-%m-%d %H:%M:%S %z", "2021-06-10 18:19:01-02:30", "-02:30");
        test_err("tz err", "2021-06-10 18:19:01 +AAAA", "%Y-%m-%d %H:%M:%S %z");
    }

    SECTION("%Z timezone name") {
        test("abbrev",   "2021-06-10 18:19:01 MSK",          "%Y-%m-%d %H:%M:%S %Z", "2021-06-10 18:19:01", "Europe/Moscow");
        test("fullname", "2021-06-10 18:19:01 Europe/Minsk", "%Y-%m-%d %H:%M:%S %Z", "2021-06-10 18:19:01", "Europe/Minsk");
    }
}
