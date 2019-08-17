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

static inline void relstr_val (char* st, char*& ptr, ptime_t val, char units) {
    if (ptr != st) *(ptr++) = ' ';
    auto res = to_chars(ptr, ptr+20, val);
    assert(!res.ec);
    ptr = res.ptr;
    *(ptr++) = units;
}

void DateRel::set (const Date& from_date, const Date& till_date) {
    _sec = _min = _hour = _day = _month = _year = 0;
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
        int days = days_in_month(tmpy, tmpm);
        _day += days;
        _month--;
    }
    
    _month += till.mon - from.mon;
    if (_month < 0) { _month += 12; _year--; }
    
    _year += till.year - from.year;
    
    if (reverse) negate();
}

string DateRel::to_string () const {
    string ret(65);
    auto ptr = ret.buf();
    auto st = ptr;
    if (_year  != 0) { relstr_val(st, ptr, _year, 'Y'); }
    if (_month != 0) { relstr_val(st, ptr, _month, 'M'); }
    if (_day   != 0) { relstr_val(st, ptr, _day, 'D'); }
    if (_hour  != 0) { relstr_val(st, ptr, _hour, 'h'); }
    if (_min   != 0) { relstr_val(st, ptr, _min, 'm'); }
    if (_sec   != 0) { relstr_val(st, ptr, _sec, 's'); }
    ret.length(ptr - st);
    return ret;
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
