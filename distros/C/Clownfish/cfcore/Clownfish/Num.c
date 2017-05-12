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

#define C_CFISH_INTEGER
#define C_CFISH_FLOAT
#define CFISH_USE_SHORT_NAMES

#include <float.h>

#include "charmony.h"

#include "Clownfish/Num.h"
#include "Clownfish/String.h"
#include "Clownfish/Err.h"
#include "Clownfish/Class.h"

#if FLT_RADIX != 2
  #error Unsupported FLT_RADIX
#endif

#if DBL_MANT_DIG != 53
  #error Unsupported DBL_MANT_DIG
#endif

#define MAX_PRECISE_I64 (INT64_C(1) << DBL_MANT_DIG)
#define MIN_PRECISE_I64 -MAX_PRECISE_I64

// For floating point range checks, it's important to use constants that
// can be exactly represented as doubles. `f64 > INT64_MAX` can produce
// wrong results.
#define POW_2_63 9223372036854775808.0

static int32_t
S_compare_i64_f64(int64_t i64, double f64);

static bool
S_equals_i64_f64(int64_t i64, double f64);

Float*
Float_new(double value) {
    Float *self = (Float*)Class_Make_Obj(FLOAT);
    return Float_init(self, value);
}

Float*
Float_init(Float *self, double value) {
    self->value = value;
    return self;
}

bool
Float_Equals_IMP(Float *self, Obj *other) {
    if (Obj_is_a(other, FLOAT)) {
        Float *twin = (Float*)other;
        return self->value == twin->value;
    }
    else if (Obj_is_a(other, INTEGER)) {
        Integer *twin = (Integer*)other;
        return S_equals_i64_f64(twin->value, self->value);
    }
    else {
        return false;
    }
}

int32_t
Float_Compare_To_IMP(Float *self, Obj *other) {
    if (Obj_is_a(other, FLOAT)) {
        Float *twin = (Float*)other;
        double a = self->value;
        double b = twin->value;
        return a < b ? -1 : a > b ? 1 : 0;
    }
    else if (Obj_is_a(other, INTEGER)) {
        Integer *twin = (Integer*)other;
        return -S_compare_i64_f64(twin->value, self->value);
    }
    else {
        THROW(ERR, "Can't compare Float to %o", Obj_get_class_name(other));
        UNREACHABLE_RETURN(int32_t);
    }
}

double
Float_Get_Value_IMP(Float *self) {
    return self->value;
}

int64_t
Float_To_I64_IMP(Float *self) {
    if (self->value < -POW_2_63 || self->value >= POW_2_63) {
        THROW(ERR, "Float out of range: %f64", self->value);
    }
    return (int64_t)self->value;
}

String*
Float_To_String_IMP(Float *self) {
    return Str_newf("%f64", self->value);
}

Float*
Float_Clone_IMP(Float *self) {
    return (Float*)INCREF(self);
}

/***************************************************************************/

Integer*
Int_new(int64_t value) {
    Integer *self = (Integer*)Class_Make_Obj(INTEGER);
    return Int_init(self, value);
}

Integer*
Int_init(Integer *self, int64_t value) {
    self->value = value;
    return self;
}

bool
Int_Equals_IMP(Integer *self, Obj *other) {
    if (Obj_is_a(other, INTEGER)) {
        Integer *twin = (Integer*)other;
        return self->value == twin->value;
    }
    else if (Obj_is_a(other, FLOAT)) {
        Float *twin = (Float*)other;
        return S_equals_i64_f64(self->value, twin->value);
    }
    else {
        return false;
    }
}

int32_t
Int_Compare_To_IMP(Integer *self, Obj *other) {
    if (Obj_is_a(other, INTEGER)) {
        Integer *twin = (Integer*)other;
        int64_t a = self->value;
        int64_t b = twin->value;
        return a < b ? -1 : a > b ? 1 : 0;
    }
    else if (Obj_is_a(other, FLOAT)) {
        Float *twin = (Float*)other;
        return S_compare_i64_f64(self->value, twin->value);
    }
    else {
        THROW(ERR, "Can't compare Integer to %o", Obj_get_class_name(other));
        UNREACHABLE_RETURN(int32_t);
    }
}

int64_t
Int_Get_Value_IMP(Integer *self) {
    return self->value;
}

double
Int_To_F64_IMP(Integer *self) {
    return (double)self->value;
}

String*
Int_To_String_IMP(Integer *self) {
    return Str_newf("%i64", self->value);
}

Integer*
Int_Clone_IMP(Integer *self) {
    return (Integer*)INCREF(self);
}

static int32_t
S_compare_i64_f64(int64_t i64, double f64) {
    double i64_as_f64 = (double)i64;
    // This conversion might not be precise. If the numbers compare as
    // unequal, the result is still correct.
    if (i64_as_f64 < f64) { return -1; }
    if (i64_as_f64 > f64) { return  1; }

    // If the integer can be represented precisely as a double, the
    // numbers are equal. Testing for (i64 < MAX_PRECISE_I64) is more
    // efficient than (i64 <= MAX_PRECISE_I64) on 32-bit systems.
    if (i64 >= MIN_PRECISE_I64 && i64 < MAX_PRECISE_I64) { return 0; }

    // Otherwise, the double is an integer.

    // Corner case. 2^63 can compare equal to an int64_t although it is
    // out of range.
    if (f64 == POW_2_63) { return -1; }

    // llrint() can be faster than casting to int64_t but isn't as
    // portable.
    int64_t f64_as_i64 = (int64_t)f64;
    return i64 < f64_as_i64 ? -1 : i64 > f64_as_i64 ? 1 : 0;
}

static bool
S_equals_i64_f64(int64_t i64, double f64) {
    double i64_as_f64 = (double)i64;
    // This conversion might not be precise. If the numbers compare as
    // unequal, the result is still correct.
    if (i64_as_f64 != f64) { return false; }

    // If the integer can be represented precisely as a double, the
    // numbers are equal. Testing for (i64 < MAX_PRECISE_I64) is more
    // efficient than (i64 <= MAX_PRECISE_I64) on 32-bit systems.
    if (i64 >= MIN_PRECISE_I64 && i64 < MAX_PRECISE_I64) { return true; }

    // Otherwise, the double is an integer.

    // Corner case. 2^63 can compare equal to an int64_t although it is
    // out of range.
    if (f64 == POW_2_63) { return false; }

    // llrint() can be faster than casting to int64_t but isn't as
    // portable.
    return i64 == (int64_t)f64;
}

