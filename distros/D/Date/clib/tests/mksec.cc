#include "test.h"
#include <cstdlib>
#include <chrono>
#include <thread>

#define TEST(name) TEST_CASE("mksec: " name, "[mksec]")

TEST("zero ctor") {
    Date date(0);
    CHECK(date.epoch() == 0);
    CHECK(date.mksec() == 0);
    CHECK(date.to_string() == "1970-01-01 03:00:00");
}

TEST("billion ctor") {
    Date date(1000000000);
    CHECK(date.to_string() == "2001-09-09 05:46:40");
    CHECK(date.mksec() == 0);
    CHECK(date.epoch() == 1000000000);
}

TEST("double & string ctors") {
    Date date(1000000000.000001);
    is_approx(date.epoch_mks(), 1000000000.000001);
    CHECK(date.to_string() == "2001-09-09 05:46:40.000001");
    CHECK(date.to_string() != "2001-09-09 05:46:40");
    CHECK(date == Date("2001-09-09 05:46:40.000001"));
    CHECK(date.c_year() == 101);
    CHECK(date.yr() == 1);
    CHECK(date.mksec() == 1);
    CHECK(date.epoch() == 1000000000);
    date = Date(date);
    is_approx(date.epoch_mks(), 1000000000.000001);
}

TEST("list ctor") {
    Date date(2018, 6, 27, 22, 12, 20, 340230);
    is_approx(date.epoch_mks(), 1530126740.34023);
    CHECK(date.mksec() == 340230);
}

TEST("relations") {
    Date d1("2001-09-09 05:46:40");
    Date d2("2001-09-09 05:46:40.01");
    CHECK(d2.mksec() == 10000);
    CHECK(d1 < d2);
    CHECK(d2 > d1);
    d1 = Date("2001-09-09 05:46:40.01");
    CHECK(d1 == d2);
}

TEST("assignment") {
    Date date(1);
    date.epoch(1000000000.000001);
    is_approx(date.epoch_mks(), 1000000000.000001);
    date.set("2001-09-09 05:46:40.000002");
    is_approx(date.epoch_mks(), 1000000000.000002);
    Date d1("2001-09-09 05:46:40");
    date.set(d1);
    CHECK(date == d1);

    Date d2(1000000000.000003);
    date.set(d2);
    CHECK(date == d2);
    CHECK(date.mksec() == 3);
}

TEST("now_hires") {
    auto date1 = Date::now_hires();
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    auto date2 = Date::now_hires();
    CHECK(date2 > date1);
    CHECK((date1.mksec() || date2.mksec()));
}
