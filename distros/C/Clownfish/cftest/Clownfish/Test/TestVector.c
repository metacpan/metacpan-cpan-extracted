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
#include <stdlib.h>

#define C_CFISH_VECTOR
#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#define MAX_VECTOR_SIZE (SIZE_MAX / sizeof(Obj*))

#include "Clownfish/Test/TestVector.h"

#include "Clownfish/String.h"
#include "Clownfish/Boolean.h"
#include "Clownfish/Err.h"
#include "Clownfish/Num.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Vector.h"
#include "Clownfish/Class.h"

TestVector*
TestVector_new() {
    return (TestVector*)Class_Make_Obj(TESTVECTOR);
}

// Return an array of size 10 with 30 garbage pointers behind.
static Vector*
S_array_with_garbage() {
    Vector *array = Vec_new(100);

    for (int i = 0; i < 40; i++) {
        Vec_Push(array, (Obj*)CFISH_TRUE);
    }

    // Remove elements using different methods.
    Vec_Excise(array, 10, 10);
    for (int i = 0; i < 10; i++) { Vec_Pop(array); }
    Vec_Resize(array, 10);

    return array;
}

static void
test_Equals(TestBatchRunner *runner) {
    Vector *array = Vec_new(0);
    Vector *other = Vec_new(0);
    String *stuff = SSTR_WRAP_C("stuff");

    TEST_TRUE(runner, Vec_Equals(array, (Obj*)array),
              "Array equal to self");

    TEST_FALSE(runner, Vec_Equals(array, (Obj*)CFISH_TRUE),
               "Array not equal to non-array");

    TEST_TRUE(runner, Vec_Equals(array, (Obj*)other),
              "Empty arrays are equal");

    Vec_Push(array, (Obj*)CFISH_TRUE);
    TEST_FALSE(runner, Vec_Equals(array, (Obj*)other),
               "Add one elem and Equals returns false");

    Vec_Push(other, (Obj*)CFISH_TRUE);
    TEST_TRUE(runner, Vec_Equals(array, (Obj*)other),
              "Add a matching elem and Equals returns true");

    Vec_Store(array, 2, (Obj*)CFISH_TRUE);
    TEST_FALSE(runner, Vec_Equals(array, (Obj*)other),
               "Add elem after a NULL and Equals returns false");

    Vec_Store(other, 2, (Obj*)CFISH_TRUE);
    TEST_TRUE(runner, Vec_Equals(array, (Obj*)other),
              "Empty elems don't spoil Equals");

    Vec_Store(other, 2, INCREF(stuff));
    TEST_FALSE(runner, Vec_Equals(array, (Obj*)other),
               "Non-matching value spoils Equals");

    Vec_Store(other, 2, NULL);
    TEST_FALSE(runner, Vec_Equals(array, (Obj*)other),
               "NULL value spoils Equals");
    TEST_FALSE(runner, Vec_Equals(other, (Obj*)array),
               "NULL value spoils Equals (reversed)");

    Vec_Excise(array, 1, 2);       // removes empty elems
    DECREF(Vec_Delete(other, 1));  // leaves NULL in place of deleted elem
    DECREF(Vec_Delete(other, 2));
    TEST_FALSE(runner, Vec_Equals(array, (Obj*)other),
               "Empty trailing elements spoil Equals");

    DECREF(array);
    DECREF(other);
}

static void
test_Store_Fetch(TestBatchRunner *runner) {
    Vector *array = Vec_new(0);
    String *elem;

    TEST_TRUE(runner, Vec_Fetch(array, 2) == NULL, "Fetch beyond end");

    Vec_Store(array, 2, (Obj*)Str_newf("foo"));
    elem = (String*)CERTIFY(Vec_Fetch(array, 2), STRING);
    TEST_UINT_EQ(runner, 3, Vec_Get_Size(array), "Store updates size");
    TEST_TRUE(runner, Str_Equals_Utf8(elem, "foo", 3), "Store");

    elem = (String*)INCREF(elem);
    TEST_INT_EQ(runner, 2, CFISH_REFCOUNT_NN(elem),
                "start with refcount of 2");
    Vec_Store(array, 2, (Obj*)Str_newf("bar"));
    TEST_INT_EQ(runner, 1, CFISH_REFCOUNT_NN(elem),
                "Displacing elem via Store updates refcount");
    DECREF(elem);
    elem = (String*)CERTIFY(Vec_Fetch(array, 2), STRING);
    TEST_TRUE(runner, Str_Equals_Utf8(elem, "bar", 3), "Store displacement");

    DECREF(array);

    array = S_array_with_garbage();
    Vec_Store(array, 40, (Obj*)CFISH_TRUE);
    bool all_null = true;
    for (size_t i = 10; i < 40; i++) {
        if (Vec_Fetch(array, i) != NULL) { all_null = false; }
    }
    TEST_TRUE(runner, all_null, "Out-of-bounds Store clears excised elements");
    DECREF(array);
}

static void
test_Push_Pop_Insert(TestBatchRunner *runner) {
    Vector *array = Vec_new(0);
    String *elem;

    TEST_UINT_EQ(runner, Vec_Get_Size(array), 0, "size starts at 0");
    TEST_TRUE(runner, Vec_Pop(array) == NULL,
              "Pop from empty array returns NULL");

    Vec_Push(array, (Obj*)Str_newf("a"));
    Vec_Push(array, (Obj*)Str_newf("b"));
    Vec_Push(array, (Obj*)Str_newf("c"));

    TEST_UINT_EQ(runner, Vec_Get_Size(array), 3, "size after Push");
    TEST_TRUE(runner, NULL != CERTIFY(Vec_Fetch(array, 2), STRING), "Push");

    elem = (String*)CERTIFY(Vec_Pop(array), STRING);
    TEST_TRUE(runner, Str_Equals_Utf8(elem, "c", 1), "Pop");
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 2, "size after Pop");
    DECREF(elem);

    Vec_Insert(array, 0, (Obj*)Str_newf("foo"));
    elem = (String*)CERTIFY(Vec_Fetch(array, 0), STRING);
    TEST_TRUE(runner, Str_Equals_Utf8(elem, "foo", 3), "Insert");
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 3, "size after Insert");

    for (int i = 0; i < 256; ++i) {
        Vec_Push(array, (Obj*)Str_newf("flotsam"));
    }
    for (size_t i = 0; i < 512; ++i) {
        Vec_Insert(array, i, (Obj*)Str_newf("jetsam"));
    }
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 3 + 256 + 512,
                 "size after exercising Push and Insert");

    DECREF(array);
}

static void
test_Insert_All(TestBatchRunner *runner) {
    int64_t i;

    {
        Vector *dst    = Vec_new(20);
        Vector *src    = Vec_new(10);
        Vector *wanted = Vec_new(30);

        for (i = 0; i < 10; i++) { Vec_Push(dst, (Obj*)Int_new(i)); }
        for (i = 0; i < 10; i++) { Vec_Push(dst, (Obj*)Int_new(i + 20)); }
        for (i = 0; i < 10; i++) { Vec_Push(src, (Obj*)Int_new(i + 10)); }
        for (i = 0; i < 30; i++) { Vec_Push(wanted, (Obj*)Int_new(i)); }

        Vec_Insert_All(dst, 10, src);
        TEST_TRUE(runner, Vec_Equals(dst, (Obj*)wanted), "Insert_All between");

        DECREF(wanted);
        DECREF(src);
        DECREF(dst);
    }

    {
        Vector *dst    = Vec_new(10);
        Vector *src    = Vec_new(10);
        Vector *wanted = Vec_new(30);

        for (i = 0; i < 10; i++) { Vec_Push(dst, (Obj*)Int_new(i)); }
        for (i = 0; i < 10; i++) { Vec_Push(src, (Obj*)Int_new(i + 20)); }
        for (i = 0; i < 10; i++) { Vec_Push(wanted, (Obj*)Int_new(i)); }
        for (i = 0; i < 10; i++) {
            Vec_Store(wanted, (size_t)i + 20, (Obj*)Int_new(i + 20));
        }

        Vec_Insert_All(dst, 20, src);
        TEST_TRUE(runner, Vec_Equals(dst, (Obj*)wanted), "Insert_All after");

        DECREF(wanted);
        DECREF(src);
        DECREF(dst);
    }
}

static void
test_Delete(TestBatchRunner *runner) {
    Vector *wanted = Vec_new(5);
    Vector *got    = Vec_new(5);
    uint32_t i;

    for (i = 0; i < 5; i++) { Vec_Push(got, (Obj*)Str_newf("%u32", i)); }
    Vec_Store(wanted, 0, (Obj*)Str_newf("0", i));
    Vec_Store(wanted, 1, (Obj*)Str_newf("1", i));
    Vec_Store(wanted, 4, (Obj*)Str_newf("4", i));
    DECREF(Vec_Delete(got, 2));
    DECREF(Vec_Delete(got, 3));
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got), "Delete");

    TEST_TRUE(runner, Vec_Delete(got, 25000) == NULL,
              "Delete beyond array size returns NULL");

    DECREF(wanted);
    DECREF(got);
}

static void
test_Resize(TestBatchRunner *runner) {
    Vector *array = Vec_new(3);
    uint32_t i;

    for (i = 0; i < 2; i++) { Vec_Push(array, (Obj*)Str_newf("%u32", i)); }
    TEST_UINT_EQ(runner, Vec_Get_Capacity(array), 3, "Start with capacity 3");

    Vec_Resize(array, 4);
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 4, "Resize up");
    TEST_UINT_EQ(runner, Vec_Get_Capacity(array), 4,
                "Resize changes capacity");

    Vec_Resize(array, 2);
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 2, "Resize down");
    TEST_TRUE(runner, Vec_Fetch(array, 2) == NULL, "Resize down zaps elem");

    Vec_Resize(array, 2);
    TEST_UINT_EQ(runner, Vec_Get_Size(array), 2, "Resize to same size");

    DECREF(array);

    array = S_array_with_garbage();
    Vec_Resize(array, 40);
    bool all_null = true;
    for (size_t i = 10; i < 40; i++) {
        if (Vec_Fetch(array, i) != NULL) { all_null = false; }
    }
    TEST_TRUE(runner, all_null, "Resize clears excised elements");
    DECREF(array);
}

static void
test_Excise(TestBatchRunner *runner) {
    Vector *wanted = Vec_new(5);
    Vector *got    = Vec_new(5);

    for (uint32_t i = 0; i < 5; i++) {
        Vec_Push(wanted, (Obj*)Str_newf("%u32", i));
        Vec_Push(got, (Obj*)Str_newf("%u32", i));
    }

    Vec_Excise(got, 7, 1);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got),
              "Excise outside of range is no-op");

    Vec_Excise(got, 2, 2);
    DECREF(Vec_Delete(wanted, 2));
    DECREF(Vec_Delete(wanted, 3));
    Vec_Store(wanted, 2, Vec_Delete(wanted, 4));
    Vec_Resize(wanted, 3);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got),
              "Excise multiple elems");

    Vec_Excise(got, 2, 2);
    Vec_Resize(wanted, 2);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got),
              "Splicing too many elems truncates");

    Vec_Excise(got, 0, 1);
    Vec_Store(wanted, 0, Vec_Delete(wanted, 1));
    Vec_Resize(wanted, 1);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got),
              "Excise first elem");

    DECREF(got);
    DECREF(wanted);
}

static void
test_Push_All(TestBatchRunner *runner) {
    Vector *wanted  = Vec_new(0);
    Vector *got     = Vec_new(0);
    Vector *scratch = Vec_new(0);
    Vector *empty   = Vec_new(0);
    uint32_t i;

    for (i =  0; i < 40; i++) { Vec_Push(wanted, (Obj*)Str_newf("%u32", i)); }
    Vec_Push(wanted, NULL);
    for (i =  0; i < 20; i++) { Vec_Push(got, (Obj*)Str_newf("%u32", i)); }
    for (i = 20; i < 40; i++) { Vec_Push(scratch, (Obj*)Str_newf("%u32", i)); }
    Vec_Push(scratch, NULL);

    Vec_Push_All(got, scratch);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got), "Push_All");

    Vec_Push_All(got, empty);
    TEST_TRUE(runner, Vec_Equals(wanted, (Obj*)got),
              "Push_All with empty array");

    DECREF(wanted);
    DECREF(got);
    DECREF(scratch);
    DECREF(empty);
}

static void
test_Slice(TestBatchRunner *runner) {
    Vector *array = Vec_new(0);
    for (uint32_t i = 0; i < 10; i++) { Vec_Push(array, (Obj*)Str_newf("%u32", i)); }
    {
        Vector *slice = Vec_Slice(array, 0, 10);
        TEST_TRUE(runner, Vec_Equals(array, (Obj*)slice), "Slice entire array");
        DECREF(slice);
    }
    {
        Vector *slice = Vec_Slice(array, 0, 11);
        TEST_TRUE(runner, Vec_Equals(array, (Obj*)slice),
            "Exceed length");
        DECREF(slice);
    }
    {
        Vector *wanted = Vec_new(0);
        Vec_Push(wanted, (Obj*)Str_newf("9"));
        Vector *slice = Vec_Slice(array, 9, 11);
        TEST_TRUE(runner, Vec_Equals(slice, (Obj*)wanted),
            "Exceed length, start near end");
        DECREF(slice);
        DECREF(wanted);
    }
    {
        Vector *slice = Vec_Slice(array, 0, 0);
        TEST_TRUE(runner, Vec_Get_Size(slice) == 0, "empty slice");
        DECREF(slice);
    }
    {
        Vector *slice = Vec_Slice(array, 20, 1);
        TEST_TRUE(runner, Vec_Get_Size(slice) ==  0, "exceed offset");
        DECREF(slice);
    }
    {
        Vector *wanted = Vec_new(0);
        Vec_Push(wanted, (Obj*)Str_newf("9"));
        Vector *slice = Vec_Slice(array, 9, SIZE_MAX - 1);
        TEST_TRUE(runner, Vec_Get_Size(slice) == 1, "guard against overflow");
        DECREF(slice);
        DECREF(wanted);
    }
    DECREF(array);
}

static void
test_Clone(TestBatchRunner *runner) {
    Vector *array = Vec_new(0);
    Vector *twin;
    uint32_t i;

    for (i = 0; i < 10; i++) {
        Vec_Push(array, (Obj*)Int_new(i));
    }
    Vec_Push(array, NULL);
    twin = Vec_Clone(array);
    TEST_TRUE(runner, Vec_Equals(array, (Obj*)twin), "Clone");
    TEST_TRUE(runner, Vec_Fetch(array, 1) == Vec_Fetch(twin, 1),
              "Clone doesn't clone elements");

    DECREF(array);
    DECREF(twin);
}

static void
S_push(void *context) {
    Vector *vec = (Vector*)context;
    Vec_Push(vec, (Obj*)CFISH_TRUE);
}

static void
S_insert_at_size_max(void *context) {
    Vector *vec = (Vector*)context;
    Vec_Insert(vec, SIZE_MAX, (Obj*)CFISH_TRUE);
}

static void
S_store_at_size_max(void *context) {
    Vector *vec = (Vector*)context;
    Vec_Store(vec, SIZE_MAX, (Obj*)CFISH_TRUE);
}

typedef struct {
    Vector *vec;
    Vector *other;
} VectorPair;

static void
S_push_all(void *vcontext) {
    VectorPair *context = (VectorPair*)vcontext;
    Vec_Push_All(context->vec, context->other);
}

static void
S_insert_all_at_size_max(void *vcontext) {
    VectorPair *context = (VectorPair*)vcontext;
    Vec_Insert_All(context->vec, SIZE_MAX, context->other);
}

static void
S_test_exception(TestBatchRunner *runner, Err_Attempt_t func, void *context,
                 const char *test_name) {
    Err *error = Err_trap(func, context);
    TEST_TRUE(runner, error != NULL, test_name);
    DECREF(error);
}

static void
test_exceptions(TestBatchRunner *runner) {
    {
        Vector *vec = Vec_new(0);
        vec->cap  = MAX_VECTOR_SIZE;
        vec->size = vec->cap;
        S_test_exception(runner, S_push, vec, "Push throws on overflow");
        vec->size = 0;
        DECREF(vec);
    }

    {
        Vector *vec = Vec_new(0);
        S_test_exception(runner, S_insert_at_size_max, vec,
                         "Insert throws on overflow");
        DECREF(vec);
    }

    {
        Vector *vec = Vec_new(0);
        S_test_exception(runner, S_store_at_size_max, vec,
                         "Store throws on overflow");
        DECREF(vec);
    }

    {
        VectorPair context;
        context.vec         = Vec_new(0);
        context.vec->cap    = 1000000000;
        context.vec->size   = context.vec->cap;
        context.other       = Vec_new(0);
        context.other->cap  = MAX_VECTOR_SIZE - context.vec->cap + 1;
        context.other->size = context.other->cap;
        S_test_exception(runner, S_push_all, &context,
                         "Push_All throws on overflow");
        context.vec->size   = 0;
        context.other->size = 0;
        DECREF(context.other);
        DECREF(context.vec);
    }

    {
        VectorPair context;
        context.vec   = Vec_new(0);
        context.other = Vec_new(0);
        S_test_exception(runner, S_insert_all_at_size_max, &context,
                         "Insert_All throws on overflow");
        DECREF(context.other);
        DECREF(context.vec);
    }
}

static void
test_Sort(TestBatchRunner *runner) {
    Vector *array  = Vec_new(8);
    Vector *wanted = Vec_new(8);

    Vec_Push(array, NULL);
    Vec_Push(array, (Obj*)Str_newf("aaab"));
    Vec_Push(array, (Obj*)Str_newf("ab"));
    Vec_Push(array, NULL);
    Vec_Push(array, NULL);
    Vec_Push(array, (Obj*)Str_newf("aab"));
    Vec_Push(array, (Obj*)Str_newf("b"));

    Vec_Push(wanted, (Obj*)Str_newf("aaab"));
    Vec_Push(wanted, (Obj*)Str_newf("aab"));
    Vec_Push(wanted, (Obj*)Str_newf("ab"));
    Vec_Push(wanted, (Obj*)Str_newf("b"));
    Vec_Push(wanted, NULL);
    Vec_Push(wanted, NULL);
    Vec_Push(wanted, NULL);

    Vec_Sort(array);
    TEST_TRUE(runner, Vec_Equals(array, (Obj*)wanted), "Sort with NULLs");

    DECREF(array);
    DECREF(wanted);
}

static void
test_Grow(TestBatchRunner *runner) {
    Vector *array = Vec_new(500);
    size_t  cap;

    cap = Vec_Get_Capacity(array);
    TEST_TRUE(runner, cap >= 500, "Array is created with minimum capacity");

    Vec_Grow(array, 2000);
    cap = Vec_Get_Capacity(array);
    TEST_TRUE(runner, cap >= 2000, "Grow to larger capacity");

    size_t old_cap = cap;
    Vec_Grow(array, old_cap);
    cap = Vec_Get_Capacity(array);
    TEST_TRUE(runner, cap >= old_cap, "Grow to same capacity");

    Vec_Grow(array, 1000);
    cap = Vec_Get_Capacity(array);
    TEST_TRUE(runner, cap >= 1000, "Grow to smaller capacity");

    DECREF(array);
}

void
TestVector_Run_IMP(TestVector *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 62);
    test_Equals(runner);
    test_Store_Fetch(runner);
    test_Push_Pop_Insert(runner);
    test_Insert_All(runner);
    test_Delete(runner);
    test_Resize(runner);
    test_Excise(runner);
    test_Push_All(runner);
    test_Slice(runner);
    test_Clone(runner);
    test_exceptions(runner);
    test_Sort(runner);
    test_Grow(runner);
}


