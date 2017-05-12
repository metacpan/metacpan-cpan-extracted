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

#include "charmony.h"

#include "CFCGoFunc.h"
#include "CFCGoTypeMap.h"
#include "CFCBase.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCUtil.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCVariable.h"
#include "CFCType.h"

#ifndef true
    #define true 1
    #define false 0
#endif

#define GO_NAME_BUF_SIZE 128

enum {
    IS_METHOD = 1,
    IS_FUNC   = 2,
    IS_CTOR   = 3
};

char*
CFCGoFunc_go_meth_name(const char *orig, int is_public) {
    char *go_name = CFCUtil_strdup(orig);
    if (!is_public) {
        go_name[0] = CFCUtil_tolower(go_name[0]);
    }
    for (size_t i = 1, j = 1, max = strlen(go_name) + 1; i < max; i++) {
        if (go_name[i] != '_') {
            go_name[j++] = go_name[i];
        }
    }
    return go_name;
}

static char*
S_prep_start(CFCParcel *parcel, const char *name, CFCClass *invoker,
             CFCParamList *param_list, CFCType *return_type, int targ) {
    const char *clownfish_dot = CFCParcel_is_cfish(parcel)
                                ? "" : "clownfish.";
    CFCVariable **param_vars = CFCParamList_get_variables(param_list);
    const char  **default_values = CFCParamList_get_initial_values(param_list);
    char *invocant;
    char go_name[GO_NAME_BUF_SIZE];

    if (targ == IS_METHOD) {
        const char *struct_sym = CFCClass_get_struct_sym(invoker);
        CFCGoTypeMap_go_meth_receiever(struct_sym, param_list, go_name,
                                       GO_NAME_BUF_SIZE);
        invocant = CFCUtil_sprintf("(%s *%sIMP) ", go_name, struct_sym);
    }
    else {
        invocant = CFCUtil_strdup("");
    }

    char *params = CFCUtil_strdup("");
    char *converted = CFCUtil_strdup("");
    size_t start = targ == IS_METHOD ? 1 : 0;
    for (size_t i = start; param_vars[i] != NULL; i++) {
        CFCVariable *var = param_vars[i];
        CFCType *type = CFCVariable_get_type(var);
        char *go_type_name = CFCGoTypeMap_go_type_name(type, parcel);
        CFCGoTypeMap_go_arg_name(param_list, i, go_name, GO_NAME_BUF_SIZE);
        if (i > start) {
            params = CFCUtil_cat(params, ", ", NULL);
        }
        params = CFCUtil_cat(params, go_name, " ", go_type_name, NULL);
        FREEMEM(go_type_name);
    }

    // Convert certain types and defer their destruction until after the
    // Clownfish call returns.
    for (size_t i = 0; param_vars[i] != NULL; i++) {
        CFCVariable *var = param_vars[i];
        CFCType *type = CFCVariable_get_type(var);
        if (!CFCType_is_object(type)) {
            continue;
        }

        if (targ == IS_METHOD && i == 0) {
            CFCGoTypeMap_go_meth_receiever(CFCClass_get_struct_sym(invoker),
                                           param_list, go_name,
                                           GO_NAME_BUF_SIZE);
        }
        else {
            CFCGoTypeMap_go_arg_name(param_list, i, go_name, GO_NAME_BUF_SIZE);
        }

        // A parameter may be marked with the nullable modifier.  It may also
        // be nullable if it has a default value of "NULL".  (Since Go does
        // not support default values for method parameters, this is the only
        // default value we care about.)
        int nullable = CFCType_nullable(type);
        if (default_values[i] != NULL
            && strcmp(default_values[i], "NULL") == 0
           ) {
            nullable = true;
        }

        const char *class_var = NULL;
        const char *struct_name = CFCType_get_specifier(type);
        if (CFCType_cfish_obj(type)) {
            class_var = "CFISH_OBJ";
        }
        else if (CFCType_cfish_string(type)) {
            class_var = "CFISH_STRING";
        }
        else if (CFCType_cfish_vector(type)) {
            class_var = "CFISH_VECTOR";
        }
        else if (CFCType_cfish_blob(type)) {
            class_var = "CFISH_BLOB";
        }
        else if (CFCType_cfish_hash(type)) {
            class_var = "CFISH_HASH";
        }

        if (class_var == NULL || (targ == IS_METHOD && i == 0)) {
            // Just unwrap -- don't convert.
            char *unwrapped;
            if (nullable) {
                unwrapped = CFCUtil_sprintf("%sUnwrapNullable(%s)",
                                            clownfish_dot, go_name);
            }
            else {
                unwrapped = CFCUtil_sprintf("%sUnwrap(%s, \"%s\")",
                                            clownfish_dot, go_name, go_name);
            }

            if (CFCType_decremented(type)) {
                char *pattern = "unsafe.Pointer(C.cfish_incref(%s))";
                char *temp = CFCUtil_sprintf(pattern, unwrapped);
                FREEMEM(unwrapped);
                unwrapped = temp;
            }

            char *conversion
                = CFCUtil_sprintf("\t%sCF := (*C.%s)(%s)\n", go_name,
                                  struct_name, unwrapped);
            converted = CFCUtil_cat(converted, conversion, NULL);
            FREEMEM(conversion);
            FREEMEM(unwrapped);
            continue;
        }

        char pattern[] =
            "\t%sCF := (*C.%s)(%sGoToClownfish(%s, unsafe.Pointer(C.%s), %s))\n";
        char *conversion = CFCUtil_sprintf(pattern, go_name, struct_name,
                                           clownfish_dot, go_name,
                                           class_var,
                                           nullable ? "true" : "false");
        converted = CFCUtil_cat(converted, conversion, NULL);
        FREEMEM(conversion);
        if (!CFCType_decremented(type)) {
            converted = CFCUtil_cat(converted,
                                    "\tdefer C.cfish_decref(unsafe.Pointer(",
                                    go_name, "CF))\n", NULL);
        }
    }

    char *ret_type_str;
    if (CFCType_is_void(return_type)) {
        ret_type_str = CFCUtil_strdup("");
    }
    else {
        ret_type_str = CFCGoTypeMap_go_type_name(return_type, parcel);
        if (ret_type_str == NULL) {
            CFCUtil_die("Can't convert invalid type in method %s", name);
        }
    }

    char pattern[] =
        "func %s%s(%s) %s {\n"
        "%s"
    ;
    char *content = CFCUtil_sprintf(pattern, invocant, name, params,
                                    ret_type_str, converted);

    FREEMEM(invocant);
    FREEMEM(converted);
    FREEMEM(params);
    FREEMEM(ret_type_str);
    return content;
}

char*
CFCGoFunc_meth_start(CFCParcel *parcel, const char *name, CFCClass *invoker,
                     CFCParamList *param_list, CFCType *return_type) {
    return S_prep_start(parcel, name, invoker, param_list, return_type,
                        IS_METHOD);
}

char*
CFCGoFunc_ctor_start(CFCParcel *parcel, const char *name,
                     CFCParamList *param_list, CFCType *return_type) {
    return S_prep_start(parcel, name, NULL, param_list, return_type,
                        IS_CTOR);
}

static char*
S_prep_cfargs(CFCParcel *parcel, CFCClass *invoker,
              CFCParamList *param_list, int targ) {
    CHY_UNUSED_VAR(parcel);
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    char go_name[GO_NAME_BUF_SIZE];
    char *cfargs = CFCUtil_strdup("");

    for (size_t i = 0; vars[i] != NULL; i++) {
        CFCVariable *var = vars[i];
        CFCType *type = CFCVariable_get_type(var);
        if (targ == IS_METHOD && i == 0) {
            CFCGoTypeMap_go_meth_receiever(CFCClass_get_struct_sym(invoker),
                                           param_list, go_name,
                                           GO_NAME_BUF_SIZE);
        }
        else {
            CFCGoTypeMap_go_arg_name(param_list, i, go_name, GO_NAME_BUF_SIZE);
        }

        if (i > 0) {
            cfargs = CFCUtil_cat(cfargs, ", ", NULL);
        }

        if (CFCType_is_primitive(type)) {
            cfargs = CFCUtil_cat(cfargs, "C.", CFCType_get_specifier(type),
                                 "(", go_name, ")", NULL);
        }
        else if (CFCType_is_object(type)) {
            cfargs = CFCUtil_cat(cfargs, go_name, "CF", NULL);
        }
    }
    return cfargs;
}

char*
CFCGoFunc_meth_cfargs(CFCParcel *parcel, CFCClass *invoker,
                      CFCParamList *param_list) {
    return S_prep_cfargs(parcel, invoker, param_list, IS_METHOD);
}

char*
CFCGoFunc_ctor_cfargs(CFCParcel *parcel, CFCParamList *param_list) {
    return S_prep_cfargs(parcel, NULL, param_list, IS_CTOR);
}

char*
CFCGoFunc_return_statement(CFCParcel *parcel, CFCType *return_type,
                           const char *cf_retval) {
    CHY_UNUSED_VAR(cf_retval);
    const char *clownfish_dot = CFCParcel_is_cfish(parcel)
                                ? "" : "clownfish.";
    const char *maybe_decref = CFCType_incremented(return_type)
        ? "\tdefer C.cfish_decref(unsafe.Pointer(retvalCF))\n" : "";
    char *statement = NULL;

    if (CFCType_is_void(return_type)) {
        return CFCUtil_strdup("");
    }
    else {
        char *ret_type_str = CFCGoTypeMap_go_type_name(return_type, parcel);
        if (ret_type_str == NULL) {
            CFCUtil_die("Can't convert type to Go: %s",
                        CFCType_to_c(return_type));
        }

        if (CFCType_is_primitive(return_type)) {
            statement = CFCUtil_sprintf("\treturn %s(retvalCF)\n", ret_type_str);
        }
        else if (CFCType_cfish_obj(return_type)) {
            char pattern[] =
                "%s\treturn %sToGo(unsafe.Pointer(retvalCF))\n";
            statement = CFCUtil_sprintf(pattern, maybe_decref, clownfish_dot);
        }
        else if (CFCType_cfish_string(return_type)) {
            char pattern[] =
                "%s\treturn %sCFStringToGo(unsafe.Pointer(retvalCF))\n";
            statement = CFCUtil_sprintf(pattern, maybe_decref, clownfish_dot);
        }
        else if (CFCType_cfish_blob(return_type)) {
            char pattern[] =
                "%s\treturn %sBlobToGo(unsafe.Pointer(retvalCF))\n";
            statement = CFCUtil_sprintf(pattern, maybe_decref, clownfish_dot);
        }
        else if (CFCType_cfish_vector(return_type)) {
            char pattern[] =
                "%s\treturn %sVectorToGo(unsafe.Pointer(retvalCF))\n";
            statement = CFCUtil_sprintf(pattern, maybe_decref, clownfish_dot);
        }
        else if (CFCType_cfish_hash(return_type)) {
            char pattern[] =
                "%s\treturn %sHashToGo(unsafe.Pointer(retvalCF))\n";
            statement = CFCUtil_sprintf(pattern, maybe_decref, clownfish_dot);
        }
        else if (CFCType_is_object(return_type)) {
            char *go_type_name = CFCGoTypeMap_go_type_name(return_type, parcel);
            char *pattern;
            if (CFCType_incremented(return_type)) {
                if (CFCType_nullable(return_type)) {
                    pattern =
                        "\tretvalGO := %sWRAPAny(unsafe.Pointer(retvalCF))\n"
                        "\tif retvalGO == nil { return nil }\n"
                        "\treturn retvalGO.(%s)\n"
                        ;
                }
                else {
                    pattern = "\treturn %sWRAPAny(unsafe.Pointer(retvalCF)).(%s)\n";
                }
            }
            else {
                if (CFCType_nullable(return_type)) {
                    pattern =
                        "\tretvalGO := %sWRAPAny(unsafe.Pointer(C.cfish_incref(unsafe.Pointer(retvalCF))))\n"
                        "\tif retvalGO == nil { return nil }\n"
                        "\treturn retvalGO.(%s)\n"
                        ;
                }
                else {
                    pattern = "\treturn %sWRAPAny(unsafe.Pointer(C.cfish_inc_refcount(unsafe.Pointer(retvalCF)))).(%s)\n";
                }
            }
            statement = CFCUtil_sprintf(pattern, clownfish_dot, go_type_name);
            FREEMEM(go_type_name);
        }
        else {
            CFCUtil_die("Unexpected type: %s", CFCType_to_c(return_type));
        }
    }

    return statement;
}
