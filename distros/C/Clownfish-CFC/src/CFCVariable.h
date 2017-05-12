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

#ifndef H_CFCVARIABLE
#define H_CFCVARIABLE

/** Clownfish::CFC::Model::Variable - A Clownfish variable.
 *
 * A variable, having a L<Type|Clownfish::CFC::Model::Type>, a name,
 * an exposure, and optionally, a location in the global namespace
 * hierarchy.
 *
 * Variable objects which exist only within a local scope, e.g. those within
 * parameter lists, do not need to know about class.  In contrast, inert class
 * vars, for example, need to know class information so that they can declare
 * themselves properly.
 */

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCVariable CFCVariable;
struct CFCClass;
struct CFCParcel;
struct CFCType;

/**
 * @param exposure See Clownfish::CFC::Model::Symbol.
 * @param name The variable's name, without any namespacing prefixes.
 * @param type A Clownfish::CFC::Model::Type.
 */
CFCVariable*
CFCVariable_new(const char *exposure, const char *name, struct CFCType *type,
                int inert);

CFCVariable*
CFCVariable_init(CFCVariable *self, const char *exposure, const char *name,
                 struct CFCType *type, int inert);

void
CFCVariable_resolve_type(CFCVariable *self);

void
CFCVariable_destroy(CFCVariable *self);

int
CFCVariable_equals(CFCVariable *self, CFCVariable *other);

struct CFCType*
CFCVariable_get_type(CFCVariable *self);

int
CFCVariable_inert(CFCVariable *self);


/** Returns a string with the Variable's C type and its
 * `name`. For instance:
 *
 *     int32_t average_lifespan
 */
const char*
CFCVariable_local_c(CFCVariable *self);

/** Returns a string with the Variable's C type and its fully qualified name
 * within the global namespace.  For example:
 *
 *     int32_t crust_Lobster_average_lifespan
 */
char*
CFCVariable_global_c(CFCVariable *self, struct CFCClass *klass);

/** Returns C code appropriate for declaring the variable in a local scope,
 * such as within a struct definition, or as an automatic variable within a C
 * function.  For example:
 *
 *     int32_t average_lifespan;
 */
const char*
CFCVariable_local_declaration(CFCVariable *self);

const char*
CFCVariable_get_name(CFCVariable *self);

char*
CFCVariable_short_sym(CFCVariable *self, struct CFCClass *klass);

char*
CFCVariable_full_sym(CFCVariable *self, struct CFCClass *klass);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCVARIABLE */

