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

#ifndef H_CLOWNFISH_PTRHASH
#define H_CLOWNFISH_PTRHASH 1

#include <stddef.h>

#include "cfish_parcel.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cfish_PtrHash cfish_PtrHash;

CFISH_VISIBLE cfish_PtrHash*
cfish_PtrHash_new(size_t min_cap);

CFISH_VISIBLE void
CFISH_PtrHash_Destroy(cfish_PtrHash *self);

CFISH_VISIBLE void
CFISH_PtrHash_Store(cfish_PtrHash *self, void *key, void *value);

CFISH_VISIBLE void*
CFISH_PtrHash_Fetch(cfish_PtrHash *self, void *key);

#ifdef CFISH_USE_SHORT_NAMES
  #define PtrHash           cfish_PtrHash
  #define PtrHash_new       cfish_PtrHash_new
  #define PtrHash_Destroy   CFISH_PtrHash_Destroy
  #define PtrHash_Store     CFISH_PtrHash_Store
  #define PtrHash_Fetch     CFISH_PtrHash_Fetch
#endif

#ifdef __cplusplus
}
#endif

#endif /* H_CLOWNFISH_PTRHASH */

