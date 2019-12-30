#pragma once
#include <exception>
#include <vector>
#include "string.h"

namespace panda {

struct backtrace {
    static const constexpr int max_depth = 50;

    backtrace () noexcept;
    backtrace (const backtrace &other) noexcept;

    string get_trace_string () const;
    const std::vector<void*>& get_trace () const noexcept { return buffer; }

    virtual ~backtrace () {}

private:
    std::vector<void*> buffer;
};

template <typename T>
struct bt : T, backtrace {
    template<typename ...Args>
    bt (Args&&... args) noexcept : T(std::forward<Args...>(args...)) {}
};

struct exception : std::exception, backtrace {
    exception () noexcept;
    exception (const string& whats) noexcept;
    exception (const exception& oth) noexcept;
    exception& operator= (const exception& oth) noexcept;

    const char* what () const noexcept override;

    virtual string whats () const noexcept;

private:
    mutable string _whats;
};


}
