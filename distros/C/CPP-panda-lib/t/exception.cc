#include "test.h"
#include <panda/exception.h>
#include <panda/from_chars.h>
#include <regex>
#include <cxxabi.h>
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
    auto r = StackframePtr(new Stackframe());
    std::cmatch what;
    if (regex_match(symbol, what, re)) {
        panda::string dll           (what[1].first, what[1].length());
        panda::string mangled_name  (what[2].first, what[2].length());
        panda::string symbol_offset (what[3].first, what[3].length());
        panda::string address       (what[4].first, what[4].length());

        int status;
        char* demangled_name = abi::__cxa_demangle(mangled_name.c_str(), nullptr, nullptr, &status);
        if (demangled_name) {
            using guard_t = std::unique_ptr<char*, std::function<void(char**)>>;
            guard_t guard(&demangled_name, [](char** ptr) { free(*ptr); });

            r->name = demangled_name;
            r->mangled_name = symbol;
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
            printf("symbol = %s\n", symbol);
        }
    } else {
        r->mangled_name = r->name = panda::string("[demangle failed]") + symbol;
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
            auto frame = as_frame(symbols[i]);
            frames.emplace_back(std::move(frame));
        }
        auto ptr = new glib_backtrace(std::move(frames));
        return iptr<BacktraceInfo>(ptr);
    }
    return iptr<BacktraceInfo>();
}

void fn00() { throw bt<std::invalid_argument>("Oops!"); }
void fn01() { fn00(); }
void fn02() { fn01(); }
void fn03() { fn02(); }
void fn04() { fn03(); }
void fn05() { fn04(); }
void fn06() { fn05(); }
void fn07() { fn06(); }
void fn08() { fn07(); }
void fn09() { fn08(); }
void fn10() { fn09(); }
void fn11() { fn10(); }
void fn12() { fn11(); }
void fn13() { fn12(); }
void fn14() { fn13(); }
void fn15() { fn14(); }
void fn16() { fn15(); }
void fn17() { fn16(); }
void fn18() { fn17(); }
void fn19() { fn18(); }
void fn20() { fn19(); }
void fn21() { fn20(); }
void fn22() { fn21(); }
void fn23() { fn22(); }
void fn24() { fn23(); }
void fn25() { fn24(); }
void fn26() { fn25(); }
void fn27() { fn26(); }
void fn28() { fn27(); }
void fn29() { fn28(); }
void fn30() { fn29(); }
void fn31() { fn30(); }
void fn32() { fn31(); }
void fn33() { fn32(); }
void fn34() { fn33(); }
void fn35() { fn34(); }
void fn36() { fn35(); }
void fn37() { fn36(); }
void fn38() { fn37(); }
void fn39() { fn38(); }
void fn40() { fn39(); }
void fn41() { fn40(); }
void fn42() { fn41(); }
void fn43() { fn42(); }
void fn44() { fn43(); }
void fn45() { fn44(); }
void fn46() { fn45(); }
void fn47() { fn46(); }
/*
void fn48() { fn47(); }
void fn49() { fn48(); }
void fn50() { fn49(); }
*/

TEST_CASE("exception with trace, catch exact exception", "[exception]") {
    bool was_catch = false;
    try {
        fn47();
    } catch( const bt<std::invalid_argument>& e) {
        REQUIRE(e.get_trace().size() == 50);
        auto trace = e.get_backtrace_info();
        REQUIRE((bool)trace);
        REQUIRE(e.what() == std::string("Oops!"));

        auto frames = trace->get_frames().data();
        auto& frame0 = frames[0];
        CHECK_THAT( frame0->library, Catch::Matchers::Contains( "lib.so" ) );
        auto& frame2 = frames[2];
        CHECK_THAT( frame2->library, Catch::Matchers::Contains( "MyTest.so" ) );
        CHECK(frame2->name == "fn00()");
        CHECK( frame2->address > 0);
        CHECK( frame2->offset > 0);

        auto& frame50 = frames[49];
        CHECK_THAT( frame50->library, Catch::Matchers::Contains( "MyTest.so" ) );
        CHECK(frame50->name == "fn47()");
        was_catch = true;
    }
    REQUIRE(was_catch);
}


TEST_CASE("exception with trace, catch non-final class", "[exception]") {
    bool was_catch = false;
    try {
        fn47();
    } catch( const std::logic_error& e) {
        REQUIRE(e.what() == std::string("Oops!"));
        auto bt = dyn_cast<const panda::Backtrace*>(&e);
        REQUIRE(bt);
        REQUIRE(bt->get_trace().size() == 50);
        auto trace = bt->get_backtrace_info();
        REQUIRE((bool)trace);
        auto frames = trace->get_frames().data();
        CHECK(frames[2]->name == "fn00()");
        CHECK(frames[49]->name == "fn47()");
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
