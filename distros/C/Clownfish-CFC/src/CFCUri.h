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

#ifndef H_CFCURI
#define H_CFCURI

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    CFC_URI_NULL     = 1,
    CFC_URI_CLASS    = 2,
    CFC_URI_FUNCTION = 3,
    CFC_URI_METHOD   = 4,
    CFC_URI_DOCUMENT = 5,
    CFC_URI_ERROR    = 6
} CFCUriType;

typedef struct CFCUri CFCUri;
struct CFCClass;
struct CFCDocument;

int
CFCUri_is_clownfish_uri(const char *uri);

CFCUri*
CFCUri_new(const char *uri, struct CFCClass *klass);

CFCUri*
CFCUri_init(CFCUri *self, const char *uri, struct CFCClass *klass);

void
CFCUri_destroy(CFCUri *self);

const char*
CFCUri_get_string(CFCUri *self);

CFCUriType
CFCUri_get_type(CFCUri *self);

struct CFCClass*
CFCUri_get_class(CFCUri *self);

struct CFCDocument*
CFCUri_get_document(CFCUri *self);

const char*
CFCUri_get_callable_name(CFCUri *self);

const char*
CFCUri_get_error(CFCUri *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCURI */

