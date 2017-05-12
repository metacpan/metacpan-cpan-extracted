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

#include <math.h>

#include "charmony.h"

#include "Clownfish/Test/TestNum.h"

#include "Clownfish/Err.h"
#include "Clownfish/String.h"
#include "Clownfish/Num.h"
#include "Clownfish/Test.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Class.h"

TestNum*
TestNum_new() {
    return (TestNum*)Class_Make_Obj(TESTNUM);
}

static void
test_To_String(TestBatchRunner *runner) {
    Float   *f64 = Float_new(1.33);
    Integer *i64 = Int_new(INT64_MAX);
    String *f64_string = Float_To_String(f64);
    String *i64_string = Int_To_String(i64);

    TEST_TRUE(runner, Str_Starts_With_Utf8(f64_string, "1.3", 3),
              "Float_To_String");
    TEST_TRUE(runner, Str_Equals_Utf8(i64_string, "9223372036854775807", 19),
              "Int_To_String");

    DECREF(i64_string);
    DECREF(f64_string);
    DECREF(i64);
    DECREF(f64);
}

static void
S_float_to_i64(void *context) {
    Float *f = (Float*)context;
    Float_To_I64(f);
}

static void
test_accessors(TestBatchRunner *runner) {
    Float   *f64 = Float_new(1.33);
    Integer *i64 = Int_new(INT64_MIN);
    double wanted64 = 1.33;
    double got64;

    got64 = Float_Get_Value(f64);
    TEST_TRUE(runner, *(int64_t*)&got64 == *(int64_t*)&wanted64,
              "F64 Get_Value");
    TEST_TRUE(runner, Float_To_I64(f64) == 1, "Float_To_I64");

    {
        Float *huge = Float_new(1e40);
        Err *error = Err_trap(S_float_to_i64, huge);
        TEST_TRUE(runner, error != NULL,
                  "Float_To_I64 throws when out of range (+)");
        DECREF(error);
        DECREF(huge);
    }

    {
        Float *huge = Float_new(-1e40);
        Err *error = Err_trap(S_float_to_i64, huge);
        TEST_TRUE(runner, error != NULL,
                  "Float_To_I64 throws when out of range (-)");
        DECREF(error);
        DECREF(huge);
    }

    TEST_TRUE(runner, Int_Get_Value(i64) == INT64_MIN, "I64 Get_Value");
    TEST_TRUE(runner, Int_To_F64(i64) == -9223372036854775808.0, "Int_To_F64");

    DECREF(i64);
    DECREF(f64);
}

static void
S_test_compare_float_int(TestBatchRunner *runner, double f64_val,
                         int64_t i64_val, int32_t result) {
    Float *f64;
    Integer *i64;

    f64 = Float_new(f64_val);
    i64 = Int_new(i64_val);
    TEST_INT_EQ(runner, Float_Compare_To(f64, (Obj*)i64), result,
                "Float_Compare_To %f %" PRId64, f64_val, i64_val);
    TEST_INT_EQ(runner, Int_Compare_To(i64, (Obj*)f64), -result,
                "Int_Compare_To %" PRId64" %f", i64_val, f64_val);
    TEST_INT_EQ(runner, Float_Equals(f64, (Obj*)i64), result == 0,
                "Float_Equals %f %" PRId64, f64_val, i64_val);
    TEST_INT_EQ(runner, Int_Equals(i64, (Obj*)f64), result == 0,
                "Int_Equals %" PRId64 " %f", i64_val, f64_val);
    DECREF(f64);
    DECREF(i64);

    if (i64_val == INT64_MIN) { return; }

    f64 = Float_new(-f64_val);
    i64 = Int_new(-i64_val);
    TEST_INT_EQ(runner, Float_Compare_To(f64, (Obj*)i64), -result,
                "Float_Compare_To %f %" PRId64, -f64_val, -i64_val);
    TEST_INT_EQ(runner, Int_Compare_To(i64, (Obj*)f64), result,
                "Int_Compare_To %" PRId64" %f", -i64_val, -f64_val);
    TEST_INT_EQ(runner, Float_Equals(f64, (Obj*)i64), result == 0,
                "Float_Equals %f %" PRId64, -f64_val, -i64_val);
    TEST_INT_EQ(runner, Int_Equals(i64, (Obj*)f64), result == 0,
                "Int_Equals %" PRId64 " %f", -i64_val, -f64_val);
    DECREF(f64);
    DECREF(i64);
}

static void
S_float_compare_to(void *context) {
    Float *f = (Float*)context;
    Float_Compare_To(f, (Obj*)OBJ);
}

static void
S_int_compare_to(void *context) {
    Integer *i = (Integer*)context;
    Int_Compare_To(i, (Obj*)OBJ);
}

static void
test_Equals_and_Compare_To(TestBatchRunner *runner) {
    {
        Float *f1 = Float_new(1.0);
        Float *f2 = Float_new(1.0);
        TEST_TRUE(runner, Float_Compare_To(f1, (Obj*)f2) == 0,
                  "Float_Compare_To equal");
        TEST_TRUE(runner, Float_Equals(f1, (Obj*)f2),
                  "Float_Equals equal");
        DECREF(f1);
        DECREF(f2);
    }

    {
        Float *f1 = Float_new(1.0);
        Float *f2 = Float_new(2.0);
        TEST_TRUE(runner, Float_Compare_To(f1, (Obj*)f2) < 0,
                  "Float_Compare_To less than");
        TEST_FALSE(runner, Float_Equals(f1, (Obj*)f2),
                   "Float_Equals less than");
        DECREF(f1);
        DECREF(f2);
    }

    {
        Float *f1 = Float_new(1.0);
        Float *f2 = Float_new(0.0);
        TEST_TRUE(runner, Float_Compare_To(f1, (Obj*)f2) > 0,
                  "Float_Compare_To greater than");
        TEST_FALSE(runner, Float_Equals(f1, (Obj*)f2),
                   "Float_Equals greater than");
        DECREF(f1);
        DECREF(f2);
    }

    {
        Float *f = Float_new(1.0);
        Err *error = Err_trap(S_float_compare_to, f);
        TEST_TRUE(runner, error != NULL,
                  "Float_Compare_To with invalid type throws");
        TEST_FALSE(runner, Float_Equals(f, (Obj*)OBJ),
                   "Float_Equals with different type");
        DECREF(error);
        DECREF(f);
    }

    {
        Integer *i1 = Int_new(INT64_C(0x6666666666666666));
        Integer *i2 = Int_new(INT64_C(0x6666666666666666));
        TEST_TRUE(runner, Int_Compare_To(i1, (Obj*)i2) == 0,
                  "Int_Compare_To equal");
        TEST_TRUE(runner, Int_Equals(i1, (Obj*)i2),
                  "Int_Equals equal");
        DECREF(i1);
        DECREF(i2);
    }

    {
        Integer *i1 = Int_new(INT64_C(0x6666666666666666));
        Integer *i2 = Int_new(INT64_C(0x6666666666666667));
        TEST_TRUE(runner, Int_Compare_To(i1, (Obj*)i2) < 0,
                  "Int_Compare_To less than");
        TEST_FALSE(runner, Int_Equals(i1, (Obj*)i2),
                   "Int_Equals less than");
        DECREF(i1);
        DECREF(i2);
    }

    {
        Integer *i1 = Int_new(INT64_C(0x6666666666666666));
        Integer *i2 = Int_new(INT64_C(0x6666666666666665));
        TEST_TRUE(runner, Int_Compare_To(i1, (Obj*)i2) > 0,
                  "Int_Compare_To greater than");
        TEST_FALSE(runner, Int_Equals(i1, (Obj*)i2),
                   "Int_Equals greater than");
        DECREF(i1);
        DECREF(i2);
    }

    {
        Integer *i = Int_new(0);
        Err *error = Err_trap(S_int_compare_to, i);
        TEST_TRUE(runner, error != NULL,
                  "Int_Compare_To with invalid type throws");
        TEST_FALSE(runner, Int_Equals(i, (Obj*)OBJ),
                   "Int_Equals with different type");
        DECREF(error);
        DECREF(i);
    }

    // NOTICE: When running these tests on x86/x64, it's best to compile
    // with -ffloat-store to avoid excess FPU precision which can hide
    // implementation bugs.
    S_test_compare_float_int(runner, (double)INT64_MAX * 2.0, INT64_MAX, 1);
    S_test_compare_float_int(runner, pow(2.0, 60.0), INT64_C(1) << 60, 0);
    S_test_compare_float_int(runner, pow(2.0, 60.0), (INT64_C(1) << 60) - 1,
                             1);
    S_test_compare_float_int(runner, pow(2.0, 60.0), (INT64_C(1) << 60) + 1,
                             -1);
    S_test_compare_float_int(runner, pow(2.0, 63.0), INT64_MAX, 1);
    S_test_compare_float_int(runner, -pow(2.0, 63.0), INT64_MIN, 0);
    // -9223372036854777856.0 == nextafter(-pow(2, 63), -INFINITY)
    S_test_compare_float_int(runner, -9223372036854777856.0, INT64_MIN, -1);
    S_test_compare_float_int(runner, 1.0, 2, -1);
}

static void
test_Clone(TestBatchRunner *runner) {
    Float   *f64 = Float_new(1.33);
    Integer *i64 = Int_new(INT64_MAX);
    Float   *f64_dupe = Float_Clone(f64);
    Integer *i64_dupe = Int_Clone(i64);
    TEST_TRUE(runner, Float_Equals(f64, (Obj*)f64_dupe),
              "Float Clone");
    TEST_TRUE(runner, Int_Equals(i64, (Obj*)i64_dupe),
              "Integer Clone");
    DECREF(i64_dupe);
    DECREF(f64_dupe);
    DECREF(i64);
    DECREF(f64);
}

void
TestNum_Run_IMP(TestNum *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 82);
    test_To_String(runner);
    test_accessors(runner);
    test_Equals_and_Compare_To(runner);
    test_Clone(runner);
}


