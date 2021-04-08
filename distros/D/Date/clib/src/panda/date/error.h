#pragma once
#include <system_error>

namespace panda { namespace date {

enum class errc : uint8_t {
    ok = 0,
    parser_error = 1,
    out_of_range,
};

struct ErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};
extern const ErrorCategory error_category;

inline std::error_code make_error_code (errc code) { return std::error_code((int)code, error_category); }

}}

namespace std {
    template <>
    struct is_error_code_enum<panda::date::errc> : true_type {};
}
