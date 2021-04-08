#include "error.h"

namespace panda { namespace date {

const ErrorCategory error_category;

const char* ErrorCategory::name () const throw() { return "panda-date"; }

std::string ErrorCategory::message (int condition) const throw() {
    switch ((errc)condition) {
        case errc::parser_error  : return "could not parse date";
        case errc::out_of_range : return "input date is out of range";
        default                 : return {};
    }
}

}}
