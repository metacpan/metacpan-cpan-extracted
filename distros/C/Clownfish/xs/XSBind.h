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

/* XSBind.h -- Functions to help bind Clownfish to Perl XS api.
 */

#ifndef H_CFISH_XSBIND
#define H_CFISH_XSBIND 1

#include "Clownfish/Obj.h"
#include "Clownfish/Blob.h"
#include "Clownfish/ByteBuf.h"
#include "Clownfish/String.h"
#include "Clownfish/Err.h"
#include "Clownfish/Hash.h"
#include "Clownfish/Num.h"
#include "Clownfish/Vector.h"
#include "Clownfish/Class.h"

/* Avoid conflicts with Clownfish bool type. */
#define HAS_BOOL
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cfish_XSBind_ClassSpec {
    const char *name;
    const char *parent_name;
    uint32_t    num_methods;
} cfish_XSBind_ClassSpec;

typedef struct cfish_XSBind_XSubSpec {
    const char *alias;
    XSUBADDR_t  xsub;
} cfish_XSBind_XSubSpec;

typedef struct cfish_XSBind_ParamSpec {
    const char *label;
    uint16_t    label_len;
    char        required;
} cfish_XSBind_ParamSpec;

/** Given either a class name or a perl object, manufacture a new Clownfish
 * object suitable for supplying to a cfish_Foo_init() function.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_new_blank_obj(pTHX_ SV *either_sv);

/** Create a new object to go with the supplied host object.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_foster_obj(pTHX_ SV *sv, cfish_Class *klass);

/** Test whether an SV is defined.  Handles "get" magic, unlike SvOK on its
 * own.
 */
CFISH_VISIBLE bool
cfish_XSBind_sv_defined(pTHX_ SV *sv);

/** Test whether an SV is true.  Wraps the expensive SvTRUE macro in a
 * function.
 */
CFISH_VISIBLE bool
cfish_XSBind_sv_true(pTHX_ SV *sv);

/** Derive an SV from a Clownfish object.  If the Clownfish object is NULL,
 * the SV will be undef.  Doesn't invoke To_Host and always returns a
 * reference to a Clownfish::Obj.
 *
 * The new SV has single refcount for which the caller must take
 * responsibility.
 */
CFISH_VISIBLE SV*
cfish_XSBind_cfish_obj_to_sv_inc(pTHX_ cfish_Obj *obj);

/** XSBind_cfish_obj_to_sv_inc, with a cast.
 */
#define CFISH_OBJ_TO_SV_INC(_obj) \
    cfish_XSBind_cfish_obj_to_sv_inc(aTHX_ (cfish_Obj*)_obj)

/** As XSBind_cfish_obj_to_sv_inc above, except decrements the object's
 * refcount after creating the SV. This is useful when the Clownfish
 * expression creates a new refcount, e.g.  a call to a constructor.
 */
CFISH_VISIBLE SV*
cfish_XSBind_cfish_obj_to_sv_noinc(pTHX_ cfish_Obj *obj);

/** XSBind_cfish_obj_to_sv_noinc, with a cast.
 */
#define CFISH_OBJ_TO_SV_NOINC(_obj) \
    cfish_XSBind_cfish_obj_to_sv_noinc(aTHX_ (cfish_Obj*)_obj)

/** Null-safe invocation of Obj_To_Host.
 */
static CFISH_INLINE SV*
cfish_XSBind_cfish_to_perl(pTHX_ cfish_Obj *obj) {
    return obj ? (SV*)CFISH_Obj_To_Host(obj, NULL) : newSV(0);
}

/** Convert a Perl SV to a Clownfish object of class `klass`.
 *
 * - If the SV contains a Clownfish object which passes an "isa" test against
 *   `klass`, return a pointer to it.
 * - If the SV contains an arrayref and `klass` is VECTOR or OBJ, perform a
 *   deep conversion of the Perl array to a Vector.
 * - If the SV contains a hashref and `klass` is HASH or OBJ, perform a
 *   deep conversion of the Perl hash to a Hash.
 * - If `klass` is STRING or OBJ, stringify and return a String.
 * - If all else fails, throw an exception.
 *
 * Returns an non-NULL, "incremented" object that must be decref'd at some
 * point.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_perl_to_cfish(pTHX_ SV *sv, cfish_Class *klass);

/** As XSBind_perl_to_cfish above, but returns NULL if the SV is undefined
 * or a reference to an undef.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_perl_to_cfish_nullable(pTHX_ SV *sv, cfish_Class *klass);

/** As XSBind_perl_to_cfish above, but returns an object that can be used for
 * a while with no need to decref.
 *
 * If `klass` is STRING or OBJ, `allocation` must point to stack-allocated
 * memory that can hold a String. Otherwise, `allocation` should be NULL.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_perl_to_cfish_noinc(pTHX_ SV *sv, cfish_Class *klass,
                                 void *allocation);

/** Return the contents of the hash entry's key as UTF-8.
 */
CFISH_VISIBLE const char*
cfish_XSBind_hash_key_to_utf8(pTHX_ HE *entry, STRLEN *size_ptr);

/** Perl-specific wrapper for Err#trap.  The "routine" must be either a
 * subroutine reference or the name of a subroutine.
 */
cfish_Err*
cfish_XSBind_trap(SV *routine, SV *context);

/** Locate hash-style params passed to an XS subroutine.  If a required
 * parameter is not present, locate_args() will throw an error.
 *
 * All possible valid param names must be passed in `specs`; if a
 * user-supplied param cannot be matched up, locate_args() will throw an
 * error.
 *
 * @param stack The Perl stack.
 * @param start Where on the Perl stack to start looking for params.  For
 * methods, this would typically be 1; for functions, most likely 0.
 * @param items The number of arguments passed to the Perl function
 * (generally, the XS variable `items`).
 * @params specs An array of XSBind_ParamSpec structs describing the
 * parameters.
 * @param locations On success, this output argument will be set to the
 * location on the stack of each param. Optional arguments that could not
 * be found have their location set to `items`.
 * @param The number of parameters in `specs` and elements in `locations`.
 */
CFISH_VISIBLE void
cfish_XSBind_locate_args(pTHX_ SV** stack, int32_t start, int32_t items,
                         const cfish_XSBind_ParamSpec *specs,
                         int32_t *locations, int32_t num_params);

/** Convert an argument from the Perl stack to a Clownfish object. Throws
 * an error if the SV can't be converted.
 *
 * @param value The SV from the Perl stack.
 * @param label The name of the param.
 * @param klass The class to convert to.
 * @param allocation Stack allocation for Obj and String.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_arg_to_cfish(pTHX_ SV *value, const char *label,
                          cfish_Class *klass, void *allocation);

/** Like XSBind_arg_to_cfish, but allows undef which is converted to NULL.
 */
CFISH_VISIBLE cfish_Obj*
cfish_XSBind_arg_to_cfish_nullable(pTHX_ SV *value, const char *label,
                                   cfish_Class *klass, void *allocation);

/** Throw an error because of invalid number of arguments.
 */
CFISH_VISIBLE void
cfish_XSBind_invalid_args_error(pTHX_ CV *cv, const char *param_list);

/** Throw an error because of an undefined argument.
 */
CFISH_VISIBLE void
cfish_XSBind_undef_arg_error(pTHX_ const char *label);

/** Initialize ISA relations and XSUBs.
 */
CFISH_VISIBLE void
cfish_XSBind_bootstrap(pTHX_ size_t num_classes,
                       const cfish_XSBind_ClassSpec *class_specs,
                       const cfish_XSBind_XSubSpec *xsub_specs,
                       const char *file);

#define XSBIND_PARAM(key, required) \
    { key, (int16_t)sizeof("" key) - 1, (char)required }

/* Define short names for most of the symbols in this file.  Note that these
 * short names are ALWAYS in effect, since they are only used for Perl and we
 * can be confident they don't conflict with anything.  (It's prudent to use
 * full symbols nevertheless in case someone else defines e.g. a function
 * named "XSBind_sv_defined".)
 */
#define XSBind_ClassSpec               cfish_XSBind_ClassSpec
#define XSBind_XSubSpec                cfish_XSBind_XSubSpec
#define XSBind_ParamSpec               cfish_XSBind_ParamSpec
#define XSBind_new_blank_obj           cfish_XSBind_new_blank_obj
#define XSBind_foster_obj              cfish_XSBind_foster_obj
#define XSBind_sv_defined              cfish_XSBind_sv_defined
#define XSBind_sv_true                 cfish_XSBind_sv_true
#define XSBind_cfish_obj_to_sv_inc     cfish_XSBind_cfish_obj_to_sv_inc
#define XSBind_cfish_obj_to_sv_noinc   cfish_XSBind_cfish_obj_to_sv_noinc
#define XSBind_cfish_to_perl           cfish_XSBind_cfish_to_perl
#define XSBind_perl_to_cfish           cfish_XSBind_perl_to_cfish
#define XSBind_perl_to_cfish_nullable  cfish_XSBind_perl_to_cfish_nullable
#define XSBind_perl_to_cfish_noinc     cfish_XSBind_perl_to_cfish_noinc
#define XSBind_hash_key_to_utf8        cfish_XSBind_hash_key_to_utf8
#define XSBind_trap                    cfish_XSBind_trap
#define XSBind_locate_args             cfish_XSBind_locate_args
#define XSBind_arg_to_cfish            cfish_XSBind_arg_to_cfish
#define XSBind_arg_to_cfish_nullable   cfish_XSBind_arg_to_cfish_nullable
#define XSBind_invalid_args_error      cfish_XSBind_invalid_args_error
#define XSBind_undef_arg_error         cfish_XSBind_undef_arg_error
#define XSBind_bootstrap               cfish_XSBind_bootstrap

/* Strip the prefix from some common ClownFish symbols where we know there's
 * no conflict with Perl.  It's a little inconsistent to do this rather than
 * leave all symbols at full size, but the succinctness is worth it.
 */
#define THROW            CFISH_THROW
#define WARN             CFISH_WARN

#ifdef __cplusplus
}
#endif

#endif // H_CFISH_XSBIND


