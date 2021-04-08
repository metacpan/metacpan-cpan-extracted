#include "test.h"

#define TEST(name) TEST_CASE("operations: " name, "[operations]")

TEST("compare") {
    Date date(1000);
    CHECK(date > Date(0));
    CHECK(date > Date(999));
    CHECK(date >= Date(1000));
    CHECK(date < Date(1001));
    CHECK(date > Date("1970-01-01 03:16:00"));
    CHECK(date < Date("1970-01-01 03:17:00"));
    CHECK(date == Date("1970-01-01 03:16:40"));
    CHECK(date.to_string() == "1970-01-01 03:16:40");
    CHECK(Date("2013-05-06 01:02:03") < Date("2013-05-06 01:02:04"));
    CHECK(Date("2013-05-06 01:02:04") == Date("2013-05-06 01:02:04"));
    CHECK(Date("2001-09-09 05:46:40") == Date(1000000000));
    CHECK(Date("2001-09-09 05:46:40") < Date(1000000001));
    CHECK(Date("2001-09-09 05:46:40") > Date(999999999));
}

TEST("add relative date") {
    Date date("2013-01-01");

    CHECK(date + DateRel(0) == date);

    CHECK(date + DateRel(0, 0, 0, 0, 0, 10) == Date("2013-01-01 00:00:10"));
    CHECK(date + DateRel("15m 60s") == Date("2013-01-01 00:15:60"));
    CHECK(date + DateRel("23h 15m 60s") == Date("2013-01-01 23:15:60"));
    CHECK(date + DateRel("24h 15m 60s") == Date("2013-01-02 00:15:60"));
    CHECK(date + 10*DAY == Date("2013-01-11"));
    CHECK(date + MONTH == Date("2013-02-01"));
    CHECK(date + 2000*YEAR == Date("4013-01-01"));

    date += DateRel("1M");
    CHECK(date == Date("2013-02-01"));
    date += 27*DAY;
    CHECK(date == Date("2013-02-28"));
    date += DAY;
    CHECK(date == Date("2013-03-01"));
}

TEST("check ops table") {
    SECTION("+") {
        Date date("2012-03-02 15:47:32");
        CHECK(date + DateRel("1D") == Date("2012-03-03 15:47:32"));
        CHECK(DateRel("1Y 1m") + date == Date("2013-03-02 15:48:32"));
    }
    SECTION("+=") {
        Date date("2012-03-02 15:47:32");
        date += MONTH;
        CHECK(date.to_string() == "2012-04-02 15:47:32");
    }
    SECTION("-") {
        Date date("2012-03-02 15:47:32");
        CHECK(date - DateRel("1D") == Date("2012-03-01 15:47:32"));
        CHECK(date - HOUR == Date("2012-03-02 14:47:32"));
        CHECK(Date("2013-04-03 16:48:33") - date == DateRel(Date("2012-03-02 15:47:32"), Date("2013-04-03 16:48:33")));
    }
    SECTION("-=") {
        Date date("2012-03-02 15:47:32");
        date -= MONTH;
        CHECK(date.to_string() == "2012-02-02 15:47:32");
        CHECK(date+1 == Date("2012-02-02 15:47:33"));
        CHECK(date-1 == Date("2012-02-02 15:47:31"));
    }
    SECTION("<=>") {
        Date date("2012-03-02 15:47:32");
        CHECK(date > Date("2012-03-02 15:47:31"));
        CHECK(date < Date("2012-03-02 15:47:33"));
        CHECK(date > Date(1330688851));
        CHECK(date < Date(1330688853));
        CHECK(date == Date(1330688852));
    }
    SECTION("eq") {
        Date date("2012-03-02 15:47:32");
        CHECK(date != Date("2012-03-02 15:47:31"));
        CHECK(!(date == Date("2012-03-02 15:47:31")));
        CHECK(date == Date(1330688852));
        CHECK(!(date != Date(1330688852)));
    }
}
