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

#include <cmark.h>

#include "charmony.h"
#include "CFCCMan.h"
#include "CFCBase.h"
#include "CFCC.h"
#include "CFCClass.h"
#include "CFCDocuComment.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCParamList.h"
#include "CFCSymbol.h"
#include "CFCType.h"
#include "CFCUri.h"
#include "CFCUtil.h"
#include "CFCVariable.h"
#include "CFCCallable.h"

#ifndef true
    #define true 1
    #define false 0
#endif

static char*
S_man_create_name(CFCClass *klass);

static char*
S_man_create_synopsis(CFCClass *klass);

static char*
S_man_create_description(CFCClass *klass);

static char*
S_man_create_functions(CFCClass *klass);

static char*
S_man_create_methods(CFCClass *klass);

static char*
S_man_create_fresh_methods(CFCClass *klass, CFCClass *ancestor);

static char*
S_man_create_func(CFCClass *klass, CFCCallable *func, const char *full_sym);

static char*
S_man_create_param_list(CFCClass *klass, CFCCallable *func);

static char*
S_man_create_inheritance(CFCClass *klass);

static char*
S_md_to_man(CFCClass *klass, const char *md, int level);

static char*
S_nodes_to_man(CFCClass *klass, cmark_node *node, int level);

static char*
S_man_escape(const char *content);

char*
CFCCMan_create_man_page(CFCClass *klass) {
    if (!CFCClass_public(klass)) { return NULL; }

    const char *class_name = CFCClass_get_name(klass);

    // Create NAME.
    char *name = S_man_create_name(klass);

    // Create SYNOPSIS.
    char *synopsis = S_man_create_synopsis(klass);

    // Create DESCRIPTION.
    char *description = S_man_create_description(klass);

    // Create CONSTRUCTORS.
    char *functions_man = S_man_create_functions(klass);

    // Create METHODS, possibly including an ABSTRACT METHODS section.
    char *methods_man = S_man_create_methods(klass);

    // Build an INHERITANCE section describing class ancestry.
    char *inheritance = S_man_create_inheritance(klass);

    // Put it all together.
    const char pattern[] =
        ".TH %s 3\n"
        "%s"
        "%s"
        "%s"
        "%s"
        "%s"
        "%s";
    char *man_page
        = CFCUtil_sprintf(pattern, class_name, name, synopsis, description,
                          functions_man, methods_man, inheritance);

    FREEMEM(name);
    FREEMEM(synopsis);
    FREEMEM(description);
    FREEMEM(functions_man);
    FREEMEM(methods_man);
    FREEMEM(inheritance);

    return man_page;
}

static char*
S_man_create_name(CFCClass *klass) {
    char *result = CFCUtil_strdup(".SH NAME\n");
    result = CFCUtil_cat(result, CFCClass_get_name(klass), NULL);

    const char *raw_brief = NULL;
    CFCDocuComment *docucom = CFCClass_get_docucomment(klass);
    if (docucom) {
        raw_brief = CFCDocuComment_get_brief(docucom);
    }
    if (raw_brief && raw_brief[0] != '\0') {
        char *brief = S_md_to_man(klass, raw_brief, 0);
        result = CFCUtil_cat(result, " \\- ", brief, NULL);
        FREEMEM(brief);
    }
    else {
        result = CFCUtil_cat(result, "\n", NULL);
    }

    return result;
}

static char*
S_man_create_synopsis(CFCClass *klass) {
    CHY_UNUSED_VAR(klass);
    return CFCUtil_strdup("");
}

static char*
S_man_create_description(CFCClass *klass) {
    char *result  = CFCUtil_strdup("");

    CFCDocuComment *docucom = CFCClass_get_docucomment(klass);
    if (!docucom) { return result; }

    const char *raw_description = CFCDocuComment_get_long(docucom);
    if (!raw_description || raw_description[0] == '\0') { return result; }

    char *description = S_md_to_man(klass, raw_description, 0);
    result = CFCUtil_cat(result, ".SH DESCRIPTION\n", description, NULL);
    FREEMEM(description);

    return result;
}

static char*
S_man_create_functions(CFCClass *klass) {
    CFCFunction **functions = CFCClass_functions(klass);
    char         *result    = CFCUtil_strdup("");

    for (int func_num = 0; functions[func_num] != NULL; func_num++) {
        CFCFunction *func = functions[func_num];
        if (!CFCFunction_public(func)) { continue; }

        if (result[0] == '\0') {
            result = CFCUtil_cat(result, ".SH FUNCTIONS\n", NULL);
        }

        const char *name = CFCFunction_get_name(func);
        result = CFCUtil_cat(result, ".TP\n.B ", name, "\n", NULL);

        char *full_func_sym = CFCFunction_full_func_sym(func, klass);
        char *function_man = S_man_create_func(klass, (CFCCallable*)func,
                                               full_func_sym);
        result = CFCUtil_cat(result, function_man, NULL);
        FREEMEM(function_man);
        FREEMEM(full_func_sym);
    }

    return result;
}

static char*
S_man_create_methods(CFCClass *klass) {
    char *methods_man = CFCUtil_strdup("");
    char *result;

    for (CFCClass *ancestor = klass;
         ancestor;
         ancestor = CFCClass_get_parent(ancestor)
    ) {
        const char *class_name = CFCClass_get_name(ancestor);
        // Exclude methods inherited from Clownfish::Obj
        if (ancestor != klass && strcmp(class_name, "Clownfish::Obj") == 0) {
            break;
        }

        char *fresh_man = S_man_create_fresh_methods(klass, ancestor);
        if (fresh_man[0] != '\0') {
            if (ancestor == klass) {
                methods_man = CFCUtil_cat(methods_man, fresh_man, NULL);
            }
            else {
                methods_man
                    = CFCUtil_cat(methods_man, ".SS Methods inherited from ",
                                  class_name, "\n", fresh_man, NULL);
            }
        }
        FREEMEM(fresh_man);
    }

    if (methods_man[0] == '\0') {
        result = CFCUtil_strdup("");
    }
    else {
        result = CFCUtil_sprintf(".SH METHODS\n%s", methods_man);
    }

    FREEMEM(methods_man);
    return result;
}

static char*
S_man_create_fresh_methods(CFCClass *klass, CFCClass *ancestor) {
    CFCMethod  **fresh_methods = CFCClass_fresh_methods(klass);
    char        *result        = CFCUtil_strdup("");

    for (int meth_num = 0; fresh_methods[meth_num] != NULL; meth_num++) {
        CFCMethod *method = fresh_methods[meth_num];
        if (!CFCMethod_public(method)) {
            continue;
        }

        if (!CFCMethod_is_fresh(method, ancestor)) {
            // The method is implementated in a subclass and already
            // documented.
            continue;
        }

        const char *name = CFCMethod_get_name(method);
        result = CFCUtil_cat(result, ".TP\n.BR ", name, NULL);
        if (CFCMethod_abstract(method)) {
            result = CFCUtil_cat(result, " \" (abstract)\"", NULL);
        }
        result = CFCUtil_cat(result, "\n", NULL);

        char *full_sym = CFCMethod_full_method_sym(method, klass);
        char *method_man = S_man_create_func(klass, (CFCCallable*)method,
                                             full_sym);
        result = CFCUtil_cat(result, method_man, NULL);
        FREEMEM(method_man);
        FREEMEM(full_sym);
    }

    return result;
}

static char*
S_man_create_func(CFCClass *klass, CFCCallable *func, const char *full_sym) {
    CFCType    *return_type   = CFCCallable_get_return_type(func);
    const char *return_type_c = CFCType_to_c(return_type);
    const char *incremented   = "";

    if (CFCType_incremented(return_type)) {
        incremented = " // incremented";
    }

    char *param_list = S_man_create_param_list(klass, func);

    const char *pattern =
        ".nf\n"
        ".fam C\n"
        "%s%s\n"
        ".BR %s %s\n"
        ".fam\n"
        ".fi\n";
    char *result = CFCUtil_sprintf(pattern, return_type_c, incremented,
                                   full_sym, param_list);

    FREEMEM(param_list);

    // Get documentation, which may be inherited.
    CFCDocuComment *docucomment = CFCCallable_get_docucomment(func);
    if (!docucomment) {
        const char *name = CFCCallable_get_name(func);
        CFCClass *parent = klass;
        while (NULL != (parent = CFCClass_get_parent(parent))) {
            CFCCallable *parent_func
                = (CFCCallable*)CFCClass_method(parent, name);
            if (!parent_func) { break; }
            docucomment = CFCCallable_get_docucomment(parent_func);
            if (docucomment) { break; }
        }
    }

    if (docucomment) {
        // Description
        const char *raw_desc = CFCDocuComment_get_description(docucomment);
        char *desc = S_md_to_man(klass, raw_desc, 1);
        result = CFCUtil_cat(result, ".IP\n", desc, NULL);
        FREEMEM(desc);

        // Params
        const char **param_names
            = CFCDocuComment_get_param_names(docucomment);
        const char **param_docs
            = CFCDocuComment_get_param_docs(docucomment);
        if (param_names[0]) {
            result = CFCUtil_cat(result, ".RS\n", NULL);
            for (size_t i = 0; param_names[i] != NULL; i++) {
                char *doc = S_md_to_man(klass, param_docs[i], 1);
                result = CFCUtil_cat(result, ".TP\n.I ", param_names[i],
                                     "\n", doc, NULL);
                FREEMEM(doc);
            }
            result = CFCUtil_cat(result, ".RE\n", NULL);
        }

        // Return value
        const char *retval_doc = CFCDocuComment_get_retval(docucomment);
        if (retval_doc && strlen(retval_doc)) {
            char *doc = S_md_to_man(klass, retval_doc, 1);
            result = CFCUtil_cat(result, ".IP\n.B Returns:\n", doc, NULL);
            FREEMEM(doc);
        }
    }

    return result;
}

static char*
S_man_create_param_list(CFCClass *klass, CFCCallable *func) {
    CFCParamList  *param_list = CFCCallable_get_param_list(func);
    CFCVariable  **variables  = CFCParamList_get_variables(param_list);

    if (!variables[0]) {
        return CFCUtil_strdup("(void);");
    }

    const char *cfc_class = CFCBase_get_cfc_class((CFCBase*)func);
    int is_method = strcmp(cfc_class, "Clownfish::CFC::Model::Method") == 0;
    char *result = CFCUtil_strdup("(");

    for (int i = 0; variables[i]; ++i) {
        CFCVariable *variable = variables[i];
        CFCType     *type     = CFCVariable_get_type(variable);
        const char  *name     = CFCVariable_get_name(variable);
        char        *type_c;

        if (is_method && i == 0) {
            const char *struct_sym = CFCClass_full_struct_sym(klass);
            type_c = CFCUtil_sprintf("%s*", struct_sym);
        }
        else {
            type_c = CFCUtil_strdup(CFCType_to_c(type));
        }

        result = CFCUtil_cat(result, "\n.RB \"    ", type_c, " \" ", name,
                             NULL);

        if (variables[i+1] || CFCType_decremented(type)) {
            result = CFCUtil_cat(result, " \"", NULL);
            if (variables[i+1]) {
                result = CFCUtil_cat(result, ",", NULL);
            }
            if (CFCType_decremented(type)) {
                result = CFCUtil_cat(result, " // decremented", NULL);
            }
            result = CFCUtil_cat(result, "\"", NULL);
        }

        FREEMEM(type_c);
    }

    result = CFCUtil_cat(result, "\n);", NULL);

    return result;
}

static char*
S_man_create_inheritance(CFCClass *klass) {
    CFCClass *ancestor = CFCClass_get_parent(klass);
    char     *result   = CFCUtil_strdup("");

    if (!ancestor) { return result; }

    const char *class_name = CFCClass_get_name(klass);
    result = CFCUtil_cat(result, ".SH INHERITANCE\n", class_name, NULL);
    while (ancestor) {
        const char *ancestor_name = CFCClass_get_name(ancestor);
        result = CFCUtil_cat(result, " is a ", ancestor_name, NULL);
        ancestor = CFCClass_get_parent(ancestor);
    }
    result = CFCUtil_cat(result, ".\n", NULL);

    return result;
}

static char*
S_md_to_man(CFCClass *klass, const char *md, int level) {
    int options = CMARK_OPT_NORMALIZE
                  | CMARK_OPT_SMART
                  | CMARK_OPT_VALIDATE_UTF8;
    cmark_node *doc = cmark_parse_document(md, strlen(md), options);
    char *result = S_nodes_to_man(klass, doc, level);
    cmark_node_free(doc);

    return result;
}

/*
 * The first level is indented with .IP, the next levels with .RS and .RE.
 * Every change of indentation requires an adjustment to the next paragraph.
 *
 * - After increasing the indent, the next paragraph must start with .IP.
 * - After decreasing the indentation to a lever larger than zero, the
 *   next paragraph mus also start with .IP.
 * - After decreasing the indentation to level zero, the next paragraph
 *   must start with .P.
 *
 * Level 0
 * .IP
 * Level 1
 * .RS
 * .IP
 * Level 2
 * .RE
 * .IP
 * Level 1
 * .P
 * Level 0
 *
 */

#define ADJUST_REINDENT  1
#define ADJUST_VSPACE    2

static char*
S_nodes_to_man(CFCClass *klass, cmark_node *node, int level) {
    char *result = CFCUtil_strdup("");
    int needs_adjust = 0;
    int found_matching_code_block = false;
    cmark_iter *iter = cmark_iter_new(node);
    cmark_event_type ev_type;

    while (CMARK_EVENT_DONE != (ev_type = cmark_iter_next(iter))) {
        cmark_node      *node = cmark_iter_get_node(iter);
        cmark_node_type  type = cmark_node_get_type(node);

        switch (type) {
            case CMARK_NODE_DOCUMENT:
                break;

            case CMARK_NODE_PARAGRAPH:
                if (ev_type == CMARK_EVENT_ENTER) {
                    if (needs_adjust == ADJUST_REINDENT) {
                        const char *man = level == 0 ? ".P\n" : ".IP\n";
                        result = CFCUtil_cat(result, man, NULL);
                    }
                    else if (needs_adjust == ADJUST_VSPACE) {
                        result = CFCUtil_cat(result, "\n", NULL);
                    }
                }
                else {
                    result = CFCUtil_cat(result, "\n", NULL);
                    needs_adjust = ADJUST_VSPACE;
                }
                break;

            case CMARK_NODE_BLOCK_QUOTE:
            case CMARK_NODE_LIST: {
                int prev_adjust = needs_adjust;
                needs_adjust = ADJUST_REINDENT;
                if (ev_type == CMARK_EVENT_ENTER) {
                    if (level > 0) {
                        result = CFCUtil_cat(result, ".RS\n", NULL);
                    }
                    ++level;
                }
                else {
                    --level;
                    if (level > 0) {
                        result = CFCUtil_cat(result, ".RE\n", NULL);
                    }
                    else if (prev_adjust == ADJUST_REINDENT) {
                        // Avoid .P after consecutive .REs.
                        needs_adjust = 0;
                    }
                }
                break;
            }

            case CMARK_NODE_ITEM:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, ".IP \\(bu\n", NULL);
                    needs_adjust = 0;
                }
                break;

            case CMARK_NODE_HEADER:
                // Only works on top level for now.
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, ".SS\n", NULL);
                }
                else {
                    result = CFCUtil_cat(result, "\n", NULL);
                    needs_adjust = 0;
                }
                break;

            case CMARK_NODE_CODE_BLOCK: {
                int is_host = CFCMarkdown_code_block_is_host(node, "c");

                if (is_host) {
                    found_matching_code_block = true;

                    if (level > 0) {
                        result = CFCUtil_cat(result, ".RS\n", NULL);
                    }

                    const char *content = cmark_node_get_literal(node);
                    char *escaped = S_man_escape(content);
                    result = CFCUtil_cat(result, ".IP\n.nf\n.fam C\n", escaped,
                                         ".fam\n.fi\n", NULL);
                    FREEMEM(escaped);

                    if (level > 0) {
                        result = CFCUtil_cat(result, ".RE\n", NULL);
                    }

                    needs_adjust = ADJUST_REINDENT;
                }

                if (CFCMarkdown_code_block_is_last(node)) {
                    if (!found_matching_code_block) {
                        if (level > 0) {
                            result = CFCUtil_cat(result, ".RS\n", NULL);
                        }
                        result = CFCUtil_cat(result,
                            ".IP\n.nf\n.fam C\n"
                            "Code example for Perl is missing\n",
                            ".fam\n.fi\n",
                            NULL);
                        if (level > 0) {
                            result = CFCUtil_cat(result, ".RE\n", NULL);
                        }
                        needs_adjust = ADJUST_REINDENT;
                    }
                    else {
                        // Reset.
                        found_matching_code_block = false;
                    }
                }

                break;
            }

            case CMARK_NODE_HTML:
                CFCUtil_warn("HTML not supported in man pages");
                break;

            case CMARK_NODE_HRULE:
                break;

            case CMARK_NODE_TEXT: {
                const char *content = cmark_node_get_literal(node);
                char *escaped = S_man_escape(content);
                result = CFCUtil_cat(result, escaped, NULL);
                FREEMEM(escaped);
                break;
            }

            case CMARK_NODE_LINEBREAK:
                result = CFCUtil_cat(result, "\n.br\n", NULL);
                break;

            case CMARK_NODE_SOFTBREAK:
                result = CFCUtil_cat(result, "\n", NULL);
                break;

            case CMARK_NODE_CODE: {
                const char *content = cmark_node_get_literal(node);
                char *escaped = S_man_escape(content);
                result = CFCUtil_cat(result, "\\FC", escaped, "\\F[]", NULL);
                FREEMEM(escaped);
                break;
            }

            case CMARK_NODE_INLINE_HTML: {
                const char *html = cmark_node_get_literal(node);
                CFCUtil_warn("HTML not supported in man pages: %s", html);
                break;
            }

            case CMARK_NODE_LINK: {
                const char *url = cmark_node_get_url(node);

                if (CFCUri_is_clownfish_uri(url)) {
                    if (ev_type == CMARK_EVENT_ENTER
                        && !cmark_node_first_child(node)
                    ) {
                        // Empty link text.
                        CFCUri *uri_obj = CFCUri_new(url, klass);
                        char *link_text = CFCC_link_text(uri_obj);
                        if (link_text) {
                            result = CFCUtil_cat(result, link_text, NULL);
                            FREEMEM(link_text);
                        }
                        CFCBase_decref((CFCBase*)uri_obj);
                    }
                }
                else {
                    if (ev_type == CMARK_EVENT_ENTER) {
                        result = CFCUtil_cat(result, "\n.UR ", url, "\n",
                                             NULL);
                    }
                    else {
                        result = CFCUtil_cat(result, "\n.UE\n", NULL);
                    }
                }

                break;
            }

            case CMARK_NODE_IMAGE:
                CFCUtil_warn("Images not supported in man pages");
                break;

            case CMARK_NODE_STRONG:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "\\fB", NULL);
                }
                else {
                    result = CFCUtil_cat(result, "\\f[]", NULL);
                }
                break;

            case CMARK_NODE_EMPH:
                if (ev_type == CMARK_EVENT_ENTER) {
                    result = CFCUtil_cat(result, "\\fI", NULL);
                }
                else {
                    result = CFCUtil_cat(result, "\\f[]", NULL);
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
S_man_escape(const char *content) {
    size_t  len        = strlen(content);
    size_t  result_len = 0;
    size_t  result_cap = len + 256;
    char   *result     = (char*)MALLOCATE(result_cap + 1);

    for (size_t i = 0; i < len; i++) {
        const char *subst      = content + i;
        size_t      subst_size = 1;

        switch (content[i]) {
            case '\\':
                // Escape backslash.
                subst      = "\\e";
                subst_size = 2;
                break;
            case '-':
                // Escape hyphen.
                subst      = "\\-";
                subst_size = 2;
                break;
            case '.':
                // Escape dot at start of line.
                if (i == 0 || content[i-1] == '\n') {
                    subst      = "\\&.";
                    subst_size = 3;
                }
                break;
            case '\'':
                // Escape single quote at start of line.
                if (i == 0 || content[i-1] == '\n') {
                    subst      = "\\&'";
                    subst_size = 3;
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

