#include "Date.h"
#include "DateRel.h"
#include "format.hpp"

namespace panda { namespace date {

string Date::_strfmt;
bool   Date::_range_check = false;

#define INPLACE_FORMAT(F) do {\
    using format_t = F; \
    dcheck(); \
    char buff[format_t::N + 1]; \
    char* buff_end = format_t::apply(buff, _date, &_mksec); \
    output.append(buff, buff_end - buff); \
} while (0)

void Date::esync () const { // w/o date normalization
    _has_epochMUT = true;
    _epochMUT = timeanyl(&_dateMUT, _zone);
}

void Date::dsync () const {
    _normalizedMUT = true;
    if (_has_epoch) { // no date -> calculate from epoch
        _has_dateMUT = true;
        bool success = anytime(_epoch, &_dateMUT, _zone);
        if (!success) error_set(E_RANGE);
    } else { // no epoch -> normalize from date (set epoch as a side effect as well)
        _has_epochMUT = true;
        _epochMUT = timeany(&_dateMUT, _zone);
    }
}

err_t Date::validate_range () {
    datetime old = _date;
    dsync();

    if (old.sec != _date.sec || old.min != _date.min || old.hour != _date.hour || old.mday != _date.mday ||
        old.mon != _date.mon || old.year != _date.year) {
        _error = E_RANGE;
        return E_RANGE;
    }

    return E_OK;
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

panda::string Date::strftime (const char* format, panda::string *output) const {
    dcheck();
    panda::string result;
    char stack_buff[1000];
    auto maxsize = 1000;
    size_t reslen = panda::time::strftime(stack_buff, maxsize, format, &_date);
    if (reslen > 0) {
        result = string(stack_buff, reslen);
        if (output) *output = result;
    }
    return result;
}

void Date::iso (panda::string& output) const {
    if (_mksec) INPLACE_FORMAT(format::iso_t);
    else        INPLACE_FORMAT(format::iso_sec_t);
}
TOSTR_WRAPPER(Date::iso, format::iso_t::N);


void Date::iso_sec (panda::string& output) const {
    INPLACE_FORMAT(format::iso_sec_t);
}
TOSTR_WRAPPER(Date::iso_sec, format::iso_sec_t::N);


void Date::mysql (panda::string& output) const {
    INPLACE_FORMAT(format::mysql_t);
}
TOSTR_WRAPPER(Date::mysql , format::mysql_t::N);


void Date::hms (panda::string& output) const {
    INPLACE_FORMAT(format::hms_t);
}
TOSTR_WRAPPER(Date::hms, format::hms_t::N);


void Date::ymd (panda::string& output) const {
    INPLACE_FORMAT(format::ymd_t);
}
TOSTR_WRAPPER(Date::ymd, format::ymd_t::N);


void Date::mdy (panda::string& output) const {
    INPLACE_FORMAT(format::mdy_t);
}
TOSTR_WRAPPER(Date::mdy, format::mdy_t::N);


void Date::dmy (panda::string& output) const {
    INPLACE_FORMAT(format::dmy_t);
}
TOSTR_WRAPPER(Date::dmy, format::dmy_t::N);


void Date::meridiam (panda::string& output) const {
    INPLACE_FORMAT(format::meridiam_t);
}
TOSTR_WRAPPER(Date::meridiam, format::meridiam_t::N);


void Date::ampm (panda::string& output) const {
    INPLACE_FORMAT(format::ampm_t);
}
TOSTR_WRAPPER(Date::ampm, format::ampm_t::N);


string_view Date::errstr () const {
    switch (_error) {
        case E_OK:
            return string_view();
        case E_UNPARSABLE:
            return "can't parse date string";
        case E_RANGE:
            return "input date is out of range";
        default:
            return "unknown error";
    }
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

}}
