#include "ppport.h"

## we want hv_fetch but with the U32 hash argument of hv_fetch_ent, so do it ourselves...

#ifdef hv_common_key_len

# define CXSA_HASH_FETCH(hv, key, len, hash) \
      hv_common_key_len((hv), (key), (len), HV_FETCH_JUST_SV, NULL, (hash))
# define CXSA_HASH_FETCH_LVALUE(hv, key, len, hash) \
      hv_common_key_len((hv), (key), (len), (HV_FETCH_JUST_SV|HV_FETCH_LVALUE), NULL, (hash))
# define CXSA_HASH_EXISTS(hv, key, len, hash) \
      hv_common_key_len((hv), (key), (len), HV_FETCH_ISEXISTS, NULL, (hash))

#else

# define CXSA_HASH_FETCH(hv, key, len, hash) hv_fetch((hv), (key), (len), 0)
# define CXSA_HASH_FETCH_LVALUE(hv, key, len, hash) hv_fetch((hv), (key), (len), 1)
# define CXSA_HASH_EXISTS(hv, key, len, hash) hv_exists((hv), (key), (len))

#endif


#ifndef croak_xs_usage
#define croak_xs_usage(cv,msg) croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), msg)
#endif

MODULE = Class::XSAccessor        PACKAGE = Class::XSAccessor
PROTOTYPES: DISABLE

void
getter(self)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(getter);
    if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
      PUSHs(*svp);
    else
      XSRETURN_UNDEF;

void
lvalue_accessor(self)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
    SV* sv;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(lvalue_accessor);
    if ((svp = CXSA_HASH_FETCH_LVALUE((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash))) {
      sv = *svp;
      sv_upgrade(sv, SVt_PVLV);
      sv_magic(sv, 0, PERL_MAGIC_ext, Nullch, 0);
      SvSMAGICAL_on(sv);
      LvTYPE(sv) = '~';
      SvREFCNT_inc(sv);
      LvTARG(sv) = SvREFCNT_inc(sv);
      SvMAGIC(sv)->mg_virtual = &cxsa_lvalue_acc_magic_vtable;
      ST(0) = sv;
      XSRETURN(1);
    }
    else
      XSRETURN_UNDEF;

void
setter(self, newvalue)
    SV* self;
    SV* newvalue;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(setter);
    if (NULL == hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newSVsv(newvalue), readfrom->hash))
      croak("Failed to write new value to hash.");
    PUSHs(newvalue);

void
chained_setter(self, newvalue)
    SV* self;
    SV* newvalue;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(chained_setter);
    if (NULL == hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newSVsv(newvalue), readfrom->hash))
      croak("Failed to write new value to hash.");
    PUSHs(self);

void
accessor(self, ...)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newSVsv(newvalue), readfrom->hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
chained_accessor(self, ...)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(chained_accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newSVsv(newvalue), readfrom->hash))
        croak("Failed to write new value to hash.");
      PUSHs(self);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
exists_predicate(self)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(exists_predicate);
    if ( CXSA_HASH_EXISTS((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash) != NULL )
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
defined_predicate(self)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(defined_predicate);
    if ( ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash))) && SvOK(*svp) )
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
constructor(class, ...)
    SV* class;
  PREINIT:
    int iStack;
    HV* hash;
    SV* obj;
    const char* classname;
  PPCODE:
    CXAH_OPTIMIZE_ENTERSUB(constructor);

    classname = SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen_const(class);
    hash = newHV();
    obj = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(classname, 1));

    if (items > 1) {
      /* if @_ - 1 (for $class) is even: most compilers probably convert items % 2 into this, but just in case */
      if (items & 1) {
        for (iStack = 1; iStack < items; iStack += 2) {
          /* we could check for the hv_store_ent return value, but perl doesn't in this situation (see pp_anonhash) */
          (void)hv_store_ent(hash, ST(iStack), newSVsv(ST(iStack+1)), 0);
        }
      } else {
        croak("Uneven number of arguments to constructor.");
      }
    }

    PUSHs(sv_2mortal(obj));

void
constant_false(self)
  SV *self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    CXAH_OPTIMIZE_ENTERSUB(constant_false);
    {
      XSRETURN_NO;
    }

void
constant_true(self)
    SV* self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    CXAH_OPTIMIZE_ENTERSUB(constant_true);
    {
      XSRETURN_YES;
    }

void
test(self, ...)
    SV* self;
  INIT:
    /* Get the const hash key struct from the global storage */
    const autoxs_hashkey * readfrom = CXAH_GET_HASHKEY;
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    warn("cxah: accessor: inside test");
    CXAH_OPTIMIZE_ENTERSUB_TEST(test);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom->key, readfrom->len, newSVsv(newvalue), readfrom->hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom->key, readfrom->len, readfrom->hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
newxs_getter(namesv, keysv)
    SV *namesv;
    SV *keysv;
  ALIAS:
    Class::XSAccessor::newxs_lvalue_accessor = 1
    Class::XSAccessor::newxs_predicate = 2
    Class::XSAccessor::newxs_defined_predicate = 3
    Class::XSAccessor::newxs_exists_predicate = 4
  PREINIT:
    char *name;
    char *key;
    STRLEN namelen, keylen;
  PPCODE:
    name = SvPV(namesv, namelen);
    key = SvPV(keysv, keylen);
    switch (ix) {
    case 0: /* newxs_getter */
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(getter), key, keylen);
      break;
    case 1: { /* newxs_lvalue_accessor */
        CV* cv;
        INSTALL_NEW_CV_HASH_OBJ(name, CXAH(lvalue_accessor), key, keylen);
        /* Make the CV lvalue-able. "cv" was set by the previous macro */
        CvLVALUE_on(cv);
      }
      break;
    case 2:
    case 3:
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(defined_predicate), key, keylen);
      break;
    case 4:
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(exists_predicate), key, keylen);
      break;
    default:
      croak("Invalid alias of newxs_getter called");
      break;
    }

void
newxs_setter(namesv, keysv, chained)
    SV *namesv;
    SV *keysv;
    bool chained;
  ALIAS:
    Class::XSAccessor::newxs_accessor = 1
  PREINIT:
    char *name;
    char *key;
    STRLEN namelen, keylen;
  PPCODE:
    name = SvPV(namesv, namelen);
    key = SvPV(keysv, keylen);
    if (ix == 0) { /* newxs_setter */
    if (chained)
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(chained_setter), key, keylen);
    else
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(setter), key, keylen);
    }
    else { /* newxs_accessor */
      if (chained)
        INSTALL_NEW_CV_HASH_OBJ(name, CXAH(chained_accessor), key, keylen);
      else
        INSTALL_NEW_CV_HASH_OBJ(name, CXAH(accessor), key, keylen);
    }

void
newxs_constructor(namesv)
    SV *namesv;
  PREINIT:
    char *name;
    STRLEN namelen;
  PPCODE:
    name = SvPV(namesv, namelen);
    INSTALL_NEW_CV(name, CXAH(constructor));

void
newxs_boolean(namesv, truth)
    SV *namesv;
    bool truth;
  PREINIT:
    char *name;
    STRLEN namelen;
  PPCODE:
    name = SvPV(namesv, namelen);
    if (truth)
      INSTALL_NEW_CV(name, CXAH(constant_true));
    else
      INSTALL_NEW_CV(name, CXAH(constant_false));

void
newxs_test(namesv, keysv)
    SV *namesv;
    SV *keysv;
  PREINIT:
    char *name;
    char *key;
    STRLEN namelen, keylen;
  PPCODE:
    name = SvPV(namesv, namelen);
    key = SvPV(keysv, keylen);
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(test), key, keylen);


