#pragma once

#include <string>
#include <cstdlib>

// TODO demangle on other compilers as well
#if __GNUC__ >= 3
#include <cxxabi.h>
#define HAS_CXXABI 1
#endif

static inline std::string demangle(char const* name)
{
    #ifdef HAS_CXXABI

    int err;
    if (char* clear = abi::__cxa_demangle(name, nullptr, 0, &err))
    {
        std::string result = clear;
        std::free(clear);
        return result;
    }

    #endif
    return name;
}
