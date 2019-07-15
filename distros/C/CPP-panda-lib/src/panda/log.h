#pragma once
#include <string>
#include <memory>
#include <string.h>
#include <type_traits>
#include <panda/string_view.h>

namespace panda { namespace log {

#ifdef WIN32
#  define __FILENAME__ (strrchr(__FILE__, '\\') ? strrchr(__FILE__, '\\') + 1 : __FILE__)
#else
#  define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#endif

#define _panda_log_code_point_ panda::log::CodePoint{__FILENAME__, __LINE__}

#define panda_should_log(level) panda::log::should_log(level, _panda_log_code_point_)

#define panda_elog(level, code) do {                                        \
    if (panda::log::should_log(level, _panda_log_code_point_)) {            \
        std::ostream& log = panda::log::details::_get_os();                 \
        code;                                                               \
        panda::log::details::_do_log(log, _panda_log_code_point_, level);   \
    }                                                                       \
} while (0);

#define panda_log(level, msg) panda_elog(level, { log << msg; })

#define panda_log_verbose_debug(msg)   panda_log(panda::log::VerboseDebug, msg)
#define panda_log_debug(msg)           panda_log(panda::log::Debug, msg)
#define panda_log_info(msg)            panda_log(panda::log::Info, msg)
#define panda_log_notice(msg)          panda_log(panda::log::Notice, msg)
#define panda_log_warn(msg)            panda_log(panda::log::Warning, msg)
#define panda_log_error(msg)           panda_log(panda::log::Error, msg)
#define panda_log_critical(msg)        panda_log(panda::log::Critical, msg)
#define panda_log_alert(msg)           panda_log(panda::log::Alert, msg)
#define panda_log_emergency(msg)       panda_log(panda::log::Emergency, msg)
#define panda_elog_verbose_debug(code) panda_elog(panda::log::VerboseDebug, code)
#define panda_elog_debug(code)         panda_elog(panda::log::Debug, code)
#define panda_elog_info(code)          panda_elog(panda::log::Info, code)
#define panda_elog_notice(code)        panda_elog(panda::log::Notice, code)
#define panda_elog_warn(code)          panda_elog(panda::log::Warning, code)
#define panda_elog_error(code)         panda_elog(panda::log::Error, code)
#define panda_elog_critical(code)      panda_elog(panda::log::Critical, code)
#define panda_elog_alert(code)         panda_elog(panda::log::Alert, code)
#define panda_elog_emergency(code)     panda_elog(panda::log::Emergency, code)

#define panda_debug_v(var) panda_log(panda::log::Debug, #var << " = " << (var))

#define PANDA_ASSERT(var, msg) if(!(auto assert_value = var)) { panda_log_emergency("assert failed: " << #var << " is " << assert_value << msg) }

enum Level {
    VerboseDebug = 0,
    Debug,
    Info,
    Notice,
    Warning,
    Error,
    Critical,
    Alert,
    Emergency
};

struct CodePoint {
    std::string_view file;
    uint32_t         line;

    std::string to_string () const;
};
std::ostream& operator<< (std::ostream&, const CodePoint&);

struct ILogger {
    virtual bool should_log (Level, const CodePoint&) { return true; }
    virtual void log        (Level, const CodePoint&, const std::string&) = 0;
    virtual ~ILogger() {}
};

namespace details {
    extern Level                    min_level;
    extern std::unique_ptr<ILogger> ilogger;

    std::ostream& _get_os ();
    bool          _do_log (std::ostream&, const CodePoint&, Level);

    template <class Func>
    struct CallbackLogger : ILogger {
        Func f;
        CallbackLogger (const Func& f) : f(f) {}
        void log (Level level, const CodePoint& cp, const std::string& s) override { f(level, cp, s); }
    };
}

void set_level  (Level);
void set_logger (ILogger*);

template <class Func, typename = std::enable_if_t<!std::is_base_of<ILogger, std::remove_cv_t<std::remove_pointer_t<Func>>>::value>>
void set_logger (const Func& f) { set_logger(new details::CallbackLogger<Func>(f)); }

inline bool should_log (Level level, const CodePoint& cp) { return level >= details::min_level && details::ilogger && details::ilogger->should_log(level, cp); }

struct escaped {
    std::string_view src;
};
std::ostream& operator<< (std::ostream&, const escaped&);

}}

