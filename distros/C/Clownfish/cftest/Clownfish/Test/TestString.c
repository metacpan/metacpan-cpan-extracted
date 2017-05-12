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

#include "Clownfish/Test/TestString.h"

#include "Clownfish/String.h"
#include "Clownfish/Boolean.h"
#include "Clownfish/ByteBuf.h"
#include "Clownfish/CharBuf.h"
#include "Clownfish/Err.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Util/Memory.h"
#include "Clownfish/Class.h"

#define SMILEY "\xE2\x98\xBA"
static char smiley[] = { (char)0xE2, (char)0x98, (char)0xBA, 0 };
static uint32_t smiley_len = 3;
static int32_t smiley_cp  = 0x263A;

static const uint8_t UTF8_COUNT[256] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

TestString*
TestStr_new() {
    return (TestString*)Class_Make_Obj(TESTSTRING);
}

static String*
S_get_str(const char *string) {
    return Str_new_from_utf8(string, strlen(string));
}

// Surround a smiley with lots of whitespace.
static String*
S_smiley_with_whitespace(size_t *num_spaces_ptr) {
    int32_t spaces[] = {
        ' ',    '\t',   '\r',   '\n',   0x000B, 0x000C, 0x000D, 0x0085,
        0x00A0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
        0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x2028, 0x2029, 0x202F,
        0x205F, 0x3000
    };
    size_t num_spaces = sizeof(spaces) / sizeof(uint32_t);

    CharBuf *buf = CB_new(0);
    for (size_t i = 0; i < num_spaces; i++) { CB_Cat_Char(buf, spaces[i]); }
    CB_Cat_Char(buf, smiley_cp);
    for (size_t i = 0; i < num_spaces; i++) { CB_Cat_Char(buf, spaces[i]); }

    String *retval = CB_To_String(buf);
    if (num_spaces_ptr) { *num_spaces_ptr = num_spaces; }

    DECREF(buf);
    return retval;
}

/* This alternative implementation of utf8_valid() is (presumably) slower, but
 * it implements the standard in a more linear, easy-to-grok way.
 */
#define TRAIL_OK(n) (n >= 0x80 && n <= 0xBF)
static bool
S_utf8_valid_alt(const char *maybe_utf8, size_t size) {
    const uint8_t *string = (const uint8_t*)maybe_utf8;
    const uint8_t *const end = string + size;
    while (string < end) {
        int count = UTF8_COUNT[*string];
        bool valid = false;
        if (count == 1) {
            if (string[0] <= 0x7F) {
                valid = true;
            }
        }
        else if (count == 2) {
            if (string[0] >= 0xC2 && string[0] <= 0xDF) {
                if (TRAIL_OK(string[1])) {
                    valid = true;
                }
            }
        }
        else if (count == 3) {
            if (string[0] == 0xE0) {
                if (string[1] >= 0xA0 && string[1] <= 0xBF
                    && TRAIL_OK(string[2])
                   ) {
                    valid = true;
                }
            }
            else if (string[0] >= 0xE1 && string[0] <= 0xEC) {
                if (TRAIL_OK(string[1])
                    && TRAIL_OK(string[2])
                   ) {
                    valid = true;
                }
            }
            else if (string[0] == 0xED) {
                if (string[1] >= 0x80 && string[1] <= 0x9F
                    && TRAIL_OK(string[2])
                   ) {
                    valid = true;
                }
            }
            else if (string[0] >= 0xEE && string[0] <= 0xEF) {
                if (TRAIL_OK(string[1])
                    && TRAIL_OK(string[2])
                   ) {
                    valid = true;
                }
            }
        }
        else if (count == 4) {
            if (string[0] == 0xF0) {
                if (string[1] >= 0x90 && string[1] <= 0xBF
                    && TRAIL_OK(string[2])
                    && TRAIL_OK(string[3])
                   ) {
                    valid = true;
                }
            }
            else if (string[0] >= 0xF1 && string[0] <= 0xF3) {
                if (TRAIL_OK(string[1])
                    && TRAIL_OK(string[2])
                    && TRAIL_OK(string[3])
                   ) {
                    valid = true;
                }
            }
            else if (string[0] == 0xF4) {
                if (string[1] >= 0x80 && string[1] <= 0x8F
                    && TRAIL_OK(string[2])
                    && TRAIL_OK(string[3])
                   ) {
                    valid = true;
                }
            }
        }

        if (!valid) {
            return false;
        }
        string += count;
    }

    if (string != end) {
        return false;
    }

    return true;
}

static void
test_all_code_points(TestBatchRunner *runner) {
    int32_t code_point;
    for (code_point = 0; code_point <= 0x10FFFF; code_point++) {
        char buffer[4];
        uint32_t size = Str_encode_utf8_char(code_point, buffer);
        char *start = buffer;

        // Verify length returned by encode_utf8_char().
        if (size != UTF8_COUNT[(unsigned char)buffer[0]]) {
            break;
        }
        // Verify that utf8_valid() agrees with alternate implementation.
        if (!!Str_utf8_valid(start, size)
            != !!S_utf8_valid_alt(start, size)
           ) {
            break;
        }
    }
    if (code_point == 0x110000) {
        PASS(runner, "Successfully round tripped 0 - 0x10FFFF");
    }
    else {
        FAIL(runner, "Failed round trip at 0x%.1X", (unsigned)code_point);
    }
}

static void
S_test_validity(TestBatchRunner *runner, const char *content, size_t size,
                bool expected, const char *description) {
    bool sane = Str_utf8_valid(content, size);
    bool double_check = S_utf8_valid_alt(content, size);
    if (sane != double_check) {
        FAIL(runner, "Disagreement: %s", description);
    }
    else {
        TEST_TRUE(runner, sane == expected, "%s", description);
    }
}

static void
test_utf8_valid(TestBatchRunner *runner) {
    // Musical symbol G clef:
    // Code point: U+1D11E
    // UTF-16:     0xD834 0xDD1E
    // UTF-8       0xF0 0x9D 0x84 0x9E
    S_test_validity(runner, "\xF0\x9D\x84\x9E", 4, true,
                    "Musical symbol G clef");
    S_test_validity(runner, "\xED\xA0\xB4\xED\xB4\x9E", 6, false,
                    "G clef as UTF-8 encoded UTF-16 surrogates");
    S_test_validity(runner, ".\xED\xA0\xB4.", 5, false,
                    "Isolated high surrogate");
    S_test_validity(runner, ".\xED\xB4\x9E.", 5, false,
                    "Isolated low surrogate");

    // Shortest form.
    S_test_validity(runner, ".\xC1\x9C.", 4, false,
                    "Non-shortest form ASCII backslash");
    S_test_validity(runner, ".\xC0\xAF.", 4, false,
                    "Non-shortest form ASCII slash");
    S_test_validity(runner, ".\xC0\x80.", 4, false,
                    "Non-shortest form ASCII NUL character");
    S_test_validity(runner, ".\xE0\x9F\xBF.", 5, false,
                    "Non-shortest form three byte sequence");
    S_test_validity(runner, ".\xF0\x8F\xBF\xBF.", 6, false,
                    "Non-shortest form four byte sequence");

    // Range.
    S_test_validity(runner, "\xF8\x88\x80\x80\x80", 5, false, "5-byte UTF-8");
    S_test_validity(runner, "\xF4\x8F\xBF\xBF", 4, true,
                    "Code point 0x10FFFF");
    S_test_validity(runner, "\xF4\x90\x80\x80", 4, false,
                    "Code point 0x110000 too large");
    S_test_validity(runner, "\xF5\x80\x80\x80", 4, false,
                    "Sequence starting with 0xF5");

    // Truncated sequences.
    S_test_validity(runner, "\xC2", 1, false,
                    "Truncated two byte sequence");
    S_test_validity(runner, "\xE2\x98", 2, false,
                    "Truncated three byte sequence");
    S_test_validity(runner, "\xF0\x9D\x84", 3, false,
                    "Truncated four byte sequence");

    // Bad continuations.
    S_test_validity(runner, "\xE2\x98\xBA\xE2\x98\xBA", 6, true,
                    "SmileySmiley");
    S_test_validity(runner, "\xE2\xBA\xE2\x98\xBA", 5, false,
                    "missing first continuation byte");
    S_test_validity(runner, "\xE2\x98\xE2\x98\xBA", 5, false,
                    "missing second continuation byte");
    S_test_validity(runner, "\xE2\xE2\x98\xBA", 4, false,
                    "missing both continuation bytes");
    S_test_validity(runner, "\xBA\xE2\x98\xBA\xE2\xBA", 5, false,
                    "missing first continuation byte (end)");
    S_test_validity(runner, "\xE2\x98\xBA\xE2\x98", 5, false,
                    "missing second continuation byte (end)");
    S_test_validity(runner, "\xE2\x98\xBA\xE2", 4, false,
                    "missing both continuation bytes (end)");
    S_test_validity(runner, "\xBA\xE2\x98\xBA", 4, false,
                    "isolated continuation byte 0xBA");
    S_test_validity(runner, "\x98\xE2\x98\xBA", 4, false,
                    "isolated continuation byte 0x98");
    S_test_validity(runner, "\xE2\x98\xBA\xBA", 4, false,
                    "isolated continuation byte 0xBA (end)");
    S_test_validity(runner, "\xE2\x98\xBA\x98", 4, false,
                    "isolated continuation byte 0x98 (end)");
    S_test_validity(runner, "\xF0xxxx", 5, false,
                    "missing continuation byte 2/4");
    S_test_validity(runner, "\xF0\x9Dxxxx", 5, false,
                    "missing continuation byte 3/4");
    S_test_validity(runner, "\xF0\x9D\x84xx", 5, false,
                    "missing continuation byte 4/4");
}

static void
S_validate_utf8(void *context) {
    const char *text = (const char*)context;
    Str_validate_utf8(text, strlen(text), "src.c", 17, "fn");
}

static void
test_validate_utf8(TestBatchRunner *runner) {
    {
        Err *error = Err_trap(S_validate_utf8, "Sigma\xC1\x9C.");
        TEST_TRUE(runner, error != NULL, "validate_utf8 throws");
        String *mess = Err_Get_Mess(error);
        const char *expected = "Invalid UTF-8 after 'Sigma': C1 9C 2E\n";
        bool ok = Str_Starts_With_Utf8(mess, expected, strlen(expected));
        TEST_TRUE(runner, ok, "validate_utf8 throws correct error message");
        DECREF(error);
    }

    {
        Err *error = Err_trap(S_validate_utf8,
                              "xxx123456789\xE2\x93\xAA"
                              "1234567890\xC1\x9C.");
        String *mess = Err_Get_Mess(error);
        const char *expected =
            "Invalid UTF-8 after '123456789\xE2\x93\xAA"
            "1234567890': C1 9C 2E\n";
        bool ok = Str_Starts_With_Utf8(mess, expected, strlen(expected));
        TEST_TRUE(runner, ok, "validate_utf8 truncates long prefix");
        DECREF(error);
    }
}

static void
test_is_whitespace(TestBatchRunner *runner) {
    TEST_TRUE(runner, Str_is_whitespace(' '), "space is whitespace");
    TEST_TRUE(runner, Str_is_whitespace('\n'), "newline is whitespace");
    TEST_TRUE(runner, Str_is_whitespace('\t'), "tab is whitespace");
    TEST_TRUE(runner, Str_is_whitespace('\v'),
              "vertical tab is whitespace");
    TEST_FALSE(runner, Str_is_whitespace('a'), "'a' isn't whitespace");
    TEST_FALSE(runner, Str_is_whitespace(0), "NULL isn't whitespace");
    TEST_FALSE(runner, Str_is_whitespace(0x263A),
               "Smiley isn't whitespace");
}

static void
S_encode_utf8_char(void *context) {
    int32_t *code_point_ptr = (int32_t*)context;
    char buffer[4];
    Str_encode_utf8_char(*code_point_ptr, buffer);
}

static void
test_encode_utf8_char(TestBatchRunner *runner) {
    int32_t code_point = 0x110000;
    Err *error = Err_trap(S_encode_utf8_char, &code_point);
    TEST_TRUE(runner, error != NULL, "Encode code point 0x110000 throws");
    DECREF(error);
}

static void
test_new(TestBatchRunner *runner) {
    static char chars[] = "A string " SMILEY " with a smile.";

    {
        char *buffer = (char*)MALLOCATE(sizeof(chars));
        strcpy(buffer, chars);
        String *thief = Str_new_steal_utf8(buffer, sizeof(chars) - 1);
        TEST_TRUE(runner, Str_Equals_Utf8(thief, chars, sizeof(chars) - 1),
                  "Str_new_steal_utf8");
        DECREF(thief);
    }

    {
        char *buffer = (char*)MALLOCATE(sizeof(chars));
        strcpy(buffer, chars);
        String *thief
            = Str_new_steal_trusted_utf8(buffer, sizeof(chars) - 1);
        TEST_TRUE(runner, Str_Equals_Utf8(thief, chars, sizeof(chars) - 1),
                  "Str_new_steal_trusted_utf8");
        DECREF(thief);
    }

    {
        String *wrapper = Str_new_wrap_utf8(chars, sizeof(chars) - 1);
        TEST_TRUE(runner, Str_Equals_Utf8(wrapper, chars, sizeof(chars) - 1),
                  "Str_new_wrap_utf8");
        DECREF(wrapper);
    }

    {
        String *wrapper = Str_new_wrap_trusted_utf8(chars, sizeof(chars) - 1);
        TEST_TRUE(runner, Str_Equals_Utf8(wrapper, chars, sizeof(chars) - 1),
                  "Str_new_wrap_trusted_utf8");
        DECREF(wrapper);
    }

    {
        String *smiley_str = Str_new_from_char(smiley_cp);
        TEST_TRUE(runner, Str_Equals_Utf8(smiley_str, smiley, smiley_len),
                  "Str_new_from_char");
        DECREF(smiley_str);
    }
}

static void
test_Cat(TestBatchRunner *runner) {
    String *wanted = Str_newf("a%s", smiley);
    String *source;
    String *got;

    source = S_get_str("");
    got = Str_Cat(source, wanted);
    TEST_TRUE(runner, Str_Equals(wanted, (Obj*)got), "Cat");
    DECREF(got);
    DECREF(source);

    source = S_get_str("a");
    got = Str_Cat_Utf8(source, smiley, smiley_len);
    TEST_TRUE(runner, Str_Equals(wanted, (Obj*)got), "Cat_Utf8");
    DECREF(got);
    DECREF(source);

    source = S_get_str("a");
    got = Str_Cat_Trusted_Utf8(source, smiley, smiley_len);
    TEST_TRUE(runner, Str_Equals(wanted, (Obj*)got), "Cat_Trusted_Utf8");
    DECREF(got);
    DECREF(source);

    DECREF(wanted);
}

static void
test_Clone(TestBatchRunner *runner) {
    String *wanted = S_get_str("foo");
    String *got    = Str_Clone(wanted);
    TEST_TRUE(runner, Str_Equals(wanted, (Obj*)got), "Clone");
    DECREF(got);
    DECREF(wanted);
}

static int64_t
S_find(String *string, String *substring) {
    StringIterator *iter = Str_Find(string, substring);
    if (iter == NULL) { return -1; }
    size_t tick = StrIter_Recede(iter, SIZE_MAX);
    DECREF(iter);
    return (int64_t)tick;
}

static void
test_Contains_and_Find(TestBatchRunner *runner) {
    String *string;
    String *substring = S_get_str("foo");
    String *empty     = S_get_str("");

    TEST_FALSE(runner, Str_Contains(empty, substring),
               "Not contained in empty string");
    TEST_INT_EQ(runner, S_find(empty, substring), -1,
                "Not found in empty string");

    string = S_get_str("foo");
    TEST_TRUE(runner, Str_Contains(string, substring),
              "Contains complete string");
    TEST_INT_EQ(runner, S_find(string, substring), 0, "Find complete string");
    TEST_TRUE(runner, Str_Contains(string, empty),
              "Contains empty string");
    TEST_INT_EQ(runner, S_find(string, empty), 0, "Find empty string");
    DECREF(string);

    string = S_get_str("afoo");
    TEST_TRUE(runner, Str_Contains(string, substring),
              "Contained after first");
    TEST_INT_EQ(runner, S_find(string, substring), 1, "Find after first");
    String *prefix = Str_SubString(string, 0, 3);
    TEST_FALSE(runner, Str_Contains(prefix, substring), "Don't overrun");
    DECREF(prefix);
    DECREF(string);

    string = S_get_str("afood");
    TEST_TRUE(runner, Str_Contains(string, substring), "Contained in middle");
    TEST_INT_EQ(runner, S_find(string, substring), 1, "Find in middle");
    DECREF(string);

    DECREF(empty);
    DECREF(substring);
}

static void
test_Code_Point_At_and_From(TestBatchRunner *runner) {
    int32_t code_points[] = {
        'a', smiley_cp, smiley_cp, 'b', smiley_cp, 'c'
    };
    uint32_t num_code_points = sizeof(code_points) / sizeof(int32_t);
    String *string = Str_newf("a%s%sb%sc", smiley, smiley, smiley);
    uint32_t i;

    for (i = 0; i < num_code_points; i++) {
        uint32_t from = num_code_points - i;
        TEST_INT_EQ(runner, Str_Code_Point_At(string, i), code_points[i],
                    "Code_Point_At %ld", (long)i);
        TEST_INT_EQ(runner, Str_Code_Point_From(string, from),
                    code_points[i], "Code_Point_From %ld", (long)from);
    }

    TEST_INT_EQ(runner, Str_Code_Point_At(string, num_code_points), STR_OOB,
                "Code_Point_At %ld", (long)num_code_points);
    TEST_INT_EQ(runner, Str_Code_Point_From(string, 0), STR_OOB,
                "Code_Point_From 0");
    TEST_INT_EQ(runner, Str_Code_Point_From(string, num_code_points + 1),
                STR_OOB, "Code_Point_From %ld", (long)(num_code_points + 1));

    DECREF(string);
}

static void
test_SubString(TestBatchRunner *runner) {
    {
        String *string = Str_newf("a%s%sb%sc", smiley, smiley, smiley);
        String *wanted = Str_newf("%sb%s", smiley, smiley);
        String *got = Str_SubString(string, 2, 3);
        TEST_TRUE(runner, Str_Equals(wanted, (Obj*)got), "SubString");
        DECREF(string);
        DECREF(wanted);
        DECREF(got);
    }

    {
        static const char chars[] = "A string.";
        String *wrapper = Str_new_wrap_utf8(chars, sizeof(chars) - 1);
        String *wanted  = Str_newf("string");
        String *got     = Str_SubString(wrapper, 2, 6);
        TEST_TRUE(runner, Str_Equals(got, (Obj*)wanted),
                  "SubString with wrapped buffer");
        DECREF(wrapper);
        DECREF(wanted);
        DECREF(got);
    }
}

static void
test_Trim(TestBatchRunner *runner) {
    String *ws_smiley = S_smiley_with_whitespace(NULL);
    String *ws_foo    = S_get_str("  foo  ");
    String *ws_only   = S_get_str("  \t  \r\n");
    String *trimmed   = S_get_str("a     b");
    String *got;

    got = Str_Trim(ws_smiley);
    TEST_TRUE(runner, Str_Equals_Utf8(got, smiley, smiley_len), "Trim");
    DECREF(got);

    got = Str_Trim_Top(ws_foo);
    TEST_TRUE(runner, Str_Equals_Utf8(got, "foo  ", 5), "Trim_Top");
    DECREF(got);

    got = Str_Trim_Tail(ws_foo);
    TEST_TRUE(runner, Str_Equals_Utf8(got, "  foo", 5), "Trim_Tail");
    DECREF(got);

    got = Str_Trim(ws_only);
    TEST_TRUE(runner, Str_Equals_Utf8(got, "", 0), "Trim with only whitespace");
    DECREF(got);

    got = Str_Trim_Top(ws_only);
    TEST_TRUE(runner, Str_Equals_Utf8(got, "", 0),
              "Trim_Top with only whitespace");
    DECREF(got);

    got = Str_Trim_Tail(ws_only);
    TEST_TRUE(runner, Str_Equals_Utf8(got, "", 0),
              "Trim_Tail with only whitespace");
    DECREF(got);

    got = Str_Trim(trimmed);
    TEST_TRUE(runner, Str_Equals(got, (Obj*)trimmed),
              "Trim doesn't change trimmed string");
    DECREF(got);

    got = Str_Trim_Top(trimmed);
    TEST_TRUE(runner, Str_Equals(got, (Obj*)trimmed),
              "Trim_Top doesn't change trimmed string");
    DECREF(got);

    got = Str_Trim_Tail(trimmed);
    TEST_TRUE(runner, Str_Equals(got, (Obj*)trimmed),
              "Trim_Tail doesn't change trimmed string");
    DECREF(got);

    DECREF(trimmed);
    DECREF(ws_only);
    DECREF(ws_foo);
    DECREF(ws_smiley);
}

static void
test_To_F64(TestBatchRunner *runner) {
    String *string;

    string = S_get_str("1.5");
    double difference = 1.5 - Str_To_F64(string);
    if (difference < 0) { difference = 0 - difference; }
    TEST_TRUE(runner, difference < 0.001, "To_F64");
    DECREF(string);

    string = S_get_str("-1.5");
    difference = 1.5 + Str_To_F64(string);
    if (difference < 0) { difference = 0 - difference; }
    TEST_TRUE(runner, difference < 0.001, "To_F64 negative");
    DECREF(string);

    // TODO: Enable this test when we have real substrings.
    /*string = S_get_str("1.59");
    double value_full = Str_To_F64(string);
    Str_Set_Size(string, 3);
    double value_short = Str_To_F64(string);
    TEST_TRUE(runner, value_short < value_full,
              "TO_F64 doesn't run past end of string");
    DECREF(string);*/
}

static void
test_To_I64(TestBatchRunner *runner) {
    String *string;

    string = S_get_str("10");
    TEST_INT_EQ(runner, Str_To_I64(string), 10, "To_I64");
    DECREF(string);

    string = S_get_str("-10");
    TEST_INT_EQ(runner, Str_To_I64(string), -10, "To_I64 negative");
    DECREF(string);

    string = S_get_str("10.");
    TEST_INT_EQ(runner, Str_To_I64(string), 10, "To_I64 stops at non-digits");
    DECREF(string);

    string = S_get_str("10" SMILEY);
    TEST_INT_EQ(runner, Str_To_I64(string), 10, "To_I64 stops at non-ASCII");
    DECREF(string);

    string = S_get_str("10A");
    TEST_INT_EQ(runner, Str_To_I64(string), 10,
              "To_I64 stops at out-of-range digits");
    DECREF(string);
}

static void
test_BaseX_To_I64(TestBatchRunner *runner) {
    String *string;

    string = S_get_str("-JJ");
    TEST_INT_EQ(runner, Str_BaseX_To_I64(string, 20), -399,
              "BaseX_To_I64 base 20");
    DECREF(string);
}

static void
test_To_String(TestBatchRunner *runner) {
    String *string = Str_newf("Test");
    String *copy   = Str_To_String(string);
    TEST_TRUE(runner, Str_Equals(copy, (Obj*)string), "To_String");
    DECREF(string);
    DECREF(copy);
}

static void
test_To_Utf8(TestBatchRunner *runner) {
    String *string = Str_newf("a%s%sb%sc", smiley, smiley, smiley);
    char *buf = Str_To_Utf8(string);
    TEST_TRUE(runner, strcmp(buf, "a" SMILEY SMILEY "b" SMILEY "c") == 0,
              "To_Utf8");
    FREEMEM(buf);
    DECREF(string);
}

static void
test_To_ByteBuf(TestBatchRunner *runner) {
    String     *string = Str_newf("foo");
    ByteBuf    *bb     = Str_To_ByteBuf(string);
    TEST_TRUE(runner, BB_Equals_Bytes(bb, "foo", 3), "To_ByteBuf");
    DECREF(bb);
    DECREF(string);
}

static void
test_Length(TestBatchRunner *runner) {
    String *string = Str_newf("a%s%sb%sc", smiley, smiley, smiley);
    TEST_UINT_EQ(runner, Str_Length(string), 6, "Length");
    DECREF(string);
}

static void
test_Compare_To(TestBatchRunner *runner) {
    String *abc = Str_newf("a%s%sb%sc", smiley, smiley, smiley);
    String *ab  = Str_newf("a%s%sb", smiley, smiley);
    String *ac  = Str_newf("a%s%sc", smiley, smiley);

    TEST_TRUE(runner, Str_Compare_To(abc, (Obj*)abc) == 0,
              "Compare_To abc abc");
    TEST_TRUE(runner, Str_Compare_To(ab, (Obj*)abc) < 0,
              "Compare_To ab abc");
    TEST_TRUE(runner, Str_Compare_To(abc, (Obj*)ab) > 0,
              "Compare_To abc ab");
    TEST_TRUE(runner, Str_Compare_To(ab, (Obj*)ac) < 0,
              "Compare_To ab ac");
    TEST_TRUE(runner, Str_Compare_To(ac, (Obj*)ab) > 0,
              "Compare_To ac ab");

    DECREF(ac);
    DECREF(ab);
    DECREF(abc);
}

static void
test_Starts_Ends_With(TestBatchRunner *runner) {
    String *prefix = S_get_str("pre" SMILEY "fix_");
    String *suffix = S_get_str("_post" SMILEY "fix");
    String *empty  = S_get_str("");

    TEST_TRUE(runner, Str_Starts_With(suffix, suffix),
              "Starts_With self returns true");
    TEST_TRUE(runner, Str_Ends_With(prefix, prefix),
              "Ends_With self returns true");

    TEST_TRUE(runner, Str_Starts_With(suffix, empty),
              "Starts_With empty string returns true");
    TEST_TRUE(runner, Str_Ends_With(prefix, empty),
              "Ends_With empty string returns true");
    TEST_FALSE(runner, Str_Starts_With(empty, suffix),
              "Empty string Starts_With returns false");
    TEST_FALSE(runner, Str_Ends_With(empty, prefix),
              "Empty string Ends_With returns false");

    {
        String *string
            = S_get_str("pre" SMILEY "fix_string_post" SMILEY "fix");
        TEST_TRUE(runner, Str_Starts_With(string, prefix),
                  "Starts_With returns true");
        TEST_TRUE(runner, Str_Ends_With(string, suffix),
                  "Ends_With returns true");
        DECREF(string);
    }

    {
        String *string
            = S_get_str("pre" SMILEY "fix:string:post" SMILEY "fix");
        TEST_FALSE(runner, Str_Starts_With(string, prefix),
                   "Starts_With returns false");
        TEST_FALSE(runner, Str_Ends_With(string, suffix),
                   "Ends_With returns false");
        DECREF(string);
    }

    DECREF(prefix);
    DECREF(suffix);
    DECREF(empty);
}

static void
test_Starts_Ends_With_Utf8(TestBatchRunner *runner) {
    String *str = S_get_str("pre" SMILEY "post");

    static const char prefix[] = "pre" SMILEY;
    static const char postfix[] = SMILEY "post";
    static const size_t prefix_size = sizeof(prefix) - 1;
    static const size_t postfix_size = sizeof(postfix) - 1;
    TEST_TRUE(runner, Str_Starts_With_Utf8(str, prefix, prefix_size),
              "Starts_With_Utf8 returns true");
    TEST_TRUE(runner, Str_Ends_With_Utf8(str, postfix, postfix_size),
              "Ends_With_Utf8 returns true");
    TEST_FALSE(runner, Str_Starts_With_Utf8(str, postfix, postfix_size),
              "Starts_With_Utf8 returns false");
    TEST_FALSE(runner, Str_Ends_With_Utf8(str, prefix, prefix_size),
              "Ends_With_Utf8 returns false");

    static const char longer[] = "12345678901234567890";
    static const size_t longer_size = sizeof(longer) - 1;
    TEST_FALSE(runner, Str_Starts_With_Utf8(str, longer, longer_size),
              "Starts_With_Utf8 longer str returns false");
    TEST_FALSE(runner, Str_Ends_With_Utf8(str, longer, longer_size),
               "Ends_With_Utf8 longer str returns false");

    DECREF(str);
}

static void
test_Get_Ptr8(TestBatchRunner *runner) {
    String *string = S_get_str("Banana");

    const char *ptr8 = Str_Get_Ptr8(string);
    TEST_TRUE(runner, strcmp(ptr8, "Banana") == 0, "Get_Ptr8");

    size_t size = Str_Get_Size(string);
    TEST_UINT_EQ(runner, size, 6, "Get_Size");

    DECREF(string);
}

static void
test_iterator(TestBatchRunner *runner) {
    static const int32_t code_points[] = {
        0x41,
        0x7F,
        0x80,
        0x7FF,
        0x800,
        0xFFFF,
        0x10000,
        0x10FFFF
    };
    static size_t num_code_points
        = sizeof(code_points) / sizeof(code_points[0]);

    CharBuf *buf = CB_new(0);
    for (size_t i = 0; i < num_code_points; ++i) {
        CB_Cat_Char(buf, code_points[i]);
    }
    String *string = CB_To_String(buf);

    {
        StringIterator *iter = Str_Top(string);

        TEST_TRUE(runner, StrIter_Equals(iter, (Obj*)iter),
                  "StringIterator equal to self");
        TEST_FALSE(runner, StrIter_Equals(iter, (Obj*)CFISH_TRUE),
                   "StringIterator not equal non-iterators");

        DECREF(iter);
    }

    {
        StringIterator *top  = Str_Top(string);
        StringIterator *tail = Str_Tail(string);

        TEST_FALSE(runner, StrIter_Equals(top, (Obj*)tail),
                   "StrIter_Equals returns false");

        TEST_INT_EQ(runner, StrIter_Compare_To(top, (Obj*)tail), -1,
                    "Compare_To top < tail");
        TEST_INT_EQ(runner, StrIter_Compare_To(tail, (Obj*)top), 1,
                    "Compare_To tail > top");
        TEST_INT_EQ(runner, StrIter_Compare_To(top, (Obj*)top), 0,
                    "Compare_To top == top");

        StringIterator *clone = StrIter_Clone(top);
        TEST_TRUE(runner, StrIter_Equals(clone, (Obj*)top), "Clone");

        StrIter_Assign(clone, tail);
        TEST_TRUE(runner, StrIter_Equals(clone, (Obj*)tail), "Assign");

        String *other = Str_newf("Other string");
        StringIterator *other_iter = Str_Top(other);
        TEST_FALSE(runner, StrIter_Equals(other_iter, (Obj*)tail),
                   "Equals returns false for different strings");
        StrIter_Assign(clone, other_iter);
        TEST_TRUE(runner, StrIter_Equals(clone, (Obj*)other_iter),
                  "Assign iterator with different string");

        DECREF(other);
        DECREF(other_iter);
        DECREF(clone);
        DECREF(top);
        DECREF(tail);
    }

    {
        StringIterator *iter = Str_Top(string);

        for (size_t i = 0; i < num_code_points; ++i) {
            TEST_TRUE(runner, StrIter_Has_Next(iter), "Has_Next %d", i);
            int32_t code_point = StrIter_Next(iter);
            TEST_INT_EQ(runner, code_point, code_points[i], "Next %d", i);
        }

        TEST_TRUE(runner, !StrIter_Has_Next(iter),
                  "Has_Next at end of string");
        TEST_INT_EQ(runner, StrIter_Next(iter), STR_OOB,
                    "Next at end of string");

        StringIterator *tail = Str_Tail(string);
        TEST_TRUE(runner, StrIter_Equals(iter, (Obj*)tail), "Equals tail");

        DECREF(tail);
        DECREF(iter);
    }

    {
        StringIterator *iter = Str_Tail(string);

        for (size_t i = num_code_points; i--;) {
            TEST_TRUE(runner, StrIter_Has_Prev(iter), "Has_Prev %d", i);
            int32_t code_point = StrIter_Prev(iter);
            TEST_INT_EQ(runner, code_point, code_points[i], "Prev %d", i);
        }

        TEST_TRUE(runner, !StrIter_Has_Prev(iter),
                  "Has_Prev at end of string");
        TEST_INT_EQ(runner, StrIter_Prev(iter), STR_OOB,
                    "Prev at start of string");

        StringIterator *top = Str_Top(string);
        TEST_TRUE(runner, StrIter_Equals(iter, (Obj*)top), "Equals top");

        DECREF(top);
        DECREF(iter);
    }

    {
        StringIterator *iter = Str_Top(string);

        StrIter_Next(iter);
        TEST_UINT_EQ(runner, StrIter_Advance(iter, 2), 2,
                     "Advance returns number of code points");
        TEST_INT_EQ(runner, StrIter_Next(iter), code_points[3],
                    "Advance works");
        TEST_UINT_EQ(runner,
                     StrIter_Advance(iter, 1000000), num_code_points - 4,
                     "Advance past end of string");

        StrIter_Prev(iter);
        TEST_UINT_EQ(runner, StrIter_Recede(iter, 2), 2,
                     "Recede returns number of code points");
        TEST_INT_EQ(runner, StrIter_Prev(iter), code_points[num_code_points-4],
                    "Recede works");
        TEST_UINT_EQ(runner, StrIter_Recede(iter, 1000000), num_code_points - 4,
                     "Recede past start of string");

        DECREF(iter);
    }

    DECREF(string);
    DECREF(buf);
}

static void
test_iterator_whitespace(TestBatchRunner *runner) {
    size_t num_spaces;
    String *ws_smiley = S_smiley_with_whitespace(&num_spaces);

    {
        StringIterator *iter = Str_Top(ws_smiley);
        TEST_UINT_EQ(runner, StrIter_Skip_Whitespace(iter), num_spaces,
                     "Skip_Whitespace");
        TEST_UINT_EQ(runner, StrIter_Skip_Whitespace(iter), 0,
                     "Skip_Whitespace without whitespace");
        DECREF(iter);
    }

    {
        StringIterator *iter = Str_Tail(ws_smiley);
        TEST_UINT_EQ(runner, StrIter_Skip_Whitespace_Back(iter), num_spaces,
                     "Skip_Whitespace_Back");
        TEST_UINT_EQ(runner, StrIter_Skip_Whitespace_Back(iter), 0,
                     "Skip_Whitespace_Back without whitespace");
        DECREF(iter);
    }

    DECREF(ws_smiley);
}

typedef struct {
    StringIterator *top;
    StringIterator *tail;
} StrIterCropContext;

static void
S_striter_crop(void *vcontext) {
    StrIterCropContext *context = (StrIterCropContext*)vcontext;
    StrIter_crop(context->top, context->tail);
}

static void
test_iterator_substring(TestBatchRunner *runner) {
    String *string = Str_newf("a%sb%sc%sd", smiley, smiley, smiley);

    StringIterator *start = Str_Top(string);
    StringIterator *end = Str_Tail(string);

    {
        String *substring = StrIter_crop(start, end);
        TEST_TRUE(runner, Str_Equals(substring, (Obj*)string),
                  "StrIter_crop whole string");
        DECREF(substring);
    }

    StrIter_Advance(start, 2);
    StrIter_Recede(end, 2);

    {
        String *substring = StrIter_crop(start, end);
        static const char wanted_buf[] = "b" SMILEY "c";
        static const size_t wanted_size = sizeof(wanted_buf) - 1;
        String *wanted = Str_new_from_utf8(wanted_buf, wanted_size);
        TEST_TRUE(runner, Str_Equals(substring, (Obj*)wanted),
                  "StrIter_crop");

        TEST_TRUE(runner, StrIter_Starts_With(start, wanted),
                  "Starts_With returns true");
        TEST_TRUE(runner, StrIter_Ends_With(end, wanted),
                  "Ends_With returns true");
        TEST_TRUE(runner,
                  StrIter_Starts_With_Utf8(start, wanted_buf, wanted_size),
                  "Starts_With_Utf8 returns true");
        TEST_TRUE(runner,
                  StrIter_Ends_With_Utf8(end, wanted_buf, wanted_size),
                  "Ends_With_Utf8 returns true");

        DECREF(wanted);
        DECREF(substring);
    }

    {
        static const char short_buf[] = "b" SMILEY "x";
        static const size_t short_size = sizeof(short_buf) - 1;
        String *short_str = Str_new_from_utf8(short_buf, short_size);
        TEST_FALSE(runner, StrIter_Starts_With(start, short_str),
                   "Starts_With returns false");
        TEST_FALSE(runner, StrIter_Ends_With(start, short_str),
                   "Ends_With returns false");
        TEST_FALSE(runner,
                   StrIter_Starts_With_Utf8(start, short_buf, short_size),
                   "Starts_With_Utf8 returns false");
        TEST_FALSE(runner,
                   StrIter_Ends_With_Utf8(start, short_buf, short_size),
                   "Ends_With_Utf8 returns false");

        static const char long_buf[] = "b" SMILEY "xxxxxxxxxxxx" SMILEY "c";
        static const size_t long_size = sizeof(long_buf) - 1;
        String *long_str = Str_new_from_utf8(long_buf, long_size);
        TEST_FALSE(runner, StrIter_Starts_With(start, long_str),
                   "Starts_With long string returns false");
        TEST_FALSE(runner, StrIter_Ends_With(end, long_str),
                   "Ends_With long string returns false");
        TEST_FALSE(runner,
                   StrIter_Starts_With_Utf8(start, long_buf, long_size),
                   "Starts_With_Utf8 long string returns false");
        TEST_FALSE(runner,
                   StrIter_Ends_With_Utf8(end, long_buf, long_size),
                   "Ends_With_Utf8 long string returns false");

        DECREF(short_str);
        DECREF(long_str);
    }

    {
        String *substring = StrIter_crop(end, NULL);
        String *wanted = Str_newf("%sd", smiley);
        TEST_TRUE(runner, Str_Equals(substring, (Obj*)wanted),
                  "StrIter_crop with NULL tail");
        DECREF(wanted);
        DECREF(substring);
    }

    {
        String *substring = StrIter_crop(NULL, start);
        String *wanted = Str_newf("a%s", smiley);
        TEST_TRUE(runner, Str_Equals(substring, (Obj*)wanted),
                  "StrIter_crop with NULL top");
        DECREF(wanted);
        DECREF(substring);
    }

    {
        StrIterCropContext context;
        context.top  = NULL;
        context.tail = NULL;
        Err *error = Err_trap(S_striter_crop, &context);
        TEST_TRUE(runner, error != NULL,
                  "StrIter_crop throws if top and tail are NULL");
        DECREF(error);
    }

    {
        String *other = SSTR_WRAP_C("other");
        StrIterCropContext context;
        context.top  = start;
        context.tail = Str_Tail(other);
        Err *error = Err_trap(S_striter_crop, &context);
        TEST_TRUE(runner, error != NULL,
                  "StrIter_crop throws if string don't match");
        DECREF(error);
        DECREF(context.tail);
    }

    {
        StrIterCropContext context;
        context.top  = end;
        context.tail = start;
        Err *error = Err_trap(S_striter_crop, &context);
        TEST_TRUE(runner, error != NULL,
                  "StrIter_crop throws if top is behind tail");
        DECREF(error);
    }

    DECREF(start);
    DECREF(end);
    DECREF(string);
}

void
TestStr_Run_IMP(TestString *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 200);
    test_all_code_points(runner);
    test_utf8_valid(runner);
    test_validate_utf8(runner);
    test_is_whitespace(runner);
    test_encode_utf8_char(runner);
    test_new(runner);
    test_Cat(runner);
    test_Clone(runner);
    test_Code_Point_At_and_From(runner);
    test_Contains_and_Find(runner);
    test_SubString(runner);
    test_Trim(runner);
    test_To_F64(runner);
    test_To_I64(runner);
    test_BaseX_To_I64(runner);
    test_To_String(runner);
    test_To_Utf8(runner);
    test_To_ByteBuf(runner);
    test_Length(runner);
    test_Compare_To(runner);
    test_Starts_Ends_With(runner);
    test_Starts_Ends_With_Utf8(runner);
    test_Get_Ptr8(runner);
    test_iterator(runner);
    test_iterator_whitespace(runner);
    test_iterator_substring(runner);
}

/*************************** StringCallbackTest ***************************/

bool
StrCbTest_Unchanged_By_Callback_IMP(StringCallbackTest *self, String *str) {
    String *before = Str_Clone(str);
    StrCbTest_Callback(self);
    return Str_Equals(str, (Obj*)before);
}

