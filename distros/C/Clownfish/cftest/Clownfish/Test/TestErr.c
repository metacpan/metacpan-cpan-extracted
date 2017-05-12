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

#include "Clownfish/Test/TestErr.h"

#include "Clownfish/String.h"
#include "Clownfish/Err.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"

TestErr*
TestErr_new() {
    return (TestErr*)Class_Make_Obj(TESTERR);
}

static void
test_To_String(TestBatchRunner *runner) {
    String *message = Str_newf("oops");
    Err *error = Err_new(message);
    String *string = Err_To_String(error);
    TEST_TRUE(runner, Str_Equals(message, (Obj*)string),
              "Stringifies as message");
    DECREF(string);
    DECREF(error);
}

static void
test_Cat_Mess(TestBatchRunner *runner) {
    Err *error = Err_new(Str_newf("alpha"));
    Err_Cat_Mess(error, SSTR_WRAP_C("\nbeta"));
    String *mess = Err_Get_Mess(error);
    TEST_TRUE(runner, Str_Equals_Utf8(mess, "alpha\nbeta", 10), "Cat_Mess");
    DECREF(error);
}

static void
test_Add_Frame(TestBatchRunner *runner) {
    {
        Err *error = Err_new(Str_newf("alpha"));
        Err_Add_Frame(error, "source.c", 128, "function");
        String *mess = Err_Get_Mess(error);
        const char *expected = "alpha\n\tfunction at source.c line 128\n";
        TEST_TRUE(runner, Str_Equals_Utf8(mess, expected, strlen(expected)),
                  "Add_Frame");
        DECREF(error);
    }

    {
        Err *error = Err_new(Str_newf("alpha\n"));
        Err_Add_Frame(error, "source.c", 128, "function");
        String *mess = Err_Get_Mess(error);
        const char *expected = "alpha\n\tfunction at source.c line 128\n";
        TEST_TRUE(runner, Str_Equals_Utf8(mess, expected, strlen(expected)),
                  "Add_Frame with trailing newline");
        DECREF(error);
    }

    {
        Err *error = Err_new(Str_newf("alpha"));
        Err_Add_Frame(error, "source.c", 128, NULL);
        String *mess = Err_Get_Mess(error);
        const char *expected = "alpha\n\tat source.c line 128\n";
        TEST_TRUE(runner, Str_Equals_Utf8(mess, expected, strlen(expected)),
                  "Add_Frame without func");
        DECREF(error);
    }
}

static void
S_rethrow(void *context) {
    Err *error = (Err*)context;
    Err_rethrow(error, "src.c", 12, "fn");
}

static void
test_rethrow(TestBatchRunner *runner) {
    Err *error = Err_new(Str_newf("error"));
    Err *rethrown = Err_trap(S_rethrow, error);
    String *mess = Err_Get_Mess(rethrown);
    const char *expected = "error\n\tfn at src.c line 12\n";
    TEST_TRUE(runner, Str_Starts_With_Utf8(mess, expected, strlen(expected)),
              "rethrow");
    DECREF(error);
}

static void
S_invalid_downcast(void *context) {
    Obj *obj = (Obj*)context;
    DOWNCAST(obj, ERR);
}

static void
test_downcast(TestBatchRunner *runner) {
    Obj *obj = (Obj*)Str_newf("gamma");

    TEST_TRUE(runner, DOWNCAST(obj, STRING) != NULL, "downcast");

    TEST_TRUE(runner, DOWNCAST(NULL, STRING) == NULL, "downcast NULL");

    Err *error = Err_trap(S_invalid_downcast, obj);
    TEST_TRUE(runner, error != NULL, "downcast throws");
    DECREF(error);

    DECREF(obj);
}

static void
S_invalid_certify(void *context) {
    Obj *obj = (Obj*)context;
    CERTIFY(obj, ERR);
}

static void
test_certify(TestBatchRunner *runner) {
    Obj *obj = (Obj*)Str_newf("epsilon");
    Err *error;

    TEST_TRUE(runner, CERTIFY(obj, STRING) != NULL, "certify");

    error = Err_trap(S_invalid_certify, NULL);
    TEST_TRUE(runner, error != NULL, "certify NULL");
    DECREF(error);

    error = Err_trap(S_invalid_certify, obj);
    TEST_TRUE(runner, error != NULL, "certify throws");
    DECREF(error);

    DECREF(obj);
}

static void
S_err_thread(void *arg) {
    TestBatchRunner *runner = (TestBatchRunner*)arg;

    TEST_TRUE(runner, Err_get_error() == NULL,
              "global error in thread initialized to null");

    Err_set_error(Err_new(Str_newf("thread")));
    String *mess = Err_Get_Mess(Err_get_error());
    TEST_TRUE(runner, Str_Equals_Utf8(mess, "thread", 6),
              "set_error in thread works");
}

static void
test_threads(TestBatchRunner *runner) {
    if (!TestUtils_has_threads) {
        SKIP(runner, 3, "no thread support");
        return;
    }

    Err_set_error(Err_new(Str_newf("main")));

    void *runtime = TestUtils_clone_host_runtime();
    Thread *thread = TestUtils_thread_create(S_err_thread, runner, runtime);
    TestUtils_thread_join(thread);
    TestUtils_destroy_host_runtime(runtime);

    String *mess = Err_Get_Mess(Err_get_error());
    TEST_TRUE(runner, Str_Equals_Utf8(mess, "main", 4),
              "thread doesn't clobber global error");
}

void
TestErr_Run_IMP(TestErr *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 15);
    test_To_String(runner);
    test_Cat_Mess(runner);
    test_Add_Frame(runner);
    test_rethrow(runner);
    test_downcast(runner);
    test_certify(runner);
    test_threads(runner);
}


