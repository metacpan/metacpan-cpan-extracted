/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <string.h>
#include <stdio.h>

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES
#define C_CFISH_CHARBUF

#include "charmony.h"

#include "Clownfish/Test/TestCharBuf.h"

#include "Clownfish/CharBuf.h"
#include "Clownfish/Err.h"
#include "Clownfish/Num.h"
#include "Clownfish/String.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"

static char smiley[] = { (char)0xE2, (char)0x98, (char)0xBA, 0 };
static uint32_t smiley_len = 3;

TestCharBuf*
TestCB_new() {
    return (TestCharBuf*)Class_Make_Obj(TESTCHARBUF);
}

static CharBuf*
S_get_cb(const char *string) {
    CharBuf *cb = CB_new(0);
    CB_Cat_Utf8(cb, string, strlen(string));
    return cb;
}

static String*
S_get_str(const char *string) {
    return Str_new_from_utf8(string, strlen(string));
}

static bool
S_cb_equals(CharBuf *cb, String *other) {
    String *string = CB_To_String(cb);
    bool retval = Str_Equals(string, (Obj*)other);
    DECREF(string);
    return retval;
}

static void
S_cat_invalid_utf8(void *context) {
    CharBuf *cb = (CharBuf*)context;
    CB_Cat_Utf8(cb, "\xF0" "a", 2);
}

static void
test_Cat(TestBatchRunner *runner) {
    String  *wanted = Str_newf("a%s", smiley);
    CharBuf *got    = S_get_cb("");

    CB_Cat(got, wanted);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "Cat");
    DECREF(got);

    got = S_get_cb("a");
    CB_Cat_Char(got, 0x263A);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "Cat_Char");
    DECREF(got);

    got = S_get_cb("a");
    CB_Cat_Utf8(got, smiley, smiley_len);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "Cat_Utf8");
    DECREF(got);

    got = S_get_cb("a");
    Err *error = Err_trap(S_cat_invalid_utf8, got);
    TEST_TRUE(runner, error != NULL, "Cat_Utf8 throws with invalid UTF-8");
    DECREF(error);
    DECREF(got);

    got = S_get_cb("a");
    CB_Cat_Trusted_Utf8(got, smiley, smiley_len);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "Cat_Trusted_Utf8");
    DECREF(got);

    DECREF(wanted);
}

static void
test_roundtrip(TestBatchRunner *runner) {
    CharBuf *cb = CB_new(0);
    int32_t code_point;

    for (code_point = 0; code_point <= 0x10FFFF; code_point++) {
        if (code_point >= 0xD800 && code_point <= 0xDFFF) { continue; }

        CB_Cat_Char(cb, code_point);
        String *str = CB_Yield_String(cb);
        const char *start = Str_Get_Ptr8(str);
        size_t size = Str_Get_Size(str);

        // Verify that utf8_valid agrees.
        if (!Str_utf8_valid(start, size)) {
            break;
        }

        // Verify round trip of encode/decode.
        if (Str_Code_Point_At(str, 0) != code_point) {
            break;
        }

        DECREF(str);
    }
    if (code_point == 0x110000) {
        PASS(runner, "Successfully round tripped 0 - 0x10FFFF");
    }
    else {
        FAIL(runner, "Failed round trip at 0x%04X", (unsigned)code_point);
    }

    DECREF(cb);
}

typedef struct {
    CharBuf *cb;
    int32_t  code_point;
} CatCharContext;

static void
S_cat_invalid_char(void *vcontext) {
    CatCharContext *context = (CatCharContext*)vcontext;
    CB_Cat_Char(context->cb, context->code_point);
}

static void
test_invalid_chars(TestBatchRunner *runner) {
    static const int32_t cps[] = { -1, 0xD800, 0xDFFF, 0x110000 };
    size_t num_cps = sizeof(cps) / sizeof(cps[0]);
    CatCharContext context;
    context.cb = CB_new(0);

    for (size_t i = 0; i < num_cps; i++) {
        context.code_point = cps[i];
        Err *error = Err_trap(S_cat_invalid_char, &context);
        TEST_TRUE(runner, error != NULL, "Cat_Char with invalid code point %d",
                  (int)cps[i]);
        DECREF(error);
    }

    DECREF(context.cb);
}

static void
test_Clone(TestBatchRunner *runner) {
    String  *wanted    = S_get_str("foo");
    CharBuf *wanted_cb = S_get_cb("foo");
    CharBuf *got       = CB_Clone(wanted_cb);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "Clone");
    DECREF(got);
    DECREF(wanted);
    DECREF(wanted_cb);
}

static void
test_vcatf_percent(TestBatchRunner *runner) {
    String  *wanted = S_get_str("foo % bar");
    CharBuf *got = S_get_cb("foo");
    CB_catf(got, " %% bar");
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%%%");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_s(TestBatchRunner *runner) {
    String  *wanted = S_get_str("foo bar bizzle baz");
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %s baz", "bizzle");
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%s");
    DECREF(wanted);
    DECREF(got);
}

static void
S_catf_s_invalid_utf8(void *context) {
    CharBuf *buf = (CharBuf*)context;
    CB_catf(buf, "bar %s baz", "\x82" "abcd");
}

static void
test_vcatf_s_invalid_utf8(TestBatchRunner *runner) {
    CharBuf *buf = S_get_cb("foo ");
    Err *error = Err_trap(S_catf_s_invalid_utf8, buf);
    TEST_TRUE(runner, error != NULL, "%%s with invalid UTF-8");
    DECREF(error);
    DECREF(buf);
}

static void
test_vcatf_null_string(TestBatchRunner *runner) {
    String  *wanted = S_get_str("foo bar [NULL] baz");
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %s baz", NULL);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%s NULL");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_str(TestBatchRunner *runner) {
    String  *wanted = S_get_str("foo bar ZEKE baz");
    String  *catworthy = S_get_str("ZEKE");
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %o baz", catworthy);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%o CharBuf");
    DECREF(catworthy);
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_obj(TestBatchRunner *runner) {
    String  *wanted = S_get_str("ooga 20 booga");
    Integer *i64    = Int_new(20);
    CharBuf *got    = S_get_cb("ooga");
    CB_catf(got, " %o booga", i64);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%o Obj");
    DECREF(i64);
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_null_obj(TestBatchRunner *runner) {
    String  *wanted = S_get_str("foo bar [NULL] baz");
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %o baz", NULL);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%o NULL");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_i8(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar -3 baz");
    int8_t num = -3;
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %i8 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%i8");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_i32(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar -100000 baz");
    int32_t num = -100000;
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %i32 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%i32");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_i64(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar -5000000000 baz");
    int64_t num = INT64_C(-5000000000);
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %i64 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%i64");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_u8(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar 3 baz");
    uint8_t num = 3;
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %u8 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%u8");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_u32(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar 100000 baz");
    uint32_t num = 100000;
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %u32 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%u32");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_u64(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo bar 5000000000 baz");
    uint64_t num = UINT64_C(5000000000);
    CharBuf *got = S_get_cb("foo ");
    CB_catf(got, "bar %u64 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%u64");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_f64(TestBatchRunner *runner) {
    String *wanted;
    char buf[64];
    float num = 1.3f;
    CharBuf *got = S_get_cb("foo ");
    sprintf(buf, "foo bar %g baz", num);
    wanted = Str_new_from_trusted_utf8(buf, strlen(buf));
    CB_catf(got, "bar %f64 baz", num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%f64");
    DECREF(wanted);
    DECREF(got);
}

static void
test_vcatf_x32(TestBatchRunner *runner) {
    String *wanted;
    char buf[64];
    unsigned long num = INT32_MAX;
    CharBuf *got = S_get_cb("foo ");
#if (CHY_SIZEOF_LONG == 4)
    sprintf(buf, "foo bar %.8lx baz", num);
#elif (CHY_SIZEOF_INT == 4)
    sprintf(buf, "foo bar %.8x baz", (unsigned)num);
#endif
    wanted = Str_new_from_trusted_utf8(buf, strlen(buf));
    CB_catf(got, "bar %x32 baz", (uint32_t)num);
    TEST_TRUE(runner, S_cb_equals(got, wanted), "%%x32");
    DECREF(wanted);
    DECREF(got);
}

typedef struct {
    CharBuf    *charbuf;
    const char *pattern;
} CatfContext;

static void
S_catf_invalid_pattern(void *vcontext) {
    CatfContext *context = (CatfContext*)vcontext;
    CB_catf(context->charbuf, context->pattern, 0);
}

static void
test_vcatf_invalid(TestBatchRunner *runner) {
    CatfContext context;
    context.charbuf = S_get_cb("foo ");

    static const char *const patterns[] = {
        "bar %z baz",
        "bar %i baz",
        "bar %i1 baz",
        "bar %i33 baz",
        "bar %i65 baz",
        "bar %u baz",
        "bar %u9 baz",
        "bar %u33 baz",
        "bar %u65 baz",
        "bar %x baz",
        "bar %x9 baz",
        "bar %x33 baz",
        "bar %f baz",
        "bar %f9 baz",
        "bar %f65 baz",
        "bar \xC2 baz"
    };
    static const size_t num_patterns = sizeof(patterns) / sizeof(patterns[0]);

    for (size_t i = 0; i < num_patterns; i++) {
        context.pattern = patterns[i];
        Err *error = Err_trap(S_catf_invalid_pattern, &context);
        TEST_TRUE(runner, error != NULL,
                  "catf throws with invalid pattern '%s'", patterns[i]);
        DECREF(error);
    }

    DECREF(context.charbuf);
}

static void
test_Clear(TestBatchRunner *runner) {
    CharBuf *cb = S_get_cb("foo");
    CB_Clear(cb);
    CB_Cat_Utf8(cb, "bar", 3);
    String *string = CB_Yield_String(cb);
    TEST_TRUE(runner, Str_Equals_Utf8(string, "bar", 3), "Clear");
    DECREF(string);
    DECREF(cb);
}

static void
test_Grow(TestBatchRunner *runner) {
    CharBuf *cb = S_get_cb("omega");
    CB_Grow(cb, 100);
    size_t cap = cb->cap;
    TEST_TRUE(runner, cap >= 100, "Grow");
    CB_Grow(cb, 100);
    TEST_UINT_EQ(runner, cb->cap, cap, "Grow to same size has no effect");
    DECREF(cb);
}

static void
test_Get_Size(TestBatchRunner *runner) {
    CharBuf *got = S_get_cb("a");
    CB_Cat_Utf8(got, smiley, smiley_len);
    TEST_UINT_EQ(runner, CB_Get_Size(got), smiley_len + 1, "Get_Size");
    DECREF(got);
}

void
TestCB_Run_IMP(TestCharBuf *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 46);
    test_vcatf_percent(runner);
    test_vcatf_s(runner);
    test_vcatf_s_invalid_utf8(runner);
    test_vcatf_null_string(runner);
    test_vcatf_str(runner);
    test_vcatf_obj(runner);
    test_vcatf_null_obj(runner);
    test_vcatf_i8(runner);
    test_vcatf_i32(runner);
    test_vcatf_i64(runner);
    test_vcatf_u8(runner);
    test_vcatf_u32(runner);
    test_vcatf_u64(runner);
    test_vcatf_f64(runner);
    test_vcatf_x32(runner);
    test_vcatf_invalid(runner);
    test_Cat(runner);
    test_roundtrip(runner);
    test_invalid_chars(runner);
    test_Clone(runner);
    test_Clear(runner);
    test_Grow(runner);
    test_Get_Size(runner);
}

