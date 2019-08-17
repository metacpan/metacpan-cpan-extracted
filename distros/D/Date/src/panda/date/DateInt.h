#pragma once
#include <cstring>
#include <panda/date/Date.h>
#include <panda/date/DateRel.h>

namespace panda { namespace date {

using panda::time::christ_days;

class DateInt {
public:
    DateInt ()                                                                          {}
    DateInt (const Date& from, const Date& till) : _from(from), _till(till)             {}
    DateInt (const DateInt& src)                 : _from(src.from()), _till(src.till()) {}

    explicit DateInt (string_view str) { operator=(str); }

    DateInt& operator= (const DateInt& oth) {
        _from = oth.from();
        _till = oth.till();
        return *this;
    }

    DateInt& operator= (string_view str);

    err_t error () const { return _from.error() == E_OK ? _till.error() : _from.error(); }

    const Date& from () const { return _from; }
    const Date& till () const { return _till; }
    Date&       from ()       { return _from; }
    Date&       till ()       { return _till; }

    panda::string to_string() const;

    ptime_t hms_diff () const {
        return (_till.hour() - _from.hour())*3600 + (_till.min() - _from.min())*60 + _till.sec() - _from.sec();
    }

    ptime_t duration () const { return error() ? 0 : (_till.epoch() - _from.epoch()); }
    ptime_t sec      () const { return duration(); }
    ptime_t imin     () const { return duration()/60; }
    double  min      () const { return (double) duration()/60; }
    ptime_t ihour    () const { return duration()/3600; }
    double  hour     () const { return (double) duration()/3600; }

    ptime_t iday     () const { return (ptime_t) day(); }
    double  day      () const { return christ_days(_till.year()) + _till.yday() - christ_days(_from.year()) - _from.yday() + (double) hms_diff() / 86400; }

    ptime_t imonth   () const { return (ptime_t) month(); }
    double  month    () const {
        return (_till.year() - _from.year())*12 + _till.month() - _from.month() +
               (double) (_till.day() - _from.day() + (double) hms_diff() / 86400) / _from.days_in_month();
    }

    ptime_t iyear () const { return (ptime_t) year(); }
    double  year  () const { return month() / 12; }

    DateRel relative () const { return DateRel(_from, _till); }

    DateInt& operator+= (const DateRel& op) {
        _from += op;
        _till += op;
        return *this;
    }

    DateInt& operator-= (const DateRel& op) {
        _from -= op;
        _till -= op;
        return *this;
    }

    ptime_t compare (const DateInt& operand) const { return duration() - operand.duration(); }

    bool is_same (const DateInt& operand) const { return _from == operand._from && _till == operand._till; }

    DateInt& negate () {
        std::swap(_from, _till);
        return *this;
    }

    DateInt negated () const { return DateInt(_till, _from); }

    int includes (const Date& date) const {
        if (_from > date) return 1;
        if (_till < date) return -1;
        return 0;
    }

private:
    Date _from;
    Date _till;
};

inline bool operator== (const DateInt& lhs, const DateInt& rhs) { return !lhs.compare(rhs); }
inline bool operator<  (const DateInt& lhs, const DateInt& rhs) { return !operator==(lhs, rhs); }
inline bool operator<= (const DateInt& lhs, const DateInt& rhs) { return lhs.compare(rhs) <= 0; }
inline bool operator>  (const DateInt& lhs, const DateInt& rhs) { return lhs.compare(rhs) > 0; }
inline bool operator>= (const DateInt& lhs, const DateInt& rhs) { return lhs.compare(rhs) >= 0; }

inline DateInt operator+ (const DateInt& lhs, const DateRel& rhs) { return DateInt(lhs) += rhs; }
inline DateInt operator- (const DateInt& lhs, const DateRel& rhs) { return DateInt(lhs) -= rhs; }

}}
