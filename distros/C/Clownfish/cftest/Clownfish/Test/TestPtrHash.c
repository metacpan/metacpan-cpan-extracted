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

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include <stdlib.h>
#include <time.h>

#include "Clownfish/Test/TestPtrHash.h"
#include "Clownfish/Class.h"
#include "Clownfish/PtrHash.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Util/Memory.h"

TestPtrHash*
TestPtrHash_new() {
    return (TestPtrHash*)Class_Make_Obj(TESTPTRHASH);
}

static void
test_Store_and_Fetch(TestBatchRunner *runner) {
    PtrHash *hash = PtrHash_new(100);
    char dummy[100];

    for (int i = 0; i < 100; i++) {
        void *key = &dummy[i];
        PtrHash_Store(hash, key, key);
    }

    bool all_equal = true;
    for (int i = 0; i < 100; i++) {
        void *key = &dummy[i];
        void *value = PtrHash_Fetch(hash, key);
        if (value != key) {
            all_equal = false;
            break;
        }
    }
    TEST_TRUE(runner, all_equal, "basic Store and Fetch");

    TEST_TRUE(runner, PtrHash_Fetch(hash, &dummy[100]) == NULL,
              "Fetch against non-existent key returns NULL");

    PtrHash_Store(hash, &dummy[50], dummy);
    TEST_TRUE(runner, PtrHash_Fetch(hash, &dummy[50]) == dummy,
              "Store replaces existing value");

    PtrHash_Destroy(hash);
}

static void
test_stress(TestBatchRunner *runner) {
    PtrHash *hash = PtrHash_new(0); // trigger multiple rebuilds.
    size_t num_elems = 200000;
    void **keys = (void**)MALLOCATE(num_elems * sizeof(void*));

    for (size_t i = 0; i < num_elems; i++) {
        size_t index = (size_t)(TestUtils_random_u64() % num_elems);
        void *key = &keys[index];
        PtrHash_Store(hash, key, key);
        keys[i] = key;
    }

    // Overwrite for good measure.
    for (size_t i = 0; i < num_elems; i++) {
        void *key = keys[i];
        PtrHash_Store(hash, key, key);
    }

    bool all_equal = true;
    for (size_t i = 0; i < num_elems; i++) {
        void *key = keys[i];
        void *got = PtrHash_Fetch(hash, key);
        if (got != key) {
            all_equal = false;
            break;
        }
    }
    TEST_TRUE(runner, all_equal, "stress test");

    FREEMEM(keys);
    PtrHash_Destroy(hash);
}

void
TestPtrHash_Run_IMP(TestPtrHash *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 4);
    srand((unsigned int)time(NULL));
    test_Store_and_Fetch(runner);
    test_stress(runner);
}


