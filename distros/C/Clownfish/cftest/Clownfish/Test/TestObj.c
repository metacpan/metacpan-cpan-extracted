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

#include <stdio.h>

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include "charmony.h"

#include "Clownfish/Test/TestObj.h"

#include "Clownfish/String.h"
#include "Clownfish/Err.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/Class.h"

TestObj*
TestObj_new() {
    return (TestObj*)Class_Make_Obj(TESTOBJ);
}

static Obj*
S_new_testobj() {
    String *class_name = SSTR_WRAP_C("TestObj");
    Obj *obj;
    Class *klass = Class_fetch_class(class_name);
    if (!klass) {
        klass = Class_singleton(class_name, OBJ);
    }
    obj = Class_Make_Obj(klass);
    return Obj_init(obj);
}

static void
test_refcounts(TestBatchRunner *runner) {
    Obj *obj = S_new_testobj();

    TEST_INT_EQ(runner, CFISH_REFCOUNT_NN(obj), 1,
                "Correct starting refcount");

    obj = CFISH_INCREF_NN(obj);
    TEST_INT_EQ(runner, CFISH_REFCOUNT_NN(obj), 2, "INCREF_NN");

    CFISH_DECREF_NN(obj);
    TEST_INT_EQ(runner, CFISH_REFCOUNT_NN(obj), 1, "DECREF_NN");

    DECREF(obj);
}

static void
test_To_String(TestBatchRunner *runner) {
    Obj *testobj = S_new_testobj();
    String *string = Obj_To_String(testobj);
    TEST_TRUE(runner, Str_Contains_Utf8(string, "TestObj", 7), "To_String");
    DECREF(string);
    DECREF(testobj);
}

static void
test_Equals(TestBatchRunner *runner) {
    Obj *testobj = S_new_testobj();
    Obj *other   = S_new_testobj();

    TEST_TRUE(runner, Obj_Equals(testobj, testobj),
              "Equals is true for the same object");
    TEST_FALSE(runner, Obj_Equals(testobj, other),
               "Distinct objects are not equal");

    DECREF(testobj);
    DECREF(other);
}

static void
test_is_a(TestBatchRunner *runner) {
    String *string     = Str_new_from_trusted_utf8("", 0);
    Class  *str_class  = Str_get_class(string);
    String *class_name = Str_get_class_name(string);

    TEST_TRUE(runner, Str_is_a(string, STRING), "String is_a String.");
    TEST_TRUE(runner, Str_is_a(string, OBJ), "String is_a Obj.");
    TEST_TRUE(runner, str_class == STRING, "get_class");
    TEST_TRUE(runner, Str_Equals(Class_Get_Name(STRING), (Obj*)class_name),
              "get_class_name");
    TEST_FALSE(runner, Obj_is_a(NULL, OBJ), "NULL is not an Obj");

    DECREF(string);
}

static void
S_attempt_init(void *context) {
    Obj_init((Obj*)context);
}

static void
S_attempt_Clone(void *context) {
    Obj_Clone((Obj*)context);
}

static void
S_attempt_Compare_To(void *context) {
    Obj_Compare_To((Obj*)context, (Obj*)context);
}

static void
S_verify_abstract_error(TestBatchRunner *runner, Err_Attempt_t routine,
                        void *context, const char *name) {
    char message[100];
    sprintf(message, "%s() is abstract", name);
    Err *error = Err_trap(routine, context);
    TEST_TRUE(runner, error != NULL
              && Err_is_a(error, ERR)
              && Str_Contains_Utf8(Err_Get_Mess(error), "bstract", 7),
              message);
    DECREF(error);
}

static void
test_abstract_routines(TestBatchRunner *runner) {
    Obj *blank = Class_Make_Obj(OBJ);
    S_verify_abstract_error(runner, S_attempt_init, blank, "init");

    Obj *obj = S_new_testobj();
    S_verify_abstract_error(runner, S_attempt_Clone,      obj, "Clone");
    S_verify_abstract_error(runner, S_attempt_Compare_To, obj, "Compare_To");
    DECREF(obj);
}

void
TestObj_Run_IMP(TestObj *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 14);
    test_refcounts(runner);
    test_To_String(runner);
    test_Equals(runner);
    test_is_a(runner);
    test_abstract_routines(runner);
}

