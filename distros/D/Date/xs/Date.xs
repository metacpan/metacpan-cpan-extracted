#include <xs/time.h>
#include <xs/date/util.h>

using namespace xs;
using namespace xs::date;
using panda::string;
using panda::string_view;

MODULE = Date::Date                PACKAGE = Date
PROTOTYPES: DISABLE

#///////////////////////////// STATIC FUNCTIONS ///////////////////////////////////

Date* now () {
    RETVAL = new Date(Date::now());
}

Date* now_hires () {
    RETVAL = new Date(Date::now_hires());
}

Date* today () {
    RETVAL = new Date(Date::today());
}

ptime_t today_epoch () {
    datetime date;
    localtime(::time(NULL), &date);
    date.sec = 0;
    date.min = 0;
    date.hour = 0;
    RETVAL = timelocall(&date);
}

Date* date (SV* date = NULL, SV* zone = NULL) {
    RETVAL = new Date(sv2date(date, tzget_optional(zone)));
}

string string_format (Simple newval = Simple()) {
    if (newval) {
        if (newval.defined()) Date::string_format(string((string_view)newval));
        else Date::string_format(string());
    }
    RETVAL = Date::string_format();
    if (!RETVAL) XSRETURN_UNDEF;
}

bool range_check (Simple newval = Simple()) {
    if (newval) Date::range_check(newval.defined() && newval.is_true());
    RETVAL = Date::range_check();
}

#///////////////////////////// OBJECT METHODS ///////////////////////////////////

Date* new (SV*, SV* date = NULL, SV* zone = NULL) {
    RETVAL = new Date(sv2date(date, tzget_optional(zone)));
}

void Date::set (SV* arg, SV* zone = NULL) {
    THIS->set(sv2date(arg, tzget_optional(zone)));
}

void Date::epoch (SV* newval = NULL) {
    if (newval) {
        if (SvNOK(newval)) THIS->epoch((double)SvNV(newval));
        else THIS->epoch(xs::in<ptime_t>(newval));
        XSRETURN(1);
    }
    dXSTARG; XSprePUSH;
    if (THIS->mksec()) PUSHn(THIS->epoch_mks());
    else               PUSHi(THIS->epoch());
}

ptime_t Date::epoch_sec () {
    RETVAL = THIS->epoch();
}

int32_t Date::year (SV* newval = NULL) {
    if (newval) THIS->year(xs::in<ptime_t>(newval));
    RETVAL = THIS->year();
}

int32_t Date::c_year (SV* newval = NULL) : ALIAS(_year=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->c_year(xs::in<ptime_t>(newval));
    RETVAL = THIS->c_year();
}

int8_t Date::yr (SV* newval = NULL) {
    if (newval) THIS->yr(xs::in<ptime_t>(newval));
    RETVAL = THIS->yr();
}

uint8_t Date::month (SV* newval = NULL) : ALIAS(mon=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->month(xs::in<ptime_t>(newval));
    RETVAL = THIS->month();
}

uint8_t Date::c_month (SV* newval = NULL) : ALIAS(c_mon=1, _mon=2, _month=3) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->c_month(xs::in<ptime_t>(newval));
    RETVAL = THIS->c_month();
}

uint8_t Date::day (SV* newval = NULL) : ALIAS(mday=1, day_of_month=2) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->day(xs::in<ptime_t>(newval));
    RETVAL = THIS->day();
}

uint8_t Date::hour (SV* newval = NULL) {
    if (newval) THIS->hour(xs::in<ptime_t>(newval));
    RETVAL = THIS->hour();
}

uint8_t Date::min (SV* newval = NULL) : ALIAS(minute=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->min(xs::in<ptime_t>(newval));
    RETVAL = THIS->min();
}

uint8_t Date::sec (SV* newval = NULL) : ALIAS(second=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->sec(xs::in<ptime_t>(newval));
    RETVAL = THIS->sec();
}

uint32_t Date::mksec (SV* newval = NULL) {
    if (newval) THIS->mksec(xs::in<ptime_t>(newval));
    RETVAL = THIS->mksec();
}

uint8_t Date::wday (SV* newval = NULL) : ALIAS(day_of_week=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->wday(xs::in<ptime_t>(newval));
    RETVAL = THIS->wday();
}

uint8_t Date::c_wday (SV* newval = NULL) : ALIAS(_wday=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->c_wday(xs::in<ptime_t>(newval));
    RETVAL = THIS->c_wday();
}

uint8_t Date::ewday (SV* newval = NULL) {
    if (newval) THIS->ewday(xs::in<ptime_t>(newval));
    RETVAL = THIS->ewday();
}

uint16_t Date::yday (SV* newval = NULL) : ALIAS(day_of_year=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->yday(xs::in<ptime_t>(newval));
    RETVAL = THIS->yday();
}

uint16_t Date::c_yday (SV* newval = NULL) : ALIAS(_yday=1) {
    PERL_UNUSED_VAR(ix);
    if (newval) THIS->c_yday(xs::in<ptime_t>(newval));
    RETVAL = THIS->c_yday();
}

bool Date::isdst () : ALIAS(daylight_savings=1) {
    PERL_UNUSED_VAR(ix);
    RETVAL = THIS->isdst();
}

string Date::to_string (...) : ALIAS(as_string=1, string=2) {
    PERL_UNUSED_VAR(ix);
    if (THIS->error()) XSRETURN_UNDEF;
    RETVAL = THIS->to_string();
}

bool Date::to_bool (...) {
    RETVAL = THIS->error() == E_OK ? true : false;
}

ptime_t Date::to_number (...) {
    RETVAL = THIS->error() == E_OK ? THIS->epoch() : 0;
}

string Date::strftime (const char* format) {
    RETVAL = THIS->strftime(format, NULL);
}

string Date::monthname () : ALIAS(monname=1) {
    RETVAL = THIS->strftime("%B", NULL);
    PERL_UNUSED_VAR(ix);
}

string Date::wdayname () : ALIAS(day_of_weekname=1) {
    RETVAL = THIS->strftime("%A", NULL);
    PERL_UNUSED_VAR(ix);
}

string Date::iso () : ALIAS(sql=1) {
    RETVAL = THIS->iso();
    PERL_UNUSED_VAR(ix);
}

string Date::iso_sec ()

string Date::mysql ()

string Date::hms ()

string Date::ymd ()

string Date::mdy ()

string Date::dmy ()

string Date::ampm ()

string Date::meridiam ()

int Date::gmtoff ()

string_view Date::tzabbr ()

string Date::tzname () {
    RETVAL = THIS->timezone()->name;
}

bool Date::tzlocal () {
    RETVAL = THIS->timezone()->is_local;
}

TimezoneSP Date::tz (SV* newzone = NULL) : ALIAS(timezone=1, zone=2) {
    if (newzone) {
        THIS->timezone(tzget_required(newzone));
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->timezone();
    PERL_UNUSED_VAR(ix);
}

void Date::to_tz (SV* newzone) : ALIAS(to_timezone=1, to_zone=2) {
    THIS->to_timezone(tzget_required(newzone));
    PERL_UNUSED_VAR(ix);
}

void Date::array () {
    auto cnt = THIS->mksec() ? 7 : 6;
    EXTEND(SP, cnt);
    mPUSHi(THIS->year());
    mPUSHu(THIS->month());
    mPUSHu(THIS->day());
    mPUSHu(THIS->hour());
    mPUSHu(THIS->min());
    mPUSHu(THIS->sec());
    if (THIS->mksec()) mPUSHu(THIS->mksec());
    XSRETURN(cnt);
}

Array Date::aref () {
    RETVAL = Array::create();
    auto cnt = THIS->mksec() ? 7 : 6;
    RETVAL.reserve(cnt);
    RETVAL.store(0, Simple(THIS->year()));
    RETVAL.store(1, Simple(THIS->month()));
    RETVAL.store(2, Simple(THIS->day()));
    RETVAL.store(3, Simple(THIS->hour()));
    RETVAL.store(4, Simple(THIS->min()));
    RETVAL.store(5, Simple(THIS->sec()));
    if (THIS->mksec()) RETVAL.store(6, Simple(THIS->mksec()));
}

void Date::struct () {
    EXTEND(SP, 9);
    mPUSHu(THIS->sec());
    mPUSHu(THIS->min());
    mPUSHu(THIS->hour());
    mPUSHu(THIS->day());
    mPUSHu(THIS->c_month());
    mPUSHi(THIS->c_year());
    mPUSHu(THIS->c_wday());
    mPUSHu(THIS->c_yday());
    mPUSHu(THIS->isdst() ? 1 : 0);
    XSRETURN(9);
}

Array Date::sref () {
    RETVAL = Array::create();
    RETVAL.reserve(8);
    RETVAL.store(0, Simple(THIS->sec()));
    RETVAL.store(1, Simple(THIS->min()));
    RETVAL.store(2, Simple(THIS->hour()));
    RETVAL.store(3, Simple(THIS->day()));
    RETVAL.store(4, Simple(THIS->c_month()));
    RETVAL.store(5, Simple(THIS->c_year()));
    RETVAL.store(6, Simple(THIS->c_wday()));
    RETVAL.store(7, Simple(THIS->c_yday()));
    RETVAL.store(8, Simple(THIS->isdst() ? 1 : 0));
}

void Date::hash () {
    int cnt = 12;
    if (THIS->mksec()) cnt = 14;
    
    EXTEND(SP, cnt);
    mPUSHp("year", 4);
    mPUSHi(THIS->year());
    mPUSHp("month", 5);
    mPUSHu(THIS->month());
    mPUSHp("day", 3);
    mPUSHu(THIS->day());
    mPUSHp("hour", 4);
    mPUSHu(THIS->hour());
    mPUSHp("min", 3);
    mPUSHu(THIS->min());
    mPUSHp("sec", 3);
    mPUSHu(THIS->sec());
    if (THIS->mksec()) {
        mPUSHp("mksec", 5);
        mPUSHu(THIS->mksec());
    }
    
    XSRETURN(cnt);
}

Hash Date::href () {
    RETVAL = Hash::create();
    RETVAL.store("year",  Simple(THIS->year()));
    RETVAL.store("month", Simple(THIS->month()));
    RETVAL.store("day",   Simple(THIS->day()));
    RETVAL.store("hour",  Simple(THIS->hour()));
    RETVAL.store("min",   Simple(THIS->min()));
    RETVAL.store("sec",   Simple(THIS->sec()));
    if (THIS->mksec()) RETVAL.store("mksec", Simple(THIS->mksec()));
}

Date* Date::clone (SV* diff = NULL, SV* zoneSV = NULL) {
    if (diff) {
        auto zone = tzget_optional(zoneSV);
        if (SvOK(diff)) {
            if (!SvRV(diff)) throw "bad argument type";
            diff = SvRV(diff);
            ptime_t vals[] = {-1, -1, -1, -1, -1, -1, -1, -1};
            if (SvTYPE(diff) == SVt_PVHV) {
                Hash hash = (HV*)diff;
                hash2vals(hash, vals, &zone);
            }
            else if (SvTYPE(diff) == SVt_PVAV) {
                Array arr = (AV*)diff;
                array2vals(arr, vals);
            }
            else throw "bad argument type";
            RETVAL = new Date(THIS->clone(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], zone));
        }
        else RETVAL = new Date(*THIS, zone);
    }
    else RETVAL = new Date(*THIS);
    PROTO = Object(ST(0)).stash();
}

SV* Date::month_begin () {
    THIS->month_begin();
    XSRETURN(1);
}

Date* Date::month_begin_new () {
    RETVAL = new Date(THIS->month_begin_new());
    PROTO = Object(ST(0)).stash();
}

SV* Date::month_end () {
    THIS->month_end();
    XSRETURN(1);
}

Date* Date::month_end_new () {
    RETVAL = new Date(THIS->month_end_new());
    PROTO = Object(ST(0)).stash();
}

int Date::days_in_month () {
    RETVAL = THIS->days_in_month();
}

uint8_t Date::error () {
    RETVAL = (uint8_t) THIS->error();
}

string_view Date::errstr ()

SV* Date::truncate () {
    THIS->truncate();
    XSRETURN(1);
}

Date* Date::truncated () : ALIAS(truncate_new=1) {
    if (ix == 1) warn("truncate_new() is deprecated, use truncated() instead");
    RETVAL = new Date(THIS->truncated());
    PROTO = Object(ST(0)).stash();
}

int Date::compare (Sv arg, bool reverse = false) {
    RETVAL = THIS->compare(sv2date(arg, THIS->timezone(), true, true));
    if (reverse) RETVAL = -RETVAL;
    if      (RETVAL < 0) RETVAL = -1;
    else if (RETVAL > 0) RETVAL = 1;
}

Date* Date::sum (Sv arg, ...) : ALIAS(add_new=1) {
    if (ix == 1) warn("add_new() is deprecated, use sum() instead");
    RETVAL = new Date(*THIS + sv2daterel(arg));
    PROTO = Object(ST(0)).stash();
}

SV* Date::add (Sv arg, ...) {
    *THIS += sv2daterel(arg);
    XSRETURN(1);
}

Sv Date::difference (Sv arg, bool reverse = false) : ALIAS(subtract_new=1) {
    if (ix == 1) warn("subtract_new() is deprecated, use difference() instead");
    if (arg.is_object_ref()) { // reverse is impossible here
        if (Object(arg).stash().name() == "Date::Rel")
            RETVAL = xs::out(new Date(*THIS - *xs::in<const DateRel*>(arg)), Object(ST(0)).stash());
        else
            RETVAL = xs::out(new DateInt(*xs::in<Date*>(arg), *THIS));
    }
    else if (reverse) { // only date supported for reverse
        RETVAL = xs::out(new DateInt(*THIS, sv2date(arg, THIS->timezone())));
    }
    else if (looks_like_number(arg)) {
        auto ret = new Date(*THIS);
        ret->epoch(ret->epoch() - xs::in<ptime_t>(arg));
        RETVAL = xs::out(ret, Object(ST(0)).stash());
    }
    else { // date or rdate scalar
        if (looks_like_relative(xs::in<string_view>(arg))) { // not a date -> reldate
            RETVAL = xs::out(new Date(*THIS - sv2daterel(arg)), Object(ST(0)).stash());
        } else { // date
            RETVAL = xs::out(new DateInt(sv2date(arg, THIS->timezone()), *THIS));
        }
    }
}

SV* Date::subtract (Sv arg, ...) {
    *THIS -= sv2daterel(arg);
    XSRETURN(1);
}

void __assign_stub (...) {
    if (!items) throw "should not happen";
    XSRETURN(1);
}
