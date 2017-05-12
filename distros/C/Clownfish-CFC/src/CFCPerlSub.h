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

#ifndef H_CFCPERLSUB
#define H_CFCPERLSUB

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCPerlSub CFCPerlSub;
struct CFCFunction;
struct CFCParamList;
struct CFCType;
struct CFCVariable;

#ifdef CFC_NEED_PERLSUB_STRUCT_DEF
#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
struct CFCPerlSub {
    CFCBase base;
    struct CFCParamList *param_list;
    char *class_name;
    char *alias;
    int use_labeled_params;
    char *perl_name;
    char *c_name;
};
#endif

/** Clownfish::CFC::Binding::Perl::Subroutine - Abstract base binding for a
 * Clownfish::CFC::Model::Function.
 * 
 * This class is used to generate binding code for invoking Clownfish's
 * functions and methods across the Perl/C barrier.
 */ 

/** Abstract constructor.
 * 
 * @param param_list A Clownfish::CFC::Model::ParamList.
 * @param class_name The name of the Perl class that the subroutine belongs
 * to.
 * @param alias The local, unqualified name for the Perl subroutine that
 * will be used to invoke the function.
 * @param use_labeled_params True if the binding should take hash-style
 * labeled parameters, false if it should take positional arguments.
 */
CFCPerlSub*
CFCPerlSub_init(CFCPerlSub *self, struct CFCParamList *param_list,
                const char *class_name, const char *alias,
                int use_labeled_params);

void
CFCPerlSub_destroy(CFCPerlSub *self);

/** Generate C declarations for the variables holding the arguments, from
 * `first` onwards.
 */
char*
CFCPerlSub_arg_declarations(CFCPerlSub *self, int first);

/** Create a comma-separated list of argument names prefixed by "arg_".
 */
char*
CFCPerlSub_arg_name_list(CFCPerlSub *self);

/** Generate code that initializes a static array of XSBind_ParamSpecs.
 * Parameters from `first` onwards are included.
 */
char*
CFCPerlSub_build_param_specs(CFCPerlSub *self, int first);

/** Generate code that that converts and assigns the arguments.
 */
char*
CFCPerlSub_arg_assignments(CFCPerlSub *self);

/** Accessor for param list.
 */
struct CFCParamList*
CFCPerlSub_get_param_list(CFCPerlSub *self);

/** Accessor for class name.
 */
const char*
CFCPerlSub_get_class_name(CFCPerlSub *self);

/** Accessor for alias.
 */
const char*
CFCPerlSub_get_alias(CFCPerlSub *self);

/** Accessor for use_labeled_params.
 */
int
CFCPerlSub_use_labeled_params(CFCPerlSub *self);

/**
 * @return the fully-qualified perl subroutine name.
 */
const char*
CFCPerlSub_perl_name(CFCPerlSub *self);

/**
 * @return the fully-qualified name of the C function that implements the
 * XSUB.
 */
const char*
CFCPerlSub_c_name(CFCPerlSub *self);

/**
 * @return a string containing the names of arguments to feed to bound C
 * function, joined by commas.
 */
const char*
CFCPerlSub_c_name_list(CFCPerlSub *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCPERLSUB */

