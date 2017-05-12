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

/** Clownfish::CFC::Model::Function - Metadata describing a function.
 */

#ifndef H_CFCFUNCTION
#define H_CFCFUNCTION

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCFunction CFCFunction;
struct CFCType;
struct CFCDocuComment;
struct CFCParamList;
struct CFCClass;

/**
 * @param exposure The function's exposure (see
 * L<Clownfish::CFC::Model::Symbol>).
 * @param name The name of the function, without any namespacing prefixes.
 * @param return_type A Clownfish::CFC::Model::Type representing the
 * function's return type.
 * @param param_list A Clownfish::CFC::Model::ParamList representing the
 * function's argument list.
 * @param docucomment A Clownfish::CFC::Model::DocuComment describing the
 * function.
 * @param is_inline Should be true if the function should be inlined by the
 * compiler.
 */
CFCFunction*
CFCFunction_new(const char *exposure, const char *name,
                struct CFCType *return_type, struct CFCParamList *param_list,
                struct CFCDocuComment *docucomment, int is_inline);

CFCFunction*
CFCFunction_init(CFCFunction *self, const char *exposure, const char *name,
                 struct CFCType *return_type, struct CFCParamList *param_list,
                 struct CFCDocuComment *docucomment, int is_inline);

void
CFCFunction_destroy(CFCFunction *self);

/** Test whether bindings can be generated for a function.
  */
int
CFCFunction_can_be_bound(CFCFunction *function);

struct CFCType*
CFCFunction_get_return_type(CFCFunction *self);

struct CFCParamList*
CFCFunction_get_param_list(CFCFunction *self);

struct CFCDocuComment*
CFCFunction_get_docucomment(CFCFunction *self);

int
CFCFunction_inline(CFCFunction *self);

/** Returns true if the function has a void return type, false otherwise.
 */
int
CFCFunction_void(CFCFunction *self);

/** A synonym for full_sym().
 */
char*
CFCFunction_full_func_sym(CFCFunction *self, struct CFCClass *klass);

/** A synonym for short_sym().
 */
char*
CFCFunction_short_func_sym(CFCFunction *self, struct CFCClass *klass);

const char*
CFCFunction_get_name(CFCFunction *self);

int
CFCFunction_public(CFCFunction *self);

/** Find the actual class of all object variables without prefix.
 */
void
CFCFunction_resolve_types(CFCFunction *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCFUNCTION */

