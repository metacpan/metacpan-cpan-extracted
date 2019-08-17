#pragma once
#include <cstdint>
#include <panda/time.h>

namespace panda { namespace date {

using panda::time::ptime_t;
using panda::time::datetime;

enum err_t {E_OK, E_UNPARSABLE, E_RANGE};

inline static ptime_t epoch_cmp (ptime_t s1, uint32_t mks1, ptime_t s2, uint32_t mks2) {
    return (s1 == s2) ? mks1 - mks2 : s1 - s2;
}

inline static ptime_t pseudo_epoch (const datetime& date) {
    return date.sec + date.min*61 + date.hour*60*61 + date.mday*24*60*61 + date.mon*31*24*60*61 + date.year*12*31*24*60*61;
}

inline static ptime_t date_cmp (const datetime& d1, uint32_t mks1, const datetime& d2, uint32_t mks2) {
    return epoch_cmp(pseudo_epoch(d1), mks1, pseudo_epoch(d2), mks2);
}

}}
