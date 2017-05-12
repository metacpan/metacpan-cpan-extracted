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

#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#include <cmark.h>

#include "charmony.h"

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCCHtml.h"
#include "CFCC.h"
#include "CFCClass.h"
#include "CFCDocuComment.h"
#include "CFCDocument.h"
#include "CFCFunction.h"
#include "CFCHierarchy.h"
#include "CFCMethod.h"
#include "CFCParamList.h"
#include "CFCParcel.h"
#include "CFCSymbol.h"
#include "CFCType.h"
#include "CFCUtil.h"
#include "CFCUri.h"
#include "CFCVariable.h"
#include "CFCCallable.h"

#ifndef true
    #define true 1
    #define false 0
#endif

#define UTF8_NDASH "\xE2\x80\x93"

struct CFCCHtml {
    CFCBase base;
    CFCHierarchy *hierarchy;
    char *doc_path;
    char *header;
    char *footer;
    char *index_filename;
};

static const CFCMeta CFCCHTML_META = {
    "Clownfish::CFC::Binding::C::Html",
    sizeof(CFCCHtml),
    (CFCBase_destroy_t)CFCCHtml_destroy
};

static const char header_template[] =
    "<!DOCTYPE html>\n"
    "<html>\n"
    "<head>\n"
    "<meta charset=\"utf-8\">\n"
    "{autogen_header}"
    "<meta name=\"viewport\" content=\"width=device-width\" />\n"
    "<title>{title}</title>\n"
    "<style type=\"text/css\">\n"
    "body {\n"
    "    max-width: 48em;\n"
    "    font: 0.85em/1.4 sans-serif;\n"
    "}\n"
    "a {\n"
    "    color: #23b;\n"
    "}\n"
    "table {\n"
    "    border-collapse: collapse;\n"
    "}\n"
    "td {\n"
    "    padding: 0;\n"
    "}\n"
    "td.label {\n"
    "    padding-right: 2em;\n"
    "    font-weight: bold;\n"
    "}\n"
    "dt {\n"
    "    font-weight: bold;\n"
    "}\n"
    "pre {\n"
    "    border: 1px solid #ccc;\n"
    "    padding: 0.2em 0.4em;\n"
    "    background: #f6f6f6;\n"
    "    font-size: 0.92em;\n"
    "}\n"
    "pre a {\n"
    "    text-decoration: none;\n"
    "}\n"
    "pre, code {\n"
    "    font-family: \"Consolas\", \"Menlo\", monospace;\n"
    "}\n"
    "span.prefix, span.comment {\n"
    "    color: #888;\n"
    "}\n"
    "</style>\n"
    "</head>\n"
    "<body>\n";

static const char footer_template[] =
    "</body>\n"
    "</html>\n"
    "{autogen_footer}";

char*
S_create_index_doc(CFCCHtml *self, CFCClass **classes, CFCDocument **docs);

char*
S_create_standalone_doc(CFCCHtml *self, CFCDocument *doc);

static int
S_compare_class_name(const void *va, const void *vb);

static int
S_compare_doc_path(const void *va, const void *vb);

static char*
S_html_create_name(CFCClass *klass);

static char*
S_html_create_synopsis(CFCClass *klass);

static char*
S_html_create_description(CFCClass *klass);

static char*
S_html_create_functions(CFCClass *klass);

static char*
S_html_create_methods(CFCClass *klass);

static char*
S_html_create_fresh_methods(CFCClass *klass, CFCClass *ancestor);

static char*
S_html_create_func(CFCClass *klass, CFCCallable *func, const char *prefix,
                   const char *short_sym);

static char*
S_html_create_param_list(CFCClass *klass, CFCCallable *func);

static char*
S_html_create_inheritance(CFCClass *klass);

static char*
S_md_to_html(const char *md, CFCClass *klass, int dir_level);

static void
S_transform_doc(cmark_node *node, CFCClass *klass, int dir_level);

static int
S_transform_code_block(cmark_node *node, int found_matching_code_block);

static void
S_transform_link(cmark_node *link, CFCClass *klass, int dir_level);

static char*
S_type_to_html(CFCType *type, const char *sep, CFCClass *doc_class);

static char*
S_cfc_uri_to_url(CFCUri *uri_obj, CFCClass *base, int dir_level);

static char*
S_class_to_url(CFCClass *klass, CFCClass *base, int dir_level);

static char*
S_document_to_url(CFCDocument *doc, CFCClass *base, int dir_level);

static char*
S_relative_url(const char *url, CFCClass *base, int dir_level);

CFCCHtml*
CFCCHtml_new(CFCHierarchy *hierarchy, const char *header, const char *footer) {
    CFCCHtml *self = (CFCCHtml*)CFCBase_allocate(&CFCCHTML_META);
    return CFCCHtml_init(self, hierarchy, header, footer);
}

CFCCHtml*
CFCCHtml_init(CFCCHtml *self, CFCHierarchy *hierarchy, const char *header,
              const char *footer) {
    CFCUTIL_NULL_CHECK(hierarchy);
    CFCUTIL_NULL_CHECK(header);
    CFCUTIL_NULL_CHECK(footer);

    self->hierarchy = (CFCHierarchy*)CFCBase_incref((CFCBase*)hierarchy);

    const char *dest = CFCHierarchy_get_dest(hierarchy);
    self->doc_path
        = CFCUtil_sprintf("%s" CHY_DIR_SEP "share" CHY_DIR_SEP "doc"
                          CHY_DIR_SEP "clownfish", dest);

    char *header_comment = CFCUtil_make_html_comment(header);
    char *footer_comment = CFCUtil_make_html_comment(footer);
    self->header = CFCUtil_global_replace(header_template, "{autogen_header}",
                                          header_comment);
    self->footer = CFCUtil_global_replace(footer_template, "{autogen_footer}",
                                          footer_comment);
    FREEMEM(footer_comment);
    FREEMEM(header_comment);

    return self;
}

void
CFCCHtml_destroy(CFCCHtml *self) {
    CFCBase_decref((CFCBase*)self->hierarchy);
    FREEMEM(self->doc_path);
    FREEMEM(self->header);
    FREEMEM(self->footer);
    FREEMEM(self->index_filename);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCCHtml_write_html_docs(CFCCHtml *self) {
    CFCHierarchy  *hierarchy    = self->hierarchy;
    CFCClass     **ordered      = CFCHierarchy_ordered_classes(hierarchy);
    CFCDocument  **doc_registry = CFCDocument_get_registry();
    const char    *doc_path     = self->doc_path;

    size_t num_classes = 0;
    for (size_t i = 0; ordered[i] != NULL; i++) {
        ++num_classes;
    }

    size_t num_md_docs = 0;
    for (size_t i = 0; doc_registry[i] != NULL; i++) {
        ++num_md_docs;
    }

    // Clone doc registry.
    size_t bytes = (num_md_docs + 1) * sizeof(CFCDocument*);
    CFCDocument **md_docs = (CFCDocument**)MALLOCATE(bytes);
    memcpy(md_docs, doc_registry, bytes);

    qsort(ordered, num_classes, sizeof(*ordered), S_compare_class_name);
    qsort(md_docs, num_md_docs, sizeof(*md_docs), S_compare_doc_path);

    size_t   max_docs  = 1 + num_classes + num_md_docs;
    char   **filenames = (char**)CALLOCATE(max_docs, sizeof(char*));
    char   **html_docs = (char**)CALLOCATE(max_docs, sizeof(char*));
    size_t   num_docs  = 0;

    // Generate HTML docs, but don't write.  That way, if there's an error
    // while generating the pages, we leak memory but don't clutter up the file
    // system.

    char *index_doc = S_create_index_doc(self, ordered, md_docs);
    if (index_doc != NULL) {
        filenames[num_docs] = CFCUtil_strdup(self->index_filename);
        html_docs[num_docs] = index_doc;
        num_docs++;
    }

    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass) || !CFCClass_public(klass)) {
            continue;
        }

        const char *class_name = CFCClass_get_name(klass);
        char *path = CFCUtil_global_replace(class_name, "::", CHY_DIR_SEP);
        filenames[num_docs] = CFCUtil_sprintf("%s.html", path);
        html_docs[num_docs] = CFCCHtml_create_html_doc(self, klass);
        ++num_docs;

        FREEMEM(path);
    }

    for (size_t i = 0; md_docs[i] != NULL; i++) {
        CFCDocument *md_doc = md_docs[i];
        const char *path = CFCDocument_get_path_part(md_doc);
        filenames[num_docs] = CFCUtil_sprintf("%s.html", path);
        html_docs[num_docs] = S_create_standalone_doc(self, md_doc);
        ++num_docs;
    }

    // Write out docs.

    for (size_t i = 0; i < num_docs; ++i) {
        char *filename = filenames[i];
        char *path     = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s", doc_path,
                                         filename);
        char *html_doc = html_docs[i];
        CFCUtil_write_if_changed(path, html_doc, strlen(html_doc));
        FREEMEM(html_doc);
        FREEMEM(path);
        FREEMEM(filename);
    }

    FREEMEM(html_docs);
    FREEMEM(filenames);
    FREEMEM(md_docs);
    FREEMEM(ordered);
}

char*
S_create_index_doc(CFCCHtml *self, CFCClass **classes, CFCDocument **docs) {
    CFCParcel **parcels = CFCParcel_all_parcels();

    // Compile standalone document list.

    char *doc_list = CFCUtil_strdup("");

    for (size_t i = 0; docs[i] != NULL; i++) {
        CFCDocument *doc = docs[i];

        const char *path_part = CFCDocument_get_path_part(doc);
        char *url  = CFCUtil_global_replace(path_part, CHY_DIR_SEP, "/");
        char *name = CFCUtil_global_replace(path_part, CHY_DIR_SEP, "::"); 
        doc_list
            = CFCUtil_cat(doc_list, "<li><a href=\"", url, ".html\">",
                          name, "</a></li>\n", NULL);
        FREEMEM(name);
        FREEMEM(url);
    }

    if (doc_list[0] != '\0') {
        const char *pattern =
            "<h2>Documentation</h2>\n"
            "<ul>\n"
            "%s"
            "</ul>\n";
        char *contents = doc_list;
        doc_list = CFCUtil_sprintf(pattern, contents);
        FREEMEM(contents);
    }

    // Compile class lists per parcel.

    char *class_lists    = CFCUtil_strdup("");
    char *parcel_names   = CFCUtil_strdup("");
    char *filename = CFCUtil_strdup("");

    for (size_t i = 0; parcels[i]; i++) {
        CFCParcel *parcel = parcels[i];
        if (CFCParcel_included(parcel)) { continue; }

        const char *prefix      = CFCParcel_get_prefix(parcel);
        const char *parcel_name = CFCParcel_get_name(parcel);

        char *class_list = CFCUtil_strdup("");

        for (size_t i = 0; classes[i] != NULL; i++) {
            CFCClass *klass = classes[i];
            if (strcmp(CFCClass_get_prefix(klass), prefix) != 0
                || !CFCClass_public(klass)
            ) {
                continue;
            }

            const char *class_name = CFCClass_get_name(klass);
            char *url = S_class_to_url(klass, NULL, 0);
            class_list
                = CFCUtil_cat(class_list, "<li><a href=\"", url, "\">",
                              class_name, "</a></li>\n", NULL);
            FREEMEM(url);
        }

        if (class_list[0] != '\0') {
            const char *pattern =
                "<h2>Classes in parcel %s</h2>\n"
                "<ul>\n"
                "%s"
                "</ul>\n";
            char *html = CFCUtil_sprintf(pattern, parcel_name, class_list);
            class_lists = CFCUtil_cat(class_lists, html, NULL);
            FREEMEM(html);

            const char *parcel_name = CFCParcel_get_name(parcel);
            const char *sep = parcel_names[0] == '\0' ? "" : ", ";
            parcel_names = CFCUtil_cat(parcel_names, sep, parcel_name, NULL);

            const char *parcel_prefix = CFCParcel_get_prefix(parcel);
            filename = CFCUtil_cat(filename, parcel_prefix, NULL);
        }

        FREEMEM(class_list);
    }

    // Create doc.

    char *title  = CFCUtil_sprintf("%s " UTF8_NDASH " C API Index",
                                   parcel_names);
    char *header = CFCUtil_global_replace(self->header, "{title}", title);

    const char pattern[] =
        "%s"
        "<h1>%s</h1>\n"
        "%s"
        "%s"
        "%s";
    char *doc
        = CFCUtil_sprintf(pattern, header, title, doc_list, class_lists,
                          self->footer);

    // Create filename

    if (filename[0] == '\0') {
        for (size_t i = 0; parcels[i]; i++) {
            CFCParcel *parcel = parcels[i];
            if (CFCParcel_included(parcel)) { continue; }
            const char *prefix = CFCParcel_get_prefix(parcel);
            filename = CFCUtil_cat(filename, prefix, NULL);
        }
    }

    char *retval = NULL;

    if (filename[0] != '\0') {
        // Removing trailing underscore.
        size_t filename_len = strlen(filename);
        filename[filename_len-1] = '\0';

        // Add .html extension.
        char *base = filename;
        filename = CFCUtil_sprintf("%s.html", base);
        FREEMEM(base);

        retval = doc;
        doc    = NULL;

        FREEMEM(self->index_filename);
        self->index_filename = filename;
        filename             = NULL;
    }

    FREEMEM(doc);
    FREEMEM(header);
    FREEMEM(title);
    FREEMEM(filename);
    FREEMEM(parcel_names);
    FREEMEM(class_lists);
    FREEMEM(doc_list);

    return retval;
}

char*
S_create_standalone_doc(CFCCHtml *self, CFCDocument *doc) {
    const char *path = CFCDocument_get_path_part(doc);
    char *title  = CFCUtil_global_replace(path, CHY_DIR_SEP, "::");
    char *header = CFCUtil_global_replace(self->header, "{title}", title);

    char *md = CFCDocument_get_contents(doc);
    int dir_level = 0;
    for (size_t i = 0; path[i]; i++) {
        if (path[i] == CHY_DIR_SEP_CHAR) { ++dir_level; }
    }
    char *body = S_md_to_html(md, NULL, dir_level);

    char *html_doc = CFCUtil_sprintf("%s%s%s", header, body, self->footer);

    FREEMEM(body);
    FREEMEM(md);
    FREEMEM(header);
    FREEMEM(title);
    return html_doc;
}

char*
CFCCHtml_create_html_doc(CFCCHtml *self, CFCClass *klass) {
    const char *class_name     = CFCClass_get_name(klass);
    char *title
        = CFCUtil_sprintf("%s " UTF8_NDASH " C API Documentation", class_name);
    char *header = CFCUtil_global_replace(self->header, "{title}", title);
    char *body = CFCCHtml_create_html_body(self, klass);

    char *html_doc = CFCUtil_sprintf("%s%s%s", header, body, self->footer);

    FREEMEM(body);
    FREEMEM(header);
    FREEMEM(title);
    return html_doc;
}

char*
CFCCHtml_create_html_body(CFCCHtml *self, CFCClass *klass) {
    if (self->index_filename == NULL) {
        // Create index filename by creating index doc.
        CFCClass    **ordered = CFCHierarchy_ordered_classes(self->hierarchy);
        CFCDocument **docs    = CFCDocument_get_registry();
        char *index_doc = S_create_index_doc(self, ordered, docs);
        FREEMEM(index_doc);
        FREEMEM(ordered);

        if (self->index_filename == NULL) {
            CFCUtil_die("Empty hierarchy");
        }
    }

    CFCParcel  *parcel         = CFCClass_get_parcel(klass);
    const char *parcel_name    = CFCParcel_get_name(parcel);
    const char *prefix         = CFCClass_get_prefix(klass);
    const char *PREFIX         = CFCClass_get_PREFIX(klass);
    const char *class_name     = CFCClass_get_name(klass);
    const char *class_nickname = CFCClass_get_nickname(klass);
    const char *class_var      = CFCClass_short_class_var(klass);
    const char *struct_sym     = CFCClass_get_struct_sym(klass);
    const char *include_h      = CFCClass_include_h(klass);

    // Create NAME.
    char *name = S_html_create_name(klass);

    // Create SYNOPSIS.
    char *synopsis = S_html_create_synopsis(klass);

    // Create DESCRIPTION.
    char *description = S_html_create_description(klass);

    // Create CONSTRUCTORS.
    char *functions_html = S_html_create_functions(klass);

    // Create METHODS, possibly including an ABSTRACT METHODS section.
    char *methods_html = S_html_create_methods(klass);

    // Build an INHERITANCE section describing class ancestry.
    char *inheritance = S_html_create_inheritance(klass);

    char *index_url = S_relative_url(self->index_filename, klass, 0);

    // Put it all together.
    const char pattern[] =
        "<h1>%s</h1>\n"
        "<table>\n"
        "<tr>\n"
        "<td class=\"label\">parcel</td>\n"
        "<td><a href=\"%s\">%s</a></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">class variable</td>\n"
        "<td><code><span class=\"prefix\">%s</span>%s</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">struct symbol</td>\n"
        "<td><code><span class=\"prefix\">%s</span>%s</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">class nickname</td>\n"
        "<td><code><span class=\"prefix\">%s</span>%s</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">header file</td>\n"
        "<td><code>%s</code></td>\n"
        "</tr>\n"
        "</table>\n"
        "%s"
        "%s"
        "%s"
        "%s"
        "%s"
        "%s";
    char *html_body
        = CFCUtil_sprintf(pattern, class_name, index_url,
                          parcel_name, PREFIX, class_var, prefix, struct_sym,
                          prefix, class_nickname, include_h, name, synopsis,
                          description, functions_html, methods_html,
                          inheritance);

    FREEMEM(index_url);
    FREEMEM(name);
    FREEMEM(synopsis);
    FREEMEM(description);
    FREEMEM(functions_html);
    FREEMEM(methods_html);
    FREEMEM(inheritance);

    return html_body;
}

static int
S_compare_class_name(const void *va, const void *vb) {
    const char *a = CFCClass_get_name(*(CFCClass**)va);
    const char *b = CFCClass_get_name(*(CFCClass**)vb);

    return strcmp(a, b);
}

static int
S_compare_doc_path(const void *va, const void *vb) {
    const char *a = CFCDocument_get_path_part(*(CFCDocument**)va);
    const char *b = CFCDocument_get_path_part(*(CFCDocument**)vb);

    return strcmp(a, b);
}

static char*
S_html_create_name(CFCClass *klass) {
    const char     *class_name = CFCClass_get_name(klass);
    char           *md         = CFCUtil_strdup(class_name);
    CFCDocuComment *docucom    = CFCClass_get_docucomment(klass);

    if (docucom) {
        const char *raw_brief = CFCDocuComment_get_brief(docucom);
        if (raw_brief && raw_brief[0] != '\0') {
            md = CFCUtil_cat(md, " " UTF8_NDASH " ", raw_brief, NULL);
        }
    }

    char *html = S_md_to_html(md, klass, 0);

    const char *format =
        "<h2>Name</h2>\n"
        "%s";
    char *result = CFCUtil_sprintf(format, html);

    FREEMEM(html);
    FREEMEM(md);
    return result;
}

static char*
S_html_create_synopsis(CFCClass *klass) {
    CHY_UNUSED_VAR(klass);
    return CFCUtil_strdup("");
}

static char*
S_html_create_description(CFCClass *klass) {
    CFCDocuComment *docucom = CFCClass_get_docucomment(klass);
    char           *desc    = NULL;

    if (docucom) {
        const char *raw_desc = CFCDocuComment_get_long(docucom);
        if (raw_desc && raw_desc[0] != '\0') {
            desc = S_md_to_html(raw_desc, klass, 0);
        }
    }

    if (!desc) { return CFCUtil_strdup(""); }

    char *result = CFCUtil_sprintf("<h2>Description</h2>\n%s", desc);

    FREEMEM(desc);
    return result;
}

static char*
S_html_create_functions(CFCClass *klass) {
    CFCFunction **functions = CFCClass_functions(klass);
    const char   *prefix    = CFCClass_get_prefix(klass);
    char         *result    = CFCUtil_strdup("");

    for (int func_num = 0; functions[func_num] != NULL; func_num++) {
        CFCFunction *func = functions[func_num];
        if (!CFCFunction_public(func)) { continue; }

        if (result[0] == '\0') {
            result = CFCUtil_cat(result, "<h2>Functions</h2>\n<dl>\n", NULL);
        }

        const char *name = CFCFunction_get_name(func);
        result = CFCUtil_cat(result, "<dt id=\"func_", name, "\">",
                             name, "</dt>\n", NULL);

        char *short_sym = CFCFunction_short_func_sym(func, klass);
        char *func_html = S_html_create_func(klass, (CFCCallable*)func, prefix,
                                             short_sym);
        result = CFCUtil_cat(result, func_html, NULL);
        FREEMEM(func_html);
        FREEMEM(short_sym);
    }

    if (result[0] != '\0') {
        result = CFCUtil_cat(result, "</dl>\n", NULL);
    }

    return result;
}

static char*
S_html_create_methods(CFCClass *klass) {
    char *methods_html  = CFCUtil_strdup("");
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

        char *fresh_html = S_html_create_fresh_methods(klass, ancestor);
        if (fresh_html[0] != '\0') {
            if (ancestor == klass) {
                methods_html = CFCUtil_cat(methods_html, fresh_html, NULL);
            }
            else {
                methods_html
                    = CFCUtil_cat(methods_html, "<h3>Methods inherited from ",
                                  class_name, "</h3>\n", fresh_html, NULL);
            }
        }
        FREEMEM(fresh_html);
    }

    if (methods_html[0] == '\0') {
        result = CFCUtil_strdup("");
    }
    else {
        result = CFCUtil_sprintf("<h2>Methods</h2>\n%s", methods_html);
    }

    FREEMEM(methods_html);
    return result;
}

/** Return HTML for the fresh methods of `ancestor`.
 */
static char*
S_html_create_fresh_methods(CFCClass *klass, CFCClass *ancestor) {
    CFCMethod  **fresh_methods = CFCClass_fresh_methods(ancestor);
    const char  *prefix        = CFCClass_get_prefix(klass);
    char        *result        = CFCUtil_strdup("");

    for (int meth_num = 0; fresh_methods[meth_num] != NULL; meth_num++) {
        CFCMethod *method = fresh_methods[meth_num];
        if (!CFCMethod_public(method)) {
            continue;
        }

        const char *name = CFCMethod_get_name(method);
        if (strcmp(name, "Destroy") == 0) {
            // Destroy must not be called directly.
            continue;
        }

        CFCMethod *other = CFCClass_method(klass, name);
        if (!CFCMethod_is_fresh(other, ancestor)) {
            // The method is implementated in a subclass and already
            // documented.
            continue;
        }

        if (result[0] == '\0') {
            result = CFCUtil_cat(result, "<dl>\n", NULL);
        }

        result = CFCUtil_cat(result, "<dt id=\"func_", name, "\">",
                             name, NULL);
        if (CFCMethod_abstract(method)) {
            result = CFCUtil_cat(result,
                    " <span class=\"comment\">(abstract)</span>", NULL);
        }
        result = CFCUtil_cat(result, "</dt>\n", NULL);

        char       *short_sym = CFCMethod_short_method_sym(method, klass);
        char *method_html = S_html_create_func(klass, (CFCCallable*)method,
                                               prefix, short_sym);
        result = CFCUtil_cat(result, method_html, NULL);
        FREEMEM(method_html);
        FREEMEM(short_sym);
    }

    if (result[0] != '\0') {
        result = CFCUtil_cat(result, "</dl>\n", NULL);
    }

    return result;
}

static char*
S_html_create_func(CFCClass *klass, CFCCallable *func, const char *prefix,
                   const char *short_sym) {
    CFCType    *ret_type      = CFCCallable_get_return_type(func);
    char       *ret_html      = S_type_to_html(ret_type, "", klass);
    const char *ret_array     = CFCType_get_array(ret_type);
    const char *ret_array_str = ret_array ? ret_array : "";
    const char *incremented   = "";

    if (CFCType_incremented(ret_type)) {
        incremented = " <span class=\"comment\">// incremented</span>";
    }

    char *param_list = S_html_create_param_list(klass, func);

    const char *pattern =
        "<dd>\n"
        "<pre><code>%s%s%s\n"
        "<span class=\"prefix\">%s</span><strong>%s</strong>%s</code></pre>\n";
    char *result = CFCUtil_sprintf(pattern, ret_html, ret_array_str,
                                   incremented, prefix, short_sym, param_list);

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
        char *desc = S_md_to_html(raw_desc, klass, 0);
        result = CFCUtil_cat(result, desc, NULL);
        FREEMEM(desc);

        // Params
        const char **param_names
            = CFCDocuComment_get_param_names(docucomment);
        const char **param_docs
            = CFCDocuComment_get_param_docs(docucomment);
        if (param_names[0]) {
            result = CFCUtil_cat(result, "<dl>\n", NULL);
            for (size_t i = 0; param_names[i] != NULL; i++) {
                char *doc = S_md_to_html(param_docs[i], klass, 0);
                result = CFCUtil_cat(result, "<dt>", param_names[i],
                                     "</dt>\n<dd>", doc, "</dd>\n",
                                     NULL);
                FREEMEM(doc);
            }
            result = CFCUtil_cat(result, "</dl>\n", NULL);
        }

        // Return value
        const char *retval_doc = CFCDocuComment_get_retval(docucomment);
        if (retval_doc && strlen(retval_doc)) {
            char *md = CFCUtil_sprintf("**Returns:** %s", retval_doc);
            char *html = S_md_to_html(md, klass, 0);
            result = CFCUtil_cat(result, html, NULL);
            FREEMEM(html);
            FREEMEM(md);
        }
    }

    result = CFCUtil_cat(result, "</dd>\n", NULL);

    FREEMEM(ret_html);
    return result;
}

static char*
S_html_create_param_list(CFCClass *klass, CFCCallable *func) {
    CFCParamList  *param_list = CFCCallable_get_param_list(func);
    CFCVariable  **variables  = CFCParamList_get_variables(param_list);

    const char *cfc_class = CFCBase_get_cfc_class((CFCBase*)func);
    int is_method = strcmp(cfc_class, "Clownfish::CFC::Model::Method") == 0;

    if (!variables[0]) {
        return CFCUtil_strdup("(void);\n");
    }

    char *result = CFCUtil_strdup("(\n");

    for (int i = 0; variables[i]; ++i) {
        CFCVariable *variable  = variables[i];
        CFCType     *type      = CFCVariable_get_type(variable);
        const char  *name      = CFCVariable_get_name(variable);
        const char  *array     = CFCType_get_array(type);
        const char  *array_str = array ? array : "";

        char *type_html;
        if (is_method && i == 0) {
            const char *prefix     = CFCClass_get_prefix(klass);
            const char *struct_sym = CFCClass_get_struct_sym(klass);
            const char *pattern    = "<span class=\"prefix\">%s</span>%s *";
            type_html = CFCUtil_sprintf(pattern, prefix, struct_sym);
        }
        else {
            type_html = S_type_to_html(type, " ", klass);
        }

        const char *sep = variables[i+1] ? "," : "";
        const char *decremented = "";

        if (CFCType_decremented(type)) {
            decremented = " <span class=\"comment\">// decremented</span>";
        }

        const char *pattern = "    %s<strong>%s</strong>%s%s%s\n";
        char *param_html = CFCUtil_sprintf(pattern, type_html, name, array_str,
                                           sep, decremented);
        result = CFCUtil_cat(result, param_html, NULL);

        FREEMEM(param_html);
        FREEMEM(type_html);
    }

    result = CFCUtil_cat(result, ");\n", NULL);

    return result;
}

static char*
S_html_create_inheritance(CFCClass *klass) {
    CFCClass *ancestor = CFCClass_get_parent(klass);
    char     *result   = CFCUtil_strdup("");

    if (!ancestor) { return result; }

    const char *class_name = CFCClass_get_name(klass);
    result = CFCUtil_cat(result, "<h2>Inheritance</h2>\n<p>", class_name,
                         NULL);
    while (ancestor) {
        const char *ancestor_name = CFCClass_get_name(ancestor);
        char *ancestor_url = S_class_to_url(ancestor, klass, 0);
        result = CFCUtil_cat(result, " is a <a href=\"", ancestor_url, "\">",
                             ancestor_name, "</a>", NULL);
        FREEMEM(ancestor_url);
        ancestor = CFCClass_get_parent(ancestor);
    }
    result = CFCUtil_cat(result, ".</p>\n", NULL);

    return result;
}

static char*
S_md_to_html(const char *md, CFCClass *klass, int dir_level) {
    int options = CMARK_OPT_SMART
                  | CMARK_OPT_VALIDATE_UTF8;
    cmark_node *doc = cmark_parse_document(md, strlen(md), options);
    S_transform_doc(doc, klass, dir_level);
    char *html = cmark_render_html(doc, CMARK_OPT_SAFE);
    cmark_node_free(doc);

    return html;
}

static void
S_transform_doc(cmark_node *node, CFCClass *klass, int dir_level) {
    int found_matching_code_block = false;
    cmark_iter *iter = cmark_iter_new(node);
    cmark_event_type ev_type;

    while (CMARK_EVENT_DONE != (ev_type = cmark_iter_next(iter))) {
        cmark_node *cur = cmark_iter_get_node(iter);
        cmark_node_type type = cmark_node_get_type(cur);

        switch (type) {
            case CMARK_NODE_CODE_BLOCK:
                found_matching_code_block
                    = S_transform_code_block(cur, found_matching_code_block);
                break;

            case CMARK_NODE_LINK:
                if (ev_type == CMARK_EVENT_EXIT) {
                    S_transform_link(cur, klass, dir_level);
                }
                break;

            default:
                break;
        }
    }

    cmark_iter_free(iter);
}

static int
S_transform_code_block(cmark_node *code_block, int found_matching_code_block) {
    int is_host = CFCMarkdown_code_block_is_host(code_block, "c");

    if (is_host) {
        found_matching_code_block = true;
    }

    if (CFCMarkdown_code_block_is_last(code_block)) {
        if (!found_matching_code_block) {
            cmark_node *warning
                = cmark_node_new(CMARK_NODE_CODE_BLOCK);
            cmark_node_set_literal(warning,
                                   "Code example for C is missing");
            cmark_node_insert_after(code_block, warning);
        }
        else {
            // Reset.
            found_matching_code_block = false;
        }
    }

    if (!is_host) { cmark_node_free(code_block); }

    return found_matching_code_block;
}

static void
S_transform_link(cmark_node *link, CFCClass *doc_class, int dir_level) {
    const char *uri_string = cmark_node_get_url(link);
    if (!uri_string || !CFCUri_is_clownfish_uri(uri_string)) {
        return;
    }

    CFCUri     *uri_obj  = CFCUri_new(uri_string, doc_class);
    CFCUriType  uri_type = CFCUri_get_type(uri_obj);
    char       *url      = S_cfc_uri_to_url(uri_obj, doc_class, dir_level);

    if (uri_type == CFC_URI_NULL || uri_type == CFC_URI_ERROR) {
        // Replace link with text.
        char *link_text = CFCC_link_text(uri_obj);
        cmark_node *text_node = cmark_node_new(CMARK_NODE_TEXT);
        cmark_node_set_literal(text_node, link_text);
        cmark_node_insert_after(link, text_node);
        cmark_node_free(link);
        FREEMEM(link_text);
    }
    else if (url) {
        cmark_node_set_url(link, url);

        if (!cmark_node_first_child(link)) {
            // Empty link text.
            char *link_text = CFCC_link_text(uri_obj);

            if (link_text) {
                cmark_node *text_node = cmark_node_new(CMARK_NODE_TEXT);
                cmark_node_set_literal(text_node, link_text);
                cmark_node_append_child(link, text_node);
                FREEMEM(link_text);
            }
        }
    }
    else {
        // Remove link.
        cmark_node *child = cmark_node_first_child(link);
        while (child) {
            cmark_node *next = cmark_node_next(child);
            cmark_node_insert_before(link, child);
            child = next;
        }
        cmark_node_free(link);
    }

    CFCBase_decref((CFCBase*)uri_obj);
    FREEMEM(url);
}

static char*
S_type_to_html(CFCType *type, const char *sep, CFCClass *doc_class) {
    const char *specifier = CFCType_get_specifier(type);
    char *specifier_html = NULL;

    if (CFCType_is_object(type)) {
        CFCClass   *klass = NULL;

        // Don't link to doc class.
        if (strcmp(specifier, CFCClass_full_struct_sym(doc_class)) != 0) {
            klass = CFCClass_fetch_by_struct_sym(specifier);
            if (!klass) {
                CFCUtil_warn("Class '%s' not found", specifier);
            }
            else if (!CFCClass_public(klass)) {
                CFCUtil_warn("Non-public class '%s' used in public method",
                             specifier);
                klass = NULL;
            }
        }

        const char *underscore = strchr(specifier, '_');
        if (!underscore) {
            CFCUtil_die("Unprefixed object specifier '%s'", specifier);
        }

        ptrdiff_t   offset     = underscore + 1 - specifier;
        char       *prefix     = CFCUtil_strndup(specifier, (size_t)offset);
        const char *struct_sym = specifier + offset;

        if (!klass) {
            const char *pattern = "<span class=\"prefix\">%s</span>%s";
            specifier_html = CFCUtil_sprintf(pattern, prefix, struct_sym);
        }
        else {
            char *url = S_class_to_url(klass, doc_class, 0);
            const char *pattern =
                "<span class=\"prefix\">%s</span>"
                "<a href=\"%s\">%s</a>";
            specifier_html = CFCUtil_sprintf(pattern, prefix, url, struct_sym);
            FREEMEM(url);
        }

        FREEMEM(prefix);
    }
    else {
        specifier_html = CFCUtil_strdup(specifier);
    }

    const char *const_str = CFCType_const(type) ? "const " : "";

    int indirection = CFCType_get_indirection(type);
    ptrdiff_t asterisk_offset = indirection < 10 ? 10 - indirection : 0;
    const char *asterisks = "**********";
    const char *ind_str   = asterisks + asterisk_offset;

    char *html = CFCUtil_sprintf("%s%s%s%s", const_str, specifier_html,
                                 sep, ind_str);

    FREEMEM(specifier_html);
    return html;
}

// Return a relative URL for a CFCUri object.
static char*
S_cfc_uri_to_url(CFCUri *uri_obj, CFCClass *doc_class, int dir_level) {
    char *url = NULL;
    CFCUriType type = CFCUri_get_type(uri_obj);

    switch (type) {
        case CFC_URI_CLASS: {
            CFCClass *klass = CFCUri_get_class(uri_obj);
            url = S_class_to_url(klass, doc_class, dir_level);
            break;
        }

        case CFC_URI_FUNCTION:
        case CFC_URI_METHOD: {
            CFCClass *klass = CFCUri_get_class(uri_obj);
            const char *name = CFCUri_get_callable_name(uri_obj);
            char *class_url = S_class_to_url(klass, doc_class, dir_level);
            url = CFCUtil_sprintf("%s#func_%s", class_url, name);
            FREEMEM(class_url);
            break;
        }

        case CFC_URI_DOCUMENT: {
            CFCDocument *doc = CFCUri_get_document(uri_obj);
            url = S_document_to_url(doc, doc_class, dir_level);
            break;
        }

        default:
            break;
    }

    return url;
}

// Return a relative URL to a class.
static char*
S_class_to_url(CFCClass *klass, CFCClass *base, int dir_level) {
    const char *class_name = CFCClass_get_name(klass);
    char *path    = CFCUtil_global_replace(class_name, "::", CHY_DIR_SEP);
    char *url     = CFCUtil_sprintf("%s.html", path);
    char *rel_url = S_relative_url(url, base, dir_level);

    FREEMEM(url);
    FREEMEM(path);
    return rel_url;
}

// Return a relative URL to a document.
static char*
S_document_to_url(CFCDocument *doc, CFCClass *base, int dir_level) {
    const char *path_part = CFCDocument_get_path_part(doc);
    char *slashy  = CFCUtil_global_replace(path_part, CHY_DIR_SEP, "/");
    char *url     = CFCUtil_sprintf("%s.html", slashy);
    char *rel_url = S_relative_url(url, base, dir_level);

    FREEMEM(url);
    FREEMEM(slashy);
    return rel_url;
}

static char*
S_relative_url(const char *url, CFCClass *base, int dir_level) {
    if (base) {
        const char *base_name = CFCClass_get_name(base);
        for (size_t i = 0; base_name[i]; i++) {
            if (base_name[i] == ':' && base_name[i+1] == ':') {
                dir_level++;
                i++;
            }
        }
    }

    // Create path back to root
    size_t bytes = (size_t)(dir_level * 3);
    char *prefix = (char*)MALLOCATE(bytes + 1);
    for (size_t i = 0; i < bytes; i += 3) {
        memcpy(prefix + i, "../", 3);
    }
    prefix[bytes] = '\0';

    char *rel_url = CFCUtil_sprintf("%s%s", prefix, url);

    FREEMEM(prefix);
    return rel_url;
}

