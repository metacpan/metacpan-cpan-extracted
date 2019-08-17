#include <cstring>
#include <algorithm>
#include <stdlib.h>
#include <panda/date/parse.h>

namespace panda { namespace date {

namespace parser {

enum class time_unit_t { NONE = 0, H, M, S};
enum class tz_info_t { LOCAL, UTC };

struct timezone_t {
    tz_info_t tz_info;
    int sign;
    uint32_t hour;
    uint32_t minute;
};

struct context_t {
    datetime& dt;
    uint32_t& mksec;
    timezone_t& tz;
    int32_t year_sign;
    uint32_t week;
    uint32_t week_day;
    time_unit_t time_unit;
};

// handlers

struct handler_year_sign {
    static inline void handle(int value, context_t& ctx) {
        ctx.year_sign = (value == '+') ? 1 : -1;
    }
};

struct handler_year {
    static inline void handle(int value, context_t& ctx) {
        ctx.dt.year = value;
    }
};

struct handler_year_v {
    static inline void handle(int value, int, context_t& ctx) {
        ctx.dt.year = static_cast<int32_t>(ctx.year_sign * value);
    }
};


struct handler_month {
    static inline void handle(int value, context_t& ctx) {
        ctx.dt.mon = value - 1;
    }
};

struct handler_day {
    static inline void handle(int value, context_t& ctx) {
        ctx.dt.mday = value;
    }
};

struct handler_week {
    static inline void handle(int value, context_t& ctx) {
        ctx.week = value;
    }
};

struct handler_week_day {
    static inline void handle(int value, context_t& ctx) {
        ctx.week_day = value;
    }
};

struct handler_hour {
    static inline void handle(int value, context_t& ctx) {
        ctx.time_unit = time_unit_t::H;
        ctx.dt.hour = value;
    }
};

struct handler_hour_v {
    static inline void handle(int value, int, context_t& ctx) {
        ctx.time_unit = time_unit_t::H;
        ctx.dt.hour = value;
    }
};

struct handler_minute {
    static inline void handle(int value, context_t& ctx) {
        ctx.time_unit = time_unit_t::M;
        ctx.dt.min = value;
    }
};

struct handler_minute_v {
    static inline void handle(int value, int, context_t& ctx) {
        ctx.time_unit = time_unit_t::M;
        ctx.dt.min = value;
    }
};

struct handler_second {
    static inline void handle(int value, context_t& ctx) {
        ctx.time_unit = time_unit_t::S;
        ctx.dt.sec = value;
    }
};

struct handler_second_v {
    static inline void handle(int value, int, context_t& ctx) {
        ctx.time_unit = time_unit_t::S;
        ctx.dt.sec = value;
    }
};


struct handler_tz_utc {
    static inline void handle(int, context_t& ctx) {
        ctx.tz.tz_info = tz_info_t::UTC;
    }
};

struct handler_tz_offset_sign {
    static inline void handle(int value, context_t& ctx) {
        ctx.tz.tz_info = tz_info_t::UTC;
        ctx.tz.sign = (value == '+') ? 1 : -1;
    }
};

struct handler_tz_offset_hour {
    static inline void handle(int value, context_t& ctx) {
        ctx.tz.tz_info = tz_info_t::UTC;
        ctx.tz.hour = value;
    }
};

struct handler_tz_offset_minute {
    static inline void handle(int value, context_t& ctx) {
        ctx.tz.tz_info = tz_info_t::UTC;
        ctx.tz.minute = value;
    }
};

struct handler_fraction {
    static inline void handle(int value, int count, context_t& ctx) {
        if (value) {
            double share = value / std::pow(10, count);
            if (ctx.time_unit == time_unit_t::H) {
                ctx.dt.min = (uint32_t)(share * 60);
                //const double sec_left = (share * 3600) - ctx.dt.min * 60;
                const double sec_left = (share - ((double)ctx.dt.min)/60) * 3600;
                ctx.dt.sec = (uint32_t)sec_left;
                const double mksec_left = (share * 3600) * 1000000 - (((double)(ctx.dt.min) * 60 * 1000000) + (double)(ctx.dt.sec) * 1000000);
                ctx.mksec = (uint32_t)mksec_left;
            } else if (ctx.time_unit == time_unit_t::M) {
                ctx.dt.sec = (uint32_t)(share * 60);
                //const double mksec_left = (share * 1000000) - ctx.dt.min * 1000000;
                const double mksec_left = (share - ((double)ctx.dt.sec)/60) * 1000000;
                ctx.mksec = (uint32_t)mksec_left;
            } else if (ctx.time_unit == time_unit_t::S) {
                ctx.mksec = (uint32_t)(share * 1000000);
            }
        }
    }
};


using handler_ordinal_date = handler_day;

// OR
template <typename ...Ts> struct op_or;
template <typename T> struct op_or<T> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        return T::parse(ptr, ptr_end, ctx);
    }
};
template <typename T, typename ...Ts> struct op_or<T, Ts...> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        const char* ptr_next = op_or<T>::parse(ptr, ptr_end, ctx);
        if (ptr_next) return ptr_next;
        return op_or<Ts...>::parse(ptr, ptr_end, ctx);
    }
};

// SEQ

template <typename ...Ts> struct op_seq;
template <typename T> struct op_seq<T> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        return T::parse(ptr, ptr_end, ctx);
    }
};
template <typename T, typename ...Ts> struct op_seq<T, Ts...> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        const char* ptr_next = op_seq<T>::parse(ptr, ptr_end, ctx);
        if (!ptr_next) return NULL;
        return op_seq<Ts...>::parse(ptr_next, ptr_end, ctx);
    }
};

// maybe

template <typename ...Ts> struct op_maybe;
template <typename T> struct op_maybe<T> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        if (ptr < ptr_end) {
            const char* ptr_next = T::parse(ptr, ptr_end, ctx);
            return ptr_next ? ptr_next : ptr;
        }
        return ptr;
    }
};
template <typename T, typename ...Ts> struct op_maybe<T, Ts...> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        if (ptr < ptr_end) {
            const char* ptr_next = T::parse(ptr, ptr_end, ctx);          // direct non-recursive call
            if (ptr_next >= ptr) return ptr_next;                        // stop chaining
            return op_maybe<Ts...>::parse(ptr, ptr_end, ctx);            // continue chaining if 1st op was NOT successfull
        }
        return ptr;
    }
};

// terms

template <char T, typename Handler = void>
struct term_char {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        if (ptr - ptr_end == 0) return NULL;
        if (*ptr == T) {
            Handler::handle(T, ctx);
            return ptr + 1;
        }
        return NULL;
    }
};

template <char T>
struct term_char<T, void> {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t&) {
        if (ptr - ptr_end == 0) return NULL;
        if (*ptr == T) return ptr + 1;
        return NULL;
    }
};

template <int N, typename Handler>
struct term_number {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        const char* number_end = ptr + N;
        if (number_end > ptr_end) return NULL;
        int value = 0;
        while(ptr != number_end) {
            char digit = (*ptr++) - '0';
            if (digit >= 0 && digit <= 9) {
                value = (value * 10) + digit;
            } else {
                return NULL;
            }
        }
        Handler::handle(value, ctx);
        return number_end;
    }
};

// parses [1...N] digits
template <int N, typename Handler>
struct term_var_number {
    static inline const char* parse(const char* ptr, const char* ptr_end, context_t& ctx) {
        const char* number_end = std::min(ptr + N, ptr_end);
        if (ptr >= ptr_end) return NULL;
        int value = 0;
        const char* start = ptr;
        while(ptr != number_end) {
            char digit = (*ptr) - '0';
            if (digit >= 0 && digit <= 9) {
                value = (value * 10) + digit;
            } else {
                break;
            }
            ++ptr;
        }
        if (ptr == start) return NULL;
        auto count = ptr - start;
        Handler::handle(value, count, ctx);
        return ptr;
    }
};



using term_year         = term_number<4, handler_year>;
using term_year_v       = term_var_number<9, handler_year_v>;
using term_month        = term_number<2, handler_month>;
using term_day          = term_number<2, handler_day>;
using term_week         = term_number<2, handler_week>;
using term_week_day     = term_number<1, handler_week_day>;
using term_ordinal_date = term_number<3, handler_ordinal_date>;
using term_hour         = term_number<2, handler_hour>;
using term_hour_v       = term_var_number<2, handler_hour_v>;
using term_min          = term_number<2, handler_minute>;
using term_min_v        = term_var_number<2, handler_minute_v>;
using term_sec          = term_number<2, handler_second>;
using term_sec_v        = term_var_number<2, handler_second_v>;
using term_tz_UTC       = term_char<'Z', handler_tz_utc>;
using term_hour_tz      = term_number<2, handler_tz_offset_hour>;
using term_min_tz       = term_number<2, handler_tz_offset_minute>;
using term_fraction_p   = term_var_number<6, handler_fraction>;
using term_fraction     = op_seq<op_or<term_char<'.'>, term_char<','>>, term_fraction_p>;
template<char T> using term_tz_sing = term_char<T, handler_tz_offset_sign>;
template<char T> using term_year_sign = term_char<T, handler_year_sign>;
template<typename B> using term_fraq = op_seq<B, term_fraction>;



using grammar_date = op_seq<
    term_year,                                                                                                      // YYYY
    op_maybe<
        op_or<
            op_seq<term_month, term_day>,                                                                           // YYYYMMDD,
            op_seq<term_char<'-'>, op_or<
                term_ordinal_date,                                                                                  // YYYY-DDD
                op_seq<term_month, op_maybe<op_seq<term_char<'-'>, term_day>>>,                                     // YYYY-MM, YYYY-MM-DD
                op_seq<term_char<'W'>, term_week, op_maybe<op_seq<term_char<'-'>, term_week_day>>>
            >>,
            op_seq<term_char<'W'>, term_week, op_maybe< term_week_day>>,                                            // YYYYWww, YYYYWwwD
            term_ordinal_date                                                                                       // YYYYDDD
        >
    >
>;

using grammar_vCard = op_seq<
    term_char<'-'>, term_char<'-'>,
    op_or<
        op_seq<term_month, term_day>,                                           // --MMDD
        op_seq<term_char<'-'>, term_day>                                        // ---DD
    >
>;

using grammar_time = op_seq<
    term_hour,                                                                  // HH
    op_maybe<
        op_or<
            op_seq<term_min, op_maybe<                                          // HHMM
                term_sec,                                                       // HHMMSS
                op_maybe<term_fraction>                                         // HHMM.M{1,6}
            >>,
            op_seq<term_char<':'>, term_min,                                    // HH:MM
                op_maybe<
                    op_seq<term_char<':'>, term_sec, op_maybe<term_fraction>>,  // HH:MM:SS, HH:MM:SS.S{1,6}
                    term_fraction                                               // HH:MM.M{1,6}
            >>,
            term_fraction                                                       // HH.H{1,6}
        >
    >
>;

using grammar_tz_offset = op_seq<
    term_hour_tz,
    op_maybe<
        term_min_tz,
        op_seq<term_char<':'>,  term_min_tz>
    >
>;

using grammar_tz = op_or<
    term_tz_UTC,                                                                // Z
    op_seq<
        op_or<term_tz_sing<'+'>, term_tz_sing<'-'>>,                            // ±HH:MM, ±HHMM, ±HH
        grammar_tz_offset
    >
>;


using grammar_iso8601 = op_or<
    op_seq<
        grammar_date,
        op_maybe<
            op_seq<
                term_char<'T'>, grammar_time, op_maybe<grammar_tz>
            >
        >
    >,
    grammar_vCard
>;

using grammar_generic = op_seq<
    op_maybe<term_year_sign<'+'>, term_year_sign<'-'>>,
    term_year_v,                                                        // ±Y{1, 9}
    op_maybe<op_seq<
        op_or<term_char<'-'>, term_char<'/'>>,
        term_month,                                                     // YYYY-MM, YYYY/MM
        op_maybe<op_seq<
            op_or<term_char<'-'>, term_char<'/'>>,
            term_day,                                                   // YYYY-MM-DD, YYYY/MM/DD
            op_maybe<op_seq<
                term_char<' '>,
                term_hour_v,
                term_char<':'>,
                term_min_v,                                             // HH:MM
                op_maybe<op_seq<
                    term_char<':'>,
                    term_sec_v,                                         // HH:MM:SS
                    op_maybe<term_fraction>                             // .s{1,6}
                >>,
                op_maybe<op_seq<
                    op_or<term_tz_sing<'+'>, term_tz_sing<'-'>>,        // ±HH:MM, ±HHMM, ±HH
                    grammar_tz_offset
                >>
            >>
        >>
    >>
>;

};

// guess date&time format guess helper ( points for ASCII character )
static uint32_t FORMAT_POINTS[256];

static bool _init () {
    FORMAT_POINTS[(unsigned char)'-'] = 1;
    FORMAT_POINTS[(unsigned char)'/'] = 1;
    FORMAT_POINTS[(unsigned char)'T'] = 100;
    FORMAT_POINTS[(unsigned char)'W'] = 100;
    return true;
}
static bool _init_ = _init();

static const int32_t WEEK_1_OFFSETS[] = {0, -1, -2, -3, 4, 3, 2};
static const int32_t WEEK_2_OFFSETS[] = {8, 7, 6, 5, 9, 10, 9};

template <typename G>
inline err_t parse(string_view str, datetime& date, uint32_t* microsec, TimezoneSP& zone) {
    using namespace panda::time;

    uint32_t microsec_backup;
    parser::timezone_t tz { parser::tz_info_t::LOCAL, 1, 0, 0 };
    parser::context_t ctx {date, microsec ? *microsec: microsec_backup, tz, 1, 0, 0, parser::time_unit_t::NONE };
    const char* begin = str.begin();
    const char* end   = str.end();
    const char* result = G::parse(begin, end, ctx);
    if (result != end) {
        return E_UNPARSABLE;
    }

    // optionally look up for TZ-offset
    if (tz.tz_info != parser::tz_info_t::LOCAL) {
        if (tz.hour || tz.minute) {
            char offset[14];
            char* ptr = offset;
            char digit_h1 = (tz.hour / 10) + '0';
            char digit_h2 = (tz.hour % 10) + '0';
            char digit_m1 = (tz.minute / 10) + '0';
            char digit_m2 = (tz.minute % 10) + '0';

            *ptr++ = '<';
            *ptr++ = (tz.sign > 0) ? '+' : '-';
            *ptr++ = digit_h1;
            *ptr++ = digit_h2;
            *ptr++ = ':';
            *ptr++ = digit_m1;
            *ptr++ = digit_m2;
            *ptr++ = '>';
            *ptr++ = (tz.sign > 0) ? '-' : '+';  // NB: yes, it is reversed
            *ptr++ = digit_h1;
            *ptr++ = digit_h2;
            *ptr++ = ':';
            *ptr++ = digit_m1;
            *ptr++ = digit_m2;

            zone = tzget(string_view(offset, 14));
        } else {
            zone = tzget("GMT");
        }
    }

    // convert from week to mday
    if (ctx.week) {
        ptime_t days_since_christ = christ_days(date.year);
        int32_t beginning_weekday = days_since_christ % 7;
        if (!ctx.week_day) ctx.week_day = 1;
        if (ctx.week == 1) {
            int mday = WEEK_1_OFFSETS[beginning_weekday] + (ctx.week_day - 1);
            if (mday <= 0) return E_UNPARSABLE; // was no such weekday that year
            date.mday = mday;
        }
        else {
            date.mday = WEEK_2_OFFSETS[beginning_weekday] + (ctx.week_day - 1) + 7 * (ctx.week - 2);
        }
    }

    return E_OK;
}

err_t parse (string_view str, datetime& date, uint32_t* microsec, TimezoneSP& zone) {
    memset(&date, 0, sizeof(datetime));
    date.mday = 1;
    auto ptr = str.cbegin();
    auto end = str.cend();
    uint32_t format_guess = 0;
    while (ptr != end) format_guess += FORMAT_POINTS[(unsigned char)*ptr++];

    if (format_guess == 0 || format_guess >= 100)
        return parse<parser::grammar_iso8601>(str, date, microsec, zone);
    else
        return parse<parser::grammar_generic>(str, date, microsec, zone);
}

err_t parse_relative (string_view str, datetime& date) {
    memset(&date, 0, sizeof(datetime)); // reset all values
    ptime_t curval = 0;
    bool negative = false;
    auto ptr = str.cbegin();
    auto end = str.cend();
    while (ptr != end) {
        char c = *ptr++;
        if (c == '-') negative = true;
        else if (c >= '0' and c <= '9') {
            curval *= 10;
            curval += (c-48);
        }
        else {
            if (negative) {
                curval = -curval;
                negative = false;
            }

            switch (c) {
                case 'Y':
                case 'y':
                    date.year = curval; break;
                case 'M':
                    date.mon = curval; break;
                case 'D':
                case 'd':
                    date.mday = curval; break;
                case 'h':
                    date.hour = curval; break;
                case 'm':
                    date.min = curval; break;
                case 's':
                    date.sec = curval; break;
            }

            curval = 0;
        }
    }

    return E_OK;
}

const unsigned char relchars[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

bool looks_like_relative (string_view str) {
    auto ptr = str.cbegin();
    auto end = str.cend();
    while (ptr != end && *ptr != 0) if (relchars[(unsigned char)*ptr++]) return true;
    return ptr == str.cbegin();
}

}}
