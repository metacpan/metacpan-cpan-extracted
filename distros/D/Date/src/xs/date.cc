#include "date.h"

namespace xs { namespace date {

using panda::string;
using panda::string_view;

panda::string_view strict_hint_name = "Date::strict";

static inline Date _sv2date (const Sv& arg, const TimezoneSP& zone, int fmt) {
    if (!arg) return Date(0, zone);
    SvGETMAGIC(arg);
    if (!arg.defined()) return Date("!"); // date with parsing error

    if (SvROK(arg)) {
        SV* v = SvRV(arg);
        if (SvOBJECT(v)) {
            Object o = v;
            if (o.stash().name() == "Date") return *xs::in<Date*>(arg);
            return Date(xs::in<string_view>(arg), zone, fmt);
        }
        else throw "invalid date argument";
    }

    if (SvNIOK(arg) || arg.is_like_number()) {
        if (SvNOK(arg)) return Date((double)SvNV(arg), zone);
        return Date(xs::in<ptime_t>(arg), zone);
    }

    return Date(xs::in<string_view>(arg), zone, fmt);
}

Date sv2date (const Sv& arg, const TimezoneSP& zone, int fmt) {
    auto ret = _sv2date(arg, zone, fmt);
    if (ret.error() && is_strict_mode()) throw xs::out(ret.error());
    return ret;
}

DateRel sv2daterel (const Sv& arg) {
    if (arg) SvGETMAGIC(arg);
    if (!arg.defined()) return DateRel();

    if (arg.is_ref()) return *xs::in<const DateRel*>(arg);

    if (SvNIOK(arg) || arg.is_like_number()) return DateRel(0, 0, 0, 0, 0, xs::in<ptime_t>(arg));

    auto ret = DateRel(xs::in<string_view>(arg));
    if (ret.error() && is_strict_mode()) throw xs::out(ret.error());
    return ret;
}

}}
