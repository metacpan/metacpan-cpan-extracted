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

#include <stdlib.h>
#include <time.h>

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include "Clownfish/Test/TestHashIterator.h"

#include "Clownfish/Err.h"
#include "Clownfish/String.h"
#include "Clownfish/Hash.h"
#include "Clownfish/HashIterator.h"
#include "Clownfish/Test.h"
#include "Clownfish/Vector.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"

TestHashIterator*
TestHashIterator_new() {
    return (TestHashIterator*)Class_Make_Obj(TESTHASHITERATOR);
}

static void
test_Next(TestBatchRunner *runner) {
    Hash     *hash     = Hash_new(0); // trigger multiple rebuilds.
    Vector   *expected = Vec_new(100);
    Vector   *keys     = Vec_new(500);
    Vector   *values   = Vec_new(500);

    for (uint32_t i = 0; i < 500; i++) {
        String *str = Str_newf("%u32", i);
        Hash_Store(hash, str, (Obj*)str);
        Vec_Push(expected, INCREF(str));
    }

    Vec_Sort(expected);

    {
        HashIterator *iter = HashIter_new(hash);
        while (HashIter_Next(iter)) {
            String *key = HashIter_Get_Key(iter);
            Obj *value = HashIter_Get_Value(iter);
            Vec_Push(keys, INCREF(key));
            Vec_Push(values, INCREF(value));
        }
        TEST_TRUE(runner, !HashIter_Next(iter),
                  "Next continues to return false after iteration finishes.");

        DECREF(iter);
    }

    Vec_Sort(keys);
    Vec_Sort(values);
    TEST_TRUE(runner, Vec_Equals(keys, (Obj*)expected), "Keys from Iter");
    TEST_TRUE(runner, Vec_Equals(values, (Obj*)expected), "Values from Iter");

    DECREF(hash);
    DECREF(expected);
    DECREF(keys);
    DECREF(values);
}

static void
S_invoke_Next(void *context) {
    HashIterator *iter = (HashIterator*)context;
    HashIter_Next(iter);
}

static void
S_invoke_Get_Key(void *context) {
    HashIterator *iter = (HashIterator*)context;
    HashIter_Get_Key(iter);
}

static void
S_invoke_Get_Value(void *context) {
    HashIterator *iter = (HashIterator*)context;
    HashIter_Get_Value(iter);
}

static void
test_empty(TestBatchRunner *runner) {
    Hash         *hash = Hash_new(0);
    HashIterator *iter = HashIter_new(hash);

    TEST_TRUE(runner, !HashIter_Next(iter),
              "First call to next false on empty hash iteration");

    Err *get_key_error = Err_trap(S_invoke_Get_Key, iter);
    TEST_TRUE(runner, get_key_error != NULL,
              "Get_Key throws exception on empty hash.");
    DECREF(get_key_error);

    Err *get_value_error = Err_trap(S_invoke_Get_Value, iter);
    TEST_TRUE(runner, get_value_error != NULL,
              "Get_Value throws exception on empty hash.");
    DECREF(get_value_error);

    DECREF(hash);
    DECREF(iter);
}

static void
test_Get_Key_and_Get_Value(TestBatchRunner *runner) {
    Hash   *hash = Hash_new(0);
    String *str  = Str_newf("foo");
    Hash_Store(hash, str, (Obj*)str);
    bool ok;

    HashIterator *iter = HashIter_new(hash);
    DECREF(hash);

    Err *get_key_error = Err_trap(S_invoke_Get_Key, iter);
    TEST_TRUE(runner, get_key_error != NULL,
              "Get_Key throws exception before first call to Next.");
    ok = Str_Contains_Utf8(Err_Get_Mess(get_key_error), "before", 6);
    TEST_TRUE(runner, ok, "Get_Key before Next throws correct message");
    DECREF(get_key_error);

    Err *get_value_error = Err_trap(S_invoke_Get_Value, iter);
    TEST_TRUE(runner, get_value_error != NULL,
              "Get_Value throws exception before first call to Next.");
    ok = Str_Contains_Utf8(Err_Get_Mess(get_value_error), "before", 6);
    TEST_TRUE(runner, ok, "Get_Value before Next throws correct message");
    DECREF(get_value_error);

    HashIter_Next(iter);
    TEST_TRUE(runner, HashIter_Get_Key(iter) != NULL,
              "Get_Key during iteration.");
    TEST_TRUE(runner, HashIter_Get_Value(iter) != NULL,
              "Get_Value during iteration.");

    HashIter_Next(iter);
    get_key_error = Err_trap(S_invoke_Get_Key, iter);
    TEST_TRUE(runner, get_key_error != NULL,
              "Get_Key throws exception after end of iteration.");
    ok = Str_Contains_Utf8(Err_Get_Mess(get_key_error), "after", 5);
    TEST_TRUE(runner, ok, "Get_Key after end throws correct message");
    DECREF(get_key_error);

    get_value_error = Err_trap(S_invoke_Get_Value, iter);
    TEST_TRUE(runner, get_value_error != NULL,
              "Get_Value throws exception after end of iteration.");
    ok = Str_Contains_Utf8(Err_Get_Mess(get_value_error), "after", 5);
    TEST_TRUE(runner, ok, "Get_Value after end throws correct message");
    DECREF(get_value_error);


    DECREF(iter);
}

static void
test_illegal_modification(TestBatchRunner *runner) {
    Hash *hash = Hash_new(0);

    for (uint32_t i = 0; i < 3; i++) {
        String *str = Str_newf("%u32", i);
        Hash_Store(hash, str, (Obj*)str);
    }

    HashIterator *iter = HashIter_new(hash);
    HashIter_Next(iter);

    for (uint32_t i = 0; i < 100; i++) {
        String *str = Str_newf("foo %u32", i);
        Hash_Store(hash, str, (Obj*)str);
    }

    Err *next_error = Err_trap(S_invoke_Next, iter);
    TEST_TRUE(runner, next_error != NULL,
              "Next on resized hash throws exception.");
    DECREF(next_error);

    Err *get_key_error = Err_trap(S_invoke_Get_Key, iter);
    TEST_TRUE(runner, get_key_error != NULL,
              "Get_Key on resized hash throws exception.");
    DECREF(get_key_error);

    Err *get_value_error = Err_trap(S_invoke_Get_Value, iter);
    TEST_TRUE(runner, get_value_error != NULL,
              "Get_Value on resized hash throws exception.");
    DECREF(get_value_error);

    DECREF(hash);
    DECREF(iter);
}

static void
test_tombstone(TestBatchRunner *runner) {
    {
        Hash   *hash = Hash_new(0);
        String *str  = Str_newf("foo");
        Hash_Store(hash, str, INCREF(str));
        DECREF(Hash_Delete(hash, str));
        DECREF(str);

        HashIterator *iter = HashIter_new(hash);
        TEST_TRUE(runner, !HashIter_Next(iter), "Next advances past tombstones.");

        DECREF(iter);
        DECREF(hash);
    }

    {
        Hash   *hash = Hash_new(0);
        String *str  = Str_newf("foo");
        Hash_Store(hash, str, INCREF(str));

        HashIterator *iter = HashIter_new(hash);
        HashIter_Next(iter);
        DECREF(Hash_Delete(hash, str));


        Err *get_key_error = Err_trap(S_invoke_Get_Key, iter);
        TEST_TRUE(runner, get_key_error != NULL,
                  "Get_Key doesn't return tombstone and throws error.");
        DECREF(get_key_error);

        DECREF(str);
        DECREF(iter);
        DECREF(hash);
    }
}

void
TestHashIterator_Run_IMP(TestHashIterator *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 21);
    srand((unsigned int)time((time_t*)NULL));
    test_Next(runner);
    test_empty(runner);
    test_Get_Key_and_Get_Value(runner);
    test_illegal_modification(runner);
    test_tombstone(runner);
}


