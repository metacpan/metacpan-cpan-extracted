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

#include "charmony.h"

#include <string.h>

#include <cmark.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCPerlPod.h"
#include "CFCUtil.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCParcel.h"
#include "CFCParamList.h"
#include "CFCPerlMethod.h"
#include "CFCFunction.h"
#include "CFCDocuComment.h"
#include "CFCUri.h"
#include "CFCDocument.h"
#include "CFCType.h"
#include "CFCVariable.h"
#include "CFCCallable.h"

#ifndef true
  #define true 1
  #define false 0
#endif

typedef struct NamePod {
    char *alias;
    char *func;
    char *sample;
    char *pod;
} NamePod;

struct CFCPerlPod {
    CFCBase base;
    char    *synopsis;
    char    *description;
    NamePod *methods;
    size_t   num_methods;
    NamePod *constructors;
    size_t   num_constructors;
};

static const CFCMeta CFCPERLPOD_META = {
    "Clownfish::CFC::Binding::Perl::Pod",
    sizeof(CFCPerlPod),
    (CFCBase_destroy_t)CFCPerlPod_destroy
};

static char*
S_gen_code_sample(CFCCallable *func, const char *alias, CFCClass *klass,
                  int is_constructor);

static char*
S_gen_positional_sample(const char *prologue, CFCParamList *param_list,
                        int start);

static char*
S_gen_labeled_sample(const char *prologue, CFCParamList *param_list,
                     int start);

static char*
S_perl_var_name(CFCType *type, int is_ctor_retval);

static char*
S_camel_to_lower(const char *camel);

static char*
S_nodes_to_pod(cmark_node *node, CFCClass *klass, int header_level);

static char*
S_node_to_pod(cmark_node *node, CFCClass *klass, int header_level);

static char*
S_pod_escape(const char *content);

static char*
S_convert_link(cmark_node *link, CFCClass *klass, int header_level);

static char*
S_pod_link(const char *text, const char *name);

CFCPerlPod*
CFCPerlPod_new(void) {
    CFCPerlPod *self
        = (CFCPerlPod*)CFCBase_allocate(&CFCPERLPOD_META);
    return CFCPerlPod_init(self);
}

CFCPerlPod*
CFCPerlPod_init(CFCPerlPod *self) {
    self->synopsis         = CFCUtil_strdup("");
    self->description      = CFCUtil_strdup("");
    self->methods          = NULL;
    self->constructors     = NULL;
    self->num_methods      = 0;
    self->num_constructors = 0;
    return self;
}

void
CFCPerlPod_destroy(CFCPerlPod *self) {
    FREEMEM(self->synopsis);
    FREEMEM(self->description);
    for (size_t i = 0; i < self->num_methods; i++) {
        FREEMEM(self->methods[i].alias);
        FREEMEM(self->methods[i].pod);
        FREEMEM(self->methods[i].func);
        FREEMEM(self->methods[i].sample);
    }
    FREEMEM(self->methods);
    for (size_t i = 0; i < self->num_constructors; i++) {
        FREEMEM(self->constructors[i].alias);
        FREEMEM(self->constructors[i].pod);
        FREEMEM(self->constructors[i].func);
        FREEMEM(self->constructors[i].sample);
    }
    FREEMEM(self->constructors);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCPerlPod_add_method(CFCPerlPod *self, const char *alias, const char *method,
                      const char *sample, const char *pod) {
    CFCUTIL_NULL_CHECK(alias);
    self->num_methods++;
    size_t size = self->num_methods * sizeof(NamePod);
    self->methods = (NamePod*)REALLOCATE(self->methods, size);
    NamePod *slot = &self->methods[self->num_methods - 1];
    slot->alias  = CFCUtil_strdup(alias);
    slot->func   = method ? CFCUtil_strdup(method) : NULL;
    slot->sample = sample ? CFCUtil_strdup(sample) : NULL;
    slot->pod    = pod ? CFCUtil_strdup(pod) : NULL;
}

void
CFCPerlPod_add_constructor(CFCPerlPod *self, const char *alias,
                           const char *pod_func, const char *sample,
                           const char *pod) {
    self->num_constructors++;
    size_t size = self->num_constructors * sizeof(NamePod);
    self->constructors = (NamePod*)REALLOCATE(self->constructors, size);
    NamePod *slot = &self->constructors[self->num_constructors - 1];
    slot->alias  = CFCUtil_strdup(alias ? alias : "new");
    slot->func   = pod_func ? CFCUtil_strdup(pod_func) : NULL;
    slot->sample = sample ? CFCUtil_strdup(sample) : NULL;
    slot->pod    = pod ? CFCUtil_strdup(pod) : NULL;
}

void
CFCPerlPod_set_synopsis(CFCPerlPod *self, const char *synopsis) {
    FREEMEM(self->synopsis);
    self->synopsis = CFCUtil_strdup(synopsis);
}

const char*
CFCPerlPod_get_synopsis(CFCPerlPod *self) {
    return self->synopsis;
}

void
CFCPerlPod_set_description(CFCPerlPod *self, const char *description) {
    FREEMEM(self->description);
    self->description = CFCUtil_strdup(description);
}

const char*
CFCPerlPod_get_description(CFCPerlPod *self) {
    return self->description;
}

char*
CFCPerlPod_methods_pod(CFCPerlPod *self, CFCClass *klass) {
    const char *class_name = CFCClass_get_name(klass);
    char *abstract_pod = CFCUtil_strdup("");
    char *methods_pod  = CFCUtil_strdup("");

    // Start with methods that don't map to a Clownfish method.
    for (size_t i = 0; i < self->num_methods; i++) {
        NamePod meth_spec = self->methods[i];
        CFCMethod *method = CFCClass_method(klass, meth_spec.func);
        if (method) { continue; }
        if (!meth_spec.pod) {
            CFCUtil_die("No POD specified for method '%s' in class '%s'",
                        meth_spec.alias, CFCClass_get_name(klass));
        }
        methods_pod = CFCUtil_cat(methods_pod, meth_spec.pod, "\n", NULL);
    }

    CFCMethod **fresh_methods = CFCClass_fresh_methods(klass);
    for (int meth_num = 0; fresh_methods[meth_num] != NULL; meth_num++) {
        CFCMethod *method = fresh_methods[meth_num];
        const char *name = CFCMethod_get_name(method);
        char *meth_pod = NULL;

        // Try to find custom POD for method.
        NamePod *meth_spec = NULL;
        for (size_t j = 0; j < self->num_methods; j++) {
            NamePod *candidate = &self->methods[j];
            const char *other_name = candidate->func;
            if (other_name && strcmp(other_name, name) == 0) {
                meth_spec = candidate;
                break;
            }
        }

        if (meth_spec) {
            // Found custom POD.
            if (meth_spec->pod) {
                meth_pod = CFCUtil_sprintf("%s\n", meth_spec->pod);
            }
            else {
                meth_pod
                    = CFCPerlPod_gen_subroutine_pod((CFCCallable*)method,
                                                    meth_spec->alias, klass,
                                                    meth_spec->sample,
                                                    class_name, false);
            }
        }
        else {
            // No custom POD found. Add POD for public methods with Perl
            // bindings.
            if (!CFCMethod_public(method)
                || CFCMethod_excluded_from_host(method)
                || !CFCMethod_can_be_bound(method)
               ) {
                continue;
            }

            // Only add POD for novel methods and the first implementation
            // of abstract methods.
            if (!CFCMethod_novel(method)) {
                if (CFCMethod_abstract(method)) { continue; }
                CFCClass *parent = CFCClass_get_parent(klass);
                CFCMethod *parent_method = CFCClass_method(parent, name);
                if (!CFCMethod_abstract(parent_method)) { continue; }
            }

            char *perl_name = CFCPerlMethod_perl_name(method);
            meth_pod
                = CFCPerlPod_gen_subroutine_pod((CFCCallable*)method,
                                                perl_name, klass, NULL,
                                                class_name, false);
            FREEMEM(perl_name);
        }

        if (CFCMethod_abstract(method)) {
            abstract_pod = CFCUtil_cat(abstract_pod, meth_pod, NULL);
        }
        else {
            methods_pod = CFCUtil_cat(methods_pod, meth_pod, NULL);
        }
        FREEMEM(meth_pod);
    }

    char *pod = CFCUtil_strdup("");
    if (strlen(abstract_pod)) {
        pod = CFCUtil_cat(pod, "=head1 ABSTRACT METHODS\n\n", abstract_pod, NULL);
    }
    FREEMEM(abstract_pod);
    if (strlen(methods_pod)) {
        pod = CFCUtil_cat(pod, "=head1 METHODS\n\n", methods_pod, NULL);
    }
    FREEMEM(methods_pod);

    return pod;
}

char*
CFCPerlPod_constructors_pod(CFCPerlPod *self, CFCClass *klass) {
    if (!self->num_constructors) {
        return CFCUtil_strdup("");
    }
    const char *class_name = CFCClass_get_name(klass);
    char *pod = CFCUtil_strdup("=head1 CONSTRUCTORS\n\n");
    for (size_t i = 0; i < self->num_constructors; i++) {
        NamePod slot = self->constructors[i];
        if (slot.pod) {
            pod = CFCUtil_cat(pod, slot.pod, "\n", NULL);
        }
        else {
            const char *func_name = slot.func ? slot.func : slot.alias;
            CFCFunction *pod_func = CFCClass_function(klass, func_name);
            if (!pod_func) {
                CFCUtil_die("Can't find constructor '%s' in class '%s'",
                            func_name, CFCClass_get_name(klass));
            }
            char *sub_pod
                = CFCPerlPod_gen_subroutine_pod((CFCCallable*)pod_func,
                                                slot.alias, klass, slot.sample,
                                                class_name, true);
            pod = CFCUtil_cat(pod, sub_pod, NULL);
            FREEMEM(sub_pod);
        }
    }
    return pod;
}

char*
CFCPerlPod_gen_subroutine_pod(CFCCallable *func,
                              const char *alias, CFCClass *klass,
                              const char *code_sample,
                              const char *class_name, int is_constructor) {
    const char *func_name = CFCCallable_get_name(func);

    // Only allow "public" subs to be exposed as part of the public API.
    if (!CFCCallable_public(func)) {
        CFCUtil_die("%s#%s is not public", class_name, func_name);
    }

    char *pod = CFCUtil_sprintf("=head2 %s\n\n", alias);

    // Add code sample.
    if (!code_sample) {
        char *auto_sample
            = S_gen_code_sample(func, alias, klass, is_constructor);
        pod = CFCUtil_cat(pod, auto_sample, "\n", NULL);
        FREEMEM(auto_sample);
    }
    else {
        pod = CFCUtil_cat(pod, code_sample, "\n", NULL);
    }

    // Get documentation, which may be inherited.
    CFCDocuComment *docucomment = CFCCallable_get_docucomment(func);
    if (!docucomment) {
        CFCClass *parent = klass;
        while (NULL != (parent = CFCClass_get_parent(parent))) {
            CFCCallable *parent_func
                = (CFCCallable*)CFCClass_method(parent, func_name);
            if (!parent_func) { break; }
            docucomment = CFCCallable_get_docucomment(parent_func);
            if (docucomment) { break; }
        }
    }
    if (!docucomment) {
        return pod;
    }

    // Incorporate "description" text from DocuComment.
    const char *long_doc = CFCDocuComment_get_description(docucomment);
    if (long_doc && strlen(long_doc)) {
        char *perlified = CFCPerlPod_md_to_pod(long_doc, klass, 3);
        pod = CFCUtil_cat(pod, perlified, NULL);
        FREEMEM(perlified);
    }

    // Add params in a list.
    const char**param_names = CFCDocuComment_get_param_names(docucomment);
    const char**param_docs  = CFCDocuComment_get_param_docs(docucomment);
    if (param_names[0]) {
        pod = CFCUtil_cat(pod, "=over\n\n", NULL);
        for (size_t i = 0; param_names[i] != NULL; i++) {
            char *perlified = CFCPerlPod_md_to_pod(param_docs[i], klass, 3);
            pod = CFCUtil_cat(pod, "=item *\n\nB<", param_names[i], "> - ",
                              perlified, NULL);
            FREEMEM(perlified);
        }
        pod = CFCUtil_cat(pod, "=back\n\n", NULL);
    }

    // Add return value description, if any.
    const char *retval_doc = CFCDocuComment_get_retval(docucomment);
    if (retval_doc && strlen(retval_doc)) {
        char *perlified = CFCPerlPod_md_to_pod(retval_doc, klass, 3);
        pod = CFCUtil_cat(pod, "Returns: ", perlified, NULL);
        FREEMEM(perlified);
    }

    return pod;
}

static char*
S_gen_code_sample(CFCCallable *func, const char *alias, CFCClass *klass,
                  int is_constructor) {
    char *prologue       = CFCUtil_sprintf("");
    char *class_var_name = S_camel_to_lower(CFCClass_get_struct_sym(klass));

    CFCType *ret_type = CFCCallable_get_return_type(func);
    if (!CFCType_is_void(ret_type)) {
        char *ret_name = S_perl_var_name(ret_type, is_constructor);

        if (!is_constructor && strcmp(ret_name, class_var_name) == 0) {
            // Return type equals `klass`. Use a generic variable name
            // to avoid confusing code samples like
            // `my $string = $string->trim`.
            prologue = CFCUtil_cat(prologue, "my $result = ", NULL);
        }
        else {
            prologue = CFCUtil_cat(prologue, "my $", ret_name, " = ", NULL);
        }

        FREEMEM(ret_name);
    }

    if (is_constructor) {
        const char *invocant = CFCClass_get_name(klass);
        prologue = CFCUtil_cat(prologue, invocant, NULL);
    }
    else {
        prologue = CFCUtil_cat(prologue, "$", class_var_name, NULL);
    }

    prologue = CFCUtil_cat(prologue, "->", alias, NULL);

    CFCParamList *param_list = CFCCallable_get_param_list(func);
    int           num_vars   = CFCParamList_num_vars(param_list);
    int           start      = is_constructor ? 0 : 1;
    char         *sample     = NULL;

    if (start == num_vars) {
        sample = CFCUtil_sprintf("    %s();\n", prologue);
    }
    else if (is_constructor || num_vars - start >= 2) {
        sample = S_gen_labeled_sample(prologue, param_list, start);
    }
    else {
        sample = S_gen_positional_sample(prologue, param_list, start);
    }

    FREEMEM(class_var_name);
    FREEMEM(prologue);
    return sample;
}

static char*
S_gen_positional_sample(const char *prologue, CFCParamList *param_list,
                        int start) {
    int           num_vars = CFCParamList_num_vars(param_list);
    CFCVariable **vars     = CFCParamList_get_variables(param_list);
    const char  **inits    = CFCParamList_get_initial_values(param_list);

    if (num_vars - start != 1) {
        CFCUtil_die("Code samples with multiple positional parameters"
                    " are not supported yet.");
    }

    const char *name = CFCVariable_get_name(vars[start]);
    char *sample = CFCUtil_sprintf("    %s($%s);\n", prologue, name);

    const char *init = inits[start];
    if (init) {
        if (strcmp(init, "NULL") == 0) { init = "undef"; }
        char *def_sample = CFCUtil_sprintf("    %s();  # default: %s\n",
                                           prologue, init);
        sample = CFCUtil_cat(sample, def_sample, NULL);
        FREEMEM(def_sample);
    }

    return sample;
}

static char*
S_gen_labeled_sample(const char *prologue, CFCParamList *param_list,
                     int start) {
    int           num_vars = CFCParamList_num_vars(param_list);
    CFCVariable **vars     = CFCParamList_get_variables(param_list);
    const char  **inits    = CFCParamList_get_initial_values(param_list);

    size_t max_name_len = 0;

    // Find maximum length of parameter name.
    for (int i = start; i < num_vars; i++) {
        const char *name = CFCVariable_get_name(vars[i]);
        size_t name_len = strlen(name);
        if (name_len > max_name_len) { max_name_len = name_len; }
    }

    char *params = CFCUtil_strdup("");

    for (int i = start; i < num_vars; i++) {
        const char *name            = CFCVariable_get_name(vars[i]);
        const char *init            = inits[i];
        char       *name_with_comma = CFCUtil_sprintf("%s,", name);
        char       *comment         = NULL;

        if (init) {
            if (strcmp(init, "NULL") == 0) { init = "undef"; }
            comment = CFCUtil_sprintf("default: %s", init);
        }
        else {
            comment = CFCUtil_strdup("required");
        }

        char *line = CFCUtil_sprintf("        %-*s => $%-*s  # %s\n",
                                     (int)max_name_len, name,
                                     (int)max_name_len + 1, name_with_comma,
                                     comment);
        params = CFCUtil_cat(params, line, NULL);
        FREEMEM(line);
        FREEMEM(comment);
        FREEMEM(name_with_comma);
    }

    const char pattern[] =
        "    %s(\n"
        "%s"
        "    );\n";
    char *sample = CFCUtil_sprintf(pattern, prologue, params);

    FREEMEM(params);
    return sample;
}

static char*
S_perl_var_name(CFCType *type, int is_ctor_retval) {
    const char *specifier = CFCType_get_specifier(type);
    char       *perl_name = NULL;

    if (CFCType_is_object(type)) {
        if (!is_ctor_retval && strcmp(specifier, "cfish_Vector") == 0) {
            perl_name = CFCUtil_strdup("arrayref");
        }
        else if (!is_ctor_retval && strcmp(specifier, "cfish_Hash") == 0) {
            perl_name = CFCUtil_strdup("hashref");
        }
        else {
            // Skip parcel prefix.
            if (CFCUtil_islower(*specifier)) {
                for (specifier++; *specifier; specifier++) {
                    if (*specifier == '_') {
                        specifier++;
                        break;
                    }
                }
            }

            perl_name = S_camel_to_lower(specifier);
        }
    }
    else if (CFCType_is_integer(type)) {
        if (strcmp(specifier, "bool") == 0) {
            perl_name = CFCUtil_strdup("bool");
        }
        else {
            perl_name = CFCUtil_strdup("int");
        }
    }
    else if (CFCType_is_floating(type)) {
        perl_name = CFCUtil_strdup("float");
    }
    else {
        CFCUtil_die("Don't know how to create code sample for type '%s'",
                    specifier);
    }

    return perl_name;
}

static char*
S_camel_to_lower(const char *camel) {
    if (camel[0] == '\0') { return CFCUtil_strdup(""); }

    size_t alloc = 1;
    for (size_t i = 1; camel[i]; i++) {
        if (CFCUtil_isupper(camel[i]) && CFCUtil_islower(camel[i+1])) {
            alloc += 1;
        }
        alloc += 1;
    }
    char *lower = (char*)MALLOCATE(alloc + 1);

    lower[0] = CFCUtil_tolower(camel[0]);
    size_t j = 1;
    for (size_t i = 1; camel[i]; i++) {
        // Only insert underscore if next char is lowercase.
        if (CFCUtil_isupper(camel[i]) && CFCUtil_islower(camel[i+1])) {
            lower[j++] = '_';
        }
        lower[j++] = CFCUtil_tolower(camel[i]);
    }
    lower[j] = '\0';

    return lower;
}

char*
CFCPerlPod_md_doc_to_pod(const char *module, const char *md) {
    int options = CMARK_OPT_SMART
                  | CMARK_OPT_VALIDATE_UTF8;
    cmark_node *doc = cmark_parse_document(md, strlen(md), options);
    cmark_node *maybe_header = cmark_node_first_child(doc);
    char *name;
    char *desc;

    if (maybe_header
        && cmark_node_get_type(maybe_header) == CMARK_NODE_HEADER
       ) {
        cmark_node *header_child = cmark_node_first_child(maybe_header);
        char *short_desc = S_nodes_to_pod(header_child, NULL, 1);
        name = CFCUtil_sprintf("%s - %s", module, short_desc);
        FREEMEM(short_desc);

        cmark_node *remaining = cmark_node_next(maybe_header);
        desc = S_nodes_to_pod(remaining, NULL, 1);
    }
    else {
        // No header found.
        name = CFCUtil_strdup(module);
        desc = S_node_to_pod(doc, NULL, 1);
    }

    const char *pattern =
        "=head1 NAME\n"
        "\n"
        "%s\n"
        "\n"
        "=head1 DESCRIPTION\n"
        "\n"
        "%s";
    char *retval = CFCUtil_sprintf(pattern, name, desc);

    FREEMEM(name);
    FREEMEM(desc);
    cmark_node_free(doc);
    return retval;
}

char*
CFCPerlPod_md_to_pod(const char *md, CFCClass *klass, int header_level) {
    int options = CMARK_OPT_SMART
                  | CMARK_OPT_VALIDATE_UTF8;
    cmark_node *doc = cmark_parse_document(md, strlen(md), options);
    char *pod = S_node_to_pod(doc, klass, header_level);
    cmark_node_free(doc);

    return pod;
}

// Convert a node and its siblings.
static char*
S_nodes_to_pod(cmark_node *node, CFCClass *klass, int header_level) {
    char *result = CFCUtil_strdup("");

    while (node != NULL) {
        char *pod = S_node_to_pod(node, klass, header_level);
        result = CFCUtil_cat(result, pod, NULL);
        FREEMEM(pod);

        node = cmark_node_next(node);
    }

    return result;
}

// Convert a single node.
static char*
S_node_to_pod(cmark_node *node, CFCClass *klass, int header_level) {
    char *result = CFCUtil_strdup("");
    if (node == NULL) {
        return result;
    }

    int found_matching_code_block = false;
    cmark_iter *iter = cmark_iter_new(node);
    cmark_event_type ev_type;

    while (CMARK_EVENT_DONE != (ev_type = cmark_iter_next(iter))) {
        cmark_node *node = cmark_iter_get_node(iter);
        cmark_node_type type = cmark_node_get_type(node);

        switch (type) {
            case CMARK_NODE_DOCUMENT:
                break;

            case CMARK_NODE_PARAGRAPH:
                if (ev_type == CMARK_EVENT_EXIT) {
                    result = CFCUtil_cat(result, "\n\n", NULL);
                }
                break;

            case CMARK_NODE_BLOCK_QUOTE:
            case CMARK_NODE_LIST:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "=over\n\n", NULL);
                }
                else {
                    result = CFCUtil_cat(result, "=back\n\n", NULL);
                }
                break;

            case CMARK_NODE_ITEM:
                // TODO: Ordered lists.
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "=item *\n\n", NULL);
                }
                break;

            case CMARK_NODE_HEADER:
                if (ev_type == CMARK_EVENT_ENTER) {
                    int extra_level = cmark_node_get_header_level(node) - 1;
                    char *header = CFCUtil_sprintf("=head%d ",
                                                   header_level + extra_level);
                    result = CFCUtil_cat(result, header, NULL);
                    FREEMEM(header);
                }
                else {
                    result = CFCUtil_cat(result, "\n\n", NULL);
                }
                break;

            case CMARK_NODE_CODE_BLOCK: {
                int is_host = CFCMarkdown_code_block_is_host(node, "perl");

                if (is_host) {
                    found_matching_code_block = true;

                    const char *content = cmark_node_get_literal(node);
                    char *copy = CFCUtil_strdup(content);
                    // Chomp trailing newline.
                    size_t len = strlen(copy);
                    if (len > 0 && copy[len-1] == '\n') {
                        copy[len-1] = '\0';
                    }
                    char *indented
                        = CFCUtil_global_replace(copy, "\n", "\n    ");
                    result
                        = CFCUtil_cat(result, "    ", indented, "\n\n", NULL);
                    FREEMEM(indented);
                    FREEMEM(copy);
                }

                if (CFCMarkdown_code_block_is_last(node)) {
                    if (!found_matching_code_block) {
                        result = CFCUtil_cat(result,
                            "    Code example for Perl is missing\n\n");
                    }
                    else {
                        // Reset.
                        found_matching_code_block = false;
                    }
                }

                break;
            }

            case CMARK_NODE_HTML: {
                const char *html = cmark_node_get_literal(node);
                result = CFCUtil_cat(result, "=begin html\n\n", html,
                                     "\n=end\n\n", NULL);
                break;
            }

            case CMARK_NODE_HRULE:
                break;

            case CMARK_NODE_TEXT: {
                const char *content = cmark_node_get_literal(node);
                char *escaped = S_pod_escape(content);
                result = CFCUtil_cat(result, escaped, NULL);
                FREEMEM(escaped);
                break;
            }

            case CMARK_NODE_LINEBREAK:
                // POD doesn't support line breaks. Start a new paragraph.
                result = CFCUtil_cat(result, "\n\n", NULL);
                break;

            case CMARK_NODE_SOFTBREAK:
                result = CFCUtil_cat(result, "\n", NULL);
                break;

            case CMARK_NODE_CODE: {
                const char *content = cmark_node_get_literal(node);
                char *escaped = S_pod_escape(content);
                result = CFCUtil_cat(result, "C<", escaped, ">", NULL);
                FREEMEM(escaped);
                break;
            }

            case CMARK_NODE_INLINE_HTML: {
                const char *html = cmark_node_get_literal(node);
                CFCUtil_warn("Inline HTML not supported in POD: %s", html);
                break;
            }

            case CMARK_NODE_LINK:
                if (ev_type == CMARK_EVENT_ENTER) {
                    char *pod = S_convert_link(node, klass, header_level);
                    result = CFCUtil_cat(result, pod, NULL);
                    FREEMEM(pod);
                    cmark_iter_reset(iter, node, CMARK_EVENT_EXIT);
                }
                break;

            case CMARK_NODE_IMAGE:
                CFCUtil_warn("Images not supported in POD");
                break;

            case CMARK_NODE_STRONG:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "B<", NULL);
                }
                else {
                    result = CFCUtil_cat(result, ">", NULL);
                }
                break;

            case CMARK_NODE_EMPH:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "I<", NULL);
                }
                else {
                    result = CFCUtil_cat(result, ">", NULL);
                }
                break;

            default:
                CFCUtil_die("Invalid cmark node type: %d", (int)type);
                break;
        }
    }

    cmark_iter_free(iter);
    return result;
}

static char*
S_pod_escape(const char *content) {
    size_t  len        = strlen(content);
    size_t  result_len = 0;
    size_t  result_cap = len + 256;
    char   *result     = (char*)MALLOCATE(result_cap + 1);

    for (size_t i = 0; i < len; i++) {
        const char *subst      = content + i;
        size_t      subst_size = 1;

        switch (content[i]) {
            case '<':
                // Escape "less than".
                subst      = "E<lt>";
                subst_size = 5;
                break;
            case '>':
                // Escape "greater than".
                subst      = "E<gt>";
                subst_size = 5;
                break;
            case '|':
                // Escape vertical bar.
                subst      = "E<verbar>";
                subst_size = 9;
                break;
            case '=':
                // Escape equal sign at start of line.
                if (i == 0 || content[i-1] == '\n') {
                    subst      = "E<61>";
                    subst_size = 5;
                }
                break;
            default:
                break;
        }

        if (result_len + subst_size > result_cap) {
            result_cap += 256;
            result = (char*)REALLOCATE(result, result_cap + 1);
        }

        memcpy(result + result_len, subst, subst_size);
        result_len += subst_size;
    }

    result[result_len] = '\0';

    return result;
}

static char*
S_convert_link(cmark_node *link, CFCClass *doc_class, int header_level) {
    cmark_node *child = cmark_node_first_child(link);
    const char *uri   = cmark_node_get_url(link);
    char       *text  = S_nodes_to_pod(child, doc_class, header_level);
    char       *retval;

    if (!CFCUri_is_clownfish_uri(uri)) {
        retval = S_pod_link(text, uri);
        FREEMEM(text);
        return retval;
    }

    char       *new_uri  = NULL;
    char       *new_text = NULL;
    CFCUri     *uri_obj  = CFCUri_new(uri, doc_class);
    CFCUriType  type     = CFCUri_get_type(uri_obj);

    switch (type) {
        case CFC_URI_ERROR: {
            const char *error = CFCUri_get_error(uri_obj);
            new_text = CFCUtil_sprintf("[%s]", error);
            break;
        }

        case CFC_URI_NULL:
            // Change all instances of NULL to 'undef'
            new_text = CFCUtil_strdup("undef");
            break;

        case CFC_URI_CLASS: {
            CFCClass *klass = CFCUri_get_class(uri_obj);

            if (klass != doc_class) {
                const char *class_name = CFCClass_get_name(klass);
                new_uri = CFCUtil_strdup(class_name);
            }

            if (text[0] == '\0') {
                const char *src = CFCClass_included(klass)
                                  ? CFCClass_get_name(klass)
                                  : CFCClass_get_struct_sym(klass);
                new_text = CFCUtil_strdup(src);
            }

            break;
        }

        case CFC_URI_FUNCTION:
        case CFC_URI_METHOD: {
            CFCClass   *klass = CFCUri_get_class(uri_obj);
            const char *name  = CFCUri_get_callable_name(uri_obj);

            // Convert "Err_get_error" to "Clownfish->error".
            if (strcmp(CFCClass_full_struct_sym(klass), "cfish_Err") == 0
                && strcmp(name, "get_error") == 0
            ) {
                new_text = CFCUtil_strdup("Clownfish->error");
                break;
            }

            char *perl_name = CFCUtil_strdup(name);
            for (size_t i = 0; perl_name[i] != '\0'; ++i) {
                perl_name[i] = CFCUtil_tolower(perl_name[i]);
            }

            // The Perl POD only contains sections for novel methods. Link
            // to the class where the method is declared first.
            if (type == CFC_URI_METHOD) {
                CFCClass *parent = CFCClass_get_parent(klass);
                while (parent && CFCClass_method(parent, name)) {
                    klass = parent;
                    parent = CFCClass_get_parent(klass);
                }
            }

            if (klass == doc_class) {
                new_uri = CFCUtil_sprintf("/%s", perl_name);
            }
            else {
                const char *class_name = CFCClass_get_name(klass);
                new_uri = CFCUtil_sprintf("%s/%s", class_name, perl_name);
            }

            if (text[0] == '\0') {
                new_text = CFCUtil_sprintf("%s()", perl_name);
            }

            FREEMEM(perl_name);
            break;
        }

        case CFC_URI_DOCUMENT: {
            CFCDocument *doc = CFCUri_get_document(uri_obj);

            const char *path_part = CFCDocument_get_path_part(doc);
            new_uri = CFCUtil_global_replace(path_part, CHY_DIR_SEP, "::");

            if (text[0] == '\0') {
                const char *name = CFCDocument_get_name(doc);
                new_text = CFCUtil_strdup(name);
            }

            break;
        }
    }

    if (new_text) {
        FREEMEM(text);
        text = new_text;
    }

    if (new_uri) {
        retval = S_pod_link(text, new_uri);
        FREEMEM(new_uri);
        FREEMEM(text);
    }
    else {
        retval = text;
    }

    CFCBase_decref((CFCBase*)uri_obj);

    return retval;
}

static char*
S_pod_link(const char *text, const char *name) {
    if (!text || text[0] == '\0' || strcmp(text, name) == 0) {
        return CFCUtil_sprintf("L<%s>", name);
    }
    else {
        return CFCUtil_sprintf("L<%s|%s>", text, name);
    }
}

