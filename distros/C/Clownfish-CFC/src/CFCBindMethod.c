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
#include "CFCBindMethod.h"
#include "CFCUtil.h"
#include "CFCMethod.h"
#include "CFCFunction.h"
#include "CFCParamList.h"
#include "CFCType.h"
#include "CFCVariable.h"
#include "CFCSymbol.h"
#include "CFCClass.h"
#include "CFCParcel.h"

#ifndef true
  #define true 1
  #define false 0
#endif

static char*
S_method_def(CFCMethod *method, CFCClass *klass, int optimized_final_meth);

/* Create a method invocation routine that resolves to a function name
 * directly, since this method may not be overridden.
 */
static char*
S_optimized_final_method_def(CFCMethod *method, CFCClass *klass) {
    return S_method_def(method, klass, true);
}

/* Create a method invocation routine which uses vtable dispatch.
 */
static char*
S_virtual_method_def(CFCMethod *method, CFCClass *klass) {
    return S_method_def(method, klass, false);
}

char*
CFCBindMeth_method_def(CFCMethod *method, CFCClass *klass) {
    // If the method is final and the class where it is declared final is in
    // the same parcel as the invocant, we can optimize the call by resolving
    // to the implementing function directly.
    if (CFCMethod_final(method)) {
        CFCClass *ancestor = klass;
        while (ancestor && !CFCMethod_is_fresh(method, ancestor)) {
            ancestor = CFCClass_get_parent(ancestor);
        }
        if (CFCClass_get_parcel(ancestor) == CFCClass_get_parcel(klass)) {
            return S_optimized_final_method_def(method, klass);
        }
    }

    return S_virtual_method_def(method, klass);
}

static char*
S_method_def(CFCMethod *method, CFCClass *klass, int optimized_final_meth) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    const char *PREFIX         = CFCClass_get_PREFIX(klass);
    const char *invoker_struct = CFCClass_full_struct_sym(klass);
    const char *self_name      = CFCParamList_param_name(param_list, 0);

    char *full_meth_sym   = CFCMethod_full_method_sym(method, klass);
    char *full_offset_sym = CFCMethod_full_offset_sym(method, klass);
    char *full_typedef    = CFCMethod_full_typedef(method, klass);
    char *full_imp_sym    = CFCMethod_imp_func(method, klass);

    // Prepare parameter lists, minus the type of the invoker.
    if (CFCParamList_variadic(param_list)) {
        CFCUtil_die("Variadic methods not supported");
    }
    const char *arg_names  = CFCParamList_name_list(param_list);
    const char *params_end = CFCParamList_to_c(param_list);
    while (*params_end && *params_end != '*') {
        params_end++;
    }

    // Prepare a return statement... or not.
    CFCType *return_type = CFCMethod_get_return_type(method);
    const char *ret_type_str = CFCType_to_c(return_type);
    const char *maybe_return = CFCType_is_void(return_type) ? "" : "return ";

    const char innards_pattern[] =
        "    const %s method = (%s)cfish_obj_method(%s, %s);\n"
        "    %smethod(%s);\n"
        ;
    char *innards = CFCUtil_sprintf(innards_pattern, full_typedef,
                                    full_typedef, self_name, full_offset_sym,
                                    maybe_return, arg_names);
    if (optimized_final_meth) {
        CFCParcel  *parcel = CFCClass_get_parcel(klass);
        const char *privacy_sym = CFCParcel_get_privacy_sym(parcel);
        char *invoker_cast = CFCUtil_strdup("");
        if (!CFCMethod_is_fresh(method, klass)) {
            CFCType *self_type = CFCMethod_self_type(method);
            invoker_cast = CFCUtil_cat(invoker_cast, "(",
                                       CFCType_to_c(self_type), ")", NULL);
        }
        const char pattern[] =
            "#ifdef %s\n"
            "    %s%s(%s%s);\n"
            "#else\n"
            "%s"
            "#endif\n"
            ;
        char *temp = CFCUtil_sprintf(pattern, privacy_sym,
                                     maybe_return, full_imp_sym,
                                     invoker_cast, arg_names, innards);
        FREEMEM(innards);
        innards = temp;
        FREEMEM(invoker_cast);
    }

    const char pattern[] =
        "extern %sVISIBLE uint32_t %s;\n"
        "static CFISH_INLINE %s\n"
        "%s(%s%s) {\n"
        "%s"
        "}\n";
    char *method_def
        = CFCUtil_sprintf(pattern, PREFIX, full_offset_sym, ret_type_str,
                          full_meth_sym, invoker_struct, params_end, innards);

    FREEMEM(innards);
    FREEMEM(full_imp_sym);
    FREEMEM(full_offset_sym);
    FREEMEM(full_meth_sym);
    FREEMEM(full_typedef);
    return method_def;
}

char*
CFCBindMeth_typedef_dec(struct CFCMethod *method, CFCClass *klass) {
    const char *params_end
        = CFCParamList_to_c(CFCMethod_get_param_list(method));
    while (*params_end && *params_end != '*') {
        params_end++;
    }
    const char *self_struct = CFCClass_full_struct_sym(klass);
    const char *ret_type = CFCType_to_c(CFCMethod_get_return_type(method));
    char *full_typedef = CFCMethod_full_typedef(method, klass);
    char *buf = CFCUtil_sprintf("typedef %s\n(*%s)(%s%s);\n", ret_type,
                                full_typedef, self_struct,
                                params_end);
    FREEMEM(full_typedef);
    return buf;
}

char*
CFCBindMeth_abstract_method_def(CFCMethod *method, CFCClass *klass) {
    CFCType    *ret_type      = CFCMethod_get_return_type(method);
    const char *ret_type_str  = CFCType_to_c(ret_type);
    CFCType    *type          = CFCMethod_self_type(method);
    const char *class_var     = CFCType_get_class_var(type);
    const char *meth_name     = CFCMethod_get_name(method);
    CFCParamList *param_list  = CFCMethod_get_param_list(method);
    const char *params        = CFCParamList_to_c(param_list);
    CFCVariable **vars        = CFCParamList_get_variables(param_list);
    const char *invocant      = CFCVariable_get_name(vars[0]);

    // All variables other than the invocant are unused, and the return is
    // unreachable.
    char *unused = CFCUtil_strdup("");
    for (int i = 1; vars[i] != NULL; i++) {
        const char *var_name = CFCVariable_get_name(vars[i]);
        size_t size = strlen(unused) + strlen(var_name) + 80;
        unused = (char*)REALLOCATE(unused, size);
        strcat(unused, "\n    CFISH_UNUSED_VAR(");
        strcat(unused, var_name);
        strcat(unused, ");");
    }
    char *unreachable;
    if (!CFCType_is_void(ret_type)) {
        unreachable = CFCUtil_sprintf("    CFISH_UNREACHABLE_RETURN(%s);\n",
                                      ret_type_str);
    }
    else {
        unreachable = CFCUtil_strdup("");
    }

    char *full_func_sym = CFCMethod_imp_func(method, klass);

    char pattern[] =
        "%s\n"
        "%s(%s) {\n"
        "%s"
        "    cfish_Err_abstract_method_call((cfish_Obj*)%s, %s, \"%s\");\n"
        "%s"
        "}\n";
    char *abstract_def
        = CFCUtil_sprintf(pattern, ret_type_str, full_func_sym, params,
                          unused, invocant, class_var, meth_name,
                          unreachable);

    FREEMEM(unused);
    FREEMEM(unreachable);
    FREEMEM(full_func_sym);
    return abstract_def;
}

char*
CFCBindMeth_imp_declaration(CFCMethod *method, CFCClass *klass) {
    CFCType      *return_type    = CFCMethod_get_return_type(method);
    CFCParamList *param_list     = CFCMethod_get_param_list(method);
    const char   *ret_type_str   = CFCType_to_c(return_type);
    const char   *param_list_str = CFCParamList_to_c(param_list);

    char *full_imp_sym = CFCMethod_imp_func(method, klass);
    char *buf = CFCUtil_sprintf("%s\n%s(%s);", ret_type_str,
                                full_imp_sym, param_list_str);

    FREEMEM(full_imp_sym);
    return buf;
}

char*
CFCBindMeth_host_data_json(CFCMethod *method) {
    if (!CFCMethod_novel(method)) { return CFCUtil_strdup(""); }

    int         excluded = CFCMethod_excluded_from_host(method);
    const char *alias    = CFCMethod_get_host_alias(method);
    char       *pair     = NULL;
    char       *json     = NULL;

    if (excluded) {
        pair = CFCUtil_strdup("\"excluded\": true");
    }
    else if (alias) {
        pair = CFCUtil_sprintf("\"alias\": \"%s\"", alias);
    }

    if (pair) {
        const char *method_name = CFCMethod_get_name(method);

        const char *pattern =
            "                \"%s\": {\n"
            "                    %s\n"
            "                }";
        json = CFCUtil_sprintf(pattern, method_name, pair);

        FREEMEM(pair);
    }
    else {
        json = CFCUtil_strdup("");
    }

    return json;
}

