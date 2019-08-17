#include "util.h"

namespace xs { namespace date {

using panda::string;
using panda::string_view;

void hash2vals (const Hash& hash, ptime_t vals[8], TimezoneSP* zoneref) {
    auto end = hash.end();
    for (auto it = hash.begin(); it != end; ++it) {
        auto key = it->key();
        switch (key[0]) {
            case 'y':
                if (key == "year") vals[0] = xs::in<ptime_t>(it->value());
                break;
            case 'm':
                if      (key == "month") vals[1] = xs::in<ptime_t>(it->value());
                else if (key == "min")   vals[4] = xs::in<ptime_t>(it->value());
                else if (key == "mksec") vals[6] = xs::in<ptime_t>(it->value());
                break;
            case 'd':
                if (key == "day") vals[2] = xs::in<ptime_t>(it->value());
                break;
            case 'h':
                if (key == "hour") vals[3] = xs::in<ptime_t>(it->value());
                break;
            case 's':
                if (key == "sec") vals[5] = xs::in<ptime_t>(it->value());
                break;
            case 'i':
                if (key == "isdst") vals[7] = SvIV(it->value());
                break;
            case 't':
                if (key[1] == 'z' && zoneref && !*zoneref) *zoneref = tzget_required(it->value());
                break;
        }
    }
}

void array2vals (const Array& array, ptime_t vals[8]) {
    auto sz = array.size();
    if (sz > 8) sz = 8;
    for (size_t i = 0; i < sz; ++i) {
        auto val = array.fetch(i);
        if (val.defined()) vals[i] = xs::in<ptime_t>(val);
    }
}

Date sv2date (const Sv& arg, const TimezoneSP& zone, bool keep_object_zone, bool no_throw) {
    if (!arg.defined()) return Date(0, zone);

    if (arg.is_ref()) {
        auto sv = Ref(arg).value();
        if (sv.is_object()) return keep_object_zone ? *xs::in<Date*>(sv) : Date(*xs::in<Date*>(sv), zone);
        ptime_t vals[] = {2000, 1, 1, 0, 0, 0, 0, -1};
        TimezoneSP hzone = zone;

        if (sv.is_hash()) {
            Hash hash = sv.get<HV>();
            hash2vals(hash, vals, &hzone);
        }
        else if (sv.is_array()) {
            Array arr = sv.get<AV>();
            array2vals(arr, vals);
        }
        else if (no_throw) return invalid_date();
        else throw "bad argument type";

        return Date(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], hzone);
    }

    if (arg.is_like_number()) {
        if (SvNOK(arg)) return Date((double)SvNV(arg), zone);
        return Date(xs::in<ptime_t>(arg), zone);
    }
    return Date(xs::in<string_view>(arg), zone);
}

DateRel sv2daterel (const Sv& arg, const Sv& arg2) {
    if (arg2) return DateRel(sv2date(arg), sv2date(arg2));
    if (!arg.defined()) return DateRel();

    if (arg.is_ref()) {
        auto sv = Ref(arg).value();
        if (sv.is_object()) return *xs::in<const DateRel*>(sv);

        ptime_t vals[] = {0, 0, 0, 0, 0, 0};

        if (sv.is_hash()) {
            Hash hash = sv.get<HV>();
            hash2vals(hash, vals, NULL);
        }
        else if (sv.is_array()) {
            Array arr = sv.get<AV>();
            array2vals(arr, vals);
        } else {
            throw "bad argument type";
        }

        return DateRel(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5]);
    }

    if (arg.is_like_number()) return DateRel(0, 0, 0, 0, 0, xs::in<ptime_t>(arg));
    return DateRel(xs::in<string_view>(arg));
}

DateInt sv2dateint (const Sv& arg, const Sv& arg2) {
    if (arg2) return DateInt(sv2date(arg), sv2date(arg2));
    if (arg.is_ref()) {
        auto sv = Ref(arg).value();
        if (sv.is_object()) return *xs::in<DateInt*>(sv);
        if (sv.is_array()) {
            Array a = sv.get<AV>();
            Scalar from = a.fetch(0);
            Scalar till = a.fetch(1);
            if (from && till) return DateInt(sv2date(from), sv2date(till));
        }
    }
    else if (arg.is_string()) return DateInt(xs::in<string_view>(arg));
    throw "bad argument type";
}

}}
