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

#ifndef H_CLOWNFISH_LOCKFREEREGISTRY
#define H_CLOWNFISH_LOCKFREEREGISTRY 1

#include <stddef.h>

#include "cfish_parcel.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Specialized lock free hash table for storing Classes.
 */

struct cfish_Obj;
struct cfish_String;

typedef struct cfish_LockFreeRegistry cfish_LockFreeRegistry;

CFISH_VISIBLE cfish_LockFreeRegistry*
cfish_LFReg_new(size_t capacity);

CFISH_VISIBLE void
cfish_LFReg_destroy(cfish_LockFreeRegistry *self);

CFISH_VISIBLE bool
cfish_LFReg_register(cfish_LockFreeRegistry *self, struct cfish_String *key,
                     struct cfish_Obj *value);

CFISH_VISIBLE struct cfish_Obj*
cfish_LFReg_fetch(cfish_LockFreeRegistry *self, struct cfish_String *key);

#ifdef CFISH_USE_SHORT_NAMES
  #define LockFreeRegistry cfish_LockFreeRegistry
  #define LFReg_new        cfish_LFReg_new
  #define LFReg_destroy    cfish_LFReg_destroy
  #define LFReg_register   cfish_LFReg_register
  #define LFReg_fetch      cfish_LFReg_fetch
#endif

#ifdef __cplusplus
}
#endif

#endif /* H_CLOWNFISH_LOCKFREEREGISTRY */

