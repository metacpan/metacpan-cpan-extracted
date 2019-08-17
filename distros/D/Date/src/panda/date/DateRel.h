#pragma once
#include <math.h>
#include <stdexcept>
#include <panda/date/Date.h>

namespace panda { namespace date {

using panda::time::datetime;

class DateRel {
public:
    explicit DateRel (ptime_t year=0, ptime_t mon=0, ptime_t day=0, ptime_t hour=0, ptime_t min=0, ptime_t sec=0)
                     : _sec(sec), _min(min), _hour(hour), _day(day), _month(mon), _year(year) {}
    explicit DateRel (string_view str)           { operator=(str); }
    DateRel (const Date& from, const Date& till) { set(from, till); }
    DateRel (const DateRel& source)              { operator=(source); }

    void set (const Date&, const Date&);

    DateRel& operator= (string_view str) {
        datetime date;
        parse_relative(str, date);
        _year  = date.year;
        _month = date.mon;
        _day   = date.mday;
        _hour  = date.hour;
        _min   = date.min;
        _sec   = date.sec;
        return *this;
    }

    DateRel& operator= (const DateRel& source) {
        _sec   = source._sec;
        _min   = source._min;
        _hour  = source._hour;
        _day   = source._day;
        _month = source._month;
        _year  = source._year;
        return *this;
    }

    ptime_t sec   () const      { return _sec; }
    void    sec   (ptime_t val) { _sec = val; }
    ptime_t min   () const      { return _min; }
    void    min   (ptime_t val) { _min = val; }
    ptime_t hour  () const      { return _hour; }
    void    hour  (ptime_t val) { _hour = val; }
    ptime_t day   () const      { return _day; }
    void    day   (ptime_t val) { _day = val; }
    ptime_t month () const      { return _month; }
    void    month (ptime_t val) { _month = val; }
    ptime_t year  () const      { return _year; }
    void    year  (ptime_t val) { _year = val; }
    bool    empty () const      { return _sec == 0 && _min == 0 && _hour == 0 && _day == 0 && _month == 0 && _year == 0; }

    ptime_t to_sec   () const { return _sec + _min*60 + _hour*3600 + _day * 86400 + (_month + 12*_year) * 2629744; }
    double  to_min   () const { return (double) to_sec() / 60; }
    double  to_hour  () const { return (double) to_sec() / 3600; }
    double  to_day   () const { return (double) to_sec() / 86400; }
    double  to_month () const { return (double) to_sec() / 2629744; }
    double  to_year  () const { return to_month() / 12; }
    ptime_t duration () const { return to_sec(); }

    string to_string () const;

    DateRel& operator+= (const DateRel&);
    DateRel& operator-= (const DateRel&);
    DateRel& operator*= (double koef);
    DateRel& operator/= (double koef);
    DateRel& negate     ();

    DateRel negated () const { return DateRel(*this).negate(); }

    ptime_t compare (const DateRel& operand) const { return to_sec() - operand.to_sec(); }

    bool is_same (const DateRel& operand) const {
        return _sec == operand._sec && _min == operand._min && _hour == operand._hour &&
               _day == operand._day && _month == operand._month && _year == operand._year;
    }

private:
    ptime_t _sec;
    ptime_t _min;
    ptime_t _hour;
    ptime_t _day;
    ptime_t _month;
    ptime_t _year;
};

extern const DateRel YEAR;
extern const DateRel MONTH;
extern const DateRel WEEK;
extern const DateRel DAY;
extern const DateRel HOUR;
extern const DateRel MIN;
extern const DateRel SEC;

inline bool operator== (const DateRel& lhs, const DateRel& rhs) { return !lhs.compare(rhs); }
inline bool operator!= (const DateRel& lhs, const DateRel& rhs) { return !operator==(lhs, rhs); }
inline bool operator<  (const DateRel& lhs, const DateRel& rhs) { return lhs.compare(rhs) < 0; }
inline bool operator<= (const DateRel& lhs, const DateRel& rhs) { return lhs.compare(rhs) <= 0; }
inline bool operator>  (const DateRel& lhs, const DateRel& rhs) { return lhs.compare(rhs) > 0; }
inline bool operator>= (const DateRel& lhs, const DateRel& rhs) { return lhs.compare(rhs) >= 0; }

inline DateRel operator+ (const DateRel& lhs, const DateRel& rhs) { return DateRel(lhs) += rhs; }
inline DateRel operator- (const DateRel& lhs, const DateRel& rhs) { return DateRel(lhs) -= rhs; }
inline DateRel operator* (const DateRel& dr, double koef)         { return DateRel(dr) *= koef; }
inline DateRel operator* (double koef, const DateRel& dr)         { return DateRel(dr) *= koef; }
inline DateRel operator/ (const DateRel& dr, double koef)         { return DateRel(dr) /= koef; }

}}
