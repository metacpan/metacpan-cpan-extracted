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

/** Clownfish::CFC::Binding::Core::Specs - Generate C code for class
 * initialization.
 */

#ifndef H_CFCBINDSPECS
#define H_CFCBINDSPECS

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCBindSpecs CFCBindSpecs;

struct CFCClass;

CFCBindSpecs*
CFCBindSpecs_new(void);

CFCBindSpecs*
CFCBindSpecs_init(CFCBindSpecs *specs);

void
CFCBindSpecs_destroy(CFCBindSpecs *specs);

const char*
CFCBindSpecs_get_typedefs(void);

void
CFCBindSpecs_add_class(CFCBindSpecs *specs, struct CFCClass *klass);

char*
CFCBindSpecs_defs(CFCBindSpecs *self);

char*
CFCBindSpecs_init_func_def(CFCBindSpecs *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCBINDSPECS */

