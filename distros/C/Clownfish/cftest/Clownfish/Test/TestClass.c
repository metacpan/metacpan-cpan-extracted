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

#define C_CFISH_BOOLEAN
#define C_CFISH_CLASS
#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include "charmony.h"

#include <string.h>

#include "Clownfish/Test/TestClass.h"

#include "Clownfish/Boolean.h"
#include "Clownfish/Class.h"
#include "Clownfish/Method.h"
#include "Clownfish/String.h"
#include "Clownfish/TestHarness/TestBatchRunner.h"
#include "Clownfish/Util/Memory.h"
#include "Clownfish/Vector.h"

TestClass*
TestClass_new() {
    return (TestClass*)Class_Make_Obj(TESTCLASS);
}

#if DEBUG_CLASS_CONTENTS

#include <stdio.h>

static void
S_memdump(void *vptr, size_t size) {
    unsigned char *ptr = (unsigned char*)vptr;
    for (size_t i = 0; i < size; i++) {
        printf("%02X ", ptr[i]);
    }
    printf("\n");
}

#endif /* DEBUG_CLASS_CONTENTS */

static void
test_bootstrap_idempotence(TestBatchRunner *runner) {
    Class    *bool_class        = BOOLEAN;
    uint32_t  bool_class_size   = BOOLEAN->class_alloc_size;
#if 0
    uint32_t  bool_ivars_offset = cfish_Bool_IVARS_OFFSET;
#endif
    Boolean  *true_singleton    = Bool_true_singleton;

    char *bool_class_contents = (char*)MALLOCATE(bool_class_size);
    memcpy(bool_class_contents, BOOLEAN, bool_class_size);

    // Force another bootstrap run.
    cfish_bootstrap_internal(1);

#if DEBUG_CLASS_CONTENTS
    printf("Before\n");
    S_memdump(bool_class_contents, bool_class_size);
    printf("After\n");
    S_memdump(BOOLEAN, bool_class_size);
#endif

    TEST_TRUE(runner, bool_class == BOOLEAN,
              "Boolean class pointer unchanged");
    TEST_TRUE(runner,
              memcmp(bool_class_contents, BOOLEAN, bool_class_size) == 0,
              "Boolean class unchanged");
#if 0
    TEST_TRUE(runner, bool_ivars_offset == cfish_Bool_IVARS_OFFSET,
              "Boolean ivars offset unchanged");
#else
    SKIP(runner, 1, "TODO: Make ivars offset accessible somehow?");
#endif
    TEST_TRUE(runner, true_singleton == Bool_true_singleton,
              "Boolean singleton unchanged");

    FREEMEM(bool_class_contents);
}

static String*
MyObj_To_String_IMP(Obj *self) {
    UNUSED_VAR(self);
    return Str_newf("delta");
}

static void
test_simple_subclass(TestBatchRunner *runner) {
    String *class_name = SSTR_WRAP_C("Clownfish::Test::MyObj");
    Class *subclass = Class_singleton(class_name, OBJ);

    TEST_TRUE(runner, Str_Equals(Class_Get_Name(subclass), (Obj*)class_name),
              "Get_Name");
    TEST_TRUE(runner, Class_Get_Parent(subclass) == OBJ, "Get_Parent");

    Obj *obj = Class_Make_Obj(subclass);
    TEST_TRUE(runner, Obj_is_a(obj, subclass), "Make_Obj");

    Class_Override(subclass, (cfish_method_t)MyObj_To_String_IMP,
                   CFISH_Obj_To_String_OFFSET);
    String *str = Obj_To_String(obj);
    TEST_TRUE(runner, Str_Equals_Utf8(str, "delta", 5), "Override");
    DECREF(str);

    DECREF(obj);
}

static void
test_add_alias_to_registry(TestBatchRunner *runner) {
    static const char alias[] = "Clownfish::Test::ObjAlias";
    bool added;

    added = Class_add_alias_to_registry(OBJ, alias, sizeof(alias) - 1);
    TEST_TRUE(runner, added, "add_alias_to_registry returns true");
    Class *klass = Class_fetch_class(SSTR_WRAP_C(alias));
    TEST_TRUE(runner, klass == OBJ, "add_alias_to_registry works");

    added = Class_add_alias_to_registry(CLASS, alias, sizeof(alias) - 1);
    TEST_FALSE(runner, added, "add_alias_to_registry returns false");
}

static void
test_Get_Methods(TestBatchRunner *runner) {
    Vector *methods = Class_Get_Methods(OBJ);
    Method *destroy = NULL;

    for (size_t i = 0, size = Vec_Get_Size(methods); i < size; i++) {
        Method *method = (Method*)Vec_Fetch(methods, i);

        if (Str_Equals_Utf8(Method_Get_Name(method), "Destroy", 7)) {
            destroy = method;
        }
    }

    TEST_TRUE(runner, destroy != NULL, "Destroy method found");

    DECREF(methods);
}

void
TestClass_Run_IMP(TestClass *self, TestBatchRunner *runner) {
    TestBatchRunner_Plan(runner, (TestBatch*)self, 12);
    test_bootstrap_idempotence(runner);
    test_simple_subclass(runner);
    test_add_alias_to_registry(runner);
    test_Get_Methods(runner);
}

