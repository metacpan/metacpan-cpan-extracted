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
#define C_CFISH_HASH

#include "Clownfish/Test/TestHash.h"

#include "Clownfish/String.h"
#include "Clownfish/Boolean.h"
#include "Clownfish/Hash.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Vector.h"
#include "Clownfish/Class.h"

TestHash*
TestHash_new() {
    return (TestHash*)Class_Make_Obj(TESTHASH);
}

static void
test_Equals(TestBatchRunner *runner) {
    Hash *hash  = Hash_new(0);
    Hash *other = Hash_new(0);
    String *stuff = SSTR_WRAP_C("stuff");

    TEST_TRUE(runner, Hash_Equals(hash, (Obj*)other),
              "Empty hashes are equal");

    Hash_Store_Utf8(hash, "foo", 3, (Obj*)CFISH_TRUE);
    TEST_FALSE(runner, Hash_Equals(hash, (Obj*)other),
               "Add one pair and Equals returns false");

    Hash_Store_Utf8(other, "foo", 3, (Obj*)CFISH_TRUE);
    TEST_TRUE(runner, Hash_Equals(hash, (Obj*)other),
              "Add a matching pair and Equals returns true");

    Hash_Store_Utf8(other, "foo", 3, INCREF(stuff));
    TEST_FALSE(runner, Hash_Equals(hash, (Obj*)other),
               "Non-matching value spoils Equals");

    DECREF(hash);
    DECREF(other);
}

static void
test_Store_and_Fetch(TestBatchRunner *runner) {
    Hash          *hash         = Hash_new(100);
    Hash          *dupe         = Hash_new(100);
    const size_t   starting_cap = Hash_Get_Capacity(hash);
    Vector        *expected     = Vec_new(100);
    Vector        *got          = Vec_new(100);
    String        *twenty       = SSTR_WRAP_C("20");
    String        *forty        = SSTR_WRAP_C("40");
    String        *foo          = SSTR_WRAP_C("foo");

    for (int32_t i = 0; i < 100; i++) {
        String *str = Str_newf("%i32", i);
        Hash_Store(hash, str, (Obj*)str);
        Hash_Store(dupe, str, INCREF(str));
        Vec_Push(expected, INCREF(str));
    }
    TEST_TRUE(runner, Hash_Equals(hash, (Obj*)dupe), "Equals");

    TEST_UINT_EQ(runner, Hash_Get_Capacity(hash), starting_cap,
                 "Initial capacity sufficient (no rebuilds)");

    for (size_t i = 0; i < 100; i++) {
        String *key  = (String*)Vec_Fetch(expected, i);
        Obj    *elem = Hash_Fetch(hash, key);
        Vec_Push(got, (Obj*)INCREF(elem));
    }

    TEST_TRUE(runner, Vec_Equals(got, (Obj*)expected),
              "basic Store and Fetch");
    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 100,
                 "size incremented properly by Hash_Store");

    TEST_TRUE(runner, Hash_Fetch(hash, foo) == NULL,
              "Fetch against non-existent key returns NULL");

    String *twelve = (String*)Hash_Fetch_Utf8(hash, "12", 2);
    TEST_TRUE(runner, Str_Equals_Utf8(twelve, "12", 2), "Fetch_Utf8");

    Obj *stored_foo = INCREF(foo);
    Hash_Store(hash, forty, stored_foo);
    TEST_TRUE(runner, Str_Equals(foo, Hash_Fetch(hash, forty)),
              "Hash_Store replaces existing value");
    TEST_FALSE(runner, Hash_Equals(hash, (Obj*)dupe),
               "replacement value spoils equals");
    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 100,
                 "size unaffected after value replaced");

    TEST_TRUE(runner, Hash_Delete(hash, forty) == stored_foo,
              "Delete returns value");
    DECREF(stored_foo);
    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 99,
                 "size decremented by successful Delete");
    TEST_TRUE(runner, Hash_Delete(hash, forty) == NULL,
              "Delete returns NULL when key not found");
    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 99,
                 "size not decremented by unsuccessful Delete");
    DECREF(Hash_Delete(dupe, forty));
    TEST_TRUE(runner, Vec_Equals(got, (Obj*)expected), "Equals after Delete");

    Obj *forty_one = Hash_Delete_Utf8(hash, "41", 2);
    TEST_TRUE(runner, forty_one != NULL, "Delete_Utf8");
    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 98,
                 "Delete_Utf8 decrements size");
    DECREF(forty_one);

    Hash_Clear(hash);
    TEST_TRUE(runner, Hash_Fetch(hash, twenty) == NULL, "Clear");
    TEST_TRUE(runner, Hash_Get_Size(hash) == 0, "size is 0 after Clear");

    Hash_Clear(hash);
    Hash_Store(hash, forty, NULL);
    TEST_TRUE(runner, Hash_Fetch(hash, forty) == NULL, "Store NULL");
    TEST_TRUE(runner, Hash_Get_Size(hash) == 1, "Size after Store NULL");
    TEST_TRUE(runner, Hash_Delete(hash, forty) == NULL, "Delete NULL value");
    TEST_TRUE(runner, Hash_Get_Size(hash) == 0,
              "Size after Deleting NULL val");

    DECREF(hash);
    DECREF(dupe);
    DECREF(got);
    DECREF(expected);
}

static void
test_Keys_Values(TestBatchRunner *runner) {
    Hash     *hash     = Hash_new(0); // trigger multiple rebuilds.
    Vector   *expected = Vec_new(100);
    Vector   *keys;
    Vector   *values;

    for (uint32_t i = 0; i < 500; i++) {
        String *str = Str_newf("%u32", i);
        Hash_Store(hash, str, (Obj*)str);
        Vec_Push(expected, INCREF(str));
    }

    Vec_Sort(expected);

    keys   = Hash_Keys(hash);
    values = Hash_Values(hash);
    Vec_Sort(keys);
    Vec_Sort(values);
    TEST_TRUE(runner, Vec_Equals(keys, (Obj*)expected), "Keys");
    TEST_TRUE(runner, Vec_Equals(values, (Obj*)expected), "Values");
    Vec_Clear(keys);
    Vec_Clear(values);

    {
        String *forty = SSTR_WRAP_C("40");
        String *nope  = SSTR_WRAP_C("nope");
        TEST_TRUE(runner, Hash_Has_Key(hash, forty), "Has_Key");
        TEST_FALSE(runner, Hash_Has_Key(hash, nope),
                   "Has_Key returns false for non-existent key");
    }

    DECREF(hash);
    DECREF(expected);
    DECREF(keys);
    DECREF(values);
}

static void
test_stress(TestBatchRunner *runner) {
    Hash     *hash     = Hash_new(0); // trigger multiple rebuilds.
    Vector   *expected = Vec_new(1000);
    Vector   *keys;
    Vector   *values;

    for (uint32_t i = 0; i < 1000; i++) {
        String *str = TestUtils_random_string((size_t)(rand() % 1200));
        while (Hash_Fetch(hash, str)) {
            DECREF(str);
            str = TestUtils_random_string((size_t)(rand() % 1200));
        }
        Hash_Store(hash, str, (Obj*)str);
        Vec_Push(expected, INCREF(str));
    }

    Vec_Sort(expected);

    // Overwrite for good measure.
    for (uint32_t i = 0; i < 1000; i++) {
        String *str = (String*)Vec_Fetch(expected, i);
        Hash_Store(hash, str, INCREF(str));
    }

    keys   = Hash_Keys(hash);
    values = Hash_Values(hash);
    Vec_Sort(keys);
    Vec_Sort(values);
    TEST_TRUE(runner, Vec_Equals(keys, (Obj*)expected), "stress Keys");
    TEST_TRUE(runner, Vec_Equals(values, (Obj*)expected), "stress Values");

    DECREF(keys);
    DECREF(values);
    DECREF(expected);
    DECREF(hash);
}

static void
test_collision(TestBatchRunner *runner) {
    Hash   *hash = Hash_new(0);
    String *one  = Str_newf("A");
    String *two  = Str_newf("P{2}|=~-ULE/d");

    TEST_TRUE(runner, Str_Hash_Sum(one) == Str_Hash_Sum(two),
              "Keys have the same hash sum");

    Hash_Store(hash, one, INCREF(one));
    Hash_Store(hash, two, INCREF(two));
    String *elem = (String*)Hash_Fetch(hash, two);
    TEST_TRUE(runner, elem == two, "Fetch works with collisions");

    DECREF(one);
    DECREF(two);
    DECREF(hash);
}

static void
test_store_skips_tombstone(TestBatchRunner *runner) {
    Hash *hash = Hash_new(0);
    size_t mask = Hash_Get_Capacity(hash) - 1;

    String *one = Str_newf("one");
    size_t slot = Str_Hash_Sum(one) & mask;

    // Find a colliding key.
    String *two = NULL;
    for (int i = 0; i < 100000; i++) {
        two = Str_newf("%i32", i);
        if (slot == (Str_Hash_Sum(two) & mask)) {
            break;
        }
        DECREF(two);
        two = NULL;
    }

    Hash_Store(hash, one, (Obj*)CFISH_TRUE);
    Hash_Store(hash, two, (Obj*)CFISH_TRUE);
    Hash_Delete(hash, one);
    Hash_Store(hash, two, (Obj*)CFISH_TRUE);

    TEST_UINT_EQ(runner, Hash_Get_Size(hash), 1, "Store skips tombstone");

    DECREF(one);
    DECREF(two);
    DECREF(hash);
}

static void
test_threshold_accounting(TestBatchRunner *runner) {
    Hash   *hash = Hash_new(20);
    String *key  = Str_newf("key");

    size_t threshold = hash->threshold;
    Hash_Store(hash, key, (Obj*)CFISH_TRUE);
    Hash_Delete(hash, key);
    TEST_UINT_EQ(runner, hash->threshold, threshold - 1,
                 "Tombstone creation decreases threshold");

    Hash_Store(hash, key, (Obj*)CFISH_TRUE);
    TEST_UINT_EQ(runner, hash->threshold, threshold,
                 "Tombstone destruction increases threshold");

    DECREF(key);
    DECREF(hash);
}

static void
test_tombstone_identification(TestBatchRunner *runner) {
    Hash   *hash = Hash_new(20);
    String *key  = Str_newf("P{2}|=~-U@!y>");

    // Tombstones have a zero hash_sum.
    TEST_UINT_EQ(runner, Str_Hash_Sum(key), 0, "Key has zero hash sum");

    Hash_Store(hash, key, (Obj*)CFISH_TRUE);
    Hash_Delete(hash, key);
    TEST_TRUE(runner, Hash_Fetch(hash, key) == NULL,
              "Key with zero hash sum isn't mistaken for tombstone");

    DECREF(key);
    DECREF(hash);
}

void
TestHash_Run_IMP(TestHash *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 39);
    srand((unsigned int)time((time_t*)NULL));
    test_Equals(runner);
    test_Store_and_Fetch(runner);
    test_Keys_Values(runner);
    test_stress(runner);
    test_collision(runner);
    test_store_skips_tombstone(runner);
    test_threshold_accounting(runner);
    test_tombstone_identification(runner);
}


