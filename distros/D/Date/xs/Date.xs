#include <xs/date.h>
#include <xs/export.h>
#include "private.h"

using namespace xs;
using namespace xs::date;
using panda::string;
using panda::string_view;

#ifdef _WIN32
    const auto LT_FORMAT = string_view("%a %b %d %H:%M:%S %Y");
#else
    const auto LT_FORMAT = string_view("%a %b %e %H:%M:%S %Y");
#endif
    
// arguments overloading for new_ymd(), date_ymd(), ->set_ymd()
static inline Date xs_date_ymd (SV** args, I32 items) {
    ptime_t vals[8] = {1970, 1, 1, 0, 0, 0, 0, -1};
    auto tz = list2vals(args, items, vals);
    auto ret = Date(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], tz);
    if (ret.error() && is_strict_mode()) throw xs::out(ret.error());
    return ret;
}

MODULE = Date::Date                PACKAGE = Date
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    
    xs::exp::create_constants(stash, {
        {"FORMAT_ISO",          (int)Date::Format::iso},
        {"FORMAT_ISO_TZ",       (int)Date::Format::iso_tz},
        {"FORMAT_ISO_DATE",     (int)Date::Format::iso_date},
        {"FORMAT_ISO8601",      (int)Date::Format::iso8601},
        {"FORMAT_ISO8601_NOTZ", (int)Date::Format::iso8601_notz},
        {"FORMAT_RFC1123",      (int)Date::Format::rfc1123},
        {"FORMAT_COOKIE",       (int)Date::Format::cookie},
        {"FORMAT_RFC850",       (int)Date::Format::rfc850},
        {"FORMAT_ANSI_C",       (int)Date::Format::ansi_c},
        {"FORMAT_YMD",          (int)Date::Format::ymd},
        {"FORMAT_DOT",          (int)Date::Format::dot},
        {"FORMAT_HMS",          (int)Date::Format::hms},
        {"FORMAT_CLF",          (int)Date::Format::clf},
        {"FORMAT_CLF_BRACKETS", (int)Date::Format::clfb},
        
        {"INPUT_FORMAT_ALL",     Date::InputFormat::all},
        {"INPUT_FORMAT_ISO",     Date::InputFormat::iso},
        {"INPUT_FORMAT_ISO8601", Date::InputFormat::iso8601},
        {"INPUT_FORMAT_RFC1123", Date::InputFormat::rfc1123},
        {"INPUT_FORMAT_RFC850",  Date::InputFormat::rfc850},
        {"INPUT_FORMAT_ANSI_C",  Date::InputFormat::ansi_c},
        {"INPUT_FORMAT_DOT",     Date::InputFormat::dot},
        {"INPUT_FORMAT_CLF",     Date::InputFormat::clf},
    });
    
    Stash ecstash("Date::Error", GV_ADD);
    xs::exp::create_constants(ecstash, {
        {"parser_error", xs::out(make_error_code(errc::parser_error))},
        {"out_of_range", xs::out(make_error_code(errc::out_of_range))},
    });
    
    stash.add_const_sub("error_category", xs::out<const std::error_category*>(&error_category));
}

#///////////////////////////// STATIC FUNCTIONS ///////////////////////////////////

const Timezone* tzget (string_view zonename = {})

void tzset (TimezoneSP newzone = {})

string tzdir (SV* newdir = NULL) {
    if (newdir) {
        tzdir(xs::in<string>(newdir));
        XSRETURN_UNDEF;
    }
    RETVAL = tzdir();
}

string tzsysdir ()

string tzembededdir(SV* newdir = NULL) {
    if (newdir) {
        tzembededdir(xs::in<string>(newdir));
        XSRETURN_UNDEF;
    }
    RETVAL = tzembededdir();
}

void available_timezones () {
    auto list = available_timezones();
    if (list.size()) EXTEND(SP, (int)list.size());
    for (auto& name : list) {
        mPUSHs(xs::out(name).detach());
    }
    XSRETURN(list.size());
}

void use_system_timezones ()

void use_embed_timezones ()

void gmtime (SV* epochSV = {}, TimezoneSP tz = {}) : ALIAS(localtime=1, anytime=2) {
    ptime_t epoch;
    if (epochSV) epoch = xs::in<ptime_t>(epochSV);
    else epoch = (ptime_t) ::time(NULL);

    datetime date;
    bool success = false;
    switch (ix) {
        case 0: success = gmtime(epoch, &date);                       break;
        case 1: success = localtime(epoch, &date);                    break;
        case 2: success = anytime(epoch, &date, tz ? tz : tzlocal()); break;
    }

    if (GIMME_V == G_ARRAY) {
        if (!success) XSRETURN_EMPTY;
        EXTEND(SP, 9);
        EXTEND_MORTAL(9);
        mPUSHu(date.sec);
        mPUSHu(date.min);
        mPUSHu(date.hour);
        mPUSHu(date.mday);
        mPUSHu(date.mon);
        mPUSHi(date.year);
        mPUSHu(date.wday);
        mPUSHu(date.yday);
        mPUSHu(date.isdst);
        XSRETURN(9);
    } else {
        EXTEND(SP, 1);
        if (!success) XSRETURN_UNDEF;
        mPUSHs(xs::out(strftime(LT_FORMAT, date)).detach());
        XSRETURN(1);
    }
}

ptime_t timegm (SV* sec, SV* min, SV* hour, SV* mday, SV* mon, SV* year, SV* isdst = {}, TimezoneSP tz = {}) : ALIAS(timelocal=1, timeany=2, timegmn=3, timelocaln=4, timeanyn=5) {
    datetime date;
    date.sec  = xs::in<ptime_t>(sec);
    date.min  = xs::in<ptime_t>(min);
    date.hour = xs::in<ptime_t>(hour);
    date.mday = xs::in<ptime_t>(mday);
    date.mon  = xs::in<ptime_t>(mon);
    date.year = xs::in<ptime_t>(year);

    if (isdst) date.isdst = SvIV(isdst);
    else date.isdst = -1;

    switch (ix) {
        case 0: RETVAL = timegml(&date);                       break;
        case 1: RETVAL = timelocall(&date);                    break;
        case 2: RETVAL = timeanyl(&date, tz ? tz : tzlocal()); break;
        case 3: RETVAL = timegm(&date);                        break;
        case 4: RETVAL = timelocal(&date);                     break;
        case 5: RETVAL = timeany(&date, tz ? tz : tzlocal());  break;
        default: croak("not reached");
    }

    if (ix >= 3) {
        sv_setiv(sec, date.sec);
        sv_setiv(min, date.min);
        sv_setiv(hour, date.hour);
        sv_setiv(mday, date.mday);
        sv_setiv(mon, date.mon);
        sv_setiv(year, date.year);
        if (isdst) sv_setiv(isdst, date.isdst);
    }
}

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
    RETVAL = Date::today_epoch();
}

Date* date (SV* val = {}, TimezoneSP tz = {}, int fmt = Date::InputFormat::all) {
    RETVAL = new Date(sv2date(val, tz, fmt));
}

Date* date_ymd (...) {
    RETVAL = new Date(xs_date_ymd(&ST(0), items));
}

bool range_check (Sv newval = {}) {
    if (newval) Date::range_check(newval.is_true());
    RETVAL = Date::range_check();
}

#///////////////////////////// OBJECT METHODS ///////////////////////////////////

Date* new (SV*, SV* val = {}, TimezoneSP tz = {}, int fmt = Date::InputFormat::all) {
    RETVAL = new Date(sv2date(val, tz, fmt));
}

Date* new_ymd (...) {
    RETVAL = new Date(xs_date_ymd(&ST(1), items - 1));
}

Date* strptime (string date, string format) {
    RETVAL = new Date(Date::strptime(date, format));
}

void Date::set (SV* val = {}, TimezoneSP tz = {}, int fmt = Date::InputFormat::all) {
    THIS->set(sv2date(val, tz, fmt));
}

void Date::set_ymd (...) {
    THIS->set(xs_date_ymd(&ST(1), items - 1));
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

string Date::to_string (int format = (int)Date::Format::iso) {
    if (THIS->error()) XSRETURN_UNDEF;
    RETVAL = THIS->to_string((Date::Format)format);
}

string Date::_op_str (...) {
    if (THIS->error()) XSRETURN_UNDEF;
    RETVAL = THIS->to_string();
}

#// $date->strftime($format)
#// Date::strftime($format, $epoch, [$timezone])
#// Date::strftime($format, $sec, $min, $hour, $mday, $mon, $year, [$isdst], [$timezone])
string strftime (Sv arg0, SV* arg1, ...) {
    if (items == 2 && arg0.is_object_ref()) {
        auto THIS = xs::in<Date*>(arg0);
        RETVAL = THIS->strftime(xs::in<string_view>(arg1));
    }
    else {
        string_view format = xs::in<string_view>(arg0);
        TimezoneSP tz;
        datetime date;
        date.isdst = -1;
        
        switch (items) {
            case 9: tz = xs::in<TimezoneSP>(ST(8));     // fall through
            case 8: date.isdst = SvIV(ST(7));           // fall through
            case 7:
                date.sec   = xs::in<ptime_t>(ST(1));
                date.min   = xs::in<ptime_t>(ST(2));
                date.hour  = xs::in<ptime_t>(ST(3));
                date.mday  = xs::in<ptime_t>(ST(4));
                date.mon   = xs::in<ptime_t>(ST(5));
                date.year  = xs::in<ptime_t>(ST(6));
                timeany(&date, tz ? tz : tzlocal());
                break;
            case 3: tz = xs::in<TimezoneSP>(ST(2));     // fall through
            case 2: {
                auto epoch  = xs::in<ptime_t>(arg1);
                if (!anytime(epoch, &date, tz ? tz : tzlocal())) XSRETURN_UNDEF;
                break;
            }
            default:
                throw "wrong number of arguments";
        }
        RETVAL = strftime(format, date);
    }    
}

bool Date::to_bool (...) {
    RETVAL = THIS->error() ? false : true;
}

ptime_t Date::to_number (...) {
    RETVAL = THIS->error() ? 0 : THIS->epoch();
}

string_view Date::month_name () : ALIAS(monname=1, monthname=2) {
    PERL_UNUSED_VAR(ix);
    RETVAL = THIS->month_name();
}

string_view Date::month_sname ()

string_view Date::wday_name () : ALIAS(day_of_weekname=1, wdayname=2) {
    PERL_UNUSED_VAR(ix);
    RETVAL = THIS->wday_name();
}

string_view Date::wday_sname ()

int Date::gmtoff ()

string_view Date::tzabbr ()

#// Date::tzname()
#// $date->tzname()
string tzname (Date* date = nullptr) {
    auto& zone = date ? date->timezone() : tzlocal();
    RETVAL = zone->name;
}

bool Date::tzlocal () {
    RETVAL = THIS->timezone()->is_local;
}

TimezoneSP Date::timezone (TimezoneSP newzone = {}) : ALIAS(tz=1, zone=2) {
    if (newzone) {
        THIS->timezone(newzone);
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->timezone();
    PERL_UNUSED_VAR(ix);
}

void Date::to_timezone (TimezoneSP newzone) : ALIAS(to_tz=1, to_zone=2) {
    THIS->to_timezone(newzone);
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

Date* Date::clone (...) {
    if (items > 1) {
        ptime_t vals[] = {-1, -1, -1, -1, -1, -1, -1, -1};
        auto tz = list2vals(&ST(1), items - 1, vals);
        RETVAL = new Date(THIS->clone(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], tz));
    }
    else RETVAL = new Date(*THIS);
    
    if (RETVAL->error() && is_strict_mode()) {
        auto err = RETVAL->error();
        delete RETVAL;
        throw xs::out(err);
    }
    
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

uint8_t Date::week_of_month ()

uint8_t Date::weeks_in_year ()

void Date::week_of_year () {
    auto info = THIS->week_of_year();
    int rcnt = 1;
    if (GIMME_V == G_ARRAY) {
        mXPUSHi(info.year);
        rcnt = 2;
    }
    mXPUSHu(info.week);
    XSRETURN(rcnt);
}

std::error_code Date::error ()

SV* Date::truncate () {
    THIS->truncate();
    XSRETURN(1);
}

Date* Date::truncated () {
    RETVAL = new Date(THIS->truncated());
    PROTO = Object(ST(0)).stash();
}

int Date::compare (Sv arg, bool reverse = false) {
    if (arg.is_ref() && !arg.is_object_ref()) XSRETURN_IV(-1); // avoid exception in typemap for wrong types
    RETVAL = THIS->compare(sv2date(arg, THIS->timezone()));
    if (reverse) RETVAL = -RETVAL;
    if      (RETVAL < 0) RETVAL = -1;
    else if (RETVAL > 0) RETVAL = 1;
}

Date* Date::sum (Sv arg, ...) {
    RETVAL = new Date(*THIS + sv2daterel(arg));
    PROTO = Object(ST(0)).stash();
}

SV* Date::add (Sv arg, ...) {
    *THIS += sv2daterel(arg);
    XSRETURN(1);
}

Sv Date::difference (Sv arg, bool reverse = false) {
    bool is_date = arg.is_object_ref() && Object(arg).stash().name() == "Date";
    if (is_date)      RETVAL = xs::out(new DateRel(*xs::in<Date*>(arg), *THIS));
    else if (reverse) throw "wrong date operation";
    else              RETVAL = xs::out(new Date(*THIS - sv2daterel(arg)), Object(ST(0)).stash());
}

SV* Date::subtract (Sv arg, ...) {
    *THIS -= sv2daterel(arg);
    XSRETURN(1);
}

void __assign_stub (...) {
    if (!items) throw "should not happen";
    XSRETURN(1);
}
