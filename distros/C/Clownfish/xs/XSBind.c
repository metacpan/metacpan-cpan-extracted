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

#include <string.h>

#define CFP_CFISH
#define C_CFISH_OBJ
#define C_CFISH_CLASS
#define C_CFISH_FLOAT
#define C_CFISH_INTEGER
#define C_CFISH_BOOLEAN
#define NEED_newRV_noinc
#include "charmony.h"
#include "XSBind.h"
#include "Clownfish/Boolean.h"
#include "Clownfish/CharBuf.h"
#include "Clownfish/HashIterator.h"
#include "Clownfish/Method.h"
#include "Clownfish/Num.h"
#include "Clownfish/PtrHash.h"
#include "Clownfish/TestHarness/TestUtils.h"
#include "Clownfish/Util/Atomic.h"
#include "Clownfish/Util/Memory.h"

#define XSBIND_REFCOUNT_FLAG   1
#define XSBIND_REFCOUNT_SHIFT  1

// Used to remember converted objects in array and hash conversion to
// handle circular references. The root object and SV are stored separately
// to allow lazy creation of the seen PtrHash.
typedef struct {
    cfish_Obj     *root_obj;
    SV            *root_sv;
    cfish_PtrHash *seen;
} cfish_ConversionCache;

static bool
S_maybe_perl_to_cfish(pTHX_ SV *sv, cfish_Class *klass, bool increment,
                      void *allocation, cfish_ConversionCache *cache,
                      cfish_Obj **obj_ptr);

// Convert a Perl hash into a Clownfish Hash.  Caller takes responsibility for
// a refcount.
static cfish_Hash*
S_perl_hash_to_cfish_hash(pTHX_ HV *phash, cfish_ConversionCache *cache);

// Convert a Perl array into a Clownfish Vector.  Caller takes responsibility
// for a refcount.
static cfish_Vector*
S_perl_array_to_cfish_array(pTHX_ AV *parray, cfish_ConversionCache *cache);

cfish_Obj*
XSBind_new_blank_obj(pTHX_ SV *either_sv) {
    cfish_Class *klass;

    // Get a Class.
    if (sv_isobject(either_sv)
        && sv_derived_from(either_sv, "Clownfish::Obj")
       ) {
        // Use the supplied object's Class.
        IV iv_ptr = SvIV(SvRV(either_sv));
        cfish_Obj *self = INT2PTR(cfish_Obj*, iv_ptr);
        klass = self->klass;
    }
    else {
        // Use the supplied class name string to find a Class.
        STRLEN len;
        char *ptr = SvPVutf8(either_sv, len);
        cfish_String *class_name = CFISH_SSTR_WRAP_UTF8(ptr, len);
        klass = cfish_Class_singleton(class_name, NULL);
    }

    // Use the Class to allocate a new blank object of the right size.
    return CFISH_Class_Make_Obj(klass);
}

cfish_Obj*
XSBind_foster_obj(pTHX_ SV *sv, cfish_Class *klass) {
    cfish_Obj *obj
        = (cfish_Obj*)cfish_Memory_wrapped_calloc(klass->obj_alloc_size, 1);
    SV *inner_obj = SvRV((SV*)sv);
    obj->klass = klass;
    sv_setiv(inner_obj, PTR2IV(obj));
    obj->ref.host_obj = inner_obj;
    return obj;
}

bool
XSBind_sv_defined(pTHX_ SV *sv) {
    if (!sv || !SvANY(sv)) { return false; }
    if (SvGMAGICAL(sv)) { mg_get(sv); }
    return !!SvOK(sv);
}

bool
XSBind_sv_true(pTHX_ SV *sv) {
    return !!SvTRUE(sv);
}

cfish_Obj*
XSBind_perl_to_cfish(pTHX_ SV *sv, cfish_Class *klass) {
    cfish_Obj *retval = NULL;
    if (!S_maybe_perl_to_cfish(aTHX_ sv, klass, true, NULL, NULL, &retval)) {
        THROW(CFISH_ERR, "Can't convert to %o", CFISH_Class_Get_Name(klass));
    }
    else if (!retval) {
        THROW(CFISH_ERR, "%o must not be undef", CFISH_Class_Get_Name(klass));
    }
    return retval;
}

cfish_Obj*
XSBind_perl_to_cfish_nullable(pTHX_ SV *sv, cfish_Class *klass) {
    cfish_Obj *retval = NULL;
    if (!S_maybe_perl_to_cfish(aTHX_ sv, klass, true, NULL, NULL, &retval)) {
        THROW(CFISH_ERR, "Can't convert to %o", CFISH_Class_Get_Name(klass));
    }
    return retval;
}

cfish_Obj*
XSBind_perl_to_cfish_noinc(pTHX_ SV *sv, cfish_Class *klass, void *allocation) {
    cfish_Obj *retval = NULL;
    if (!S_maybe_perl_to_cfish(aTHX_ sv, klass, false, allocation, NULL,
                               &retval)
       ) {
        THROW(CFISH_ERR, "Can't convert to %o", CFISH_Class_Get_Name(klass));
    }
    else if (!retval) {
        THROW(CFISH_ERR, "%o must not be undef", CFISH_Class_Get_Name(klass));
    }
    return retval;
}

static bool
S_maybe_perl_to_cfish(pTHX_ SV *sv, cfish_Class *klass, bool increment,
                      void *allocation, cfish_ConversionCache *cache,
                      cfish_Obj **obj_ptr) {
    if (sv_isobject(sv)) {
        cfish_String *class_name = CFISH_Class_Get_Name(klass);
        // Assume that the class name is always NULL-terminated. Somewhat
        // dangerous but should be safe.
        if (sv_derived_from(sv, CFISH_Str_Get_Ptr8(class_name))) {
            // Unwrap a real Clownfish object.
            IV tmp = SvIV(SvRV(sv));
            cfish_Obj *obj = INT2PTR(cfish_Obj*, tmp);
            if (increment) {
                obj = CFISH_INCREF(obj);
            }
            *obj_ptr = obj;
            return true;
        }
    }
    else if (SvROK(sv)) {
        cfish_Obj *obj = NULL;
        SV *inner = SvRV(sv);
        svtype inner_type = SvTYPE(inner);

        // Attempt to convert Perl hashes and arrays into their Clownfish
        // analogues.
        if (inner_type == SVt_PVAV) {
            if (klass == CFISH_VECTOR || klass == CFISH_OBJ) {
                obj = (cfish_Obj*)
                         S_perl_array_to_cfish_array(aTHX_ (AV*)inner, cache);
            }
        }
        else if (inner_type == SVt_PVHV) {
            if (klass == CFISH_HASH || klass == CFISH_OBJ) {
                obj = (cfish_Obj*)
                         S_perl_hash_to_cfish_hash(aTHX_ (HV*)inner, cache);
            }
        }
        else if (inner_type < SVt_PVAV && !SvOK(inner)) {
            // Reference to undef. After cloning a Perl interpeter,
            // most Clownfish objects look like this after they're
            // CLONE_SKIPped.
            *obj_ptr = NULL;
            return true;
        }

        if (obj) {
            if (!increment) {
                // Mortalize the converted object -- which is somewhat
                // dangerous, but is the only way to avoid requiring that the
                // caller take responsibility for a refcount.
                sv_2mortal(XSBind_cfish_obj_to_sv_noinc(aTHX_ obj));
            }

            *obj_ptr = obj;
            return true;
        }
    }
    else if (!XSBind_sv_defined(aTHX_ sv)) {
        *obj_ptr = NULL;
        return true;
    }

    // Stringify as last resort.
    if (klass == CFISH_STRING || klass == CFISH_OBJ) {
        STRLEN size;
        char *ptr = SvPVutf8(sv, size);

        if (increment) {
            *obj_ptr = (cfish_Obj*)cfish_Str_new_from_trusted_utf8(ptr, size);
            return true;
        }
        else {
            // Wrap the string from an ordinary Perl scalar inside a
            // stack String.
            if (!allocation) {
                CFISH_THROW(CFISH_ERR, "Allocation for stack string missing");
            }
            *obj_ptr = (cfish_Obj*)cfish_Str_init_stack_string(
                    allocation, ptr, size);
            return true;
        }
    }

    return false;
}

const char*
XSBind_hash_key_to_utf8(pTHX_ HE *entry, STRLEN *size_ptr) {
    const char *key_str = NULL;
    STRLEN key_len = HeKLEN(entry);

    if (key_len == (STRLEN)HEf_SVKEY) {
        // Key is stored as an SV.  Use its UTF-8 flag?  Not sure about
        // this.
        SV *key_sv = HeKEY_sv(entry);
        key_str = SvPVutf8(key_sv, key_len);
    }
    else {
        key_str = HeKEY(entry);

        if (!HeKUTF8(entry)) {
            for (STRLEN i = 0; i < key_len; i++) {
                if ((key_str[i] & 0x80) == 0x80) {
                    // Force key to UTF-8 if necessary.
                    SV *key_sv = HeSVKEY_force(entry);
                    key_str = SvPVutf8(key_sv, key_len);
                    break;
                }
            }
        }
    }

    *size_ptr = key_len;
    return key_str;
}

static cfish_Hash*
S_perl_hash_to_cfish_hash(pTHX_ HV *phash, cfish_ConversionCache *cache) {
    cfish_ConversionCache new_cache;

    if (cache) {
        // Lookup perl hash in conversion cache.
        if ((SV*)phash == cache->root_sv) {
            return (cfish_Hash*)CFISH_INCREF(cache->root_obj);
        }
        if (cache->seen) {
            void *cached_hash = CFISH_PtrHash_Fetch(cache->seen, phash);
            if (cached_hash) {
                return (cfish_Hash*)CFISH_INCREF(cached_hash);
            }
        }
    }

    uint32_t    num_keys = hv_iterinit(phash);
    cfish_Hash *retval   = cfish_Hash_new(num_keys);

    if (!cache) {
        // Set up conversion cache.
        cache = &new_cache;
        cache->root_obj = (cfish_Obj*)retval;
        cache->root_sv  = (SV*)phash;
        cache->seen     = NULL;
    }
    else {
        if (!cache->seen) {
            // Create PtrHash lazily.
            cache->seen = cfish_PtrHash_new(0);
        }
        CFISH_PtrHash_Store(cache->seen, phash, retval);
    }

    while (num_keys--) {
        HE         *entry    = hv_iternext(phash);
        STRLEN      key_len  = 0;
        const char *key_str  = XSBind_hash_key_to_utf8(aTHX_ entry, &key_len);
        SV         *value_sv = HeVAL(entry);

        // Recurse.
        cfish_Obj *value;
        bool success = S_maybe_perl_to_cfish(aTHX_ value_sv, CFISH_OBJ,
                                             true, NULL, cache, &value);
        if (!success) {
            THROW(CFISH_ERR, "Can't convert to Clownfish::Obj");
        }

        CFISH_Hash_Store_Utf8(retval, key_str, key_len, value);
    }

    if (cache == &new_cache && cache->seen) {
        CFISH_PtrHash_Destroy(cache->seen);
    }

    return retval;
}

static cfish_Vector*
S_perl_array_to_cfish_array(pTHX_ AV *parray, cfish_ConversionCache *cache) {
    cfish_ConversionCache new_cache;

    if (cache) {
        // Lookup perl array in conversion cache.
        if ((SV*)parray == cache->root_sv) {
            return (cfish_Vector*)CFISH_INCREF(cache->root_obj);
        }
        if (cache->seen) {
            void *cached_vector = CFISH_PtrHash_Fetch(cache->seen, parray);
            if (cached_vector) {
                return (cfish_Vector*)CFISH_INCREF(cached_vector);
            }
        }
    }

    const uint32_t  size   = av_len(parray) + 1;
    cfish_Vector   *retval = cfish_Vec_new(size);

    if (!cache) {
        // Set up conversion cache.
        cache = &new_cache;
        cache->root_obj = (cfish_Obj*)retval;
        cache->root_sv  = (SV*)parray;
        cache->seen     = NULL;
    }
    else {
        if (!cache->seen) {
            // Create PtrHash lazily.
            cache->seen = cfish_PtrHash_new(0);
        }
        CFISH_PtrHash_Store(cache->seen, parray, retval);
    }

    // Iterate over array elems.
    for (uint32_t i = 0; i < size; i++) {
        SV **elem_sv = av_fetch(parray, i, false);
        if (elem_sv) {
            cfish_Obj *elem;
            bool success = S_maybe_perl_to_cfish(aTHX_ *elem_sv, CFISH_OBJ,
                                                 true, NULL, cache, &elem);
            if (!success) {
                THROW(CFISH_ERR, "Can't convert to Clownfish::Obj");
            }
            if (elem) { CFISH_Vec_Store(retval, i, elem); }
        }
    }
    CFISH_Vec_Resize(retval, size); // needed if last elem is NULL

    if (cache == &new_cache && cache->seen) {
        CFISH_PtrHash_Destroy(cache->seen);
    }

    return retval;
}

struct trap_context {
    SV *routine;
    SV *context;
};

static void
S_attempt_perl_call(void *context) {
    struct trap_context *args = (struct trap_context*)context;
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVsv(args->context)));
    PUTBACK;
    call_sv(args->routine, G_DISCARD);
    FREETMPS;
    LEAVE;
}

cfish_Err*
XSBind_trap(SV *routine, SV *context) {
    struct trap_context args;
    args.routine = routine;
    args.context = context;
    return cfish_Err_trap(S_attempt_perl_call, &args);
}

void
cfish_XSBind_locate_args(pTHX_ SV** stack, int32_t start, int32_t items,
                         const XSBind_ParamSpec *specs, int32_t *locations,
                         int32_t num_params) {
    // Verify that our args come in pairs.
    if ((items - start) % 2 != 0) {
        THROW(CFISH_ERR,
              "Expecting hash-style params, got odd number of args");
        return;
    }

    int32_t num_consumed = 0;
    for (int32_t i = 0; i < num_params; i++) {
        const XSBind_ParamSpec *spec = &specs[i];

        // Iterate through the stack looking for labels which match this param
        // name.  If the label appears more than once, keep track of where it
        // appears *last*, as the last time a param appears overrides all
        // previous appearances.
        int32_t location = items;
        for (int32_t tick = start; tick < items; tick += 2) {
            SV *const key_sv = stack[tick];
            if (SvCUR(key_sv) == (STRLEN)spec->label_len) {
                if (memcmp(SvPVX(key_sv), spec->label, spec->label_len) == 0) {
                    location = tick + 1;
                    ++num_consumed;
                }
            }
        }

        // Didn't find this parameter. Throw an error if it was required.
        if (location == items && spec->required) {
            THROW(CFISH_ERR, "Missing required parameter: '%s'", spec->label);
            return;
        }

        // Store the location.
        locations[i] = location;
    }

    // Ensure that all parameter labels were valid.
    if (num_consumed != (items - start) / 2) {
        // Find invalid parameter.
        for (int32_t tick = start; tick < items; tick += 2) {
            SV *const key_sv = stack[tick];
            const char *key = SvPVX(key_sv);
            STRLEN key_len = SvCUR(key_sv);
            bool found = false;

            for (int32_t i = 0; i < num_params; ++i) {
                const XSBind_ParamSpec *spec = &specs[i];

                if (key_len == (STRLEN)spec->label_len
                    && memcmp(key, spec->label, key_len) == 0
                   ) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                const char *key_c = SvPV_nolen(key_sv);
                THROW(CFISH_ERR, "Invalid parameter: '%s'", key_c);
                return;
            }
        }
    }
}

cfish_Obj*
XSBind_arg_to_cfish(pTHX_ SV *value, const char *label, cfish_Class *klass,
                    void *allocation) {
    cfish_Obj *obj = NULL;

    if (!S_maybe_perl_to_cfish(aTHX_ value, klass, false, allocation, NULL,
                               &obj)
       ) {
        THROW(CFISH_ERR, "Invalid value for '%s' - not a %o", label,
              CFISH_Class_Get_Name(klass));
        CFISH_UNREACHABLE_RETURN(cfish_Obj*);
    }

    if (!obj) {
        XSBind_undef_arg_error(aTHX_ label);
    }

    return obj;
}

cfish_Obj*
XSBind_arg_to_cfish_nullable(pTHX_ SV *value, const char *label,
                             cfish_Class *klass, void *allocation) {
    cfish_Obj *obj = NULL;

    if (!S_maybe_perl_to_cfish(aTHX_ value, klass, false, allocation, NULL,
                               &obj)
       ) {
        THROW(CFISH_ERR, "Invalid value for '%s' - not a %o", label,
              CFISH_Class_Get_Name(klass));
        CFISH_UNREACHABLE_RETURN(cfish_Obj*);
    }

    return obj;
}

void
XSBind_invalid_args_error(pTHX_ CV *cv, const char *param_list) {
    THROW(CFISH_ERR, "Usage: %s(%s)", GvNAME(CvGV(cv)), param_list);
}

void
XSBind_undef_arg_error(pTHX_ const char *label) {
    THROW(CFISH_ERR, "'%s' must not be undef", label);
}

void
XSBind_bootstrap(pTHX_ size_t num_classes,
                 const XSBind_ClassSpec *class_specs,
                 const XSBind_XSubSpec *xsub_specs,
                 const char *file) {
    size_t xsub_idx = 0;

    for (size_t i = 0; i < num_classes; i++) {
        const XSBind_ClassSpec *class_spec = &class_specs[i];

        // Set up @ISA array.
        if (class_spec->parent_name) {
            cfish_String *isa_name
                = cfish_Str_newf("%s::ISA", class_spec->name);
            AV *isa = get_av(CFISH_Str_Get_Ptr8(isa_name), 1);
            av_push(isa, newSVpv(class_spec->parent_name, 0));
            CFISH_DECREF(isa_name);
        }

        // Register XSUBs.
        for (uint32_t j = 0; j < class_spec->num_methods; j++) {
            const XSBind_XSubSpec *xsub_spec = &xsub_specs[xsub_idx++];

            cfish_String *xsub_name
                = cfish_Str_newf("%s::%s", class_spec->name, xsub_spec->alias);
            newXS(CFISH_Str_Get_Ptr8(xsub_name), xsub_spec->xsub, file);
            CFISH_DECREF(xsub_name);
        }
    }
}

/***************************************************************************
 * The routines below are declared within the Clownfish core but left
 * unimplemented and must be defined for each host language.
 ***************************************************************************/

/**************************** Clownfish::Obj *******************************/

static CFISH_INLINE bool
SI_immortal(cfish_Class *klass) {
    if (klass == CFISH_CLASS
        || klass == CFISH_METHOD
        || klass == CFISH_BOOLEAN
       ){
        return true;
    }
    return false;
}

static CFISH_INLINE bool
SI_is_string_type(cfish_Class *klass) {
    if (klass == CFISH_STRING) {
        return true;
    }
    return false;
}

// Returns a blessed RV.
static SV*
S_lazy_init_host_obj(pTHX_ cfish_Obj *self, bool increment) {
    cfish_Class  *klass      = self->klass;
    cfish_String *class_name = CFISH_Class_Get_Name(klass);

    SV *outer_obj = newSV(0);
    sv_setref_pv(outer_obj, CFISH_Str_Get_Ptr8(class_name), self);
    SV *inner_obj = SvRV(outer_obj);

    /* Up till now we've been keeping track of the refcount in
     * self->ref.count.  We're replacing ref.count with ref.host_obj, which
     * will assume responsibility for maintaining the refcount. */
    cfish_ref_t old_ref = self->ref;
    size_t excess = old_ref.count >> XSBIND_REFCOUNT_SHIFT;
    if (!increment) { excess -= 1; }
    SvREFCNT(inner_obj) += excess;

    // Overwrite refcount with host object.
    if (SI_immortal(klass)) {
        SvSHARE(inner_obj);
        if (!cfish_Atomic_cas_ptr((void**)&self->ref, old_ref.host_obj,
                                  inner_obj)) {
            // Another thread beat us to it.  Now we have a Perl object to
            // defuse. "Unbless" the object first to make sure the
            // Clownfish destructor won't be called.
            HV *stash = SvSTASH(inner_obj);
            SvSTASH_set(inner_obj, NULL);
            SvREFCNT_dec((SV*)stash);
            SvOBJECT_off(inner_obj);
            SvREFCNT(inner_obj) -= excess;
#if (PERL_VERSION <= 16)
            PL_sv_objcount--;
#endif
            SvREFCNT_dec(outer_obj);

            return newRV_inc((SV*)self->ref.host_obj);
        }
    }
    else {
        self->ref.host_obj = inner_obj;
    }

    return outer_obj;
}

uint32_t
cfish_get_refcount(void *vself) {
    cfish_Obj *self = (cfish_Obj*)vself;
    cfish_ref_t ref = self->ref;
    return ref.count & XSBIND_REFCOUNT_FLAG
           ? ref.count >> XSBIND_REFCOUNT_SHIFT
           : SvREFCNT((SV*)ref.host_obj);
}

cfish_Obj*
cfish_inc_refcount(void *vself) {
    cfish_Obj *self = (cfish_Obj*)vself;

    // Handle special cases.
    cfish_Class *const klass = self->klass;
    if (klass->flags & CFISH_fREFCOUNTSPECIAL) {
        if (SI_is_string_type(klass)) {
            // Only copy-on-incref Strings get special-cased.  Ordinary
            // Strings fall through to the general case.
            if (CFISH_Str_Is_Copy_On_IncRef((cfish_String*)self)) {
                const char *utf8 = CFISH_Str_Get_Ptr8((cfish_String*)self);
                size_t size = CFISH_Str_Get_Size((cfish_String*)self);
                return (cfish_Obj*)cfish_Str_new_from_trusted_utf8(utf8, size);
            }
        }
        else if (SI_immortal(klass)) {
            return self;
        }
    }

    if (self->ref.count & XSBIND_REFCOUNT_FLAG) {
        if (self->ref.count == XSBIND_REFCOUNT_FLAG) {
            CFISH_THROW(CFISH_ERR, "Illegal refcount of 0");
        }
        self->ref.count += 1 << XSBIND_REFCOUNT_SHIFT;
    }
    else {
        SvREFCNT_inc_simple_void_NN((SV*)self->ref.host_obj);
    }
    return self;
}

uint32_t
cfish_dec_refcount(void *vself) {
    cfish_Obj *self = (cfish_Obj*)vself;

    cfish_Class *klass = self->klass;
    if (klass->flags & CFISH_fREFCOUNTSPECIAL) {
        if (SI_immortal(klass)) {
            return 1;
        }
    }

    uint32_t modified_refcount = I32_MAX;
    if (self->ref.count & XSBIND_REFCOUNT_FLAG) {
        if (self->ref.count == XSBIND_REFCOUNT_FLAG) {
            CFISH_THROW(CFISH_ERR, "Illegal refcount of 0");
        }
        if (self->ref.count
            == ((1 << XSBIND_REFCOUNT_SHIFT) | XSBIND_REFCOUNT_FLAG)) {
            modified_refcount = 0;
            CFISH_Obj_Destroy(self);
        }
        else {
            self->ref.count -= 1 << XSBIND_REFCOUNT_SHIFT;
            modified_refcount = self->ref.count >> XSBIND_REFCOUNT_SHIFT;
        }
    }
    else {
        dTHX;
        modified_refcount = SvREFCNT((SV*)self->ref.host_obj) - 1;
        // If the SV's refcount falls to 0, DESTROY will be invoked from
        // Perl-space.
        SvREFCNT_dec((SV*)self->ref.host_obj);
    }
    return modified_refcount;
}

SV*
XSBind_cfish_obj_to_sv_inc(pTHX_ cfish_Obj *obj) {
    if (obj == NULL) { return newSV(0); }

    SV *perl_obj;
    if (obj->ref.count & XSBIND_REFCOUNT_FLAG) {
        perl_obj = S_lazy_init_host_obj(aTHX_ obj, true);
    }
    else {
        perl_obj = newRV_inc((SV*)obj->ref.host_obj);
    }

    // Enable overloading for Perl 5.8.x
#if PERL_VERSION <= 8
    HV *stash = SvSTASH((SV*)obj->ref.host_obj);
    if (Gv_AMG(stash)) {
        SvAMAGIC_on(perl_obj);
    }
#endif

    return perl_obj;
}

SV*
XSBind_cfish_obj_to_sv_noinc(pTHX_ cfish_Obj *obj) {
    if (obj == NULL) { return newSV(0); }

    SV *perl_obj;
    if (obj->ref.count & XSBIND_REFCOUNT_FLAG) {
        perl_obj = S_lazy_init_host_obj(aTHX_ obj, false);
    }
    else {
        perl_obj = newRV_noinc((SV*)obj->ref.host_obj);
    }

    // Enable overloading for Perl 5.8.x
#if PERL_VERSION <= 8
    HV *stash = SvSTASH((SV*)obj->ref.host_obj);
    if (Gv_AMG(stash)) {
        SvAMAGIC_on(perl_obj);
    }
#endif

    return perl_obj;
}

void*
CFISH_Obj_To_Host_IMP(cfish_Obj *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    return XSBind_cfish_obj_to_sv_inc(aTHX_ self);
}

/*************************** Clownfish::Class ******************************/

cfish_Obj*
CFISH_Class_Make_Obj_IMP(cfish_Class *self) {
    cfish_Obj *obj
        = (cfish_Obj*)cfish_Memory_wrapped_calloc(self->obj_alloc_size, 1);
    obj->klass = self;
    obj->ref.count = (1 << XSBIND_REFCOUNT_SHIFT) | XSBIND_REFCOUNT_FLAG;
    return obj;
}

cfish_Obj*
CFISH_Class_Init_Obj_IMP(cfish_Class *self, void *allocation) {
    memset(allocation, 0, self->obj_alloc_size);
    cfish_Obj *obj = (cfish_Obj*)allocation;
    obj->klass = self;
    obj->ref.count = (1 << XSBIND_REFCOUNT_SHIFT) | XSBIND_REFCOUNT_FLAG;
    return obj;
}

void
cfish_Class_register_with_host(cfish_Class *singleton, cfish_Class *parent) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    EXTEND(SP, 2);
    PUSHMARK(SP);
    mPUSHs((SV*)CFISH_Class_To_Host(singleton, NULL));
    mPUSHs((SV*)CFISH_Class_To_Host(parent, NULL));
    PUTBACK;
    call_pv("Clownfish::Class::_register", G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
}

cfish_Vector*
cfish_Class_fresh_host_methods(cfish_String *class_name) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    EXTEND(SP, 1);
    PUSHMARK(SP);
    mPUSHs((SV*)CFISH_Str_To_Host(class_name, NULL));
    PUTBACK;
    call_pv("Clownfish::Class::_fresh_host_methods", G_SCALAR);
    SPAGAIN;
    cfish_Vector *methods
        = (cfish_Vector*)XSBind_perl_to_cfish(aTHX_ POPs, CFISH_VECTOR);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return methods;
}

cfish_String*
cfish_Class_find_parent_class(cfish_String *class_name) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    EXTEND(SP, 1);
    PUSHMARK(SP);
    mPUSHs((SV*)CFISH_Str_To_Host(class_name, NULL));
    PUTBACK;
    call_pv("Clownfish::Class::_find_parent_class", G_SCALAR);
    SPAGAIN;
    cfish_String *parent_class = (cfish_String*)
        XSBind_perl_to_cfish_nullable(aTHX_ POPs, CFISH_STRING);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return parent_class;
}

/*************************** Clownfish::Method ******************************/

cfish_String*
CFISH_Method_Host_Name_IMP(cfish_Method *self) {
    return cfish_Method_lower_snake_alias(self);
}

/***************************** Clownfish::Err *******************************/

// Anonymous XSUB helper for Err#trap().  It wraps the supplied C function
// so that it can be run inside a Perl eval block.
static SV *attempt_xsub = NULL;

XS(cfish_Err_attempt_via_xs) {
    dXSARGS;
    CFISH_UNUSED_VAR(cv);
    SP -= items;
    if (items != 2) {
        CFISH_THROW(CFISH_ERR, "Usage: $sub->(routine, context)");
    };
    IV routine_iv = SvIV(ST(0));
    IV context_iv = SvIV(ST(1));
    CFISH_Err_Attempt_t routine = INT2PTR(CFISH_Err_Attempt_t, routine_iv);
    void *context               = INT2PTR(void*, context_iv);
    routine(context);
    XSRETURN(0);
}

void
cfish_Err_init_class(void) {
    dTHX;
    char *file = (char*)__FILE__;
    SV *xsub = (SV*)newXS(NULL, cfish_Err_attempt_via_xs, file);
    if (!cfish_Atomic_cas_ptr((void**)&attempt_xsub, NULL, xsub)) {
        SvREFCNT_dec(xsub);
    }
}

cfish_Err*
cfish_Err_get_error() {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    call_pv("Clownfish::Err::get_error", G_SCALAR);
    SPAGAIN;
    cfish_Err *error
        = (cfish_Err*)XSBind_perl_to_cfish_nullable(aTHX_ POPs, CFISH_ERR);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return error;
}

void
cfish_Err_set_error(cfish_Err *error) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHmortal;
    if (error) {
        mPUSHs((SV*)CFISH_Err_To_Host(error, NULL));
    }
    else {
        PUSHmortal;
    }
    PUTBACK;
    call_pv("Clownfish::Err::set_error", G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
}

void
cfish_Err_do_throw(cfish_Err *err) {
    dTHX;
    dSP;
    SV *error_sv = (SV*)CFISH_Err_To_Host(err, NULL);
    CFISH_DECREF(err);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(error_sv));
    PUTBACK;
    call_pv("Clownfish::Err::do_throw", G_DISCARD);
    FREETMPS;
    LEAVE;
}

void
cfish_Err_throw_mess(cfish_Class *klass, cfish_String *message) {
    CFISH_UNUSED_VAR(klass);
    cfish_Err *err = cfish_Err_new(message);
    cfish_Err_do_throw(err);
}

void
cfish_Err_warn_mess(cfish_String *message) {
    dTHX;
    SV *error_sv = (SV*)CFISH_Str_To_Host(message, NULL);
    CFISH_DECREF(message);
    warn("%s", SvPV_nolen(error_sv));
    SvREFCNT_dec(error_sv);
}

cfish_Err*
cfish_Err_trap(CFISH_Err_Attempt_t routine, void *context) {
    dTHX;
    cfish_Err *error = NULL;
    SV *routine_sv = newSViv(PTR2IV(routine));
    SV *context_sv = newSViv(PTR2IV(context));
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(routine_sv));
    PUSHs(sv_2mortal(context_sv));
    PUTBACK;

    int count = call_sv(attempt_xsub, G_EVAL | G_DISCARD);
    if (count != 0) {
        cfish_String *mess
            = cfish_Str_newf("'attempt' returned too many values: %i32",
                             (int32_t)count);
        error = cfish_Err_new(mess);
    }
    else {
        SV *dollar_at = get_sv("@", FALSE);
        if (SvTRUE(dollar_at)) {
            if (sv_isobject(dollar_at)
                && sv_derived_from(dollar_at,"Clownfish::Err")
               ) {
                IV error_iv = SvIV(SvRV(dollar_at));
                error = INT2PTR(cfish_Err*, error_iv);
                CFISH_INCREF(error);
            }
            else {
                STRLEN len;
                char *ptr = SvPVutf8(dollar_at, len);
                cfish_String *mess = cfish_Str_new_from_trusted_utf8(ptr, len);
                error = cfish_Err_new(mess);
            }
        }
    }
    FREETMPS;
    LEAVE;

    return error;
}

/**************************** Clownfish::String *****************************/

void*
CFISH_Str_To_Host_IMP(cfish_String *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    SV *sv = newSVpvn(CFISH_Str_Get_Ptr8(self), CFISH_Str_Get_Size(self));
    SvUTF8_on(sv);
    return sv;
}

/***************************** Clownfish::Blob ******************************/

void*
CFISH_Blob_To_Host_IMP(cfish_Blob *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    return newSVpvn(CFISH_Blob_Get_Buf(self), CFISH_Blob_Get_Size(self));
}

/**************************** Clownfish::ByteBuf ****************************/

void*
CFISH_BB_To_Host_IMP(cfish_ByteBuf *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    return newSVpvn(CFISH_BB_Get_Buf(self), CFISH_BB_Get_Size(self));
}

/**************************** Clownfish::Vector *****************************/

void*
CFISH_Vec_To_Host_IMP(cfish_Vector *self, void *vcache) {
    dTHX;
    cfish_ConversionCache *cache = (cfish_ConversionCache*)vcache;
    cfish_ConversionCache  new_cache;

    if (cache) {
        // Lookup Vector in conversion cache.
        if ((cfish_Obj*)self == cache->root_obj) {
            return newRV_inc(cache->root_sv);
        }
        if (cache->seen) {
            void *cached_av = CFISH_PtrHash_Fetch(cache->seen, self);
            if (cached_av) {
                return newRV_inc((SV*)cached_av);
            }
        }
    }

    AV *perl_array = newAV();

    if (!cache) {
        // Set up conversion cache.
        cache = &new_cache;
        cache->root_obj = (cfish_Obj*)self;
        cache->root_sv  = (SV*)perl_array;
        cache->seen     = NULL;
    }
    else {
        if (!cache->seen) {
            // Create PtrHash lazily.
            cache->seen = cfish_PtrHash_new(0);
        }
        CFISH_PtrHash_Store(cache->seen, self, perl_array);
    }

    size_t num_elems = CFISH_Vec_Get_Size(self);

    // Iterate over array elems.
    if (num_elems) {
        if (num_elems > I32_MAX) {
            THROW(CFISH_ERR, "Vector too large for Perl AV");
        }
        av_fill(perl_array, num_elems - 1);
        for (size_t i = 0; i < num_elems; i++) {
            cfish_Obj *val = CFISH_Vec_Fetch(self, i);
            if (val == NULL) {
                continue;
            }
            else {
                // Recurse for each value.
                SV *const val_sv = (SV*)CFISH_Obj_To_Host(val, cache);
                av_store(perl_array, i, val_sv);
            }
        }
    }

    if (cache == &new_cache && cache->seen) {
        CFISH_PtrHash_Destroy(cache->seen);
    }

    return newRV_noinc((SV*)perl_array);
}

/***************************** Clownfish::Hash ******************************/

void*
CFISH_Hash_To_Host_IMP(cfish_Hash *self, void *vcache) {
    dTHX;
    cfish_ConversionCache *cache = (cfish_ConversionCache*)vcache;
    cfish_ConversionCache  new_cache;

    if (cache) {
        // Lookup Hash in conversion cache.
        if ((cfish_Obj*)self == cache->root_obj) {
            return newRV_inc(cache->root_sv);
        }
        if (cache->seen) {
            void *cached_hv = CFISH_PtrHash_Fetch(cache->seen, self);
            if (cached_hv) {
                return newRV_inc((SV*)cached_hv);
            }
        }
    }

    HV *perl_hash = newHV();

    if (!cache) {
        // Set up conversion cache.
        cache = &new_cache;
        cache->root_obj = (cfish_Obj*)self;
        cache->root_sv  = (SV*)perl_hash;
        cache->seen     = NULL;
    }
    else {
        if (!cache->seen) {
            // Create PtrHash lazily.
            cache->seen = cfish_PtrHash_new(0);
        }
        CFISH_PtrHash_Store(cache->seen, self, perl_hash);
    }

    cfish_HashIterator *iter = cfish_HashIter_new(self);

    // Iterate over key-value pairs.
    while (CFISH_HashIter_Next(iter)) {
        cfish_String *key      = CFISH_HashIter_Get_Key(iter);
        const char   *key_ptr  = CFISH_Str_Get_Ptr8(key);
        I32           key_size = CFISH_Str_Get_Size(key);

        // Recurse for each value.
        cfish_Obj *val    = CFISH_HashIter_Get_Value(iter);
        SV        *val_sv = val
                            ? (SV*)CFISH_Obj_To_Host(val, cache)
                            : newSV(0);

        // Using a negative `klen` argument to signal UTF-8 is undocumented
        // in older Perl versions but works since 5.8.0.
        (void)hv_store(perl_hash, key_ptr, -key_size, val_sv, 0);
    }

    if (cache == &new_cache && cache->seen) {
        CFISH_PtrHash_Destroy(cache->seen);
    }

    CFISH_DECREF(iter);
    return newRV_noinc((SV*)perl_hash);
}

/****************************** Clownfish::Num ******************************/

void*
CFISH_Float_To_Host_IMP(cfish_Float *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    return newSVnv(self->value);
}

void*
CFISH_Int_To_Host_IMP(cfish_Integer *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    SV *sv = NULL;

    if (sizeof(IV) >= 8) {
        sv = newSViv((IV)self->value);
    }
    else {
        sv = newSVnv((double)self->value); // lossy
    }

    return sv;
}

void*
CFISH_Bool_To_Host_IMP(cfish_Boolean *self, void *vcache) {
    CFISH_UNUSED_VAR(vcache);
    dTHX;
    return newSViv((IV)self->value);
}

/********************* Clownfish::TestHarness::TestUtils ********************/


#ifndef CFISH_NOTHREADS

void*
cfish_TestUtils_clone_host_runtime() {
    PerlInterpreter *interp = (PerlInterpreter*)PERL_GET_CONTEXT;
    PerlInterpreter *clone  = perl_clone(interp, CLONEf_CLONE_HOST);
    PERL_SET_CONTEXT(interp);
    return clone;
}

void
cfish_TestUtils_set_host_runtime(void *runtime) {
    PERL_SET_CONTEXT(runtime);
}

void
cfish_TestUtils_destroy_host_runtime(void *runtime) {
    PerlInterpreter *current = (PerlInterpreter*)PERL_GET_CONTEXT;
    PerlInterpreter *interp  = (PerlInterpreter*)runtime;

    // Switch to the interpreter before destroying it. Required on some
    // platforms.
    if (current != interp) {
        PERL_SET_CONTEXT(interp);
    }

    perl_destruct(interp);
    perl_free(interp);

    if (current != interp) {
        PERL_SET_CONTEXT(current);
    }
}

#else /* CFISH_NOTHREADS */

void*
cfish_TestUtils_clone_host_runtime() {
    CFISH_THROW(CFISH_ERR, "No thread support");
    CFISH_UNREACHABLE_RETURN(void*);
}

void
cfish_TestUtils_set_host_runtime(void *runtime) {
    CFISH_UNUSED_VAR(runtime);
    CFISH_THROW(CFISH_ERR, "No thread support");
}

void
cfish_TestUtils_destroy_host_runtime(void *runtime) {
    CFISH_UNUSED_VAR(runtime);
    CFISH_THROW(CFISH_ERR, "No thread support");
}

#endif

