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

#ifndef H_CFCJSON
#define H_CFCJSON

#ifdef __cplusplus
extern "C" {
#endif

#define CFCJSON_STRING 1
#define CFCJSON_HASH   2
#define CFCJSON_NULL   3
#define CFCJSON_BOOL   4

typedef struct CFCJson CFCJson;

CFCJson*
CFCJson_parse(const char *json);

void
CFCJson_destroy(CFCJson *self);

int
CFCJson_get_type(CFCJson *self);

const char*
CFCJson_get_string(CFCJson *self);

int
CFCJson_get_bool(CFCJson *self);

size_t
CFCJson_get_num_children(CFCJson *self);

CFCJson**
CFCJson_get_children(CFCJson *self);

CFCJson*
CFCJson_find_hash_elem(CFCJson *self, const char *key);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCJSON */

