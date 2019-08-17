#pragma once
#include <xs.h>
#include <panda/date.h>

namespace xs {

template <class TYPE> struct Typemap<panda::date::Date*, TYPE> : TypemapObject<panda::date::Date*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date"; }
};

template <class TYPE> struct Typemap<panda::date::DateRel*, TYPE*> : TypemapObject<panda::date::DateRel*, TYPE*, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date::Rel"; }
};

template <class TYPE> struct Typemap<panda::date::DateInt*, TYPE> : TypemapObject<panda::date::DateInt*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Date::Int"; }
};

}
