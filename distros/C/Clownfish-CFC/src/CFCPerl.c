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

#ifndef true
  #define true 1
  #define false 0
#endif

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCPerl.h"
#include "CFCParcel.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCHierarchy.h"
#include "CFCUtil.h"
#include "CFCPerlClass.h"
#include "CFCPerlSub.h"
#include "CFCPerlConstructor.h"
#include "CFCPerlMethod.h"
#include "CFCPerlTypeMap.h"
#include "CFCPerlPod.h"
#include "CFCBindCore.h"
#include "CFCDocument.h"

typedef struct CFCPerlPodFile {
    char *path;
    char *contents;
} CFCPerlPodFile;

struct CFCPerl {
    CFCBase base;
    CFCHierarchy *hierarchy;
    char *lib_dir;
    char *header;
    char *footer;
    char *c_header;
    char *c_footer;
    char *pod_header;
    char *pod_footer;
};

// Modify a string in place, swapping out "::" for the supplied character.
static void
S_replace_double_colons(char *text, char replacement);

static CFCPerlPodFile*
S_write_class_pod(CFCPerl *self);

static CFCPerlPodFile*
S_write_standalone_pod(CFCPerl *self);

static const CFCMeta CFCPERL_META = {
    "Clownfish::CFC::Binding::Perl",
    sizeof(CFCPerl),
    (CFCBase_destroy_t)CFCPerl_destroy
};

CFCPerl*
CFCPerl_new(CFCHierarchy *hierarchy, const char *lib_dir, const char *header,
            const char *footer) {
    CFCPerl *self = (CFCPerl*)CFCBase_allocate(&CFCPERL_META);
    return CFCPerl_init(self, hierarchy, lib_dir, header, footer);
}

CFCPerl*
CFCPerl_init(CFCPerl *self, CFCHierarchy *hierarchy, const char *lib_dir,
             const char *header, const char *footer) {
    CFCUTIL_NULL_CHECK(hierarchy);
    CFCUTIL_NULL_CHECK(lib_dir);
    CFCUTIL_NULL_CHECK(header);
    CFCUTIL_NULL_CHECK(footer);
    self->hierarchy  = (CFCHierarchy*)CFCBase_incref((CFCBase*)hierarchy);
    self->lib_dir    = CFCUtil_strdup(lib_dir);
    self->header     = CFCUtil_strdup(header);
    self->footer     = CFCUtil_strdup(footer);
    self->c_header   = CFCUtil_make_c_comment(header);
    self->c_footer   = CFCUtil_make_c_comment(footer);
    self->pod_header = CFCUtil_make_perl_comment(header);
    self->pod_footer = CFCUtil_make_perl_comment(footer);

    return self;
}

void
CFCPerl_destroy(CFCPerl *self) {
    CFCBase_decref((CFCBase*)self->hierarchy);
    FREEMEM(self->lib_dir);
    FREEMEM(self->header);
    FREEMEM(self->footer);
    FREEMEM(self->c_header);
    FREEMEM(self->c_footer);
    FREEMEM(self->pod_header);
    FREEMEM(self->pod_footer);
    CFCBase_destroy((CFCBase*)self);
}

static void
S_replace_double_colons(char *text, char replacement) {
    size_t pos = 0;
    for (char *ptr = text; *ptr != '\0'; ptr++) {
        if (strncmp(ptr, "::", 2) == 0) {
            text[pos++] = replacement;
            ptr++;
        }
        else {
            text[pos++] = *ptr;
        }
    }
    text[pos] = '\0';
}

char**
CFCPerl_write_pod(CFCPerl *self) {
    CFCPerlPodFile *class_pods      = S_write_class_pod(self);
    CFCPerlPodFile *standalone_pods = S_write_standalone_pod(self);

    size_t max_paths = 0;
    for (size_t i = 0; class_pods[i].contents; i++)      { max_paths++; }
    for (size_t i = 0; standalone_pods[i].contents; i++) { max_paths++; }
    char **pod_paths = (char**)CALLOCATE(max_paths + 1, sizeof(char*));

    // Write out any POD files that have changed.
    CFCPerlPodFile *file_arrays[2] = {
        class_pods,
        standalone_pods
    };
    size_t num_written = 0;
    for (size_t j = 0; j < 2; ++j) {
        CFCPerlPodFile *pod_files = file_arrays[j];

        for (size_t i = 0; pod_files[i].contents; i++) {
            char *pod      = pod_files[i].contents;
            char *pod_path = pod_files[i].path;

            if (CFCUtil_write_if_changed(pod_path, pod, strlen(pod))) {
                pod_paths[num_written] = pod_path;
                num_written++;
            }
            else {
                FREEMEM(pod_path);
            }

            FREEMEM(pod);
        }

        FREEMEM(pod_files);
    }
    pod_paths[num_written] = NULL;

    return pod_paths;
}

static CFCPerlPodFile*
S_write_class_pod(CFCPerl *self) {
    CFCPerlClass **registry  = CFCPerlClass_registry();
    size_t num_registered = 0;
    while (registry[num_registered] != NULL) { num_registered++; }
    CFCPerlPodFile *pod_files
        = (CFCPerlPodFile*)CALLOCATE(num_registered + 1,
                                     sizeof(CFCPerlPodFile));
    size_t count = 0;

    // Generate POD, but don't write.  That way, if there's an error while
    // generating pod, we leak memory but don't clutter up the file system.
    for (size_t i = 0; i < num_registered; i++) {
        const char *class_name = CFCPerlClass_get_class_name(registry[i]);
        char *raw_pod = CFCPerlClass_create_pod(registry[i]);
        if (!raw_pod) { continue; }
        char *pod = CFCUtil_sprintf("%s\n%s%s", self->pod_header, raw_pod,
                                    self->pod_footer);
        char *pod_path = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s.pod",
                                         self->lib_dir, class_name);
        S_replace_double_colons(pod_path, CHY_DIR_SEP_CHAR);

        pod_files[count].contents = pod;
        pod_files[count].path     = pod_path;
        count++;

        FREEMEM(raw_pod);
    }
    pod_files[count].contents = NULL;
    pod_files[count].path     = NULL;

    return pod_files;
}

static CFCPerlPodFile*
S_write_standalone_pod(CFCPerl *self) {
    CFCDocument **docs = CFCDocument_get_registry();
    size_t num_pod_files = 0;
    while (docs[num_pod_files]) { num_pod_files++; }
    size_t alloc_size = (num_pod_files + 1) * sizeof(CFCPerlPodFile);
    CFCPerlPodFile *pod_files = (CFCPerlPodFile*)MALLOCATE(alloc_size);

    for (size_t i = 0; i < num_pod_files; i++) {
        CFCDocument *doc = docs[i];
        const char *path_part = CFCDocument_get_path_part(doc);
        char *module  = CFCUtil_global_replace(path_part, CHY_DIR_SEP, "::");
        char *md      = CFCDocument_get_contents(doc);
        char *raw_pod = CFCPerlPod_md_doc_to_pod(module, md);

        const char *pattern =
            "%s"
            "\n"
            "=encoding utf8\n"
            "\n"
            "%s"
            "%s";
        char *pod = CFCUtil_sprintf(pattern, self->pod_header, raw_pod,
                                    self->pod_footer);

        char *pod_path = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s.pod",
                                         self->lib_dir, path_part);

        pod_files[i].contents = pod;
        pod_files[i].path     = pod_path;

        FREEMEM(raw_pod);
        FREEMEM(md);
        FREEMEM(module);
    }

    pod_files[num_pod_files].contents = NULL;
    pod_files[num_pod_files].path     = NULL;

    return pod_files;
}

static void
S_write_host_h(CFCPerl *self, CFCParcel *parcel) {
    const char *prefix = CFCParcel_get_prefix(parcel);
    const char *PREFIX = CFCParcel_get_PREFIX(parcel);

    char *guard = CFCUtil_sprintf("H_%sBOOT", PREFIX);

    const char pattern[] = 
        "%s\n"
        "\n"
        "#ifndef %s\n"
        "#define %s 1\n"
        "\n"
        "#ifdef __cplusplus\n"
        "extern \"C\" {\n"
        "#endif\n"
        "\n"
        "void\n"
        "%sbootstrap_perl(void);\n"
        "\n"
        "#ifdef __cplusplus\n"
        "}\n"
        "#endif\n"
        "\n"
        "#endif /* %s */\n"
        "\n"
        "%s\n";
    char *content
        = CFCUtil_sprintf(pattern, self->c_header, guard, guard, prefix, guard,
                          self->c_footer);

    const char *inc_dest = CFCHierarchy_get_include_dest(self->hierarchy);
    char *host_h_path = CFCUtil_sprintf("%s" CHY_DIR_SEP "%sperl.h", inc_dest,
                                        prefix);
    CFCUtil_write_file(host_h_path, content, strlen(content));
    FREEMEM(host_h_path);

    FREEMEM(content);
    FREEMEM(guard);
}

static void
S_write_host_c(CFCPerl *self, CFCParcel *parcel) {
    CFCClass **ordered = CFCHierarchy_ordered_classes(self->hierarchy);
    const char  *prefix      = CFCParcel_get_prefix(parcel);
    const char  *privacy_sym = CFCParcel_get_privacy_sym(parcel);
    char        *includes    = CFCUtil_strdup("");
    char        *cb_defs     = CFCUtil_strdup("");
    char        *alias_adds  = CFCUtil_strdup("");

    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_inert(klass)) { continue; }
        const char *class_prefix = CFCClass_get_prefix(klass);
        if (strcmp(class_prefix, prefix) != 0) { continue; }

        const char *class_name = CFCClass_get_name(klass);

        const char *include_h = CFCClass_include_h(klass);
        includes = CFCUtil_cat(includes, "#include \"", include_h,
                               "\"\n", NULL);

        // Callbacks.
        CFCMethod **fresh_methods = CFCClass_fresh_methods(klass);
        for (int meth_num = 0; fresh_methods[meth_num] != NULL; meth_num++) {
            CFCMethod *method = fresh_methods[meth_num];

            // Define callback.
            if (CFCMethod_novel(method) && !CFCMethod_final(method)) {
                char *cb_def = CFCPerlMethod_callback_def(method, klass);
                cb_defs = CFCUtil_cat(cb_defs, cb_def, "\n", NULL);
                FREEMEM(cb_def);
            }
        }

        // Add class aliases.
        CFCPerlClass *class_binding = CFCPerlClass_singleton(class_name);
        if (class_binding) {
            const char *class_var = CFCClass_full_class_var(klass);
            const char **aliases
                = CFCPerlClass_get_class_aliases(class_binding);
            for (size_t j = 0; aliases[j] != NULL; j++) {
                const char *alias = aliases[j];
                int alias_len  = (int)strlen(alias);
                const char pattern[] =
                    "    cfish_Class_add_alias_to_registry("
                    "%s, \"%s\", %d);\n";
                char *alias_add
                    = CFCUtil_sprintf(pattern, class_var, alias, alias_len);
                alias_adds = CFCUtil_cat(alias_adds, alias_add, NULL);
                FREEMEM(alias_add);
            }

            char *metadata_code
                = CFCPerlClass_method_metadata_code(class_binding);
            alias_adds = CFCUtil_cat(alias_adds, metadata_code, NULL);
            FREEMEM(metadata_code);
        }
    }

    const char pattern[] =
        "%s"
        "\n"
        "#define %s\n"  // privacy_sym
        "\n"
        "#include \"%sperl.h\"\n"
        "#include \"XSBind.h\"\n"
        "#include \"Clownfish/Class.h\"\n"
        "#include \"Clownfish/Err.h\"\n"
        "#include \"Clownfish/Obj.h\"\n"
        "%s"
        "\n"
        "/* Avoid conflicts with Clownfish bool type. */\n"
        "#define HAS_BOOL\n"
        "#define PERL_NO_GET_CONTEXT\n"
        "#include \"EXTERN.h\"\n"
        "#include \"perl.h\"\n"
        "#include \"XSUB.h\"\n"
        "\n"
        "static void\n"
        "S_finish_callback_void(pTHX_ const char *meth_name) {\n"
        "    int count = call_method(meth_name, G_VOID | G_DISCARD);\n"
        "    if (count != 0) {\n"
        "        CFISH_THROW(CFISH_ERR, \"Bad callback to '%%s': %%i32\",\n"
        "                    meth_name, (int32_t)count);\n"
        "    }\n"
        "    FREETMPS;\n"
        "    LEAVE;\n"
        "}\n"
        "\n"
        "static CFISH_INLINE SV*\n"
        "SI_do_callback_sv(pTHX_ const char *meth_name) {\n"
        "    int count = call_method(meth_name, G_SCALAR);\n"
        "    if (count != 1) {\n"
        "        CFISH_THROW(CFISH_ERR, \"Bad callback to '%%s': %%i32\",\n"
        "                    meth_name, (int32_t)count);\n"
        "    }\n"
        "    dSP;\n"
        "    SV *return_sv = POPs;\n"
        "    PUTBACK;\n"
        "    return return_sv;\n"
        "}\n"
        "\n"
        "static int64_t\n"
        "S_finish_callback_i64(pTHX_ const char *meth_name) {\n"
        "    SV *return_sv = SI_do_callback_sv(aTHX_ meth_name);\n"
        "    int64_t retval;\n"
        "    if (sizeof(IV) == 8) {\n"
        "        retval = (int64_t)SvIV(return_sv);\n"
        "    }\n"
        "    else {\n"
        "        if (SvIOK(return_sv)) {\n"
        "            // It's already no more than 32 bits, so don't convert.\n"
        "            retval = SvIV(return_sv);\n"
        "        }\n"
        "        else {\n"
        "            // Maybe lossy.\n"
        "            double temp = SvNV(return_sv);\n"
        "            retval = (int64_t)temp;\n"
        "        }\n"
        "    }\n"
        "    FREETMPS;\n"
        "    LEAVE;\n"
        "    return retval;\n"
        "}\n"
        "\n"
        "static double\n"
        "S_finish_callback_f64(pTHX_ const char *meth_name) {\n"
        "    SV *return_sv = SI_do_callback_sv(aTHX_ meth_name);\n"
        "    double retval = SvNV(return_sv);\n"
        "    FREETMPS;\n"
        "    LEAVE;\n"
        "    return retval;\n"
        "}\n"
        "\n"
        "static cfish_Obj*\n"
        "S_finish_callback_obj(pTHX_ void *vself, const char *meth_name,\n"
        "                      int nullable) {\n"
        "    SV *return_sv = SI_do_callback_sv(aTHX_ meth_name);\n"
        "    cfish_Obj *retval\n"
        "        = XSBind_perl_to_cfish_nullable(aTHX_ return_sv, CFISH_OBJ);\n"
        "    FREETMPS;\n"
        "    LEAVE;\n"
        "    if (!nullable && !retval) {\n"
        "        CFISH_THROW(CFISH_ERR, \"%%o#%%s cannot return NULL\",\n"
        "                    cfish_Obj_get_class_name((cfish_Obj*)vself),\n"
        "                    meth_name);\n"
        "    }\n"
        "    return retval;\n"
        "}\n"
	"\n"
        "%s"
        "\n"
        "void\n"
        "%sbootstrap_perl() {\n"
        "    dTHX;\n"
        "    %sbootstrap_parcel();\n"
        "\n"
        "%s"
        "}\n"
        "\n"
        "%s";
    char *content
        = CFCUtil_sprintf(pattern, self->c_header, privacy_sym, prefix,
                          includes, cb_defs, prefix, prefix, alias_adds,
                          self->c_footer);

    const char *src_dest = CFCHierarchy_get_source_dest(self->hierarchy);
    char *host_c_path = CFCUtil_sprintf("%s" CHY_DIR_SEP "%sperl.c", src_dest,
                                        prefix);
    CFCUtil_write_file(host_c_path, content, strlen(content));
    FREEMEM(host_c_path);

    FREEMEM(content);
    FREEMEM(alias_adds);
    FREEMEM(cb_defs);
    FREEMEM(includes);
    FREEMEM(ordered);
}

void
CFCPerl_write_hostdefs(CFCPerl *self) {
    const char pattern[] =
        "%s\n"
        "\n"
        "#ifndef H_CFISH_HOSTDEFS\n"
        "#define H_CFISH_HOSTDEFS 1\n"
        "\n"
        "/* Refcount / host object */\n"
        "typedef union {\n"
        "    size_t  count;\n"
        "    void   *host_obj;\n"
        "} cfish_ref_t;\n"
        "\n"
        "#define CFISH_OBJ_HEAD\\\n"
        "   cfish_ref_t ref;\n"
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

void
CFCPerl_write_host_code(CFCPerl *self) {
    CFCParcel **parcels = CFCParcel_all_parcels();

    for (size_t i = 0; parcels[i]; ++i) {
        CFCParcel *parcel = parcels[i];

        if (!CFCParcel_included(parcel)) {
            S_write_host_h(self, parcel);
            S_write_host_c(self, parcel);
        }
    }
}

static char*
S_add_xsub_spec(char *xsub_specs, CFCPerlSub *xsub) {
    const char *c_name = CFCPerlSub_c_name(xsub);
    const char *alias = CFCPerlSub_get_alias(xsub);
    const char *sep = xsub_specs[0] == '\0' ? "" : ",\n";
    xsub_specs = CFCUtil_cat(xsub_specs, sep, "        { \"", alias, "\", ",
                             c_name, " }", NULL);
    return xsub_specs;
}

void
CFCPerl_write_bindings(CFCPerl *self, const char *boot_class,
                       CFCParcel **parcels) {
    CFCUTIL_NULL_CHECK(boot_class);
    CFCUTIL_NULL_CHECK(parcels);

    CFCClass     **ordered  = CFCHierarchy_ordered_classes(self->hierarchy);
    CFCPerlClass **registry = CFCPerlClass_registry();
    char *privacy_syms    = CFCUtil_strdup("");
    char *includes        = CFCUtil_strdup("");
    char *generated_xs    = CFCUtil_strdup("");
    char *class_specs     = CFCUtil_strdup("");
    char *xsub_specs      = CFCUtil_strdup("");
    char *bootstrap_calls = CFCUtil_strdup("");
    char *hand_rolled_xs  = CFCUtil_strdup("");

    for (size_t i = 0; parcels[i]; ++i) {
        CFCParcel *parcel = parcels[i];

        // Set host_module_name for parcel.
        if (!CFCParcel_included(parcel) && CFCParcel_is_installed(parcel)) {
            CFCParcel_set_host_module_name(parcel, boot_class);
        }

        // Bake the parcel privacy defines into the XS, so it can be compiled
        // without any extra compiler flags.
        const char *privacy_sym = CFCParcel_get_privacy_sym(parcel);
        privacy_syms = CFCUtil_cat(privacy_syms, "#define ", privacy_sym,
                                   "\n", NULL);

        // Bootstrap calls.
        const char *prefix = CFCParcel_get_prefix(parcel);
        includes = CFCUtil_cat(includes, "#include \"", prefix, "perl.h\"\n",
                               NULL);
        bootstrap_calls = CFCUtil_cat(bootstrap_calls, "    ", prefix,
                                      "bootstrap_perl();\n", NULL);
    }

    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];

        CFCParcel *parcel = CFCClass_get_parcel(klass);
        int found = false;
        for (size_t j = 0; parcels[j]; j++) {
            if (parcel == parcels[j]) {
                found = true;
                break;
            }
        }
        if (!found) { continue; }

        // Pound-includes for generated headers.
        const char *include_h = CFCClass_include_h(klass);
        includes = CFCUtil_cat(includes, "#include \"", include_h, "\"\n",
                               NULL);

        if (CFCClass_inert(klass)) { continue; }
        int num_xsubs = 0;

        // Constructors.
        CFCPerlConstructor **constructors
            = CFCPerlClass_constructor_bindings(klass);
        for (size_t j = 0; constructors[j] != NULL; j++) {
            CFCPerlSub *xsub = (CFCPerlSub*)constructors[j];

            // Add the XSUB function definition.
            char *xsub_def
                = CFCPerlConstructor_xsub_def(constructors[j], klass);
            generated_xs = CFCUtil_cat(generated_xs, xsub_def, "\n",
                                       NULL);
            FREEMEM(xsub_def);

            // Add XSUB initialization at boot.
            xsub_specs = S_add_xsub_spec(xsub_specs, xsub);
            num_xsubs += 1;

            CFCBase_decref((CFCBase*)constructors[j]);
        }
        FREEMEM(constructors);

        // Methods.
        CFCPerlMethod **methods = CFCPerlClass_method_bindings(klass);
        for (size_t j = 0; methods[j] != NULL; j++) {
            CFCPerlSub *xsub = (CFCPerlSub*)methods[j];

            // Add the XSUB function definition.
            char *xsub_def = CFCPerlMethod_xsub_def(methods[j], klass);
            generated_xs = CFCUtil_cat(generated_xs, xsub_def, "\n",
                                       NULL);
            FREEMEM(xsub_def);

            // Add XSUB initialization at boot.
            xsub_specs = S_add_xsub_spec(xsub_specs, xsub);
            num_xsubs += 1;

            CFCBase_decref((CFCBase*)methods[j]);
        }
        FREEMEM(methods);

        // Append XSBind_ClassSpec entry.
        const char *class_name = CFCClass_get_name(klass);
        CFCClass *parent = CFCClass_get_parent(klass);
        char *parent_name;
        if (parent) {
            parent_name = CFCUtil_sprintf("\"%s\"", CFCClass_get_name(parent));
        }
        else {
            parent_name = CFCUtil_strdup("NULL");
        }
        char *class_spec = CFCUtil_sprintf("{ \"%s\", %s, %d }", class_name,
                                           parent_name, num_xsubs);
        const char *sep = class_specs[0] == '\0' ? "" : ",\n";
        class_specs = CFCUtil_cat(class_specs, sep, "        ", class_spec,
                                  NULL);
        FREEMEM(class_spec);
        FREEMEM(parent_name);
    }

    // Hand-rolled XS.
    for (size_t i = 0; registry[i] != NULL; i++) {
        CFCPerlClass *perl_class = registry[i];

        CFCParcel *parcel = CFCPerlClass_get_parcel(perl_class);
        int found = false;
        for (size_t j = 0; parcels[j]; j++) {
            if (parcel == parcels[j]) {
                found = true;
                break;
            }
        }
        if (!found) { continue; }

        const char *xs = CFCPerlClass_get_xs_code(perl_class);
        hand_rolled_xs = CFCUtil_cat(hand_rolled_xs, xs, "\n", NULL);
    }

    const char pattern[] =
        "%s" // Header.
        "\n"
        "%s" // Privacy syms.
        "\n"
        "#include \"XSBind.h\"\n"
        "%s" // Includes.
        "\n"
        "#ifndef XS_INTERNAL\n"
        "  #define XS_INTERNAL XS\n"
        "#endif\n"
        "\n"
        "%s" // Generated XS.
        "\n"
        "MODULE = %s   PACKAGE = %s\n" // Boot class.
        "\n"
        "BOOT:\n"
        "{\n"
        "    static const cfish_XSBind_ClassSpec class_specs[] = {\n"
        "%s\n" // Class specs.
        "    };\n"
        "    static const cfish_XSBind_XSubSpec xsub_specs[] = {\n"
        "%s\n" // XSUB specs.
        "    };\n"
        "    size_t num_classes\n"
        "        = sizeof(class_specs) / sizeof(class_specs[0]);\n"
        "    const char* file = __FILE__;\n"
        "\n"
        "%s" // Bootstrap calls.
        "\n"
        "    cfish_XSBind_bootstrap(aTHX_ num_classes, class_specs,\n"
        "                           xsub_specs, file);\n"
        "}\n"
        "\n"
        "%s" // Hand-rolled XS.
        "\n"
        "%s"; // Footer
    char *contents
        = CFCUtil_sprintf(pattern, self->c_header, privacy_syms, includes,
                          generated_xs, boot_class, boot_class, class_specs,
                          xsub_specs, bootstrap_calls, hand_rolled_xs,
                          self->c_footer);

    // Derive path to generated .xs file.
    char *xs_path = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s.xs", self->lib_dir,
                                    boot_class);
    S_replace_double_colons(xs_path, CHY_DIR_SEP_CHAR);

    // Write out if there have been any changes.
    CFCUtil_write_if_changed(xs_path, contents, strlen(contents));

    FREEMEM(xs_path);
    FREEMEM(contents);
    FREEMEM(hand_rolled_xs);
    FREEMEM(bootstrap_calls);
    FREEMEM(xsub_specs);
    FREEMEM(class_specs);
    FREEMEM(generated_xs);
    FREEMEM(includes);
    FREEMEM(privacy_syms);
    FREEMEM(ordered);
}

void
CFCPerl_write_xs_typemap(CFCPerl *self) {
    CFCPerlTypeMap_write_xs_typemap(self->hierarchy);
}

