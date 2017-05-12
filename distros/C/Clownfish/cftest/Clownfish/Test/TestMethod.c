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

#include "Clownfish/Test/TestMethod.h"

#include "Clownfish/Err.h"
#include "Clownfish/Method.h"
#include "Clownfish/String.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"

TestMethod*
TestMethod_new() {
    return (TestMethod*)Class_Make_Obj(TESTMETHOD);
}

static void
S_set_host_alias(void *context) {
    Method *method = (Method*)context;
    Method_Set_Host_Alias(method, SSTR_WRAP_C("foo"));
}

static void
test_accessors(TestBatchRunner *runner) {
    String *name = SSTR_WRAP_C("Frobnicate_Widget");
    Method *method = Method_new(name, NULL, 0);

    TEST_TRUE(runner, Str_Equals(Method_Get_Name(method), (Obj*)name),
              "Get_Name");

    String *alias = SSTR_WRAP_C("host_frob");
    Method_Set_Host_Alias(method, alias);
    TEST_TRUE(runner, Str_Equals(Method_Get_Host_Alias(method), (Obj*)alias),
              "Set_Host_Alias");
    Err *error = Err_trap(S_set_host_alias, method);
    TEST_TRUE(runner, error != NULL,
              "Set_Host_Alias can't be called more than once");
    DECREF(error);

    TEST_FALSE(runner, Method_Is_Excluded_From_Host(method),
               "Is_Excluded_From_Host");

    Method_Destroy(method);
}

static void
test_lower_snake_alias(TestBatchRunner *runner) {
    String *name = SSTR_WRAP_C("Frobnicate_Widget");
    Method *method = Method_new(name, NULL, 0);

    {
        String *alias = Method_lower_snake_alias(method);
        TEST_TRUE(runner, Str_Equals_Utf8(alias, "frobnicate_widget", 17),
                  "lower_snake_alias without explicit alias");
        DECREF(alias);
    }

    {
        String *new_alias = SSTR_WRAP_C("host_frob");
        Method_Set_Host_Alias(method, new_alias);
        String *alias = Method_lower_snake_alias(method);
        TEST_TRUE(runner, Str_Equals(alias, (Obj*)new_alias),
                  "lower_snake_alias with explicit alias");
        DECREF(alias);
    }

    Method_Destroy(method);
}

void
TestMethod_Run_IMP(TestMethod *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 6);
    test_accessors(runner);
    test_lower_snake_alias(runner);
}

