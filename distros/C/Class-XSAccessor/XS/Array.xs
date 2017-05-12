#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"

MODULE = Class::XSAccessor		PACKAGE = Class::XSAccessor::Array
PROTOTYPES: DISABLE

void
getter(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(getter);
    if ((svp = av_fetch((AV *)SvRV(self), index, 1)))
      PUSHs(svp[0]);
    else
      XSRETURN_UNDEF;

void
lvalue_accessor(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
    SV** svp;
    SV* sv;
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(lvalue_accessor);
    if ((svp = av_fetch((AV *)SvRV(self), index, 1))) {
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
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(setter);
    if (NULL == av_store((AV*)SvRV(self), index, newSVsv(newvalue)))
      croak("Failed to write new value to array.");
    PUSHs(newvalue);

void
chained_setter(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(chained_setter);
    if (NULL == av_store((AV*)SvRV(self), index, newSVsv(newvalue)))
      croak("Failed to write new value to array.");
    PUSHs(self);

void
accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == av_store((AV*)SvRV(self), index, newSVsv(newvalue)))
        croak("Failed to write new value to array.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = av_fetch((AV *)SvRV(self), index, 1)))
        PUSHs(svp[0]);
      else
        XSRETURN_UNDEF;
    }

void
chained_accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(chained_accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == av_store((AV*)SvRV(self), index, newSVsv(newvalue)))
        croak("Failed to write new value to array.");
      PUSHs(self);
    }
    else {
      if ((svp = av_fetch((AV *)SvRV(self), index, 1)))
        PUSHs(svp[0]);
      else
        XSRETURN_UNDEF;
    }

void
predicate(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = CXSAccessor_arrayindices[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_ARRAY(self);
    CXAA_OPTIMIZE_ENTERSUB(predicate);
    if ( (svp = av_fetch((AV *)SvRV(self), index, 1)) && SvOK(svp[0]) )
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
constructor(class, ...)
    SV* class;
  PREINIT:
    AV* array;
    SV* obj;
    const char* classname;
  PPCODE:
    CXAA_OPTIMIZE_ENTERSUB(constructor);

    classname = SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen_const(class);
    array = newAV();
    obj = sv_bless( newRV_noinc((SV*)array), gv_stashpv(classname, 1) );
    /* we ignore arguments. See Class::XSAccessor's XS code for
     * how we'd use them in case of bless {@_} => $class.
     */
    PUSHs(sv_2mortal(obj));

void
newxs_getter(namesv, index)
    SV *namesv;
    U32 index;
  ALIAS:
    Class::XSAccessor::Array::newxs_lvalue_accessor = 1
    Class::XSAccessor::Array::newxs_predicate       = 2
  PREINIT:
    char *name;
    STRLEN namelen;
  PPCODE:
    name = SvPV(namesv, namelen);
    switch (ix) {
    case 0: /* newxs_getter */
      INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(getter), index);
      break;
    case 1: /* newxs_lvalue_accessor */
      {
        CV* cv;
        INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(lvalue_accessor), index);
        /* Make the CV lvalue-able. "cv" was set by the previous macro */
        CvLVALUE_on(cv);
        break;
      }
    case 2: /* newxs_predicate */
      INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(predicate), index);
      break;
    default:
      croak("Invalid alias of newxs_getter called");
      break;
    }

void
newxs_setter(namesv, index, chained)
    SV *namesv;
    U32 index;
    bool chained;
  ALIAS:
    Class::XSAccessor::Array::newxs_accessor = 1
  PREINIT:
    char *name;
    STRLEN namelen;
  PPCODE:
    name = SvPV(namesv, namelen);
    if (ix == 0) { /* newxs_setter */
      if (chained)
        INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(chained_setter), index);
      else
        INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(setter), index);
    }
    else { /* newxs_accessor */
      if (chained)
        INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(chained_accessor), index);
      else
        INSTALL_NEW_CV_ARRAY_OBJ(name, CXAA(accessor), index);
    }

void
newxs_constructor(namesv)
    SV *namesv;
  PREINIT:
    char *name;
    STRLEN namelen;
  PPCODE:
    name = SvPV(namesv, namelen);
    INSTALL_NEW_CV(name, CXAA(constructor));
