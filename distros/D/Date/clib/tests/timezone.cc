#include "test.h"
#include <thread>

#define TEST(name) TEST_CASE("timezone: " name, "[timezone]")

TEST("local") {
    for (auto& date : std::vector<Date>{Date("2014-01-01 00:00:00"), Date("2014-01-01 00:00:00", nullptr), Date("2014-01-01 00:00:00", tzget(""))}) {
        CHECK(date.timezone() == tzlocal());
    }
}

TEST("date follows local zone when it changes") {
    tzset("Europe/Moscow");
    Date d("2014-01-01 00:00:00");
    CHECK(d.to_string(Date::Format::iso_tz) == "2014-01-01 00:00:00+04");
    CHECK(d.epoch() == 1388520000);
    tzset("America/New_York");
    d.epoch(d.epoch());
    CHECK(d.to_string(Date::Format::iso_tz) == "2013-12-31 15:00:00-05");
    CHECK(d.epoch() == 1388520000);
}

TEST("with zone") {
    Date date("2014-01-01 00:00:00", tzget("America/New_York"));
    CHECK(date.timezone() == tzget("America/New_York"));
    CHECK(date.timezone()->name == "America/New_York");
    Date b = Date("2014-01-01 00:00:00");
    CHECK(date.epoch() > b.epoch());
    CHECK(date > b);
    CHECK(date != b);
    CHECK(date.to_string() == b.to_string());
}

TEST("clone with tz") {
    Date src("2014-01-01 00:00:00", tzget("America/New_York"));
    SECTION("with local") {
        auto date = src.clone(-1, -1, -1, -1, -1, -1, -1, -1, tzget(""));
        CHECK(date.timezone() == tzlocal());
        CHECK(date == Date("2014-01-01 00:00:00"));
        CHECK(date != src);
        CHECK(date.to_string() == "2014-01-01 00:00:00");
    }
    SECTION("with other") {
        Date date = src.clone(-1, -1, -1, -1, -1, -1, -1, -1, tzget("Europe/Kiev"));
        CHECK(date.timezone()->name == "Europe/Kiev");
        CHECK(date.to_string(Date::Format::iso8601) == "2014-01-01T00:00:00+02");
    }
}

TEST("to_timezone") {
    SECTION("local") {
        Date src("2014-01-01 00:00:00", tzget("America/New_York"));
        auto date = src;
        date.to_timezone(tzlocal());
        CHECK(date.timezone() == tzlocal());
        CHECK(date.epoch() == src.epoch());
    }
    SECTION("other") {
        Date src("2014-01-01 00:00:00", tzget("America/New_York"));
        auto date = src;
        date.to_timezone(tzget("Australia/Melbourne"));
        CHECK(date.epoch() == src.epoch());
        CHECK(date.to_string() != src.to_string());
    }
}

TEST("timezone()") {
    Date src("2014-01-01 00:00:00", tzget("America/New_York"));
    auto date = src;
    date.timezone(tzget("Australia/Melbourne"));
    CHECK(date.epoch() != src.epoch());
    CHECK(date.to_string() == src.to_string());
}

TEST_CASE("timezone: timezone thread safe", "[.thread-safe]") {
    auto tz = tzget("America/New_York");

    std::vector<std::thread> list;
    for (int i = 0; i < 10; ++i) {
        list.push_back(std::thread([&]{
            for (int i = 0; i < 1000000; ++i) {
                Date d("2014-01-01 00:00:00", tz);
                d.to_string();
            }
        }));
    }

    for (auto& t : list) t.join();

    CHECK(tz.use_count() < 10); // actually 2
    SUCCEED();
}

TEST_CASE("timezone: localzone thread safe", "[.thread-safe]") {
    std::vector<std::thread> list;
    for (int i = 0; i < 10; ++i) {
        list.push_back(std::thread([&]{
            for (int i = 0; i < 1000000; ++i) {
                Date d("2014-01-01 00:00:00");
                d.epoch();
                if (i % 100 == 0) {
                    switch ((i/100) % 3) {
                        case 0 : tzset("America/New_York"); break;
                        case 1 : tzset("Europe/Moscow"); break;
                        case 2 : tzset("Europe/Kiev"); break;
                    }
                }
            }
        }));
    }

    for (auto& t : list) t.join();

    SUCCEED();
}

TEST_CASE("timezone: bench date with tz", "[.]") {
    for (int i = 0; i < 10000000; ++i) {
        Date d("2014-01-01 00:00:00", tzget("America/New_York"));
    }
}

TEST_CASE("timezone: bench date local", "[.]") {
    for (int i = 0; i < 10000000; ++i) {
        Date d(123456789);
        d.epoch();
    }
}
