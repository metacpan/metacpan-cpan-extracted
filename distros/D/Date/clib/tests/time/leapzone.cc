#include "../test.h"

#define TEST(name) TEST_CASE("time-leapzone: " name, "[time-leapzone]")

TEST("from data") {
    auto data = get_dates("right");
    for (auto& row : data) {
        tzset(row.first);
        auto& dates = row.second;
        for (auto& row : dates) {
            CHECK_LOCALTIME(row.epoch, row.dt);
            CHECK(timelocal(&row.dt) == row.epoch);
        }
    }
}

TEST("near leap second time") {
    tzset("right/UTC");
    CHECK_LOCALTIME(1230768022, 2008,11,31,23,59,59,0,3,365);
    CHECK_LOCALTIME(1230768023, 2008,11,31,23,59,60,0,3,365);
    CHECK_LOCALTIME(1230768024, 2009,0,1,0,0,0,0,4,0);

    auto dt = mkdt(2008,11,31,23,59,59,1);
    CHECK(timelocall(&dt) == 1230768022);
    CHECK_DATETIME(dt, 2008,11,31,23,59,59,1); // not normalized yet
    CHECK(timelocal(&dt) == 1230768022);
    CHECK_DATETIME(dt, 2008,11,31,23,59,59,0,3,365);

    dt = mkdt(2008,11,31,23,59,60,1);
    CHECK(timelocall(&dt) == 1230768023);
    CHECK(timelocal(&dt) == 1230768023);
    CHECK_DATETIME(dt, 2008,11,31,23,59,60,0,3,365);

    dt = mkdt(2009,0,1,0,0,0,1);
    CHECK(timelocall(&dt) == 1230768024);
    CHECK(timelocal(&dt) == 1230768024);
    CHECK_DATETIME(dt, 2009,0,1,0,0,0,0,4,0);
}

TEST("leap second inside transitions") {
    tzset("right/Europe/Moscow");
    CHECK_LOCALTIME(1230768021, 2009,0,1,2,59,58,0,4,0);
    CHECK_LOCALTIME(1230768022, 2009,0,1,2,59,59,0,4,0);
    CHECK_LOCALTIME(1230768023, 2009,0,1,2,59,60,0,4,0);
    CHECK_LOCALTIME(1230768024, 2009,0,1,3,0,0,0,4,0);
    CHECK_LOCALTIME(1230768025, 2009,0,1,3,0,1,0,4,0);

    auto dt = mkdt(2009,0,1,2,59,58,1);
    CHECK(timelocall(&dt) == 1230768021);
    CHECK(timelocal(&dt) == 1230768021);
    CHECK_DATETIME(dt, 2009,0,1,2,59,58,0,4,0);

    dt = mkdt(2009,0,1,2,59,59,1);
    CHECK(timelocall(&dt) == 1230768022);
    CHECK(timelocal(&dt) == 1230768022);
    CHECK_DATETIME(dt, 2009,0,1,2,59,59,0);

    dt = mkdt(2009,0,1,2,59,60,1);
    CHECK(timelocall(&dt) == 1230768023);
    CHECK(timelocal(&dt) == 1230768023);
    CHECK_DATETIME(dt, 2009,0,1,2,59,60,0);

    dt = mkdt(2009,0,1,3,0,0,1);
    CHECK(timelocall(&dt) == 1230768024);
    CHECK(timelocal(&dt) == 1230768024);
    CHECK_DATETIME(dt, 2009,0,1,3,0,0,0);

    // check normalization (120 != 60+60)
    dt = mkdt(2009,0,1,2,58,119,1);
    CHECK(timelocall(&dt) == 1230768022);
    CHECK(timelocal(&dt) == 1230768022);
    CHECK_DATETIME(dt, 2009,0,1,2,59,59,0);

    dt = mkdt(2009,0,1,2,58,120,1);
    CHECK(timelocall(&dt) == 1230768024);
    CHECK(timelocal(&dt) == 1230768024);
    CHECK_DATETIME(dt, 2009,0,1,3,0,0,0);

    dt = mkdt(2009,0,1,3,0,-1,1);
    CHECK(timelocall(&dt) == 1230768022);
    CHECK(timelocal(&dt) == 1230768022);
    CHECK_DATETIME(dt, 2009,0,1,2,59,59,0);

    dt = mkdt(2009,0,1,2,59,61,1);
    CHECK(timelocall(&dt) == 1230768025);
    CHECK(timelocal(&dt) == 1230768025);
    CHECK_DATETIME(dt, 2009,0,1,3,0,1,0);
}

TEST("when last transition is leap second") {
    tzset("right/Europe/Moscow");
    CHECK_LOCALTIME(1341100822, 2012,6,1,3,59,58,0,0,182);
    CHECK_LOCALTIME(1341100823, 2012,6,1,3,59,59,0,0,182);
    CHECK_LOCALTIME(1341100824, 2012,6,1,3,59,60,0,0,182);
    CHECK_LOCALTIME(1341100825, 2012,6,1,4,0,0,0,0,182);
    CHECK_LOCALTIME(1341100826, 2012,6,1,4,0,1,0,0,182);

    auto dt = mkdt(2012,6,1,3,59,58,1);
    CHECK(timelocall(&dt) == 1341100822);
    CHECK(timelocal(&dt) == 1341100822);
    CHECK_DATETIME(dt, 2012,6,1,3,59,58,0);
    dt = mkdt(2012,6,1,3,59,59,1);
    CHECK(timelocall(&dt) == 1341100823);
    CHECK(timelocal(&dt) == 1341100823);
    CHECK_DATETIME(dt, 2012,6,1,3,59,59,0);
    dt = mkdt(2012,6,1,3,59,60,1);
    CHECK(timelocall(&dt) == 1341100824);
    CHECK(timelocal(&dt) == 1341100824);
    CHECK_DATETIME(dt, 2012,6,1,3,59,60,0);
    dt = mkdt(2012,6,1,4,0,0,1);
    CHECK(timelocall(&dt) == 1341100825);
    CHECK(timelocal(&dt) == 1341100825);
    CHECK_DATETIME(dt, 2012,6,1,4,0,0,0);
    // check normalization (120 != 60+60)
    dt = mkdt(2012,6,1,3,58,119,1);
    CHECK(timelocall(&dt) == 1341100823);
    CHECK(timelocal(&dt) == 1341100823);
    CHECK_DATETIME(dt, 2012,6,1,3,59,59,0);
    dt = mkdt(2012,6,1,3,58,120,1);
    CHECK(timelocall(&dt) == 1341100825);
    CHECK(timelocal(&dt) == 1341100825);
    CHECK_DATETIME(dt, 2012,6,1,4,0,0,0);
    dt = mkdt(2012,6,1,4,0,-1,1);
    CHECK(timelocall(&dt) == 1341100823);
    CHECK(timelocal(&dt) == 1341100823);
    CHECK_DATETIME(dt, 2012,6,1,3,59,59,0);
    dt = mkdt(2012,6,1,3,59,61,1);
    CHECK(timelocall(&dt) == 1341100826);
    CHECK(timelocal(&dt) == 1341100826);
    CHECK_DATETIME(dt, 2012,6,1,4,0,1,0);
}
