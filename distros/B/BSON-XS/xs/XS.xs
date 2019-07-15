/* vim: set ts=2 sts=2 sw=2 et tw=75: */

/*
 *  Copyright 2009-2016 MongoDB, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "bson.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "regcomp.h"
#include "string.h"
#include "limits.h"

/* load after other Perl headers */
#include "ppport.h"

/* adapted from perl.h and must come after it */
#if !defined(Strtoll)
#    ifdef __hpux
#        define Strtoll __strtoll
#    endif
#    ifdef WIN32
#        define Strtoll _strtoi64
#    endif
#    if !defined(Strtoll) && defined(HAS_STRTOLL)
#        define Strtoll strtoll
#    endif
#    if !defined(Strtoll) && defined(HAS_STRTOQ)
#        define Strtoll strtoq
#    endif
#    if !defined(Strtoll)
#        error strtoll not available
#    endif
#endif

/* whether to add an _id field */
#define PREP 1
#define NO_PREP 0

/* define regex macros for Perl 5.8 */
#ifndef RX_PRECOMP
#define RX_PRECOMP(re) ((re)->precomp)
#define RX_PRELEN(re) ((re)->prelen)
#endif

#define SUBTYPE_BINARY_DEPRECATED 2
#define SUBTYPE_BINARY 0

/* struct for circular ref checks */
typedef struct _stackette {
  void *ptr;
  struct _stackette *prev;
} stackette;

#define EMPTY_STACK 0

#define MAX_DEPTH 100

/* convenience functions taken from Text::CSV_XS by H.M. Brand */
#define _is_reftype(f,x) \
    (f && ((SvGMAGICAL (f) && mg_get (f)) || 1) && SvROK (f) && SvTYPE (SvRV (f)) == x)
#define _is_arrayref(f) _is_reftype (f, SVt_PVAV)
#define _is_hashref(f)  _is_reftype (f, SVt_PVHV)
#define _is_coderef(f)  _is_reftype (f, SVt_PVCV)

/* shorthand for getting an SV* from a hash and key */
#define _hv_fetchs_sv(h,k) \
    (((svp = hv_fetchs(h, k, FALSE)) && *svp) ? *svp : 0)

/* perl call helpers
 *
 * For convenience, these functions encapsulate the verbose stack
 * manipulation code necessary to call perl functions from C.
 *
 */

static SV * call_method_va(SV *self, const char *method, int num, ...);
static SV * call_method_with_pairs_va(SV *self, const char *method, ...);
static SV * new_object_from_pairs(const char *klass, ...);
static SV * call_method_with_arglist (SV *self, const char *method, va_list args);
static SV * call_sv_va (SV *func, int num, ...);
static SV * call_pv_va (char *func, int num, ...);
static bool call_key_value_iter (SV *func, SV **ret );

#define call_perl_reader(s,m) call_method_va(s,m,0)

/* BSON encoding
 *
 * Public function  perl_mongo_sv_to_bsonis the entry point.  It calls one
 * of the container encoding functions, hv_doc_to_bson, or
 * ixhash_doc_to_bson.  Those iterate their contents, encoding them with
 * sv_to_bson_elem.  sv_to_bson_elem delegates to various append_*
 * functions for particular types.
 *
 * Other functions are utility functions used during encoding.
 */

static void perl_mongo_sv_to_bson (bson_t * bson, SV *sv, HV *opts);

static void hv_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc);
static void ixhash_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc);
static void iter_src_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc);

#define hv_doc_to_bson(b,d,o,s,u) hv_to_bson((b),(d),(o),(s),(u),0)
#define hv_elem_to_bson(b,d,o,s,u) hv_to_bson((b),(d),(o),(s),(u),1)
#define ixhash_doc_to_bson(b,d,o,s,u) ixhash_to_bson((b),(d),(o),(s),(u),0)
#define ixhash_elem_to_bson(b,d,o,s,u) ixhash_to_bson((b),(d),(o),(s),(u),1)
#define iter_doc_to_bson(b,d,o,s,u) iter_src_to_bson((b),(d),(o),(s),(u),0)
#define iter_elem_to_bson(b,d,o,s,u) iter_src_to_bson((b),(d),(o),(s),(u),1)

static void sv_to_bson_elem (bson_t * bson, const char *key, SV *sv, HV *opts, stackette *stack, int depth);

const char * maybe_append_first_key(bson_t *bson, HV *opts, stackette *stack, int depth);

static void append_binary(bson_t * bson, const char * key, bson_subtype_t subtype, SV * sv);
static void append_regex(bson_t * bson, const char *key, REGEXP *re, SV * sv);
static void append_decomposed_regex(bson_t *bson, const char *key, const char *pattern, const char *flags);
static void append_fit_int(bson_t * bson, const char *key, SV * sv);
static void append_utf8(bson_t * bson, const char *key, SV * sv);

static void assert_valid_key(const char* str, STRLEN len);
static const char * bson_key(const char * str, HV *opts);
static void get_regex_flags(char * flags, SV *sv);
static int64_t math_bigint_to_int64(SV *sv, const char *key);
static SV* int64_as_SV(int64_t value);
static stackette * check_circular_ref(void *ptr, stackette *stack);
static SV* bson_parent_type(SV *sv);

/* BSON decoding
 *
 * Public function _decode_bson is the entry point.  It calls
 * bson_doc_to_hashref, which construct a container and fills it using
 * bson_elem_to_sv.  That may call bson_doc_to_hashref or
 * bson_doc_to_arrayref to decode sub-containers.
 *
 * The bson_oid_to_sv function manually constructs a BSON::OID object to
 * avoid the overhead of calling its constructor.  This optimization is
 * fragile and might need to be reconsidered.
 *
 */

static SV * bson_doc_to_hashref(bson_iter_t * iter, HV *opts, int depth, bool top);
static SV * bson_doc_to_tiedhash(bson_iter_t * iter, HV *opts, int depth, bool top);
static SV * bson_array_to_arrayref(bson_iter_t * iter, HV *opts, int depth);
static SV * bson_elem_to_sv(const bson_iter_t * iter, const char *key, HV *opts, int depth);
static SV * bson_oid_to_sv(const bson_iter_t * iter);

/********************************************************************
 * Some C libraries (e.g. MSVCRT) do not have a "timegm" function.
 * Here is a surrogate implementation.
 ********************************************************************/

#if defined(WIN32) || defined(sun)

static int
is_leap_year(unsigned year) {
    year += 1900;
    return (year % 4) == 0 && ((year % 100) != 0 || (year % 400) == 0);
}

static time_t
timegm(struct tm *tm) {
  static const unsigned month_start[2][12] = {
        { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 },
        { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 },
        };
  time_t ret = 0;
  int i;

  for (i = 70; i < tm->tm_year; ++i)
    ret += is_leap_year(i) ? 366 : 365;

  ret += month_start[is_leap_year(tm->tm_year)][tm->tm_mon];
  ret += tm->tm_mday - 1;
  ret *= 24;
  ret += tm->tm_hour;
  ret *= 60;
  ret += tm->tm_min;
  ret *= 60;
  ret += tm->tm_sec;
  return ret;
}

#endif /* WIN32 */

/********************************************************************
 * perl call helpers
 ********************************************************************/

/* call_method_va -- calls a method with a variable number
 * of SV * arguments.  The SV* arguments are NOT mortalized.
 * Must give the number of arguments before the variable list */

static SV *
call_method_va (SV *self, const char *method, int num, ...) {
  dSP;
  SV *ret;
  I32 count;
  va_list args;

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);
  XPUSHs (self);

  va_start (args, num);
  for( ; num > 0; num-- ) {
    XPUSHs (va_arg( args, SV* ));
  }
  va_end(args);

  PUTBACK;
  count = call_method (method, G_SCALAR);

  SPAGAIN;
  if (count != 1) {
    croak ("method didn't return a value");
  }
  ret = POPs;
  SvREFCNT_inc (ret);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

/* call_method_va_paris -- calls a method with a variable number
 * of key/value pairs as paired char* and SV* arguments.  The SV* arguments
 * are NOT mortalized.  The final argument must be a NULL key. */

static SV *
call_method_with_pairs_va (SV *self, const char *method, ...) {
  SV *ret;
  va_list args;
  va_start (args, method);
  ret = call_method_with_arglist(self, method, args);
  va_end(args);
  return ret;
}

/* new_object_from_pairs -- calls 'new' with a variable number of
 * of key/value pairs as paired char* and SV* arguments.  The SV* arguments
 * are NOT mortalized.  The final argument must be a NULL key. */

static SV *
new_object_from_pairs(const char *klass, ...) {
  SV *ret;
  va_list args;
  va_start (args, klass);
  ret = call_method_with_arglist(sv_2mortal(newSVpv(klass,0)), "new", args);
  va_end(args);
  return ret;
}

static SV *
call_method_with_arglist (SV *self, const char *method, va_list args) {
  dSP;
  SV *ret = NULL;
  char *key;
  I32 count;

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);
  XPUSHs (self);

  while ((key = va_arg (args, char *))) {
    mXPUSHp (key, strlen (key));
    XPUSHs (va_arg (args, SV *));
  }

  PUTBACK;
  count = call_method (method, G_SCALAR);

  SPAGAIN;
  if (count != 1) {
    croak ("method didn't return a value");
  }
  ret = POPs;
  SvREFCNT_inc (ret);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static SV *
call_sv_va (SV *func, int num, ...) {
  dSP;
  SV *ret;
  I32 count;
  va_list args;

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);

  va_start (args, num);
  for( ; num > 0; num-- ) {
    XPUSHs (va_arg( args, SV* ));
  }
  va_end(args);

  PUTBACK;
  count = call_sv(func, G_SCALAR);

  SPAGAIN;
  if (count != 1) {
    croak ("method didn't return a value");
  }
  ret = POPs;
  SvREFCNT_inc (ret);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}


/* Call func and return key value pairs.
 *
 * ret is address of (SV*)[2] where key and value will be put.
 *
 * return value is true if key is defined and false otherwise.
 */
static bool
call_key_value_iter (SV *func, SV **ret ) {
  dSP;
  I32 count;
  bool ok;

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);
  PUTBACK;

  count = call_sv(func, G_ARRAY);

  SPAGAIN;

  if ( count == 0 ) {
    ok = false;
  }
  else {
    SvREFCNT_inc (ret[1] = POPs);
    SvREFCNT_inc (ret[0] = POPs);

    ok = SvOK(ret[0]) != 0;
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ok;
}

static SV *
call_pv_va (char *func, int num, ...) {
  dSP;
  SV *ret;
  I32 count;
  va_list args;

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);

  va_start (args, num);
  for( ; num > 0; num-- ) {
    XPUSHs (va_arg( args, SV* ));
  }
  va_end(args);

  PUTBACK;
  count = call_pv(func, G_SCALAR);

  SPAGAIN;
  if (count != 1) {
    croak ("function %s didn't return a value", func);
  }
  ret = POPs;
  SvREFCNT_inc (ret);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

/********************************************************************
 * BSON encoding
 ********************************************************************/

void
perl_mongo_sv_to_bson (bson_t * bson, SV *sv, HV *opts) {

  if (!SvROK (sv)) {
    croak ("not a reference");
  }

  if ( ! sv_isobject(sv) ) {
    switch ( SvTYPE(SvRV(sv)) ) {
      case SVt_PVHV:
        hv_doc_to_bson (bson, sv, opts, EMPTY_STACK, 0);
        break;
      default:
        sv_dump(sv);
        croak ("Can't encode unhandled variable type");
    }
  }
  else {
    SV *obj;
    char *class;

    obj = SvRV(sv);
    class = HvNAME(SvSTASH(obj));

    if ( strEQ(class, "Tie::IxHash") ) {
      ixhash_doc_to_bson(bson, sv, opts, EMPTY_STACK, 0);
    }
    else if ( strEQ(class, "BSON::Doc") ) {
      iter_doc_to_bson(bson, sv, opts, EMPTY_STACK, 0);
    }
    else if ( strEQ(class, "BSON::Raw") ) {
      STRLEN str_len;
      SV *encoded;
      const char *bson_str;
      bson_t *child;

      encoded = sv_2mortal(call_perl_reader(sv, "bson"));
      bson_str = SvPV(encoded, str_len);
      child = bson_new_from_data((uint8_t*) bson_str, str_len);
      bson_concat(bson, child);
      bson_destroy(child);
    }
    else if ( strEQ(class, "MongoDB::BSON::_EncodedDoc") ) {
      STRLEN str_len;
      SV **svp;
      SV *encoded;
      const char *bson_str;
      bson_t *child;

      encoded = _hv_fetchs_sv((HV *)obj, "bson");
      bson_str = SvPV(encoded, str_len);
      child = bson_new_from_data((uint8_t*) bson_str, str_len);
      bson_concat(bson, child);
      bson_destroy(child);
    }
    else if ( strEQ(class, "MongoDB::BSON::Raw") ) {
      SV *str_sv;
      char *str;
      STRLEN str_len;
      bson_t *child;

      str_sv = SvRV(sv);

      // check type ok
      if (!SvPOK(str_sv)) {
        croak("MongoDB::BSON::Raw must be a blessed string reference");
      }

      str = SvPV(str_sv, str_len);

      child = bson_new_from_data((uint8_t*) str, str_len);
      bson_concat(bson, child);
      bson_destroy(child);
    }
    else if (SvTYPE(obj) == SVt_PVHV) {
      hv_doc_to_bson(bson, sv, opts, EMPTY_STACK, 0);
    }
    else {
      croak ("Can't encode non-container of type '%s'", class);
    }
  }
}

static void
hv_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc) {
  HE *he;
  HV *hv;
  const char *first_key = NULL;

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }
  hv = (HV*)SvRV(sv);
  if (!(stack = check_circular_ref(hv, stack))) {
    croak("circular reference detected");
  }

  if ( ! subdoc ) {
    first_key = maybe_append_first_key(bson, opts, stack, depth);
  }

  (void)hv_iterinit (hv);
  while ((he = hv_iternext (hv))) {
    SV **hval;
    STRLEN len;
    const char *key = HePV (he, len);
    uint32_t utf8 = HeUTF8(he);
    assert_valid_key(key, len);

    /* if we've already added the first key, continue */
    if (first_key && strcmp(key, first_key) == 0) {
      continue;
    }

    /*
     * HeVAL doesn't return the correct value for tie(%foo, 'Tie::IxHash')
     * so we're using hv_fetch
     */
    if ((hval = hv_fetch(hv, key, utf8 ? -len : len, 0)) == 0) {
      croak("could not find hash value for key %s, len:%lu", key, (long unsigned int)len);
    }
    if (!utf8) {
      key = (const char *) bytes_to_utf8((U8 *)key, &len);
    }

    if ( ! is_utf8_string((const U8*)key,len)) {
        croak( "Invalid UTF-8 detected while encoding BSON" );
    }

    sv_to_bson_elem (bson, key, *hval, opts, stack, depth);
    if (!utf8) {
      Safefree(key);
    }
  }

  /* free the hv elem */
  if ( ! subdoc ) {
    Safefree(stack);
  }
  depth--;
}

static void
ixhash_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc) {
  int i;
  SV **keys_sv, **values_sv;
  AV *array, *keys, *values;
  const char *first_key = NULL;

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  /*
   * a Tie::IxHash is of the form:
   * [ {hash}, [keys], [order], 0 ]
   */
  array = (AV*)SvRV(sv);

  /* check if we're in an infinite loop */
  if (!(stack = check_circular_ref(array, stack))) {
    croak("circular ref");
  }

  /* keys in order, from position 1 */
  keys_sv = av_fetch(array, 1, 0);
  keys = (AV*)SvRV(*keys_sv);

  /* values in order, from position 2 */
  values_sv = av_fetch(array, 2, 0);
  values = (AV*)SvRV(*values_sv);

  if ( ! subdoc ) {
    first_key = maybe_append_first_key(bson, opts, stack, depth);
  }

  for (i=0; i<=av_len(keys); i++) {
    SV **k, **v;
    STRLEN len;
    const char *str;

    if (!(k = av_fetch(keys, i, 0)) ||
        !(v = av_fetch(values, i, 0))) {
      croak ("failed to fetch associative array value");
    }

    str = SvPVutf8(*k, len);
    assert_valid_key(str,len);

    if (first_key && strcmp(str, first_key) == 0) {
        continue;
    }

    sv_to_bson_elem(bson, str, *v, opts, stack, depth);
  }

  /* free the ixhash elem */
  if ( ! subdoc ) {
    Safefree(stack);
  }
  depth--;
}

/* Construct a BSON document from an iterator code ref that returns key
 * value pairs */

static void
iter_src_to_bson(bson_t * bson, SV *sv, HV *opts, stackette *stack, int depth, bool subdoc) {
  int i;
  SV *iter;
  SV * kv[2];
  const char *first_key = NULL;

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  /* check if we're in an infinite loop */
  if (!(stack = check_circular_ref(SvRV(sv), stack))) {
    croak("circular ref: %s", SvPV_nolen(sv));
  }

  if ( ! subdoc ) {
    first_key = maybe_append_first_key(bson, opts, stack, depth);
  }

  iter = sv_2mortal(call_perl_reader(sv, "_iterator"));
  if ( !SvROK(iter) || SvTYPE(SvRV(iter)) != SVt_PVCV ) {
    croak("invalid iterator from %s", SvPV_nolen(sv));
  }

  while ( call_key_value_iter( iter, kv ) ) {
    sv_2mortal(kv[0]);
    sv_2mortal(kv[1]);
    STRLEN len;
    const char *str;

    str = SvPVutf8(kv[0], len);
    assert_valid_key(str,len);

    if (first_key && strcmp(str, first_key) == 0) {
        continue;
    }

    sv_to_bson_elem(bson, str, kv[1], opts, stack, depth);
  }

  /* free the stack elem for sv */
  if ( ! subdoc ) {
    Safefree(stack);
  }
  depth--;
}

/* This is for an array reference contained *within* a document */
static void
av_to_bson (bson_t * bson, AV *av, HV *opts, stackette *stack, int depth) {
  I32 i;

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  if (!(stack = check_circular_ref(av, stack))) {
    croak("circular ref");
  }

  for (i = 0; i <= av_len (av); i++) {
    SV **sv;
    SV *key = sv_2mortal(newSViv (i));
    if (!(sv = av_fetch (av, i, 0)))
      sv_to_bson_elem (bson, SvPV_nolen(key), newSV(0), opts, stack, depth);
    else
      sv_to_bson_elem (bson, SvPV_nolen(key), *sv, opts, stack, depth);
  }

  /* free the av elem */
  Safefree(stack);
  depth--;
}

/* verify and transform key, if necessary */
static const char *
bson_key(const char * str, HV *opts) {
  SV **svp;
  SV *tempsv;
  STRLEN len;

  /* first swap op_char if necessary */
  if (
      (tempsv = _hv_fetchs_sv(opts, "op_char"))
      && SvOK(tempsv)
      && SvPV_nolen(tempsv)[0] == str[0]
  ) {
    char *out = savepv(str);
    SAVEFREEPV(out);
    *out = '$';
    str = out;
  }

  /* then check for validity */
  if (
      (tempsv = _hv_fetchs_sv(opts, "invalid_chars"))
      && SvOK(tempsv)
      && (len = sv_len(tempsv))
  ) {
    STRLEN i;
    const char *invalid = SvPV_nolen(tempsv);

    for (i=0; i<len; i++) {
      if (strchr(str, invalid[i])) {
        croak("key '%s' has invalid character(s) '%s'", str, invalid);
      }
    }
  }

  return str;
}

static void
sv_to_bson_elem (bson_t * bson, const char * in_key, SV *sv, HV *opts, stackette *stack, int depth) {
  SV **svp;
  const char * key = bson_key(in_key,opts);

  if (!SvOK(sv)) {
    if (SvGMAGICAL(sv)) {
      mg_get(sv);
    }
  }

  if (!SvOK(sv)) {
      bson_append_null(bson, key, -1);
      return;
  }
  else if (SvROK (sv)) {
    if (sv_isobject (sv)) {
      const char* obj_type = sv_reftype(SvRV(sv), true);
      SV* parent = bson_parent_type(SvRV(sv));
      if ( parent != NULL ) {
        obj_type = (const char *) SvPV_nolen(parent);
      }

      /* OIDs */
      if (strEQ(obj_type, "BSON::OID")) {
        SV *attr = sv_2mortal(call_perl_reader(sv, "oid"));
        char *bytes = SvPV_nolen(attr);
        bson_oid_t oid;
        bson_oid_init_from_data(&oid, (uint8_t*) bytes);

        bson_append_oid(bson, key, -1, &oid);

      }
      else if (strEQ(obj_type, "MongoDB::OID")) {
        SV *attr = sv_2mortal(call_perl_reader(sv, "value"));
        char *str = SvPV_nolen (attr);
        bson_oid_t oid;
        bson_oid_init_from_string(&oid, str);

        bson_append_oid(bson, key, -1, &oid);

      }
      /* Tie::IxHash */
      else if (strEQ(obj_type, "Tie::IxHash")) {
        bson_t child;

        bson_append_document_begin(bson, key, -1, &child);
        ixhash_elem_to_bson(&child, sv, opts, stack, depth);
        bson_append_document_end(bson, &child);
      }
      else if (strEQ(obj_type, "BSON::Doc")) {
        bson_t child;

        bson_append_document_begin(bson, key, -1, &child);
        iter_elem_to_bson(&child, sv, opts, stack, depth);
        bson_append_document_end(bson, &child);
      }
      else if (strEQ(obj_type, "BSON::Array")) {
        bson_t child;

        bson_append_array_begin(bson, key, -1, &child);
        av_to_bson (&child, (AV *)SvRV (sv), opts, stack, depth);
        bson_append_array_end(bson, &child);
      }
      else if (strEQ(obj_type, "BSON::Raw")) {
        STRLEN str_len;
        SV *encoded;
        const char *bson_str;
        bson_t *child;

        encoded = sv_2mortal(call_perl_reader(sv, "bson"));
        bson_str = SvPV(encoded, str_len);

        child = bson_new_from_data((uint8_t*) bson_str, str_len);
        bson_append_document(bson, key, -1, child);
        bson_destroy(child);
      }
      else if (strEQ(obj_type, "MongoDB::BSON::Raw")) {
        SV *str_sv;
        char *str;
        STRLEN str_len;
        bson_t *child;

        str_sv = SvRV(sv);

        // check type ok
        if (!SvPOK(str_sv)) {
          croak("MongoDB::BSON::Raw must be a blessed string reference");
        }

        str = SvPV(str_sv, str_len);

        child = bson_new_from_data((uint8_t*) str, str_len);
        bson_append_document(bson, key, -1, child);
        bson_destroy(child);
      }
      else if (strEQ(obj_type, "BSON::Time")) {
        SV *ms = sv_2mortal(call_perl_reader(sv, "value"));
        if ( sv_isa(ms, "Math::BigInt") ) {
          int64_t t = math_bigint_to_int64(ms,key);
          bson_append_date_time(bson, key, -1, t);
        }
        else {
          bson_append_date_time(bson, key, -1, (int64_t)SvIV(ms));
        }
      }
      /* Time::Moment */
      else if (strEQ(obj_type, "Time::Moment")) {
        SV *sec = sv_2mortal(call_perl_reader(sv, "epoch"));
        SV *ms = sv_2mortal(call_perl_reader(sv, "millisecond"));
        bson_append_date_time(bson, key, -1, (int64_t)SvIV(sec)*1000+SvIV(ms));
      }
      /* DateTime */
      else if (strEQ(obj_type, "DateTime")) {
        SV *sec, *ms, *tz, *tz_name;
        STRLEN len;
        char *str;

        /* check for floating tz */
        tz = sv_2mortal(call_perl_reader (sv, "time_zone"));
        tz_name = sv_2mortal(call_perl_reader (tz, "name"));
        str = SvPV(tz_name, len);
        if (len == 8 && strncmp("floating", str, 8) == 0) {
          warn("saving floating timezone as UTC");
        }

        sec = sv_2mortal(call_perl_reader (sv, "epoch"));
        ms = sv_2mortal(call_perl_reader(sv, "millisecond"));

        bson_append_date_time(bson, key, -1, (int64_t)SvIV(sec)*1000+SvIV(ms));
      }
      /* DateTime::TIny */
      else if (strEQ(obj_type, "DateTime::Tiny")) {
        struct tm t;
        time_t epoch_secs = time(NULL);
        int64_t epoch_ms;

        t.tm_year   = SvIV( sv_2mortal(call_perl_reader( sv, "year"    )) ) - 1900;
        t.tm_mon    = SvIV( sv_2mortal(call_perl_reader( sv, "month"   )) ) -    1;
        t.tm_mday   = SvIV( sv_2mortal(call_perl_reader( sv, "day"     )) )       ;
        t.tm_hour   = SvIV( sv_2mortal(call_perl_reader( sv, "hour"    )) )       ;
        t.tm_min    = SvIV( sv_2mortal(call_perl_reader( sv, "minute"  )) )       ;
        t.tm_sec    = SvIV( sv_2mortal(call_perl_reader( sv, "second"  )) )       ;
        t.tm_isdst  = -1;     /* no dst/tz info in DateTime::Tiny */

        epoch_secs = timegm( &t );

        /* no miliseconds in DateTime::Tiny, so just multiply by 1000 */
        epoch_ms = (int64_t)epoch_secs*1000;
        bson_append_date_time(bson, key, -1, epoch_ms);
      }
      else if (strEQ(obj_type, "Mango::BSON::Time")) {
        SV *ms = _hv_fetchs_sv((HV *)SvRV(sv), "time");
        bson_append_date_time(bson, key, -1, (int64_t)SvIV(ms));
      }
      /* DBRef */
      else if (strEQ(obj_type, "BSON::DBRef") || strEQ(obj_type, "MongoDB::DBRef")) {
        SV *dbref;
        bson_t child;
        dbref = sv_2mortal(call_perl_reader(sv, "_ordered"));
        bson_append_document_begin(bson, key, -1, &child);
        ixhash_elem_to_bson(&child, dbref, opts, stack, depth);
        bson_append_document_end(bson, &child);
      }

      /* boolean -- these are the most well-known boolean libraries
       * on CPAN.  Type::Serialiser::Boolean now aliases to
       * JSON::PP::Boolean so it is listed at the end for compatibility
       * with old versions of it.  Old versions of Cpanel::JSON::XS
       * similarly have their own type, but now use JSON::PP::Boolean.
       */
      else if (
          strEQ(obj_type, "boolean") ||
          strEQ(obj_type, "BSON::Bool") ||
          strEQ(obj_type, "JSON::XS::Boolean") ||
          strEQ(obj_type, "JSON::PP::Boolean") ||
          strEQ(obj_type, "JSON::Tiny::_Bool") ||
          strEQ(obj_type, "Mojo::JSON::_Bool") ||
          strEQ(obj_type, "Cpanel::JSON::XS::Boolean") ||
          strEQ(obj_type, "Types::Serialiser::Boolean")
        ) {
        bson_append_bool(bson, key, -1, SvIV(SvRV(sv)));
      }
      else if (strEQ(obj_type, "BSON::Code") || strEQ(obj_type, "MongoDB::Code")) {
        SV *code, *scope;
        char *code_str;
        STRLEN code_len;

        code = sv_2mortal(call_perl_reader (sv, "code"));
        code_str = SvPVutf8(code, code_len);

        if ( ! is_utf8_string((const U8*)code_str,code_len)) {
          croak( "Invalid UTF-8 detected while encoding BSON from %s", SvPV_nolen(sv) );
        }

        scope = sv_2mortal(call_perl_reader(sv, "scope"));

        if (SvOK(scope)) {
            bson_t * child = bson_new();
            hv_elem_to_bson(child, scope, opts, EMPTY_STACK, 0);
            bson_append_code_with_scope(bson, key, -1, code_str, code_len, child);
            bson_destroy(child);
        } else {
            bson_append_code(bson, key, -1, code_str);
        }

      }
      else if (strEQ(obj_type, "BSON::Timestamp")) {
        SV *sec, *inc;

        inc = sv_2mortal(call_perl_reader(sv, "increment"));
        sec = sv_2mortal(call_perl_reader(sv, "seconds"));

        bson_append_timestamp(bson, key, -1, SvIV(sec), SvIV(inc));
      }
      else if (strEQ(obj_type, "MongoDB::Timestamp")) {
        SV *sec, *inc;

        inc = sv_2mortal(call_perl_reader(sv, "inc"));
        sec = sv_2mortal(call_perl_reader(sv, "sec"));

        bson_append_timestamp(bson, key, -1, SvIV(sec), SvIV(inc));
      }
      else if (strEQ(obj_type, "BSON::MinKey") || strEQ(obj_type, "MongoDB::MinKey")) {
        bson_append_minkey(bson, key, -1);
      }
      else if (strEQ(obj_type, "BSON::MaxKey") || strEQ(obj_type, "MongoDB::MaxKey")) {
        bson_append_maxkey(bson, key, -1);
      }
      else if (strEQ(obj_type, "MongoDB::BSON::_EncodedDoc")) {
        STRLEN str_len;
        SV **svp;
        SV *encoded;
        const char *bson_str;
        bson_t *child;

        encoded = _hv_fetchs_sv((HV *)SvRV(sv), "bson");
        bson_str = SvPV(encoded, str_len);
        child = bson_new_from_data((uint8_t*) bson_str, str_len);
        bson_append_document(bson, key, -1, child);
        bson_destroy(child);
      }
      else if (strEQ(obj_type, "BSON::String")) {
        SV *str_sv;
        char *str;
        STRLEN str_len;

        str_sv = sv_2mortal(call_perl_reader(sv,"value"));
        append_utf8(bson, key, str_sv);
      }
      else if (strEQ(obj_type, "MongoDB::BSON::String")) {
        SV *str_sv;
        char *str;
        STRLEN str_len;

        str_sv = SvRV(sv);

        /* check type ok */
        if (!SvPOK(str_sv)) {
          croak("MongoDB::BSON::String must be a blessed string reference");
        }

        append_utf8(bson, key, str_sv);
      }
      else if (strEQ(obj_type, "BSON::Bytes") || strEQ(obj_type, "MongoDB::BSON::Binary")) {
        SV *data, *subtype;

        subtype = sv_2mortal(call_perl_reader(sv, "subtype"));
        data = sv_2mortal(call_perl_reader(sv, "data"));

        append_binary(bson, key, SvIV(subtype), data);
      }
      else if (strEQ(obj_type, "BSON::Binary")) {
        SV *data, *packed, *subtype;
        bson_subtype_t int_subtype;
        char *pat = "C*";

        subtype = sv_2mortal(call_perl_reader(sv, "subtype"));
        int_subtype = SvOK(subtype) ? SvIV(subtype) : 0;
        data = sv_2mortal(call_perl_reader(sv, "data"));
        packed = sv_2mortal(newSVpvs(""));

        /* if data is an array ref, pack it; othewise, pack an empty binary */
        if ( SvOK(data) && ( SvTYPE(SvRV(data)) == SVt_PVAV) ) {
          AV *d_array = (AV*) SvRV(data);
          packlist(packed, pat, pat+2,
            av_fetch(d_array,0,0), av_fetch(d_array,av_len(d_array),0)
          );
        }

        append_binary(bson, key, int_subtype, packed);
      }
      else if (strEQ(obj_type, "Regexp")) {
#if PERL_REVISION==5 && PERL_VERSION>=12
        REGEXP * re = SvRX(sv);
#else
        REGEXP * re = (REGEXP *) mg_find((SV*)SvRV(sv), PERL_MAGIC_qr)->mg_obj;
#endif

        append_regex(bson, key, re, sv);
      }
      else if (strEQ(obj_type, "BSON::Regex") || strEQ(obj_type, "MongoDB::BSON::Regexp") ) {
        /* Abstract regexp object */
        SV *pattern, *flags;
        pattern = sv_2mortal(call_perl_reader( sv, "pattern" ));
        flags   = sv_2mortal(call_perl_reader( sv, "flags" ));

        append_decomposed_regex( bson, key, SvPV_nolen( pattern ), SvPV_nolen( flags ) );
      }
      /* 64-bit integers */
      else if (strEQ(obj_type, "Math::BigInt")) {
        bson_append_int64(bson, key, -1, math_bigint_to_int64(sv,key));
      }
      else if (strEQ(obj_type, "BSON::Int64") ) {
        SV *v = sv_2mortal(call_perl_reader(sv, "value"));

        if ( SvROK(v) ) {
          /* delegate to wrapped value type */
          return sv_to_bson_elem(bson,in_key,v,opts,stack,depth);
        }

        bson_append_int64(bson, key, -1, (int64_t)SvIV(sv));
      }
      else if (strEQ(obj_type, "Math::Int64")) {
        uint64_t v_int;
        SV *v_sv = call_pv_va("Math::Int64::int64_to_native",1,sv);
        Copy(SvPVbyte_nolen(v_sv), &v_int, 1, uint64_t);
        bson_append_int64(bson, key, -1, v_int);
      }
      else if (strEQ(obj_type, "BSON::Int32") ) {
        bson_append_int32(bson, key, -1, (int32_t)SvIV(sv));
      }
      else if (strEQ(obj_type, "BSON::Double") ) {
        bson_append_double(bson, key, -1, (double)SvNV(sv));
      }
      else if (strEQ(obj_type, "BSON::Decimal128") ) {
        bson_decimal128_t dec;
        SV *dec_sv;
        char *bid_bytes;

        dec_sv = sv_2mortal(call_perl_reader( sv, "bytes" ));
        bid_bytes = SvPV_nolen(dec_sv);

        /* normalize from little endian back to native byte order */
        Copy(bid_bytes, &dec.low, 1, uint64_t);
        Copy(bid_bytes + 8, &dec.high, 1, uint64_t);
        dec.low = BSON_UINT64_FROM_LE(dec.low);
        dec.high = BSON_UINT64_FROM_LE(dec.high);

        bson_append_decimal128(bson, key, -1, &dec);
      }
      else {
        croak ("For key '%s', can't encode value of type '%s'", key, HvNAME(SvSTASH(SvRV(sv))));
      }
    } else {
      SV *deref = SvRV(sv);
      switch (SvTYPE (deref)) {
      case SVt_PVHV: {
        /* hash */
        bson_t child;
        bson_append_document_begin(bson, key, -1, &child);
        /* don't add a _id to inner objs */
        hv_elem_to_bson (&child, sv, opts, stack, depth);
        bson_append_document_end(bson, &child);
        break;
      }
      case SVt_PVAV: {
        /* array */
        bson_t child;
        bson_append_array_begin(bson, key, -1, &child);
        av_to_bson (&child, (AV *)SvRV (sv), opts, stack, depth);
        bson_append_array_end(bson, &child);
        break;
      }
      default: {
          if ( SvPOK(deref) ) {
            /* binary */
            append_binary(bson, key, BSON_SUBTYPE_BINARY, deref);
          }
          else {
            croak ("For key '%s', can't encode value '%s'", key, SvPV_nolen(sv));
          }
        }
      }
    }
  } else {
    /* Value is a defined, non-reference scalar */
    SV *tempsv;
    bool prefer_numeric;

    tempsv = _hv_fetchs_sv(opts, "prefer_numeric");
    prefer_numeric = SvTRUE(tempsv);

#if PERL_REVISION==5 && PERL_VERSION<=18
    /* Before 5.18, get magic would clear public flags. This restores them
     * from private flags but ONLY if there is no public flag already, as
     * we have nothing else to go on for serialization.
     */
    if (!(SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK))) {
        SvFLAGS(sv) |= (SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
    }
#endif

    I32 is_number = looks_like_number(sv);

    if ( SvNOK(sv) ) {
      bson_append_double(bson, key, -1, (double)SvNV(sv));
    } else if ( SvIOK(sv) ) {
      append_fit_int(bson, key, sv);
    } else if ( prefer_numeric && is_number )  {
      /* copy to avoid modifying flags of the original */
      tempsv = sv_2mortal(newSVsv(sv));
      if (is_number & IS_NUMBER_NOT_INT) { /* double */
        bson_append_double(bson, key, -1, (double)SvNV(tempsv));
      } else {
        append_fit_int(bson, key, tempsv);
      }
    } else {
      append_utf8(bson, key, sv);
    }

  }
}

const char *
maybe_append_first_key(bson_t *bson, HV *opts, stackette *stack, int depth) {
  SV *tempsv;
  SV **svp;
  const char *first_key = NULL;

  if ( (tempsv = _hv_fetchs_sv(opts, "first_key")) && SvOK (tempsv) ) {
    STRLEN len;
    first_key = SvPVutf8(tempsv, len);
    assert_valid_key(first_key, len);
    if ( (tempsv = _hv_fetchs_sv(opts, "first_value")) ) {
      sv_to_bson_elem(bson, first_key, tempsv, opts, stack, depth);
    }
    else {
      bson_append_null(bson, first_key, -1);
    }
  }

  return first_key;
}

static void
append_decomposed_regex(bson_t *bson, const char *key, const char *pattern, const char *flags ) {
  size_t pattern_length = strlen( pattern );
  char *buf;

  Newx(buf, pattern_length + 1, char );
  Copy(pattern, buf, pattern_length, char );
  buf[ pattern_length ] = '\0';
  bson_append_regex(bson, key, -1, buf, flags);
  Safefree(buf);
}

static void
append_regex(bson_t * bson, const char *key, REGEXP *re, SV * sv) {
  char flags[]     = {0,0,0,0,0,0,0}; /* space for imxslu + \0 */
  char *buf;
  int i, j;

  get_regex_flags(flags, sv);

  /* sort flags -- how cool to write a sort algorithm by hand! Since we're
   * only sorting a tiny array, who cares if it's n-squared? */
  for ( i=0; flags[i]; i++ ) {
    for ( j=i+1; flags[j] ; j++ ) {
      if ( flags[i] > flags[j] ) {
        char t = flags[j];
        flags[j] = flags[i];
        flags[i] = t;
      }
    }
  }

  Newx(buf, (RX_PRELEN(re) + 1), char );
  Copy(RX_PRECOMP(re), buf, RX_PRELEN(re), char );
  buf[RX_PRELEN(re)] = '\0';

  bson_append_regex(bson, key, -1, buf, flags);

  Safefree(buf);
}

static void
append_binary(bson_t * bson, const char * key, bson_subtype_t subtype, SV * sv) {
    STRLEN len;
    uint8_t * bytes = (uint8_t *) SvPVbyte(sv, len);

    bson_append_binary(bson, key, -1, subtype, bytes, len);
}

static void
append_fit_int(bson_t * bson, const char *key, SV * sv) {
#if defined(MONGO_USE_64_BIT_INT)
  IV i = SvIV(sv);
  if ( i >= INT32_MIN && i <= INT32_MAX) {
    bson_append_int32(bson, key, -1, (int32_t)i);
  }
  else {
    bson_append_int64(bson, key, -1, (int64_t)i);
  }
#else
  bson_append_int32(bson, key, -1, (int32_t)SvIV(sv));
#endif
  return;
}

static void
append_utf8(bson_t * bson, const char *key, SV * sv) {
  STRLEN len;
  const char *str = SvPVutf8(sv, len);

  if ( ! is_utf8_string((const U8*)str,len)) {
    croak( "Invalid UTF-8 detected while encoding BSON" );
  }

  bson_append_utf8(bson, key, -1, str, len);
  return;
}

static void
assert_valid_key(const char* str, STRLEN len) {
  if(strlen(str)  < len) {
    SV *clean = call_pv_va("BSON::XS::_printable",1,sv_2mortal(newSVpvn(str,len)));
    croak("Key '%s' contains null character", SvPV_nolen(clean));
  }
}

static void
get_regex_flags(char * flags, SV *sv) {
  unsigned int i = 0, f = 0;

#if PERL_REVISION == 5 && PERL_VERSION < 10
  /* pre-5.10 doesn't have the re API */
  STRLEN string_length;
  char *re_string = SvPV( sv, string_length );

  /* pre-5.14 regexes are stringified in the format: (?ix-sm:foo) where
     everything between ? and - are the current flags. The format changed
     around 5.14, but for everything after 5.10 we use the re API anyway. */
  for( i = 2; i < string_length && re_string[i] != '-'; i++ ) {
    if ( re_string[i] == 'i'  ||
         re_string[i] == 'm'  ||
         re_string[i] == 'x'  ||
         re_string[i] == 'l'  ||
         re_string[i] == 'u'  ||
         re_string[i] == 's' ) {
      flags[f++] = re_string[i];
    } else if ( re_string[i] == ':' ) {
      break;
    }
  }
#else
  /* 5.10 added an API to extract flags, so we use that */
  int ret_count;
  SV *flags_sv;
  SV *pat_sv;
  char *flags_tmp;
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK (SP);
  XPUSHs (sv);
  PUTBACK;

  ret_count = call_pv( "re::regexp_pattern", G_ARRAY );
  SPAGAIN;

  if ( ret_count != 2 ) {
    croak( "error introspecting regex" );
  }

  /* regexp_pattern returns two items (in list context), the pattern and a list of flags */
  flags_sv = POPs;
  pat_sv   = POPs; /* too bad we throw this away */

  flags_tmp = SvPVutf8_nolen(flags_sv);
  for ( i = 0; i < sizeof( flags_tmp ); i++ ) {
    if ( flags_tmp[i] == 0 ) break;

    /* MongoDB supports only flags /imxslu */
    if ( flags_tmp[i] == 'i' ||
         flags_tmp[i] == 'm' ||
         flags_tmp[i] == 'x' ||
         flags_tmp[i] == 'l' ||
         flags_tmp[i] == 'u' ||
         flags_tmp[i] == 's' ) {
      flags[f++] = flags_tmp[i];
    }
    else {
      /* do nothing; just ignore it */
    }
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
#endif
}

/* Converts Math::BigInt to int64_t; sv must be Math::BigInt */
static int64_t math_bigint_to_int64(SV *sv, const char *key) {
  SV *tempsv;
  char *str;
  int64_t big;
  char *end = NULL;

  tempsv = sv_2mortal(call_perl_reader(sv, "bstr"));
  str = SvPV_nolen(tempsv);
  errno = 0;
  big = Strtoll(str, &end, 10);

  /* check for conversion problems */
  if ( end && (*end != '\0') ) {
    if ( errno == ERANGE && ( big == LLONG_MAX || big == LLONG_MIN ) ) {
      croak( "For key '%s', Math::BigInt '%s' can't fit into a 64-bit integer", key, str );
    }
    else {
      croak( "For key '%s', couldn't convert Math::BigInt '%s' to 64-bit integer", key, str );
    }
  }

  return big;
}

static SV* int64_to_math_bigint(int64_t value) {
    char buf[22];
    SV *class;
    SV *as_str;
    SV *bigint;

    sprintf(buf, "%" PRIi64, value);
    as_str = sv_2mortal(newSVpv(buf,strlen(buf)));
    class = sv_2mortal(newSVpvs("Math::BigInt"));
    bigint = call_method_va(class, "new", 1, as_str);
    return bigint;
}

/**
 * checks if a ptr has been parsed already and, if not, adds it to the stack. If
 * we do have a circular ref, this function returns 0.
 */
static stackette*
check_circular_ref(void *ptr, stackette *stack) {
  stackette *ette, *start = stack;

  while (stack) {
    if (ptr == stack->ptr) {
      return 0;
    }
    stack = stack->prev;
  }

  /* push this onto the circular ref stack */
  Newx(ette, 1, stackette);
  ette->ptr = ptr;
  /* if stack has not been initialized, stack will be 0 so this will work out */
  ette->prev = start;

  return ette;
}

/**
 * Given an object SV, finds the first superclass in reverse mro order that
 * starts with "BSON::" and returns it as a mortal SV.  Otherwise, returns
 * NULL if no such type is found.
 */
static SV*
bson_parent_type(SV* sv) {
  SV** handle;
  AV* mro;
  int i;

  if (! SvOBJECT(sv)) {
    return NULL;
  }

  mro = mro_get_linear_isa(SvSTASH(sv));

  if (av_len(mro) == -1) {
    return NULL;
  }
  /* iterate backwards */
  for ( i=av_len(mro); i >= 0; i-- ) {
    handle = av_fetch(mro, i, 0);
    if (handle != NULL) {
      char* klass = SvPV_nolen(*handle);
      if (strnEQ(klass, "BSON::", 6)) {
        return sv_2mortal(newSVpvn(klass,strlen(klass)));
      }
    }
  }
  return NULL;
}

/********************************************************************
 * BSON decoding
 ********************************************************************/

static SV *
bson_doc_to_hashref(bson_iter_t * iter, HV *opts, int depth, bool top) {
  SV **svp;
  SV *wrap;
  SV *ordered;
  SV *ret;
  HV *hv = newHV();

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  /* delegate if 'ordered' option is true */
  if ( (ordered = _hv_fetchs_sv(opts, "ordered")) && SvTRUE(ordered) ) {
    return bson_doc_to_tiedhash(iter, opts, depth, top);
  }

  int is_dbref = 1;
  int key_num  = 0;

  while (bson_iter_next(iter)) {
    const char *name;
    SV *value;

    name = bson_iter_key(iter);

    if ( ! is_utf8_string((const U8*)name,strlen(name))) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    key_num++;
    /* check if this is a DBref. We must see the keys
       $ref, $id, and optionally $db in that order, with no extra keys */
    if ( key_num == 1 && strcmp( name, "$ref" ) ) is_dbref = 0;
    if ( key_num == 2 && is_dbref == 1 && strcmp( name, "$id" ) ) is_dbref = 0;

    /* get value and store into hash */
    value = bson_elem_to_sv(iter, name, opts, depth);
    if (!hv_store (hv, name, 0-strlen(name), value, 0)) {
      croak ("failed storing value in hash");
    }
  }

  ret = newRV_noinc ((SV *)hv);

  /* XXX shouldn't need to limit to size 3 */
  if ( ! top && key_num >= 2 && is_dbref == 1
      && (wrap = _hv_fetchs_sv(opts, "wrap_dbrefs")) && SvTRUE(wrap)
  ) {
    SV *class = sv_2mortal(newSVpvs("BSON::DBRef"));
    SV *dbref = call_method_va(class, "new", 1, sv_2mortal(ret) );
    return dbref;
  }

  depth--;
  return ret;
}

static SV *
bson_doc_to_tiedhash(bson_iter_t * iter, HV *opts, int depth, bool top) {
  SV **svp;
  SV *wrap;
  SV *ret;
  SV *ixhash;
  SV *tie;
  SV *key;
  HV *hv = newHV();

  int is_dbref = 1;
  int key_num  = 0;

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  ixhash = new_object_from_pairs("Tie::IxHash",NULL);

  while (bson_iter_next(iter)) {
    const char *name;
    SV *value;

    name = bson_iter_key(iter);

    if ( ! is_utf8_string((const U8*)name,strlen(name))) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    key_num++;
    /* check if this is a DBref. We must see the keys
       $ref, $id, and optionally $db in that order, with no extra keys */
    if ( key_num == 1 && strcmp( name, "$ref" ) ) is_dbref = 0;
    if ( key_num == 2 && is_dbref == 1 && strcmp( name, "$id" ) ) is_dbref = 0;

    /* get key and value and store into hash */
    key = sv_2mortal( newSVpvn(name, strlen(name)) );
    SvUTF8_on(key);
    value = bson_elem_to_sv(iter, name, opts, depth);
    call_method_va(ixhash, "STORE", 2, key, value);
  }

  /* tie the ixhash to the return hash */
  sv_magic((SV*) hv, ixhash, PERL_MAGIC_tied, NULL, 0);
  ret = newRV_noinc((SV*) hv);

  /* XXX shouldn't need to limit to size 3 */
  if ( !top && key_num >= 2 && is_dbref == 1
      && (wrap = _hv_fetchs_sv(opts, "wrap_dbrefs")) && SvTRUE(wrap)
  ) {
    SV *class = sv_2mortal(newSVpvs("BSON::DBRef"));
    SV *dbref = call_method_va(class, "new", 1, ret );
    return dbref;
  }

  depth--;
  return ret;
}

static SV *
bson_array_to_arrayref(bson_iter_t * iter, HV *opts, int depth) {
  AV *ret = newAV ();

  depth++;
  if ( depth > MAX_DEPTH ) {
    croak("Exceeded max object depth of %d", MAX_DEPTH);
  }

  while (bson_iter_next(iter)) {
    SV *sv;
    const char *name = bson_iter_key(iter);

    /* get value */
    if ((sv = bson_elem_to_sv(iter, name, opts, depth))) {
      av_push (ret, sv);
    }
  }

  depth--;
  return newRV_noinc ((SV *)ret);
}

static SV *
bson_elem_to_sv (const bson_iter_t * iter, const char *key, HV *opts, int depth) {
  SV **svp;
  SV *value = 0;

  switch(bson_iter_type(iter)) {
  case BSON_TYPE_OID: {
    value = bson_oid_to_sv(iter);
    break;
  }
  case BSON_TYPE_DOUBLE: {
    SV *tempsv;
    SV *d = newSVnv(bson_iter_double(iter));

    /* Check for Inf and NaN */
    if (Perl_isinf(SvNV(d)) || Perl_isnan(SvNV(d)) ) {
      SvPV_nolen(d); /* force to PVNV for compatibility */
    }

    if ( (tempsv = _hv_fetchs_sv(opts, "wrap_numbers")) && SvTRUE(tempsv) ) {
      value = new_object_from_pairs("BSON::Double", "value", sv_2mortal(d), NULL);
    }
    else {
      value = d;
    }
    break;
  }
  case BSON_TYPE_SYMBOL:
  case BSON_TYPE_UTF8: {
    SV *wrap;
    SV *s;
    const char * str;
    uint32_t len;

    if (bson_iter_type(iter) == BSON_TYPE_SYMBOL) {
      str = bson_iter_symbol(iter, &len);
    } else {
      str = bson_iter_utf8(iter, &len);
    }

    if ( ! is_utf8_string((const U8*)str,len)) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    /* this makes a copy of the buffer */
    /* len includes \0 */
    s = newSVpvn(str, len);
    SvUTF8_on(s);

    if ( (wrap = _hv_fetchs_sv(opts, "wrap_strings")) && SvTRUE(wrap) ) {
      value = new_object_from_pairs("BSON::String", "value", sv_2mortal(s), NULL);
    }
    else {
      value = s;
    }

    break;
  }
  case BSON_TYPE_DOCUMENT: {
    bson_iter_t child;
    bson_iter_recurse(iter, &child);

    value = bson_doc_to_hashref(&child, opts, depth, FALSE);

    break;
  }
  case BSON_TYPE_ARRAY: {
    bson_iter_t child;
    bson_iter_recurse(iter, &child);

    value = bson_array_to_arrayref(&child, opts, depth);

    break;
  }
  case BSON_TYPE_BINARY: {
    const char * buf;
    uint32_t len;
    bson_subtype_t type;
    bson_iter_binary(iter, &type, &len, (const uint8_t **)&buf);

    if ( BSON_UNLIKELY(type == BSON_SUBTYPE_BINARY_DEPRECATED) ) {
      /* for the deprecated subtype, bson_iter_binary gives
       * buffer pointer just past the inner length and adjusted len */
      int32_t sublen;
      Copy(buf-4, &sublen, 1, int32_t);
      sublen = BSON_UINT32_FROM_LE(sublen);

      /* adjusted len must match sublen */
      if ( sublen != len ) {
        croak("key '%s' (binary subtype 0x02) is invalid", key);
      }
    }

    value = new_object_from_pairs(
        "BSON::Bytes",
        "data", sv_2mortal(newSVpvn(buf, len)),
        "subtype", sv_2mortal(newSViv(type)),
        NULL
    );

    break;
  }
  case BSON_TYPE_BOOL: {
    value = bson_iter_bool(iter)
      ? newSVsv(get_sv("BSON::XS::_boolean_true", GV_ADD))
      : newSVsv(get_sv("BSON::XS::_boolean_false", GV_ADD));
    break;
  }
  case BSON_TYPE_UNDEFINED:
  case BSON_TYPE_NULL: {
    value = newSV(0);
    break;
  }
  case BSON_TYPE_INT32: {
    SV *tempsv;
    SV *i = newSViv(bson_iter_int32(iter));
    if ( (tempsv = _hv_fetchs_sv(opts, "wrap_numbers")) && SvTRUE(tempsv) ) {
      value = new_object_from_pairs("BSON::Int32", "value", sv_2mortal(i), NULL);
    }
    else {
      value = i;
    }
    break;
  }
  case BSON_TYPE_INT64: {
    SV *tempsv;
#if defined(MONGO_USE_64_BIT_INT)
    SV *i = newSViv(bson_iter_int64(iter));
    if ( (tempsv = _hv_fetchs_sv(opts, "wrap_numbers")) && SvTRUE(tempsv) ) {
      value = new_object_from_pairs("BSON::Int64", "value", sv_2mortal(i), NULL);
    }
    else {
      value = i;
    }
#else
    SV *bigint = int64_to_math_bigint(bson_iter_int64(iter));
    if ( (tempsv = _hv_fetchs_sv(opts, "wrap_numbers")) && SvTRUE(tempsv) ) {
      value = new_object_from_pairs("BSON::Int64", "value", sv_2mortal(bigint), NULL);
    }
    else {
      value = bigint;
    }
#endif
    break;
  }
  case BSON_TYPE_DATE_TIME: {
    const int64_t msec = bson_iter_date_time(iter);
    SV *obj;
    SV *temp;
    SV *dt_type_sv;


#if defined(MONGO_USE_64_BIT_INT)
    obj = new_object_from_pairs("BSON::Time", "value", sv_2mortal(newSViv(msec)), NULL);
#else
    obj = new_object_from_pairs("BSON::Time", "value", sv_2mortal(int64_to_math_bigint(msec)), NULL);
#endif

    if ( (dt_type_sv = _hv_fetchs_sv(opts, "dt_type")) && SvOK(dt_type_sv) ) {
      char *dt_type = SvPV_nolen(dt_type_sv);
      if ( strEQ(dt_type, "BSON::Time") ) {
          /* already BSON::Time */
          value = obj;
      } else if ( strEQ(dt_type, "Time::Moment") ) {
          value = call_perl_reader(sv_2mortal(obj),"as_time_moment");
      } else if ( strEQ(dt_type, "DateTime") ) {
          value = call_perl_reader(sv_2mortal(obj),"as_datetime");
      } else if ( strEQ(dt_type, "DateTime::Tiny") ) {
          value = call_perl_reader(sv_2mortal(obj),"as_datetime_tiny");
      } else if ( strEQ(dt_type, "Mango::BSON::Time") ) {
          value = call_perl_reader(sv_2mortal(obj),"as_mango_time");
      } else {
          croak( "unsupported dt_type \"%s\"", dt_type );
      }
    }
    else {
      value = obj;
    }

    break;
  }
  case BSON_TYPE_REGEX: {
    const char * regex_str;
    const char * options;
    regex_str = bson_iter_regex(iter, &options);

    /* always make a BSON::Regex object instead of a native Perl
     * regexp to prevent the risk of compilation failure as well as
     * security risks compiling unknown regular expressions. */

    value = new_object_from_pairs(
      "BSON::Regex",
      "pattern", sv_2mortal(newSVpv(regex_str,0)),
      "flags", sv_2mortal(newSVpv(options,0)),
      NULL
    );
    break;
  }
  case BSON_TYPE_CODE: {
    const char * code;
    uint32_t len;
    SV *code_sv;

    code = bson_iter_code(iter, &len);

    if ( ! is_utf8_string((const U8*)code,len)) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    code_sv = sv_2mortal(newSVpvn(code, len));
    SvUTF8_on(code_sv);

    value = new_object_from_pairs("BSON::Code", "code", code_sv, NULL);

    break;
  }
  case BSON_TYPE_CODEWSCOPE: {
    const char * code;
    const uint8_t * scope;
    uint32_t code_len, scope_len;
    SV * code_sv;
    SV * scope_sv;
    bson_t bson;
    bson_iter_t child;

    code = bson_iter_codewscope(iter, &code_len, &scope_len, &scope);

    if ( ! is_utf8_string((const U8*)code,code_len)) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    code_sv = sv_2mortal(newSVpvn(code, code_len));
    SvUTF8_on(code_sv);

    if ( ! ( bson_init_static(&bson, scope, scope_len) && bson_iter_init(&child, &bson) ) ) {
        croak("error iterating BSON type %d\n", bson_iter_type(iter));
    }

    scope_sv = sv_2mortal(bson_doc_to_hashref(&child, opts, depth, TRUE));
    value = new_object_from_pairs("BSON::Code", "code", code_sv, "scope", scope_sv, NULL);

    break;
  }
  case BSON_TYPE_TIMESTAMP: {
    SV *sec_sv, *inc_sv;
    uint32_t sec, inc;

    bson_iter_timestamp(iter, &sec, &inc);

    sec_sv = sv_2mortal(newSVuv(sec));
    inc_sv = sv_2mortal(newSVuv(inc));

    value = new_object_from_pairs("BSON::Timestamp", "seconds", sec_sv, "increment", inc_sv, NULL);
    break;
  }
  case BSON_TYPE_MINKEY: {
    HV *stash = gv_stashpv("BSON::MinKey", GV_ADD);
    value = sv_bless(newRV_noinc((SV*)newHV()), stash);
    break;
  }
  case BSON_TYPE_MAXKEY: {
    HV *stash = gv_stashpv("BSON::MaxKey", GV_ADD);
    value = sv_bless(newRV_noinc((SV*)newHV()), stash);
    break;
  }
  case BSON_TYPE_DECIMAL128: {
    bson_decimal128_t dec;
    char bid_bytes[16];
    SV *dec_sv;

    if ( ! bson_iter_decimal128(iter, &dec) ) {
      croak("could not decode decimal128");
    }

    /* normalize to little endian regardless of native byte order */
    dec.low = BSON_UINT64_TO_LE(dec.low);
    dec.high = BSON_UINT64_TO_LE(dec.high);
    Copy(&dec.low, bid_bytes, 1, uint64_t);
    Copy(&dec.high, bid_bytes + 8, 1, uint64_t);

    dec_sv = sv_2mortal(newSVpvn(bid_bytes, 16));
    value = new_object_from_pairs("BSON::Decimal128", "bytes", dec_sv, NULL);

    break;
  }
  case BSON_TYPE_DBPOINTER: {
    uint32_t    len;
    const char  *collection;
    const       bson_oid_t *oid_ptr;
    SV *coll;
    SV *oid;

    bson_iter_dbpointer(iter, &len, &collection, &oid_ptr);

    if ( ! is_utf8_string((const U8*)collection,len)) {
      croak( "Invalid UTF-8 detected while decoding BSON" );
    }

    coll = newSVpvn(collection, len);
    SvUTF8_on(coll);

    oid = new_object_from_pairs(
      "BSON::OID", "oid", newSVpvn((const char *) oid_ptr->bytes, 12), NULL
    );

    value = new_object_from_pairs( "BSON::DBRef",
      "ref", sv_2mortal(coll), "id", sv_2mortal(oid), NULL
    );

    break;
  }
  default: {
    /* Should already have been caught during bson_validate() but in case not: */
    croak("unsupported BSON type \\x%02X for key '%s'.  Are you using the latest version of BSON::XS?", bson_iter_type(iter), key );
  }
  }
  return value;
}

static SV *
bson_oid_to_sv (const bson_iter_t * iter) {
  HV *stash, *id_hv;

  const bson_oid_t * oid = bson_iter_oid(iter);

  id_hv = newHV();
  (void)hv_stores(id_hv, "oid", newSVpvn((const char *) oid->bytes, 12));

  stash = gv_stashpv("BSON::OID", 0);
  return sv_bless(newRV_noinc((SV *)id_hv), stash);
}

MODULE = BSON::XS       PACKAGE = BSON::XS

PROTOTYPES: DISABLE

void
_decode_bson(msg, options)
        SV *msg
        SV *options

    PREINIT:
        char * data;
        bson_t bson;
        bson_iter_t iter;
        size_t error_offset;
        STRLEN length;
        HV *opts;
        uint32_t invalid_type;
        const char *invalid_key;

    PPCODE:
        data = SvPV(msg, length);
        opts = NULL;

        if ( options ) {
            if ( SvROK(options) && SvTYPE(SvRV(options)) == SVt_PVHV ) {
                opts = (HV *) SvRV(options);
            }
            else {
                croak("options must be a reference to a hash");
            }
        }

        if ( ! bson_init_static(&bson, (uint8_t *) data, length) ) {
          croak("Error reading BSON document");
        }

        if ( ! bson_validate(&bson, BSON_VALIDATE_NONE, &error_offset, &invalid_key, &invalid_type) ) {
          croak( "Invalid BSON input" );
        }

        if ( invalid_type != 0 ) {
            croak("unsupported BSON type \\x%02X for key '%s'.  Are you using the latest version of BSON::XS?", invalid_type, invalid_key );
        }

        if ( ! bson_iter_init(&iter, &bson) ) {
          croak( "Error creating BSON iterator" );
        }

        XPUSHs(sv_2mortal(bson_doc_to_hashref(&iter, opts, 0, TRUE)));

void
_encode_bson(doc, options)
        SV *doc
        SV *options
    PREINIT:
        bson_t * bson;
        HV *opts;
    PPCODE:
        opts = NULL;
        bson = bson_new();
        if ( options ) {
            if ( SvROK(options) && SvTYPE(SvRV(options)) == SVt_PVHV ) {
                opts = (HV *) SvRV(options);
            }
            else {
                croak("options must be a reference to a hash");
            }
        }
        perl_mongo_sv_to_bson(bson, doc, opts);
        XPUSHs(sv_2mortal(newSVpvn((const char *)bson_get_data(bson), bson->len)));
        bson_destroy(bson);

SV *
_generate_oid ()
    PREINIT:
        bson_oid_t boid;
    CODE:
        bson_oid_init(&boid, NULL);
        RETVAL = newSVpvn((const char *) boid.bytes, 12);
    OUTPUT:
        RETVAL
