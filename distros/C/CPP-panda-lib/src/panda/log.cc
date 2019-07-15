#include "log.h"
#include <math.h>
#include <memory>
#include <iomanip>
#include <sstream>

namespace panda { namespace log {

namespace details {
    Level                    min_level = Debug;
    std::unique_ptr<ILogger> ilogger;

    static thread_local std::ostringstream os;

    std::ostream& _get_os () { return os; }

    bool _do_log (std::ostream& _stream, const CodePoint& cp, Level level) {
        std::ostringstream& stream = static_cast<std::ostringstream&>(_stream);
        if (!ilogger) return false;
        stream.flush();
        std::string s(stream.str());
        stream.str({});
        ilogger->log(level, cp, s);
        return true;
    }
}

void set_level (Level val) {
    details::min_level = val;
}

void set_logger (ILogger* l) {
    details::ilogger.reset(l);
}

std::string CodePoint::to_string () const {
    std::ostringstream os;
    os << *this;
    os.flush();
    return os.str();
}

std::ostream& operator<< (std::ostream& stream, const CodePoint& cp) {
    size_t total = cp.file.size() + log10(cp.line) + 2;
    const char* whitespaces = "                        "; // 24 spaces
    if (total < 24) {
        whitespaces += total;
    } else {
        whitespaces = "";
    }
    stream << cp.file << ":" << cp.line << whitespaces;
    return stream;
}

std::ostream& operator<< (std::ostream& stream, const escaped& str) {
   for (auto c : str.src) {
       if (c > 31) {
           stream << c;
       } else {
           stream << "\\" << std::setfill('0') << std::setw(2) << uint32_t(uint8_t(c));
       }
   }
   return stream;
}

}}
