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

#ifndef H_CFCPYTYPEMAP
#define H_CFCPYTYPEMAP

#ifdef __cplusplus
extern "C" {
#endif

struct CFCType;
struct CFCParcel;

/** Return an expression converts from a variable of type `type` to a
 * PyObject*.
 * 
 * @param type A Clownfish::CFC::Model::Type, which will be used to select the
 * mapping code.
 * @param cf_var The name of the variable from which we are extracting a
 * value.
 */ 
char*
CFCPyTypeMap_c_to_py(struct CFCType *type, const char *cf_var);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCPYTYPEMAP */

