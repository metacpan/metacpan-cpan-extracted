#include <panda/date/inc.h>
#include <panda/date/DateInt.h>
#include <panda/date/DateRel.h>

namespace panda { namespace date {

DateInt& DateInt::operator= (string_view data) {
    auto len = data.length();
    auto str = data.data();
    const char* delim = strchr(str, '~');
    if (delim == NULL || delim >= str + len - 2) {
        _from.error(E_UNPARSABLE);
        return *this;
    }

    // skip trailing spaces
    const char* from_end = delim;
    while (*from_end-- == ' ');
    err_t error = _from.set(string_view(str, from_end - str));
    if (error != E_OK) return *this;

    const char* till_starts = delim + 2;
    _till.set(string_view(till_starts, str + len - till_starts));
    return *this;
}

panda::string DateInt::to_string () const {
    if (error()) return panda::string{};
    return _from.to_string() + " ~ " +  _till.to_string();
}

}}
