#pragma once
#include <cmath>
#include <time.h>
#include <cstdint>
#include <errno.h>
#include <system_error>
#include <panda/string.h>
#include <panda/date/inc.h>
#include <panda/date/parse.h>

namespace panda { namespace date {

using panda::time::TimezoneSP;
using panda::time::datetime;
using panda::time::days_in_month;
using panda::time::tzget;
using panda::time::tzlocal;

struct DateRel;

constexpr const uint32_t MICROSECONDS_IN_SECOND = 1000000;
constexpr const ptime_t  MAX_MICROSECONDS       = 9223372036854000000;

struct Date {
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

    explicit Date (ptime_t epoch = 0, const TimezoneSP& zone = TimezoneSP()) : _error(E_OK) { set(epoch, zone); }

    template <class T, typename = std::enable_if_t<std::is_floating_point<T>::value>> // otherwise would be ambiguity with previous ctor if passed not ptime_t and not double
    explicit Date (T epoch, const TimezoneSP& zone = TimezoneSP()) : _error(E_OK) { set(epoch, zone); }

    Date (ptime_t epoch, ptime_t mksec, const TimezoneSP& zone = TimezoneSP()) : _error(E_OK) { set(epoch, mksec, zone); }

    explicit Date (string_view str, const TimezoneSP& zone = TimezoneSP()) { set(str, zone); }

    Date (int32_t year, ptime_t mon, ptime_t day, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0, ptime_t mksec = 0, int isdst = -1, const TimezoneSP& zone = TimezoneSP()) {
        set(year, mon, day, hour, min, sec, mksec, isdst, zone);
    }

    Date (const Date& source, const TimezoneSP& zone = TimezoneSP()) { set(source, zone); }

    void set (ptime_t ep, const TimezoneSP& zone = TimezoneSP()) {
        _zone_set(zone);
        epoch(ep);
    }

    void set (ptime_t ep, ptime_t mksec, const TimezoneSP& zone = TimezoneSP()) {
        if (mksec >= 0 && mksec < MICROSECONDS_IN_SECOND) {
            set(ep, zone);
            _mksec = mksec;
        } else {
            auto tmp = (uint64_t)(mksec + MAX_MICROSECONDS) % MICROSECONDS_IN_SECOND;
            set((ptime_t)(ep + (mksec - tmp) / MICROSECONDS_IN_SECOND), zone);
            _mksec = tmp;
        }
    }

    void set (double ep, const TimezoneSP& zone = TimezoneSP()) {
        _zone_set(zone);
        epoch(ep);
    }

    err_t set (string_view str, const TimezoneSP& zone = TimezoneSP()) {
        TimezoneSP instring_zone;
        _mksec = 0;
        _error = parse(str, _date, &_mksec, instring_zone); // parse() can parse and create zone
        _zone_set(instring_zone ? instring_zone : zone);

        if (_error == E_OK) {
            _has_date = true;
            dchg_auto();
            if (_range_check) validate_range();
        }
        else epoch(0);

        return (err_t)_error;
    }

    err_t set (int32_t year, ptime_t month, ptime_t day, ptime_t hour = 0, ptime_t min = 0, ptime_t sec = 0, ptime_t mksec = 0, int isdst= -1, const TimezoneSP& zone = TimezoneSP()) {
        _zone_set(zone);
        _error      = E_OK;
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

        return (err_t)_error;
    }

    void set (const Date& source, const TimezoneSP& zone = TimezoneSP()) {
        _error = source._error;
        if (!zone || _error) {
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

    Date& operator= (const Date& source) { set(source); return *this; }

    Date clone (int32_t year, ptime_t mon=-1, ptime_t day=-1, ptime_t hour=-1, ptime_t min=-1, ptime_t sec=-1, ptime_t mksec=-1, int isdst=-1, const TimezoneSP& zone = TimezoneSP()) const {
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

    const datetime&   date       () const    { dcheck(); return _date; }
    bool              has_epoch  () const    { return _has_epoch; }
    bool              has_date   () const    { return _has_date; }
    bool              normalized () const    { return _normalized; }
    err_t             error      () const    { return (err_t) _error; }
    void              error      (err_t val) { error_set(val); }
    const TimezoneSP& timezone   () const    { return _zone; }

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
    void    epoch (ptime_t val) {
        namespace pt = panda::time;
        _epoch = val;
        _mksec = 0;
        _has_epoch = true;
        echg();
        if ((val > pt::EPOCH_MAX) || (val < pt::EPOCH_MIN)) error_set(E_RANGE);
    }
    template <class T, typename = std::enable_if_t<std::is_floating_point<T>::value>> // otherwise ambiguity
    void epoch (T val) { epoch((ptime_t)val); _mksec = std::round((val - (ptime_t)val) * MICROSECONDS_IN_SECOND); }

    double  epoch_mks () const      { echeck(); return (double)_epoch + (double(_mksec) / MICROSECONDS_IN_SECOND); }
    void    epoch_mks (double val)  { epoch(val); }

    int32_t year   () const      { dcheck(); return _date.year; }
    void    year   (int32_t val) { dcheck(); _date.year = val; dchg_auto(); }
    int32_t c_year () const      { return year() - 1900; }
    void    c_year (int32_t val) { year(val + 1900); }
    int8_t  yr     () const      { return year() % 100; }
    void    yr     (int val)     { year( year() - yr() + val ); }

    uint8_t month   () const      { dcheck(); return _date.mon + 1; }
    void    month   (ptime_t val) { dcheck(); _date.mon = val - 1; dchg_auto(); }
    uint8_t c_month () const      { return month() - 1; }
    void    c_month (ptime_t val) { month(val + 1); }

    uint8_t mday () const      { dcheck(); return _date.mday; }
    void    mday (ptime_t val) { dcheck(); _date.mday = val; dchg_auto(); }
    uint8_t day  () const      { return mday(); }
    void    day  (ptime_t val) { mday(val); }

    uint8_t hour () const      { dcheck(); return _date.hour; }
    void    hour (ptime_t val) { dcheck(); _date.hour = val; dchg_auto(); }

    uint8_t min () const      { dcheck(); return _date.min; }
    void    min (ptime_t val) { dcheck(); _date.min = val; dchg_auto(); }

    uint8_t sec () const      { dcheck(); return _date.sec; }
    void    sec (ptime_t val) { dcheck(); _date.sec = val; dchg_auto(); }

    uint32_t mksec () const { return _mksec; }
    void     mksec (ptime_t val) {
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
    }

    uint8_t wday   () const      { dcheck(); return _date.wday + 1; }
    void    wday   (ptime_t val) { dcheck(); _date.mday += val - (_date.wday + 1); dchg_auto(); }
    uint8_t c_wday () const      { return wday() - 1; }
    void    c_wday (ptime_t val) { wday(val + 1); }
    uint8_t ewday  () const      { dcheck(); return _date.wday == 0 ? 7 : _date.wday; }
    void    ewday  (ptime_t val) { _date.mday += val - ewday(); dchg_auto(); }

    uint16_t yday   () const      { dcheck(); return _date.yday + 1; }
    void     yday   (ptime_t val) { dcheck(); _date.mday += val - 1 - _date.yday; dchg_auto(); }
    uint16_t c_yday () const      { return yday() - 1; }
    void     c_yday (ptime_t val) { yday(val + 1); }

    bool        isdst  () const { dcheck(); return _date.isdst > 0 ? true : false; }
    int32_t     gmtoff () const { dcheck(); return _date.gmtoff; }
    string_view tzabbr () const { dcheck(); return (const char*)_date.zone; }

    int days_in_month () const { dcheck(); return panda::time::days_in_month(_date.year, _date.mon); }

    Date& month_begin     ()       { mday(1); return *this; }
    Date& month_end       ()       { mday(days_in_month()); return *this; }
    Date  month_begin_new () const { Date ret(*this); ret.mday(1); return ret; }
    Date  month_end_new   () const { Date ret(*this); ret.mday(days_in_month()); return ret; }

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

    panda::string strftime (const char*, panda::string*) const;
    string_view errstr () const;

    panda::string to_string () const {
        panda::string result;
        if (!_error) {
            if (!_strfmt) iso(result);
            else this->strftime(_strfmt.c_str(), &result);
        }
        return result;
    }

    ptime_t compare (const Date&) const;

    Date& operator+= (const DateRel&);
    Date& operator-= (const DateRel&);

    panda::string iso () const;
    void iso (panda::string&) const;

    panda::string iso_sec () const;
    void iso_sec (panda::string&) const;

    panda::string mysql () const;
    void mysql (panda::string&) const;

    panda::string hms () const;
    void hms (panda::string&) const;

    panda::string ymd () const;
    void ymd (panda::string& ) const;

    panda::string mdy () const;
    void mdy (panda::string&) const;

    panda::string dmy () const;
    void dmy (panda::string& ) const;

    panda::string meridiam () const;
    void meridiam (panda::string& ) const;

    panda::string ampm () const;
    void ampm (panda::string&) const;

    static bool range_check ()         { return _range_check; }
    static void range_check (bool val) { _range_check = val; }

    static const string& string_format () { return _strfmt; }

    static void string_format (const string& fmt) { _strfmt = fmt; }

private:
    friend void swap (Date&, Date&);

    static string _strfmt;
    static bool   _range_check;

    TimezoneSP _zone;

    union {
                ptime_t _epoch;
        mutable ptime_t _epochMUT;
    };
    union {
                datetime _date;
        mutable datetime _dateMUT;
    };
    union {
                bool _has_epoch;
        mutable bool _has_epochMUT;
    };
    union {
                bool _has_date;
        mutable bool _has_dateMUT;
    };
    union {
                bool _normalized;
        mutable bool _normalizedMUT;
    };
    union {
                uint8_t _error;
        mutable uint8_t _errorMUT;
    };
    union {
                uint32_t _mksec;
        mutable uint32_t _mksecMUT;
    };

    void esync () const;
    void dsync () const;
    err_t validate_range ();

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
        _has_dateMUT = false;
        _normalizedMUT = false;
    }

    void error_set(err_t val) const {
        _errorMUT = val;
        _epochMUT = 0;
        _mksecMUT = 0;
        _has_epochMUT = true;
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

void swap (Date&, Date&);

}}
