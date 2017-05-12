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

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCDocument.h"
#include "CFCUtil.h"

struct CFCDocument {
    CFCBase base;
    char *path;
    char *path_part;
    char *name;
};

static const CFCMeta CFCDOCUMENT_META = {
    "Clownfish::CFC::Model::Document",
    sizeof(CFCDocument),
    (CFCBase_destroy_t)CFCDocument_destroy
};

static CFCDocument **registry = NULL;
static size_t registry_size = 0;
static size_t registry_cap  = 0;

static void
S_register(CFCDocument *self);

CFCDocument*
CFCDocument_create(const char *path, const char *path_part) {
    CFCDocument *self = (CFCDocument*)CFCBase_allocate(&CFCDOCUMENT_META);
    return CFCDocument_do_create(self, path, path_part);
}

CFCDocument*
CFCDocument_do_create(CFCDocument *self, const char *path,
                      const char *path_part) {
    self->path      = CFCUtil_strdup(path);
    self->path_part = CFCUtil_strdup(path_part);

    if (CHY_DIR_SEP_CHAR != '/') {
        for (size_t i = 0; self->path_part[i]; i++) {
            if (self->path_part[i] == '/') {
                self->path_part[i] = CHY_DIR_SEP_CHAR;
            }
        }
    }

    const char *last_dir_sep = strrchr(self->path_part, CHY_DIR_SEP_CHAR);
    if (last_dir_sep) {
        self->name = CFCUtil_strdup(last_dir_sep + 1);
    }
    else {
        self->name = CFCUtil_strdup(self->path_part);
    }

    S_register(self);

    return self;
}

void
CFCDocument_destroy(CFCDocument *self) {
    FREEMEM(self->path);
    FREEMEM(self->path_part);
    FREEMEM(self->name);
    CFCBase_destroy((CFCBase*)self);
}

static void
S_register(CFCDocument *self) {
    if (CFCDocument_fetch(self->name) != NULL) {
        CFCUtil_die("Two documents with name %s", self->name);
    }

    if (registry_size == registry_cap) {
        size_t new_cap = registry_cap + 10;
        size_t bytes   = (new_cap + 1) * sizeof(CFCDocument*);
        registry = (CFCDocument**)REALLOCATE(registry, bytes);
        registry_cap = new_cap;
    }

    registry[registry_size]   = (CFCDocument*)CFCBase_incref((CFCBase*)self);
    registry[registry_size+1] = NULL;
    registry_size++;
}

CFCDocument**
CFCDocument_get_registry() {
    if (registry == NULL) {
        registry = (CFCDocument**)CALLOCATE(1, sizeof(CFCDocument*));
    }

    return registry;
}

CFCDocument*
CFCDocument_fetch(const char *name) {
    for (size_t i = 0; i < registry_size; i++) {
        CFCDocument *doc = registry[i];

        if (strcmp(doc->name, name) == 0) {
            return doc;
        }
    }

    return NULL;
}

void
CFCDocument_clear_registry(void) {
    for (size_t i = 0; i < registry_size; i++) {
        CFCBase_decref((CFCBase*)registry[i]);
    }
    FREEMEM(registry);
    registry_size = 0;
    registry_cap  = 0;
    registry      = NULL;
}

char*
CFCDocument_get_contents(CFCDocument *self) {
    size_t len;
    return CFCUtil_slurp_text(self->path, &len);
}

const char*
CFCDocument_get_path(CFCDocument *self) {
    return self->path;
}

const char*
CFCDocument_get_path_part(CFCDocument *self) {
    return self->path_part;
}

const char*
CFCDocument_get_name(CFCDocument *self) {
    return self->name;
}

