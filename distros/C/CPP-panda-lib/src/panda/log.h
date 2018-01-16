#pragma once

#include <string>
#include <sstream>
#include <iostream>
#include <vector>
#include <panda/function.h>
#include <panda/string_view.h>
#include <panda/CallbackDispatcher.h>
#include <string.h>
#include <chrono>
#include <math.h>

namespace panda {

namespace logger {
    struct CodePoint;

    template <typename S>
    S& operator <<(S& stream, const CodePoint& cp);

    struct CodePoint {
        std::string_view file;
        uint32_t line;

        std::string to_string() const {
            std::ostringstream os;
            os << *this;
            os.flush();
            return os.str();
        }
    };

    template <typename S>
    S& operator <<(S& stream, const CodePoint& cp) {
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


    enum Level {
        EMERGENCY,
        CRITICAL,
        WARNING,
        INFO,
        VERBOSE,
        DEBUG
    };

    struct ILogger {
        virtual bool should_log(Level, CodePoint) {return true;}
        virtual void log(Level, CodePoint, const std::string&) = 0;
    };
}

class Log
{
public:

    Log(logger::CodePoint cp, logger::Level log_level = logger::DEBUG)
        : level(log_level),
          cp(cp)
    {}

    Log(Log&& oth) = default;

    explicit operator bool() const {
        return should_log(level, cp);
    }

    template <typename T>
    std::ostringstream& operator <<(T&& t)
    {
        os << t;
        return os;
    }

    ~Log()
    {
        if (!logger()) {
            return;
        }
        os.flush();
        s = os.str();

        logger()->log(level, cp, s);
    }

    static std::unique_ptr<logger::ILogger>& logger();

    static bool should_log(logger::Level level, logger::CodePoint cp);

    static void set_max_level(logger::Level val);

private:
    std::string s;
    std::ostringstream os;
    logger::Level level;
    logger::CodePoint cp;
};
#ifdef WIN323
#  define __FILENAME__ (strrchr(__FILE__, '\\') ? strrchr(__FILE__, '\\') + 1 : __FILE__)
#else
#  define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#endif // WIN32

#define _panda_code_point_ panda::logger::CodePoint{__FILENAME__, __LINE__}
#define _panda_log_impl_(LEVEL, MSG) panda::Log::should_log(panda::logger::LEVEL, _panda_code_point_) \
                                 && (panda::Log(_panda_code_point_, panda::logger::LEVEL) << MSG)

#define panda_debug_v(VAR) _panda_log_impl_(DEBUG, #VAR << " = " << (VAR))

#define panda_log_debug(MSG) _panda_log_impl_(DEBUG, MSG)
#define panda_log_verbose(MSG) _panda_log_impl_(VERBOSE, MSG)
#define panda_log_info(MSG) _panda_log_impl_(INFO, MSG)
#define panda_log_warn(MSG) _panda_log_impl_(WARNING, MSG)

#define panda_log_critical(MSG) _panda_log_impl_(CRITICAL, MSG)
#define panda_log_emergency(MSG) _panda_log_impl_(EMERGENCY, MSG)


#define PANDA_ASSERT(VAR, MSG) if(!(auto assert_value = VAR)) {panda_log_emergency("assert failed: " << #VAR << " is " << assert_value << MSG)}

}
