#include <type_traits>
#include <panda/from_chars.h>

#define TOSTR_WRAPPER(name, maxsize)\
panda::string name() const {        \
    panda::string output(maxsize);  \
    name(output);                   \
    return output;                  \
}

namespace panda { namespace date { namespace format {

const constexpr int YEAR_MAX = 999999999;
const constexpr int YEAR_MIN = YEAR_MAX * -1;


template <std::size_t N>
struct tag_t: std::integral_constant<std::size_t, N>{
    inline static char* applyN(char* in, int value) {
        assert(value >= 0);
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
};

// length(999999999) + 1 == 10
struct tag_year     : tag_t<10> {
    inline static char* apply(char* in, const datetime& dt, uint32_t const*) {
        size_t i;
        auto year = dt.year > YEAR_MAX ? YEAR_MAX : dt.year < YEAR_MIN ? YEAR_MIN : dt.year;
        char buf[10];
        char* buff = buf;
        auto res = to_chars(buff, buff + 10, year);
        assert(!res.ec); // because buf should always be enough
        size_t len = res.ptr - buff;
        auto* orig_ptr = in;
        if (dt.year >= 0 && dt.year <= 9999) {
            if (dt.year <= 999) {
                for (i = 0; i < 4 - len; i++) *(in++) = '0';
            }
        }
        else if (dt.year > 9999) {
            *orig_ptr++ = '+';  // write '+' for years > 9999
        }
        for (i = 0; i < len; i++) *(orig_ptr++) = *(buff++);
        return orig_ptr;
    }
};
struct tag_month : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) { return applyN(in, dt.mon + 1); }};
struct tag_day   : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) { return applyN(in, dt.mday); }};
struct tag_hour  : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) { return applyN(in, dt.hour); }};
struct tag_min   : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) { return applyN(in, dt.min); }};
struct tag_sec   : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) { return applyN(in, dt.sec); }};

struct tag_mksec : tag_t<7> { inline static char* apply(char* in, const datetime&, uint32_t const* mk) {
    auto value = *mk;
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
    return result;
}};


struct tag_ampm     : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) {
    *(in++) = dt.hour < 12 ? 'A' : 'P';
    *(in++) = 'M';
    return in;
}};
struct tag_hour_meridiam : tag_t<2> { inline static char* apply(char* in, const datetime& dt, uint32_t const*) {
    auto h = dt.hour % 12;
    if (h == 0) h = 12;
    return applyN(in, h);
}};


template <char C>
struct tag_char : tag_t<1> {
    inline static char* apply(char* in, const datetime&, uint32_t const*) {
        *in = C;
        return ++in;
    }
};


template <typename ...Ts> struct size_of_t;
template <typename T> struct size_of_t<T> { static const auto Value = T::value; };
template <typename T, typename ...Ts> struct size_of_t<T, Ts ...> {
    static const auto Value = (size_of_t<T>::Value + size_of_t<Ts...>::Value);
};

template <typename ... Tags> struct Composer;
template <typename T1> struct Composer<T1> {
    static char* fn(char* in, const datetime& dt, uint32_t const* mksec) {
        return T1::apply(in, dt, mksec);
    }
};
template <typename T, typename ...Tags> struct Composer<T, Tags...> {
    static char* fn(char* in, const datetime& dt, uint32_t const* mksec) {
        return Composer<Tags...>::fn(Composer<T>::fn(in, dt, mksec), dt, mksec);
    }
};

template <typename ...Args>
struct expression_t {
    static const auto N  = size_of_t<Args...>::Value;
    using FinalComposer = Composer<Args...>;

    inline static char* apply(char* in, const datetime& dt, uint32_t const* mksec) {
        return FinalComposer::fn(in,dt, mksec);
    }
};

using iso_sec_t = expression_t<
    tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<' '>,
    tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec
>;

using iso_t = expression_t<
    tag_year, tag_char<'-'>, tag_month, tag_char<'-'>, tag_day, tag_char<' '>,
    tag_hour, tag_char<':'>, tag_min, tag_char<':'>, tag_sec, tag_mksec
>;

using mysql_t    = expression_t<tag_year,  tag_month,     tag_day,   tag_hour,      tag_min, tag_sec>;
using hms_t      = expression_t<tag_hour,  tag_char<':'>, tag_min,   tag_char<':'>, tag_sec>;
using ymd_t      = expression_t<tag_year,  tag_char<'/'>, tag_month, tag_char<'/'>, tag_day>;
using mdy_t      = expression_t<tag_month, tag_char<'/'>, tag_day,   tag_char<'/'>, tag_year>;
using dmy_t      = expression_t<tag_day,   tag_char<'/'>, tag_month, tag_char<'/'>, tag_year>;
using ampm_t     = expression_t<tag_ampm>;
using meridiam_t = expression_t<tag_hour_meridiam, tag_char<':'>, tag_min, tag_char<' '>, tag_ampm>;


}}}
