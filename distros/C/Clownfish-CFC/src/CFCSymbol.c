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

#ifndef true
  #define true 1
  #define false 0
#endif

#define CFC_NEED_SYMBOL_STRUCT_DEF
#include "CFCSymbol.h"
#include "CFCClass.h"
#include "CFCParcel.h"
#include "CFCUtil.h"

static const CFCMeta CFCSYMBOL_META = {
    "Clownfish::CFC::Model::Symbol",
    sizeof(CFCSymbol),
    (CFCBase_destroy_t)CFCSymbol_destroy
};

CFCSymbol*
CFCSymbol_new(const char *exposure, const char *name) {
    CFCSymbol *self = (CFCSymbol*)CFCBase_allocate(&CFCSYMBOL_META);
    return CFCSymbol_init(self, exposure, name);
}

static int
S_validate_exposure(const char *exposure) {
    if (!exposure) { return false; }
    if (strcmp(exposure, "public")
        && strcmp(exposure, "parcel")
        && strcmp(exposure, "private")
        && strcmp(exposure, "local")
       ) {
        return false;
    }
    return true;
}

static int
S_validate_identifier(const char *identifier) {
    const char *ptr = identifier;
    if (!CFCUtil_isalpha(*ptr) && *ptr != '_') { return false; }
    for (; *ptr != 0; ptr++) {
        if (!CFCUtil_isalnum(*ptr) && *ptr != '_') { return false; }
    }
    return true;
}

CFCSymbol*
CFCSymbol_init(CFCSymbol *self, const char *exposure, const char *name) {
    // Validate.
    if (!S_validate_exposure(exposure)) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("Invalid exposure: '%s'", exposure ? exposure : "[NULL]");
    }
    if (!name || !S_validate_identifier(name)) {
        CFCBase_decref((CFCBase*)self);
        CFCUtil_die("Invalid name: '%s'",  name ? name : "[NULL]");
    }

    // Assign.
    self->exposure       = CFCUtil_strdup(exposure);
    self->name           = CFCUtil_strdup(name);

    return self;
}

void
CFCSymbol_destroy(CFCSymbol *self) {
    FREEMEM(self->exposure);
    FREEMEM(self->name);
    CFCBase_destroy((CFCBase*)self);
}

int
CFCSymbol_equals(CFCSymbol *self, CFCSymbol *other) {
    if (strcmp(self->name, other->name) != 0) { return false; }
    if (strcmp(self->exposure, other->exposure) != 0) { return false; }
    return true;
}

int
CFCSymbol_public(CFCSymbol *self) {
    return !strcmp(self->exposure, "public");
}

int
CFCSymbol_parcel(CFCSymbol *self) {
    return !strcmp(self->exposure, "parcel");
}

int
CFCSymbol_private(CFCSymbol *self) {
    return !strcmp(self->exposure, "private");
}

int
CFCSymbol_local(CFCSymbol *self) {
    return !strcmp(self->exposure, "local");
}

char*
CFCSymbol_full_sym(CFCSymbol *self, CFCClass *klass) {
    const char *prefix   = CFCClass_get_prefix(klass);
    const char *nickname = CFCClass_get_nickname(klass);
    char *full_sym = CFCUtil_sprintf("%s%s_%s", prefix, nickname, self->name);
    return full_sym;
}

char*
CFCSymbol_short_sym(CFCSymbol *self, CFCClass *klass) {
    const char *nickname = CFCClass_get_nickname(klass);
    char *short_sym = CFCUtil_sprintf("%s_%s", nickname, self->name);
    return short_sym;
}

const char*
CFCSymbol_get_exposure(CFCSymbol *self) {
    return self->exposure;
}

const char*
CFCSymbol_get_name(CFCSymbol *self) {
    return self->name;
}

