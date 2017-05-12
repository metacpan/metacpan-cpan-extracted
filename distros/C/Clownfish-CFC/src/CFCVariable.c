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
#include <string.h>

#ifndef true
  #define true 1
  #define false 0
#endif

#define CFC_NEED_SYMBOL_STRUCT_DEF
#include "CFCClass.h"
#include "CFCSymbol.h"
#include "CFCVariable.h"
#include "CFCParcel.h"
#include "CFCType.h"
#include "CFCUtil.h"

struct CFCVariable {
    struct CFCSymbol symbol;
    CFCType *type;
    char *local_c;
    char *global_c;
    char *local_dec;
    int   inert;
};

static const CFCMeta CFCVARIABLE_META = {
    "Clownfish::CFC::Model::Variable",
    sizeof(CFCVariable),
    (CFCBase_destroy_t)CFCVariable_destroy
};

static void
S_generate_c_strings(CFCVariable *self);

CFCVariable*
CFCVariable_new(const char *exposure, const char *name, struct CFCType *type,
                int inert) {
    CFCVariable *self = (CFCVariable*)CFCBase_allocate(&CFCVARIABLE_META);
    return CFCVariable_init(self, exposure, name, type, inert);
}

CFCVariable*
CFCVariable_init(CFCVariable *self, const char *exposure, const char *name,
                 struct CFCType *type, int inert) {
    // Validate params.
    if (!type) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("type cannot be NULL");
    }

    // Default exposure to "local".
    const char *real_exposure = exposure ? exposure : "local";

    CFCSymbol_init((CFCSymbol*)self, real_exposure, name);

    // Assign type, inert.
    self->type = (CFCType*)CFCBase_incref((CFCBase*)type);
    self->inert = !!inert;

    self->local_c   = NULL;
    self->local_dec = NULL;
    self->global_c  = NULL;

    return self;
}

void
CFCVariable_resolve_type(CFCVariable *self) {
    CFCType_resolve(self->type);
}

void
CFCVariable_destroy(CFCVariable *self) {
    CFCBase_decref((CFCBase*)self->type);
    FREEMEM(self->local_c);
    FREEMEM(self->global_c);
    FREEMEM(self->local_dec);
    CFCSymbol_destroy((CFCSymbol*)self);
}

int
CFCVariable_equals(CFCVariable *self, CFCVariable *other) {
    if (!CFCType_equals(self->type, other->type)) { return false; }
    return CFCSymbol_equals((CFCSymbol*)self, (CFCSymbol*)other);
}

// Cache various C string representations.
static void
S_generate_c_strings(CFCVariable *self) {
    const char *type_str = CFCType_to_c(self->type);
    const char *postfix  = "";
    if (CFCType_is_composite(self->type)
        && CFCType_get_array(self->type) != NULL
       ) {
        postfix = CFCType_get_array(self->type);
    }
    const char *name = CFCVariable_get_name(self);
    self->local_c = CFCUtil_sprintf("%s %s%s", type_str, name, postfix);
    self->local_dec = CFCUtil_sprintf("%s;", self->local_c);
}

CFCType*
CFCVariable_get_type(CFCVariable *self) {
    return self->type;
}

int
CFCVariable_inert(CFCVariable *self) {
    return self->inert;
}

const char*
CFCVariable_local_c(CFCVariable *self) {
    if (!self->local_c) { S_generate_c_strings(self); }
    return self->local_c;
}

char*
CFCVariable_global_c(CFCVariable *self, CFCClass *klass) {
    const char *type_str = CFCType_to_c(self->type);
    const char *postfix  = "";
    if (CFCType_is_composite(self->type)
        && CFCType_get_array(self->type) != NULL
       ) {
        postfix = CFCType_get_array(self->type);
    }

    char *full_sym = CFCVariable_full_sym(self, klass);
    char *global_c = CFCUtil_sprintf("%s %s%s", type_str, full_sym, postfix);

    FREEMEM(full_sym);
    return global_c;
}

const char*
CFCVariable_local_declaration(CFCVariable *self) {
    if (!self->local_dec) { S_generate_c_strings(self); }
    return self->local_dec;
}

const char*
CFCVariable_get_name(CFCVariable *self) {
    return CFCSymbol_get_name((CFCSymbol*)self);
}

char*
CFCVariable_short_sym(CFCVariable *self, CFCClass *klass) {
    return CFCSymbol_short_sym((CFCSymbol*)self, klass);
}

char*
CFCVariable_full_sym(CFCVariable *self, CFCClass *klass) {
    return CFCSymbol_full_sym((CFCSymbol*)self, klass);
}

