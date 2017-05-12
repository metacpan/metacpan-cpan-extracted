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

/** Clownfish::CFC::Model::Document - A standalone documentatio file.
 */

#ifndef H_CFCDOCUMENT
#define H_CFCDOCUMENT

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCDocument CFCDocument;

CFCDocument*
CFCDocument_create(const char *path, const char *path_part);

CFCDocument*
CFCDocument_do_create(CFCDocument *self, const char *path,
                      const char *path_part);

void
CFCDocument_destroy(CFCDocument *self);

CFCDocument**
CFCDocument_get_registry(void);

CFCDocument*
CFCDocument_fetch(const char *name);

void
CFCDocument_clear_registry(void);

char*
CFCDocument_get_contents(CFCDocument *self);

const char*
CFCDocument_get_path(CFCDocument *self);

const char*
CFCDocument_get_path_part(CFCDocument *self);

const char*
CFCDocument_get_name(CFCDocument *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCDOCUMENT */

