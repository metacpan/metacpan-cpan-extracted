#include "../test.h"

#define TEST(name) TEST_CASE("relative-basic: " name, "[relative-basic]")

TEST("ctor") {
    SECTION("empty") {
        DateRel rel;
        CHECK(rel.sec() == 0);
        CHECK(rel.min() == 0);
        CHECK(rel.hour() == 0);
        CHECK(rel.day() == 0);
        CHECK(rel.month() == 0);
        CHECK(rel.year() == 0);
        CHECK(rel.to_string() == "");
    }

    SECTION("from list") {
        DateRel rel(1,2,3,4,5,6);
        CHECK(rel.sec() == 6);
        CHECK(rel.min() == 5);
        CHECK(rel.hour() == 4);
        CHECK(rel.day() == 3);
        CHECK(rel.month() == 2);
        CHECK(rel.year() == 1);
        CHECK(rel.to_string() == "1Y 2M 3D 4h 5m 6s");
    }

    SECTION("copy ctor") {
        DateRel rel(1,2,3,4,5,6);
        auto rel2 = rel;
        CHECK(rel2.to_string() == "1Y 2M 3D 4h 5m 6s");
    }

    SECTION("from date pair") {
        DateRel rel(Date("2012-03-02 15:47:32"), Date("2013-04-03 16:48:33"));
        CHECK(rel.to_string() == "1Y 1M 1D 1h 1m 1s");
        CHECK(rel.duration() == 34304461);
        CHECK(rel.duration() != DateRel(rel.to_string()).duration());
        CHECK(rel.from()->to_string() == "2012-03-02 15:47:32");
        CHECK(rel.till()->to_string() == "2013-04-03 16:48:33");

        rel = DateRel("2013-04-03 16:48:33", "2012-03-02 15:47:32");
        CHECK(rel.to_string() == "-1Y -1M -1D -1h -1m -1s");
        CHECK(rel.duration() == -34304461);
        CHECK(rel.from()->to_string() == "2013-04-03 16:48:33");
        CHECK(rel.till()->to_string() == "2012-03-02 15:47:32");
        CHECK(rel.duration() != DateRel(rel.to_string()).duration());
    }
}


TEST("set") {
    DateRel rel;
    SECTION("string") {
        rel = "1Y 2M 3D 4h 5m 6s";
    }
    SECTION("oth") {
        rel = DateRel("1Y 2M 3D 4h 5m 6s");
    }
    SECTION("dates") {
        rel.set("2020-01-01 00:00:00", "2021-03-04 04:05:06");
    }
    CHECK(rel.to_string() == "1Y 2M 3D 4h 5m 6s");
}

TEST("duration") {
    SECTION("without date") {
        DateRel rel(1,2,3,4,5,6);
        CHECK(rel.to_secs() == 37090322);
        CHECK(rel.to_secs() == rel.duration());
        is_approx(rel.to_mins(),   618172.033333);
        is_approx(rel.to_hours(),  10302.867222);
        is_approx(rel.to_days(),   429.286134);
        is_approx(rel.to_months(), 14.104156);
        is_approx(rel.to_years(),  1.175346);
        CHECK(rel.to_string() == "1Y 2M 3D 4h 5m 6s");
    }
    SECTION("with date") {
        DateRel rel(Date(1000000000), Date(1100000000));
        CHECK(rel.duration() == 100000000);
        CHECK(rel.to_secs() == rel.duration());
        is_approx(rel.to_mins(),   1666666.666666);
        is_approx(rel.to_hours(),  27777.777777);
        is_approx(rel.to_days(),   1157.36574);
        is_approx(rel.to_months(), 38.012191);
        is_approx(rel.to_years(),  3.167682);
        CHECK(rel.to_string() == "3Y 2M 8h 46m 40s");
    }
}

TEST("includes") {
    DateRel rel("2004-09-10", "2004-11-10");
    CHECK(rel.includes(Date("2004-09-01")) == 1);
    CHECK(rel.includes(Date("2004-09-10")) == 0);
    CHECK(rel.includes(Date("2004-10-01")) == 0);
    CHECK(rel.includes(Date("2004-11-10")) == 0);
    CHECK(rel.includes(Date(1101848400)) == -1);
    CHECK(DateRel("100s").includes(Date(123456)) == 0);
}

TEST("constants") {
    CHECK(SEC   == DateRel("1s"));
    CHECK(MIN   == DateRel("1m"));
    CHECK(HOUR  == DateRel("1h"));
    CHECK(DAY   == DateRel("1D"));
    CHECK(WEEK  == DateRel("7D"));
    CHECK(MONTH == DateRel("1M"));
    CHECK(YEAR  == DateRel("1Y"));
}

TEST("different timezones") {
    auto rel = DateRel(Date("2021-05-10T17:00:00+03:00"), Date("2021-05-10T17:00:00+03:00"));
    CHECK(rel.duration() == 0);

    rel = DateRel(Date("2021-05-10T17:00:00+04:00"), Date("2021-05-10T17:00:00+03:00"));
    CHECK(rel.duration() == 3600);

    rel = DateRel(Date("2021-05-10T17:00:00+02:00"), Date("2021-05-10T17:00:00+03:00"));
    CHECK(rel.duration() == -3600);

    rel = DateRel(Date("2021-05-10T17:00:00+02:00"), Date("2021-05-10T17:00:00", tzget("Europe/Moscow")));
    CHECK(rel.duration() == -3600);
}
