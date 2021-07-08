#include "DateRel.h"

%%{
    machine daterel_parser;
    
    action sign { sign = *p; }
    
    action digit {
        acc *= 10;
        acc += fc - '0';
    }
    
    action number {
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }

    action sec   { NSAVE(_sec); }
    action min   { NSAVE(_min); }
    action hour  { NSAVE(_hour); }
    action day   { NSAVE(_day); }
    action month { NSAVE(_month); }
    action year  { NSAVE(_year); }
    
    action week {
        _day += acc*7;
        acc = 0;
    }
    
    number = "-"? $sign digit+ $digit %number;

    simple_part = (number [Yy] %year) | (number "M" %month) | (number [Dd] %day) | (number [Ww] %week) | (number "h" %hour) | (number "m" %min) | (number "s" %sec);
    simple = (simple_part (space+ simple_part)*) %{ format |= InputFormat::simple; };
    
    iso8601_duration = (
        "P" (number "Y" %year)? (number "M" %month)? (number "D" %day)? (number "W" %week)? ("T" (number "H" %hour)? (number "M" %min)? (number "S" %sec)?)?
    ) %{ format |= InputFormat::iso8601; };

    main := simple | iso8601_duration;
}%%

namespace panda { namespace date {

%% write data;

#define NSAVE(dest) { dest += acc; acc = 0; }
        
errc DateRel::parse (string_view str, int available_formats) {
    _year = _month = _day = _hour = _min = _sec = 0;
    int         cs     = daterel_parser_start;
    int64_t     acc    = 0;
    char        sign   = 0;
    const char* p      = str.data();
    const char* pe     = p + str.length();
    const char* eof    = pe;
    int         format = 0;
    
    %% write exec;
    
    if (cs < daterel_parser_first_final && (available_formats & InputFormat::iso8601i)) {
        _year = _month = _day = _hour = _min = _sec = 0;
        // ISO8601 interval format: "iso8601_date/iso8601_relative"
        auto pos = str.find('/');
        if (pos == string::npos) return errc::parser_error;
        format = InputFormat::iso8601i;
        
        _from = Date(str.substr(0, pos), {}, Date::InputFormat::iso8601);
        if (_from->error()) return errc::parser_error;

        return parse(str.substr(pos+1), InputFormat::iso8601d);
    }
    
    if (!(format & available_formats)) {
        _year = _month = _day = _hour = _min = _sec = 0;
        return errc::parser_error;
    }
    
    return errc::ok;
}

}}
