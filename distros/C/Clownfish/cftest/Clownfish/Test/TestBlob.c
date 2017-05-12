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

#include "Clownfish/Test/TestBlob.h"

#include "Clownfish/Blob.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"
#include "Clownfish/Util/Memory.h"

#include <string.h>

TestBlob*
TestBlob_new() {
    return (TestBlob*)Class_Make_Obj(TESTBLOB);
}

static void
test_new_steal(TestBatchRunner *runner) {
    size_t size = 4;
    char *buf = (char*)MALLOCATE(size);
    memset(buf, 'x', size);
    Blob *blob = Blob_new_steal(buf, size);
    TEST_TRUE(runner, Blob_Get_Buf(blob) == buf, "new_steal steals buf");
    TEST_TRUE(runner, Blob_Equals_Bytes(blob, "xxxx", 4),
              "new_steal doesn't change buf");
    DECREF(blob);
}

static void
test_new_wrap(TestBatchRunner *runner) {
    static const char buf[] = "xxxx";
    Blob *blob = Blob_new_wrap(buf, 4);
    TEST_TRUE(runner, Blob_Get_Buf(blob) == buf, "new_wrap wraps buf");
    TEST_TRUE(runner, Blob_Equals_Bytes(blob, "xxxx", 4),
              "new_wrap doesn't change buf");
    DECREF(blob);
}

static void
test_Equals(TestBatchRunner *runner) {
    Blob *blob = Blob_new("foo", 4); // Include terminating NULL.

    {
        Blob *other = Blob_new("foo", 4);
        TEST_TRUE(runner, Blob_Equals(blob, (Obj*)other), "Equals");
        DECREF(other);
    }

    {
        Blob *other = Blob_new("foo", 3);
        TEST_FALSE(runner, Blob_Equals(blob, (Obj*)other),
                   "Different size spoils Equals");
        DECREF(other);
    }

    {
        Blob *other = Blob_new("bar", 4);
        TEST_UINT_EQ(runner, Blob_Get_Size(blob), Blob_Get_Size(other),
                     "same length");
        TEST_FALSE(runner, Blob_Equals(blob, (Obj*)other),
                   "Different content spoils Equals");
        DECREF(other);
    }

    TEST_FALSE(runner, Blob_Equals(blob, (Obj*)BLOB),
               "Different type spoils Equals");

    TEST_TRUE(runner, Blob_Equals_Bytes(blob, "foo", 4), "Equals_Bytes");
    TEST_FALSE(runner, Blob_Equals_Bytes(blob, "foo", 3),
               "Equals_Bytes spoiled by different size");
    TEST_FALSE(runner, Blob_Equals_Bytes(blob, "bar", 4),
               "Equals_Bytes spoiled by different content");

    DECREF(blob);
}

static void
test_Clone(TestBatchRunner *runner) {
    Blob *blob = Blob_new("foo", 3);
    Blob *twin = Blob_Clone(blob);
    TEST_TRUE(runner, Blob_Equals(blob, (Obj*)twin), "Clone");
    DECREF(blob);
    DECREF(twin);
}

static void
test_Compare_To(TestBatchRunner *runner) {
    {
        Blob *a = Blob_new("foo", 4);
        Blob *b = Blob_new("foo", 4);
        TEST_INT_EQ(runner, Blob_Compare_To(a, (Obj*)b), 0,
                    "Compare_To returns 0 for equal Blobs");
        DECREF(a);
        DECREF(b);
    }

    {
        Blob *a = Blob_new("foo", 3);
        Blob *b = Blob_new("foo\0b", 5);
        TEST_TRUE(runner, Blob_Compare_To(a, (Obj*)b) < 0,
                  "shorter Blob sorts first");
        TEST_TRUE(runner, Blob_Compare_To(b, (Obj*)a) > 0,
                  "longer Blob sorts last");
        DECREF(a);
        DECREF(b);
    }

    {
        Blob *a = Blob_new("foo\0a", 5);
        Blob *b = Blob_new("foo\0b", 5);
        TEST_TRUE(runner, Blob_Compare_To(a, (Obj*)b) < 0,
                  "NULL doesn't interfere with Compare_To");
        DECREF(a);
        DECREF(b);
    }
}

void
TestBlob_Run_IMP(TestBlob *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 17);
    test_new_steal(runner);
    test_new_wrap(runner);
    test_Equals(runner);
    test_Clone(runner);
    test_Compare_To(runner);
}


