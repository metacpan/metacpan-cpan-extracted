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
#include <stdio.h>
#include <stdlib.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCGo.h"
#include "CFCParcel.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCHierarchy.h"
#include "CFCUtil.h"
#include "CFCGoClass.h"
#include "CFCGoMethod.h"
#include "CFCGoTypeMap.h"

#ifndef true
  #define true 1
  #define false 0
#endif

static void
S_CFCGo_destroy(CFCGo *self);

struct mapping {
    char *parcel;
    char *package;
};

static size_t num_parcel_mappings;
static struct mapping *parcel_mappings;

struct CFCGo {
    CFCBase base;
    CFCHierarchy *hierarchy;
    char *header;
    char *footer;
    char *c_header;
    char *c_footer;
    int suppress_init;
};

static const CFCMeta CFCGO_META = {
    "Clownfish::CFC::Binding::Go",
    sizeof(CFCGo),
    (CFCBase_destroy_t)S_CFCGo_destroy
};

CFCGo*
CFCGo_new(CFCHierarchy *hierarchy) {
    CFCUTIL_NULL_CHECK(hierarchy);
    CFCGo *self = (CFCGo*)CFCBase_allocate(&CFCGO_META);
    self->hierarchy  = (CFCHierarchy*)CFCBase_incref((CFCBase*)hierarchy);
    self->header     = CFCUtil_strdup("");
    self->footer     = CFCUtil_strdup("");
    self->c_header   = CFCUtil_strdup("");
    self->c_footer   = CFCUtil_strdup("");
    self->suppress_init = false;
    return self;
}

static void
S_CFCGo_destroy(CFCGo *self) {
    CFCBase_decref((CFCBase*)self->hierarchy);
    FREEMEM(self->header);
    FREEMEM(self->footer);
    FREEMEM(self->c_header);
    FREEMEM(self->c_footer);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCGo_set_header(CFCGo *self, const char *header) {
    CFCUTIL_NULL_CHECK(header);
    free(self->header);
    self->header = CFCUtil_strdup(header);
    free(self->c_header);
    self->c_header = CFCUtil_make_c_comment(header);
}

void
CFCGo_set_footer(CFCGo *self, const char *footer) {
    CFCUTIL_NULL_CHECK(footer);
    free(self->footer);
    self->footer = CFCUtil_strdup(footer);
    free(self->c_footer);
    self->c_footer = CFCUtil_make_c_comment(footer);
}

void
CFCGo_set_suppress_init(CFCGo *self, int suppress_init) {
    self->suppress_init = !!suppress_init;
}

static void
S_write_hostdefs(CFCGo *self) {
    const char pattern[] =
        "/*\n"
        " * %s\n"
        " */\n"
        "\n"
        "#ifndef H_CFISH_HOSTDEFS\n"
        "#define H_CFISH_HOSTDEFS 1\n"
        "\n"
        "#define CFISH_NO_DYNAMIC_OVERRIDES\n"
        "\n"
        "#define CFISH_OBJ_HEAD \\\n"
        "    size_t refcount;\n"
        "\n"
        "#endif /* H_CFISH_HOSTDEFS */\n"
        "\n"
        "%s\n";
    char *content
        = CFCUtil_sprintf(pattern, self->header, self->footer);

    // Write if the content has changed.
    const char *inc_dest = CFCHierarchy_get_include_dest(self->hierarchy);
    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "cfish_hostdefs.h",
                                     inc_dest);
    CFCUtil_write_if_changed(filepath, content, strlen(content));

    FREEMEM(filepath);
    FREEMEM(content);
}

// Pound-includes for generated headers.
static char*
S_gen_h_includes(CFCGo *self) {
    CFCClass **ordered = CFCHierarchy_ordered_classes(self->hierarchy);
    char *h_includes = CFCUtil_strdup("");
    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        const char *include_h = CFCClass_include_h(klass);
        h_includes = CFCUtil_cat(h_includes, "#include \"", include_h,
                                   "\"\n", NULL);
    }
    FREEMEM(ordered);
    return h_includes;
}

static void
S_register_classes(CFCGo *self, CFCParcel *parcel) {
    CFCClass **ordered = CFCHierarchy_ordered_classes(self->hierarchy);
    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)
            || CFCClass_get_parcel(klass) != parcel
           ) {
            continue;
        }
        const char *class_name = CFCClass_get_name(klass);
        if (!CFCGoClass_singleton(class_name)) {
            CFCGoClass *binding = CFCGoClass_new(parcel, class_name);
            CFCGoClass_register(binding);
        }
    }
}

static char*
S_gen_cgo_comment(CFCGo *self, CFCParcel *parcel, const char *h_includes) {
    CHY_UNUSED_VAR(self);
    const char *prefix = CFCParcel_get_prefix(parcel);
    // Bake in parcel privacy define, so that binding code can be compiled
    // without extra compiler flags.
    const char *privacy_sym = CFCParcel_get_privacy_sym(parcel);
    char pattern[] =
        "#define %s\n"
        "\n"
        "%s\n"
        "\n"
        ;
    return CFCUtil_sprintf(pattern, privacy_sym, h_includes, prefix);
}

static char*
S_gen_prereq_imports(CFCParcel *parcel) {
    char *imports = CFCUtil_strdup("");
    CFCParcel **prereqs = CFCParcel_prereq_parcels(parcel);
    for (int i = 0; prereqs[i] != NULL; i++) {
        const char *dep_parcel = CFCParcel_get_name(prereqs[i]);
        const char *dep_package = NULL;
        for (size_t j = 0; j < num_parcel_mappings; j++) {
            if (strcmp(dep_parcel, parcel_mappings[j].parcel) == 0) {
                dep_package = parcel_mappings[j].package;
            }
        }
        if (dep_package == NULL) {
            CFCUtil_die("Can't find a Go package string to import for "
                        "Clownfish parcel %s, a dependency of %s",
                        dep_parcel, CFCParcel_get_name(parcel));
        }
        imports = CFCUtil_cat(imports, "import \"", dep_package, "\"\n",
                              NULL);
    }
    return imports;
}

static char*
S_gen_init_code(CFCGo *self, CFCParcel *parcel) {
    const char *prefix = CFCParcel_get_prefix(parcel);
    if (self->suppress_init) {
        return CFCUtil_strdup("");
    }

    const char pattern[] =
        "func init() {\n"
        "    C.%sbootstrap_parcel()\n"
        "    initWRAP()\n"
        "}\n";
    return CFCUtil_sprintf(pattern, prefix);
}

static char*
S_gen_autogen_go(CFCGo *self, CFCParcel *parcel) {
    CHY_UNUSED_VAR(self);
    const char *clownfish_dot = CFCParcel_is_cfish(parcel)
                                ? "" : "clownfish.";
    CFCGoClass **registry = CFCGoClass_registry();
    char *type_decs   = CFCUtil_strdup("");
    char *boilerplate = CFCUtil_strdup("");
    char *ctors       = CFCUtil_strdup("");
    char *meth_defs   = CFCUtil_strdup("");
    char *wrap_funcs  = CFCUtil_strdup("");

    for (int i = 0; registry[i] != NULL; i++) {
        CFCGoClass *class_binding = registry[i];
        CFCClass *client = CFCGoClass_get_client(class_binding);

        if (CFCClass_get_parcel(client) != parcel) {
            continue;
        }

        char *type_dec = CFCGoClass_go_typing(class_binding);
        type_decs = CFCUtil_cat(type_decs, type_dec, "\n", NULL);
        FREEMEM(type_dec);

        char *boiler_code = CFCGoClass_boilerplate_funcs(class_binding);
        boilerplate = CFCUtil_cat(boilerplate, boiler_code, "\n", NULL);
        FREEMEM(boiler_code);

        char *ctor_code = CFCGoClass_gen_ctors(class_binding);
        ctors = CFCUtil_cat(ctors, ctor_code, "\n", NULL);
        FREEMEM(ctor_code);

        char *glue = CFCGoClass_gen_meth_glue(class_binding);
        meth_defs = CFCUtil_cat(meth_defs, glue, "\n", NULL);
        FREEMEM(glue);

        char *wrap_func = CFCGoClass_gen_wrap_func_reg(class_binding);
        wrap_funcs = CFCUtil_cat(wrap_funcs, wrap_func, NULL);
        FREEMEM(wrap_func);
    }

    if (strlen(wrap_funcs)) {
        char pattern[] =
            "\tnewEntries := map[unsafe.Pointer]%sWrapFunc{\n%s"
            "\t}\n"
            "\t%sRegisterWrapFuncs(newEntries)\n"
            ;
        char *temp = CFCUtil_sprintf(pattern, clownfish_dot, wrap_funcs,
                                     clownfish_dot);
        FREEMEM(wrap_funcs);
        wrap_funcs = temp;
    }

    char pattern[] =
        "// Type declarations.\n"
        "\n"
        "%s\n"
        "\n"
        "// Autogenerated utility functions.\n"
        "\n"
        "%s\n"
        "\n"
        "// Register WRAP functions.\n"
        "func initWRAP() {\n"
        "%s"
        "}\n"
        "\n"
        "// Constructors.\n"
        "\n"
        "%s\n"
        "\n"
        "// Method bindings.\n"
        "\n"
        "%s\n"
        "\n"
        ;
    char *content
        = CFCUtil_sprintf(pattern, type_decs, boilerplate, wrap_funcs,
                          ctors, meth_defs);

    FREEMEM(wrap_funcs);
    FREEMEM(meth_defs);
    FREEMEM(ctors);
    FREEMEM(boilerplate);
    FREEMEM(type_decs);
    return content;
}

static void
S_write_cfbind_go(CFCGo *self, CFCParcel *parcel, const char *dest,
                  const char *h_includes) {
    const char *PREFIX = CFCParcel_get_PREFIX(parcel);
    char *go_short_package = CFCGoTypeMap_go_short_package(parcel);
    char *cgo_comment   = S_gen_cgo_comment(self, parcel, h_includes);
    char *prereqs       = S_gen_prereq_imports(parcel);
    char *init_code     = S_gen_init_code(self, parcel);
    char *autogen_go    = S_gen_autogen_go(self, parcel);
    const char pattern[] =
        "%s"
        "\n"
        "package %s\n"
        "\n"
        "/*\n"
        "%s\n"
        "*/\n"
        "import \"C\"\n"
        "import \"unsafe\"\n"
        "%s"
        "\n"
        "%s\n"
        "\n"
        "%s\n"
        "\n"
        "//export %sDummyExport\n"
        "func %sDummyExport() int {\n"
        "\treturn 1\n"
        "}\n"
        "%s";
    char *content
        = CFCUtil_sprintf(pattern, self->c_header, go_short_package,
                          cgo_comment, prereqs, init_code, autogen_go,
                          PREFIX, PREFIX, self->c_footer);

    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "cfbind.go", dest);
    CFCUtil_write_if_changed(filepath, content, strlen(content));

    FREEMEM(filepath);
    FREEMEM(content);
    FREEMEM(autogen_go);
    FREEMEM(init_code);
    FREEMEM(prereqs);
    FREEMEM(cgo_comment);
    FREEMEM(go_short_package);
}

void
CFCGo_write_bindings(CFCGo *self, CFCParcel *parcel, const char *dest) {
    char *h_includes = S_gen_h_includes(self);

    S_register_classes(self, parcel);
    S_write_hostdefs(self);
    S_write_cfbind_go(self, parcel, dest, h_includes);

    FREEMEM(h_includes);
}

void
CFCGo_register_parcel_package(const char *parcel, const char *package) {
    size_t amount = sizeof(struct mapping) * (num_parcel_mappings + 1);
    parcel_mappings = (struct mapping*)REALLOCATE(parcel_mappings, amount);
    parcel_mappings[num_parcel_mappings].parcel  = CFCUtil_strdup(parcel);
    parcel_mappings[num_parcel_mappings].package = CFCUtil_strdup(package);
    num_parcel_mappings++;
}
