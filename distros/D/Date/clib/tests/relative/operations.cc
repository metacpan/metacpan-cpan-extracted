#include "../test.h"

#define TEST(name) TEST_CASE("relative-operations: " name, "[relative-operations]")

TEST("basic") {
    DateRel rel;

    rel = SEC+MIN+HOUR+DAY+MONTH+YEAR;
    CHECK(rel.to_string() == "1Y 1M 1D 1h 1m 1s");
    CHECK(rel + 10*SEC == rel + DateRel("10s"));
    CHECK(rel + 10*SEC == rel + DateRel(0,0,0,0,0,10));
    rel += 10*SEC;
    CHECK(rel.to_string() == "1Y 1M 1D 1h 1m 11s");

    CHECK(rel*2 == DateRel("2Y 2M 2D 2h 2m 22s"));
    rel *= 2;
    CHECK(rel.to_string() == "2Y 2M 2D 2h 2m 22s");

    CHECK(rel/2 == DateRel("1Y 1M 1D 1h 1m 11s"));
    rel /= 2;
    CHECK(rel.to_string() == "1Y 1M 1D 1h 1m 11s");

    CHECK(rel - YEAR == DateRel("1M 1D 1h 1m 11s"));
    rel -= YEAR;
    CHECK(rel.to_string() == "1M 1D 1h 1m 11s");

    rel -= DateRel(0,1,1);
    CHECK(rel.to_string() == "1h 1m 11s");

    rel -= DateRel("1h 2m 1s");
    CHECK(rel.to_string() == "-1m 10s");

    CHECK(YEAR/2 == DateRel("6M"));
    CHECK(MONTH/2 == DateRel("15D 5h 14m 32s"));
    CHECK(DAY/2 == DateRel("12h"));
    CHECK(HOUR/2 == DateRel("30m"));
    CHECK(MIN/2 == DateRel("30s"));
    CHECK(SEC/2 == DateRel(""));
    CHECK(YEAR*0.5 == DateRel("6M"));
    CHECK(MONTH*0.5 == DateRel("15D 5h 14m 32s"));
    CHECK(DAY*0.5 == DateRel("12h"));
    CHECK(HOUR*0.5 == DateRel("30m"));
    CHECK(MIN*0.5 == DateRel("30s"));
    CHECK(SEC*0.5 == DateRel(""));

    rel += rel;
    CHECK(rel.to_string() == "-2m 20s");

    rel = DateRel("1Y 3M") + rel;
    CHECK(rel.to_string() == "1Y 3M -2m 20s");

    rel -= rel;
    CHECK(rel == DateRel{});

    CHECK(rel*2 == DateRel{});

    CHECK(rel*2 == rel);

    rel = DateRel("1Y 2M");
    CHECK(rel > 1000*SEC);
    CHECK(rel > YEAR);
    CHECK(rel < 2*YEAR);
    CHECK(rel == YEAR + 2*MONTH);
    CHECK(rel == 14*MONTH);
    CHECK(!rel.is_same(14*MONTH));
}

TEST("+") {
    CHECK(MONTH + DateRel("1D") == DateRel("1M 1D"));
    CHECK(MONTH + Date("2012-01-01") == Date("2012-02-01"));
}

TEST("+=") {
    DateRel rel("1Y 1M");
    rel += MONTH;
    CHECK(rel.to_string() == "1Y 2M");
}

TEST("-") {
    CHECK(MONTH - DateRel("1D") == DateRel("1M -1D"));
}

TEST("-=") {
    DateRel rel("1Y 1M");
    rel -= MONTH;
    CHECK(rel.to_string() == "1Y");
}

TEST("*") {
    CHECK(MONTH*5 == DateRel("5M"));
    CHECK(100*DAY == DateRel("100D"));
}

TEST("*=") {
    DateRel rel("100Y 2M");
    rel *= 0.5;
    CHECK(rel.to_string() =="50Y 1M");
}

TEST("/") {
    CHECK((DAY/4).to_string() == "6h");
}

TEST("/=") {
    DateRel rel("100Y 2M");
    rel /= 0.5;
    CHECK(rel.to_string() == "200Y 4M");
}

TEST("- unary") {
    CHECK(-DateRel("1Y 2M -3D -4h") == DateRel("-1Y -2M 3D 4h"));
    CHECK(-YEAR == DateRel("-1Y"));
}

TEST("<=>") {
    DateRel rel("1Y 1M");
    CHECK(rel > YEAR);
    CHECK(rel < DateRel("1Y 1M 1s"));
    CHECK(YEAR < rel);
    CHECK(DateRel("1Y 1M 1s") > rel);
    CHECK(!(rel > rel));
    CHECK(!(rel < rel));
    CHECK(rel == rel);
    CHECK(rel != DateRel("1Y 30M"));
}

TEST("clone") {
    DateRel rel("1Y 2M 3D 4h 5m 6s");
    auto cl = rel;
    rel.year(2);
    CHECK(rel == DateRel("2Y 2M 3D 4h 5m 6s"));

    cl = DateRel("2019-01-01", "2020-01-01");
    CHECK(cl.from() == Date("2019-01-01"));
}
