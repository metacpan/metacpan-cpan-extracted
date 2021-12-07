#include "test.h"
#include <catch2/reporters/catch_reporter_registrars.hpp>
#include <catch2/reporters/catch_reporter_event_listener.hpp>

static unordered_string_map<string, unordered_string_map<string, string>> test_dates =
    #include "time/gendata.icc"
;

struct MyListener : Catch::EventListenerBase {
    using EventListenerBase::EventListenerBase;

    void testRunStarting (Catch::TestRunInfo const&) override {
        tzembededdir("zoneinfo");
        use_embed_timezones();
        if (tzget("Europe/Moscow")->name != "Europe/Moscow") {
            throw std::runtime_error("no embeded zones");
        }
    }

    void testCaseStarting (Catch::TestCaseInfo const&) override {
        tzset("Europe/Moscow");
    }

    void testCaseEnded (Catch::TestCaseStats const&) override {
        tzset("Europe/Moscow");
    }
};
CATCH_REGISTER_LISTENER(MyListener);


static void _get_dates (std::vector<TestMoment>& ret, const string& data) {
    size_t pos = 0, cur;
    std::vector<int64_t> tmp;
    auto ptr = data.data();
    while (1) {
        cur = data.find(',', pos);
        int64_t val;
        auto res = from_chars(ptr + pos, (cur == string::npos ? (ptr + data.length()) : (ptr + cur)), val);
        if (res.ec) throw std::invalid_argument("bad dataset content");
        tmp.push_back(val);
        if (cur == string::npos) break;
        pos = cur + 1;
    }

    if (tmp.size() % 10) throw std::invalid_argument("bad dataset content");

    for (size_t i = 0; i < tmp.size(); i += 10) {
        TestMoment e;
        int64_t epoch = tmp[i];
        if (sizeof(ptime_t) < 8 && (epoch >= 2147483648 || epoch < -2147483648)) continue; // skip large numbers for 32bit systems

        e.epoch    = tmp[i];
        e.dt.sec   = tmp[i+1];
        e.dt.min   = tmp[i+2];
        e.dt.hour  = tmp[i+3];
        e.dt.mday  = tmp[i+4];
        e.dt.mon   = tmp[i+5];
        e.dt.year  = tmp[i+6];
        e.dt.wday  = tmp[i+7];
        e.dt.yday  = tmp[i+8];
        e.dt.isdst = tmp[i+9];

        ret.push_back(e);
    }
}

unordered_string_map<string, std::vector<TestMoment>> get_dates (string_view dataset) {
    unordered_string_map<string, std::vector<TestMoment>> ret;
    auto& data = test_dates.at(dataset);
    for (auto& row : data) _get_dates(ret[row.first], row.second);
    return ret;
}

void CHECK_DATETIME (const datetime& d1, const datetime& d2) {
    CHECK_DATETIME(d1, d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec, d2.isdst, d2.wday, d2.yday);
}

void CHECK_DATETIME (const datetime& d1, int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst, int32_t wday, int32_t yday) {
    std::vector<ptime_t> dt1{d1.year, d1.mon, d1.mday, d1.hour, d1.min, d1.sec, isdst == -1 ? isdst : d1.isdst, wday == -1 ? wday : d1.wday, yday == -1 ? yday : d1.yday};
    std::vector<ptime_t> dt2{year, mon, mday, hour, min, sec, isdst, wday, yday};
    CHECK(dt1 == dt2);
}

void CHECK_LOCALTIME (ptime_t epoch, const datetime& d1) {
    CHECK_LOCALTIME(epoch, d1.year, d1.mon, d1.mday, d1.hour, d1.min, d1.sec, d1.isdst, d1.wday, d1.yday);
}

void CHECK_LOCALTIME (ptime_t epoch, int32_t year, ptime_t mon, ptime_t mday, ptime_t hour, ptime_t min, ptime_t sec, int32_t isdst, int32_t wday, int32_t yday) {
    datetime res;
    CHECK(localtime(epoch, &res));
    CHECK_DATETIME(res, year, mon, mday, hour, min, sec, isdst, wday, yday);
}

