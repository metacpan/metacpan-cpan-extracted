#include "time.h"
#include <stdio.h>

namespace panda { namespace time {

static const int64_t ZONE_N_GMT = *((int64_t*)"GMT\0\0\0\0");

static constexpr const int EPOCH_CHRIST_DAYS = 719162; // christ_days(1970);
static constexpr const int EPOCH_WDAY        = 4;

static constexpr const int DAYS_PER_YEAR  = 365; // non-leap year only
static constexpr const int DAYS_PER_QYEAR = DAYS_PER_YEAR*4 + 1;
static constexpr const int DAYS_PER_CENT  = DAYS_PER_QYEAR*25 - 1;
static constexpr const int DAYS_PER_QCENT = DAYS_PER_CENT*4 + 1;

static constexpr const ptime_t MAX_YEARS   = (ptime_t) 1 << 32;
static constexpr const ptime_t MAX_MONTHS  = MAX_YEARS*12;
static constexpr const ptime_t MAX_DAYS    = MAX_MONTHS*31;
static constexpr const ptime_t MAX_HOURS   = MAX_DAYS*24;
static constexpr const ptime_t MAX_MINUTES = MAX_HOURS*60;
static constexpr const ptime_t MAX_EPOCH   = MAX_MINUTES*60;

static constexpr const ptime_t OUTLIM_MONTH_BY_12    = ((MAX_MONTHS / 12) + 1)*12;
static constexpr const ptime_t OUTLIM_EPOCH_BY_86400 = ((MAX_EPOCH / 86400) + 1)*86400;
static constexpr const ptime_t OUTLIM_DAY_BY_7       = ((MAX_DAYS / 7) + 1)*7;
static constexpr const ptime_t OUTLIM_DAY_BY_QCENT   = ((MAX_DAYS / DAYS_PER_QCENT) + 1)*DAYS_PER_QCENT;

const int DAYS_IN_MONTH[2][12] = {
    {31,28,31,30,31,30,31,31,30,31,30,31},
    {31,29,31,30,31,30,31,31,30,31,30,31},
};

const int MON2YDAY[2][12] = {
    {0,31,59,90,120,151,181,212,243,273,304,334},
    {0,31,60,91,121,152,182,213,244,274,305,335}
};

static constexpr const int YDAY2MDAY[][366] = {
    {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,-1},
    {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
};

static constexpr const int YDAY2MON[][366] = {
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,-1},
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11}
};

const string_view MONTH_NAMES[12] = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
const string_view WDAY_NAMES[7]   = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};

#define __PTIME_TRANS_BINFIND(VAR, FIELD) \
    int index = -1; \
    int low = 0; \
    int high = zone->trans_cnt; \
    while (high - low > 1) { \
        int mid = (high+low)/2; \
        if (zone->trans[mid].FIELD > VAR) high = mid; \
        else if (zone->trans[mid].FIELD < VAR) low = mid; \
        else { index = mid; break; } \
    } \
    if (index < 0) index = high - 1;

#define _PTIME_LT_LEAPSEC_CORR(source) \
    if (epoch < source.leap_end) result->sec = 60 + epoch - source.start;

// GIVEN DAYS PASSED SINCE 1 Jan 0001 00:00:00 CALCULATES REAL YEAR AND DAYS REMAINDER - YDAY [0-365]
static inline void christ_year (ptime_t days, int32_t &year, int32_t &remainder) {
    // 1-st step: separate FULL QUAD CENTURIES
    ptime_t tmp = (days + OUTLIM_DAY_BY_QCENT) % DAYS_PER_QCENT;
    year = (days - tmp)/DAYS_PER_QCENT * 400;
    days = tmp;

    // 2-nd step: separate FULL CENTURIES, condition fixes QCENT -> CENT border
    if (days == DAYS_PER_CENT*4) {
        year += 300;
        days = DAYS_PER_CENT;
    } else {
        year += days/DAYS_PER_CENT * 100;
        days %= DAYS_PER_CENT;
    }

    // 3-rd step: separate FULL QUAD YEARS, no border fix needed
    year += days/DAYS_PER_QYEAR * 4;
    days %= DAYS_PER_QYEAR;

    // 4-th step: separate FULL YEARS, condition fixes QYEAR -> YEAR border
    if (days == DAYS_PER_YEAR*4) {
        year += 4; // actually 3, but we must add 1 to result year, as the start is 1-st year, not 0-th
        remainder = 365;
    } else {
        year += days/DAYS_PER_YEAR + 1; // we must add 1 to result year, as the start is 1-st year, not 0-th
        remainder = days % DAYS_PER_YEAR;
    }
}

static inline void _gmtime (ptime_t epoch, datetime* result) {
    ptime_t sec_remainder = (epoch + OUTLIM_EPOCH_BY_86400) % 86400;
    ptime_t delta_days = (epoch - sec_remainder)/86400;
    result->wday = (OUTLIM_DAY_BY_7 + EPOCH_WDAY + delta_days) % 7;
    result->hour = sec_remainder/3600;
    sec_remainder %= 3600;
    result->min = sec_remainder/60;
    result->sec = sec_remainder % 60;

    int32_t year;
    int32_t remainder;
    christ_year(EPOCH_CHRIST_DAYS + delta_days, year, remainder);

    int leap = is_leap_year(year);
    result->yday = remainder;
    result->mon  = YDAY2MON[leap][remainder];
    result->mday = YDAY2MDAY[leap][remainder];
    result->gmtoff = 0;
    result->n_zone = ZONE_N_GMT;
    result->isdst = 0;
    result->year = year;
}

static inline bool is_epoch_valid(ptime_t epoch) { return (epoch <= EPOCH_MAX) && (epoch >= EPOCH_MIN); }

static inline ptime_t _timegmll (const datetime* date) {
    int leap = is_leap_year(date->year);
    ptime_t delta_days = christ_days(date->year) + MON2YDAY[leap][date->mon] + date->mday - 1 - EPOCH_CHRIST_DAYS;
    return delta_days * 86400 + date->hour * 3600 + date->min * 60 + date->sec;
}

static inline ptime_t _timegml (datetime* date) {
    ptime_t mon_remainder = (date->mon + OUTLIM_MONTH_BY_12) % 12;
    date->year += (date->mon - mon_remainder) / 12;
    date->mon = mon_remainder;
    return _timegmll(date);
}

static inline ptime_t _timegm (datetime* date) {
    ptime_t result = _timegml(date);
    _gmtime(result, date);
    return result;
}

bool gmtime (ptime_t epoch, datetime* result) {
    if (is_epoch_valid(epoch)){
        _gmtime(epoch, result);
        return true;
    };
    return false;
}

ptime_t timegm   (datetime *date)       { return _timegm(date); }
ptime_t timegml  (datetime *date)       { return _timegml(date); }
ptime_t timegmll (const datetime *date) { return _timegmll(date); }

static inline ptime_t _calc_rule_epoch (int is_leap, const datetime* curdate, datetime border) {
    border.mday = (border.wday + curdate->yday - MON2YDAY[is_leap][border.mon] - curdate->wday + 378) % 7 + 7*border.yday - 6;
    if (border.mday > DAYS_IN_MONTH[is_leap][border.mon]) border.mday -= 7;
    border.year = curdate->year;
    return _timegmll(&border);
}

bool anytime (ptime_t epoch, datetime* result, const TimezoneSP& zone) {
    bool r = is_epoch_valid(epoch);
    if (r) {
        if (epoch < zone->ltrans.start) {
            __PTIME_TRANS_BINFIND(epoch, start);
            _gmtime(epoch + zone->trans[index].offset, result);
            result->gmtoff = zone->trans[index].gmt_offset;
            result->n_zone = zone->trans[index].n_abbrev;
            result->isdst  = zone->trans[index].isdst;
            _PTIME_LT_LEAPSEC_CORR(zone->trans[index]);
        }
        else if (!zone->future.hasdst) { // future with no DST
            _gmtime(epoch + zone->future.outer.offset, result);
            result->n_zone = zone->future.outer.n_abbrev;
            result->gmtoff = zone->future.outer.gmt_offset;
            result->isdst  = zone->future.outer.isdst; // some zones stay in dst in future (when no POSIX string and last trans is in dst)
            _PTIME_LT_LEAPSEC_CORR(zone->ltrans);
        }
        else {
            _gmtime(epoch + zone->future.outer.offset, result);
            int is_leap = is_leap_year(result->year);

            if ((epoch >= _calc_rule_epoch(is_leap, result, zone->future.outer.end) - zone->future.outer.offset) &&
                (epoch < _calc_rule_epoch(is_leap, result, zone->future.inner.end) - zone->future.inner.offset)) {
                _gmtime(epoch + zone->future.inner.offset, result);
                result->isdst  = zone->future.inner.isdst;
                result->n_zone = zone->future.inner.n_abbrev;
                result->gmtoff = zone->future.inner.gmt_offset;
            } else {
                result->isdst  = zone->future.outer.isdst;
                result->n_zone = zone->future.outer.n_abbrev;
                result->gmtoff = zone->future.outer.gmt_offset;
            }
            _PTIME_LT_LEAPSEC_CORR(zone->ltrans);
        }
    };
    return r;
}

ptime_t timeany (datetime* date, const TimezoneSP& zone) {
#   define PTIME_ANY_NORMALIZE
    if (date->isdst > 0) {
#       undef PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    } else {
#       define PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    }
#   undef PTIME_ANY_NORMALIZE
}

ptime_t timeanyl (datetime* date, const TimezoneSP& zone) {
    if (date->isdst > 0) {
#       undef PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    } else {
#       define PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    }
}

}}
