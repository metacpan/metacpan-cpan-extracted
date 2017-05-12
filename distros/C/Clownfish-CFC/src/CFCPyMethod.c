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

#include "CFCPyMethod.h"
#include "CFCPyTypeMap.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCSymbol.h"
#include "CFCType.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCVariable.h"

#ifndef true
#define true  1
#define false 0
#endif

/* Take a NULL-terminated list of CFCVariables and build up a string of
 * directives like:
 *
 *     UNUSED_VAR(var1);
 *     UNUSED_VAR(var2);
 */
static char*
S_build_unused_vars(CFCVariable **vars);

/* Create an unreachable return statement if necessary, in order to thwart
 * compiler warnings. */
static char*
S_maybe_unreachable(CFCType *return_type);

static char*
S_build_py_args(CFCParamList *param_list) {
    int num_vars = CFCParamList_num_vars(param_list);
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    char pattern[] = "    PyObject *cfcb_ARGS = S_pack_tuple(%d";
    char *py_args = CFCUtil_sprintf(pattern, num_vars - 1);

    for (int i = 1; vars[i] != NULL; i++) {
        const char *var_name = CFCVariable_get_name(vars[i]);
        CFCType *type = CFCVariable_get_type(vars[i]);
        char *conversion = CFCPyTypeMap_c_to_py(type, var_name);
        py_args = CFCUtil_cat(py_args, ",\n        ", conversion, NULL);
        FREEMEM(conversion);
    }
    py_args = CFCUtil_cat(py_args, ");", NULL);

    return py_args;
}

static char*
S_gen_decs(CFCParamList *param_list, int first_tick) {
    char *decs = CFCUtil_strdup("");
    int num_vars = CFCParamList_num_vars(param_list);
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    for (int i = first_tick; i < num_vars; i++) {
        CFCType *type = CFCVariable_get_type(vars[i]);
        const char *name = CFCVariable_get_name(vars[i]);
        decs = CFCUtil_cat(decs, "    ", CFCType_to_c(type), " ", name,
                           "_ARG = 0;\n", NULL);
    }
    return decs;
}

/* Some of the ParseTuple conversion routines provided by the Python-flavored
 * CFBind module accept a CFBindArg instead of just a pointer to the value
 * itself.  This routine generates the declarations for those CFBindArg
 * variables, as well as handling some default values.
 */
static char*
S_gen_declaration(CFCVariable *var, const char *val) {
    CFCType *type = CFCVariable_get_type(var);
    const char *var_name = CFCVariable_get_name(var);
    const char *type_str = CFCType_to_c(type);
    char *result = NULL;

    if (CFCType_is_object(type)) {
        const char *specifier = CFCType_get_specifier(type);
        if (strcmp(specifier, "cfish_String") == 0) {
            if (val && strcmp(val, "NULL") != 0) {
                const char pattern[] =
                    "    const char arg_%s_DEFAULT[] = %s;\n"
                    "    %s_ARG = CFISH_SSTR_WRAP_UTF8(\n"
                    "        arg_%s_DEFAULT, sizeof(arg_%s_DEFAULT) - 1);\n"
                    ;
                result = CFCUtil_sprintf(pattern, var_name, val, var_name,
                                         var_name, var_name);
            }
        }
        else {
            if (val && strcmp(val, "NULL") != 0) {
                CFCUtil_die("Can't assign a default of '%s' to a %s",
                            val, type_str);
            }
            if (strcmp(specifier, "cfish_Hash") != 0
                && strcmp(specifier, "cfish_Vector") != 0
                ) {
                const char *class_var = CFCType_get_class_var(type);
                char pattern[] =
                    "    CFBindArg wrap_arg_%s = {%s, &%s_ARG};\n"
                    ;
                result = CFCUtil_sprintf(pattern, var_name, class_var,
                                         var_name);
            }
        }
    }
    else if (CFCType_is_primitive(type)) {
        if (val) {
            char pattern[] = "    %s_ARG = %s;\n";
            result = CFCUtil_sprintf(pattern, var_name, val);
        }
    }
    else {
        CFCUtil_die("Unexpected type, can't gen declaration: %s", type_str);
    }

    return result;
}

static char*
S_gen_target(CFCVariable *var, const char *value) {
    CFCType *type = CFCVariable_get_type(var);
    const char *specifier = CFCType_get_specifier(type);
    const char *micro_sym = CFCVariable_get_name(var);
    const char *maybe_maybe = "";
    const char *dest_name;
    char *var_name = NULL;
    if (CFCType_is_primitive(type)) {
        dest_name = CFCType_get_specifier(type);
        if (value != NULL) {
            maybe_maybe = "maybe_";
        }
        var_name = CFCUtil_sprintf("%s_ARG", CFCVariable_get_name(var));
    }
    else if (CFCType_is_object(type)) {
        if (CFCType_nullable(type) ||
            (value && strcmp(value, "NULL") == 0)
           ) {
            maybe_maybe = "maybe_";
        }
        if (strcmp(specifier, "cfish_String") == 0) {
            dest_name = "string";
            var_name = CFCUtil_sprintf("%s_ARG", CFCVariable_get_name(var));
        }
        else if (strcmp(specifier, "cfish_Hash") == 0) {
            dest_name = "hash";
            var_name = CFCUtil_sprintf("%s_ARG", CFCVariable_get_name(var));
        }
        else if (strcmp(specifier, "cfish_Vector") == 0) {
            dest_name = "vec";
            var_name = CFCUtil_sprintf("%s_ARG", CFCVariable_get_name(var));
        }
        else {
            dest_name = "obj";
            var_name = CFCUtil_sprintf("wrap_arg_%s", micro_sym);
        }
    }
    else {
        dest_name = "INVALID";
    }
    char *content = CFCUtil_sprintf(", CFBind_%sconvert_%s, &%s",
                                    maybe_maybe, dest_name, var_name);
    FREEMEM(var_name);
    return content;
}

/* Generate the code which parses arguments passed from Python and converts
 * them to Clownfish-flavored C values.
 */
static char*
S_gen_arg_parsing(CFCParamList *param_list, int first_tick, char **error) {
    char *content = NULL;

    CFCVariable **vars = CFCParamList_get_variables(param_list);
    const char **vals = CFCParamList_get_initial_values(param_list);
    int num_vars = CFCParamList_num_vars(param_list);

    char *declarations = CFCUtil_strdup("");
    char *keywords     = CFCUtil_strdup("");
    char *format_str   = CFCUtil_strdup("");
    char *targets      = CFCUtil_strdup("");
    int optional_started = 0;

    for (int i = first_tick; i < num_vars; i++) {
        CFCVariable *var  = vars[i];
        const char  *val  = vals[i];

        const char *var_name = CFCVariable_get_name(var);
        keywords = CFCUtil_cat(keywords, "\"", var_name, "\", ", NULL);

        // Build up ParseTuple format string.
        if (val == NULL) {
            if (optional_started) { // problem!
                *error = "Required after optional param";
                goto CLEAN_UP_AND_RETURN;
            }
        }
        else {
            if (!optional_started) {
                optional_started = 1;
                format_str = CFCUtil_cat(format_str, "|", NULL);
            }
        }
        format_str = CFCUtil_cat(format_str, "O&", NULL);

        char *declaration = S_gen_declaration(var, val);
        declarations = CFCUtil_cat(declarations, declaration, NULL);
        FREEMEM(declaration);

        char *target = S_gen_target(var, val);
        targets = CFCUtil_cat(targets, target, NULL);
        FREEMEM(target);
    }

    char parse_pattern[] =
        "%s"
        "    char *keywords[] = {%sNULL};\n"
        "    char *fmt = \"%s\";\n"
        "    int ok = PyArg_ParseTupleAndKeywords(args, kwargs, fmt,\n"
        "        keywords%s);\n"
        "    if (!ok) { return NULL; }\n"
        ;
    content = CFCUtil_sprintf(parse_pattern, declarations, keywords,
                              format_str, targets);

CLEAN_UP_AND_RETURN:
    FREEMEM(declarations);
    FREEMEM(keywords);
    FREEMEM(format_str);
    FREEMEM(targets);
    return content;
}

static char*
S_build_pymeth_invocation(CFCMethod *method) {
    CFCType *return_type = CFCMethod_get_return_type(method);
    const char *micro_sym = CFCSymbol_get_name((CFCSymbol*)method);
    char *invocation = NULL;
    const char *ret_type_str = CFCType_to_c(return_type);

    if (CFCType_is_void(return_type)) {
        const char pattern[] =
            "    CALL_PYMETH_VOID((PyObject*)self, \"%s\", cfcb_ARGS);";
        invocation = CFCUtil_sprintf(pattern, micro_sym);
    }
    else if (CFCType_is_object(return_type)) {
        const char *nullable
            = CFCType_nullable(return_type) ? "true" : "false";
        const char *ret_class = CFCType_get_class_var(return_type);
        const char pattern[] =
            "    %s cfcb_RESULT = (%s)CALL_PYMETH_OBJ((PyObject*)self, \"%s\", cfcb_ARGS, %s, %s);";
        invocation = CFCUtil_sprintf(pattern, ret_type_str, ret_type_str, micro_sym,
                                     ret_class, nullable);
    }
    else if (CFCType_is_primitive(return_type)) {
        char type_upcase[64];
        if (strlen(ret_type_str) > 63) {
            CFCUtil_die("Unexpectedly long type name: %s", ret_type_str);
        }
        for (size_t i = 0, max = strlen(ret_type_str) + 1; i < max; i++) {
            type_upcase[i] = CFCUtil_toupper(ret_type_str[i]);
        }
        const char pattern[] =
            "    %s cfcb_RESULT = CALL_PYMETH_%s((PyObject*)self, \"%s\", cfcb_ARGS);";
        invocation = CFCUtil_sprintf(pattern, ret_type_str, type_upcase,
                                     micro_sym);
    }
    else {
        CFCUtil_die("Unexpected return type: %s", CFCType_to_c(return_type));
    }

    return invocation;
}

static char*
S_callback_refcount_mods(CFCParamList *param_list) {
    char *refcount_mods = CFCUtil_strdup("");
    CFCVariable **arg_vars = CFCParamList_get_variables(param_list);

    // Adjust refcounts of arguments per method signature, so that Perl code
    // does not have to.
    for (int i = 0; arg_vars[i] != NULL; i++) {
        CFCVariable *var  = arg_vars[i];
        CFCType     *type = CFCVariable_get_type(var);
        const char  *name = CFCVariable_get_name(var);
        if (!CFCType_is_object(type)) {
            continue;
        }
        else if (CFCType_incremented(type)) {
            refcount_mods = CFCUtil_cat(refcount_mods, "    CFISH_INCREF(",
                                        name, ");\n", NULL);
        }
        else if (CFCType_decremented(type)) {
            refcount_mods = CFCUtil_cat(refcount_mods, "    CFISH_DECREF(",
                                        name, ");\n", NULL);
        }
    }

    return refcount_mods;
}

char*
CFCPyMethod_callback_def(CFCMethod *method, CFCClass *invoker) {
    CFCParamList *param_list   = CFCMethod_get_param_list(method);
    CFCVariable **vars         = CFCParamList_get_variables(param_list);
    CFCType      *return_type  = CFCMethod_get_return_type(method);
    const char   *ret_type_str = CFCType_to_c(return_type);
    const char   *params       = CFCParamList_to_c(param_list);
    char         *override_sym = CFCMethod_full_override_sym(method, invoker);
    char *content;

    if (CFCMethod_can_be_bound(method)) {
        char *py_args = S_build_py_args(param_list);
        char *invocation = S_build_pymeth_invocation(method);
        char *refcount_mods = S_callback_refcount_mods(param_list);
        const char *maybe_return = CFCType_is_void(return_type)
                                   ? ""
                                   : "    return cfcb_RESULT;\n";

        const char pattern[] =
            "%s\n"
            "%s(%s) {\n"
            "%s\n"
            "%s\n"
            "%s"
            "%s"
            "}\n";
        content = CFCUtil_sprintf(pattern, ret_type_str, override_sym, params,
                                  py_args, invocation, refcount_mods,
                                  maybe_return);
    }
    else {
        char *unused = S_build_unused_vars(vars);
        char *unreachable = S_maybe_unreachable(return_type);
        char *meth_sym = CFCMethod_full_method_sym(method, invoker);
        const char pattern[] =
            "%s\n"
            "%s(%s) {%s\n"
            "    CFISH_THROW(CFISH_ERR, \"Can't override %s via binding\");%s\n"
            "}\n";
        content = CFCUtil_sprintf(pattern, ret_type_str, override_sym,
                                  params, unused, meth_sym, unreachable);
        FREEMEM(meth_sym);
        FREEMEM(unused);
        FREEMEM(unreachable);
    }

    FREEMEM(override_sym);
    return content;
}

static char*
S_build_unused_vars(CFCVariable **vars) {
    char *unused = CFCUtil_strdup("");

    for (int i = 0; vars[i] != NULL; i++) {
        const char *var_name = CFCVariable_get_name(vars[i]);
        size_t size = strlen(unused) + strlen(var_name) + 80;
        unused = (char*)REALLOCATE(unused, size);
        strcat(unused, "\n    CFISH_UNUSED_VAR(");
        strcat(unused, var_name);
        strcat(unused, ");");
    }

    return unused;
}

static char*
S_maybe_unreachable(CFCType *return_type) {
    char *return_statement;
    if (CFCType_is_void(return_type)) {
        return_statement = CFCUtil_strdup("");
    }
    else {
        const char *ret_type_str = CFCType_to_c(return_type);
        char pattern[] = "\n    CFISH_UNREACHABLE_RETURN(%s);";
        return_statement = CFCUtil_sprintf(pattern, ret_type_str);
    }
    return return_statement;
}

static char*
S_meth_top(CFCMethod *method) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);

    if (CFCParamList_num_vars(param_list) == 1) {
        char pattern[] =
            "(PyObject *self, PyObject *unused) {\n"
            "    CFISH_UNUSED_VAR(unused);\n"
            ;
        return CFCUtil_sprintf(pattern);
    }
    else {
        char *error = NULL;
        char *arg_parsing = S_gen_arg_parsing(param_list, 1, &error);
        if (error) {
            CFCUtil_die("%s in %s", error, CFCMethod_get_name(method));
        }
        if (!arg_parsing) {
            return NULL;
        }
        char *decs = S_gen_decs(param_list, 1);
        char pattern[] =
            "(PyObject *self, PyObject *args, PyObject *kwargs) {\n"
            "%s" // decs
            "%s"
            ;
        char *result = CFCUtil_sprintf(pattern, decs, arg_parsing);
        FREEMEM(arg_parsing);
        return result;
    }
}

static char*
S_gen_arg_increfs(CFCParamList *param_list, int first_tick) {
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    int num_vars = CFCParamList_num_vars(param_list);
    char *content = CFCUtil_strdup("");
    for (int i = first_tick; i < num_vars; i++) {
        CFCType *type = CFCVariable_get_type(vars[i]);
        if (CFCType_decremented(type)) {
            const char *name = CFCVariable_get_name(vars[i]);
            const char *specifier = CFCType_get_specifier(type);
            char pattern[] =
                "    %s_ARG = (%s*)CFISH_INCREF(%s_ARG);\n";
            char *incref = CFCUtil_sprintf(pattern, name, specifier, name);
            content = CFCUtil_cat(content, incref, NULL);
            FREEMEM(incref);
        }
    }
    return content;
}

// Prep refcount decrement calls to follow the Clownfish subroutine
// invocation.
static char*
S_gen_decrefs(CFCParamList *param_list, int first_tick) {
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    int num_vars = CFCParamList_num_vars(param_list);
    char *decrefs = CFCUtil_strdup("");

    for (int i = first_tick; i < num_vars; i++) {
        CFCVariable *var = vars[i];
        CFCType *type = CFCVariable_get_type(var);
        const char *micro_sym = CFCVariable_get_name(var);
        const char *specifier = CFCType_get_specifier(type);

        if (strcmp(specifier, "cfish_Obj") == 0
             || strcmp(specifier, "cfish_String") == 0
             || strcmp(specifier, "cfish_Vector") == 0
             || strcmp(specifier, "cfish_Hash") == 0
            ) {
            decrefs = CFCUtil_cat(decrefs, "    CFISH_DECREF(", micro_sym,
                                  "_ARG);\n", NULL);
        }
    }

    return decrefs;
}

static char*
S_gen_arg_list(CFCParamList *param_list, const char *first_arg) {
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    int num_vars = CFCParamList_num_vars(param_list);
    char *arg_list = CFCUtil_strdup("");
    for (int i = 0; i < num_vars; i++) {
        if (i > 0) {
            arg_list = CFCUtil_cat(arg_list, ", ", NULL);
        }
        if (i == 0 && first_arg != NULL) {
            arg_list = CFCUtil_cat(arg_list, first_arg, NULL);
        }
        else {
            arg_list = CFCUtil_cat(arg_list, CFCVariable_get_name(vars[i]),
                                   "_ARG", NULL);
        }
    }
    return arg_list;
}

static char*
S_gen_meth_invocation(CFCMethod *method, CFCClass *invoker) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    char *full_meth = CFCMethod_full_method_sym(method, invoker);
    char *meth_type_c = CFCMethod_full_typedef(method, invoker);
    const char *class_var = CFCClass_full_class_var(invoker);
    char *first_arg
        = CFCUtil_sprintf("(%s*)self", CFCClass_full_struct_sym(invoker));
    char *arg_list = S_gen_arg_list(param_list, first_arg);

    CFCType *return_type = CFCMethod_get_return_type(method);
    char *maybe_declare;
    const char *maybe_assign;
    if (CFCType_is_void(return_type)) {
        maybe_declare = CFCUtil_strdup("");
        maybe_assign = "";
    }
    else {
        maybe_declare = CFCUtil_sprintf("    %s retvalCF = 0;\n",
                                        CFCType_to_c(return_type));
        maybe_assign = "retvalCF = ";
    }

    const char pattern[] =
        "%s"
        "    %s method = CFISH_METHOD_PTR(%s, %s);\n"
        "    CFBIND_TRY(%smethod(%s));\n"
        ;
    char *content
        = CFCUtil_sprintf(pattern, maybe_declare, meth_type_c, class_var,
                          full_meth, maybe_assign, arg_list);

    FREEMEM(arg_list);
    FREEMEM(first_arg);
    FREEMEM(maybe_declare);
    FREEMEM(full_meth);
    FREEMEM(meth_type_c);
    return content;
}

char*
CFCPyMethod_wrapper(CFCMethod *method, CFCClass *invoker) {
    CFCParamList *param_list  = CFCMethod_get_param_list(method);
    CFCType      *return_type = CFCMethod_get_return_type(method);
    char *meth_sym   = CFCMethod_full_method_sym(method, invoker);
    char *meth_top   = S_meth_top(method);
    char *increfs    = S_gen_arg_increfs(param_list, 1);
    char *decrefs    = S_gen_decrefs(param_list, 1);
    char *invocation = S_gen_meth_invocation(method, invoker);
    char *ret;
    if (CFCType_is_void(return_type)) {
        ret = CFCUtil_strdup("    Py_RETURN_NONE;\n");
    }
    else if (CFCType_incremented(return_type)) {
        ret = CFCUtil_strdup("    return CFBind_cfish_to_py_zeroref((cfish_Obj*)retvalCF);\n");
    }
    else {
        char *conv = CFCPyTypeMap_c_to_py(return_type, "retvalCF");
        ret = CFCUtil_sprintf("    return %s;\n", conv);
        FREEMEM(conv);
    }

    char pattern[] =
        "static PyObject*\n"
        "S_%s%s"
        "%s" // increfs
        "%s" // invocation
        "%s" // decrefs
        "    if (CFBind_migrate_cferr()) {\n"
        "        return NULL;\n"
        "    }\n"
        "%s" // ret
        "}\n"
        ;
    char *wrapper = CFCUtil_sprintf(pattern, meth_sym, meth_top,
                                    increfs, invocation, decrefs, ret);
    FREEMEM(ret);
    FREEMEM(invocation);
    FREEMEM(decrefs);
    FREEMEM(increfs);
    FREEMEM(meth_sym);
    FREEMEM(meth_top);

    return wrapper;
}

char*
CFCPyMethod_constructor_wrapper(CFCFunction *init_func, CFCClass *invoker) {
    CFCParamList *param_list  = CFCFunction_get_param_list(init_func);
    const char *self_type
        = CFCType_to_c(CFCFunction_get_return_type(init_func));
    char *func_sym   = CFCFunction_full_func_sym(init_func, invoker);
    char *decs       = S_gen_decs(param_list, 1);
    char *increfs    = S_gen_arg_increfs(param_list, 1);
    char *decrefs    = S_gen_decrefs(param_list, 1);
    const char *class_var  = CFCClass_full_class_var(invoker);
    const char *struct_sym = CFCClass_full_struct_sym(invoker);
    char *error = NULL;
    char *arg_parsing = S_gen_arg_parsing(param_list, 1, &error);
    if (error) {
        CFCUtil_die("%s in constructor for %s", error,
                    CFCClass_get_name(invoker));
    }
    if (!arg_parsing) {
        CFCUtil_die("Unexpected arg parsing error for %s",
                    CFCClass_get_name(invoker));
    }
    char *first_arg = CFCUtil_sprintf("(%s)CFISH_Class_Make_Obj(%s)",
                                      self_type, class_var);
    char *arg_list = S_gen_arg_list(param_list, first_arg);

    char pattern[] =
        "static PyObject*\n"
        "S_%s_PY_NEW(PyTypeObject *type, PyObject *args, PyObject *kwargs) {\n"
        "%s" // decs
        "%s" // arg_parsing
        "%s" // increfs
        "    %s self = NULL;\n"
        "    CFBIND_TRY(self = %s(%s));\n"
        "%s" // decrefs
        "    if (CFBind_migrate_cferr()) {\n"
        "        return NULL;\n"
        "    }\n"
        "    return (PyObject*)self;\n"
        "}\n"
        ;
    char *wrapper = CFCUtil_sprintf(pattern, struct_sym, decs,
                                    arg_parsing, increfs, self_type,
                                    func_sym, arg_list, decrefs);

    FREEMEM(arg_list);
    FREEMEM(first_arg);
    FREEMEM(func_sym);
    FREEMEM(decrefs);
    FREEMEM(increfs);
    FREEMEM(decs);
    FREEMEM(arg_parsing);
    return wrapper;
}

char*
CFCPyMethod_pymethoddef(CFCMethod *method, CFCClass *invoker) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    const char *flags = CFCParamList_num_vars(param_list) == 1
                        ? "METH_NOARGS"
                        : "METH_KEYWORDS|METH_VARARGS";
    char *meth_sym = CFCMethod_full_method_sym(method, invoker);
    char *micro_sym = CFCUtil_strdup(CFCSymbol_get_name((CFCSymbol*)method));
    for (int i = 0; micro_sym[i] != 0; i++) {
        micro_sym[i] = CFCUtil_tolower(micro_sym[i]);
    }

    char pattern[] =
        "{\"%s\", (PyCFunction)S_%s, %s, NULL},";
    char *py_meth_def = CFCUtil_sprintf(pattern, micro_sym, meth_sym, flags);

    FREEMEM(meth_sym);
    FREEMEM(micro_sym);
    return py_meth_def;
}

