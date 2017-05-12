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

#include "CFCBindSpecs.h"

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCParcel.h"
#include "CFCUtil.h"

struct CFCBindSpecs {
    CFCBase base;

    char *novel_specs;
    char *overridden_specs;
    char *inherited_specs;
    char *class_specs;
    char *init_code;

    int num_novel;
    int num_overridden;
    int num_inherited;
    int num_specs;
};

static char*
S_ivars_size(CFCClass *klass);

static void
S_add_novel_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                 int meth_index);

static char*
S_parent_offset(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                const char *meth_type, int meth_index);

static void
S_add_overridden_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                      int meth_index);

static void
S_add_inherited_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                     int meth_index);

static const CFCMeta CFCBINDSPECS_META = {
    "Clownfish::CFC::Binding::Core::Specs",
    sizeof(CFCBindSpecs),
    (CFCBase_destroy_t)CFCBindSpecs_destroy
};

CFCBindSpecs*
CFCBindSpecs_new() {
    CFCBindSpecs *self = (CFCBindSpecs*)CFCBase_allocate(&CFCBINDSPECS_META);
    return CFCBindSpecs_init(self);
}

CFCBindSpecs*
CFCBindSpecs_init(CFCBindSpecs *self) {
    self->novel_specs      = CFCUtil_strdup("");
    self->overridden_specs = CFCUtil_strdup("");
    self->inherited_specs  = CFCUtil_strdup("");
    self->class_specs      = CFCUtil_strdup("");
    self->init_code        = CFCUtil_strdup("");

    return self;
}

void
CFCBindSpecs_destroy(CFCBindSpecs *self) {
    FREEMEM(self->novel_specs);
    FREEMEM(self->overridden_specs);
    FREEMEM(self->inherited_specs);
    FREEMEM(self->class_specs);
    FREEMEM(self->init_code);
    CFCBase_destroy((CFCBase*)self);
}

const char*
CFCBindSpecs_get_typedefs() {
    return
        "/* Structs for Class initialization.\n"
        " */\n"
        "\n"
        "typedef struct cfish_NovelMethSpec {\n"
        "    uint32_t       *offset;\n"
        "    const char     *name;\n"
        "    cfish_method_t  func;\n"
        "    cfish_method_t  callback_func;\n"
        "} cfish_NovelMethSpec;\n"
        "\n"
        "typedef struct cfish_OverriddenMethSpec {\n"
        "    uint32_t       *offset;\n"
        "    uint32_t       *parent_offset;\n"
        "    cfish_method_t  func;\n"
        "} cfish_OverriddenMethSpec;\n"
        "\n"
        "typedef struct cfish_InheritedMethSpec {\n"
        "    uint32_t *offset;\n"
        "    uint32_t *parent_offset;\n"
        "} cfish_InheritedMethSpec;\n"
        "\n"
        "typedef enum {\n"
        "    cfish_ClassSpec_FINAL = 1\n"
        "} cfish_ClassSpecFlags;\n"
        "\n"
        "typedef struct cfish_ClassSpec {\n"
        "    cfish_Class **klass;\n"
        "    cfish_Class **parent;\n"
        "    const char   *name;\n"
        "    uint32_t      ivars_size;\n"
        "    uint32_t     *ivars_offset_ptr;\n"
        "    uint32_t      num_novel_meths;\n"
        "    uint32_t      num_overridden_meths;\n"
        "    uint32_t      num_inherited_meths;\n"
        "    uint32_t      flags;\n"
        "} cfish_ClassSpec;\n"
        "\n"
        "typedef struct cfish_ParcelSpec {\n"
        "    const cfish_ClassSpec          *class_specs;\n"
        "    const cfish_NovelMethSpec      *novel_specs;\n"
        "    const cfish_OverriddenMethSpec *overridden_specs;\n"
        "    const cfish_InheritedMethSpec  *inherited_specs;\n"
        "    uint32_t num_classes;\n"
        "} cfish_ParcelSpec;\n"
        "\n";
}

void
CFCBindSpecs_add_class(CFCBindSpecs *self, CFCClass *klass) {
    if (CFCClass_inert(klass)) { return; }

    const char *class_name        = CFCClass_get_name(klass);
    const char *class_var         = CFCClass_full_class_var(klass);
    const char *ivars_offset_name = CFCClass_full_ivars_offset(klass);

    const char *flags = CFCClass_final(klass) ? "cfish_ClassSpec_FINAL" : "0";

    char *ivars_size = S_ivars_size(klass);

    char *parent_ptr = NULL;
    CFCClass *parent = CFCClass_get_parent(klass);
    if (!parent) {
        parent_ptr = CFCUtil_strdup("NULL");
    }
    else {
        if (CFCClass_get_parcel(klass) == CFCClass_get_parcel(parent)) {
            parent_ptr
                = CFCUtil_sprintf("&%s", CFCClass_full_class_var(parent));
        }
        else {
            parent_ptr = CFCUtil_strdup("NULL");

            const char *class_name = CFCClass_get_name(klass);
            const char *parent_var = CFCClass_full_class_var(parent);
            const char *pattern =
                "    /* %s */\n"
                "    class_specs[%d].parent = &%s;\n";
            char *init_code = CFCUtil_sprintf(pattern, class_name,
                                              self->num_specs, parent_var);
            self->init_code = CFCUtil_cat(self->init_code, init_code, NULL);
            FREEMEM(init_code);
        }
    }

    int num_new_novel      = 0;
    int num_new_overridden = 0;
    int num_new_inherited  = 0;
    CFCMethod **methods = CFCClass_methods(klass);

    for (int meth_num = 0; methods[meth_num] != NULL; meth_num++) {
        CFCMethod *method = methods[meth_num];

        if (CFCMethod_is_fresh(method, klass)) {
            if (CFCMethod_novel(method)) {
                int meth_index = self->num_novel + num_new_novel;
                S_add_novel_meth(self, method, klass, meth_index);
                ++num_new_novel;
            }
            else {
                int meth_index = self->num_overridden + num_new_overridden;
                S_add_overridden_meth(self, method, klass, meth_index);
                ++num_new_overridden;
            }
        }
        else {
            int meth_index = self->num_inherited + num_new_inherited;
            S_add_inherited_meth(self, method, klass, meth_index);
            ++num_new_inherited;
        }
    }

    char pattern[] =
        "    {\n"
        "        &%s, /* class */\n"
        "        %s, /* parent */\n"
        "        \"%s\", /* name */\n"
        "        %s, /* ivars_size */\n"
        "        &%s, /* ivars_offset_ptr */\n"
        "        %d, /* num_novel */\n"
        "        %d, /* num_overridden */\n"
        "        %d, /* num_inherited */\n"
        "        %s /* flags */\n"
        "    }";
    char *class_spec
        = CFCUtil_sprintf(pattern, class_var, parent_ptr, class_name,
                          ivars_size, ivars_offset_name, num_new_novel,
                          num_new_overridden, num_new_inherited, flags);

    const char *sep = self->num_specs == 0 ? "" : ",\n";
    self->class_specs = CFCUtil_cat(self->class_specs, sep, class_spec, NULL);

    self->num_novel      += num_new_novel;
    self->num_overridden += num_new_overridden;
    self->num_inherited  += num_new_inherited;
    self->num_specs      += 1;

    FREEMEM(class_spec);
    FREEMEM(parent_ptr);
    FREEMEM(ivars_size);
}

char*
CFCBindSpecs_defs(CFCBindSpecs *self) {
    if (self->num_specs == 0) { return CFCUtil_strdup(""); }

    const char *novel_pattern =
        "static cfish_NovelMethSpec novel_specs[] = {\n"
        "%s\n"
        "};\n"
        "\n";
    char *novel_specs = self->num_novel == 0
                        ? CFCUtil_strdup("")
                        : CFCUtil_sprintf(novel_pattern, self->novel_specs);

    const char *overridden_pattern =
        "static cfish_OverriddenMethSpec overridden_specs[] = {\n"
        "%s\n"
        "};\n"
        "\n";
    char *overridden_specs = self->num_overridden == 0
                             ? CFCUtil_strdup("")
                             : CFCUtil_sprintf(overridden_pattern,
                                               self->overridden_specs);

    const char *inherited_pattern =
        "static cfish_InheritedMethSpec inherited_specs[] = {\n"
        "%s\n"
        "};\n"
        "\n";
    char *inherited_specs = self->num_inherited == 0
                            ? CFCUtil_strdup("")
                            : CFCUtil_sprintf(inherited_pattern,
                                              self->inherited_specs);

    const char *pattern =
        "%s"
        "%s"
        "%s"
        "static cfish_ClassSpec class_specs[] = {\n"
        "%s\n"
        "};\n"
        "\n"
        "static const cfish_ParcelSpec parcel_spec = {\n"
        "    class_specs,\n"
        "    novel_specs,\n"
        "    overridden_specs,\n"
        "    inherited_specs,\n"
        "    %d\n" // num_classes
        "};\n";
    char *defs = CFCUtil_sprintf(pattern, novel_specs, overridden_specs,
                                 inherited_specs, self->class_specs,
                                 self->num_specs);

    FREEMEM(inherited_specs);
    FREEMEM(overridden_specs);
    FREEMEM(novel_specs);
    return defs;
}

char*
CFCBindSpecs_init_func_def(CFCBindSpecs *self) {
    const char *pattern =
        "static void\n"
        "S_bootstrap_specs() {\n"
        "%s"
        "\n"
        "    cfish_Class_bootstrap(&parcel_spec);\n"
        "}\n";
    return CFCUtil_sprintf(pattern, self->init_code);
}

static char*
S_ivars_size(CFCClass *klass) {
    CFCParcel *parcel = CFCClass_get_parcel(klass);
    char *ivars_size = NULL;

    if (CFCParcel_is_cfish(parcel)) {
        const char *struct_sym   = CFCClass_full_struct_sym(klass);
        ivars_size = CFCUtil_sprintf("sizeof(%s)", struct_sym);
    }
    else {
        size_t num_non_package_ivars = CFCClass_num_non_package_ivars(klass);
        size_t num_ivars             = CFCClass_num_member_vars(klass);

        if (num_non_package_ivars == num_ivars) {
            // No members in this package.
            ivars_size = CFCUtil_strdup("0");
        }
        else {
            const char *ivars_struct = CFCClass_full_ivars_struct(klass);
            ivars_size = CFCUtil_sprintf("sizeof(%s)", ivars_struct);
        }
    }

    return ivars_size;
}

static void
S_add_novel_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                 int meth_index) {
    const char *meth_name = CFCMethod_get_name(method);
    const char *sep = meth_index == 0 ? "" : ",\n";

    char *full_override_sym;
    if (!CFCMethod_final(method)) {
        full_override_sym = CFCMethod_full_override_sym(method, klass);
    }
    else {
        full_override_sym = CFCUtil_strdup("NULL");
    }

    char *imp_func        = CFCMethod_imp_func(method, klass);
    char *full_offset_sym = CFCMethod_full_offset_sym(method, klass);

    char pattern[] =
        "    {\n"
        "        &%s, /* offset */\n"
        "        \"%s\", /* name */\n"
        "        (cfish_method_t)%s, /* func */\n"
        "        (cfish_method_t)%s /* callback_func */\n"
        "    }";
    char *def
        = CFCUtil_sprintf(pattern, full_offset_sym, meth_name, imp_func,
                          full_override_sym);
    self->novel_specs = CFCUtil_cat(self->novel_specs, sep, def, NULL);

    FREEMEM(def);
    FREEMEM(full_offset_sym);
    FREEMEM(imp_func);
    FREEMEM(full_override_sym);
}

static char*
S_parent_offset(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                const char *meth_type, int meth_index) {
    CFCClass *parent = CFCClass_get_parent(klass);

    if (!parent) {
        return CFCUtil_strdup("NULL");
    }

    char *parent_offset = NULL;
    char *parent_offset_sym = CFCMethod_full_offset_sym(method, parent);

    if (CFCClass_get_parcel(parent) == CFCClass_get_parcel(klass)) {
        parent_offset = CFCUtil_sprintf("&%s", parent_offset_sym);
    }
    else {
        parent_offset = CFCUtil_strdup("NULL");

        char pattern[] = "    %s_specs[%d].parent_offset = &%s;\n";
        char *code = CFCUtil_sprintf(pattern, meth_type, meth_index,
                                     parent_offset_sym);
        self->init_code = CFCUtil_cat(self->init_code, code, NULL);
        FREEMEM(code);
    }

    FREEMEM(parent_offset_sym);

    return parent_offset;
}

static void
S_add_overridden_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                      int meth_index) {
    const char *sep = meth_index == 0 ? "" : ",\n";

    char *imp_func        = CFCMethod_imp_func(method, klass);
    char *full_offset_sym = CFCMethod_full_offset_sym(method, klass);
    char *parent_offset   = S_parent_offset(self, method, klass, "overridden",
                                            meth_index);

    char pattern[] =
        "    {\n"
        "        &%s, /* offset */\n"
        "        %s, /* parent_offset */\n"
        "        (cfish_method_t)%s /* func */\n"
        "    }";
    char *def
        = CFCUtil_sprintf(pattern, full_offset_sym, parent_offset, imp_func);
    self->overridden_specs
        = CFCUtil_cat(self->overridden_specs, sep, def, NULL);

    FREEMEM(def);
    FREEMEM(parent_offset);
    FREEMEM(full_offset_sym);
    FREEMEM(imp_func);
}

static void
S_add_inherited_meth(CFCBindSpecs *self, CFCMethod *method, CFCClass *klass,
                     int meth_index) {
    const char *sep = meth_index == 0 ? "" : ",\n";

    char *full_offset_sym = CFCMethod_full_offset_sym(method, klass);
    char *parent_offset   = S_parent_offset(self, method, klass, "inherited",
                                            meth_index);

    char pattern[] =
        "    {\n"
        "        &%s, /* offset */\n"
        "        %s /* parent_offset */\n"
        "    }";
    char *def = CFCUtil_sprintf(pattern, full_offset_sym, parent_offset);
    self->inherited_specs = CFCUtil_cat(self->inherited_specs, sep, def, NULL);

    FREEMEM(def);
    FREEMEM(full_offset_sym);
    FREEMEM(parent_offset);
}

