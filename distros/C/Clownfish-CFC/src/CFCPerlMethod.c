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

#define CFC_NEED_PERLSUB_STRUCT_DEF 1
#include "CFCPerlSub.h"
#include "CFCPerlMethod.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCSymbol.h"
#include "CFCType.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCPerlTypeMap.h"
#include "CFCVariable.h"

struct CFCPerlMethod {
    CFCPerlSub  sub;
    CFCMethod  *method;
};

// Return the main chunk of the code for the xsub.
static char*
S_xsub_body(CFCPerlMethod *self, CFCClass *klass);

// Create an assignment statement for extracting $self from the Perl stack.
static char*
S_self_assign_statement(CFCPerlMethod *self);

// Return code for an xsub which uses labeled params.
static char*
S_xsub_def_labeled_params(CFCPerlMethod *self, CFCClass *klass);

// Return code for an xsub which uses positional args.
static char*
S_xsub_def_positional_args(CFCPerlMethod *self, CFCClass *klass);

/* Generate code which converts C types to Perl types and pushes arguments
 * onto the Perl stack.
 */
static char*
S_callback_start(CFCMethod *method);

/* Adapt the refcounts of parameters and return types.
 */
static char*
S_callback_refcount_mods(CFCMethod *method);

/* Return a function which throws a runtime error indicating which variable
 * couldn't be mapped.  TODO: it would be better to resolve all these cases at
 * compile-time.
 */
static char*
S_invalid_callback_body(CFCMethod *method);

// Create a callback for a method which operates in a void context.
static char*
S_void_callback_body(CFCMethod *method, const char *callback_start,
                     const char *refcount_mods);

// Create a callback which returns a primitive type.
static char*
S_primitive_callback_body(CFCMethod *method, const char *callback_start,
                          const char *refcount_mods);

/* Create a callback which returns an object type -- either a generic object or
 * a string. */
static char*
S_obj_callback_body(CFCMethod *method, const char *callback_start,
                    const char *refcount_mods);

static const CFCMeta CFCPERLMETHOD_META = {
    "Clownfish::CFC::Binding::Perl::Method",
    sizeof(CFCPerlMethod),
    (CFCBase_destroy_t)CFCPerlMethod_destroy
};

CFCPerlMethod*
CFCPerlMethod_new(CFCClass *klass, CFCMethod *method) {
    CFCPerlMethod *self
        = (CFCPerlMethod*)CFCBase_allocate(&CFCPERLMETHOD_META);
    return CFCPerlMethod_init(self, klass, method);
}

CFCPerlMethod*
CFCPerlMethod_init(CFCPerlMethod *self, CFCClass *klass, CFCMethod *method) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    const char *class_name = CFCClass_get_name(klass);
    int use_labeled_params = CFCParamList_num_vars(param_list) > 2
                             ? 1 : 0;

    char *perl_name = CFCPerlMethod_perl_name(method);
    CFCPerlSub_init((CFCPerlSub*)self, param_list, class_name, perl_name,
                    use_labeled_params);
    self->method = (CFCMethod*)CFCBase_incref((CFCBase*)method);
    FREEMEM(perl_name);
    return self;
}

void
CFCPerlMethod_destroy(CFCPerlMethod *self) {
    CFCBase_decref((CFCBase*)self->method);
    CFCPerlSub_destroy((CFCPerlSub*)self);
}

char*
CFCPerlMethod_perl_name(CFCMethod *method) {
    // See if the user wants the method to have a specific alias.
    const char *alias = CFCMethod_get_host_alias(method);
    if (alias) {
        return CFCUtil_strdup(alias);
    }

    // Derive Perl name by lowercasing.
    const char *name      = CFCMethod_get_name(method);
    char       *perl_name = CFCUtil_strdup(name);
    for (size_t i = 0; perl_name[i] != '\0'; i++) {
        perl_name[i] = CFCUtil_tolower(perl_name[i]);
    }

    return perl_name;
}

char*
CFCPerlMethod_xsub_def(CFCPerlMethod *self, CFCClass *klass) {
    if (self->sub.use_labeled_params) {
        return S_xsub_def_labeled_params(self, klass);
    }
    else {
        return S_xsub_def_positional_args(self, klass);
    }
}

static char*
S_xsub_body(CFCPerlMethod *self, CFCClass *klass) {
    CFCMethod    *method     = self->method;
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    CFCVariable **arg_vars   = CFCParamList_get_variables(param_list);
    char         *name_list  = CFCPerlSub_arg_name_list((CFCPerlSub*)self);
    char         *body       = CFCUtil_strdup("");

    // Extract the method function pointer.
    char *full_meth = CFCMethod_full_method_sym(method, klass);
    char *method_ptr
        = CFCUtil_sprintf("method = CFISH_METHOD_PTR(%s, %s);\n    ",
                          CFCClass_full_class_var(klass), full_meth);
    body = CFCUtil_cat(body, method_ptr, NULL);
    FREEMEM(full_meth);
    FREEMEM(method_ptr);

    // Compensate for functions which eat refcounts.
    // It would be more efficient to convert decremented arguments
    // by calling XSBind_perl_to_cfish without noinc.
    for (int i = 0; arg_vars[i] != NULL; i++) {
        CFCVariable *var = arg_vars[i];
        CFCType     *type = CFCVariable_get_type(var);
        if (CFCType_is_object(type) && CFCType_decremented(type)) {
            const char *name   = CFCVariable_get_name(var);
            const char *type_c = CFCType_to_c(type);
            const char *pattern =
                "arg_%s = (%s)CFISH_INCREF(arg_%s);\n    ";
            char *statement = CFCUtil_sprintf(pattern, name, type_c, name);
            body = CFCUtil_cat(body, statement, NULL);
            FREEMEM(statement);
        }
    }

    if (CFCType_is_void(CFCMethod_get_return_type(method))) {
        // Invoke method in void context.
        body = CFCUtil_cat(body, "method(", name_list,
                           ");\n    XSRETURN(0);", NULL);
    }
    else {
        // Return a value for method invoked in a scalar context.
        CFCType *return_type = CFCMethod_get_return_type(method);
        char *assignment = CFCPerlTypeMap_to_perl(return_type, "retval");
        if (!assignment) {
            const char *type_str = CFCType_to_c(return_type);
            CFCUtil_die("Can't find typemap for '%s'", type_str);
        }
        body = CFCUtil_cat(body, "retval = method(", name_list,
                           ");\n    ST(0) = ", assignment, ";", NULL);
        if (CFCType_is_object(return_type)
            && CFCType_incremented(return_type)
           ) {
            body = CFCUtil_cat(body, "\n    CFISH_DECREF(retval);", NULL);
        }
        body = CFCUtil_cat(body, "\n    sv_2mortal( ST(0) );\n    XSRETURN(1);",
                           NULL);
        FREEMEM(assignment);
    }

    FREEMEM(name_list);

    return body;
}

// Create an assignment statement for extracting $self from the Perl stack.
static char*
S_self_assign_statement(CFCPerlMethod *self) {
    CFCParamList *param_list = CFCMethod_get_param_list(self->method);
    CFCVariable **vars = CFCParamList_get_variables(param_list);
    CFCType *type = CFCVariable_get_type(vars[0]);
    const char *self_name = CFCVariable_get_name(vars[0]);
    const char *type_c = CFCType_to_c(type);
    if (!CFCType_is_object(type)) {
        CFCUtil_die("Not an object type: %s", type_c);
    }
    const char *class_var = CFCType_get_class_var(type);
    char pattern[] = "arg_%s = (%s)XSBind_perl_to_cfish_noinc("
                     "aTHX_ ST(0), %s, NULL);";
    char *statement = CFCUtil_sprintf(pattern, self_name, type_c, class_var);

    return statement;
}

static char*
S_xsub_def_labeled_params(CFCPerlMethod *self, CFCClass *klass) {
    CFCMethod *method = self->method;
    const char *c_name = self->sub.c_name;
    CFCParamList *param_list = self->sub.param_list;
    CFCVariable **arg_vars   = CFCParamList_get_variables(param_list);
    CFCVariable *self_var    = arg_vars[0];
    CFCType     *return_type = CFCMethod_get_return_type(method);
    int num_vars = CFCParamList_num_vars(param_list);
    const char  *self_name   = CFCVariable_get_name(self_var);
    char *param_specs = CFCPerlSub_build_param_specs((CFCPerlSub*)self, 1);
    char *arg_decls   = CFCPerlSub_arg_declarations((CFCPerlSub*)self, 0);
    char *meth_type_c = CFCMethod_full_typedef(method, klass);
    char *self_assign = S_self_assign_statement(self);
    char *arg_assigns = CFCPerlSub_arg_assignments((CFCPerlSub*)self);
    char *body        = S_xsub_body(self, klass);

    char *retval_decl;
    if (CFCType_is_void(return_type)) {
        retval_decl = CFCUtil_strdup("");
    }
    else {
        const char *return_type_c = CFCType_to_c(return_type);
        retval_decl = CFCUtil_sprintf("    %s retval;\n", return_type_c);
    }

    const char *locations_sv = "";
    if (num_vars > 1) {
        locations_sv = "    SV *sv;\n";
    }

    char pattern[] =
        "XS_INTERNAL(%s);\n"
        "XS_INTERNAL(%s) {\n"
        "    dXSARGS;\n"
        "%s"        // param_specs
        "    int32_t locations[%d];\n"
        "%s" // locations_sv
        "%s"        // arg_decls
        "    %s method;\n"
        "%s"
        "\n"
        "    CFISH_UNUSED_VAR(cv);\n"
        "    if (items < 1) {\n"
        "        XSBind_invalid_args_error(aTHX_ cv, \"%s, ...\");\n"
        "    }\n"
        "    SP -= items;\n"
        "\n"
        "    /* Locate args on Perl stack. */\n"
        "    XSBind_locate_args(aTHX_ &ST(0), 1, items, param_specs,\n"
        "                       locations, %d);\n"
        "    %s\n"  // self_assign
        "%s"        // arg_assigns
        "\n"
        "    /* Execute */\n"
        "    %s\n"  // body
        "}\n";
    char *xsub_def
        = CFCUtil_sprintf(pattern, c_name, c_name, param_specs, num_vars - 1,
                          locations_sv, arg_decls, meth_type_c, retval_decl,
                          self_name, num_vars - 1, self_assign, arg_assigns,
                          body);

    FREEMEM(param_specs);
    FREEMEM(arg_decls);
    FREEMEM(meth_type_c);
    FREEMEM(self_assign);
    FREEMEM(arg_assigns);
    FREEMEM(body);
    FREEMEM(retval_decl);
    return xsub_def;
}

static char*
S_xsub_def_positional_args(CFCPerlMethod *self, CFCClass *klass) {
    CFCMethod *method = self->method;
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    CFCVariable **arg_vars = CFCParamList_get_variables(param_list);
    CFCType     *return_type = CFCMethod_get_return_type(method);
    const char **arg_inits = CFCParamList_get_initial_values(param_list);
    int num_vars = CFCParamList_num_vars(param_list);
    char *arg_decls   = CFCPerlSub_arg_declarations((CFCPerlSub*)self, 0);
    char *meth_type_c = CFCMethod_full_typedef(method, klass);
    char *self_assign = S_self_assign_statement(self);
    char *arg_assigns = CFCPerlSub_arg_assignments((CFCPerlSub*)self);
    char *body        = S_xsub_body(self, klass);

    // Determine how many args are truly required and build an error check.
    int min_required = 0;
    for (int i = 0; i < num_vars; i++) {
        if (arg_inits[i] == NULL) {
            min_required = i + 1;
        }
    }
    char *num_args_cond;
    if (min_required < num_vars) {
        const char cond_pattern[] = "items < %d || items > %d";
        num_args_cond = CFCUtil_sprintf(cond_pattern, min_required, num_vars);
    }
    else {
        num_args_cond = CFCUtil_sprintf("items != %d", num_vars);
    }
    char *xs_name_list = num_vars > 0
                         ? CFCUtil_strdup(CFCVariable_get_name(arg_vars[0]))
                         : CFCUtil_strdup("");
    for (int i = 1; i < num_vars; i++) {
        const char *var_name = CFCVariable_get_name(arg_vars[i]);
        if (i < min_required) {
            xs_name_list = CFCUtil_cat(xs_name_list, ", ", var_name, NULL);
        }
        else {
            xs_name_list = CFCUtil_cat(xs_name_list, ", [", var_name, "]",
                                       NULL);
        }
    }
    const char *working_sv = "";
    if (num_vars > 1) {
        working_sv = "    SV *sv;\n";
    }

    char *retval_decl;
    if (CFCType_is_void(return_type)) {
        retval_decl = CFCUtil_strdup("");
    }
    else {
        const char *return_type_c = CFCType_to_c(return_type);
        retval_decl = CFCUtil_sprintf("    %s retval;\n", return_type_c);
    }

    char pattern[] =
        "XS_INTERNAL(%s);\n"
        "XS_INTERNAL(%s) {\n"
        "    dXSARGS;\n"
        "%s" // working_sv
        "%s" // arg_decls
        "    %s method;\n"
        "%s"
        "\n"
        "    CFISH_UNUSED_VAR(cv);\n"
        "    SP -= items;\n"
        "    if (%s) {\n"
        "        XSBind_invalid_args_error(aTHX_ cv, \"%s\");\n"
        "    }\n"
        "\n"
        "    /* Extract vars from Perl stack. */\n"
        "    %s\n"
        "%s" // arg_assigns
        "\n"
        "    /* Execute */\n"
        "    %s\n"
        "}\n";
    char *xsub
        = CFCUtil_sprintf(pattern, self->sub.c_name, self->sub.c_name,
                          working_sv, arg_decls, meth_type_c, retval_decl,
                          num_args_cond, xs_name_list, self_assign,
                          arg_assigns, body);

    FREEMEM(arg_assigns);
    FREEMEM(arg_decls);
    FREEMEM(meth_type_c);
    FREEMEM(self_assign);
    FREEMEM(body);
    FREEMEM(num_args_cond);
    FREEMEM(xs_name_list);
    FREEMEM(retval_decl);
    return xsub;
}

char*
CFCPerlMethod_callback_def(CFCMethod *method, CFCClass *klass) {
    CFCType *return_type = CFCMethod_get_return_type(method);
    char *callback_body = NULL;

    // Return a callback wrapper that throws an error if there are no
    // bindings for a method.
    if (!CFCMethod_can_be_bound(method)) {
        callback_body = S_invalid_callback_body(method);
    }
    else {
        char *start = S_callback_start(method);
        char *refcount_mods = S_callback_refcount_mods(method);

        if (CFCType_is_void(return_type)) {
            callback_body = S_void_callback_body(method, start, refcount_mods);
        }
        else if (CFCType_is_object(return_type)) {
            callback_body = S_obj_callback_body(method, start, refcount_mods);
        }
        else if (CFCType_is_integer(return_type)
                 || CFCType_is_floating(return_type)
            ) {
            callback_body = S_primitive_callback_body(method, start,
                                                      refcount_mods);
        }
        else {
            // Can't map return type.
            callback_body = S_invalid_callback_body(method);
        }

        FREEMEM(start);
        FREEMEM(refcount_mods);
    }

    char *override_sym = CFCMethod_full_override_sym(method, klass);

    CFCParamList *param_list = CFCMethod_get_param_list(method);
    const char *params = CFCParamList_to_c(param_list);

    const char *ret_type_str = CFCType_to_c(return_type);

    char pattern[] =
        "%s\n"
        "%s(%s) {\n"
        "%s"
        "}\n";
    char *callback_def
        = CFCUtil_sprintf(pattern, ret_type_str, override_sym, params,
                          callback_body);

    FREEMEM(callback_body);
    FREEMEM(override_sym);
    return callback_def;
}

static char*
S_callback_start(CFCMethod *method) {
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    static const char pattern[] =
        "    dTHX;\n"
        "    dSP;\n"
        "    EXTEND(SP, %d);\n"
        "    ENTER;\n"
        "    SAVETMPS;\n"
        "    PUSHMARK(SP);\n"
        "    mPUSHs((SV*)CFISH_Obj_To_Host((cfish_Obj*)self, NULL));\n";
    int num_args = CFCParamList_num_vars(param_list) - 1;
    int num_to_extend = num_args == 0 ? 1
                      : num_args == 1 ? 2
                      : 1 + (num_args * 2);
    char *params = CFCUtil_sprintf(pattern, num_to_extend);

    // Iterate over arguments, mapping them to Perl scalars.
    CFCVariable **arg_vars = CFCParamList_get_variables(param_list);
    for (int i = 1; arg_vars[i] != NULL; i++) {
        CFCVariable *var      = arg_vars[i];
        const char  *name     = CFCVariable_get_name(var);
        CFCType     *type     = CFCVariable_get_type(var);
        const char  *c_type   = CFCType_to_c(type);

        // Add labels when there are two or more parameters.
        if (num_args > 1) {
            char num_buf[20];
            sprintf(num_buf, "%d", (int)strlen(name));
            params = CFCUtil_cat(params, "    mPUSHp(\"", name, "\", ",
                                 num_buf, ");\n", NULL);
        }

        if (CFCType_is_object(type)) {
            // Wrap Clownfish object types in Perl objects.
            params = CFCUtil_cat(params, "    mPUSHs(XSBind_cfish_to_perl(",
                                 "aTHX_ (cfish_Obj*)", name, "));\n", NULL);
        }
        else if (CFCType_is_integer(type)) {
            // Convert primitive integer types to IV Perl scalars.
            int width = (int)CFCType_get_width(type);
            if (width != 0 && width <= 4) {
                params = CFCUtil_cat(params, "    mPUSHi(",
                                     name, ");\n", NULL);
            }
            else {
                // If the Perl IV integer type is not wide enough, use
                // doubles.  This may be lossy if the value is above 2**52,
                // but practically speaking, it's important to handle numbers
                // between 2**32 and 2**52 cleanly.
                params = CFCUtil_cat(params,
                                     "    if (sizeof(IV) >= sizeof(", c_type,
                                     ")) { mPUSHi(", name, "); }\n",
                                     "    else { mPUSHn((double)", name,
                                     "); } // lossy \n", NULL);
            }
        }
        else if (CFCType_is_floating(type)) {
            // Convert primitive floating point types to NV Perl scalars.
            params = CFCUtil_cat(params, "    mPUSHn(",
                                 name, ");\n", NULL);
        }
        else {
            // Can't map variable type.
            const char *type_str = CFCType_to_c(type);
            CFCUtil_die("Can't map type '%s' to Perl", type_str);
        }
    }

    // Restore the Perl stack pointer.
    params = CFCUtil_cat(params, "    PUTBACK;\n", NULL);

    return params;
}

static char*
S_callback_refcount_mods(CFCMethod *method) {
    char *refcount_mods = CFCUtil_strdup("");
    CFCType *return_type = CFCMethod_get_return_type(method);
    CFCParamList *param_list = CFCMethod_get_param_list(method);
    CFCVariable **arg_vars = CFCParamList_get_variables(param_list);

    // `XSBind_perl_to_cfish()` returns an incremented object.  If this method
    // does not return an incremented object, we must cancel out that
    // refcount.  (No function can return a decremented object.)
    if (CFCType_is_object(return_type) && !CFCType_incremented(return_type)) {
        refcount_mods = CFCUtil_cat(refcount_mods,
                                    "    CFISH_DECREF(retval);\n", NULL);
    }

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

static char*
S_invalid_callback_body(CFCMethod *method) {
    CFCParamList *param_list   = CFCMethod_get_param_list(method);
    CFCVariable **param_vars = CFCParamList_get_variables(param_list);
    char *unused = CFCUtil_strdup("");
    for (int i = 0; param_vars[i] != NULL; i++) {
        const char *name = CFCVariable_get_name(param_vars[i]);
        unused = CFCUtil_cat(unused, "    CFISH_UNUSED_VAR(", name, ");\n",
                             NULL);
    }

    CFCType *return_type = CFCMethod_get_return_type(method);
    const char *ret_type_str = CFCType_to_c(return_type);
    char *maybe_ret
        = CFCType_is_void(return_type)
          ? CFCUtil_sprintf("")
          : CFCUtil_sprintf("    CFISH_UNREACHABLE_RETURN(%s);\n",
                            ret_type_str);

    char *perl_name = CFCPerlMethod_perl_name(method);

    char pattern[] =
        "%s"
        "    cfish_Err_invalid_callback(\"%s\");\n"
        "%s";
    char *callback_body
        = CFCUtil_sprintf(pattern, unused, perl_name, maybe_ret);

    FREEMEM(perl_name);
    FREEMEM(unused);
    FREEMEM(maybe_ret);
    return callback_body;
}

static char*
S_void_callback_body(CFCMethod *method, const char *callback_start,
                     const char *refcount_mods) {
    char *perl_name = CFCPerlMethod_perl_name(method);
    const char pattern[] =
        "%s"
        "    S_finish_callback_void(aTHX_ \"%s\");\n"
        "%s";
    char *callback_body
        = CFCUtil_sprintf(pattern, callback_start, perl_name, refcount_mods);

    FREEMEM(perl_name);
    return callback_body;
}

static char*
S_primitive_callback_body(CFCMethod *method, const char *callback_start,
                          const char *refcount_mods) {
    CFCType *return_type = CFCMethod_get_return_type(method);
    const char *ret_type_str = CFCType_to_c(return_type);
    char callback_func[50];

    if (CFCType_is_integer(return_type)) {
	if (strcmp(ret_type_str, "bool") == 0) {
             strcpy(callback_func, "!!S_finish_callback_i64");
	}
	else {
             strcpy(callback_func, "S_finish_callback_i64");
	}
    }
    else if (CFCType_is_floating(return_type)) {
        strcpy(callback_func, "S_finish_callback_f64");
    }
    else {
        CFCUtil_die("Unexpected type: %s", ret_type_str);
    }

    char *perl_name = CFCPerlMethod_perl_name(method);

    char pattern[] =
        "%s"
        "    %s retval = (%s)%s(aTHX_ \"%s\");\n"
        "%s"
        "    return retval;\n";
    char *callback_body
        = CFCUtil_sprintf(pattern, callback_start, ret_type_str, ret_type_str,
                          callback_func, perl_name, refcount_mods);

    FREEMEM(perl_name);
    return callback_body;
}

static char*
S_obj_callback_body(CFCMethod *method, const char *callback_start,
                    const char *refcount_mods) {
    CFCType *return_type = CFCMethod_get_return_type(method);
    const char *ret_type_str = CFCType_to_c(return_type);
    const char *nullable  = CFCType_nullable(return_type) ? "true" : "false";

    char *perl_name = CFCPerlMethod_perl_name(method);

    char pattern[] =
        "%s"
        "    %s retval = (%s)S_finish_callback_obj(aTHX_ self, \"%s\", %s);\n"
        "%s"
        "    return retval;\n";
    char *callback_body
        = CFCUtil_sprintf(pattern, callback_start, ret_type_str, ret_type_str,
                          perl_name, nullable, refcount_mods);

    FREEMEM(perl_name);
    return callback_body;
}

