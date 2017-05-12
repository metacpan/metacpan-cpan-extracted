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

#ifndef H_CFCGOCLASS
#define H_CFCGOCLASS

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCGoClass CFCGoClass;
struct CFCParcel;
struct CFCClass;

/** Clownfish::CFC::Binding::Go::Class - Generate Go binding code for a
 * Clownfish::CFC::Model::Class.
 */

/**
 * @param parcel A CFCParcel.
 * @param class_name The name of the class to be registered.
 */
CFCGoClass*
CFCGoClass_new(struct CFCParcel *parcel, const char *class_name);

/** Add a new class binding to the registry.  Each unique parcel/class-name
 * combination may only be registered once.
 */
void
CFCGoClass_register(CFCGoClass *self);

/** Given a class name, return a class binding if one exists.
 */
CFCGoClass*
CFCGoClass_singleton(const char *class_name);

/** All registered class bindings.
 */
CFCGoClass**
CFCGoClass_registry(void);

/** Release all memory and references held by the registry.
 */
void
CFCGoClass_clear_registry(void);

struct CFCClass*
CFCGoClass_get_client(CFCGoClass *self);

/** Return any Go type statements describing the Clownfish class.
 */
char*
CFCGoClass_go_typing(CFCGoClass *self);

/** Return boilerplate Go code needed for each Clownfish class.
 */
char*
CFCGoClass_boilerplate_funcs(CFCGoClass *self);

char*
CFCGoClass_gen_ctors(CFCGoClass *self);

char*
CFCGoClass_gen_meth_glue(CFCGoClass *self);

char*
CFCGoClass_gen_wrap_func_reg(CFCGoClass *self);

void
CFCGoClass_spec_method(CFCGoClass *self, const char *name, const char *sig);

void
CFCGoClass_set_suppress_struct(CFCGoClass *self, int suppress_struct);

void
CFCGoClass_set_suppress_ctor(CFCGoClass *self, int suppress_ctor);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCGOCLASS */

