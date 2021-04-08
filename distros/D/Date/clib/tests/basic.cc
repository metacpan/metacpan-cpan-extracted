#include "test.h"

#define TEST(name) TEST_CASE("basic: " name, "[basic]")

TEST("from zero epoch") {
    Date date(0);
    CHECK(date.epoch() == 0);
    CHECK(date.year() == 1970);
    CHECK(date.c_year() == 70);
    CHECK(date.yr() == 70);
    CHECK(date.month() == 1);
    CHECK(date.c_month() == 0);
    CHECK(date.day() == 1);
    CHECK(date.hour() == 3);
    CHECK(date.min() == 0);
    CHECK(date.sec() == 0);
    CHECK(date.to_string() == "1970-01-01 03:00:00");
}

TEST("from epoch") {
    Date date(1000000000);
    CHECK(date.to_string() == "2001-09-09 05:46:40");
    CHECK(date.c_year() == 101);
    CHECK(date.yr() == 1);
}

TEST("from date") {
    Date date(Date(1000000000));
    CHECK(date.epoch() == 1000000000);
}

TEST("from list") {
    Date date(2012,02,20,15,16,17);
    CHECK(date.to_string() == "2012-02-20 15:16:17");
    date = Date(2012,02,20,15,16);
    CHECK(date.to_string() == "2012-02-20 15:16:00");
    date = Date(2012,02,20,15);
    CHECK(date.to_string() == "2012-02-20 15:00:00");
    date = Date(2012,02,20);
    CHECK(date.to_string() == "2012-02-20 00:00:00");
}

TEST("from string") {
    Date date("2013-03-05 23:45:56");
    CHECK(date.wday() == 3);
    CHECK(date.c_wday() == 2);
    CHECK(date.ewday() == 2);
    CHECK(date.yday() == 64);
    CHECK(date.c_yday() == 63);
    CHECK(!date.isdst());

    date.set("2013-03-10 23:45:56");
    CHECK(date.wday() == 1);
    CHECK(date.c_wday() == 0);
    CHECK(date.ewday() == 7);

    tzset("Europe/Kiev");

    date = Date("2013-09-05 23:45:56");
    CHECK(date.isdst());
    CHECK(date.tzabbr() ==  "EEST");

    date = Date("2013-12-05 23:45:56");
    CHECK(!date.isdst());
    CHECK(date.tzabbr() == "EET");
}

TEST("limit formats") {
    CHECK(!Date("2013-03-05 23:45:56", {}, Date::InputFormat::all).error());
    CHECK(!Date("2013-03-05 23:45:56", {}, Date::InputFormat::iso).error());
    CHECK(!Date("2013-03-05 23:45:56", {}, Date::InputFormat::iso | Date::InputFormat::iso8601).error());
    CHECK(Date("2013-03-05 23:45:56", {}, Date::InputFormat::iso8601).error());
    CHECK(!Date("2013-03-05", {}, Date::InputFormat::iso8601).error());
    CHECK(!Date("2013-03-05", {}, Date::InputFormat::iso).error());
}

TEST("error") {
    CHECK(Date(+67767976233446399 + 1).error() == errc::out_of_range);
}

TEST("MEIACORE-728 bugfix") {
    CHECK(Date("-567815678-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date("567815678-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date("+999999999-12-31 23:59:59").error() == errc::parser_error);
    CHECK(Date("1234567890-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date("1234567890-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date("-1234567890-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date("-1234567890-12-27 02:52:56").error() == errc::parser_error);
    CHECK(Date(-1977603371737344898).error() == errc::out_of_range);
    CHECK(Date(-67768100567884800 - 1).error() == errc::out_of_range);
    CHECK(Date(+67767976233446399 + 1).error() == errc::out_of_range);
}
