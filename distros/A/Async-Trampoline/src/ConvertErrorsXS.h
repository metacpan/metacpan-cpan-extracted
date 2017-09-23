#pragma once

#include "Demangle.h"

// requires the Perl headers

#include <typeinfo>
#include <stdexcept>

#define CXX_TRY try {

#define CXX_CATCH } catch (std::exception const& _convert_errors_xs_ex) {   \
    croak("%s: %s",                                                         \
            demangle(typeid(_convert_errors_xs_ex).name()).c_str(),         \
            _convert_errors_xs_ex.what());                               \
}
