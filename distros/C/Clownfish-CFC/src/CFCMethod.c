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

#define CFC_NEED_CALLABLE_STRUCT_DEF
#include "CFCCallable.h"
#include "CFCMethod.h"
#include "CFCType.h"
#include "CFCClass.h"
#include "CFCUtil.h"
#include "CFCParamList.h"
#include "CFCDocuComment.h"
#include "CFCVariable.h"
#include "CFCJson.h"

#ifndef true
    #define true 1
    #define false 0
#endif

struct CFCMethod {
    CFCCallable callable;
    CFCMethod *novel_method;
    char *fresh_class_name;
    char *host_alias;
    int is_final;
    int is_abstract;
    int is_novel;
    int is_excluded;
};

static const CFCMeta CFCMETHOD_META = {
    "Clownfish::CFC::Model::Method",
    sizeof(CFCMethod),
    (CFCBase_destroy_t)CFCMethod_destroy
};

CFCMethod*
CFCMethod_new(const char *exposure, const char *name, CFCType *return_type,
              CFCParamList *param_list, CFCDocuComment *docucomment,
              const char *class_name, int is_final, int is_abstract) {
    CFCMethod *self = (CFCMethod*)CFCBase_allocate(&CFCMETHOD_META);
    return CFCMethod_init(self, exposure, name, return_type, param_list,
                          docucomment, class_name, is_final, is_abstract);
}

static int
S_validate_meth_name(const char *meth_name) {
    if (!meth_name || !strlen(meth_name)) { return false; }

    int need_upper  = true;
    int need_letter = true;
    for (;; meth_name++) {
        if (need_upper  && !CFCUtil_isupper(*meth_name)) { return false; }
        if (need_letter && !CFCUtil_isalpha(*meth_name)) { return false; }
        need_upper  = false;
        need_letter = false;

        // We've reached NULL-termination without problems, so succeed.
        if (!*meth_name) { return true; }

        if (!CFCUtil_isalnum(*meth_name)) {
            if (*meth_name != '_') { return false; }
            need_upper  = true;
        }
    }
}

CFCMethod*
CFCMethod_init(CFCMethod *self, const char *exposure, const char *name,
               CFCType *return_type, CFCParamList *param_list,
               CFCDocuComment *docucomment, const char *class_name,
               int is_final, int is_abstract) {
    // Validate class_name.
    CFCUTIL_NULL_CHECK(class_name);
    if (!CFCClass_validate_class_name(class_name)) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("Invalid class_name: '%s'", class_name);
    }
    // Validate name.
    if (!S_validate_meth_name(name)) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("Invalid name: '%s'",
                    name ? name : "[NULL]");
    }

    // Super-init.
    CFCCallable_init((CFCCallable*)self, exposure, name, return_type,
                     param_list, docucomment);

    // Verify that the first element in the arg list is a self.
    CFCVariable **args = CFCParamList_get_variables(param_list);
    if (!args[0]) { CFCUtil_die("Missing 'self' argument"); }
    CFCType *type = CFCVariable_get_type(args[0]);
    const char *specifier  = CFCType_get_specifier(type);
    const char *last_colon = strrchr(class_name, ':');
    const char *struct_sym = last_colon ? last_colon + 1 : class_name;
    if (strcmp(specifier, struct_sym) != 0) {
        const char *first_underscore = strchr(specifier, '_');
        int mismatch = !first_underscore
                       || strcmp(first_underscore + 1, struct_sym) != 0;
        if (mismatch) {
            CFCUtil_die("First arg type doesn't match class: '%s' '%s'",
                        class_name, specifier);
        }
    }

    self->novel_method      = NULL;
    self->fresh_class_name  = CFCUtil_strdup(class_name);
    self->host_alias        = NULL;
    self->is_final          = is_final;
    self->is_abstract       = is_abstract;
    self->is_excluded       = false;

    // Assume that this method is novel until we discover when applying
    // inheritance that it overrides another.
    self->is_novel = true;

    return self;
}

void
CFCMethod_resolve_types(CFCMethod *self) {
    CFCCallable_resolve_types((CFCCallable*)self);
}

void
CFCMethod_destroy(CFCMethod *self) {
    CFCBase_decref((CFCBase*)self->novel_method);
    FREEMEM(self->fresh_class_name);
    FREEMEM(self->host_alias);
    CFCCallable_destroy((CFCCallable*)self);
}

int
CFCMethod_compatible(CFCMethod *self, CFCMethod *other) {
    if (!other) { return false; }
    const char *name       = CFCMethod_get_name(self);
    const char *other_name = CFCMethod_get_name(other);
    if (strcmp(name, other_name)) { return false; }
    int my_public = CFCMethod_public(self);
    int other_public = CFCMethod_public(other);
    if (!!my_public != !!other_public) { return false; }

    // Check arguments and initial values.
    CFCParamList *my_param_list    = self->callable.param_list;
    CFCParamList *other_param_list = other->callable.param_list;
    CFCVariable **my_args    = CFCParamList_get_variables(my_param_list);
    CFCVariable **other_args = CFCParamList_get_variables(other_param_list);
    const char  **my_vals    = CFCParamList_get_initial_values(my_param_list);
    const char  **other_vals = CFCParamList_get_initial_values(other_param_list);
    for (size_t i = 1; ; i++) {  // start at 1, skipping self
        if (!!my_args[i] != !!other_args[i]) { return false; }
        if (!!my_vals[i] != !!other_vals[i]) { return false; }
        if (my_vals[i]) {
            if (strcmp(my_vals[i], other_vals[i])) { return false; }
        }
        if (my_args[i]) {
            CFCType *my_type    = CFCVariable_get_type(my_args[i]);
            CFCType *other_type = CFCVariable_get_type(other_args[i]);
            if (!CFCType_equals(my_type, other_type)) {
                return false;
            }

            const char *my_sym    = CFCVariable_get_name(my_args[i]);
            const char *other_sym = CFCVariable_get_name(other_args[i]);
            if (strcmp(my_sym, other_sym) != 0) {
                return false;
            }
        }
        else {
            break;
        }
    }

    // Check return types.
    CFCType *type       = CFCMethod_get_return_type(self);
    CFCType *other_type = CFCMethod_get_return_type(other);
    if (CFCType_is_object(type)) {
        // Weak validation to allow covariant object return types.
        if (!CFCType_is_object(other_type)) { return false; }
        if (!CFCType_similar(type, other_type)) { return false; }
    }
    else {
        if (!CFCType_equals(type, other_type)) { return false; }
    }

    return true;
}

void
CFCMethod_override(CFCMethod *self, CFCMethod *orig) {
    // Check that the override attempt is legal.
    if (CFCMethod_final(orig)) {
        const char *orig_name  = CFCMethod_get_name(orig);
        CFCUtil_die("Attempt to override final method '%s' from '%s' by '%s'",
                    orig_name, orig->fresh_class_name, self->fresh_class_name);
    }
    if (!CFCMethod_compatible(self, orig)) {
        const char *orig_name  = CFCMethod_get_name(orig);
        CFCUtil_die("Non-matching signatures for method '%s' in '%s' and '%s'",
                    orig_name, orig->fresh_class_name, self->fresh_class_name);
    }

    // Mark the Method as no longer novel.
    self->is_novel = false;

    // Cache novel method.
    CFCMethod *novel_method = orig->is_novel ? orig : orig->novel_method;
    self->novel_method = (CFCMethod*)CFCBase_incref((CFCBase*)novel_method);
}

CFCMethod*
CFCMethod_finalize(CFCMethod *self) {
    const char *exposure   = CFCMethod_get_exposure(self);
    const char *name       = CFCMethod_get_name(self);
    CFCMethod  *finalized
        = CFCMethod_new(exposure, name,
                        self->callable.return_type,
                        self->callable.param_list,
                        self->callable.docucomment,
                        self->fresh_class_name, true, self->is_abstract);
    finalized->novel_method
        = (CFCMethod*)CFCBase_incref((CFCBase*)self->novel_method);
    finalized->is_novel = self->is_novel;
    return finalized;
}

int
CFCMethod_can_be_bound(CFCMethod *method) {
    /*
     * Check for
     * - private methods
     * - methods with types which cannot be mapped automatically
     */
    return !CFCSymbol_private((CFCSymbol*)method)
           && CFCCallable_can_be_bound((CFCCallable*)method);
}

void
CFCMethod_read_host_data_json(CFCMethod *self, CFCJson *hash,
                              const char *path) {
    int         excluded = false;
    const char *alias    = NULL;

    CFCJson **children = CFCJson_get_children(hash);
    for (int i = 0; children[i]; i += 2) {
        const char *key = CFCJson_get_string(children[i]);

        if (strcmp(key, "excluded") == 0) {
            excluded = CFCJson_get_bool(children[i+1]);
        }
        else if (strcmp(key, "alias") == 0) {
            alias = CFCJson_get_string(children[i+1]);
        }
        else {
            CFCUtil_die("Unexpected key '%s' in '%s'", key, path);
        }
    }

    if (excluded) {
        CFCMethod_exclude_from_host(self);
    }
    else if (alias) {
        CFCMethod_set_host_alias(self, alias);
    }
}

void
CFCMethod_set_host_alias(CFCMethod *self, const char *alias) {
    if (!alias || !alias[0]) {
        CFCUtil_die("Missing required param 'alias'");
    }
    if (!self->is_novel) {
        const char *name = CFCMethod_get_name(self);
        CFCUtil_die("Can't set_host_alias %s -- method %s not novel in %s",
                    alias, name, self->fresh_class_name);
    }
    if (self->host_alias) {
        const char *name = CFCMethod_get_name(self);
        if (strcmp(self->host_alias, alias) == 0) { return; }
        CFCUtil_die("Can't set_host_alias %s -- already set to %s for method"
                    " %s in %s", alias, self->host_alias, name,
                    self->fresh_class_name);
    }
    self->host_alias = CFCUtil_strdup(alias);
}

const char*
CFCMethod_get_host_alias(CFCMethod *self) {
    CFCMethod *novel_method = CFCMethod_find_novel_method(self);
    return novel_method->host_alias;
}

void
CFCMethod_exclude_from_host(CFCMethod *self) {
    if (!self->is_novel) {
        const char *name = CFCMethod_get_name(self);
        CFCUtil_die("Can't exclude_from_host -- method %s not novel in %s",
                    name, self->fresh_class_name);
    }
    self->is_excluded = true;
}

int
CFCMethod_excluded_from_host(CFCMethod *self) {
    CFCMethod *novel_method = CFCMethod_find_novel_method(self);
    return novel_method->is_excluded;
}

CFCMethod*
CFCMethod_find_novel_method(CFCMethod *self) {
    if (self->is_novel) {
        return self;
    }
    else {
        return self->novel_method;
    }
}

static char*
S_short_method_sym(CFCMethod *self, CFCClass *invoker, const char *postfix) {
    const char *nickname = CFCClass_get_nickname(invoker);
    const char *name     = CFCMethod_get_name(self);
    return CFCUtil_sprintf("%s_%s%s", nickname, name, postfix);
}

static char*
S_full_method_sym(CFCMethod *self, CFCClass *invoker, const char *postfix) {
    const char *PREFIX   = CFCClass_get_PREFIX(invoker);
    const char *nickname = CFCClass_get_nickname(invoker);
    const char *name     = CFCMethod_get_name(self);
    return CFCUtil_sprintf("%s%s_%s%s", PREFIX, nickname, name, postfix);
}

char*
CFCMethod_short_method_sym(CFCMethod *self, CFCClass *invoker) {
    return S_short_method_sym(self, invoker, "");
}

char*
CFCMethod_full_method_sym(CFCMethod *self, CFCClass *invoker) {
    return S_full_method_sym(self, invoker, "");
}

char*
CFCMethod_full_offset_sym(CFCMethod *self, CFCClass *invoker) {
    return S_full_method_sym(self, invoker, "_OFFSET");
}

const char*
CFCMethod_get_name(CFCMethod *self) {
    return CFCSymbol_get_name((CFCSymbol*)self);
}

char*
CFCMethod_short_typedef(CFCMethod *self, CFCClass *invoker) {
    return S_short_method_sym(self, invoker, "_t");
}

char*
CFCMethod_full_typedef(CFCMethod *self, CFCClass *invoker) {
    return S_full_method_sym(self, invoker, "_t");
}

char*
CFCMethod_full_override_sym(CFCMethod *self, CFCClass *klass) {
    const char *Prefix   = CFCClass_get_Prefix(klass);
    const char *nickname = CFCClass_get_nickname(klass);
    const char *name     = CFCMethod_get_name(self);
    return CFCUtil_sprintf("%s%s_%s_OVERRIDE", Prefix, nickname, name);
}

int
CFCMethod_final(CFCMethod *self) {
    return self->is_final;
}

int
CFCMethod_abstract(CFCMethod *self) {
    return self->is_abstract;
}

int
CFCMethod_novel(CFCMethod *self) {
    return self->is_novel;
}

CFCType*
CFCMethod_self_type(CFCMethod *self) {
    CFCVariable **vars = CFCParamList_get_variables(self->callable.param_list);
    return CFCVariable_get_type(vars[0]);
}

const char*
CFCMethod_get_exposure(CFCMethod *self) {
    return CFCSymbol_get_exposure((CFCSymbol*)self);
}

int
CFCMethod_is_fresh(CFCMethod *self, CFCClass *klass) {
    const char *class_name = CFCClass_get_name(klass);
    return strcmp(self->fresh_class_name, class_name) == 0;
}

int
CFCMethod_public(CFCMethod *self) {
    return CFCSymbol_public((CFCSymbol*)self);
}

CFCType*
CFCMethod_get_return_type(CFCMethod *self) {
    return self->callable.return_type;
}

CFCParamList*
CFCMethod_get_param_list(CFCMethod *self) {
    return self->callable.param_list;
}

char*
CFCMethod_imp_func(CFCMethod *self, CFCClass *klass) {
    CFCClass *ancestor = klass;

    while (ancestor) {
        if (CFCMethod_is_fresh(self, ancestor)) { break; }
        ancestor = CFCClass_get_parent(ancestor);
    }
    if (!ancestor) {
        CFCUtil_die("No fresh method implementation found for '%s' in '%s'",
                    CFCMethod_get_name(self), CFCClass_get_name(klass));
    }

    return S_full_method_sym(self, ancestor, "_IMP");
}

char*
CFCMethod_short_imp_func(CFCMethod *self, CFCClass *klass) {
    return S_short_method_sym(self, klass, "_IMP");
}

