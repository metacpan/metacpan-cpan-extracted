#include "../test.h"
#include <panda/function.h>

#define TEST(name) TEST_CASE("time-strftime: " name, "[time-strftime]")


static ptime_t e2() {
    static auto d2 = mkdt(1983, 6, 15, 1, 2, 3);
    static auto ret = timelocal(&d2);
    return ret;
}

static void test (string_view fmt, string_view val1, string_view val2 = "EPTA", const function<void()>& custom = {}) {
    static auto d1 = mkdt(2019, 11, 9, 20, 34, 56);
    static auto d2 = mkdt(1983, 6, 15, 1, 2, 3);
    timelocal(&d1);
    timelocal(&d2);

    if (val2 == "EPTA") val2 = val1;
    SECTION("'" + std::string(fmt.data(), fmt.size()) + "'") {
        CHECK(strftime(fmt, d1) == val1);
        CHECK(strftime(fmt, d2) == val2);
        if (custom) custom();
    }
}

TEST("modifiers") {
    test("", "");
    test("%%", "%");
    test("%a", "Mon", "Fri");
    test("%A", "Monday", "Friday");
    test("%b", "Dec", "Jul");
    test("%B", "December", "July");
    test("%c", "Mon Dec  9 20:34:56 2019", "Fri Jul 15 01:02:03 1983");
    test("%C", "20", "19"); // century[00-99]
    test("%d", "09", "15"); // mday[01-31]
    test("%D", "12/09/19", "07/15/83");
    test("%e", " 9", "15"); // mday[1-31]
    test("%F", "2019-12-09", "1983-07-15");
    test("%H", "20", "01"); // hour[00-23]
    test("%I", "08", "01"); // hour[01-12]
    test("%j", "343", "196"); // yday[001-366]
    test("%k", "20", " 1"); // hour[0-23]
    test("%l", " 8", " 1"); // hour[1-12]
    test("%m", "12", "07"); // month[01-12]
    test("%M", "34", "02"); // minute[00-59]
    test("%n", "\n"); // newline char
    test("%p", "PM", "AM"); // AMPM
    test("%P", "pm", "am"); // ampm
    test("%r", "08:34:56 PM", "01:02:03 AM");
    test("%R", "20:34", "01:02");
    test("%s", "1575912896", "427064523"); // epoch
    test("%S", "56", "03"); // second[00-59]
    test("%t", "\t"); // tab character
    test("%T", "20:34:56", "01:02:03"); // HH:MM:SS
    test("%u", "1", "5", []{ CHECK(strftime("%u", localtime(e2() + 86400*2)) == "7"); }); // wday [1-7, Mon-Sun]
    test("%w", "1", "5", []{ CHECK(strftime("%w", localtime(e2() + 86400*2)) == "0"); }); // wday [0-6, Sun-Sat]
    test("%X", "20:34:56", "01:02:03"); // preferred HMS style
    test("%y", "19", "83"); // yr[00-99]
    test("%Y", "2019", "1983"); // year[0000-9999]
    test("%z", "+0300", "+0400"); // tzoff [+-]HHMM
    test("%Z", "MSK", "MSD"); // tzabbr
}

TEST("with static text") {
    test("<%Y>", "<2019>", "<1983>");
    test("%Y/%m/%d", "2019/12/09", "1983/07/15");
}

TEST("unpaired percent") {
    test("%", "%");
    test("%m%", "12%", "07%");
}

TEST("unknown modifier") {
    test("%[", "[");
}

TEST("combined") {
    test("%a %b %e %H:%M:%S %Y", "Mon Dec  9 20:34:56 2019", "Fri Jul 15 01:02:03 1983");
}
