#include "ppport.h"

## we want hv_fetch but with the U32 hash argument of hv_fetch_ent, so do it ourselves...
#ifdef hv_common_key_len
#define CXSA_HASH_FETCH(hv, key, len, hash) hv_common_key_len((hv), (key), (len), HV_FETCH_JUST_SV, NULL, (hash))
#else
#define CXSA_HASH_FETCH(hv, key, len, hash) hv_fetch(hv, key, len, 0)
#endif

#ifndef croak_xs_usage
#define croak_xs_usage(cv,msg) croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), msg)
#endif

MODULE = Class::XSAccessor        PACKAGE = Class::XSAccessor
PROTOTYPES: DISABLE


void
array_setter_init(self, ...)
    SV* self;
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    SV* newvalue = NULL; /* squelch may-be-used-uninitialized warning that doesn't apply */
    SV ** hashAssignRes;
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(array_setter);
    if (items == 2) {
      newvalue = newSVsv(ST(1));
    }
    else if (items > 2) {
      I32 i;
      AV* tmp = newAV();
      av_extend(tmp, items-1);
      for (i = 1; i < items; ++i) {
        newvalue = newSVsv(ST(i));
        if (!av_store(tmp, i-1, newvalue)) {
          SvREFCNT_dec(newvalue);
          croak("Failure to store value in array");
        }
      }
      newvalue = newRV_noinc((SV*) tmp);
    }
    else {
      croak_xs_usage(cv, "self, newvalue(s)");
    }

    if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newvalue, readfrom->hash))) {
      PUSHs(*hashAssignRes);
    }
    else {
      SvREFCNT_dec(newvalue);
      croak("Failed to write new value to hash.");
    }

void
array_setter(self, ...)
    SV* self;
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    SV* newvalue = NULL; /* squelch may-be-used-uninitialized warning that doesn't apply */
    SV ** hashAssignRes;
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items == 2) {
      newvalue = newSVsv(ST(1));
    }
    else if (items > 2) {
      I32 i;
      AV* tmp = newAV();
      av_extend(tmp, items-1);
      for (i = 1; i < items; ++i) {
        newvalue = newSVsv(ST(i));
        if (!av_store(tmp, i-1, newvalue)) {
          SvREFCNT_dec(newvalue);
          croak("Failure to store value in array");
        }
      }
      newvalue = newRV_noinc((SV*) tmp);
    }
    else {
      croak_xs_usage(cv, "self, newvalue(s)");
    }

    if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newvalue, readfrom->hash))) {
      PUSHs(*hashAssignRes);
    }
    else {
      SvREFCNT_dec(newvalue);
      croak("Failed to write new value to hash.");
    }

void
array_accessor_init(self, ...)
    SV* self;
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    SV ** hashAssignRes;
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(array_accessor);
    if (items == 1) {
      SV** svp;
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }
    else { /* writing branch */
      SV* newvalue;
      if (items == 2) {
        newvalue = newSVsv(ST(1));
      }
      else { /* items > 2 */
        I32 i;
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for (i = 1; i < items; ++i) {
          newvalue = newSVsv(ST(i));
          if (!av_store(tmp, i-1, newvalue)) {
            SvREFCNT_dec(newvalue);
            croak("Failure to store value in array");
          }
        }
        newvalue = newRV_noinc((SV*) tmp);
      }

      if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newvalue, readfrom->hash))) {
        PUSHs(*hashAssignRes);
      }
      else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
      }
    } /* end writing branch */

void
array_accessor(self, ...)
    SV* self;
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    SV ** hashAssignRes;
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items == 1) {
      SV** svp;
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }
    else { /* writing branch */
      SV* newvalue;
      if (items == 2) {
        newvalue = newSVsv(ST(1));
      }
      else { /* items > 2 */
        I32 i;
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for (i = 1; i < items; ++i) {
          newvalue = newSVsv(ST(i));
          if (!av_store(tmp, i-1, newvalue)) {
            SvREFCNT_dec(newvalue);
            croak("Failure to store value in array");
          }
        }
        newvalue = newRV_noinc((SV*) tmp);
      }

      if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newvalue, readfrom->hash))) {
        PUSHs(*hashAssignRes);
      }
      else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
      }
    } /* end writing branch */

void
_newxs_compat_setter(namesv, keysv)
    SV *namesv;
    SV *keysv;
  PREINIT:
    char *name;
    char *key;
    STRLEN namelen, keylen;
  PPCODE:
    name = SvPV(namesv, namelen);
    key = SvPV(keysv, keylen);
    /* WARNING: If this is called in your code, you're doing it WRONG! */
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(array_setter_init), key, keylen);

void
_newxs_compat_accessor(namesv, keysv)
    SV *namesv;
    SV *keysv;
  PREINIT:
    char *name;
    char *key;
    STRLEN namelen, keylen;
  PPCODE:
    name = SvPV(namesv, namelen);
    key = SvPV(keysv, keylen);
    /* WARNING: If this is called in your code, you're doing it WRONG! */
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(array_accessor_init), key, keylen);

