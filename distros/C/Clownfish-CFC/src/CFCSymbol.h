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

/** Clownfish::CFC::Model::Symbol - Base class for Clownfish symbols.
 *
 * Clownfish::CFC::Model::Symbol serves as a parent class for entities which
 * may live in the global namespace, such as classes, functions, methods, and
 * variables.
 */

#ifndef H_CFCSYMBOL
#define H_CFCSYMBOL

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCSymbol CFCSymbol;
struct CFCClass;
struct CFCParcel;

#ifdef CFC_NEED_SYMBOL_STRUCT_DEF
#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
struct CFCSymbol {
    CFCBase base;
    char *exposure;
    char *name;
};
#endif

/**
 * @param exposure The scope in which the symbol is exposed.  Must be
 * 'public', 'parcel', 'private', or 'local'.
 * @param name The local identifier for the symbol.
 */
CFCSymbol*
CFCSymbol_new(const char *exposure, const char *name);

CFCSymbol*
CFCSymbol_init(CFCSymbol *self, const char *exposure, const char *name);

void
CFCSymbol_destroy(CFCSymbol *self);

/** Return true if the symbols are "equal", false otherwise.
 */
int
CFCSymbol_equals(CFCSymbol *self, CFCSymbol *other);

const char*
CFCSymbol_get_exposure(CFCSymbol *self);

/** Return true if the Symbol's exposure is "public".
 */
int
CFCSymbol_public(CFCSymbol *self);

/** Return true if the Symbol's exposure is "parcel".
 */
int
CFCSymbol_parcel(CFCSymbol *self);

/** Return true if the Symbol's exposure is "private".
 */
int
CFCSymbol_private(CFCSymbol *self);

/** Return true if the Symbol's exposure is "local".
 */
int
CFCSymbol_local(CFCSymbol *self);

/** Accessor for the Symbol's name.
 */
const char*
CFCSymbol_get_name(CFCSymbol *self);

/** Returns the C representation for the symbol minus the parcel's prefix,
 * e.g.  "Lobster_average_lifespan".
 */
char*
CFCSymbol_short_sym(CFCSymbol *self, struct CFCClass *klass);

/** Returns the fully qualified C representation for the symbol, e.g.
 * "crust_Lobster_average_lifespan".
 */
char*
CFCSymbol_full_sym(CFCSymbol *self, struct CFCClass *klass);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCSYMBOL */

