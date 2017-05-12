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

#ifndef true
  #define true 1
  #define false 0
#endif

#define CFC_NEED_PERLSUB_STRUCT_DEF 1
#include "CFCPerlSub.h"
#include "CFCPerlConstructor.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCParamList.h"
#include "CFCType.h"
#include "CFCVariable.h"
#include "CFCUtil.h"
#include "CFCPerlTypeMap.h"

struct CFCPerlConstructor {
    CFCPerlSub   sub;
    CFCFunction *init_func;
};

static const CFCMeta CFCPERLCONSTRUCTOR_META = {
    "Clownfish::CFC::Binding::Perl::Constructor",
    sizeof(CFCPerlConstructor),
    (CFCBase_destroy_t)CFCPerlConstructor_destroy
};

CFCPerlConstructor*
CFCPerlConstructor_new(CFCClass *klass, const char *alias,
                       const char *initializer) {
    CFCPerlConstructor *self
        = (CFCPerlConstructor*)CFCBase_allocate(&CFCPERLCONSTRUCTOR_META);
    return CFCPerlConstructor_init(self, klass, alias, initializer);
}

CFCPerlConstructor*
CFCPerlConstructor_init(CFCPerlConstructor *self, CFCClass *klass,
                        const char *alias, const char *initializer) {
    CFCUTIL_NULL_CHECK(alias);
    CFCUTIL_NULL_CHECK(klass);
    const char *class_name = CFCClass_get_name(klass);
    initializer = initializer ? initializer : "init";

    // Find the implementing function.
    self->init_func = NULL;
    CFCFunction **funcs = CFCClass_functions(klass);
    for (size_t i = 0; funcs[i] != NULL; i++) {
        CFCFunction *func = funcs[i];
        const char *func_name = CFCFunction_get_name(func);
        if (strcmp(initializer, func_name) == 0) {
            self->init_func = (CFCFunction*)CFCBase_incref((CFCBase*)func);
            break;
        }
    }
    if (!self->init_func) {
        CFCUtil_die("Missing or invalid '%s' function for '%s'",
                    initializer, class_name);
    }
    CFCParamList *param_list = CFCFunction_get_param_list(self->init_func);
    CFCPerlSub_init((CFCPerlSub*)self, param_list, class_name, alias,
                    true);
    return self;
}

void
CFCPerlConstructor_destroy(CFCPerlConstructor *self) {
    CFCBase_decref((CFCBase*)self->init_func);
    CFCPerlSub_destroy((CFCPerlSub*)self);
}

char*
CFCPerlConstructor_xsub_def(CFCPerlConstructor *self, CFCClass *klass) {
    const char    *c_name        = self->sub.c_name;
    CFCParamList  *param_list    = self->sub.param_list;
    int            num_vars      = CFCParamList_num_vars(param_list);
    CFCVariable  **arg_vars      = CFCParamList_get_variables(param_list);
    CFCVariable   *self_var      = arg_vars[0];
    CFCType       *self_type     = CFCVariable_get_type(self_var);
    const char    *self_type_str = CFCType_to_c(self_type);
    const char    *self_name     = CFCVariable_get_name(self_var);
    const char    *items_check   = NULL;

    char *param_specs = NULL;
    char *arg_decls   = CFCPerlSub_arg_declarations((CFCPerlSub*)self, 0);
    char *locs_decl   = NULL;
    char *locate_args = NULL;
    char *arg_assigns = CFCPerlSub_arg_assignments((CFCPerlSub*)self);
    char *func_sym    = CFCFunction_full_func_sym(self->init_func, klass);
    char *name_list   = CFCPerlSub_arg_name_list((CFCPerlSub*)self);

    if (num_vars <= 1) {
        // No params.
        items_check = "items != 1";
        param_specs = CFCUtil_strdup("");
        locs_decl   = CFCUtil_strdup("");
        locate_args = CFCUtil_strdup("");
    }
    else {
        int num_params = num_vars - 1;
        items_check = "items < 1";
        param_specs = CFCPerlSub_build_param_specs((CFCPerlSub*)self, 1);
        locs_decl   = CFCUtil_sprintf("    int32_t locations[%d];\n"
                                      "    SV *sv;\n",
                                      num_params);

        const char *pattern =
            "    XSBind_locate_args(aTHX_ &ST(0), 1, items, param_specs,\n"
            "                       locations, %d);\n";
        locate_args = CFCUtil_sprintf(pattern, num_params);
    }

    // Compensate for swallowed refcounts.
    char *refcount_mods = CFCUtil_strdup("");
    for (size_t i = 0; arg_vars[i] != NULL; i++) {
        CFCVariable *var = arg_vars[i];
        CFCType *type = CFCVariable_get_type(var);
        if (CFCType_is_object(type) && CFCType_decremented(type)) {
            const char *name = CFCVariable_get_name(var);
            refcount_mods
                = CFCUtil_cat(refcount_mods, "\n    CFISH_INCREF(arg_", name,
                              ");", NULL);
        }
    }

    const char pattern[] =
        "XS_INTERNAL(%s);\n"
        "XS_INTERNAL(%s) {\n"
        "    dXSARGS;\n"
        "%s" // param_specs
        "%s" // locs_decl
        "%s" // arg_decls
        "    %s retval;\n"
        "\n"
        "    CFISH_UNUSED_VAR(cv);\n"
        "    if (%s) {\n"
        "        XSBind_invalid_args_error(aTHX_ cv, \"class_name, ...\");\n"
        "    }\n"
        "    SP -= items;\n"
        "\n"
        "%s" // locate_args
        "%s" // arg_assigns
        // Create "self" last, so that earlier exceptions while fetching
        // params don't trigger a bad invocation of DESTROY.
        "    arg_%s = (%s)XSBind_new_blank_obj(aTHX_ ST(0));%s\n"
        "\n"
        "    retval = %s(%s);\n"
        "    ST(0) = sv_2mortal(CFISH_OBJ_TO_SV_NOINC(retval));\n"
        "    XSRETURN(1);\n"
        "}\n\n";
    char *xsub_def
        = CFCUtil_sprintf(pattern, c_name, c_name, param_specs, locs_decl,
                          arg_decls, self_type_str, items_check, locate_args,
                          arg_assigns, self_name, self_type_str, refcount_mods,
                          func_sym, name_list);

    FREEMEM(refcount_mods);
    FREEMEM(name_list);
    FREEMEM(func_sym);
    FREEMEM(arg_assigns);
    FREEMEM(locate_args);
    FREEMEM(locs_decl);
    FREEMEM(arg_decls);
    FREEMEM(param_specs);

    return xsub_def;
}

