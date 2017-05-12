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
#include <stdio.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCGoFunc.h"
#include "CFCGoMethod.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCSymbol.h"
#include "CFCType.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCGoTypeMap.h"
#include "CFCVariable.h"

#ifndef true
    #define true 1
    #define false 0
#endif

struct CFCGoMethod {
    CFCBase     base;
    CFCMethod  *method;
    char       *sig;
};

static void
S_CFCGoMethod_destroy(CFCGoMethod *self);

static const CFCMeta CFCGOMETHOD_META = {
    "Clownfish::CFC::Binding::Go::Method",
    sizeof(CFCGoMethod),
    (CFCBase_destroy_t)S_CFCGoMethod_destroy
};

CFCGoMethod*
CFCGoMethod_new(CFCMethod *method) {
    CFCGoMethod *self
        = (CFCGoMethod*)CFCBase_allocate(&CFCGOMETHOD_META);
    self->method = (CFCMethod*)CFCBase_incref((CFCBase*)method);
    self->sig    = NULL;
    return self;
}

static void
S_CFCGoMethod_destroy(CFCGoMethod *self) {
    CFCBase_decref((CFCBase*)self->method);
    FREEMEM(self->sig);
    CFCBase_destroy((CFCBase*)self);
}

CFCMethod*
CFCGoMethod_get_client(CFCGoMethod *self) {
    return self->method;
}

void
CFCGoMethod_customize(CFCGoMethod *self, const char *sig) {
    FREEMEM(self->sig);
    self->sig = CFCUtil_strdup(sig);
    if (self->method) {
        CFCMethod_exclude_from_host(self->method);
    }
}

static void
S_lazy_init_sig(CFCGoMethod *self, CFCClass *invoker) {
    if (self->sig || !self->method) {
        return;
    }

    CFCMethod *method = self->method;
    CFCParcel *parcel = CFCClass_get_parcel(invoker);
    CFCType *return_type = CFCMethod_get_return_type(method);
    char *name = CFCGoFunc_go_meth_name(CFCMethod_get_name(method),
                                        CFCMethod_public(method));
    char *go_ret_type = CFCType_is_void(return_type)
                        ? CFCUtil_strdup("")
                        : CFCGoTypeMap_go_type_name(return_type, parcel);

    // Assemble list of argument types.
    char *args = CFCUtil_strdup("");
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    for (int i = 1; vars[i] != NULL; i++) {
        CFCType *type = CFCVariable_get_type(vars[i]);
        if (i > 1) {
            args = CFCUtil_cat(args, ", ", NULL);
        }
        char *go_type = CFCGoTypeMap_go_type_name(type, parcel);
        args = CFCUtil_cat(args, go_type, NULL);
        FREEMEM(go_type);
    }

    self->sig = CFCUtil_sprintf("%s(%s) %s", name, args, go_ret_type);

    FREEMEM(args);
    FREEMEM(go_ret_type);
    FREEMEM(name);
}

const char*
CFCGoMethod_get_sig(CFCGoMethod *self, CFCClass *invoker) {
    if (self->sig) {
        return self->sig;
    }
    else if (!self->method) {
        return "";
    }
    else {
        S_lazy_init_sig(self, invoker);
        return self->sig;
    }
}

char*
CFCGoMethod_func_def(CFCGoMethod *self, CFCClass *invoker) {
    if (!self->method || CFCMethod_excluded_from_host(self->method)) {
        return CFCUtil_strdup("");
    }

    CFCMethod    *novel_method = CFCMethod_find_novel_method(self->method);
    CFCParcel    *parcel     = CFCClass_get_parcel(invoker);
    CFCParamList *param_list = CFCMethod_get_param_list(novel_method);
    CFCType      *ret_type   = CFCMethod_get_return_type(novel_method);
    char *name = CFCGoFunc_go_meth_name(CFCMethod_get_name(novel_method),
                                        CFCMethod_public(novel_method));
    char *first_line = CFCGoFunc_meth_start(parcel, name, invoker,
                                            param_list, ret_type);
    char *cfunc;
    if (CFCMethod_novel(self->method) && CFCMethod_final(self->method)) {
        cfunc = CFCUtil_strdup(CFCMethod_imp_func(self->method, invoker));
    }
    else {
        cfunc = CFCMethod_full_method_sym(novel_method, invoker);
    }

    char *cfargs = CFCGoFunc_meth_cfargs(parcel, invoker, param_list);

    char *maybe_retval;
    char *maybe_return;
    if (CFCType_is_void(ret_type)) {
        maybe_retval = CFCUtil_strdup("");
        maybe_return = CFCUtil_strdup("");
    }
    else {
        maybe_retval = CFCUtil_strdup("retvalCF := ");
        maybe_return = CFCGoFunc_return_statement(parcel, ret_type,
                                                  "retvalCF");
    }

    char pattern[] =
        "%s"
        "\t%sC.%s(%s)\n"
        "%s"
        "}\n"
        ;
    char *content = CFCUtil_sprintf(pattern, first_line, maybe_retval,
                                    cfunc, cfargs, maybe_return);

    FREEMEM(maybe_retval);
    FREEMEM(maybe_return);
    FREEMEM(cfunc);
    FREEMEM(cfargs);
    FREEMEM(first_line);
    FREEMEM(name);
    return content;
}

