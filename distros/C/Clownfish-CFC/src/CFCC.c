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

#include <stdio.h>
#include <string.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCC.h"
#include "CFCCHtml.h"
#include "CFCCMan.h"
#include "CFCClass.h"
#include "CFCDocument.h"
#include "CFCHierarchy.h"
#include "CFCMethod.h"
#include "CFCUri.h"
#include "CFCUtil.h"

struct CFCC {
    CFCBase base;
    CFCHierarchy *hierarchy;
    CFCCHtml     *html_gen;
    char         *c_header;
    char         *c_footer;
    char         *man_header;
    char         *man_footer;
};

static const CFCMeta CFCC_META = {
    "Clownfish::CFC::Binding::C",
    sizeof(CFCC),
    (CFCBase_destroy_t)CFCC_destroy
};

CFCC*
CFCC_new(CFCHierarchy *hierarchy, const char *header, const char *footer) {
    CFCC *self = (CFCC*)CFCBase_allocate(&CFCC_META);
    return CFCC_init(self, hierarchy, header, footer);
}

CFCC*
CFCC_init(CFCC *self, CFCHierarchy *hierarchy, const char *header,
          const char *footer) {
    CFCUTIL_NULL_CHECK(hierarchy);
    CFCUTIL_NULL_CHECK(header);
    CFCUTIL_NULL_CHECK(footer);
    self->hierarchy  = (CFCHierarchy*)CFCBase_incref((CFCBase*)hierarchy);
    self->html_gen   = CFCCHtml_new(hierarchy, header, footer);
    self->c_header   = CFCUtil_make_c_comment(header);
    self->c_footer   = CFCUtil_make_c_comment(footer);
    self->man_header = CFCUtil_make_troff_comment(header);
    self->man_footer = CFCUtil_make_troff_comment(footer);
    return self;
}

void
CFCC_destroy(CFCC *self) {
    CFCBase_decref((CFCBase*)self->hierarchy);
    CFCBase_decref((CFCBase*)self->html_gen);
    FREEMEM(self->c_header);
    FREEMEM(self->c_footer);
    FREEMEM(self->man_header);
    FREEMEM(self->man_footer);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCC_write_html_docs(CFCC *self) {
    CFCCHtml_write_html_docs(self->html_gen);
}

void
CFCC_write_man_pages(CFCC *self) {
    CFCHierarchy  *hierarchy = self->hierarchy;
    CFCClass     **ordered   = CFCHierarchy_ordered_classes(hierarchy);

    size_t num_classes = 0;
    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (!CFCClass_included(klass)) { ++num_classes; }
    }
    char **man_pages = (char**)CALLOCATE(num_classes, sizeof(char*));

    // Generate man pages, but don't write.  That way, if there's an error
    // while generating the pages, we leak memory but don't clutter up the file 
    // system.
    for (size_t i = 0, j = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)) { continue; }

        char *man_page = CFCCMan_create_man_page(klass);
        man_pages[j++] = man_page;
    }

    const char *dest = CFCHierarchy_get_dest(hierarchy);
    char *man3_path
        = CFCUtil_sprintf("%s" CHY_DIR_SEP "man" CHY_DIR_SEP "man3", dest);

    // Write out any man pages that have changed.
    for (size_t i = 0, j = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)) { continue; }

        char *raw_man_page = man_pages[j++];
        if (!raw_man_page) { continue; }
        char *man_page = CFCUtil_sprintf("%s%s%s", self->man_header,
                                         raw_man_page, self->man_footer);

        const char *full_struct_sym = CFCClass_full_struct_sym(klass);
        char *filename = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s.3", man3_path,
                                         full_struct_sym);
        CFCUtil_write_if_changed(filename, man_page, strlen(man_page));
        FREEMEM(filename);
        FREEMEM(man_page);
        FREEMEM(raw_man_page);
    }

    FREEMEM(man3_path);
    FREEMEM(man_pages);
    FREEMEM(ordered);
}

void
CFCC_write_hostdefs(CFCC *self) {
    const char pattern[] =
        "%s\n"
        "\n"
        "#ifndef H_CFISH_HOSTDEFS\n"
        "#define H_CFISH_HOSTDEFS 1\n"
        "\n"
        "#define CFISH_OBJ_HEAD \\\n"
        "    size_t refcount;\n"
        "\n"
        "#define CFISH_NO_DYNAMIC_OVERRIDES\n"
        "\n"
        "#endif /* H_CFISH_HOSTDEFS */\n"
        "\n"
        "%s\n";
    char *content
        = CFCUtil_sprintf(pattern, self->c_header, self->c_footer);

    // Unlink then write file.
    const char *inc_dest = CFCHierarchy_get_include_dest(self->hierarchy);
    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "cfish_hostdefs.h",
                                     inc_dest);
    remove(filepath);
    CFCUtil_write_file(filepath, content, strlen(content));
    FREEMEM(filepath);

    FREEMEM(content);
}

char*
CFCC_link_text(CFCUri *uri_obj) {
    char *link_text = NULL;
    CFCUriType type = CFCUri_get_type(uri_obj);

    switch (type) {
        case CFC_URI_ERROR: {
            const char *error = CFCUri_get_error(uri_obj);
            link_text = CFCUtil_sprintf("[%s]", error);
            break;
        }

        case CFC_URI_NULL:
            link_text = CFCUtil_strdup("NULL");
            break;

        case CFC_URI_CLASS: {
            CFCClass *klass = CFCUri_get_class(uri_obj);
            const char *src = CFCClass_included(klass)
                              ? CFCClass_get_name(klass)
                              : CFCClass_get_struct_sym(klass);
            link_text = CFCUtil_strdup(src);
            break;
        }

        case CFC_URI_FUNCTION:
        case CFC_URI_METHOD: {
            const char *name = CFCUri_get_callable_name(uri_obj);
            link_text = CFCUtil_sprintf("%s()", name);
            break;
        }

        case CFC_URI_DOCUMENT: {
            CFCDocument *doc = CFCUri_get_document(uri_obj);
            const char *name = CFCDocument_get_name(doc);
            link_text = CFCUtil_strdup(name);
            break;
        }

        default:
            CFCUtil_die("Unsupported node type: %d", (int)type);
            break;
    }

    return link_text;
}

