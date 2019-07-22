#include "from_chars.h"
#include <cctype> // isspace
#include <cstring> // memcpy
#include <stdexcept>

namespace panda {

static unsigned _index[256];
static char     _rindex[36];

static bool _init () {
    for (auto& val : _index) val = 255;
    for (int i = 0; i <= 9; ++i)  _index['0' + i] = i;
    for (int i = 0; i <= 25; ++i) _index['a' + i] = i+10;
    for (int i = 0; i <= 25; ++i) _index['A' + i] = i+10;
    for (int i = 0; i <= 9; ++i)  _rindex[i]      = '0' + i;
    for (int i = 0; i <= 25; ++i) _rindex[i + 10] = 'a' + i;
    return true;
}
static const bool _inited = _init();

static inline bool _is_space (unsigned char ch)    { return std::isspace(ch); }
//static inline bool _is_space (unsigned wchar_t ch) { return std::iswspace(ch); }

template <class C>
static inline bool _find_sign (const C*& ptr, const C* const end) {
    if (ptr == end) return false;

    bool minus = false;
    if (*ptr == '-') { ++ptr; minus = true; }
    else if (*ptr == '+') ++ptr;

    return minus;
}

template <typename UT, typename UC>
static inline UT _parse (const UC*& ptr, const UC* const end, unsigned base, UT max, bool& overflow) {
    UT res = 0;
    UT maxmp = max / base;
    overflow = false;

    for (; ptr != end; ++ptr) {
        if (sizeof(UC) > 1 && *ptr > 255) break;
        auto val = _index[*ptr];
        if (val >= base) break;
        if (res > maxmp) { overflow = true; res = max; break; }
        res *= base;
        if (val > (UT)(max - res)) { overflow = true; res = max; break; }
        res += val;
    }

    if (overflow) for (; ptr != end; ++ptr) if ((sizeof(UC) > 1 && *ptr > 255) || _index[*ptr] >= base) break; // move to the end of the number

    return res;
}

template <typename UT, typename C>
static inline typename std::enable_if<std::is_unsigned<UT>::value, from_chars_result>::type _from_chars (const C* s, const C* send, UT& value, unsigned base) {
    using UC = typename std::make_unsigned<C>::type;
    const UC* ptr = (const UC*)s;
    const UC* const end = (const UC*)send;
    if (base < 2 || base > 36) base = 10;

    while (ptr != end && _is_space(*ptr)) ++ptr; // skip whitespaces in the beginning

    bool overflow;
    auto tmp = ptr;
    value = _parse(ptr, end, base, std::numeric_limits<UT>::max(), overflow);

    if (ptr - tmp == 0) return {s, make_error_code(std::errc::invalid_argument)};
    if (overflow)       return {(const C*)ptr, make_error_code(std::errc::result_out_of_range)};
    return {(const C*)ptr, std::error_code()};
}

template <typename T, typename C>
static inline typename std::enable_if<!std::is_unsigned<T>::value, from_chars_result>::type _from_chars (const C* s, const C* send, T& value, unsigned base) {
    using UC = typename std::make_unsigned<C>::type;
    using UT = typename std::make_unsigned<T>::type;
    const UC* ptr = (const UC*)s;
    const UC* const end = (const UC*)send;
    if (base < 2 || base > 36) base = 10;

    while (ptr != end && _is_space(*ptr)) ++ptr; // skip whitespaces in the beginning

    bool minus = false;
    if (ptr != end && *ptr == '-') { ++ptr; minus = true; }
    bool overflow;
    auto tmp = ptr;

    if (minus) {
        UT max = (UT)std::numeric_limits<T>::max() - (T)(std::numeric_limits<T>::max() + std::numeric_limits<T>::min());
        UT tmp = _parse<UT>(ptr, end, base, max, overflow);
        value = (T)0 - tmp;
    } else {
        value = _parse<UT>(ptr, end, base, (UT)std::numeric_limits<T>::max(), overflow);
    }

    if (ptr - tmp == 0) return {s, make_error_code(std::errc::invalid_argument)};
    if (overflow)       return {(const C*)ptr, make_error_code(std::errc::result_out_of_range)};
    return {(const C*)ptr, std::error_code()};
}

from_chars_result from_chars (const char* first, const char* last, int8_t&             value, int base) { return _from_chars<int8_t>            (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, int16_t&            value, int base) { return _from_chars<int16_t>           (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, int&                value, int base) { return _from_chars<int>               (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, long&               value, int base) { return _from_chars<long>              (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, long long&          value, int base) { return _from_chars<long long>         (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, uint8_t&            value, int base) { return _from_chars<uint8_t>           (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, uint16_t&           value, int base) { return _from_chars<uint16_t>          (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, unsigned&           value, int base) { return _from_chars<unsigned>          (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, unsigned long&      value, int base) { return _from_chars<unsigned long>     (first, last, value, base); }
from_chars_result from_chars (const char* first, const char* last, unsigned long long& value, int base) { return _from_chars<unsigned long long>(first, last, value, base); }

template <typename UT, typename C>
static inline C* _compile (C* ptr, UT value, int base) {
    do {
        *--ptr = _rindex[value % base];
        value /= base;
    } while (value != 0);
    return ptr;
}

template <typename UT, typename C>
static inline typename std::enable_if<std::is_unsigned<UT>::value, to_chars_result>::type _to_chars (C* d, C* dend, UT value, int base) {
    if (base < 2 || base > 36) base = 10;
    int maxsize = std::ceil(std::numeric_limits<UT>::digits * log(2) / log(base)); /* enough for UT-bit integer represented in given base */
    char strval[maxsize];
    char* end = strval + maxsize;
    char* begin = _compile(end, value, base);
    auto len = end - begin;
    if (dend - d < len) return {dend, make_error_code(std::errc::value_too_large)};
    std::memcpy(d, begin, len);
    return {d + len, std::error_code()};
}

template <typename T, typename C>
static inline typename std::enable_if<!std::is_unsigned<T>::value, to_chars_result>::type _to_chars (C* d, C* dend, T value, int base) {
    using UT = typename std::make_unsigned<T>::type;
    if (base < 2 || base > 36) base = 10;
    int maxsize = std::ceil(std::numeric_limits<UT>::digits * log(2) / log(base) + 1);
    char strval[maxsize];
    char* end = strval + maxsize;
    char* begin;

    if (value >= 0) begin = _compile(end, value, base);
    else {
        UT positive_value = (UT)std::numeric_limits<T>::max() - (T)(std::numeric_limits<T>::max() + value);
        begin = _compile(end, positive_value, base);
        *--begin = '-';
    }

    auto len = end - begin;
    if (dend - d < len) return {dend, make_error_code(std::errc::value_too_large)};
    std::memcpy(d, begin, len);
    return {d + len, std::error_code()};
}

to_chars_result to_chars (char* first, char* last, int8_t             value, int base) { return _to_chars<int8_t>  (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, int16_t            value, int base) { return _to_chars<int16_t> (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, int                value, int base) { return _to_chars<int> (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, long               value, int base) { return _to_chars<long> (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, long long          value, int base) { return _to_chars<long long> (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, uint8_t            value, int base) { return _to_chars<uint8_t> (first, last, value, base); }
to_chars_result to_chars (char* first, char* last, uint16_t           value, int base) { return _to_chars<uint16_t>(first, last, value, base); }
to_chars_result to_chars (char* first, char* last, unsigned           value, int base) { return _to_chars<unsigned>(first, last, value, base); }
to_chars_result to_chars (char* first, char* last, unsigned long      value, int base) { return _to_chars<unsigned long>(first, last, value, base); }
to_chars_result to_chars (char* first, char* last, unsigned long long value, int base) { return _to_chars<unsigned long long>(first, last, value, base); }

}
