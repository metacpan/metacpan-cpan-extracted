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
#define CFC_NEED_PERLSUB_STRUCT_DEF
#include "CFCPerlSub.h"
#include "CFCBase.h"
#include "CFCFunction.h"
#include "CFCUtil.h"
#include "CFCParamList.h"
#include "CFCPerlTypeMap.h"
#include "CFCVariable.h"
#include "CFCType.h"

#ifndef true
    #define true 1
    #define false 0
#endif

static char*
S_arg_assignment(CFCVariable *var, const char *val,
                 const char *stack_location);

CFCPerlSub*
CFCPerlSub_init(CFCPerlSub *self, CFCParamList *param_list,
                const char *class_name, const char *alias,
                int use_labeled_params) {
    CFCUTIL_NULL_CHECK(param_list);
    CFCUTIL_NULL_CHECK(class_name);
    CFCUTIL_NULL_CHECK(alias);
    self->param_list  = (CFCParamList*)CFCBase_incref((CFCBase*)param_list);
    self->class_name  = CFCUtil_strdup(class_name);
    self->alias       = CFCUtil_strdup(alias);
    self->use_labeled_params = use_labeled_params;
    self->perl_name = CFCUtil_sprintf("%s::%s", class_name, alias);

    size_t c_name_len = strlen(self->perl_name) + sizeof("XS_") + 1;
    self->c_name = (char*)MALLOCATE(c_name_len);
    size_t j = 3;
    memcpy(self->c_name, "XS_", j);
    for (size_t i = 0, max = strlen(self->perl_name); i < max; i++) {
        char c = self->perl_name[i];
        if (c == ':') {
            while (self->perl_name[i + 1] == ':') { i++; }
            self->c_name[j++] = '_';
        }
        else {
            self->c_name[j++] = c;
        }
    }
    self->c_name[j] = 0; // NULL-terminate.

    return self;
}

void
CFCPerlSub_destroy(CFCPerlSub *self) {
    CFCBase_decref((CFCBase*)self->param_list);
    FREEMEM(self->class_name);
    FREEMEM(self->alias);
    FREEMEM(self->perl_name);
    FREEMEM(self->c_name);
    CFCBase_destroy((CFCBase*)self);
}

char*
CFCPerlSub_arg_declarations(CFCPerlSub *self, int first) {
    CFCParamList *param_list = self->param_list;
    CFCVariable **arg_vars   = CFCParamList_get_variables(param_list);
    int           num_vars   = CFCParamList_num_vars(param_list);
    char         *decls      = CFCUtil_strdup("");

    // Declare variables.
    for (int i = first; i < num_vars; i++) {
        CFCVariable *arg_var  = arg_vars[i];
        CFCType     *type     = CFCVariable_get_type(arg_var);
        const char  *type_str = CFCType_to_c(type);
        const char  *var_name = CFCVariable_get_name(arg_var);
        decls = CFCUtil_cat(decls, "    ", type_str, " arg_", var_name,
                            ";\n", NULL);
    }

    return decls;
}

char*
CFCPerlSub_arg_name_list(CFCPerlSub *self) {
    CFCParamList  *param_list = self->param_list;
    CFCVariable  **arg_vars   = CFCParamList_get_variables(param_list);
    int            num_vars   = CFCParamList_num_vars(param_list);
    char          *name_list  = CFCUtil_strdup("");

    for (int i = 0; i < num_vars; i++) {
        const char *var_name = CFCVariable_get_name(arg_vars[i]);
        if (i > 0) {
            name_list = CFCUtil_cat(name_list, ", ", NULL);
        }
        name_list = CFCUtil_cat(name_list, "arg_", var_name, NULL);
    }

    return name_list;
}

char*
CFCPerlSub_build_param_specs(CFCPerlSub *self, int first) {
    CFCParamList  *param_list = self->param_list;
    CFCVariable  **arg_vars   = CFCParamList_get_variables(param_list);
    const char   **arg_inits  = CFCParamList_get_initial_values(param_list);
    int            num_vars   = CFCParamList_num_vars(param_list);

    const char *pattern
        = "    static const XSBind_ParamSpec param_specs[%d] = {";
    char *param_specs = CFCUtil_sprintf(pattern, num_vars - first);

    // Iterate over args in param list.
    for (int i = first; i < num_vars; i++) {
        if (i != first) {
            param_specs = CFCUtil_cat(param_specs, ",", NULL);
        }

        CFCVariable *var  = arg_vars[i];
        const char  *val  = arg_inits[i];
        const char  *name = CFCVariable_get_name(var);
        int required = val ? 0 : 1;

        char *spec = CFCUtil_sprintf("XSBIND_PARAM(\"%s\", %d)", name,
                                     required);
        param_specs = CFCUtil_cat(param_specs, "\n        ", spec, NULL);
        FREEMEM(spec);
    }

    param_specs = CFCUtil_cat(param_specs, "\n    };\n", NULL);

    return param_specs;
}

char*
CFCPerlSub_arg_assignments(CFCPerlSub *self) {
    CFCParamList  *param_list = self->param_list;
    CFCVariable  **arg_vars   = CFCParamList_get_variables(param_list);
    const char   **arg_inits  = CFCParamList_get_initial_values(param_list);
    int            num_vars   = CFCParamList_num_vars(param_list);

    char *arg_assigns = CFCUtil_strdup("");

    for (int i = 1; i < num_vars; i++) {
        char stack_location[30];
        if (self->use_labeled_params) {
            sprintf(stack_location, "locations[%d]", i - 1);
        }
        else {
            sprintf(stack_location, "%d", i);
        }
        char *statement = S_arg_assignment(arg_vars[i], arg_inits[i],
                                           stack_location);
        arg_assigns = CFCUtil_cat(arg_assigns, statement, NULL);
        FREEMEM(statement);
    }

    return arg_assigns;
}

static char*
S_arg_assignment(CFCVariable *var, const char *val,
                 const char *stack_location) {
    const char *var_name  = CFCVariable_get_name(var);
    CFCType    *var_type  = CFCVariable_get_type(var);
    char       *statement = NULL;

    char *conversion = CFCPerlTypeMap_from_perl(var_type, "sv", var_name);
    if (!conversion) {
        const char *type_c = CFCType_to_c(var_type);
        CFCUtil_die("Can't map type '%s'", type_c);
    }

    if (val) {
        if (CFCType_is_object(var_type)) {
            const char pattern[] = "    arg_%s = %s < items ? %s : %s;\n";
            statement = CFCUtil_sprintf(pattern, var_name, stack_location,
                                        conversion, val);
        }
        else {
            const char pattern[] =
                "    arg_%s = %s < items && XSBind_sv_defined(aTHX_ sv)\n"
                "             ? %s : %s;\n";
            statement = CFCUtil_sprintf(pattern, var_name, stack_location,
                                        conversion, val);
        }
    }
    else {
        if (CFCType_is_object(var_type)) {
            const char pattern[] = "    arg_%s = %s;\n";
            statement = CFCUtil_sprintf(pattern, var_name, conversion);
        }
        else {
            const char pattern[] =
                "    if (!XSBind_sv_defined(aTHX_ sv)) {\n"
                "        XSBind_undef_arg_error(aTHX_ \"%s\");\n"
                "    }\n"
                "    arg_%s = %s;\n";
            statement = CFCUtil_sprintf(pattern, var_name, var_name,
                                        conversion);
        }
    }

    const char pattern[] =
        "    sv = ST(%s);\n"
        "%s";
    char *retval = CFCUtil_sprintf(pattern, stack_location, statement);

    FREEMEM(conversion);
    FREEMEM(statement);
    return retval;
}

CFCParamList*
CFCPerlSub_get_param_list(CFCPerlSub *self) {
    return self->param_list;
}

const char*
CFCPerlSub_get_class_name(CFCPerlSub *self) {
    return self->class_name;
}

const char*
CFCPerlSub_get_alias(CFCPerlSub *self) {
    return self->alias;
}

int
CFCPerlSub_use_labeled_params(CFCPerlSub *self) {
    return self->use_labeled_params;
}

const char*
CFCPerlSub_perl_name(CFCPerlSub *self) {
    return self->perl_name;
}

const char*
CFCPerlSub_c_name(CFCPerlSub *self) {
    return self->c_name;
}

const char*
CFCPerlSub_c_name_list(CFCPerlSub *self) {
    return CFCParamList_name_list(self->param_list);
}

