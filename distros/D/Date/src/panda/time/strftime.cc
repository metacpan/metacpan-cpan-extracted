#include "time.h"
#include "format.h"

namespace panda { namespace time {

using namespace format;

#define REQCAP(n)                   \
    if (d >= de - n + 1) {          \
        cap *= 2;                   \
        auto len = d - ret.data();  \
        ret.length(len);            \
        d = ret.reserve(cap) + len; \
        de = ret.data() + cap;      \
    }

#define ADD(tag) {                  \
    REQCAP(tag::length);            \
    d = tag::apply(d, dt, 0);   \
}

using mdyr_s_t = exp_t<tag_month, tag_char<'/'>, tag_day, tag_char<'/'>, tag_yr>;

string strftime (string_view format, const datetime& dt) {
    string ret;
    auto len = format.length();
    auto d   = ret.reserve(len > 23 ? (len + 15) : len);
    auto cap = ret.capacity();
    auto de  = (const char*)d + cap;
    auto s   = format.data();
    auto se  = s + len;

    while (s < se) {
        char c = *s++;
        if (c != '%' || s == se) {
            REQCAP(1);
            *d++ = c;
            continue;
        }
        switch (*s++) {
            case 'a': ADD(tag_wday_short);    break;
            case 'A': ADD(tag_wday_long);     break;
            case 'h':
            case 'b': ADD(tag_month_short);   break;
            case 'B': ADD(tag_month_long);    break;
            case 'c': ADD(ansi_c_t);          break;
            case 'C': ADD(tag_century);       break;
            case 'D': ADD(mdyr_s_t);          break;
            case 'd': ADD(tag_day);           break;
            case 'e': ADD(tag_day_spad);      break;
            case 'F': ADD(ymd_t);             break;
            case 'H': ADD(tag_hour);          break;
            case 'I': ADD(tag_hour12);        break;
            case 'j': ADD(tag_yday);          break;
            case 'k': ADD(tag_hour_spad);     break;
            case 'l': ADD(tag_hour12_spad);   break;
            case 'm': ADD(tag_month);         break;
            case 'M': ADD(tag_min);           break;
            case 'n': REQCAP(1); *d++ = '\n'; break;
            case 'p': ADD(tag_AMPM);          break;
            case 'P': ADD(tag_ampm);          break;
            case 'r': ADD(hms12_t);           break;
            case 'R': ADD(hm_t);              break;
            case 's': ADD(tag_epoch);         break;
            case 'S': ADD(tag_sec);           break;
            case 't': REQCAP(1); *d++ = '\t'; break;
            case 'X':
            case 'T': ADD(hms_t);             break;
            case 'u': ADD(tag_ewday);         break;
            case 'w': ADD(tag_c_wday);        break;
            case 'y': ADD(tag_yr);            break;
            case 'Y': ADD(tag_year);          break;
            case 'z': ADD(tag_tzoff_void);    break;
            case 'Z': ADD(tag_tzabbr);        break;
            default: // keep symbol after percent
                REQCAP(1);
                *d++ = *(s-1);
        }
    }

    ret.length(d - ret.data());
    return ret;
}

}}

//%G     The  ISO 8601  week-based  year (see NOTES) with century as a decimal number.  The 4-digit year corresponding to the ISO week number (see %V).  This has the same format and value as %Y, except that if
//       the ISO week number belongs to the previous or next year, that year is used instead. (TZ) (Calculated from tm_year, tm_yday, and tm_wday.)
//%g     Like %G, but without century, that is, with a 2-digit year (00–99). (TZ) (Calculated from tm_year, tm_yday, and tm_wday.)
//%U     The week number of the current year as a decimal number, range 00 to 53, starting with the first Sunday as the first day of week 01.  See also %V and %W.  (Calculated from tm_yday and tm_wday.)
//%V     The ISO 8601 week number (see NOTES) of the current year as a decimal number, range 01 to 53, where week 1 is the first week that has at least 4 days in the new year.  See also %U and %W.  (Calculated
//       from tm_year, tm_yday, and tm_wday.)  (SU)
//%W     The week number of the current year as a decimal number, range 00 to 53, starting with the first Monday as the first day of week 01.  (Calculated from tm_yday and tm_wday.)
