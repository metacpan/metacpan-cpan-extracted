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
#include "CFCParcel.h"
#include "CFCFileSpec.h"
#include "CFCVersion.h"
#include "CFCUtil.h"
#include "CFCJson.h"
#include "CFCClass.h"

struct CFCParcel {
    CFCBase base;
    char *name;
    char *nickname;
    char *host_module_name;
    CFCVersion *version;
    CFCVersion *major_version;
    CFCFileSpec *file_spec;
    char *prefix;
    char *Prefix;
    char *PREFIX;
    char *privacy_sym;
    int is_installed;
    char **inherited_parcels;
    size_t num_inherited_parcels;
    char **struct_syms;
    size_t num_struct_syms;
    CFCPrereq **prereqs;
    size_t num_prereqs;
};

static void
S_set_prereqs(CFCParcel *self, CFCJson *node, const char *path);

static CFCParcel **registry = NULL;
static size_t num_registered = 0;

CFCParcel*
CFCParcel_fetch(const char *name) {
    for (size_t i = 0; i < num_registered ; i++) {
        CFCParcel *existing = registry[i];
        if (strcmp(existing->name, name) == 0) {
            return existing;
        }
    }

    return NULL;
}

void
CFCParcel_register(CFCParcel *self) {
    const char *name     = self->name;
    const char *nickname = self->nickname;

    for (size_t i = 0; i < num_registered ; i++) {
        CFCParcel *other = registry[i];

        if (strcmp(other->name, name) == 0) {
            CFCUtil_die("Parcel '%s' already registered", name);
        }
        if (strcmp(other->nickname, nickname) == 0) {
            CFCUtil_die("Parcel with nickname '%s' already registered",
                        nickname);
        }
    }

    size_t size = (num_registered + 2) * sizeof(CFCParcel*);
    registry = (CFCParcel**)REALLOCATE(registry, size);
    registry[num_registered++] = (CFCParcel*)CFCBase_incref((CFCBase*)self);
    registry[num_registered]   = NULL;
}

CFCParcel**
CFCParcel_all_parcels(void) {
    if (registry == NULL) {
        registry = (CFCParcel**)MALLOCATE(sizeof(CFCParcel*));
        registry[0] = NULL;
    }

    return registry;
}

void
CFCParcel_reap_singletons(void) {
    for (size_t i = 0; i < num_registered; i++) {
        CFCBase_decref((CFCBase*)registry[i]);
    }
    FREEMEM(registry);
    num_registered = 0;
    registry = NULL;
}

static int
S_validate_name_or_nickname(const char *orig) {
    const char *ptr = orig;
    for (; *ptr != 0; ptr++) {
        if (!CFCUtil_isalpha(*ptr)) { return false; }
    }
    return true;
}

static const CFCMeta CFCPARCEL_META = {
    "Clownfish::CFC::Model::Parcel",
    sizeof(CFCParcel),
    (CFCBase_destroy_t)CFCParcel_destroy
};

CFCParcel*
CFCParcel_new(const char *name, const char *nickname, CFCVersion *version,
              CFCVersion *major_version, CFCFileSpec *file_spec) {
    CFCParcel *self = (CFCParcel*)CFCBase_allocate(&CFCPARCEL_META);
    return CFCParcel_init(self, name, nickname, version, major_version,
                          file_spec);
}

CFCParcel*
CFCParcel_init(CFCParcel *self, const char *name, const char *nickname,
               CFCVersion *version, CFCVersion *major_version,
               CFCFileSpec *file_spec) {
    // Validate name.
    if (!name || !S_validate_name_or_nickname(name)) {
        CFCUtil_die("Invalid name: '%s'", name ? name : "[NULL]");
    }
    self->name = CFCUtil_strdup(name);

    // Validate or derive nickname.
    if (nickname) {
        if (!S_validate_name_or_nickname(nickname)) {
            CFCUtil_die("Invalid nickname: '%s'", nickname);
        }
        self->nickname = CFCUtil_strdup(nickname);
    }
    else {
        // Default nickname to name.
        self->nickname = CFCUtil_strdup(name);
    }

    // Default to version v0.
    if (version) {
        self->version = (CFCVersion*)CFCBase_incref((CFCBase*)version);
    }
    else {
        self->version = CFCVersion_new("v0");
    }
    if (major_version) {
        self->major_version
            = (CFCVersion*)CFCBase_incref((CFCBase*)major_version);
    }
    else {
        self->major_version = CFCVersion_new("v0");
    }

    // Set file_spec.
    self->file_spec = (CFCFileSpec*)CFCBase_incref((CFCBase*)file_spec);

    // Derive prefix, Prefix, PREFIX.
    size_t nickname_len  = strlen(self->nickname);
    size_t prefix_len = nickname_len ? nickname_len + 1 : 0;
    size_t amount     = prefix_len + 1;
    self->prefix = (char*)MALLOCATE(amount);
    self->Prefix = (char*)MALLOCATE(amount);
    self->PREFIX = (char*)MALLOCATE(amount);
    memcpy(self->Prefix, self->nickname, nickname_len);
    if (nickname_len) {
        self->Prefix[nickname_len]  = '_';
        self->Prefix[nickname_len + 1]  = '\0';
    }
    else {
        self->Prefix[nickname_len] = '\0';
    }
    for (size_t i = 0; i < amount; i++) {
        self->prefix[i] = CFCUtil_tolower(self->Prefix[i]);
        self->PREFIX[i] = CFCUtil_toupper(self->Prefix[i]);
    }
    self->prefix[prefix_len] = '\0';
    self->Prefix[prefix_len] = '\0';
    self->PREFIX[prefix_len] = '\0';

    // Derive privacy symbol.
    size_t privacy_sym_len = nickname_len + 4;
    self->privacy_sym = (char*)MALLOCATE(privacy_sym_len + 1);
    memcpy(self->privacy_sym, "CFP_", 4);
    for (size_t i = 0; i < nickname_len; i++) {
        self->privacy_sym[i+4] = CFCUtil_toupper(self->nickname[i]);
    }
    self->privacy_sym[privacy_sym_len] = '\0';

    // Initialize flags.
    self->is_installed = false;

    // Initialize arrays.
    self->inherited_parcels = (char**)CALLOCATE(1, sizeof(char*));
    self->num_inherited_parcels = 0;
    self->struct_syms = (char**)CALLOCATE(1, sizeof(char*));
    self->num_struct_syms = 0;
    self->prereqs = (CFCPrereq**)CALLOCATE(1, sizeof(CFCPrereq*));
    self->num_prereqs = 0;

    return self;
}

static CFCParcel*
S_new_from_json(const char *json, CFCFileSpec *file_spec) {
    const char *path = file_spec ? CFCFileSpec_get_path(file_spec) : "[NULL]";
    CFCJson *parsed = CFCJson_parse(json);
    if (!parsed) {
        CFCUtil_die("Invalid JSON parcel definition in '%s'", path);
    }
    if (CFCJson_get_type(parsed) != CFCJSON_HASH) {
        CFCUtil_die("Parcel definition must be a hash in '%s'", path);
    }
    const char  *name          = NULL;
    const char  *nickname      = NULL;
    int          installed     = true;
    CFCVersion  *version       = NULL;
    CFCVersion  *major_version = NULL;
    CFCJson     *prereqs       = NULL;
    CFCJson    **children      = CFCJson_get_children(parsed);
    for (size_t i = 0; children[i]; i += 2) {
        const char *key = CFCJson_get_string(children[i]);
        CFCJson *value = children[i + 1];
        int value_type = CFCJson_get_type(value);
        if (strcmp(key, "name") == 0) {
            if (value_type != CFCJSON_STRING) {
                CFCUtil_die("'name' must be a string (filepath %s)", path);
            }
            name = CFCJson_get_string(value);
        }
        else if (strcmp(key, "nickname") == 0) {
            if (value_type != CFCJSON_STRING) {
                CFCUtil_die("'nickname' must be a string (filepath %s)",
                            path);
            }
            nickname = CFCJson_get_string(value);
        }
        else if (strcmp(key, "installed") == 0) {
            if (value_type != CFCJSON_BOOL) {
                CFCUtil_die("'installed' must be a boolean (filepath %s)",
                            path);
            }
            installed = CFCJson_get_bool(value);
        }
        else if (strcmp(key, "version") == 0) {
            if (value_type != CFCJSON_STRING) {
                CFCUtil_die("'version' must be a string (filepath %s)",
                            path);
            }
            version = CFCVersion_new(CFCJson_get_string(value));
        }
        else if (strcmp(key, "major_version") == 0) {
            if (value_type != CFCJSON_STRING) {
                CFCUtil_die("'major_version' must be a string (filepath %s)",
                            path);
            }
            major_version = CFCVersion_new(CFCJson_get_string(value));
        }
        else if (strcmp(key, "prerequisites") == 0) {
            if (value_type != CFCJSON_HASH) {
                CFCUtil_die("'prerequisites' must be a hash (filepath %s)",
                            path);
            }
            prereqs = value;
        }
        else {
            CFCUtil_die("Unrecognized key: '%s' (filepath '%s')",
                        key, path);
        }
    }
    if (!name) {
        CFCUtil_die("Missing required key 'name' (filepath '%s')", path);
    }
    if (!version) {
        CFCUtil_die("Missing required key 'version' (filepath '%s')", path);
    }
    CFCParcel *self = CFCParcel_new(name, nickname, version, major_version,
                                    file_spec);
    self->is_installed = installed;
    if (prereqs) {
        S_set_prereqs(self, prereqs, path);
    }
    CFCBase_decref((CFCBase*)version);
    CFCBase_decref((CFCBase*)major_version);

    CFCJson_destroy(parsed);
    return self;
}

static void
S_set_prereqs(CFCParcel *self, CFCJson *node, const char *path) {
    size_t num_prereqs = CFCJson_get_num_children(node) / 2;
    CFCJson **children = CFCJson_get_children(node);
    CFCPrereq **prereqs
        = (CFCPrereq**)MALLOCATE((num_prereqs + 1) * sizeof(CFCPrereq*));

    for (size_t i = 0; i < num_prereqs; ++i) {
        const char *name = CFCJson_get_string(children[2*i]);

        CFCJson *value = children[2*i+1];
        int value_type = CFCJson_get_type(value);
        CFCVersion *version = NULL;
        if (value_type == CFCJSON_STRING) {
            version = CFCVersion_new(CFCJson_get_string(value));
        }
        else if (value_type != CFCJSON_NULL) {
            CFCUtil_die("Invalid prereq value (filepath '%s')", path);
        }

        prereqs[i] = CFCPrereq_new(name, version);

        CFCBase_decref((CFCBase*)version);
    }
    prereqs[num_prereqs] = NULL;

    // Assume that prereqs are empty.
    FREEMEM(self->prereqs);
    self->prereqs     = prereqs;
    self->num_prereqs = num_prereqs;
}

CFCParcel*
CFCParcel_new_from_json(const char *json, CFCFileSpec *file_spec) {
    return S_new_from_json(json, file_spec);
}

CFCParcel*
CFCParcel_new_from_file(CFCFileSpec *file_spec) {
    const char *path = CFCFileSpec_get_path(file_spec);
    size_t len;
    char *json = CFCUtil_slurp_text(path, &len);
    CFCParcel *self = S_new_from_json(json, file_spec);
    FREEMEM(json);
    return self;
}

void
CFCParcel_destroy(CFCParcel *self) {
    FREEMEM(self->name);
    FREEMEM(self->nickname);
    FREEMEM(self->host_module_name);
    CFCBase_decref((CFCBase*)self->version);
    CFCBase_decref((CFCBase*)self->major_version);
    CFCBase_decref((CFCBase*)self->file_spec);
    FREEMEM(self->prefix);
    FREEMEM(self->Prefix);
    FREEMEM(self->PREFIX);
    FREEMEM(self->privacy_sym);
    CFCUtil_free_string_array(self->inherited_parcels);
    CFCUtil_free_string_array(self->struct_syms);
    for (size_t i = 0; self->prereqs[i]; ++i) {
        CFCBase_decref((CFCBase*)self->prereqs[i]);
    }
    FREEMEM(self->prereqs);
    CFCBase_destroy((CFCBase*)self);
}

int
CFCParcel_equals(CFCParcel *self, CFCParcel *other) {
    if (strcmp(self->name, other->name)) { return false; }
    if (strcmp(self->nickname, other->nickname)) { return false; }
    if (CFCVersion_compare_to(self->version, other->version) != 0) {
        return false;
    }
    if (CFCParcel_included(self) != CFCParcel_included(other)) {
        return false;
    }
    return true;
}

const char*
CFCParcel_get_name(CFCParcel *self) {
    return self->name;
}

const char*
CFCParcel_get_nickname(CFCParcel *self) {
    return self->nickname;
}

const char*
CFCParcel_get_host_module_name(CFCParcel *self) {
    return self->host_module_name;
}

void
CFCParcel_set_host_module_name(CFCParcel *self, const char *name) {
    if (self->host_module_name != NULL) {
        if (strcmp(self->host_module_name, name) != 0) {
            CFCUtil_die("Conflicting host modules '%s' and '%s' for parcel %s",
                        self->host_module_name, name, self->name);
        }
    }
    else {
        self->host_module_name = CFCUtil_strdup(name);
    }
}

int
CFCParcel_is_installed(CFCParcel *self) {
    return self->is_installed;
}

CFCVersion*
CFCParcel_get_version(CFCParcel *self) {
    return self->version;
}

CFCVersion*
CFCParcel_get_major_version(CFCParcel *self) {
    return self->major_version;
}

const char*
CFCParcel_get_prefix(CFCParcel *self) {
    return self->prefix;
}

const char*
CFCParcel_get_Prefix(CFCParcel *self) {
    return self->Prefix;
}

const char*
CFCParcel_get_PREFIX(CFCParcel *self) {
    return self->PREFIX;
}

const char*
CFCParcel_get_privacy_sym(CFCParcel *self) {
    return self->privacy_sym;
}

const char*
CFCParcel_get_cfp_path(CFCParcel *self) {
    return self->file_spec
           ? CFCFileSpec_get_path(self->file_spec)
           : NULL;
}

const char*
CFCParcel_get_source_dir(CFCParcel *self) {
    return self->file_spec
           ? CFCFileSpec_get_source_dir(self->file_spec)
           : NULL;
}

int
CFCParcel_included(CFCParcel *self) {
    return self->file_spec ? CFCFileSpec_included(self->file_spec) : false;
}

void
CFCParcel_add_inherited_parcel(CFCParcel *self, CFCParcel *inherited) {
    const char *name     = CFCParcel_get_name(self);
    const char *inh_name = CFCParcel_get_name(inherited);

    if (strcmp(name, inh_name) == 0) { return; }

    for (size_t i = 0; self->inherited_parcels[i]; ++i) {
        const char *other_name = self->inherited_parcels[i];
        if (strcmp(other_name, inh_name) == 0) { return; }
    }

    size_t num_parcels = self->num_inherited_parcels;
    self->inherited_parcels
        = (char**)REALLOCATE(self->inherited_parcels,
                             (num_parcels + 2) * sizeof(char*));
    self->inherited_parcels[num_parcels]   = CFCUtil_strdup(inh_name);
    self->inherited_parcels[num_parcels+1] = NULL;
    self->num_inherited_parcels = num_parcels + 1;
}

CFCParcel**
CFCParcel_inherited_parcels(CFCParcel *self) {
    CFCParcel **parcels
        = (CFCParcel**)CALLOCATE(self->num_inherited_parcels + 1,
                                 sizeof(CFCParcel*));

    for (size_t i = 0; self->inherited_parcels[i]; ++i) {
        parcels[i] = CFCParcel_fetch(self->inherited_parcels[i]);
    }

    return parcels;
}

CFCPrereq**
CFCParcel_get_prereqs(CFCParcel *self) {
    return self->prereqs;
}

CFCParcel**
CFCParcel_prereq_parcels(CFCParcel *self) {
    CFCParcel **parcels
        = (CFCParcel**)CALLOCATE(self->num_prereqs + 1, sizeof(CFCParcel*));

    for (size_t i = 0; self->prereqs[i]; ++i) {
        const char *name = CFCPrereq_get_name(self->prereqs[i]);
        parcels[i] = CFCParcel_fetch(name);
    }

    return parcels;
}

int
CFCParcel_has_prereq(CFCParcel *self, CFCParcel *parcel) {
    const char *name = CFCParcel_get_name(parcel);

    if (strcmp(CFCParcel_get_name(self), name) == 0) {
        return true;
    }

    for (int i = 0; self->prereqs[i]; ++i) {
        const char *prereq_name = CFCPrereq_get_name(self->prereqs[i]);
        if (strcmp(prereq_name, name) == 0) {
            return true;
        }
    }

    return false;
}

void
CFCParcel_read_host_data_json(CFCParcel *self, const char *host_lang) {
    const char *source_dir = CFCParcel_get_source_dir(self);
    char *path = CFCUtil_sprintf("%s" CHY_DIR_SEP "parcel_%s.json", source_dir,
                                 host_lang);

    size_t len;
    char *json = CFCUtil_slurp_text(path, &len);
    CFCJson *extra_data = CFCJson_parse(json);
    if (!extra_data) {
        CFCUtil_die("Invalid JSON in file '%s'", path);
    }

    CFCJson *host_module_json
        = CFCJson_find_hash_elem(extra_data, "host_module");
    if (host_module_json) {
        const char *name = CFCJson_get_string(host_module_json);
        CFCParcel_set_host_module_name(self, name);
    }

    CFCJson *class_hash = CFCJson_find_hash_elem(extra_data, "classes");
    if (class_hash) {
        CFCJson **children = CFCJson_get_children(class_hash);
        for (int i = 0; children[i]; i += 2) {
            const char *class_name = CFCJson_get_string(children[i]);
            CFCClass *klass = CFCClass_fetch_singleton(class_name);
            if (!klass) {
                CFCUtil_die("Class '%s' in '%s' not found", class_name, path);
            }
            CFCClass_read_host_data_json(klass, children[i+1], path);
        }
    }

    CFCJson_destroy(extra_data);
    FREEMEM(json);
    FREEMEM(path);
}

void
CFCParcel_add_struct_sym(CFCParcel *self, const char *struct_sym) {
    size_t num_struct_syms = self->num_struct_syms + 1;
    size_t size = (num_struct_syms + 1) * sizeof(char*);
    char **struct_syms = (char**)REALLOCATE(self->struct_syms, size);
    struct_syms[num_struct_syms-1] = CFCUtil_strdup(struct_sym);
    struct_syms[num_struct_syms]   = NULL;
    self->struct_syms     = struct_syms;
    self->num_struct_syms = num_struct_syms;
}

static CFCParcel*
S_lookup_struct_sym(CFCParcel *self, const char *struct_sym) {
    for (size_t i = 0; self->struct_syms[i]; ++i) {
        if (strcmp(self->struct_syms[i], struct_sym) == 0) {
            return self;
        }
    }

    return NULL;
}

CFCParcel*
CFCParcel_lookup_struct_sym(CFCParcel *self, const char *struct_sym) {
    CFCParcel *parcel = S_lookup_struct_sym(self, struct_sym);

    for (size_t i = 0; self->prereqs[i]; ++i) {
        const char *prereq_name   = CFCPrereq_get_name(self->prereqs[i]);
        CFCParcel  *prereq_parcel = CFCParcel_fetch(prereq_name);
        CFCParcel *maybe_parcel
            = S_lookup_struct_sym(prereq_parcel, struct_sym);

        if (maybe_parcel) {
            if (parcel) {
                CFCUtil_die("Type '%s' is ambigious", struct_sym);
            }
            parcel = maybe_parcel;
        }
    }

    return parcel;
}

int
CFCParcel_is_cfish(CFCParcel *self) {
    return !strcmp(self->prefix, "cfish_");
}

/**************************************************************************/

struct CFCPrereq {
    CFCBase base;
    char *name;
    CFCVersion *version;
};

static const CFCMeta CFCPREREQ_META = {
    "Clownfish::CFC::Model::Prereq",
    sizeof(CFCPrereq),
    (CFCBase_destroy_t)CFCPrereq_destroy
};

CFCPrereq*
CFCPrereq_new(const char *name, CFCVersion *version) {
    CFCPrereq *self = (CFCPrereq*)CFCBase_allocate(&CFCPREREQ_META);
    return CFCPrereq_init(self, name, version);
}

CFCPrereq*
CFCPrereq_init(CFCPrereq *self, const char *name, CFCVersion *version) {
    // Validate name.
    if (!name || !S_validate_name_or_nickname(name)) {
        CFCUtil_die("Invalid name: '%s'", name ? name : "[NULL]");
    }
    self->name = CFCUtil_strdup(name);

    // Default to version v0.
    if (version) {
        self->version = (CFCVersion*)CFCBase_incref((CFCBase*)version);
    }
    else {
        self->version = CFCVersion_new("v0");
    }

    return self;
}

void
CFCPrereq_destroy(CFCPrereq *self) {
    FREEMEM(self->name);
    CFCBase_decref((CFCBase*)self->version);
    CFCBase_destroy((CFCBase*)self);
}

const char*
CFCPrereq_get_name(CFCPrereq *self) {
    return self->name;
}

CFCVersion*
CFCPrereq_get_version(CFCPrereq *self) {
    return self->version;
}

