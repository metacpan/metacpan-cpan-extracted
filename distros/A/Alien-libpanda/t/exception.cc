#include "test.h"
#include <panda/exception.h>
#include <panda/from_chars.h>
#include <regex>
#include <cxxabi.h>
#include <iostream>
#if defined(__unix__)
  #include <execinfo.h>
#endif

using namespace panda;

iptr<BacktraceInfo> glib_produce(const RawTrace& buffer);
static BacktraceProducer glib_producer(glib_produce);

static bool _init() {
    Backtrace::install_producer(glib_producer);
    return true;
}
static bool init = _init();

static std::regex re("(.+)\\((.+)\\+0x(.+)\\) \\[0x(.+)\\]");

static StackframePtr as_frame (const char* symbol) {
    using guard_t = std::unique_ptr<char*, std::function<void(char**)>>;
    auto r = StackframePtr(new Stackframe());
    std::cmatch what;
    if (regex_match(symbol, what, re)) {
        panda::string dll           (what[1].first, what[1].length());
        panda::string mangled_name  (what[2].first, what[2].length());
        panda::string symbol_offset (what[3].first, what[3].length());
        panda::string address       (what[4].first, what[4].length());

        int status;
        char* demangled_name = abi::__cxa_demangle(mangled_name.c_str(), nullptr, nullptr, &status);
        guard_t guard;
        //printf("symbol = %s, d = %s, o=%s\n", symbol, demangled_name ? demangled_name : "[n/a]", mangled_name.c_str());
        if (demangled_name) {
            guard = guard_t(&demangled_name, [](char** ptr) { free(*ptr); });
        } else {
            demangled_name = (char*)mangled_name.c_str();
        }
        r->name = demangled_name;
        r->mangled_name = mangled_name;
        r->file = "n/a";
        r->library = dll;
        r->line_no = 0;

        std::uint64_t addr = 0;
        // +2 to skip 0x prefix
        auto addr_r = from_chars(address.data(), address.data() + address.length(), addr, 16);
        if (!addr_r.ec) { r->address = addr; }
        else            { r->address = 0; }

        std::uint64_t offset = 0;
        // +2 to skip 0x prefix
        auto offset_r = from_chars(symbol_offset.data(), symbol_offset.data() + symbol_offset.size(), offset, 16);
        if (!offset_r.ec) { r->offset = offset; }
        else              { r->offset = 0; }
        //printf("symbol = %s\n", symbol);
    }
    return r;
}

struct glib_backtrace: BacktraceInfo {

    glib_backtrace(std::vector<StackframePtr>&& frames_):frames{std::move(frames_)}{}

    const std::vector<StackframePtr>& get_frames() const override { return frames; }
    virtual string to_string() const override { std::abort(); }

    std::vector<StackframePtr> frames;
};

iptr<BacktraceInfo> glib_produce(const RawTrace& buffer) {
    using guard_t = std::unique_ptr<char**, std::function<void(char***)>>;
    char** symbols = backtrace_symbols(buffer.data(), buffer.size());
    if (symbols) {
        guard_t guard(&symbols, [](char*** ptr) { free(*ptr); });
        std::vector<StackframePtr> frames;
        frames.reserve(buffer.size());
        for (int i = 0; i < static_cast<int>(buffer.size()); ++i) {
            // printf("symbol = %s\n", symbols[i]);
            auto frame = as_frame(symbols[i]);
            frames.emplace_back(std::move(frame));
        }
        auto ptr = new glib_backtrace(std::move(frames));
        return iptr<BacktraceInfo>(ptr);
    }
    return iptr<BacktraceInfo>();
}

// prevent inlining
extern "C" {

int v = 0;

void fnxx() { ++v; }
void fn00() { ++v; fnxx(); throw bt<std::invalid_argument>("Oops!"); }
void fn01() { fn00(); ++v; }
void fn02() { fn01(); ++v; }
void fn03() { fn02(); ++v; }
void fn04() { fn03(); ++v; }
void fn05() { fn04(); ++v; }
void fn06() { fn05(); ++v; }
void fn07() { fn06(); ++v; }
void fn08() { fn07(); ++v; }
void fn09() { fn08(); ++v; }
void fn10() { fn09(); ++v; }
void fn11() { fn10(); ++v; }
void fn12() { fn11(); ++v; }
void fn13() { fn12(); ++v; }
void fn14() { fn13(); ++v; }
void fn15() { fn14(); ++v; }
void fn16() { fn15(); ++v; }
void fn17() { fn16(); ++v; }
void fn18() { fn17(); ++v; }
void fn19() { fn18(); ++v; }
void fn20() { fn19(); ++v; }
void fn21() { fn20(); ++v; }
void fn22() { fn21(); ++v; }
void fn23() { fn22(); ++v; }
void fn24() { fn23(); ++v; }
void fn25() { fn24(); ++v; }
void fn26() { fn25(); ++v; }
void fn27() { fn26(); ++v; }
void fn28() { fn27(); ++v; }
void fn29() { fn28(); ++v; }
void fn30() { fn29(); ++v; }
void fn31() { fn30(); ++v; }
void fn32() { fn31(); ++v; }
void fn33() { fn32(); ++v; }
void fn34() { fn33(); ++v; }
void fn35() { fn34(); ++v; }
void fn36() { fn35(); ++v; }
void fn37() { fn36(); ++v; }
void fn38() { fn37(); ++v; }
void fn39() { fn38(); ++v; }
void fn40() { fn39(); ++v; }
void fn41() { fn40(); ++v; }
void fn42() { fn41(); ++v; }
void fn43() { fn42(); ++v; }
void fn44() { fn43(); ++v; }
void fn45() { fn44(); ++v; }
void fn46() { fn45(); ++v; }
void fn47() { fn46(); ++v; }
void fn48() { fn47(); ++v; }

}

TEST_CASE("exception with trace, catch exact exception", "[exception]") {
    bool was_catch = false;
    try {
        fn48();
    } catch( const bt<std::invalid_argument>& e) {
        auto trace = e.get_backtrace_info();
        REQUIRE(e.get_trace().size() == 50);
        REQUIRE((bool)trace);
        REQUIRE(e.what() == std::string("Oops!"));

        auto frames = trace->get_frames();
        REQUIRE(frames.size() >= 47);
        
        StackframePtr fn00_frame = nullptr;
        StackframePtr fn46_frame = nullptr;

        for(auto& f : frames)  {
            std::cout << f->name << "\n";
            if (f->name.find("fn00") != string::npos) { fn00_frame = f; }
            if (f->name.find("fn46") != string::npos) { fn46_frame = f; }
        }
        REQUIRE(fn00_frame);
        REQUIRE(fn46_frame);
        CHECK_THAT( fn00_frame->library, Catch::Matchers::Contains( "MyTest.so" ) );
        CHECK_THAT( fn00_frame->name, Catch::Matchers::Contains( "fn00" ) );
        CHECK( fn46_frame->address > 0);
        CHECK( fn46_frame->offset > 0);
        CHECK_THAT( fn46_frame->library, Catch::Matchers::Contains( "MyTest.so" ) );

        was_catch = true;
    }
    REQUIRE(was_catch);
}

TEST_CASE("exception with trace, catch non-final class", "[exception]") {
    bool was_catch = false;
    try {
        fn48();
    } catch( const std::logic_error& e) {
        REQUIRE(e.what() == std::string("Oops!"));
        auto bt = dyn_cast<const panda::Backtrace*>(&e);
        REQUIRE(bt);
        REQUIRE(bt->get_trace().size() == 50);
        auto trace = bt->get_backtrace_info();
        REQUIRE((bool)trace);
        auto frames = trace->get_frames();
        REQUIRE(frames.size() >= 47);
        StackframePtr fn00_frame = nullptr;
        StackframePtr fn46_frame = nullptr;

        for(auto& f : frames)  {
            if (f->name.find("fn00") != string::npos) { fn00_frame = f; }
            if (f->name.find("fn46") != string::npos) { fn46_frame = f; }
        }
        CHECK(fn00_frame);
        CHECK(fn46_frame);
        was_catch = true;
    }
    REQUIRE(was_catch);
}

TEST_CASE("panda::exception with string", "[exception]") {
    bool was_catch = false;
    try {
        throw panda::exception("my-description");
    } catch( const exception& e) {
        REQUIRE(e.whats() == "my-description");
        was_catch = true;
    }
    REQUIRE(was_catch);
}
