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
#include <stdlib.h>

#ifndef true
#define true 1
#define false 0
#endif

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCGoClass.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCFunction.h"
#include "CFCSymbol.h"
#include "CFCVariable.h"
#include "CFCType.h"
#include "CFCGoFunc.h"
#include "CFCGoMethod.h"
#include "CFCGoTypeMap.h"

struct CFCGoClass {
    CFCBase base;
    CFCParcel *parcel;
    char *class_name;
    CFCClass *client;
    CFCGoMethod **method_bindings;
    size_t num_bound;
    int suppress_struct;
    int suppress_ctor;
};

static CFCGoClass **registry = NULL;
static size_t registry_size = 0;
static size_t registry_cap  = 0;

static void
S_CFCGoClass_destroy(CFCGoClass *self);

static void
S_lazy_init_method_bindings(CFCGoClass *self);

static const CFCMeta CFCGOCLASS_META = {
    "Clownfish::CFC::Binding::Go::Class",
    sizeof(CFCGoClass),
    (CFCBase_destroy_t)S_CFCGoClass_destroy
};

CFCGoClass*
CFCGoClass_new(CFCParcel *parcel, const char *class_name) {
    CFCUTIL_NULL_CHECK(parcel);
    CFCUTIL_NULL_CHECK(class_name);
    CFCGoClass *self = (CFCGoClass*)CFCBase_allocate(&CFCGOCLASS_META);
    self->parcel = (CFCParcel*)CFCBase_incref((CFCBase*)parcel);
    self->class_name = CFCUtil_strdup(class_name);
    // Client may be NULL, since fetch_singleton() does not always succeed.
    CFCClass *client = CFCClass_fetch_singleton(class_name);
    self->client = (CFCClass*)CFCBase_incref((CFCBase*)client);
    return self;
}

static void
S_CFCGoClass_destroy(CFCGoClass *self) {
    CFCBase_decref((CFCBase*)self->parcel);
    CFCBase_decref((CFCBase*)self->client);
    FREEMEM(self->class_name);
    for (int i = 0; self->method_bindings[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->method_bindings[i]);
    }
    FREEMEM(self->method_bindings);
    CFCBase_destroy((CFCBase*)self);
}

static int
S_compare_cfcgoclass(const void *va, const void *vb) {
    CFCGoClass *a = *(CFCGoClass**)va;
    CFCGoClass *b = *(CFCGoClass**)vb;
    return strcmp(a->class_name, b->class_name);
}

void
CFCGoClass_register(CFCGoClass *self) {
    if (registry_size == registry_cap) {
        size_t new_cap = registry_cap + 10;
        size_t amount = (new_cap + 1) * sizeof(CFCGoClass*);
        registry = (CFCGoClass**)REALLOCATE(registry, amount);
        for (size_t i = registry_cap; i <= new_cap; i++) {
            registry[i] = NULL;
        }
        registry_cap = new_cap;
    }
    CFCGoClass *existing = CFCGoClass_singleton(self->class_name);
    if (existing) {
        CFCUtil_die("Class '%s' already registered", self->class_name);
    }
    registry[registry_size] = (CFCGoClass*)CFCBase_incref((CFCBase*)self);
    registry_size++;
    qsort(registry, registry_size, sizeof(CFCGoClass*),
          S_compare_cfcgoclass);
}

CFCGoClass*
CFCGoClass_singleton(const char *class_name) {
    CFCUTIL_NULL_CHECK(class_name);
    for (size_t i = 0; i < registry_size; i++) {
        CFCGoClass *existing = registry[i];
        if (strcmp(class_name, existing->class_name) == 0) {
            return existing;
        }
    }
    return NULL;
}

CFCClass*
CFCGoClass_get_client(CFCGoClass *self) {
    if (!self->client) {
        CFCClass *client = CFCClass_fetch_singleton(self->class_name);
        self->client = (CFCClass*)CFCBase_incref((CFCBase*)client);
    }
    return self->client;
}

CFCGoClass**
CFCGoClass_registry() {
    if (!registry) {
        registry = (CFCGoClass**)CALLOCATE(1, sizeof(CFCGoClass*));
    }
    return registry;
}

void
CFCGoClass_clear_registry(void) {
    for (size_t i = 0; i < registry_size; i++) {
        CFCBase_decref((CFCBase*)registry[i]);
    }
    FREEMEM(registry);
    registry_size = 0;
    registry_cap  = 0;
    registry      = NULL;
}

char*
CFCGoClass_go_typing(CFCGoClass *self) {
    char *content = NULL;
    if (!self->client) {
        CFCUtil_die("Can't find class for %s", self->class_name);
    }
    else if (CFCClass_inert(self->client)) {
        content = CFCUtil_strdup("");
    } else {
        const char *short_struct = CFCClass_get_struct_sym(self->client);

        CFCClass *parent = CFCClass_get_parent(self->client);
        char *parent_type_str = NULL;
        if (parent) {
            const char *parent_struct = CFCClass_get_struct_sym(parent);
            CFCParcel *parent_parcel = CFCClass_get_parcel(parent);
            if (parent_parcel == self->parcel) {
                parent_type_str = CFCUtil_strdup(parent_struct);
            }
            else {
                char *parent_package
                    = CFCGoTypeMap_go_short_package(parent_parcel);
                parent_type_str = CFCUtil_sprintf("%s.%s", parent_package,
                                                  parent_struct);
                FREEMEM(parent_package);
            }
        }

        char *go_struct_def;
        if (parent && !self->suppress_struct) {
            go_struct_def
                = CFCUtil_sprintf("type %sIMP struct {\n\t%sIMP\n}\n",
                                  short_struct, parent_type_str);
        }
        else {
            go_struct_def = CFCUtil_strdup("");
        }

        char *parent_iface;
        if (parent) {
            parent_iface = CFCUtil_sprintf("\t%s\n", parent_type_str);
        }
        else {
            parent_iface = CFCUtil_strdup("");
        }

        char *novel_iface = CFCUtil_strdup("");
        S_lazy_init_method_bindings(self);
        for (int i = 0; self->method_bindings[i] != NULL; i++) {
            CFCGoMethod *meth_binding = self->method_bindings[i];
            CFCMethod *method = CFCGoMethod_get_client(meth_binding);
            if (method) {
                if (!CFCMethod_novel(method)) {
                    continue;
                }
                const char *sym = CFCMethod_get_name(method);
                if (!CFCClass_fresh_method(self->client, sym)) {
                    continue;
                }
            }

            const char *sig = CFCGoMethod_get_sig(meth_binding, self->client);
            novel_iface = CFCUtil_cat(novel_iface, "\t", sig, "\n", NULL);
        }

        char pattern[] =
            "type %s interface {\n"
            "%s"
            "%s"
            "}\n"
            "\n"
            "%s"
            ;
        content = CFCUtil_sprintf(pattern, short_struct, parent_iface,
                                  novel_iface, go_struct_def);
        FREEMEM(parent_type_str);
        FREEMEM(go_struct_def);
        FREEMEM(parent_iface);
    }
    return content;
}

char*
CFCGoClass_boilerplate_funcs(CFCGoClass *self) {
    char *content = NULL;
    if (!self->client) {
        CFCUtil_die("Can't find class for %s", self->class_name);
    }
    else if (CFCClass_inert(self->client)) {
        content = CFCUtil_strdup("");
    } else {
        const char *clownfish_dot = CFCParcel_is_cfish(self->parcel)
                                    ? "" : "clownfish.";
        const char *short_struct = CFCClass_get_struct_sym(self->client);
        char pattern[] =
            "func WRAP%s(ptr unsafe.Pointer) %s {\n"
            "\tobj := &%sIMP{}\n"
            "\tobj.INITOBJ(ptr)\n"
            "\treturn obj\n"
            "}\n"
            "\n"
            "func WRAP%sASOBJ(ptr unsafe.Pointer) %sObj {\n"
            "\treturn WRAP%s(ptr)\n"
            "}\n"
            ;

        content = CFCUtil_sprintf(pattern, short_struct, short_struct,
                                  short_struct, short_struct, clownfish_dot,
                                  short_struct);
    }
    return content;
}


char*
CFCGoClass_gen_ctors(CFCGoClass *self) {
    CFCFunction *ctor_func = CFCClass_function(self->client, "new");
    if (self->suppress_ctor
        || !ctor_func
        || !CFCFunction_can_be_bound(ctor_func)
       ) {
        return CFCUtil_strdup("");
    }
    CFCParcel    *parcel     = CFCClass_get_parcel(self->client);
    CFCParamList *param_list = CFCFunction_get_param_list(ctor_func);
    CFCType      *ret_type   = CFCFunction_get_return_type(ctor_func);
    const char   *struct_sym = CFCClass_get_struct_sym(self->client);
    char         *name       = CFCUtil_sprintf("New%s", struct_sym);
    char         *cfunc  = CFCFunction_full_func_sym(ctor_func, self->client);
    char         *cfargs = CFCGoFunc_ctor_cfargs(parcel, param_list);
    char *first_line
        = CFCGoFunc_ctor_start(parcel, name, param_list, ret_type);
    char *ret_statement
        = CFCGoFunc_return_statement(parcel, ret_type, "retvalCF");

    char pattern[] =
        "%s"
        "\tretvalCF := C.%s(%s)\n"
        "%s"
        "}\n"
        ;
    char *content = CFCUtil_sprintf(pattern, first_line, cfunc,
                                    cfargs, ret_statement);

    FREEMEM(ret_statement);
    FREEMEM(cfargs);
    FREEMEM(cfunc);
    FREEMEM(first_line);
    FREEMEM(name);
    return content;
}

static void
S_lazy_init_method_bindings(CFCGoClass *self) {
    if (self->method_bindings) {
        return;
    }
    CFCUTIL_NULL_CHECK(self->client);
    size_t        num_bound     = 0;
    CFCMethod   **fresh_methods = CFCClass_fresh_methods(self->client);
    CFCGoMethod **bound
        = (CFCGoMethod**)CALLOCATE(1, sizeof(CFCGoMethod*));

     // Iterate over the class's fresh methods.
    for (size_t i = 0; fresh_methods[i] != NULL; i++) {
        CFCMethod *method = fresh_methods[i];

        // Skip methods which have been explicitly excluded.
        if (CFCMethod_excluded_from_host(method)) {
            continue;
        }

        // Skip methods that shouldn't be bound.
        if (!CFCMethod_can_be_bound(method)) {
            continue;
        }

        // Only include novel methods.
        if (!CFCMethod_novel(method)) {
            continue;
        }
        const char *sym = CFCMethod_get_name(method);
        if (!CFCClass_fresh_method(self->client, sym)) {
            continue;
        }

        /* Create the binding, add it to the array.
         */
        CFCGoMethod *meth_binding = CFCGoMethod_new(method);
        size_t size = (num_bound + 2) * sizeof(CFCGoMethod*);
        bound = (CFCGoMethod**)REALLOCATE(bound, size);
        bound[num_bound] = meth_binding;
        num_bound++;
        bound[num_bound] = NULL;
    }

    self->method_bindings = bound;
    self->num_bound       = num_bound;
}

char*
CFCGoClass_gen_meth_glue(CFCGoClass *self) {
    S_lazy_init_method_bindings(self);
    char *meth_defs = CFCUtil_strdup("");
    for (size_t i = 0; self->method_bindings[i] != NULL; i++) {
        CFCGoMethod *meth_binding = self->method_bindings[i];
        char *method_def
            = CFCGoMethod_func_def(meth_binding, self->client);
        meth_defs = CFCUtil_cat(meth_defs, method_def, "\n", NULL);
        FREEMEM(method_def);
    }
    return meth_defs;
}

char*
CFCGoClass_gen_wrap_func_reg(CFCGoClass *self) {
    if (CFCClass_inert(self->client)) {
        return CFCUtil_strdup("");
    }
    char pattern[] =
        "\t\tunsafe.Pointer(C.%s): WRAP%sASOBJ,\n";

    const char *short_struct = CFCClass_get_struct_sym(self->client);
    const char *class_var = CFCClass_full_class_var(self->client);
    return CFCUtil_sprintf(pattern, class_var, short_struct);
}

void
CFCGoClass_spec_method(CFCGoClass *self, const char *name, const char *sig) {
    CFCUTIL_NULL_CHECK(sig);
    S_lazy_init_method_bindings(self);
    if (!name) {
        CFCGoMethod *meth_binding = CFCGoMethod_new(NULL);
        CFCGoMethod_customize(meth_binding, sig);

        size_t size = (self->num_bound + 2) * sizeof(CFCGoMethod*);
        self->method_bindings
            = (CFCGoMethod**)REALLOCATE(self->method_bindings, size);
        self->method_bindings[self->num_bound] = meth_binding;
        self->num_bound++;
        self->method_bindings[self->num_bound] = NULL;
    }
    else {
        CFCGoMethod *binding = NULL;
        for (int i = 0; self->method_bindings[i] != NULL; i++) {
            CFCGoMethod *candidate = self->method_bindings[i];
            CFCMethod *meth = CFCGoMethod_get_client(candidate);
            if (meth && strcmp(name, CFCMethod_get_name(meth)) == 0) {
                binding = candidate;
                break;
            }
        }
        if (!binding) {
            CFCUtil_die("Can't find a method named '%s'", name);
        }
        CFCGoMethod_customize(binding, sig);
    }
}

void
CFCGoClass_set_suppress_struct(CFCGoClass *self, int suppress_struct) {
    self->suppress_struct = !!suppress_struct;
}

void
CFCGoClass_set_suppress_ctor(CFCGoClass *self, int suppress_ctor) {
    self->suppress_ctor = !!suppress_ctor;
}

