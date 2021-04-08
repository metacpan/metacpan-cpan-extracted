#pragma once
#include <xs.h>
#include <xs/Scope.h>
#include <panda/time.h>

using namespace panda::time;
using xs::Simple;
using panda::string;
using panda::string_view;

static inline TimezoneSP list2vals (SV** args, I32 items, ptime_t vals[8]) {
    if (!items) return nullptr;

    TimezoneSP tz;
    if (SvPOK(args[0]) && !looks_like_number(args[0])) {
        for (I32 i = 0; i < items - 1; i += 2) {
            SV* keysv = args[i];
            if (!SvPOK(keysv) || SvCUR(keysv) < 2) continue;
            auto key = string_view(SvPVX(keysv), SvCUR(keysv));
            switch (key[0]) {
                case 'y': if (key == "year" ) vals[0] = SvIV(args[i+1]); break;
                case 'd': if (key == "day"  ) vals[2] = xs::in<ptime_t>(args[i+1]); break;
                case 'h': if (key == "hour" ) vals[3] = xs::in<ptime_t>(args[i+1]); break;
                case 's': if (key == "sec"  ) vals[5] = xs::in<ptime_t>(args[i+1]); break;
                case 't': if (key == "tz"   ) tz      = xs::in<TimezoneSP>(args[i+1]); break;
                case 'i': if (key == "isdst") vals[7] = SvIV(args[i+1]); break;
                case 'm': switch (key[1]) {
                    case 'o': if (key == "month") vals[1] = xs::in<ptime_t>(args[i+1]); break;
                    case 'i': if (key == "min"  ) vals[4] = xs::in<ptime_t>(args[i+1]); break;
                    case 'k': if (key == "mksec") vals[6] = SvIV(args[i+1]); break;
                    default : warn("unknown parameter '%s'", string(key).c_str()); break;
                }; break;
                default: warn("unknown parameter '%s'", string(key).c_str()); break;
            }
        }
    } else {
        if (items > 8) items = 8;
        switch (items) {
            case 8: tz      = xs::in<TimezoneSP>(args[7]);  // fall through
            case 7: vals[6] = SvIV(args[6]);                // fall through
            case 6: vals[5] = xs::in<ptime_t>(args[5]);     // fall through
            case 5: vals[4] = xs::in<ptime_t>(args[4]);     // fall through
            case 4: vals[3] = xs::in<ptime_t>(args[3]);     // fall through
            case 3: vals[2] = xs::in<ptime_t>(args[2]);     // fall through
            case 2: vals[1] = xs::in<ptime_t>(args[1]);     // fall through
            case 1: vals[0] = SvIV(args[0]);
        }
    }
    return tz;
}
