#pragma once

#if __cpp_lib_string_view >= 201603L
#   define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
// HACK! Clang contains <string_view> and includes it from <string>, but it does not define __cpp_lib_string_view 
#elif  __clang__ && defined(__has_include)
#   if __has_include(<string_view>)
#       define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
#   endif
#endif

#if defined(PANDA_LIB_USE_PANDA_LIB_STRING_VIEW)
#       include <string_view>
#else
#       include <panda/lib/hash.h>
#       include <panda/basic_string_view.h>
namespace std {

    typedef basic_string_view<char>     string_view;
    typedef basic_string_view<wchar_t>  wstring_view;
    typedef basic_string_view<char16_t> u16string_view;
    typedef basic_string_view<char32_t> u32string_view;

    template<>
    struct hash<string_view> {
        size_t operator() (string_view v) const {
            return panda::lib::hashXX<size_t>((const char*)v.data(), v.length());
        }
    };

    template<>
    struct hash<u16string_view> {
        size_t operator() (u16string_view v) const {
            return panda::lib::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(char16_t));
        }
    };

    template<>
    struct hash<u32string_view> {
        size_t operator() (u32string_view v) const {
            return panda::lib::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(char32_t));
        }
    };

    template<>
    struct hash<wstring_view> {
        size_t operator() (wstring_view v) const {
            return panda::lib::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(wchar_t));
        }
    };

    inline namespace literals { namespace string_view_literals {

        // uncomment when -Wno-literal-suffix works
        //constexpr string_view    operator "" sv (const char*     str, size_t len) noexcept { return string_view(str, len); }
        //constexpr u16string_view operator "" sv (const char16_t* str, size_t len) noexcept { return u16string_view(str, len); }
        //constexpr u32string_view operator "" sv (const char32_t* str, size_t len) noexcept { return u32string_view(str, len); }
        //constexpr wstring_view   operator "" sv (const wchar_t*  str, size_t len) noexcept { return wstring_view(str, len); }

    }}
}
#undef PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 
#endif
