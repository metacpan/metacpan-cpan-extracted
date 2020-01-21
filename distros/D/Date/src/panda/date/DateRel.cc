#include "DateRel.h"
#include <panda/from_chars.h>
    
namespace panda { namespace date {

const DateRel YEAR  (1);
const DateRel MONTH (0,1);
const DateRel WEEK  (0,0,7);
const DateRel DAY   (0,0,1);
const DateRel HOUR  (0,0,0,1);
const DateRel MIN   (0,0,0,0,1);
const DateRel SEC   (0,0,0,0,0,1);

static inline void relstr_val (char*& ptr, ptime_t val, char units) {
    auto res = to_chars(ptr, ptr+20, val);
    assert(!res.ec);
    ptr = res.ptr;
    *(ptr++) = units;
}

void DateRel::set (const Date& from_date, const Date& till_date) {
    _sec = _min = _hour = _day = _month = _year = 0;
    _from = from_date;
    bool reverse = from_date > till_date;
    auto& from = reverse ? till_date.date() : from_date.date();
    auto& till = reverse ? from_date.date() : till_date.date();

    _sec = till.sec - from.sec;
    if (_sec < 0) { _sec += 60; _min--; }
    
    _min += till.min - from.min;
    if (_min < 0) { _min += 60; _hour--; }
    
    _hour += till.hour - from.hour;
    if (_hour < 0) { _hour += 24; _day--; }
    
    _day += till.mday - from.mday;
    if (_day < 0) {
        int tmpy = till.year;
        int tmpm = till.mon-1;
        if (tmpm < 0) { tmpm += 12; tmpy--; }
        int days = panda::time::days_in_month(tmpy, tmpm);
        _day += days;
        _month--;
    }
    
    _month += till.mon - from.mon;
    if (_month < 0) { _month += 12; _year--; }
    
    _year += till.year - from.year;
    
    if (reverse) negate();
}

string DateRel::to_string (Format fmt) const {
    char buf[150];
    char* ptr = buf;
    switch (fmt) {
        case Format::simple:
            if (_year ) { relstr_val(ptr, _year, 'Y'); }
            if (_month) { if (ptr != buf) *(ptr++) = ' '; relstr_val(ptr, _month, 'M'); }
            if (_day  ) { if (ptr != buf) *(ptr++) = ' '; relstr_val(ptr, _day, 'D'); }
            if (_hour ) { if (ptr != buf) *(ptr++) = ' '; relstr_val(ptr, _hour, 'h'); }
            if (_min  ) { if (ptr != buf) *(ptr++) = ' '; relstr_val(ptr, _min, 'm'); }
            if (_sec  ) { if (ptr != buf) *(ptr++) = ' '; relstr_val(ptr, _sec, 's'); }
            break;
        case Format::iso8601i:
            if (_from) {
                auto dstr = _from->to_string(Date::Format::iso8601);
                auto len = dstr.length();
                memcpy(ptr, dstr.data(), len);
                ptr += len;
                *ptr++ = '/';
            }
        case Format::iso8601d:
            *ptr++ = 'P';
            if (_year ) { relstr_val(ptr, _year, 'Y'); }
            if (_month) { relstr_val(ptr, _month, 'M'); }
            if (_day  ) { relstr_val(ptr, _day, 'D'); }
            if (_hour | _min | _sec) *ptr++ = 'T';
            if (_hour ) { relstr_val(ptr, _hour, 'H'); }
            if (_min  ) { relstr_val(ptr, _min, 'M'); }
            if (_sec  ) { relstr_val(ptr, _sec, 'S'); }
            break;

        default: throw std::invalid_argument("unknown format type for relative date output");
    }
    return string(buf, ptr - buf);
}

DateRel& DateRel::operator+= (const DateRel& op) {
    _sec   += op._sec;
    _min   += op._min;
    _hour  += op._hour;
    _day   += op._day;
    _month += op._month;
    _year  += op._year;
    return *this;
}

DateRel& DateRel::operator-= (const DateRel& op) {
    _sec   -= op._sec;
    _min   -= op._min;
    _hour  -= op._hour;
    _day   -= op._day;
    _month -= op._month;
    _year  -= op._year;
    return *this;
}

DateRel& DateRel::operator*= (double koef) {
    if (fabs(koef) < 1 && koef != 0) return operator/=(1/koef);
    _sec   *= koef;
    _min   *= koef;
    _hour  *= koef;
    _day   *= koef;
    _month *= koef;
    _year  *= koef;
    return *this;
}

DateRel& DateRel::operator/= (double koef) {
    if (fabs(koef) <= 1) return operator*=(1/koef);
    double td;
    int64_t tmp;
    
    tmp = _year;
    _year /= koef;
    td = (tmp - _year*koef)*12;
    tmp = td;
    _month += tmp;
    td = (td - tmp)*((double)2629744/86400);
    tmp = td;
    _day += tmp;
    td = (td - tmp)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;

    tmp = _month;
    _month /= koef;
    td = (tmp - _month*koef)*((double)2629744/86400);
    tmp = td;
    _day += tmp;
    td = (td - tmp)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _day;
    _day /= koef;
    td = (tmp - _day*koef)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _hour;
    _hour /= koef;
    td = (tmp - _hour*koef)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _min;
    _min /= koef;
    _sec += (tmp - _min*koef)*60;
    
    _sec /= koef;
    
    return *this;
}

DateRel& DateRel::negate () {
    _sec   = -_sec;
    _min   = -_min;
    _hour  = -_hour;
    _day   = -_day;
    _month = -_month;
    _year  = -_year;
    return *this;
}

}}
