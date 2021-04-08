#include "test.h"

#define TEST(name) TEST_CASE("advanced: " name, "[advanced]")

TEST("to_string") {
    Date date("2013-09-05 13:14:15.123456+02");
    CHECK(date.to_string(Date::Format::hms) == "13:14:15");
}

TEST("mksec") {
    Date date("2013-09-05 13:14:15.123456+02");
    CHECK(date.mksec() == 123456);
}

TEST("gmtoff") {
    Date date("2013-09-05 13:14:15.123456+02");
    CHECK(date.gmtoff() == 2 * 3600);

    date = Date("2013-09-05 23:04:05");
    CHECK(date.gmtoff() == 14400);

    tzset("America/New_York");
    date = Date("2013-09-05 23:45:56");
    CHECK(date.gmtoff() == -14400);
}

TEST("month days") {
    Date date("2013-09-05 03:04:05");
    CHECK(date.month_begin_new().to_string() == "2013-09-01 03:04:05");
    CHECK(date.month_end_new().to_string() == "2013-09-30 03:04:05");
    CHECK(date.days_in_month() == 30);

    date = Date("2013-08-05 03:04:05");
    CHECK(date.month_begin_new().to_string() == "2013-08-01 03:04:05");
    CHECK(date.to_string() == "2013-08-05 03:04:05");
    CHECK(date.month_end_new().to_string() == "2013-08-31 03:04:05");
    CHECK(date.to_string() == "2013-08-05 03:04:05");
    CHECK(date.days_in_month() == 31);
    date.month_begin();
    CHECK(date.to_string() == "2013-08-01 03:04:05");
    date.month_end();
    CHECK(date.to_string() == "2013-08-31 03:04:05");

    date = Date("2013-02-05 03:04:05");
    CHECK(date.month_begin_new().to_string() == "2013-02-01 03:04:05");
    CHECK(date.month_end_new().to_string() == "2013-02-28 03:04:05");
    CHECK(date.days_in_month() == 28);

    date = Date("2012-02-05 03:04:05");
    CHECK(date.month_begin_new().to_string() == "2012-02-01 03:04:05");
    CHECK(date.month_end_new().to_string() == "2012-02-29 03:04:05");
    CHECK(date.days_in_month() == 29);
}

TEST("now") {
    auto now = Date::now();
    CHECK(abs(now.epoch() - ::time(NULL)) <= 1);
}

TEST("today") {
    // if this will fail due to day change border, i will eat my shoes
    auto now = Date::now();
    auto date = Date::today();
    CHECK(date.year() == now.year());
    CHECK(date.month() == now.month());
    CHECK(date.day() == now.day());
    CHECK(date.hour() == 0);
    CHECK(date.min() == 0);
    CHECK(date.sec() == 0);
}

TEST("today_epoch") {
    CHECK(abs(Date::today_epoch() - Date::today().epoch()) <= 1);
}

TEST("truncate") {
    Date date("2013-01-26 06:47:29");
    auto date2 = date.truncated();
    CHECK(date.to_string() == "2013-01-26 06:47:29");
    CHECK(date2.to_string() == "2013-01-26 00:00:00");
    date.truncate();
    CHECK(date.to_string() == "2013-01-26 00:00:00");
}

TEST("set") {
    Date date(0);
    date.set(10);
    CHECK(date.to_string() == "1970-01-01 03:00:10");
    date.set("2970-01-01 03:00:10");
    CHECK(date.to_string() == "2970-01-01 03:00:10");
    date.set(2010,5,6,7,8,9);
    CHECK(date.to_string() == "2010-05-06 07:08:09");
}

TEST("strftime") {
    Date date(10);
    CHECK(date.strftime("%Y:%S") == "1970:10");
}

TEST("week_of_month") {
    // Mon Tue Wed Thu Fri Sat Sun
    //                       1   2
    //   3   4   5   6   7   8   9
    //  10  11  12  13  14  15  16
    //  17  18  19  20  21  22  23
    //  24  25  26  27  28  29  30
    //  31
    Date date("2020-08-01");
    CHECK(date.week_of_month() == 0);
    date.mday(2);
    CHECK(date.week_of_month() == 0);
    date.mday(3);
    CHECK(date.week_of_month() == 1);
    date.mday(9);
    CHECK(date.week_of_month() == 1);
    date.mday(10);
    CHECK(date.week_of_month() == 2);
    date.mday(16);
    CHECK(date.week_of_month() == 2);
    date.mday(17);
    CHECK(date.week_of_month() == 3);
    date.mday(23);
    CHECK(date.week_of_month() == 3);
    date.mday(24);
    CHECK(date.week_of_month() == 4);
    date.mday(30);
    CHECK(date.week_of_month() == 4);
    date.mday(31);
    CHECK(date.week_of_month() == 5);
}

TEST("weeks_in_year") {
    Date date("2020-01-01");
    CHECK(date.weeks_in_year() == 53);
    date.year(2019);
    CHECK(date.weeks_in_year() == 52);
    date.year(2018);
    CHECK(date.weeks_in_year() == 52);
    date.year(2017);
    CHECK(date.weeks_in_year() == 52);
    date.year(2016);
    CHECK(date.weeks_in_year() == 52);
    date.year(2015);
    CHECK(date.weeks_in_year() == 53);
    date.year(2048);
    CHECK(date.weeks_in_year() == 53);
    date.year(1998);
    CHECK(date.weeks_in_year() == 53);
}

TEST("week_of_year") {
    Date date("2020-06-19");
    CHECK(date.week_of_year() == Date::WeekOfYear{25, 2020});
    date = Date("2020-01-01");
    CHECK(date.week_of_year() == Date::WeekOfYear{1, 2020});
    date = Date("2020-12-31");
    CHECK(date.week_of_year() == Date::WeekOfYear{53, 2020});

    date = Date("2019-06-19");
    CHECK(date.week_of_year() == Date::WeekOfYear{25, 2019});
    date = Date("2019-01-01");
    CHECK(date.week_of_year() == Date::WeekOfYear{1, 2019});
    date = Date("2019-12-31");
    CHECK(date.week_of_year() == Date::WeekOfYear{1, 2020});

    date = Date("2017-01-01");
    CHECK(date.week_of_year() == Date::WeekOfYear{52, 2016});
    date = Date("2017-12-31");
    CHECK(date.week_of_year() == Date::WeekOfYear{52, 2017});
}
