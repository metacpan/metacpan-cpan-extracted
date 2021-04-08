#include  "../test.h"

#define TEST(name) TEST_CASE("time-timegm: " name, "[time-timegm]")

TEST("from data") {
    auto dates = get_dates("utc").at("UTC");
    for (auto& row : dates) {
        auto dt = row.dt;
        CHECK(timegm(&dt)      == row.epoch);
        CHECK(timegml(&row.dt) == row.epoch);
    }
}

TEST("normalization") {
    auto dt = mkdt(1970,0,1,0,0,-1);
    CHECK(timegmll(&dt) == -1);
    CHECK_DATETIME(dt, 1970,0,1,0,0,-1);
    CHECK(timegml(&dt) == -1);
    CHECK_DATETIME(dt, 1970,0,1,0,0,-1);
    CHECK(timegm(&dt) == -1);
    CHECK_DATETIME(dt, 1969,11,31,23,59,59);

    dt = mkdt(1970,234,-4643,2341,-34332,-1213213);
    CHECK(timegm(&dt) == 219167267);
    CHECK_DATETIME(dt, 1976,11,11,15,47,47);

    dt = mkdt(2010,-123,-1234,12345,-123456,-1234567);
    CHECK(timegm(&dt) == 867832073);
    CHECK_DATETIME(dt, 1997,6,2,8,27,53);

    dt = mkdt(2010,-1,0,0,0,0);
    CHECK(timegm(&dt) == 1259539200);
    CHECK_DATETIME(dt, 2009,10,30,0,0,0);
}
