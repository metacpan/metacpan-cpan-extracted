#pragma once
#include <xs.h>
#include "../date.h"

namespace xs { namespace date {

using namespace panda::date;

inline Date invalid_date () { return Date(-2000000000, 0, 1); }

inline TimezoneSP tzget_required (SV* zone) {
    return tzget(zone && SvOK(zone) ? xs::in<panda::string_view>(aTHX_ zone) : panda::string_view());
}

inline TimezoneSP tzget_optional (SV* zone) {
    return zone ? tzget(SvOK(zone) ? xs::in<panda::string_view>(aTHX_ zone) : panda::string_view()) : TimezoneSP();
}

void hash2vals  (const Hash& hash, ptime_t vals[8], TimezoneSP* zoneref);
void array2vals (const Array& array, ptime_t vals[8]);

Date    sv2date    (const Sv& arg, const TimezoneSP& zone = TimezoneSP(), bool keep_object_zone = false, bool no_throw = false);
DateRel sv2daterel (const Sv& arg, const Sv& arg2 = Sv());
DateInt sv2dateint (const Sv& arg, const Sv& arg2 = Sv());

}}
