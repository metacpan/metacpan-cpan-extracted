#include "Date.h"
#include "DateRel.h"
#include "../time/format.h"
#include <ostream>

namespace panda { namespace date {

bool Date::_range_check = false;


Date Date::strptime (string_view str, string_view fmt) {
    Date d;
    d._strptime(str, fmt);
    if (d._error == errc::ok) {
        if (d._has_date) {
            d._has_date = true;
            d._has_epoch = false;
            d._normalized = false;
            d.dsync();
            d.dchg_auto();
            if (_range_check) d.validate_range();
        }
    }
    else d.epoch(0);
    return d;
}


inline static ptime_t epoch_cmp (ptime_t s1, uint32_t mks1, ptime_t s2, uint32_t mks2) {
    return (s1 == s2) ? (ptime_t)mks1 - mks2 : s1 - s2;
}

inline static ptime_t pseudo_epoch (const datetime& date) {
    return date.sec + date.min*61 + date.hour*60*61 + date.mday*24*60*61 + date.mon*31*24*60*61 + ptime_t(date.year)*12*31*24*60*61;
}

inline static ptime_t date_cmp (const datetime& d1, uint32_t mks1, const datetime& d2, uint32_t mks2) {
    return epoch_cmp(pseudo_epoch(d1), mks1, pseudo_epoch(d2), mks2);
}

ptime_t Date::today_epoch () {
    datetime date;
    localtime(::time(NULL), &date);
    date.sec = 0;
    date.min = 0;
    date.hour = 0;
    return timelocall(&date);
}

void Date::set (string_view str, const TimezoneSP& zone, int fmt) {
    if (zone) _zone = zone;
    parse(str, fmt); // parse() can parse and create zone

    if (_error == errc::ok) {
        _has_date = true;
        dchg_auto();
        if (_range_check) validate_range();
    }
    else epoch(0);
}

void Date::set (int32_t year, ptime_t month, ptime_t day, ptime_t hour, ptime_t min, ptime_t sec, ptime_t mksec, int isdst, const TimezoneSP& zone) {
    _zone_set(zone);
    _error      = errc::ok;
    _date.year  = year;
    _date.mon   = month - 1;
    _date.mday  = day;
    _date.hour  = hour;
    _date.min   = min;
    _date.sec   = sec;
    _date.isdst = isdst;
    _has_date   = true;

    if (mksec >= 0 && mksec < MICROSECONDS_IN_SECOND) _mksec = mksec;
    else {
        _mksec = (uint64_t)(mksec + MAX_MICROSECONDS) % MICROSECONDS_IN_SECOND;
        _date.sec += (mksec - _mksec) / MICROSECONDS_IN_SECOND;
    }

    dchg();
    if (_range_check) validate_range();
}

void Date::set (const Date& source, const TimezoneSP& zone) {
    _error = source._error;
    if (!zone || _error != errc::ok) {
        _has_epoch  = source._has_epoch;
        _has_date   = source._has_date;
        _normalized = source._normalized;
        _zone       = source._zone;
        _epoch      = source._epoch;
        _mksec      = source._mksec;
        if (_has_date) _date  = source._date;
    } else {
        source.dcheck();
        _has_epoch  = false;
        _has_date   = true;
        _normalized = source._normalized;
        _date       = source._date;
        _zone       = zone;
        _mksec      = source._mksec;
    }
}

void Date::esync () const { // w/o date normalization
    _has_epoch = true;
    _epoch = timeanyl(&_date, timezone());
}

void Date::dsync () const {
    _normalized = true;
    if (_has_epoch) { // no date -> calculate from epoch
        _has_date = true;
        bool success = anytime(_epoch, &_date, timezone());
        if (!success) error_set(errc::out_of_range);
    } else { // no epoch -> normalize from date (set epoch as a side effect as well)
        _has_epoch = true;
        _epoch = timeany(&_date, timezone());
    }
}

void Date::validate_range () {
    datetime old = _date;
    dsync();
    if (old.sec != _date.sec || old.min != _date.min || old.hour != _date.hour || old.mday != _date.mday ||
        old.mon != _date.mon || old.year != _date.year) {
        _error = errc::out_of_range;
    }
}

uint8_t Date::week_of_month () const {
    int thu = mday() + 4 - ewday();
    return (thu + 6) / 7;
}

void Date::week_of_month (uint8_t val) {
    int x = mday() + 1 - ewday(); // this week monday
    x += 7 * (val - week_of_month());
    if (x <= 0) x = 1;
    auto days = days_in_month();
    if (x > days) x = days;
    mday(x);
}

uint8_t Date::weeks_in_year (int32_t year) {
    auto jan1wday = (panda::time::christ_days(year) % 7) + 1;
    // Years starting with a Thursday and leap years starting with a Wednesday have 53 weeks.
    return (jan1wday == 4 || (jan1wday == 3 && panda::time::is_leap_year(year))) ? 53 : 52;
}

Date::WeekOfYear Date::week_of_year () const {
    uint8_t week = (yday() + 10 - ewday()) / 7;
    WeekOfYear ret = {week, year()};
    if (week == 0) {
        --ret.year;
        ret.week = weeks_in_year(ret.year);
    }
    else if (week == 53 && weeks_in_year(ret.year) == 52) {
        ++ret.year;
        ret.week = 1;
    }
    return ret;
}

ptime_t Date::compare (const Date& operand) const {
    if (_has_epoch && operand._has_epoch) return epoch_cmp(_epoch, _mksec, operand._epoch, operand._mksec);
    else if (_zone != operand._zone) return epoch_cmp(epoch(), _mksec, operand.epoch(), operand._mksec);
    else return date_cmp(date(), _mksec, operand.date(), operand._mksec);
    return 0;
}

Date& Date::operator+= (const DateRel& operand) {
    if (operand.year() | operand.month() | operand.day()) {
        dcheck();
        _date.year += operand.year();
        _date.mon  += operand.month();
        _date.mday += operand.day();
        _date.hour += operand.hour();
        _date.min  += operand.min();
        _date.sec  += operand.sec();
        dchg_auto();
    } else {
        echeck();
        _epoch += operand.sec() + operand.min()*60 + operand.hour()*3600;
        echg();
    }
    return *this;
}

Date& Date::operator-= (const DateRel& operand) {
    if (operand.year() | operand.month() | operand.day()) {
        dcheck();
        _date.mday -= operand.day();
        _date.mon  -= operand.month();
        _date.year -= operand.year();
        _date.hour -= operand.hour();
        _date.min  -= operand.min();
        _date.sec  -= operand.sec();
        dchg_auto();
    } else {
        echeck();
        _epoch -= operand.sec() + operand.min()*60 + operand.hour()*3600;
        echg();
    }
    return *this;
}

static constexpr const int32_t WEEK_1_OFFSETS[] = {0, -1, -2, -3, 4, 3, 2};
static constexpr const int32_t WEEK_2_OFFSETS[] = {8, 7, 6, 5, 9, 10, 9};

void Date::_post_parse_week(unsigned week) {
    // convert from week to mday for YYYY-Wnn[-nn] format
    if (week) {
        auto days_since_christ = panda::time::christ_days(_date.year);
        int32_t beginning_weekday = days_since_christ % 7;
        if (!_date.wday) _date.wday = 1;
        if (week == 1) {
            _date.mday = WEEK_1_OFFSETS[beginning_weekday] + (_date.wday - 1);
        }
        else {
            _date.mday = WEEK_2_OFFSETS[beginning_weekday] + (_date.wday - 1) + 7 * (week - 2);
        }
    }
    else if (_date.wday) { // check wday number if included in date
        if (_date.wday != panda::time::wday(_date.year, _date.mon, _date.mday)) {
            _error = errc::out_of_range;
            return;
        }
    }
}

using namespace panda::time::format;
using iso_t          = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<' '>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_mksec>;
using iso_tz_t       = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<' '>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_mksec, tag_tzoff>;
using iso_date_t     = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day>;
using iso8601_t      = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<'T'>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_mksec, tag_tzoff>;
using iso8601_notz_t = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<'T'>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_mksec>;
using rfc1123_t      = exp_t<tag_wday_short, tag_char<','>, tag_char<' '>, tag_day, tag_char<' '>, tag_month_short, tag_char<' '>, tag_year, tag_char<' '>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_char<' '>, tag_tz1123>;
using rfc850_t       = exp_t<tag_wday_long, tag_char<','>, tag_char<' '>, tag_day, tag_char<'-'>, tag_month_short, tag_char<'-'>, tag_yr, tag_char<' '>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_char<' '>, tag_tz1123>;
using ymd_s_t        = exp_t<tag_year,  tag_char<'/'>, tag_month, tag_char<'/'>, tag_day>;
using dot_t          = exp_t<tag_day,   tag_char<'.'>, tag_month, tag_char<'.'>, tag_year>;
using clf            = exp_t<tag_day, tag_char<'/'>, tag_month_short, tag_char<'/'>, tag_year, tag_char<':'>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_char<' '>, tag_tzoff_void>;
using clfb           = exp_t<tag_char<'['>, tag_day, tag_char<'/'>, tag_month_short, tag_char<'/'>, tag_year, tag_char<':'>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_char<' '>, tag_tzoff_void, tag_char<']'>>;

#define INPLACE_FORMAT(FMT) do {                    \
    char buf[FMT::length + 1];                      \
    char* buf_end = FMT::apply(buf, _date, _mksec); \
    output.append(buf, buf_end - buf);              \
} while (0)

string Date::to_string (Format fmt) const {
    if (_error != errc::ok) return {};
    dcheck();
    string output;
    switch (fmt) {
        case Format::iso          : INPLACE_FORMAT(iso_t); break;
        case Format::iso_date     : INPLACE_FORMAT(iso_date_t); break;
        case Format::iso_tz       : INPLACE_FORMAT(iso_tz_t); break;
        case Format::iso8601      : INPLACE_FORMAT(iso8601_t); break;
        case Format::iso8601_notz : INPLACE_FORMAT(iso8601_notz_t); break;
        case Format::rfc1123      : INPLACE_FORMAT(rfc1123_t); break;
        case Format::rfc850       : INPLACE_FORMAT(rfc850_t); break;
        case Format::ansi_c       : INPLACE_FORMAT(ansi_c_t); break;
        case Format::ymd          : INPLACE_FORMAT(ymd_s_t); break;
        case Format::dot          : INPLACE_FORMAT(dot_t); break;
        case Format::hms          : INPLACE_FORMAT(hms_t); break;
        case Format::clf          : INPLACE_FORMAT(clf); break;
        case Format::clfb         : INPLACE_FORMAT(clfb); break;
        default: throw std::invalid_argument("unknown format type for date output");
    }
    return output;
}

void swap (Date& a, Date& b) {
    using std::swap;
    swap(a._zone, b._zone);
    swap(a._date, b._date);
    swap(a._has_epoch, b._has_epoch);
    swap(a._has_date, b._has_date);
    swap(a._normalized, b._normalized);
    swap(a._error, b._error);
    swap(a._mksec, b._mksec);
}

std::ostream& operator<< (std::ostream& os, const Date& d) {
    return os << d.to_string();
}

}}
