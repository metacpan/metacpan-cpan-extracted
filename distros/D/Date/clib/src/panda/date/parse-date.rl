#include "Date.h" 
#include <string.h>
#include <stdlib.h>
#include <algorithm>

%%{
    machine date_parser;
    
    action digit {
        acc *= 10;
        acc += fc - '0';
    }

    action sec   { NSAVE(_date.sec); }
    action min   { NSAVE(_date.min); }
    action hour  { NSAVE(_date.hour); }
    action day   { NSAVE(_date.mday); }
    action month { _date.mon = acc - 1; acc = 0; }
    action year  { NSAVE(_date.year); }
    
    action yr {
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }

    action mks_start {
        mksec_ptr = p;
    }
    
    action mks {
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
    
    ### TZ rule syntax for arbitrary offset
    ###         < + 0 1 : 3 0 > - 0 1  :  3  0
    ### indexes 0 1 2 3 4 5 6 7 8 9 10 11 12 13
    
    action tzsign {
        tzi.rule[0] = '<';
        tzi.rule[1] = *p;
        tzi.rule[4] = ':';
        tzi.rule[7] = '>';
        tzi.rule[8] = *p ^ 6; // swap '+'<->'-': yes, it is reversed
        tzi.rule[11] = ':';
        tzi.rule[5] = tzi.rule[6] = tzi.rule[12] = tzi.rule[13] = '0'; // in case there will be no minutes
        tzi.len = 14;
    }
    
    action tzhour {
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
    
    action tzmin {
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
    
    action tzgmt {
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
    
    action week { NSAVE(week); }
    action wday { _date.wday = *p - '0'; }
    
    nn = digit{2} $digit;

    sec      = nn %sec;
    min      = nn %min;
    hour     = nn %hour;
    day      = nn %day;
    day_void = day | (" " digit $digit) %day;
    month    = nn %month;
    year     = digit{4} $digit %year;
    yr       = nn %yr;
    mks      = digit{1,6} >mks_start $digit %mks;
    smks     = sec ([.,] mks)?;

    tzoff_sign = [+\-] $tzsign;
    tzoff_hour = nn %tzhour;
    tzoff_min  = nn %tzmin;
    tzoff      = tzoff_sign tzoff_hour (":" tzoff_min)?;
    tzgmt      = "Z" %tzgmt;
    tzd        = tzoff | tzgmt;
    tzclf      = tzoff_sign tzoff_hour tzoff_min;
    
    mon_name = "Jan" %{ _date.mon = 0; } |
               "Feb" %{ _date.mon = 1; } |
               "Mar" %{ _date.mon = 2; } |
               "Apr" %{ _date.mon = 3; } |
               "May" %{ _date.mon = 4; } |
               "Jun" %{ _date.mon = 5; } |
               "Jul" %{ _date.mon = 6; } |
               "Aug" %{ _date.mon = 7; } |
               "Sep" %{ _date.mon = 8; } |
               "Oct" %{ _date.mon = 9; } |
               "Nov" %{ _date.mon = 10;} |
               "Dec" %{ _date.mon = 11;};
    
    wday_name = "Mon" %{ _date.wday = 1; } |
                "Tue" %{ _date.wday = 2; } |
                "Wed" %{ _date.wday = 3; } |
                "Thu" %{ _date.wday = 4; } |
                "Fri" %{ _date.wday = 5; } |
                "Sat" %{ _date.wday = 6; } |
                "Sun" %{ _date.wday = 0; };
                
    weekday_name = "Monday"    %{ _date.wday = 1; } |
                   "Tuesday"   %{ _date.wday = 2; } |
                   "Wednesday" %{ _date.wday = 3; } |
                   "Thursday"  %{ _date.wday = 4; } |
                   "Friday"    %{ _date.wday = 5; } |
                   "Saturday"  %{ _date.wday = 6; } |
                   "Sunday"    %{ _date.wday = 0; };

    iso = (
        ((year "/" month "/" day) | (year "-" month "-" day)) (" " hour ":" min (":" smks)? tzd?)?
    ) %{ format |= InputFormat::iso; };

    iso8601_tzd  = tzd | ((tzoff_sign tzoff_hour tzoff_min?) | tzgmt);
    iso8601_void = year     month      day ( "T" hour     (min      smks?)?  iso8601_tzd? )?;
    iso8601_std  = year "-" month ("-" day ( "T" hour (":" min (":" smks)?)? iso8601_tzd? )?)?;
    iso8601_week = year "-W" nn %week ("-" digit $wday)?;
    iso8601      = (iso8601_std | iso8601_void | iso8601_week) %{ format |= InputFormat::iso8601; };
    
    rfc1123_zone = ("Z" | "UT" | "GMT") %tzgmt |
                   ("EST" | "EDT")      %{ TZRULE("EST5EDT"); } |
                   ("CST" | "CDT")      %{ TZRULE("CST6CDT"); } |
                   ("MST" | "MDT")      %{ TZRULE("MST7MDT"); } |
                   ("PST" | "PDT")      %{ TZRULE("PST8PDT"); } |
                   "A"                  %{ TZRULE("<-01:00>+01:00"); } |
                   "M"                  %{ TZRULE("<-12:00>+12:00"); } |
                   "N"                  %{ TZRULE("<+01:00>-01:00"); } |
                   "Y"                  %{ TZRULE("<+12:00>-12:00"); } |
                   (tzoff_sign tzoff_hour tzoff_min);
    rfc1123 = (
        (wday_name ", ")? day " " mon_name " " (year | yr) " " hour ":" min (":" sec)? " " rfc1123_zone
    ) %{ format |= InputFormat::rfc1123; };
    
    rfc850 = (
        weekday_name ", " day "-" mon_name "-" yr " " hour ":" min ":" sec " " rfc1123_zone
    ) %{ format |= InputFormat::rfc850; };
    
    ansi_c = (
        wday_name " " mon_name " " day_void " " hour ":" min ":" sec " " year
    ) %{ format |= InputFormat::ansi_c; };

    dot = (day "." month "." year) %{ format |= InputFormat::dot; };
    
    clf_raw = day "/" mon_name "/" year ":" hour ":" min ":" sec " " tzclf;
    clfb = ( "[" clf_raw "]" );
    clf = (clf_raw | clfb) %{ format |= InputFormat::clf; };


    all := iso | iso8601 | dot | rfc1123 | rfc850 | ansi_c | clf;
}%%

namespace panda { namespace date {

%% write data;

static TimezoneSP gmt_zone;

#define NSAVE(dest) { dest = acc; acc = 0; }
        
#define TZRULE(str) do {                    \
    memcpy(tzi.rule, str, sizeof(str) - 1); \
    tzi.len = sizeof(str) - 1;              \
} while(0)

void Date::parse (string_view str, int allowed_formats) {
    memset(&_date, 0, sizeof(_date)); // reset all values
    _date.mday = 1;
    _error = errc::ok;
    _mksec = 0;

    enum class TZType { LOCAL, OFFSET };
    
    const char* p      = str.data();
    const char* pe     = p + str.length();
    const char* eof    = pe;
    int         cs     = date_parser_en_all;
    uint64_t    acc    = 0;
    const char* mksec_ptr;
    int         format = 0;
    
    struct {
        char rule[14];
        int  len = 0;
    } tzi;
    
    unsigned week = 0;

    %% write exec;

    if (cs < date_parser_first_final || !(allowed_formats & format)) {
        _error = errc::parser_error;
        return;
    }
    
    if (tzi.len) _zone = panda::time::tzget(string_view(tzi.rule, tzi.len));
    _post_parse_week(week);
}

}}
