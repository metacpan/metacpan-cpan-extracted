#include "../test.h"

#define TEST(name) TEST_CASE("time-gmtime: " name, "[time-gmtime]")

TEST("from data") {
    auto dates = get_dates("utc").at("UTC");
    for (auto& row : dates) {
        datetime res;
        CHECK(gmtime(row.epoch, &res));
        CHECK_DATETIME(res, row.dt);
    }
}

TEST("out of range") {
    X64ONLY;
    datetime dt;
    CHECK(gmtime(+67767976233446399, &dt));
    CHECK(gmtime(-67768100567884800, &dt));
    CHECK(!gmtime(+67767976233446399 + 1, nullptr)); // dt pointer should not be used
    CHECK(!gmtime(-67768100567884800 - 1, nullptr));
}
