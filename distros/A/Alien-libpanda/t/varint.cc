#include "test.h"
#include <panda/varint.h>

using namespace panda;

TEST_CASE("varint encode", "[varint]") {
    CHECK(varint_encode(0) == string("\0"));
    CHECK(varint_encode(1) == string("\1"));
    CHECK(varint_encode(127) == string("\x7f"));

    CHECK(varint_encode(128) == string("\x80\1"));
    CHECK(varint_encode(129) == string("\x81\1"));
}

TEST_CASE("varint decode", "[varint]") {
    CHECK(varint_decode(string("\0")) == 0);
    CHECK(varint_decode(string("\1")) == 1);
    CHECK(varint_decode(string("\x7f")) == 127);

    CHECK(varint_decode(string("\x80\1")) == 128);
    CHECK(varint_decode(string("\x81\1")) == 129);
}

TEST_CASE("varint cross check", "[varint]") {
    for (uint32_t i = 0; i < 256; ++i) {
        if (varint_decode(varint_encode(i)) != i) {
            FAIL(i);
        }
    }
    for (uint32_t i = 0; i < 500000; i+=29) {
        if (varint_decode(varint_encode(i)) != i) {
            FAIL(i);
        }
    }
    REQUIRE(true);
}

TEST_CASE("varint_s cross check", "[varint]") {
    for (int i = 256; i < 256; ++i) {
        if (varint_decode_s(varint_encode_s(i)) != i) {
            FAIL(i);
        }
    }
    for (int i = -500000; i < 500000; i+=29) {
        int res = varint_decode_s(varint_encode_s(i));
        if (res != i) {
            INFO(res);
            FAIL(i);
        }
    }
    REQUIRE(true);
}

TEST_CASE("VarIntStack", "[varint]") {
    VarIntStack stack;
    stack.push(300);
    stack.push(400);
    CHECK(stack.top() == 400);
    stack.pop();
    CHECK(stack.top() == 300);
}
