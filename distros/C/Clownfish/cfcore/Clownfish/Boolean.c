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

#include "charmony.h"

#define C_CFISH_BOOLEAN
#define CFISH_USE_SHORT_NAMES
#include "Clownfish/Boolean.h"

#include "Clownfish/Class.h"
#include "Clownfish/String.h"
#include "Clownfish/Util/Atomic.h"

Boolean *Bool_true_singleton;
Boolean *Bool_false_singleton;

void
Bool_init_class() {
    Boolean *true_obj = (Boolean*)Class_Make_Obj(BOOLEAN);
    true_obj->value   = true;
    true_obj->string  = Str_newf("true");
    if (!Atomic_cas_ptr((void**)&Bool_true_singleton, NULL, true_obj)) {
        Bool_Destroy(true_obj);
    }

    Boolean *false_obj = (Boolean*)Class_Make_Obj(BOOLEAN);
    false_obj->value   = false;
    false_obj->string  = Str_newf("false");
    if (!Atomic_cas_ptr((void**)&Bool_false_singleton, NULL, false_obj)) {
        Bool_Destroy(false_obj);
    }
}

Boolean*
Bool_singleton(bool value) {
    return value ? CFISH_TRUE : CFISH_FALSE;
}

void
Bool_Destroy_IMP(Boolean *self) {
    if (self != CFISH_TRUE && self != CFISH_FALSE) {
        DECREF(self->string);
        SUPER_DESTROY(self, BOOLEAN);
    }
}

bool
Bool_Get_Value_IMP(Boolean *self) {
    return self->value;
}

Boolean*
Bool_Clone_IMP(Boolean *self) {
    return self;
}

String*
Bool_To_String_IMP(Boolean *self) {
    return (String*)INCREF(self->string);
}

bool
Bool_Equals_IMP(Boolean *self, Obj *other) {
    return self == (Boolean*)other;
}

