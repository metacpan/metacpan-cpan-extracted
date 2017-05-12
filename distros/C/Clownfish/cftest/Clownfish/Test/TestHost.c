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

#include "Clownfish/Test/TestHost.h"
#include "Clownfish/Class.h"
#include "Clownfish/String.h"

TestHost*
TestHost_new() {
    return (TestHost*)Class_Make_Obj(TESTHOST);
}

Obj*
TestHost_Test_Obj_Pos_Arg_IMP(TestHost *self, Obj *arg) {
    UNUSED_VAR(self);
    return arg;
}

Obj*
TestHost_Test_Obj_Pos_Arg_Def_IMP(TestHost *self, Obj *arg) {
    UNUSED_VAR(self);
    return arg;
}

Obj*
TestHost_Test_Obj_Label_Arg_IMP(TestHost *self, Obj *arg, bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

Obj*
TestHost_Test_Obj_Label_Arg_Def_IMP(TestHost *self, Obj *arg, bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

int32_t
TestHost_Test_Int32_Pos_Arg_IMP(TestHost *self, int32_t arg) {
    UNUSED_VAR(self);
    return arg;
}

int32_t
TestHost_Test_Int32_Pos_Arg_Def_IMP(TestHost *self, int32_t arg) {
    UNUSED_VAR(self);
    return arg;
}

int32_t
TestHost_Test_Int32_Label_Arg_IMP(TestHost *self, int32_t arg, bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

int32_t
TestHost_Test_Int32_Label_Arg_Def_IMP(TestHost *self, int32_t arg,
                                      bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

bool
TestHost_Test_Bool_Pos_Arg_IMP(TestHost *self, bool arg) {
    UNUSED_VAR(self);
    return arg;
}

bool
TestHost_Test_Bool_Pos_Arg_Def_IMP(TestHost *self, bool arg) {
    UNUSED_VAR(self);
    return arg;
}

bool
TestHost_Test_Bool_Label_Arg_IMP(TestHost *self, bool arg, bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

bool
TestHost_Test_Bool_Label_Arg_Def_IMP(TestHost *self, bool arg, bool unused) {
    UNUSED_VAR(self);
    UNUSED_VAR(unused);
    return arg;
}

void
TestHost_Invoke_Invalid_Callback_From_C_IMP(TestHost *self) {
    TestHost_Invalid_Callback(self);
}

String*
TestHost_Aliased_IMP(TestHost *self) {
    UNUSED_VAR(self);
    return Str_newf("C");
}

String*
TestHost_Invoke_Aliased_From_C_IMP(TestHost *self) {
    UNUSED_VAR(self);
    return TestHost_Aliased(self);
}


