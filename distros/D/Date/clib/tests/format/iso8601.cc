#include "../test.h"

#define TEST(name) TEST_CASE("format-iso8601: " name, "[format-iso8601]")

static void CHECK_YMDHMS (const Date& d, ptime_t year, ptime_t month, ptime_t day = 1, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0) {
    CHECK(std::vector<ptime_t>{d.year(), d.month(), d.day(), d.hour(), d.min(), d.sec()} == std::vector<ptime_t>{year, month, day, hour, min, sec});
}

TEST("parse") {
    SECTION("YYYY-MM-DDTHH:MM:SS+hh:mm") {
        Date a("2017-08-28T13:49:35+01:00");
        CHECK(!a.error());
        CHECK_YMDHMS(a, 2017, 8, 28, 13, 49, 35);
        CHECK(a.epoch() == 1503924575);
        CHECK(a.tzabbr() == "+01:00");
    }

    SECTION("YYYY-MM-DD") {
        Date a("2017-02-01");
        CHECK(!a.error());
        CHECK_YMDHMS(a, 2017, 2, 1, 0, 0, 0);

        a = Date("2017-14-99");
        CHECK(!a.error());
    }

    SECTION("YYYYMMDDTHHMMSS+hhmm") {
        Date d("20170828T134935+0100");
        CHECK(d.epoch() == 1503924575);
        CHECK(d.tzabbr() == "+01:00");
    }

    SECTION("YYYY-MM-DDTHH:MM:SSZ") {
        Date d("2017-08-28T13:49:35Z");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 8, 28, 13, 49, 35);
        CHECK(d.epoch() == 1503928175);
        CHECK(d.tzabbr() == "GMT");
    }

    SECTION("YYYY-MM") {
        Date d("2017-02");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 2);
        CHECK(d.tzabbr() == "MSK");
    }

    SECTION("YYYY-MM-DDTHH:MM:SS") {
        Date d("2017-01-02T03:04:05");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 1, 2, 3, 4, 5);
        CHECK(d.epoch() == 1483315445);
    }

    SECTION("YYYYMMDDTHHMMSSZ") {
        Date d("20170828T134935Z");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 8, 28, 13, 49, 35);
        CHECK(d.epoch() == 1503928175);
    }

    SECTION("YYYY-Wnn") {
        Date d("2017-W06");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 2, 6);

        d = Date("2014-W06");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2014, 2, 3);

        d = Date("2017-W01");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 1, 2);

        d = Date("2014-W01");
        CHECK(d.error());
    }

    SECTION("YYYY-Wnn-n") {
        Date d("2017-W35-3");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 8, 30);

        d = Date("2014-W45-5");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2014, 11, 7);

        d = Date("2017-W01-5");
        CHECK(!d.error());
        CHECK_YMDHMS(d, 2017, 1, 6);

        d = Date("2014-W01-2");
        CHECK(d.error());
    }

    SECTION("loyality for wrong delimiters in offset") {
        SECTION("no delimiter in non-void variant") {
            Date d("2017-08-28T13:49:35+0100");
            CHECK(d.epoch() == 1503924575);
            CHECK(d.tzabbr() == "+01:00");
        };
        SECTION("delimiter in void variant") {
            Date d("20170828T134935+01:00");
            CHECK(d.epoch() == 1503924575);
            CHECK(d.tzabbr() == "+01:00");
        };
    }
}

TEST("stringify") {
    Date d(2017, 8, 28, 13, 49, 35, 123456);
    SECTION("Format iso8601") {
        CHECK(d.to_string(Date::Format::iso8601) == "2017-08-28T13:49:35.123456+03");
    }
    SECTION("Format iso8601_notz") {
        CHECK(d.to_string(Date::Format::iso8601_notz) == "2017-08-28T13:49:35.123456");
    }
}
