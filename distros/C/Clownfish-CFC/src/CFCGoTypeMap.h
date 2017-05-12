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

#ifndef H_CFCGOTYPEMAP
#define H_CFCGOTYPEMAP

#ifdef __cplusplus
extern "C" {
#endif

struct CFCType;
struct CFCParcel;
struct CFCParamList;

char*
CFCGoTypeMap_go_type_name(struct CFCType *type,
                          struct CFCParcel *current_parcel);

/** Return the Go package name associated with a Clownfish parcel.
 */
char*
CFCGoTypeMap_go_short_package(struct CFCParcel *parcel);

/** Convert param names to lowerCamelCase, storing the result in `buf`.
 */
void
CFCGoTypeMap_go_arg_name(struct CFCParamList *param_list, size_t tick,
                         char *buf, size_t buf_len);

/** For the name of the method receiver, default to lower case letter derived
 * from type, e.g. `f` for `Foo`.
 *
 * `param_list` may be NULL.  If it is not, check to see whether the
 * single-letter name is already taken by another parameter.  In the event of
 * a clash, use the result of `CFCGoTypeMap_go_arg_name` instead.
 */
void
CFCGoTypeMap_go_meth_receiever(const char *struct_name,
                               struct CFCParamList *param_list,
                               char *buf, size_t buf_len);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCGOTYPEMAP */

