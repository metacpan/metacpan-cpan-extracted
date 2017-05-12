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
#include <stdio.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCPerlClass.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCFunction.h"
#include "CFCDocuComment.h"
#include "CFCSymbol.h"
#include "CFCVariable.h"
#include "CFCType.h"
#include "CFCPerlPod.h"
#include "CFCPerlSub.h"
#include "CFCPerlMethod.h"
#include "CFCPerlConstructor.h"
#include "CFCPerlTypeMap.h"

struct CFCPerlClass {
    CFCBase base;
    CFCParcel *parcel;
    char *class_name;
    CFCClass *client;
    char *xs_code;
    CFCPerlPod *pod_spec;
    char **cons_aliases;
    char **cons_inits;
    size_t num_cons;
    int    exclude_cons;
    char **class_aliases;
    size_t num_class_aliases;
};

static CFCPerlClass **registry = NULL;
static size_t registry_size = 0;
static size_t registry_cap  = 0;

static const CFCMeta CFCPERLCLASS_META = {
    "Clownfish::CFC::Binding::Perl::Class",
    sizeof(CFCPerlClass),
    (CFCBase_destroy_t)CFCPerlClass_destroy
};

CFCPerlClass*
CFCPerlClass_new(CFCParcel *parcel, const char *class_name) {
    CFCPerlClass *self = (CFCPerlClass*)CFCBase_allocate(&CFCPERLCLASS_META);
    return CFCPerlClass_init(self, parcel, class_name);
}

CFCPerlClass*
CFCPerlClass_init(CFCPerlClass *self, CFCParcel *parcel,
                  const char *class_name) {
    CFCUTIL_NULL_CHECK(class_name);

    // Client may be NULL, since fetch_singleton() does not always succeed.
    CFCClass *client = CFCClass_fetch_singleton(class_name);
    if (client == NULL) {
        if (parcel == NULL) {
            CFCUtil_die("Missing parcel for class %s", class_name);
        }
    }
    else {
        CFCParcel *client_parcel = CFCClass_get_parcel(client);

        if (parcel == NULL) {
            parcel = client_parcel;
        }
        else if (client_parcel != parcel) {
            CFCUtil_die("Wrong parcel %s for class %s",
                        CFCParcel_get_name(parcel), class_name);
        }
    }

    self->parcel = (CFCParcel*)CFCBase_incref((CFCBase*)parcel);
    self->class_name = CFCUtil_strdup(class_name);
    self->client = (CFCClass*)CFCBase_incref((CFCBase*)client);
    self->pod_spec          = NULL;
    self->xs_code           = NULL;
    self->cons_aliases      = NULL;
    self->cons_inits        = NULL;
    self->num_cons          = 0;
    self->exclude_cons      = 0;
    self->class_aliases     = (char**)CALLOCATE(1, sizeof(char*));
    self->num_class_aliases = 0;
    return self;
}

void
CFCPerlClass_destroy(CFCPerlClass *self) {
    CFCBase_decref((CFCBase*)self->parcel);
    CFCBase_decref((CFCBase*)self->client);
    CFCBase_decref((CFCBase*)self->pod_spec);
    FREEMEM(self->class_name);
    FREEMEM(self->xs_code);
    for (size_t i = 0; i < self->num_cons; i++) {
        FREEMEM(self->cons_aliases[i]);
        FREEMEM(self->cons_inits[i]);
    }
    FREEMEM(self->cons_aliases);
    FREEMEM(self->cons_inits);
    CFCUtil_free_string_array(self->class_aliases);
    CFCBase_destroy((CFCBase*)self);
}

static int
S_compare_cfcperlclass(const void *va, const void *vb) {
    CFCPerlClass *a = *(CFCPerlClass**)va;
    CFCPerlClass *b = *(CFCPerlClass**)vb;
    return strcmp(a->class_name, b->class_name);
}

void
CFCPerlClass_add_to_registry(CFCPerlClass *self) {
    if (registry_size == registry_cap) {
        size_t new_cap = registry_cap + 10;
        registry = (CFCPerlClass**)REALLOCATE(registry,
                                              (new_cap + 1) * sizeof(CFCPerlClass*));
        for (size_t i = registry_cap; i <= new_cap; i++) {
            registry[i] = NULL;
        }
        registry_cap = new_cap;
    }
    CFCPerlClass *existing = CFCPerlClass_singleton(self->class_name);
    if (existing) {
        CFCUtil_die("Class '%s' already registered", self->class_name);
    }
    registry[registry_size] = (CFCPerlClass*)CFCBase_incref((CFCBase*)self);
    registry_size++;
    qsort(registry, registry_size, sizeof(CFCPerlClass*),
          S_compare_cfcperlclass);
}

CFCPerlClass*
CFCPerlClass_singleton(const char *class_name) {
    CFCUTIL_NULL_CHECK(class_name);
    for (size_t i = 0; i < registry_size; i++) {
        CFCPerlClass *existing = registry[i];
        if (strcmp(class_name, existing->class_name) == 0) {
            return existing;
        }
    }
    return NULL;
}

CFCPerlClass**
CFCPerlClass_registry() {
    if (!registry) {
        registry = (CFCPerlClass**)CALLOCATE(1, sizeof(CFCPerlClass*));
    }
    return registry;
}

void
CFCPerlClass_clear_registry(void) {
    for (size_t i = 0; i < registry_size; i++) {
        CFCBase_decref((CFCBase*)registry[i]);
    }
    FREEMEM(registry);
    registry_size = 0;
    registry_cap  = 0;
    registry      = NULL;
}

void
CFCPerlClass_bind_method(CFCPerlClass *self, const char *alias,
                         const char *meth_name) {
    if (!self->client) {
        CFCUtil_die("Can't bind_method %s -- can't find client for %s",
                    alias, self->class_name);
    }
    CFCMethod *method = CFCClass_method(self->client, meth_name);
    if (!method) {
        CFCUtil_die("Can't bind_method %s -- can't find method %s in %s",
                    alias, meth_name, self->class_name);
    }
    if (!CFCMethod_is_fresh(method, self->client)) {
        CFCUtil_die("Can't bind_method %s -- method %s not fresh in %s",
                    alias, meth_name, self->class_name);
    }
    CFCMethod_set_host_alias(method, alias);
}

void
CFCPerlClass_exclude_method(CFCPerlClass *self, const char *meth_name) {
    if (!self->client) {
        CFCUtil_die("Can't exclude_method %s -- can't find client for %s",
                    meth_name, self->class_name);
    }
    CFCMethod *method = CFCClass_method(self->client, meth_name);
    if (!method) {
        CFCUtil_die("Can't exclude_method %s -- method not found in %s",
                    meth_name, self->class_name);
    }
    if (!CFCMethod_is_fresh(method, self->client)) {
        CFCUtil_die("Can't exclude_method %s -- method not fresh in %s",
                    meth_name, self->class_name);
    }
    CFCMethod_exclude_from_host(method);
}

void
CFCPerlClass_bind_constructor(CFCPerlClass *self, const char *alias,
                              const char *initializer) {
    alias       = alias       ? alias       : "new";
    initializer = initializer ? initializer : "init";
    size_t size = (self->num_cons + 1) * sizeof(char*);
    self->cons_aliases = (char**)REALLOCATE(self->cons_aliases, size);
    self->cons_inits   = (char**)REALLOCATE(self->cons_inits,   size);
    self->cons_aliases[self->num_cons] = (char*)CFCUtil_strdup(alias);
    self->cons_inits[self->num_cons]   = (char*)CFCUtil_strdup(initializer);
    self->num_cons++;
    if (!self->client) {
        CFCUtil_die("Can't bind_constructor %s -- can't find client for %s",
                    alias, self->class_name);
    }
}

void
CFCPerlClass_exclude_constructor(CFCPerlClass *self) {
    self->exclude_cons = 1;
}

CFCPerlMethod**
CFCPerlClass_method_bindings(CFCClass *klass) {
    size_t          num_bound     = 0;
    CFCMethod     **fresh_methods = CFCClass_fresh_methods(klass);
    CFCPerlMethod **bound 
        = (CFCPerlMethod**)CALLOCATE(1, sizeof(CFCPerlMethod*));

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

        /* Create the binding, add it to the array.
         *
         * Also create an XSub binding for each override.  Each of these
         * directly calls the implementing function, rather than invokes the
         * method on the object using vtable method dispatch.  Doing things
         * this way allows SUPER:: invocations from Perl-space to work
         * properly.
         */
        CFCPerlMethod *meth_binding = CFCPerlMethod_new(klass, method);
        size_t size = (num_bound + 2) * sizeof(CFCPerlMethod*);
        bound = (CFCPerlMethod**)REALLOCATE(bound, size);
        bound[num_bound] = meth_binding;
        num_bound++;
        bound[num_bound] = NULL;
    }

    return bound;
}

static const char NEW[] = "new";

CFCPerlConstructor**
CFCPerlClass_constructor_bindings(CFCClass *klass) {
    const char    *class_name = CFCClass_get_name(klass);
    CFCPerlClass  *perl_class = CFCPerlClass_singleton(class_name);
    CFCFunction  **functions  = CFCClass_functions(klass);
    size_t         num_bound  = 0;
    CFCPerlConstructor **bound 
        = (CFCPerlConstructor**)CALLOCATE(1, sizeof(CFCPerlConstructor*));

    // Iterate over the list of possible initialization functions.
    for (size_t i = 0; functions[i] != NULL; i++) {
        CFCFunction  *function  = functions[i];
        const char   *func_name = CFCFunction_get_name(function);
        const char   *alias     = NULL;

        // Find user-specified alias.
        if (perl_class == NULL) {
            // Bind init() to new() when possible.
            if (strcmp(func_name, "init") == 0
                && CFCFunction_can_be_bound(function)
               ) {
                alias = NEW;
            }
        }
        else {
            for (size_t j = 0; j < perl_class->num_cons; j++) {
                if (strcmp(func_name, perl_class->cons_inits[j]) == 0) {
                    alias = perl_class->cons_aliases[j];
                    if (!CFCFunction_can_be_bound(function)) {
                        CFCUtil_die("Can't bind %s as %s"
                                    " -- types can't be mapped",
                                    func_name, alias);
                    }
                    break;
                }
            }

            // Automatically bind init() to new() when possible.
            if (!alias
                && !perl_class->exclude_cons
                && strcmp(func_name, "init") == 0
                && CFCFunction_can_be_bound(function)
               ) {
                int saw_new = 0;
                for (size_t j = 0; j < perl_class->num_cons; j++) {
                    if (strcmp(perl_class->cons_aliases[j], "new") == 0) {
                        saw_new = 1;
                    }
                }
                if (!saw_new) {
                    alias = NEW;
                }
            }
        }

        if (!alias) {
            continue;
        }

        // Create the binding, add it to the array.
        CFCPerlConstructor *cons_binding
            = CFCPerlConstructor_new(klass, alias, func_name);
        size_t size = (num_bound + 2) * sizeof(CFCPerlConstructor*);
        bound = (CFCPerlConstructor**)REALLOCATE(bound, size);
        bound[num_bound] = cons_binding;
        num_bound++;
        bound[num_bound] = NULL;
    }

    return bound;
}

char*
CFCPerlClass_create_pod(CFCPerlClass *self) {
    CFCPerlPod *pod_spec   = self->pod_spec;
    const char *class_name = self->class_name;
    CFCClass   *client     = self->client;
    if (!pod_spec) {
        return NULL;
    }
    if (!client) {
        CFCUtil_die("No client for %s", class_name);
    }
    CFCDocuComment *docucom = CFCClass_get_docucomment(client);
    if (!docucom) {
        CFCUtil_die("No DocuComment for %s", class_name);
    }

    // Get the class's brief description.
    const char *raw_brief = CFCDocuComment_get_brief(docucom);
    char *brief = CFCPerlPod_md_to_pod(raw_brief, client, 2);

    // Get the class's long description.
    char *description;
    const char *pod_description = CFCPerlPod_get_description(pod_spec);
    if (pod_description && strlen(pod_description)) {
        description = CFCUtil_sprintf("%s\n", pod_description);
    }
    else {
        const char *raw_description = CFCDocuComment_get_long(docucom);
        description = CFCPerlPod_md_to_pod(raw_description, client, 2);
    }

    // Create SYNOPSIS.
    const char *raw_synopsis = CFCPerlPod_get_synopsis(pod_spec);
    char *synopsis = CFCUtil_strdup("");
    if (raw_synopsis && strlen(raw_synopsis)) {
        synopsis = CFCUtil_cat(synopsis, "=head1 SYNOPSIS\n\n", raw_synopsis,
                               "\n", NULL);
    }

    // Create CONSTRUCTORS.
    char *constructor_pod = CFCPerlPod_constructors_pod(pod_spec, client);

    // Create METHODS, possibly including an ABSTRACT METHODS section.
    char *methods_pod = CFCPerlPod_methods_pod(pod_spec, client);

    // Build an INHERITANCE section describing class ancestry.
    char *inheritance = CFCUtil_strdup("");
    if (CFCClass_get_parent(client)) {
        inheritance = CFCUtil_cat(inheritance, "=head1 INHERITANCE\n\n",
                                  class_name, NULL);
        CFCClass *ancestor = client;
        while (NULL != (ancestor = CFCClass_get_parent(ancestor))) {
            const char *ancestor_klass = CFCClass_get_name(ancestor);
            if (CFCPerlClass_singleton(ancestor_klass)) {
                inheritance = CFCUtil_cat(inheritance, " isa L<",
                                          ancestor_klass, ">", NULL);
            }
            else {
                inheritance = CFCUtil_cat(inheritance, " isa ",
                                          ancestor_klass, NULL);
            }
        }
        inheritance = CFCUtil_cat(inheritance, ".\n\n", NULL);
    }

    // Put it all together.
    const char pattern[] =
        "=encoding utf8\n"
        "\n"
        "=head1 NAME\n"
        "\n"
        "%s - %s"
        "%s"
        "=head1 DESCRIPTION\n"
        "\n"
        "%s"
        "%s"
        "%s"
        "%s"
        "=cut\n"
        "\n";
    char *pod
        = CFCUtil_sprintf(pattern, class_name, brief, synopsis, description,
                          constructor_pod, methods_pod, inheritance);

    FREEMEM(brief);
    FREEMEM(synopsis);
    FREEMEM(description);
    FREEMEM(constructor_pod);
    FREEMEM(methods_pod);
    FREEMEM(inheritance);

    return pod;
}

CFCClass*
CFCPerlClass_get_client(CFCPerlClass *self) {
    return self->client;
}

const char*
CFCPerlClass_get_class_name(CFCPerlClass *self) {
    return self->class_name;
}

void
CFCPerlClass_append_xs(CFCPerlClass *self, const char *xs) {
    if (!self->xs_code) {
        self->xs_code = CFCUtil_strdup("");
    }
    self->xs_code = CFCUtil_cat(self->xs_code, xs, NULL);
}

const char*
CFCPerlClass_get_xs_code(CFCPerlClass *self) {
    return self->xs_code;
}

void
CFCPerlClass_set_pod_spec(CFCPerlClass *self, CFCPerlPod *pod_spec) {
    CFCPerlPod *old_pod_spec = self->pod_spec;
    self->pod_spec = (CFCPerlPod*)CFCBase_incref((CFCBase*)pod_spec);
    CFCBase_decref((CFCBase*)old_pod_spec);
}

CFCPerlPod*
CFCPerlClass_get_pod_spec(CFCPerlClass *self) {
    return self->pod_spec;
}

void
CFCPerlClass_add_class_alias(CFCPerlClass *self, const char *alias) {
    for (size_t i = 0; i < self->num_class_aliases; i++) {
        if (strcmp(alias, self->class_aliases[i]) == 0) {
            CFCUtil_die("Alias '%s' already added for class '%s'", alias,
                        self->class_name);
        }
    }
    size_t size = (self->num_class_aliases + 2) * sizeof(char*);
    self->class_aliases = (char**)REALLOCATE(self->class_aliases, size);
    self->class_aliases[self->num_class_aliases] = CFCUtil_strdup(alias);
    self->num_class_aliases++;
    self->class_aliases[self->num_class_aliases] = NULL;
}

const char**
CFCPerlClass_get_class_aliases(CFCPerlClass *self) {
    return (const char **)self->class_aliases;
}

// Generate C code which initializes method metadata.
char*
CFCPerlClass_method_metadata_code(CFCPerlClass *self) {
    const char *class_var = CFCClass_full_class_var(self->client);
    CFCMethod **fresh_methods = CFCClass_fresh_methods(self->client);
    char *code = CFCUtil_strdup("");

    for (int i = 0; fresh_methods[i] != NULL; i++) {
        CFCMethod *method = fresh_methods[i];
        if (!CFCMethod_novel(method)) { continue; }

        const char *meth_name = CFCMethod_get_name(method);
        const char *alias     = CFCMethod_get_host_alias(method);
        if (alias) {
            code = CFCUtil_cat(code, "    CFISH_Class_Add_Host_Method_Alias(",
                               class_var, ", \"", alias, "\", \"", meth_name,
                               "\");\n", NULL);
        }
        if (CFCMethod_excluded_from_host(method)) {
            code = CFCUtil_cat(code, "    CFISH_Class_Exclude_Host_Method(",
                               class_var, ", \"", meth_name, "\");\n", NULL);
        }
    }

    return code;
}

CFCParcel*
CFCPerlClass_get_parcel(CFCPerlClass *self) {
    return self->parcel;
}

