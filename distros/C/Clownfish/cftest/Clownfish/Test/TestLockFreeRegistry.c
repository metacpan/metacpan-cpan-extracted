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
#include <string.h>

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include "Clownfish/Test/TestLockFreeRegistry.h"

#include "Clownfish/Class.h"
#include "Clownfish/LockFreeRegistry.h"
#include "Clownfish/String.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Util/Memory.h"

#define NUM_THREADS 5

typedef struct ThreadArgs {
    LockFreeRegistry *registry;
    uint32_t         *nums;
    uint32_t          num_objs;
    uint64_t          target_time;
    uint32_t          succeeded;
} ThreadArgs;

TestLockFreeRegistry*
TestLFReg_new() {
    return (TestLockFreeRegistry*)Class_Make_Obj(TESTLOCKFREEREGISTRY);
}

static void
test_all(TestBatchRunner *runner) {
    LockFreeRegistry *registry = LFReg_new(1);
    String *foo = Str_newf("foo");
    String *bar = Str_newf("bar");
    String *baz = Str_newf("baz");
    String *foo_dupe = Str_newf("foo");

    TEST_TRUE(runner, LFReg_register(registry, foo, (Obj*)foo),
              "Register() returns true on success");
    TEST_FALSE(runner,
               LFReg_register(registry, foo_dupe, (Obj*)foo_dupe),
               "Can't Register() keys that test equal");

    TEST_TRUE(runner, LFReg_register(registry, bar, (Obj*)bar),
              "Register() key with the same Hash_Sum but that isn't Equal");

    TEST_TRUE(runner, LFReg_fetch(registry, foo_dupe) == (Obj*)foo,
              "Fetch()");
    TEST_TRUE(runner, LFReg_fetch(registry, bar) == (Obj*)bar,
              "Fetch() again");
    TEST_TRUE(runner, LFReg_fetch(registry, baz) == NULL,
              "Fetch() non-existent key returns NULL");

    DECREF(foo_dupe);
    DECREF(baz);
    DECREF(bar);
    DECREF(foo);
    LFReg_destroy(registry);
}

static void
S_register_many(void *varg) {
    ThreadArgs *args = (ThreadArgs*)varg;

    // Encourage contention, so that all threads try to register at the same
    // time.

    // Sleep until target_time.
    uint64_t time = TestUtils_time();
    if (args->target_time > time) {
        TestUtils_usleep(args->target_time - time);
    }

    TestUtils_thread_yield();

    uint32_t succeeded = 0;
    for (uint32_t i = 0; i < args->num_objs; i++) {
        String *obj = Str_newf("%u32", args->nums[i]);
        if (LFReg_register(args->registry, obj, (Obj*)obj)) {
            succeeded++;
        }
        DECREF(obj);
    }

    args->succeeded = succeeded;
}

static void
test_threads(TestBatchRunner *runner) {
    if (!TestUtils_has_threads) {
        SKIP(runner, 1, "No thread support");
        return;
    }

    LockFreeRegistry *registry = LFReg_new(32);
    ThreadArgs thread_args[NUM_THREADS];
    uint32_t num_objs = 10000;

    for (uint32_t i = 0; i < NUM_THREADS; i++) {
        uint32_t *nums = (uint32_t*)MALLOCATE(num_objs * sizeof(uint32_t));

        for (uint32_t j = 0; j < num_objs; j++) {
            nums[j] = j;
        }

        // Fisher-Yates shuffle.
        for (uint32_t j = num_objs - 1; j > 0; j--) {
            uint32_t r = (uint32_t)TestUtils_random_u64() % (j + 1);
            uint32_t tmp = nums[j];
            nums[j] = nums[r];
            nums[r] = tmp;
        }

        thread_args[i].registry = registry;
        thread_args[i].nums     = nums;
        thread_args[i].num_objs = num_objs;
    }

    Thread *threads[NUM_THREADS];
    uint64_t target_time = TestUtils_time() + 200 * 1000;

    for (uint32_t i = 0; i < NUM_THREADS; i++) {
        thread_args[i].target_time = target_time;
        threads[i]
            = TestUtils_thread_create(S_register_many, &thread_args[i], NULL);
    }

    uint32_t total_succeeded = 0;

    for (uint32_t i = 0; i < NUM_THREADS; i++) {
        TestUtils_thread_join(threads[i]);
        total_succeeded += thread_args[i].succeeded;
        FREEMEM(thread_args[i].nums);
    }

    TEST_INT_EQ(runner, total_succeeded, num_objs,
                "registered exactly the right number of entries across all"
                " threads");

    LFReg_destroy(registry);
}

void
TestLFReg_Run_IMP(TestLockFreeRegistry *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 7);
    test_all(runner);
    test_threads(runner);
}


