#pragma once
#include "Date.h"
#include <panda/optional.h>

namespace panda { namespace date {

struct DateRel {
    enum class Format { simple, iso8601d, iso8601i };

    struct InputFormat {
        static const int simple   = 1;
        static const int iso8601d = 2;
        static const int iso8601i = 4;
        static const int iso8601  = iso8601d + iso8601i;
        static const int all      = ~0;
    };

    DateRel () : _sec(0), _min(0), _hour(0), _day(0), _month(0), _year(0) {}

    DateRel (ptime_t year, ptime_t mon = 0, ptime_t day=0, ptime_t hour=0, ptime_t min=0, ptime_t sec=0)
                     : _sec(sec), _min(min), _hour(hour), _day(day), _month(mon), _year(year) {}

    explicit DateRel (string_view str, int fmt = InputFormat::all) { _error = parse(str, fmt); }

    DateRel (const Date& from, const Date& till)               { set(from, till); }
    DateRel (const string_view& from, const string_view& till) { set(Date(from), Date(till)); }
    DateRel (const DateRel& source)                            { operator=(source); }

    void set (const Date&, const Date&);
    void set (const string_view& from, const string_view& till) { set(Date(from), Date(till)); }

    DateRel& operator= (string_view str) { _error = parse(str, InputFormat::all); return *this; }

    DateRel& operator= (const DateRel& source) {
        _sec   = source._sec;
        _min   = source._min;
        _hour  = source._hour;
        _day   = source._day;
        _month = source._month;
        _year  = source._year;
        _from  = source._from;
        _error = source._error;
        return *this;
    }

    std::error_code error () const { return _error; }

    ptime_t sec   () const { return _sec; }
    ptime_t min   () const { return _min; }
    ptime_t hour  () const { return _hour; }
    ptime_t day   () const { return _day; }
    ptime_t month () const { return _month; }
    ptime_t year  () const { return _year; }

    const optional<Date>& from  () const { return _from; }
          optional<Date>& from  ()       { return _from; }
          optional<Date>  till  () const { return _from ? (*_from + *this) : optional<Date>(); }

    DateRel& sec   (ptime_t val)   { _sec = val; return *this; }
    DateRel& min   (ptime_t val)   { _min = val; return *this; }
    DateRel& hour  (ptime_t val)   { _hour = val; return *this; }
    DateRel& day   (ptime_t val)   { _day = val; return *this; }
    DateRel& month (ptime_t val)   { _month = val; return *this; }
    DateRel& year  (ptime_t val)   { _year = val; return *this; }
    DateRel& from  (const Date& v) { _from = v; return *this; }

    bool empty () const { return (_sec | _min | _hour | _day | _month | _year) == 0; }

    ptime_t duration () const {
        if (_from) return (*_from + *this).epoch() - _from->epoch();
        else       return _sec + _min*60 + _hour*3600 + _day * 86400 + (_month + 12*_year) * 2629744;
    }

    ptime_t to_secs  () const { return duration(); }
    double  to_mins  () const { return double(duration()) / 60; }
    double  to_hours () const { return double(duration()) / 3600; }

    double to_days () const {
        if (_from) {
            auto till = *_from + *this;
            return panda::time::christ_days(till.year()) - panda::time::christ_days(_from->year()) +
                   till.yday()  - _from->yday() + double(hms_diff(till)) / 86400;
        }
        else return double(duration()) / 86400;
    }

    double to_months () const {
        if (_from) {
            auto till = *_from + *this;
            return (till.year() - _from->year())*12 + till.month() - _from->month() +
                   double(till.day() - _from->day() + double(hms_diff(till)) / 86400) / _from->days_in_month();
        }
        else return double(duration()) / 2629744;
    }

    double to_years () const { return to_months() / 12; }

    string to_string (Format fmt = Format::simple) const;

    DateRel& operator+= (const DateRel&);
    DateRel& operator-= (const DateRel&);
    DateRel& operator*= (double koef);
    DateRel& operator/= (double koef);
    DateRel  operator-  () const { return negated(); }
    DateRel& negate     ();

    DateRel negated () const { return DateRel(*this).negate(); }

    ptime_t compare (const DateRel& operand) const { return duration() - operand.duration(); }

    bool is_same (const DateRel& operand) const {
        return _sec == operand._sec && _min == operand._min && _hour == operand._hour &&
               _day == operand._day && _month == operand._month && _year == operand._year && _from == operand._from;
    }

    int includes (const Date& date) const {
        if (!_from) return 0;
        if (*_from > date) return 1;
        if ((*_from + *this) < date) return -1;
        return 0;
    }

private:
    ptime_t        _sec;
    ptime_t        _min;
    ptime_t        _hour;
    ptime_t        _day;
    ptime_t        _month;
    ptime_t        _year;
    optional<Date> _from;
    errc           _error = errc::ok;

    errc parse (string_view, int);

    ptime_t hms_diff (const Date& till) const {
        return (till.hour() - _from->hour())*3600 + (till.min() - _from->min())*60 + till.sec() - _from->sec();
    }
};

#undef SEC // fuck solaris

extern const DateRel YEAR;
extern const DateRel MONTH;
extern const DateRel WEEK;
extern const DateRel DAY;
extern const DateRel HOUR;
extern const DateRel MIN;
extern const DateRel SEC;

std::ostream& operator<< (std::ostream&, const DateRel&);

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

inline DateRel operator- (const Date& lhs, const Date& rhs)       { return DateRel(rhs, lhs); }

}}
