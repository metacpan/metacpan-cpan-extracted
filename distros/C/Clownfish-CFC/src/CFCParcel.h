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

/** Clownfish::CFC::Model::Parcel - Collection of code.
 *
 * A Parcel is a cohesive collection of code, which could, in theory, be
 * published as as a single entity.
 *
 * Clownfish supports two-tier manual namespacing, using a prefix, an optional
 * class nickname, and the local symbol:
 *
 *     prefix_ClassNick_local_symbol
 *
 * Clownfish::CFC::Model::Parcel supports the first tier, specifying initial
 * prefixes.  These prefixes come in three capitalization variants: prefix_,
 * Prefix_, and PREFIX_.
 */

#ifndef H_CFCPARCEL
#define H_CFCPARCEL

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCParcel CFCParcel;
typedef struct CFCPrereq CFCPrereq;
struct CFCFileSpec;
struct CFCVersion;

/** Return the parcel which has been registered for `name`.
 */
CFCParcel*
CFCParcel_fetch(const char *name);

/** Register the supplied parcel.  Throws an error if a parcel with the same
 * name has already been registered.
 */
void
CFCParcel_register(CFCParcel *self);

/** Return a NULL-terminated list of all registered parcels.
 */
CFCParcel**
CFCParcel_all_parcels(void);

/** Decref all singletons at shutdown.
 */
void
CFCParcel_reap_singletons(void);

CFCParcel*
CFCParcel_new(const char *name, const char *nickname,
              struct CFCVersion *version, struct CFCVersion *major_version,
              struct CFCFileSpec *file_spec);

CFCParcel*
CFCParcel_new_from_file(struct CFCFileSpec *file_spec);

CFCParcel*
CFCParcel_new_from_json(const char *json, struct CFCFileSpec *file_spec);

CFCParcel*
CFCParcel_init(CFCParcel *self, const char *name, const char *nickname,
               struct CFCVersion *version, struct CFCVersion *major_version,
               struct CFCFileSpec *file_spec);

void
CFCParcel_destroy(CFCParcel *self);

int
CFCParcel_equals(CFCParcel *self, CFCParcel *other);

const char*
CFCParcel_get_name(CFCParcel *self);

const char*
CFCParcel_get_nickname(CFCParcel *self);

const char*
CFCParcel_get_host_module_name(CFCParcel *self);

void
CFCParcel_set_host_module_name(CFCParcel *self, const char *name);

int
CFCParcel_is_installed(CFCParcel *self);

struct CFCVersion*
CFCParcel_get_version(CFCParcel *self);

struct CFCVersion*
CFCParcel_get_major_version(CFCParcel *self);

/** Return the all-lowercase version of the Parcel's prefix.
 */
const char*
CFCParcel_get_prefix(CFCParcel *self);

/** Return the Titlecase version of the Parcel's prefix.
 */
const char*
CFCParcel_get_Prefix(CFCParcel *self);

/** Return the all-caps version of the Parcel's prefix.
 */
const char*
CFCParcel_get_PREFIX(CFCParcel *self);

/* Return the Parcel's privacy symbol.
 */
const char*
CFCParcel_get_privacy_sym(CFCParcel *self);

/* Return the path to the Parcel's .cfp file. May return NULL if the parcel
 * wasn't created from a file.
 */
const char*
CFCParcel_get_cfp_path(CFCParcel *self);

/* Return the Parcel's source or include dir. May return NULL if the parcel
 * wasn't created from a file.
 */
const char*
CFCParcel_get_source_dir(CFCParcel *self);

/** Return true if the parcel is from an include directory.
 */
int
CFCParcel_included(CFCParcel *self);

/** Add another Parcel containing superclasses that subclasses in the Parcel
 * extend.
 */
void
CFCParcel_add_inherited_parcel(CFCParcel *self, CFCParcel *inherited);

/** Return a NULL-terminated array of all Parcels containing superclasses that
 * subclasses in the Parcel extend. Must be freed by the caller.
 */
CFCParcel**
CFCParcel_inherited_parcels(CFCParcel *self);

/** Return a NULL-terminated array of all prerequisites.
 */
CFCPrereq**
CFCParcel_get_prereqs(CFCParcel *self);

/** Return a NULL-terminated array of all prerequisite Parcels. Must be freed
 * by the caller.
 */
CFCParcel**
CFCParcel_prereq_parcels(CFCParcel *self);

/** Return true if parcel equals self or is a direct prerequisite of self.
 */
int
CFCParcel_has_prereq(CFCParcel *self, CFCParcel *parcel);

/** Read host-specific data for an included parcel from a JSON file.
 */
void
CFCParcel_read_host_data_json(CFCParcel *self, const char *host_lang);

void
CFCParcel_add_struct_sym(CFCParcel *self, const char *struct_sym);

/** Search the parcel and all direct prerequisites for a class with
 * struct_sym. Return the parcel in which the class was found or NULL.
 */
CFCParcel*
CFCParcel_lookup_struct_sym(CFCParcel *self, const char *struct_sym);

/** Indicate whether the parcel is "clownfish", the main Clownfish runtime.
 */
int
CFCParcel_is_cfish(CFCParcel *self);

/**************************************************************************/

CFCPrereq*
CFCPrereq_new(const char *name, struct CFCVersion *version);

CFCPrereq*
CFCPrereq_init(CFCPrereq *self, const char *name, struct CFCVersion *version);

void
CFCPrereq_destroy(CFCPrereq *self);

const char*
CFCPrereq_get_name(CFCPrereq *self);

struct CFCVersion*
CFCPrereq_get_version(CFCPrereq *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCPARCEL */

