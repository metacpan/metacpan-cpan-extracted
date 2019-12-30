#include "test.h"
#include <panda/exception.h>

using namespace panda;

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
void fn48() { fn47(); }
void fn49() { fn48(); }
void fn50() { fn49(); }


TEST_CASE("exception with trace, catch exact exception", "[exception]") {
    bool was_catch = false;
    try {
        fn50();
    } catch( const bt<std::invalid_argument>& e) {
        REQUIRE(e.get_trace().size() == 50);
        auto trace = e.get_trace_string();
        REQUIRE((bool)trace);
        REQUIRE(e.what() == std::string("Oops!"));
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "lib.so" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "MyTest.so" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "fn00" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "fn40" ) );
        REQUIRE_THAT( trace, !Catch::Matchers::Contains( "fn50" ) );
        was_catch = true;
    }
    REQUIRE(was_catch);
}

TEST_CASE("exception with trace, catch non-final class", "[exception]") {
    bool was_catch = false;
    try {
        fn50();
    } catch( const std::logic_error& e) {
        REQUIRE(e.what() == std::string("Oops!"));
        auto bt = dyn_cast<const backtrace*>(&e);
        REQUIRE(bt);
        REQUIRE(bt->get_trace().size() == 50);
        auto trace = bt->get_trace_string();
        REQUIRE((bool)trace);
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "lib.so" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "MyTest.so" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "fn00" ) );
        REQUIRE_THAT( trace, Catch::Matchers::Contains( "fn40" ) );
        REQUIRE_THAT( trace, !Catch::Matchers::Contains( "fn50" ) );
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
