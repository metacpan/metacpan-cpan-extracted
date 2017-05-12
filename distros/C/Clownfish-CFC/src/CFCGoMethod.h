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

#ifndef H_CFCGOMETHOD
#define H_CFCGOMETHOD

#ifdef __cplusplus
extern "C" {
#endif

/** Clownfish::CFC::Binding::Go::Method - Binding for a method.
 */

typedef struct CFCGoMethod CFCGoMethod;
struct CFCMethod;
struct CFCClass;

CFCGoMethod*
CFCGoMethod_new(struct CFCMethod *method);

struct CFCMethod*
CFCGoMethod_get_client(CFCGoMethod *self);

/** Customize the a Go method binding.  Supply a method signature to be
 * inserted into the Go interface and suppress the default method
 * implementation.
 */
void
CFCGoMethod_customize(CFCGoMethod *self, const char *sig);

/** Retrieve the Go interface method signature.
 */
const char*
CFCGoMethod_get_sig(CFCGoMethod *self, struct CFCClass *invoker);

char*
CFCGoMethod_func_def(CFCGoMethod *self, struct CFCClass *invoker);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCGOMETHOD */

