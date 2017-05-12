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

#define C_CFISH_OBJ
#define C_CFISH_CLASS
#define CFISH_USE_SHORT_NAMES

#include "charmony.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "Clownfish/Obj.h"
#include "Clownfish/String.h"
#include "Clownfish/Err.h"
#include "Clownfish/Hash.h"
#include "Clownfish/Class.h"
#include "Clownfish/Util/Memory.h"

Obj*
Obj_init(Obj *self) {
    ABSTRACT_CLASS_CHECK(self, OBJ);
    return self;
}

void
Obj_Destroy_IMP(Obj *self) {
    FREEMEM(self);
}

bool
Obj_is_a(Obj *self, Class *ancestor) {
    Class *klass = self ? self->klass : NULL;

    while (klass != NULL) {
        if (klass == ancestor) {
            return true;
        }
        klass = klass->parent;
    }

    return false;
}

bool
Obj_Equals_IMP(Obj *self, Obj *other) {
    return (self == other);
}

String*
Obj_To_String_IMP(Obj *self) {
#if (CHY_SIZEOF_PTR == 4)
    return Str_newf("%o@0x%x32", Obj_get_class_name(self), self);
#elif (CHY_SIZEOF_PTR == 8)
    int64_t   iaddress   = CHY_PTR_TO_I64(self);
    uint64_t  address    = (uint64_t)iaddress;
    uint32_t  address_hi = (uint32_t)(address >> 32);
    uint32_t  address_lo = address & 0xFFFFFFFF;
    return Str_newf("%o@0x%x32%x32", Obj_get_class_name(self), address_hi,
                    address_lo);
#else
  #error "Unexpected pointer size."
#endif
}

Class*
Obj_get_class(Obj *self) {
    return self->klass;
}

String*
Obj_get_class_name(Obj *self) {
    return Class_Get_Name(self->klass);
}


