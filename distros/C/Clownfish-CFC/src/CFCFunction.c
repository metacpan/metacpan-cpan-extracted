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

#include <string.h>

#ifndef true
    #define true 1
    #define false 0
#endif

#define CFC_NEED_CALLABLE_STRUCT_DEF
#include "CFCCallable.h"
#include "CFCFunction.h"
#include "CFCClass.h"
#include "CFCType.h"
#include "CFCParamList.h"
#include "CFCVariable.h"
#include "CFCDocuComment.h"
#include "CFCUtil.h"

struct CFCFunction {
    CFCCallable callable;
    int is_inline;
};

static const CFCMeta CFCFUNCTION_META = {
    "Clownfish::CFC::Model::Function",
    sizeof(CFCFunction),
    (CFCBase_destroy_t)CFCFunction_destroy
};

CFCFunction*
CFCFunction_new(const char *exposure, const char *name, CFCType *return_type,
                CFCParamList *param_list, CFCDocuComment *docucomment,
                int is_inline) {
    CFCFunction *self = (CFCFunction*)CFCBase_allocate(&CFCFUNCTION_META);
    return CFCFunction_init(self, exposure, name, return_type, param_list,
                            docucomment, is_inline);
}

static int
S_validate_function_name(const char *name) {
    size_t len = strlen(name);
    if (!len) { return false; }
    for (size_t i = 0; i < len; i++) {
        char c = name[i];
        if (!CFCUtil_islower(c) && !CFCUtil_isdigit(c) && c != '_') {
            return false;
        }
    }
    return true;
}

CFCFunction*
CFCFunction_init(CFCFunction *self, const char *exposure, const char *name,
                 CFCType *return_type, CFCParamList *param_list,
                 CFCDocuComment *docucomment, int is_inline) {

    if (!S_validate_function_name(name)) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("Invalid function name: '%s'", name);
    }
    CFCCallable_init((CFCCallable*)self, exposure, name, return_type,
                     param_list, docucomment);
    self->is_inline = is_inline;
    return self;
}

void
CFCFunction_resolve_types(CFCFunction *self) {
    CFCCallable_resolve_types(&self->callable);
}

void
CFCFunction_destroy(CFCFunction *self) {
    CFCCallable_destroy((CFCCallable*)self);
}

int
CFCFunction_can_be_bound(CFCFunction *self) {
    return CFCCallable_can_be_bound((CFCCallable*)self);
}

CFCType*
CFCFunction_get_return_type(CFCFunction *self) {
    return self->callable.return_type;
}

CFCParamList*
CFCFunction_get_param_list(CFCFunction *self) {
    return self->callable.param_list;
}

CFCDocuComment*
CFCFunction_get_docucomment(CFCFunction *self) {
    return self->callable.docucomment;
}

int
CFCFunction_inline(CFCFunction *self) {
    return self->is_inline;
}

int
CFCFunction_void(CFCFunction *self) {
    return CFCType_is_void(self->callable.return_type);
}

char*
CFCFunction_full_func_sym(CFCFunction *self, CFCClass *klass) {
    return CFCSymbol_full_sym((CFCSymbol*)self, klass);
}

char*
CFCFunction_short_func_sym(CFCFunction *self, CFCClass *klass) {
    return CFCSymbol_short_sym((CFCSymbol*)self, klass);
}

const char*
CFCFunction_get_name(CFCFunction *self) {
    return CFCSymbol_get_name((CFCSymbol*)self);
}

int
CFCFunction_public(CFCFunction *self) {
    return CFCSymbol_public((CFCSymbol*)self);
}

