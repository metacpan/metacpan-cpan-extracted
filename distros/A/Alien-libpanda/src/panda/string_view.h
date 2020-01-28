#pragma once
#include "hash.h"
#include "basic_string_view.h"

//#if __cpp_lib_string_view >= 201603L
//#   define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
//// HACK! Clang contains <string_view> and includes it from <string>, but it does not define __cpp_lib_string_view
//#elif  __clang__ && defined(__has_include)
//#   if __has_include(<string_view>)
//#       define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
//#   endif
//#endif
//
//#if defined(PANDA_LIB_USE_PANDA_LIB_STRING_VIEW)
//#       include <string_view>
//#else
//#undef PANDA_LIB_USE_PANDA_LIB_STRING_VIEW
//#endif

namespace panda {
    using string_view    = basic_string_view<char>;
    using wstring_view   = basic_string_view<wchar_t>;
    using u16string_view = basic_string_view<char16_t>;
    using u32string_view = basic_string_view<char32_t>;
}

namespace std {
    template<>
    struct hash<panda::string_view> {
        size_t operator() (panda::string_view v) const {
            return panda::hash::hashXX<size_t>((const char*)v.data(), v.length());
        }
    };

    template<>
    struct hash<panda::u16string_view> {
        size_t operator() (panda::u16string_view v) const {
            return panda::hash::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(char16_t));
        }
    };

    template<>
    struct hash<panda::u32string_view> {
        size_t operator() (panda::u32string_view v) const {
            return panda::hash::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(char32_t));
        }
    };

    template<>
    struct hash<panda::wstring_view> {
        size_t operator() (panda::wstring_view v) const {
            return panda::hash::hashXX<size_t>((const char*)v.data(), v.length() * sizeof(wchar_t));
        }
    };
}
