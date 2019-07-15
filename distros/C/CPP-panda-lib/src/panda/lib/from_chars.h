#pragma once
#if __cpp_lib_to_chars >= 201611L
#  include <charconv>
#else
#  include <cmath>
#  include <limits>
#  include <stdint.h>
#  include <stddef.h>
#  include <system_error>

namespace std {

struct from_chars_result {
    const char* ptr;
    std::error_code ec;
};

struct to_chars_result {
    char* ptr;
    std::error_code ec;
};

std::from_chars_result from_chars (const char* first, const char* last, int8_t&             value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, int16_t&            value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, int&                value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, long&               value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, long long&          value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, uint8_t&            value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, uint16_t&           value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, unsigned&           value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, unsigned long&      value, int base = 10);
std::from_chars_result from_chars (const char* first, const char* last, unsigned long long& value, int base = 10);

std::to_chars_result to_chars (char* first, char* last, int8_t             value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, int16_t            value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, int                value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, long               value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, long long          value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, uint8_t            value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, uint16_t           value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, unsigned           value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, unsigned long      value, int base = 10);
std::to_chars_result to_chars (char* first, char* last, unsigned long long value, int base = 10);

}

#endif

namespace panda {

template <typename UT>
constexpr typename std::enable_if<std::is_unsigned<UT>::value, size_t>::type to_chars_maxsize (int base = 10) {
    return std::ceil(std::numeric_limits<UT>::digits * (std::log(2) / std::log(base)));
}

template <typename T>
constexpr typename std::enable_if<!std::is_unsigned<T>::value, size_t>::type to_chars_maxsize (int base = 10) {
    return std::ceil(std::numeric_limits<T>::digits * (std::log(2) / std::log(base)) + 1);
}

}
