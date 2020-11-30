#pragma once
#include <xs.h>
#include <xs/Scope.h>
#include <panda/date.h>
#include <panda/time.h>

namespace xs { namespace date {

using namespace panda::date;
using namespace panda::time;

extern panda::string_view strict_hint_name;

inline bool is_strict_mode () { return Scope::Hints::exists(strict_hint_name); }

Date    sv2date    (const Sv& arg, const TimezoneSP& zone = {}, int fmt = Date::InputFormat::all);
DateRel sv2daterel (const Sv& arg);

}}

namespace xs {

template <> struct Typemap<const panda::time::Timezone*> : TypemapObject<const panda::time::Timezone*, const panda::time::Timezone*, ObjectTypeForeignPtr, ObjectStorageMG> {
    static std::string package () { return "Date::Timezone"; }
};

template <> struct Typemap<panda::time::TimezoneSP> : Typemap<const panda::time::Timezone*> {
    using Super = Typemap<const panda::time::Timezone*>;

    static inline panda::time::TimezoneSP in (const Sv& arg) {
        if (arg.is_object_ref()) return Super::in(arg);
        if (!arg) return {};
        if (!arg.is_true()) return panda::time::tzlocal();
        return panda::time::tzget(xs::in<panda::string_view>(arg));
    }
};

template <class TYPE> struct Typemap<panda::date::Date*, TYPE> : TypemapObject<panda::date::Date*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date"; }
};

template <> struct Typemap<panda::date::Date> : TypemapBase<panda::date::Date> {
    static inline panda::date::Date in (const Sv& arg) { return xs::date::sv2date(arg); }
    static inline Sv out (const panda::date::Date& v, const Sv& proto = Sv()) { return xs::out(new panda::date::Date(v), proto); }
};

template <class TYPE> struct Typemap<panda::date::DateRel*, TYPE*> : TypemapObject<panda::date::DateRel*, TYPE*, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date::Rel"; }
};

template <> struct Typemap<panda::date::DateRel> : TypemapBase<panda::date::DateRel> {
    static inline panda::date::DateRel in (const Sv& arg) { return xs::date::sv2daterel(arg); }
    static inline Sv out (const panda::date::DateRel& v, const Sv& proto = Sv()) { return xs::out(new panda::date::DateRel(v), proto); }
};

}
