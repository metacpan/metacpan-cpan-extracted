#include "time.h"
#include <type_traits>
#include <panda/from_chars.h>

namespace panda { namespace time { namespace format {

template <std::size_t N>
struct tag : std::integral_constant<std::size_t, N>{
    static const auto length = N;

    inline static char* applyN (char* in, int value) {
        char* result = in + N;
        char* tail = result - 1;
        for (std::size_t i = 0; i < N; ++i) {
            char digit = value % 10;
            value /= 10;
            *tail = digit + '0';
            --tail;
        }
        return result;
    }

    inline static char* applyN_spad (char* in, int value) {
        char* result = in + N;
        char* tail = result - 1;

        for (std::size_t i = 0; i < N - 1; ++i) {
            char digit = value % 10;
            value /= 10;
            *tail = digit + '0';
            --tail;
        }

        char digit = value % 10;
        value /= 10;
        if (digit) *tail = digit + '0';
        else       *tail = ' ';
        --tail;

        return result;
    }
};

template <char C>
struct tag_char : tag<1> {
    inline static char* apply (char* in, const datetime&, uint32_t) {
        *in = C;
        return ++in;
    }
};

struct tag_century   : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.year/100); }};
struct tag_year      : tag<4> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.year); }};
struct tag_yr        : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.year % 100); }};
struct tag_month     : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.mon + 1); }};
struct tag_day       : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.mday); }};
struct tag_day_spad  : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN_spad(in, dt.mday); }};
struct tag_hour      : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.hour); }};
struct tag_hour_spad : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN_spad(in, dt.hour); }};
struct tag_min       : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.min); }};
struct tag_sec       : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.sec); }};
struct tag_yday      : tag<3> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.yday + 1); }};
struct tag_c_wday    : tag<1> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.wday); }};
struct tag_ewday     : tag<1> { inline static char* apply (char* in, const datetime& dt, uint32_t) { return applyN(in, dt.wday ? dt.wday : 7); }};

struct tag_hour12 : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto h = dt.hour % 12;
    if (h == 0) h = 12;
    return applyN(in, h);
}};

struct tag_hour12_spad : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto h = dt.hour % 12;
    if (h == 0) h = 12;
    return applyN_spad(in, h);
}};

struct tag_AMPM : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    *in++ = dt.hour < 12 ? 'A' : 'P';
    *in++ = 'M';
    return in;
}};

struct tag_ampm : tag<2> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    *in++ = dt.hour < 12 ? 'a' : 'p';
    *in++ = 'm';
    return in;
}};

struct tag_mksec : tag<7> { inline static char* apply (char* in, const datetime&, uint32_t value) {
    if (!value) return in;
    *in++ = '.';

    char* result = nullptr;
    char* tail = in + 6;
    for (std::size_t i = 0; i < 6; ++i) {
        --tail;
        char digit = value % 10;
        value /= 10;
        if (!result) {
            if (!digit) continue;
            result = tail + 1;
        }
        *tail = digit + '0';
    }
    /* happens when mksec is garbage. gargabe in => garbage out, don't care, just do not crash */
    if (!result) { return in; }
    return result;
}};

struct tag_tzoff : tag<6> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto off = dt.gmtoff;

    if (off >= 0) *in++ = '+';
    else {
        *in++ = '-';
        off = -off;
    }

    auto hour = off / 3600;
    auto min  = (off % 3600) / 60;

    if (!min) return tag<2>::applyN(in, hour);

    in = tag<2>::applyN(in, hour);
    *in++ = ':';
    return tag<2>::applyN(in, min);
}};

struct tag_tzoff_void : tag<5> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto off = dt.gmtoff;

    if (off >= 0) *in++ = '+';
    else {
        *in++ = '-';
        off = -off;
    }

    return tag<2>::applyN(tag<2>::applyN(in, off / 3600), (off % 3600) / 60);
}};

struct tag_tzabbr : tag<7> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto src = dt.zone;
    while (char c = *src++) *in++ = c;
    return in;
}};

struct tag_tz1123 : tag<5> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    if (!dt.gmtoff) {
        *in++ = 'G';
        *in++ = 'M';
        *in++ = 'T';
        return in;
    }
    auto off = dt.gmtoff;

    if (off >= 0) *in++ = '+';
    else {
        *in++ = '-';
        off = -off;
    }

    return tag<2>::applyN(tag<2>::applyN(in, off / 3600), (off % 3600) / 60);
}};

struct tag_month_short : tag<3> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto name = MONTH_NAMES[dt.mon];
    *in++ = name[0];
    *in++ = name[1];
    *in++ = name[2];
    return in;
}};

struct tag_month_long : tag<9> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto name = MONTH_NAMES[dt.mon];
    auto size = name.length();
    memcpy(in, name.data(), size);
    in += size;
    return in;
}};

struct tag_wday_short : tag<3> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto name = WDAY_NAMES[dt.wday];
    *in++ = name[0];
    *in++ = name[1];
    *in++ = name[2];
    return in;
}};

struct tag_wday_long : tag<9> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto name = WDAY_NAMES[dt.wday];
    auto size = name.length();
    memcpy(in, name.data(), size);
    in += size;
    return in;
}};

// max epoch has 17 digits, but in past it has additional '-'
struct tag_epoch : tag<18> { inline static char* apply (char* in, const datetime& dt, uint32_t) {
    auto gmtoff = dt.gmtoff;
    // we can use the lightest version timegmll() because it is guaranteed that <dt> is already normalized
    auto epoch = timegmll(&dt) - gmtoff;
    auto res = to_chars(in, in + length, epoch);
    assert(!res.ec);
    return res.ptr;
}};

template <typename...Ts> struct size_of_t;
template <typename T> struct size_of_t<T> { static const auto length = T::length; };
template <typename T, typename...Ts> struct size_of_t<T, Ts...> {
    static const auto length = (size_of_t<T>::length + size_of_t<Ts...>::length);
};

template <typename... Tags> struct Composer;
template <typename T1> struct Composer<T1> {
    static char* fn (char* in, const datetime& dt, uint32_t mksec) {
        return T1::apply(in, dt, mksec);
    }
};
template <typename T, typename...Tags> struct Composer<T, Tags...> {
    static char* fn (char* in, const datetime& dt, uint32_t mksec) {
        return Composer<Tags...>::fn(Composer<T>::fn(in, dt, mksec), dt, mksec);
    }
};

template <typename ...Args>
struct exp_t {
    static constexpr const auto length = size_of_t<Args...>::length;
    inline static char* apply (char* in, const datetime& dt, uint32_t mksec) {
        return Composer<Args...>::fn(in,dt, mksec);
    }
};

using ansi_c_t = exp_t<tag_wday_short, tag_char<' '>, tag_month_short, tag_char<' '>, tag_day_spad, tag_char<' '>, tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_char<' '>, tag_year>;
using ymd_t    = exp_t<tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day>;
using mdy_s_t  = exp_t<tag_month, tag_char<'/'>, tag_day, tag_char<'/'>, tag_year>;
using hms_t    = exp_t<tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec>;
using hms12_t  = exp_t<tag_hour12, tag_char<':'>, tag_min,   tag_char<':'>, tag_sec, tag_char<' '>, tag_AMPM>;
using hm_t     = exp_t<tag_hour, tag_char<':'>, tag_min>;

}}}
