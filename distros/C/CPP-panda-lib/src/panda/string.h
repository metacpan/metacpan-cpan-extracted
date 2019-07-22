#pragma once
#include "basic_string.h"

namespace panda {
    typedef basic_string<char>     string;
    typedef basic_string<wchar_t>  wstring;
    typedef basic_string<char16_t> u16string;
    typedef basic_string<char32_t> u32string;

    namespace {
        template <typename T>
        inline T _stox (const string& str, std::size_t* pos = 0, int base = 10) {
            T val;
            auto res = from_chars(str.data(), str.data() + str.length(), val, base);
            if (pos) {
                *pos = res.ptr - str.data();
            }
            if (res.ec) {
                if (res.ec == std::errc::invalid_argument) throw std::invalid_argument("stoi");
                else if (res.ec == std::errc::result_out_of_range) throw std::out_of_range("stoi");
            }
            return val;
        }
    }

    inline int                stoi   (const string& str, std::size_t* pos = 0, int base = 10) { return _stox<int>(str, pos, base); }
    inline long               stol   (const string& str, std::size_t* pos = 0, int base = 10) { return _stox<long>(str, pos, base); }
    inline long long          stoll  (const string& str, std::size_t* pos = 0, int base = 10) { return _stox<long long>(str, pos, base); }
    inline unsigned long      stoul  (const string& str, std::size_t* pos = 0, int base = 10) { return _stox<unsigned long>(str, pos, base); }
    inline unsigned long long stoull (const string& str, std::size_t* pos = 0, int base = 10) { return _stox<unsigned long long>(str, pos, base); }

    inline string to_string (int value)                { return string::from_number(value); }
    inline string to_string (long value)               { return string::from_number(value); }
    inline string to_string (long long value)          { return string::from_number(value); }
    inline string to_string (unsigned value)           { return string::from_number(value); }
    inline string to_string (unsigned long value)      { return string::from_number(value); }
    inline string to_string (unsigned long long value) { return string::from_number(value); }
}
