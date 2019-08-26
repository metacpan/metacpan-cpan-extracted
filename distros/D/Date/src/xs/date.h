#pragma once
#include <xs.h>
#include <panda/date.h>

namespace xs { namespace date {

using namespace panda::date;

inline Date invalid_date () { return Date(-2000000000, 0, 1); }

inline TimezoneSP tzget_required (SV* zone) {
    return tzget(zone && SvOK(zone) ? xs::in<panda::string_view>(zone) : panda::string_view());
}

inline TimezoneSP tzget_optional (SV* zone) {
    return zone ? tzget(SvOK(zone) ? xs::in<panda::string_view>(zone) : panda::string_view()) : TimezoneSP();
}

void hash2vals  (const Hash& hash, ptime_t vals[8], TimezoneSP* zoneref);
void array2vals (const Array& array, ptime_t vals[8]);

Date    sv2date    (const Sv& arg, const TimezoneSP& zone = TimezoneSP(), bool keep_object_zone = false, bool no_throw = false);
DateRel sv2daterel (const Sv& arg, const Sv& arg2 = Sv());
DateInt sv2dateint (const Sv& arg, const Sv& arg2 = Sv());

}}

namespace xs {

template <class TYPE> struct Typemap<panda::date::Date*, TYPE> : TypemapObject<panda::date::Date*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date"; }
};

template <> struct Typemap<panda::date::Date> : TypemapBase<panda::date::Date> {
    panda::date::Date in (const Sv& arg) { return xs::date::sv2date(arg); }
    Sv out (const panda::date::Date& v, const Sv& proto = Sv()) { return xs::out(new panda::date::Date(v), proto); }
};

template <class TYPE> struct Typemap<panda::date::DateRel*, TYPE*> : TypemapObject<panda::date::DateRel*, TYPE*, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date::Rel"; }
};

template <> struct Typemap<panda::date::DateRel> : TypemapBase<panda::date::DateRel> {
    panda::date::DateRel in (const Sv& arg) { return xs::date::sv2daterel(arg); }
    Sv out (const panda::date::DateRel& v, const Sv& proto = Sv()) { return xs::out(new panda::date::DateRel(v), proto); }
};

template <class TYPE> struct Typemap<panda::date::DateInt*, TYPE> : TypemapObject<panda::date::DateInt*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date::Int"; }
};

template <> struct Typemap<panda::date::DateInt> : TypemapBase<panda::date::DateInt> {
    panda::date::DateInt in (const Sv& arg) { return xs::date::sv2dateint(arg); }
    Sv out (const panda::date::DateInt& v, const Sv& proto = Sv()) { return xs::out(new panda::date::DateInt(v), proto); }
};

}
