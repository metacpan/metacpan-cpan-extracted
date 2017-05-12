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


#ifndef H_CFCGOFUNC
#define H_CFCGOFUNC

#ifdef __cplusplus
extern "C" {
#endif

struct CFCFunction;
struct CFCParcel;
struct CFCType;
struct CFCClass;
struct CFCParamList;

char*
CFCGoFunc_go_meth_name(const char *orig, int is_public);

char*
CFCGoFunc_meth_start(struct CFCParcel *parcel, const char *name,
                     struct CFCClass *invoker,
                     struct CFCParamList *param_list,
                     struct CFCType *return_type);

char*
CFCGoFunc_ctor_start(struct CFCParcel *parcel, const char *name,
                     struct CFCParamList *param_list,
                     struct CFCType *return_type);

/** Convert Go method arguments to comma-separated Clownfish-flavored C
 * arguments, to be passed to a Clownfish method.
 */
char*
CFCGoFunc_meth_cfargs(struct CFCParcel *parcel, struct CFCClass *invoker,
                      struct CFCParamList *param_list);

/** Convert Go method arguments to comma-separated Clownfish-flavored C
 * arguments, to be passed to a Clownfish `new` function.
 */
char*
CFCGoFunc_ctor_cfargs(struct CFCParcel *parcel,
                      struct CFCParamList *param_list);

/** Generate a Go return statement which maps from a CGO Clownfish type to a
 * Go type.
 *
 * @param parcel The parcel in which the code is being generated.
 * @param type The type of return value, which must be convertible.
 * @param cf_retval A Go expression representing the return value of a
 * Clownfish subroutine.
 */
char*
CFCGoFunc_return_statement(struct CFCParcel *parcel,
                           struct CFCType *return_type,
                           const char *cf_retval);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCGOFUNC */

