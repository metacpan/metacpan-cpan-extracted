#include "log.h"
#include <math.h>
#include <memory>
#include <iomanip>
#include <sstream>

namespace panda { namespace log {

namespace details {
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

void set_level (Level val, const string& module) {
    if (module) {
        auto& modules = ::panda_log_module->children;
        auto iter = modules.find(module);
        if (iter == modules.end()) {
            throw std::invalid_argument("unknown module");
        }
        iter->second->set_level(val);
    } else {
        panda_log_module->set_level(val);
    }

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

Module::Module(const string& name, Level level)
    : Module(name, panda_log_module, level)
{}

Module::Module(const string& name, Module* parent, Level level)
    : level(level), name(name)
{
    if (!parent) return;

    this->parent = parent;

    if (parent->children.find(name) != parent->children.end()) {
        string msg = "panda::log::Module " + name + "is already registered";
        throw std::logic_error(msg.c_str());
    }
    parent->children[name] = this;
}

void Module::set_level(Level level) {
    this->level = level;
    for (auto& p : children) {
        p.second->set_level(level);
    }
}

}
}

static panda::log::Module* panda_log_root_module() {
    static panda::log::Module inst("", nullptr);
    return &inst;
}
panda::log::Module* panda_log_module = panda_log_root_module();
