#include "test.h"
#include <panda/error.h>

using panda::ErrorCode;

enum MyErr {
    Err1 = 1,
    Err2
};

class MyCategory : public std::error_category
{
public:
    const char * name() const noexcept override {return "MyCategory";}
    std::string message(int ev) const override {return std::string("MyErr:") + std::to_string(ev);}
};

const MyCategory my_category;

namespace std {
template <> struct is_error_code_enum<MyErr> : std::true_type {};
}

std::error_code make_error_code(MyErr err) noexcept {
    return std::error_code(err, my_category);
}

TEST_CASE("ErrorCode ctor", "[error]") {
    SECTION("default") {
        ErrorCode code;
        CHECK_FALSE(code);
        CHECK_FALSE(code.next());
        CHECK_FALSE(code.code());
        CHECK_FALSE(code.next().code());
    }
    SECTION("val+cat") {
        ErrorCode code(2, my_category);
        CHECK(code);
        CHECK_FALSE(code.next());
    }
    SECTION("enum") {
        ErrorCode code(Err1);
        CHECK(code);
        CHECK_FALSE(code.next());
    }
    SECTION("nested") {
        ErrorCode nested_code(Err1);
        ErrorCode code(Err2, nested_code);
        CHECK(code);
        REQUIRE(code.next());
        CHECK_FALSE(code.next().next());
        CHECK(code.what() == "MyErr:2, preceded by:\n"
                             "MyErr:1");
        nested_code.clear();
        CHECK(code.next() == Err1); // check it was copy and no sharing
    }
}

TEST_CASE("ErrorCode methods", "[error]") {
    ErrorCode e1(Err1);
    ErrorCode e2;
    e2 = e1;
    REQUIRE(e2 == e1);
}

TEST_CASE("ErrorCode defctor", "[error]") {
    ErrorCode orig;
    ErrorCode wrap(Err1, orig);
    CHECK(wrap == Err1);
    CHECK(wrap.next().code().value() == 0);
}
