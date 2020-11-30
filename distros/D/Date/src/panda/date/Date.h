#pragma once
#include "error.h"
#include "../time.h"
#include <math.h>
#include <time.h>
#include <errno.h>
#include <stdint.h>
#include <system_error>
#include <panda/memory.h>

namespace panda { namespace date {

using panda::time::ptime_t;
using panda::time::TimezoneSP;
using panda::time::datetime;
using panda::time::tzlocal;

struct DateRel;

constexpr const uint32_t MICROSECONDS_IN_SECOND = 1000000;
constexpr const ptime_t  MAX_MICROSECONDS       = 9223372036854000000;

struct Date {
    enum class Format {iso, iso_tz, iso_date, iso8601, iso8601_notz, rfc1123, rfc850, ansi_c, ymd, dot, hms, clf, clfb, cookie = rfc1123};

    struct InputFormat {
        static const int iso     = 1;
        static const int iso8601 = 2;
        static const int rfc1123 = 4;
        static const int rfc850  = 8;
        static const int ansi_c  = 16;
        static const int dot     = 32;
        static const int clf     = 64;
        static const int all     = ~0;
    };

    struct WeekOfYear {
        uint8_t week;
        int32_t year;
    };

    static inline Date now () { return Date(::time(NULL)); }

    static inline Date now_hires (clockid_t clock_id = CLOCK_REALTIME) {
        struct timespec ts;
        int status = clock_gettime(clock_id, &ts);
        if (status == 0) {
            auto ret = Date(ts.tv_sec);
            ret._mksec = ts.tv_nsec / 1000;
            return ret;
        }
        throw std::system_error(errno, std::generic_category(), "clock_gettime");
    }

    static inline Date today () {
        Date ret = now();
        ret.truncate();
        return ret;
    }

    Date () { set((ptime_t)0, nullptr); }

    explicit Date (ptime_t epoch, const TimezoneSP& zone = {}) { set(epoch, zone); }

    template <class T, typename = std::enable_if_t<std::is_floating_point<T>::value>> // otherwise would be ambiguity with previous ctor if passed not ptime_t and not double
    explicit Date (T epoch, const TimezoneSP& zone = {}) { set(epoch, zone); }

    Date (ptime_t epoch, ptime_t mksec, const TimezoneSP& zone = {}) { set(epoch, mksec, zone); }

    explicit Date (string_view str, const TimezoneSP& zone = {}, int fmt = InputFormat::all) { set(str, zone, fmt); }

    Date (int32_t year, ptime_t mon, ptime_t day, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0, ptime_t mksec = 0, int isdst = -1, const TimezoneSP& zone = {}) {
        set(year, mon, day, hour, min, sec, mksec, isdst, zone);
    }

    Date (const Date& source, const TimezoneSP& zone = {}) { set(source, zone); }

    void set (ptime_t ep, const TimezoneSP& zone = {}) {
        _zone_set(zone);
        epoch(ep);
    }

    void set (ptime_t ep, ptime_t mksec, const TimezoneSP& zone = {}) {
        if (mksec >= 0 && mksec < MICROSECONDS_IN_SECOND) {
            set(ep, zone);
            _mksec = mksec;
        } else {
            auto tmp = (uint64_t)(mksec + MAX_MICROSECONDS) % MICROSECONDS_IN_SECOND;
            set((ptime_t)(ep + (mksec - tmp) / MICROSECONDS_IN_SECOND), zone);
            _mksec = tmp;
        }
    }

    void set (double ep, const TimezoneSP& zone = {}) {
        _zone_set(zone);
        epoch(ep);
    }

    void set (const Date& source, const TimezoneSP& zone = {});
    void set (string_view str, const TimezoneSP& zone = {}, int = InputFormat::all);
    void set (int32_t year, ptime_t month, ptime_t day, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0, ptime_t mksec = 0, int isdst= -1, const TimezoneSP& zone = {});

    Date& operator= (const Date& source) { set(source); return *this; }

    Date clone (int32_t year, ptime_t mon=-1, ptime_t day=-1, ptime_t hour=-1, ptime_t min=-1, ptime_t sec=-1, ptime_t mksec=-1, int isdst=-1, const TimezoneSP& zone = {}) const {
        dcheck();
        return Date(
            year  >= 0 ? year : _date.year,
            mon   >  0 ? mon  : _date.mon+1,
            day   >  0 ? day  : _date.mday,
            hour  >= 0 ? hour : _date.hour,
            min   >= 0 ? min  : _date.min,
            sec   >= 0 ? sec  : _date.sec,
            mksec >= 0 ? mksec : _mksec,
            isdst,
            zone ? zone : _zone
        );
    }

    const datetime&   date       () const { dcheck(); return _date; }
    bool              has_epoch  () const { return _has_epoch; }
    bool              has_date   () const { return _has_date; }
    bool              normalized () const { return _normalized; }
    std::error_code   error      () const { return _error; }
    const TimezoneSP& timezone   () const { return _zone; }

    void timezone (const TimezoneSP& zone) {
        dcheck();
        _zone = zone ? zone : tzlocal();
        dchg_auto();
    }

    void to_timezone (const TimezoneSP& zone) {
        echeck();
        _zone = zone ? zone : tzlocal();
        echg();
    }

    ptime_t epoch () const      { echeck(); return _epoch; }
    Date&   epoch (ptime_t val) {
        _epoch = val;
        _mksec = 0;
        _has_epoch = true;
        echg();
        if (val > panda::time::EPOCH_MAX || val < panda::time::EPOCH_MIN) error_set(errc::out_of_range);
        return *this;
    }
    template <class T, typename = std::enable_if_t<std::is_floating_point<T>::value>> // otherwise ambiguity
    Date& epoch (T val) { epoch((ptime_t)val); _mksec = std::round((val - (ptime_t)val) * MICROSECONDS_IN_SECOND); return *this; }

    double  epoch_mks () const      { echeck(); return (double)_epoch + (double(_mksec) / MICROSECONDS_IN_SECOND); }
    Date&   epoch_mks (double val)  { return epoch(val); }

    int32_t year   () const      { dcheck(); return _date.year; }
    Date&   year   (int32_t val) { dcheck(); _date.year = val; dchg_auto(); return *this; }
    int32_t c_year () const      { return year() - 1900; }
    Date&   c_year (int32_t val) { return year(val + 1900);}
    int8_t  yr     () const      { return year() % 100; }
    Date&   yr     (int val)     { return year( year() - yr() + val ); }

    uint8_t month   () const      { dcheck(); return _date.mon + 1; }
    Date&   month   (ptime_t val) { dcheck(); _date.mon = val - 1; dchg_auto(); return *this; }
    uint8_t c_month () const      { return month() - 1; }
    Date&   c_month (ptime_t val) { return month(val + 1); }

    uint8_t mday () const      { dcheck(); return _date.mday; }
    Date&   mday (ptime_t val) { dcheck(); _date.mday = val; dchg_auto(); return *this; }
    uint8_t day  () const      { return mday(); }
    Date&   day  (ptime_t val) { return mday(val); }

    uint8_t hour () const      { dcheck(); return _date.hour; }
    Date&   hour (ptime_t val) { dcheck(); _date.hour = val; dchg_auto(); return *this; }

    uint8_t min () const      { dcheck(); return _date.min; }
    Date&   min (ptime_t val) { dcheck(); _date.min = val; dchg_auto(); return *this; }

    uint8_t sec () const      { dcheck(); return _date.sec; }
    Date&   sec (ptime_t val) { dcheck(); _date.sec = val; dchg_auto(); return *this; }

    uint32_t mksec () const { return _mksec; }
    Date&    mksec (ptime_t val) {
        if (val >= 0 && val < MICROSECONDS_IN_SECOND) _mksec = val;
        else {
            _mksec = (uint64_t)(val + MAX_MICROSECONDS) % MICROSECONDS_IN_SECOND;
            ptime_t add_secs = (val - _mksec) / MICROSECONDS_IN_SECOND;
            if (_has_epoch) {
                _epoch += add_secs;
                echg();
            } else {
                _date.sec += add_secs;
                dchg_auto();
            }
        }
        return *this;
    }

    uint8_t wday   () const      { dcheck(); return _date.wday + 1; }
    Date&   wday   (ptime_t val) { dcheck(); _date.mday += val - (_date.wday + 1); dchg_auto(); return *this; }
    uint8_t c_wday () const      { return wday() - 1; }
    Date&   c_wday (ptime_t val) { return wday(val + 1); }
    uint8_t ewday  () const      { dcheck(); return _date.wday == 0 ? 7 : _date.wday; }
    Date&   ewday  (ptime_t val) { _date.mday += val - ewday(); dchg_auto(); return *this; }

    uint16_t yday   () const      { dcheck(); return _date.yday + 1; }
    Date&    yday   (ptime_t val) { dcheck(); _date.mday += val - 1 - _date.yday; dchg_auto(); return *this; }
    uint16_t c_yday () const      { return yday() - 1; }
    Date&    c_yday (ptime_t val) { return yday(val + 1); }

    bool        isdst  () const { dcheck(); return _date.isdst > 0 ? true : false; }
    int32_t     gmtoff () const { dcheck(); return _date.gmtoff; }
    string_view tzabbr () const { dcheck(); return (const char*)_date.zone; }

    int days_in_month () const { dcheck(); return panda::time::days_in_month(_date.year, _date.mon); }

    Date& month_begin     ()       { mday(1); return *this; }
    Date& month_end       ()       { mday(days_in_month()); return *this; }
    Date  month_begin_new () const { Date ret(*this); ret.mday(1); return ret; }
    Date  month_end_new   () const { Date ret(*this); ret.mday(days_in_month()); return ret; }

    string_view month_name  () const { dcheck(); return panda::time::month_name(_date.mon); }
    string_view month_sname () const { dcheck(); return panda::time::month_sname(_date.mon); }
    string_view wday_name   () const { dcheck(); return panda::time::wday_name(_date.wday); }
    string_view wday_sname  () const { dcheck(); return panda::time::wday_sname(_date.wday); }

    uint8_t    week_of_month () const;
    void       week_of_month (uint8_t val);
    uint8_t    weeks_in_year () const { return weeks_in_year(year()); }
    WeekOfYear week_of_year  () const;

    Date& truncate () {
        dcheck();
        _date.hour = _date.min = _date.sec = _mksec = 0;
        dchg_auto();
        return *this;
    }

    Date truncated () const {
        Date ret(*this);
        ret.truncate();
        return ret;
    }

    string strftime (string_view fmt) const { dcheck(); return panda::time::strftime(fmt, _date); }

    string to_string (Format = Format::iso) const;

    ptime_t compare (const Date&) const;

    Date& operator+= (const DateRel&);
    Date& operator-= (const DateRel&);

    Date& operator+= (ptime_t sec) { echeck(); _epoch += sec; echg(); return *this; }
    Date& operator-= (ptime_t sec) { echeck(); _epoch -= sec; echg(); return *this; }

    static bool range_check ()         { return _range_check; }
    static void range_check (bool val) { _range_check = val; }

    static uint8_t weeks_in_year (int32_t year);

private:
    friend void swap (Date&, Date&);

    static bool _range_check;

    mutable ptime_t  _epoch;
    mutable datetime _date;
    TimezoneSP       _zone;
    mutable bool     _has_epoch;
    mutable bool     _has_date;
    mutable bool     _normalized;
    mutable errc     _error = errc::ok;
    mutable uint32_t _mksec;

    void parse (string_view, int);

    void esync () const;
    void dsync () const;
    void validate_range ();

    void echeck () const { if (!_has_epoch) esync(); }
    void dcheck () const { if (!_has_date || !_normalized) dsync(); };

    void dchg () {
        _has_epoch = false;
        _normalized = false;
    }

    void dchg_auto () {
        dchg();
        _date.isdst = -1;
    }

    void echg () const {
        _has_date = false;
        _normalized = false;
    }

    void error_set (errc val) const {
        _error = val;
        _epoch = 0;
        _mksec = 0;
        _has_epoch = true;
        echg();
    }

    void _zone_set (const TimezoneSP& zone) {
        if (!_zone) _zone = zone ? zone : tzlocal();
        else if (zone) _zone = zone;
    }
};

inline bool operator== (const Date& lhs, const Date& rhs) { return !lhs.compare(rhs); }
inline bool operator!= (const Date& lhs, const Date& rhs) { return lhs.compare(rhs); }
inline bool operator<  (const Date& lhs, const Date& rhs) { return lhs.compare(rhs) < 0; }
inline bool operator<= (const Date& lhs, const Date& rhs) { return lhs.compare(rhs) <= 0; }
inline bool operator>  (const Date& lhs, const Date& rhs) { return lhs.compare(rhs) > 0; }
inline bool operator>= (const Date& lhs, const Date& rhs) { return lhs.compare(rhs) >= 0; }

inline Date operator+ (const Date& d, const DateRel& dr) { return Date(d) += dr; }
inline Date operator+ (const DateRel& dr, const Date& d) { return Date(d) += dr; }
inline Date operator- (const Date& d, const DateRel& dr) { return Date(d) -= dr; }

inline Date operator+ (const Date& d, ptime_t sec) { return Date(d.epoch() + sec); }
inline Date operator+ (ptime_t sec, const Date& d) { return Date(d.epoch() + sec); }
inline Date operator- (const Date& d, ptime_t sec) { return Date(d.epoch() - sec); }

void swap (Date&, Date&);

}}
