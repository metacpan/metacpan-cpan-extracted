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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

#ifndef true
    #define true 1
    #define false 0
#endif

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCHierarchy.h"
#include "CFCClass.h"
#include "CFCFile.h"
#include "CFCFileSpec.h"
#include "CFCParcel.h"
#include "CFCSymbol.h"
#include "CFCUtil.h"
#include "CFCParser.h"
#include "CFCDocument.h"
#include "CFCVersion.h"

struct CFCHierarchy {
    CFCBase base;
    size_t num_sources;
    char **sources;
    size_t num_includes;
    char **includes;
    size_t num_prereqs;
    char **prereqs;
    char *dest;
    char *inc_dest;
    char *src_dest;
    CFCParser *parser;
    CFCClass **trees;
    size_t num_trees;
    CFCFile **files;
    size_t num_files;
    CFCClass **classes;
    size_t classes_cap;
    size_t num_classes;
};

typedef struct CFCFindFilesContext {
    const char  *ext;
    char       **paths;
    size_t       num_paths;
} CFCFindFilesContext;

static void
S_parse_source_cfp_files(const char *source_dir);

static void
S_find_prereqs(CFCHierarchy *self, CFCParcel *parcel);

static void
S_find_prereq(CFCHierarchy *self, CFCParcel *parent, CFCPrereq *prereq);

static CFCParcel*
S_audition_parcel(const char *version_dir, const char *vstring,
                  CFCVersion *min_version, CFCParcel *best);

static void
S_parse_cf_files(CFCHierarchy *self, const char *source_dir, int is_included);

static void
S_find_doc_files(const char *source_dir);

static void
S_find_files(const char *path, void *arg);

static char*
S_extract_path_part(const char *path, const char *dir, const char *ext);

static void
S_connect_classes(CFCHierarchy *self);

static void
S_add_file(CFCHierarchy *self, CFCFile *file);

static void
S_add_tree(CFCHierarchy *self, CFCClass *klass);

static CFCFile*
S_fetch_file(CFCHierarchy *self, const char *path_part);

// Recursive helper function for CFCUtil_propagate_modified.
static int
S_do_propagate_modified(CFCHierarchy *self, CFCClass *klass, int modified);

static const CFCMeta CFCHIERARCHY_META = {
    "Clownfish::CFC::Model::Hierarchy",
    sizeof(CFCHierarchy),
    (CFCBase_destroy_t)CFCHierarchy_destroy
};

CFCHierarchy*
CFCHierarchy_new(const char *dest) {
    CFCHierarchy *self = (CFCHierarchy*)CFCBase_allocate(&CFCHIERARCHY_META);
    return CFCHierarchy_init(self, dest);
}

CFCHierarchy*
CFCHierarchy_init(CFCHierarchy *self, const char *dest) {
    if (!dest || !strlen(dest)) {
        CFCUtil_die("'dest' is required");
    }
    self->sources      = (char**)CALLOCATE(1, sizeof(char*));
    self->num_sources  = 0;
    self->includes     = (char**)CALLOCATE(1, sizeof(char*));
    self->num_includes = 0;
    self->prereqs      = (char**)CALLOCATE(1, sizeof(char*));
    self->num_prereqs  = 0;
    self->dest         = CFCUtil_strdup(dest);
    self->trees        = (CFCClass**)CALLOCATE(1, sizeof(CFCClass*));
    self->num_trees    = 0;
    self->files        = (CFCFile**)CALLOCATE(1, sizeof(CFCFile*));
    self->num_files    = 0;
    self->classes_cap  = 10;
    self->classes      = (CFCClass**)CALLOCATE(
                            (self->classes_cap + 1), sizeof(CFCClass*));
    self->num_classes  = 0;
    self->parser       = CFCParser_new();

    self->inc_dest = CFCUtil_sprintf("%s" CHY_DIR_SEP "include", self->dest);
    self->src_dest = CFCUtil_sprintf("%s" CHY_DIR_SEP "source", self->dest);

    return self;
}

void
CFCHierarchy_destroy(CFCHierarchy *self) {
    for (size_t i = 0; self->trees[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->trees[i]);
    }
    for (size_t i = 0; self->files[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->files[i]);
    }
    for (size_t i = 0; self->classes[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->classes[i]);
    }
    CFCUtil_free_string_array(self->sources);
    CFCUtil_free_string_array(self->includes);
    CFCUtil_free_string_array(self->prereqs);
    FREEMEM(self->trees);
    FREEMEM(self->files);
    FREEMEM(self->classes);
    FREEMEM(self->dest);
    FREEMEM(self->inc_dest);
    FREEMEM(self->src_dest);
    CFCBase_decref((CFCBase*)self->parser);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCHierarchy_add_source_dir(CFCHierarchy *self, const char *source_dir) {
    // Don't add directory twice.
    for (size_t i = 0; self->sources[i] != NULL; ++i) {
        if (strcmp(self->sources[i], source_dir) == 0) { return; }
    }

    size_t n = self->num_sources;
    size_t size = (n + 2) * sizeof(char*);
    self->sources      = (char**)REALLOCATE(self->sources, size);
    self->sources[n]   = CFCUtil_strdup(source_dir);
    self->sources[n+1] = NULL;
    self->num_sources  = n + 1;
}

void
CFCHierarchy_add_include_dir(CFCHierarchy *self, const char *include_dir) {
    // Don't add directory twice.
    for (size_t i = 0; self->includes[i] != NULL; ++i) {
        if (strcmp(self->includes[i], include_dir) == 0) { return; }
    }

    size_t n = self->num_includes;
    size_t size = (n + 2) * sizeof(char*);
    self->includes      = (char**)REALLOCATE(self->includes, size);
    self->includes[n]   = CFCUtil_strdup(include_dir);
    self->includes[n+1] = NULL;
    self->num_includes  = n + 1;
}

void
CFCHierarchy_add_prereq(CFCHierarchy *self, const char *parcel) {
    size_t n = self->num_prereqs;
    size_t size = (n + 2) * sizeof(char*);
    self->prereqs      = (char**)REALLOCATE(self->prereqs, size);
    self->prereqs[n]   = CFCUtil_strdup(parcel);
    self->prereqs[n+1] = NULL;
    self->num_prereqs  = n + 1;
}

void
CFCHierarchy_build(CFCHierarchy *self) {
    // Read .cfp files.
    for (size_t i = 0; self->sources[i] != NULL; i++) {
        S_parse_source_cfp_files(self->sources[i]);
    }

    // Copy array of source parcels.
    CFCParcel **parcels = CFCParcel_all_parcels();
    size_t num_source_parcels = 0;
    while (parcels[num_source_parcels] != NULL) { num_source_parcels++; }
    size_t alloc_size = num_source_parcels * sizeof(CFCParcel*);
    CFCParcel **source_parcels = (CFCParcel**)MALLOCATE(alloc_size);
    memcpy(source_parcels, parcels, alloc_size);

    // Find prerequisite parcels.
    for (size_t i = 0; i < num_source_parcels; i++) {
        S_find_prereqs(self, source_parcels[i]);
    }

    // Read .cfh and .md files.
    for (size_t i = 0; self->sources[i] != NULL; i++) {
        S_parse_cf_files(self, self->sources[i], false);
        S_find_doc_files(self->sources[i]);
    }

    // Read .cfh files of included parcels.
    parcels = CFCParcel_all_parcels();
    for (size_t i = 0; parcels[i] != NULL; i++) {
        CFCParcel *parcel = parcels[i];
        if (CFCParcel_included(parcel)) {
            const char *source_dir = CFCParcel_get_source_dir(parcel);
            S_parse_cf_files(self, source_dir, true);
        }
    }

    for (int i = 0; self->classes[i] != NULL; i++) {
        CFCClass_resolve_types(self->classes[i]);
    }

    S_connect_classes(self);
    for (size_t i = 0; self->trees[i] != NULL; i++) {
        CFCClass_grow_tree(self->trees[i]);
    }

    FREEMEM(source_parcels);
}

static void
S_parse_source_cfp_files(const char *source_dir) {
    CFCFindFilesContext context;
    context.ext       = ".cfp";
    context.paths     = (char**)CALLOCATE(1, sizeof(char*));
    context.num_paths = 0;
    CFCUtil_walk(source_dir, S_find_files, &context);

    // Parse .cfp files and register the parcels they define.
    for (int i = 0; context.paths[i] != NULL; i++) {
        const char *path = context.paths[i];
        char *path_part = S_extract_path_part(path, source_dir, ".cfp");
        CFCFileSpec *file_spec
            = CFCFileSpec_new(source_dir, path_part, ".cfp", false);
        CFCParcel *parcel = CFCParcel_new_from_file(file_spec);
        const char *name = CFCParcel_get_name(parcel);
        CFCParcel *existing = CFCParcel_fetch(name);
        if (existing) {
            CFCUtil_die("Parcel '%s' defined twice in %s and %s",
                        CFCParcel_get_name(parcel),
                        CFCParcel_get_cfp_path(existing), path);
        }
        else {
            CFCParcel_register(parcel);
        }
        CFCBase_decref((CFCBase*)parcel);
        CFCBase_decref((CFCBase*)file_spec);
        FREEMEM(path_part);
    }

    CFCUtil_free_string_array(context.paths);
}

static void
S_find_prereqs(CFCHierarchy *self, CFCParcel *parcel) {
    CFCPrereq **prereqs = CFCParcel_get_prereqs(parcel);

    for (size_t i = 0; prereqs[i] != NULL; i++) {
        S_find_prereq(self, parcel, prereqs[i]);
    }
}

static void
S_find_prereq(CFCHierarchy *self, CFCParcel *parent, CFCPrereq *prereq) {
    const char *name        = CFCPrereq_get_name(prereq);
    CFCVersion *min_version = CFCPrereq_get_version(prereq);

    // Check whether prereq was processed already.
    CFCParcel **parcels = CFCParcel_all_parcels();
    for (int i = 0; parcels[i]; ++i) {
        CFCParcel *parcel = parcels[i];
        const char *other_name = CFCParcel_get_name(parcel);

        if (strcmp(other_name, name) == 0) {
            CFCVersion *other_version = CFCParcel_get_version(parcel);
            CFCVersion *major_version = CFCParcel_get_major_version(parcel);

            if (CFCVersion_compare_to(major_version, min_version) <= 0
                && CFCVersion_compare_to(min_version, other_version) <= 0
               ) {
                // Compatible version found.
                return;
            }
            else {
                CFCUtil_die("Parcel %s %s required by %s not compatible with"
                            " version %s required by %s",
                            name, other_version, "[TODO]",
                            CFCVersion_get_vstring(min_version),
                            CFCParcel_get_name(parent));
            }
        }
    }

    CFCParcel *parcel = NULL;

    // TODO: Decide whether to prefer higher versions from directories
    // that come later in the list of include dirs or stop processing once
    // a suitable version was found in a dir.
    for (size_t i = 0; self->includes[i] != NULL; i++) {
        char *name_dir = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s",
                                         self->includes[i], name);

        if (CFCUtil_is_dir(name_dir)) {
            void *dirhandle = CFCUtil_opendir(name_dir);
            const char *entry = NULL;

            while (NULL != (entry = CFCUtil_dirnext(dirhandle))) {
                if (!CFCVersion_is_vstring(entry)) { continue; }

                char *version_dir = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s",
                                                    name_dir, entry);

                if (CFCUtil_is_dir(version_dir)) {
                    parcel = S_audition_parcel(version_dir, entry, min_version,
                                               parcel);
                }

                FREEMEM(version_dir);
            }

            CFCUtil_closedir(dirhandle, name_dir);
        }

        FREEMEM(name_dir);
    }

    if (parcel == NULL) {
        CFCUtil_die("Parcel %s %s required by %s not found",
                    name, CFCVersion_get_vstring(min_version),
                    CFCParcel_get_name(parent));
    }

    CFCParcel_register(parcel);

    S_find_prereqs(self, parcel);

    CFCBase_decref((CFCBase*)parcel);
}

static CFCParcel*
S_audition_parcel(const char *version_dir, const char *vstring,
                  CFCVersion *min_version, CFCParcel *best) {
    CFCVersion *version      = CFCVersion_new(vstring);
    CFCVersion *best_version = best ? CFCParcel_get_version(best) : NULL;

    // Version must match min_version and be greater than the previous best.
    if (CFCVersion_compare_to(version, min_version) >= 0
        && (best_version == NULL
            || CFCVersion_compare_to(version, best_version) > 0)
       ) {
        // Parse parcel JSON for major version check.
        CFCFileSpec *file_spec = CFCFileSpec_new(version_dir, "parcel",
                                                 ".json", true);
        CFCParcel *parcel = CFCParcel_new_from_file(file_spec);
        CFCVersion *major_version = CFCParcel_get_major_version(parcel);

        if (CFCVersion_compare_to(major_version, min_version) <= 0) {
            CFCBase_decref((CFCBase*)best);
            best = parcel;
        }
        else {
            CFCBase_decref((CFCBase*)parcel);
        }

        CFCBase_decref((CFCBase*)file_spec);
    }

    CFCBase_decref((CFCBase*)version);

    return best;
}

static void
S_parse_cf_files(CFCHierarchy *self, const char *source_dir, int is_included) {
    CFCFindFilesContext context;
    context.ext       = ".cfh";
    context.paths     = (char**)CALLOCATE(1, sizeof(char*));
    context.num_paths = 0;
    CFCUtil_walk(source_dir, S_find_files, &context);

    // Process any file that has at least one class declaration.
    for (int i = 0; context.paths[i] != NULL; i++) {
        // Derive the name of the class that owns the module file.
        char *source_path = context.paths[i];
        char *path_part = S_extract_path_part(source_path, source_dir, ".cfh");

        // Ignore hidden files.
        if (path_part[0] == '.'
            || strstr(path_part, CHY_DIR_SEP ".") != NULL) {
            continue;
        }

        CFCFileSpec *file_spec = CFCFileSpec_new(source_dir, path_part, ".cfh",
                                                 is_included);

        // Slurp and parse file.
        size_t unused;
        char *content = CFCUtil_slurp_text(source_path, &unused);
        CFCFile *file = CFCParser_parse_file(self->parser, content, file_spec);
        FREEMEM(content);
        if (!file) {
            int lineno = CFCParser_get_lineno(self->parser);
            CFCUtil_die("%s:%d: parser error", source_path, lineno);
        }

        // Make sure path_part is unique because the name of the generated
        // C header is derived from it.
        CFCFile *existing = S_fetch_file(self, path_part);
        if (existing) {
            CFCUtil_die("File %s.cfh found twice in %s and %s",
                        path_part, CFCFile_get_source_dir(existing),
                        source_dir);
        }

        S_add_file(self, file);

        CFCBase_decref((CFCBase*)file);
        CFCBase_decref((CFCBase*)file_spec);
        FREEMEM(path_part);
    }
    self->classes[self->num_classes] = NULL;

    CFCUtil_free_string_array(context.paths);
}

static void
S_find_doc_files(const char *source_dir) {
    CFCFindFilesContext context;
    context.ext       = ".md";
    context.paths     = (char**)CALLOCATE(1, sizeof(char*));
    context.num_paths = 0;
    CFCUtil_walk(source_dir, S_find_files, &context);

    for (int i = 0; context.paths[i] != NULL; i++) {
        char *path = context.paths[i];
        char *path_part = S_extract_path_part(path, source_dir, ".md");
        CFCDocument *doc = CFCDocument_create(path, path_part);

        CFCBase_decref((CFCBase*)doc);
        FREEMEM(path_part);
    }

    CFCUtil_free_string_array(context.paths);
}

static void
S_find_files(const char *path, void *arg) {
    CFCFindFilesContext *context = (CFCFindFilesContext*)arg;
    const char  *ext       = context->ext;
    size_t       path_len  = strlen(path);
    size_t       ext_len   = strlen(ext);

    if (path_len > ext_len && (strcmp(path + path_len - ext_len, ext) == 0)) {
        size_t   num_paths = context->num_paths;
        size_t   size      = (num_paths + 2) * sizeof(char*);
        char   **paths     = (char**)REALLOCATE(context->paths, size);

        paths[num_paths]     = CFCUtil_strdup(path);
        paths[num_paths + 1] = NULL;

        context->num_paths++;
        context->paths = paths;
    }
}

static char*
S_extract_path_part(const char *path, const char *dir, const char *ext) {
    size_t path_len = strlen(path);
    size_t dir_len  = strlen(dir);
    size_t ext_len  = strlen(ext);

    if (path_len <= dir_len + ext_len) {
        CFCUtil_die("Unexpected path '%s'", path);
    }
    if (strncmp(path, dir, dir_len) != 0) {
        CFCUtil_die("'%s' doesn't start with '%s'", path, dir);
    }
    if (strcmp(path + path_len - ext_len, ext) != 0) {
        CFCUtil_die("'%s' doesn't end with '%s'", path, ext);
    }

    const char *src = path + dir_len;
    size_t path_part_len = path_len - (dir_len + ext_len);
    while (path_part_len && *src == CHY_DIR_SEP_CHAR) {
        ++src;
        --path_part_len;
    }

    return CFCUtil_strndup(src, path_part_len);
}

static void
S_connect_classes(CFCHierarchy *self) {
    // Wrangle the classes into hierarchies and figure out inheritance.
    for (int i = 0; self->classes[i] != NULL; i++) {
        CFCClass *klass = self->classes[i];
        const char *parent_name = CFCClass_get_parent_class_name(klass);
        if (parent_name) {
            for (size_t j = 0; ; j++) {
                CFCClass *maybe_parent = self->classes[j];
                if (!maybe_parent) {
                    CFCUtil_die("Parent class '%s' not defined", parent_name);
                }
                const char *maybe_parent_name
                    = CFCClass_get_name(maybe_parent);
                if (strcmp(parent_name, maybe_parent_name) == 0) {
                    CFCClass_add_child(maybe_parent, klass);
                    break;
                }
            }
        }
        else {
            S_add_tree(self, klass);
        }
    }
}

void
CFCHierarchy_read_host_data_json(CFCHierarchy *self, const char *host_lang) {
    CHY_UNUSED_VAR(self);
    CFCParcel **parcels = CFCParcel_all_parcels();

    for (int i = 0; parcels[i]; ++i) {
        CFCParcel *parcel = parcels[i];
        if (CFCParcel_included(parcel)) {
            CFCParcel_read_host_data_json(parcel, host_lang);
        }
    }
}

int
CFCHierarchy_propagate_modified(CFCHierarchy *self, int modified) {
    // Seed the recursive write.
    int somebody_is_modified = false;
    for (size_t i = 0; self->trees[i] != NULL; i++) {
        CFCClass *tree = self->trees[i];
        if (S_do_propagate_modified(self, tree, modified)) {
            somebody_is_modified = true;
        }
    }
    if (somebody_is_modified || modified) {
        return true;
    }
    else {
        return false;
    }
}

int
S_do_propagate_modified(CFCHierarchy *self, CFCClass *klass, int modified) {
    const char *path_part = CFCClass_get_path_part(klass);
    CFCUTIL_NULL_CHECK(path_part);
    CFCFile *file = S_fetch_file(self, path_part);
    CFCUTIL_NULL_CHECK(file);
    const char *source_path = CFCFile_get_path(file);
    char *h_path = CFCFile_h_path(file, self->inc_dest);

    if (!CFCUtil_current(source_path, h_path)) {
        modified = true;
    }
    FREEMEM(h_path);
    if (modified) {
        CFCFile_set_modified(file, modified);
    }

    // Proceed to the next generation.
    int somebody_is_modified = modified;
    CFCClass **children = CFCClass_children(klass);
    for (size_t i = 0; children[i] != NULL; i++) {
        CFCClass *kid = children[i];
        if (CFCClass_final(klass)) {
            CFCUtil_die("Attempt to inherit from final class '%s' by '%s'",
                        CFCClass_get_name(klass),
                        CFCClass_get_name(kid));
        }
        if (S_do_propagate_modified(self, kid, modified)) {
            somebody_is_modified = 1;
        }
    }

    return somebody_is_modified;
}

static void
S_add_tree(CFCHierarchy *self, CFCClass *klass) {
    CFCUTIL_NULL_CHECK(klass);
    const char *full_struct_sym = CFCClass_full_struct_sym(klass);
    for (size_t i = 0; self->trees[i] != NULL; i++) {
        const char *existing = CFCClass_full_struct_sym(self->trees[i]);
        if (strcmp(full_struct_sym, existing) == 0) {
            CFCUtil_die("Tree '%s' alread added", full_struct_sym);
        }
    }
    self->num_trees++;
    size_t size = (self->num_trees + 1) * sizeof(CFCClass*);
    self->trees = (CFCClass**)REALLOCATE(self->trees, size);
    self->trees[self->num_trees - 1]
        = (CFCClass*)CFCBase_incref((CFCBase*)klass);
    self->trees[self->num_trees] = NULL;
}

CFCClass**
CFCHierarchy_ordered_classes(CFCHierarchy *self) {
    size_t num_classes = 0;
    size_t max_classes = 10;
    CFCClass **ladder = (CFCClass**)MALLOCATE(
                            (max_classes + 1) * sizeof(CFCClass*));
    for (size_t i = 0; self->trees[i] != NULL; i++) {
        CFCClass *tree = self->trees[i];
        CFCClass **child_ladder = CFCClass_tree_to_ladder(tree);
        for (size_t j = 0; child_ladder[j] != NULL; j++) {
            if (num_classes == max_classes) {
                max_classes += 10;
                ladder = (CFCClass**)REALLOCATE(
                             ladder, (max_classes + 1) * sizeof(CFCClass*));
            }
            ladder[num_classes++] = child_ladder[j];
        }
        FREEMEM(child_ladder);
    }
    ladder[num_classes] = NULL;
    return ladder;
}

void
CFCHierarchy_write_log(CFCHierarchy *self) {
    // For now, we only write an empty file that can be used as a Makefile
    // target. It might be useful to add statistics about the class hierarchy
    // later.
    const char *file_content = "{}\n";

    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "hierarchy.json",
                                     self->dest);
    remove(filepath);
    CFCUtil_write_file(filepath, file_content, strlen(file_content));
    FREEMEM(filepath);
}

static CFCFile*
S_fetch_file(CFCHierarchy *self, const char *path_part) {
    for (size_t i = 0; self->files[i] != NULL; i++) {
        const char *existing = CFCFile_get_path_part(self->files[i]);
        if (strcmp(path_part, existing) == 0) {
            return self->files[i];
        }
    }
    return NULL;
}

static void
S_add_file(CFCHierarchy *self, CFCFile *file) {
    CFCUTIL_NULL_CHECK(file);
    CFCClass **classes = CFCFile_classes(file);

    for (size_t i = 0; self->files[i] != NULL; i++) {
        CFCFile *existing = self->files[i];
        CFCClass **existing_classes = CFCFile_classes(existing);
        for (size_t j = 0; classes[j] != NULL; j++) {
            const char *new_class_name = CFCClass_get_name(classes[j]);
            for (size_t k = 0; existing_classes[k] != NULL; k++) {
                const char *existing_class_name
                    = CFCClass_get_name(existing_classes[k]);
                if (strcmp(new_class_name, existing_class_name) == 0) {
                    CFCUtil_die("Class '%s' already registered",
                                new_class_name);
                }
            }
        }
    }

    self->num_files++;
    size_t size = (self->num_files + 1) * sizeof(CFCFile*);
    self->files = (CFCFile**)REALLOCATE(self->files, size);
    self->files[self->num_files - 1]
        = (CFCFile*)CFCBase_incref((CFCBase*)file);
    self->files[self->num_files] = NULL;

    for (size_t i = 0; classes[i] != NULL; i++) {
        if (self->num_classes == self->classes_cap) {
            self->classes_cap += 10;
            self->classes = (CFCClass**)REALLOCATE(
                              self->classes,
                              (self->classes_cap + 1) * sizeof(CFCClass*));
        }
        self->classes[self->num_classes++]
            = (CFCClass*)CFCBase_incref((CFCBase*)classes[i]);
        self->classes[self->num_classes] = NULL;
    }
}

struct CFCFile**
CFCHierarchy_files(CFCHierarchy *self) {
    return self->files;
}

const char**
CFCHierarchy_get_source_dirs(CFCHierarchy *self) {
    return (const char **)self->sources;
}

const char**
CFCHierarchy_get_include_dirs(CFCHierarchy *self) {
    return (const char **)self->includes;
}

const char*
CFCHierarchy_get_dest(CFCHierarchy *self) {
    return self->dest;
}

const char*
CFCHierarchy_get_include_dest(CFCHierarchy *self) {
    return self->inc_dest;
}

const char*
CFCHierarchy_get_source_dest(CFCHierarchy *self) {
    return self->src_dest;
}


