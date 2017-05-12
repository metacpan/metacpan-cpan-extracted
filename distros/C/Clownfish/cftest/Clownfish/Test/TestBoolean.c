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

#include "Clownfish/Test/TestBoolean.h"

#include "Clownfish/String.h"
#include "Clownfish/Boolean.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"

TestBoolean*
TestBoolean_new() {
    return (TestBoolean*)Class_Make_Obj(TESTBOOLEAN);
}

static void
test_singleton(TestBatchRunner *runner) {
    TEST_TRUE(runner, Bool_singleton(true) == CFISH_TRUE,
              "Bool_singleton true");
    TEST_TRUE(runner, Bool_singleton(false) == CFISH_FALSE,
              "Bool_singleton false");
}

static void
test_To_String(TestBatchRunner *runner) {
    String *true_string  = Bool_To_String(CFISH_TRUE);
    String *false_string = Bool_To_String(CFISH_FALSE);

    TEST_TRUE(runner, Str_Equals_Utf8(true_string, "true", 4),
              "Bool_To_String [true]");
    TEST_TRUE(runner, Str_Equals_Utf8(false_string, "false", 5),
              "Bool_To_String [false]");

    DECREF(false_string);
    DECREF(true_string);
}

static void
test_accessors(TestBatchRunner *runner) {
    TEST_INT_EQ(runner, Bool_Get_Value(CFISH_TRUE), true,
                "Bool_Get_Value [true]");
    TEST_INT_EQ(runner, Bool_Get_Value(CFISH_FALSE), false,
                "Bool_Get_Value [false]");
}

static void
test_Equals_and_Compare_To(TestBatchRunner *runner) {
    TEST_TRUE(runner, Bool_Equals(CFISH_TRUE, (Obj*)CFISH_TRUE),
              "CFISH_TRUE Equals itself");
    TEST_TRUE(runner, Bool_Equals(CFISH_FALSE, (Obj*)CFISH_FALSE),
              "CFISH_FALSE Equals itself");
    TEST_FALSE(runner, Bool_Equals(CFISH_FALSE, (Obj*)CFISH_TRUE),
               "CFISH_FALSE not Equals CFISH_TRUE ");
    TEST_FALSE(runner, Bool_Equals(CFISH_TRUE, (Obj*)CFISH_FALSE),
               "CFISH_TRUE not Equals CFISH_FALSE ");
    TEST_FALSE(runner, Bool_Equals(CFISH_TRUE, (Obj*)STRING),
               "CFISH_TRUE not Equals random other object ");
}

static void
test_Clone(TestBatchRunner *runner) {
    TEST_TRUE(runner, Bool_Equals(CFISH_TRUE, (Obj*)Bool_Clone(CFISH_TRUE)),
              "Boolean Clone");
}

void
TestBoolean_Run_IMP(TestBoolean *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 12);

    // Destroying the singletons should have no effect.
    Bool_Destroy(CFISH_TRUE);
    Bool_Destroy(CFISH_FALSE);

    test_singleton(runner);
    test_To_String(runner);
    test_accessors(runner);
    test_Equals_and_Compare_To(runner);
    test_Clone(runner);
}


