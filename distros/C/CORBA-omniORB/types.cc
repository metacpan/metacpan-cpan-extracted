/* -*- mode: C++; c-file-style: "bsd"; c-basic-offset: 4; -*- */

#include "pomni.h"
#include "exttypes.h"

// The pin table connects CORBA::Object_ptr's to the surrogate 
// Perl object. We store the objects here as IV's, not as SV's,
// since we don't hold a reference on the object, and need to
// remove them from here when reference count has dropped to zero

// Find or create a Perl object for this CORBA object.
// Takes over ownership of obj
SV *
pomni_objref_to_sv (pTHX_ CORBA::Object *obj, const char *repoid)
{
    CM_DEBUG(("pomni_objref_to_sv(%p)\n",obj));
    if (CORBA::is_nil (obj))
	// FIXME: memory leaks?
	return newSVsv(&PL_sv_undef);

    char buf[24];
    int n = sprintf(buf, "%lu", PTR2ul(obj));

    HV *pin_table = get_hv("CORBA::omniORB::_pin_table", TRUE);
    {
	SV **svp = hv_fetch (pin_table, buf, n, 0);
	if (svp) {
	    CORBA::release (obj);
	    SV *rv = newSV(0);
	    sv_setsv(rv, *svp);
	    return rv;
	}
    }

    if(!repoid)
	repoid = obj->_PR_getobj()->_mostDerivedRepoId();

    const char *classname = "CORBA::Object";
    POmniIfaceInfo *info = pomni_find_interface_description (aTHX_ repoid);
    CM_DEBUG(("converting %s objref %p to sv\n", repoid, obj));
    if (info)
	classname = (const char *)info->pkg.c_str();

    SV *rv = newSV(0);
    sv_setref_iv(rv, classname, PTR2IV((void *) obj));

    SV *weakref = newSV(0);
    sv_setsv(weakref, rv);
    sv_rvweaken(weakref);
    hv_store (pin_table, buf, n, weakref, 0);

    return rv;
}

SV *
pomni_local_objref_to_sv (pTHX_ CORBA::Object *obj,
			  const char *classname,
			  bool force)
{
    CM_DEBUG(("pomni_objref_to_sv(%p)\n",obj));
    if (CORBA::is_nil (obj))
	// FIXME: memory leaks?
	return newSVsv(&PL_sv_undef);

    char buf[24];
    int n = sprintf(buf, "%lu", PTR2ul(obj));

    HV *pin_table = get_hv("CORBA::omniORB::_pin_table", TRUE);
    {
	SV **svp = hv_fetch (pin_table, buf, n, 0);
	if (svp) {
	    CORBA::release (obj);

	    if(force && !sv_derived_from(*svp, classname)) {
		// Re-bless this reference to narrow its type
		sv_bless(*svp, gv_stashpv(classname, FALSE));
	    }

	    return newSVsv(*svp);
	}
    }

    SV *rv = newSV(0);
    sv_setref_iv(rv, classname, PTR2IV((void *) obj));

    SV *weakref = newSVsv(rv);
    sv_rvweaken(weakref);
    hv_store (pin_table, buf, n, weakref, 0);

    return rv;
}

// Removes an object from the pin table
void
pomni_objref_destroy (pTHX_ CORBA::Object *obj)
{
    char buf[24];
    int n = sprintf(buf, "%lu", PTR2ul(obj));
    
    HV *pin_table = get_hv("CORBA::omniORB::_pin_table", TRUE);
    hv_delete (pin_table, buf, n, G_DISCARD);
    CM_DEBUG(("DESTROY object reference %p\n", obj));
}

CORBA::Object_ptr
pomni_sv_to_objref (pTHX_ SV *perlobj)
{
    if (!SvOK(perlobj))
	return CORBA::Object::_nil();

    if (!sv_derived_from (perlobj, "CORBA::Object"))
	croak ("Argument is not a CORBA::Object");

    CORBA::Object_ptr result
	= (CORBA::Object_ptr) INT2PTR(void *, SvIV(SvRV(perlobj)));
    return result;
}

CORBA::Object_ptr
pomni_sv_to_local_objref (pTHX_ SV *perlobj, char *classname)
{
    if (!SvOK(perlobj))
	return CORBA::Object::_nil();

    if (!sv_derived_from (perlobj, classname))
	croak ("Argument is not a %s", classname);

    CORBA::Object_ptr result
	= (CORBA::Object_ptr) INT2PTR(void *, SvIV(SvRV(perlobj)));
    return result;
}

#ifdef MEMCHECK
void 
pomni_clear_pins(pTHX)
{
    HV *pin_table = get_hv("CORBA::omniORB::_pin_table", FALSE);
    if(!pin_table)
	return;
    hv_undef(pin_table);
}
#endif

void
pomni_clone_pins(pTHX)
{
    HV *pin_table = get_hv("CORBA::omniORB::_pin_table", FALSE);
    if(!pin_table)
	return;
    
    hv_iterinit(pin_table);
    HE *entry;
    while((entry = hv_iternext(pin_table)) != 0) {
	SV *weakref = hv_iterval(pin_table, entry);
	if(SvROK(weakref)) {
	    SV *iv = SvRV(weakref);
	    CORBA::Object_ptr obj
		= (CORBA::Object_ptr) INT2PTR(void *, SvIV(iv));
	    CM_DEBUG(("Incrementing ref count of %p\n", obj));
	    obj->_NP_incrRefCount();
	}
    }
}

// Cached DynAnyFactory
static DynamicAny::DynAnyFactory_ptr dynany_factory
  = DynamicAny::DynAnyFactory::_nil();

// Construction and decomposition of various complex types requires
// the use of DynAny instances.

static void
ensure_dynany_factory(void) {
    if(CORBA::is_nil(dynany_factory)) {
	CORBA::Object_var obj
	    = pomni_orb->resolve_initial_references("DynAnyFactory");
	dynany_factory = DynamicAny::DynAnyFactory::_narrow(obj);

	if (CORBA::is_nil(dynany_factory))
	    croak("Cannot obtain a DynAnyFactory");
    }
}

static DynamicAny::DynAny_ptr
create_dyn_any(const CORBA::Any &value) {
    ensure_dynany_factory();
    return dynany_factory->create_dyn_any(value);
}

static DynamicAny::DynAny_ptr
create_dyn_any_from_type_code(CORBA::TypeCode_ptr tc) {
    ensure_dynany_factory();
    return dynany_factory->create_dyn_any_from_type_code(tc);
}

// The rest of this file implements mapping Perl data structures
// to and from CORBA::Any objects.

// When possible we insert into Any objects using the <<= operators,
// which are standard but don't give us failure feedback. However, we
// already do most or all of the checking that omniORB will be doing
// anyways.

static bool sv_to_any   (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv);
static SV * sv_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc);

static bool
short_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    IV v = SvIV(sv);

    if ((CORBA::Short)v != v) {
	warn ("CORBA::Short out of range");
	return false;
    }
    
    *res <<= (CORBA::Short)v;
    return true;
}

static bool
long_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    IV v = SvIV(sv);

    if ((CORBA::Long)v != v) {
	warn ("CORBA::Long out of range");
	return false;
    }
    
    *res <<= (CORBA::Long)v;
    return true;
}

static bool
ushort_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    IV v = SvIV(sv);

    if ((CORBA::UShort)v != v) {
	warn ("CORBA::UShort out of range");
	return false;
    }
    
    *res <<= (CORBA::UShort)v;
    return true;
}

static bool
ulong_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    double v = SvNV(sv);

    if ((CORBA::ULong)v != v) {
	warn ("CORBA::ULong out of range");
	return false;
    }
    
    *res <<= (CORBA::ULong)v;
    return true;
}

static bool
float_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    double v = SvNV(sv);

    if ((CORBA::Float)v != v) {
	warn ("CORBA::Float out of range");
	return false;
    }
    
    *res <<= (CORBA::Float)v;
    return true;
}

static bool
double_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    double v = SvNV(sv);

    if ((CORBA::Double)v != v) {
	warn ("CORBA::Double out of range");
	return false;
    }
    
    *res <<= (CORBA::Double)v;
    return true;
}

static bool 
char_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    char *str;
    STRLEN len;

    str = SvPV(sv, len);

    if (len < 1) {
	warn("Character must have length >= 1");
	return false;
    }

    // FIXME: Is null character OK?
    
    *res <<= CORBA::Any::from_char(str[0]);
    return true;
}

static bool
boolean_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    *res <<= CORBA::Any::from_boolean(SvTRUE(sv));
    return true;
}

static bool
octet_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    CORBA::Octet v = SvIV(sv);

    if ((CORBA::Octet)v != v) {
	warn ("CORBA::Octet out of range");
	return false;
    }
    
    *res <<= CORBA::Any::from_octet(v);
    return true;
}

static bool
enum_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
    DynamicAny::DynEnum_var dynenum
	= DynamicAny::DynEnum::_narrow(dynany);

    try {
	dynenum->set_as_string(SvPV(sv, PL_na));
    } catch(DynamicAny::DynAny::InvalidValue &e) {
	warn("Invalid enumeration tag '%s' for %s",
	     SvPV(sv, PL_na), (const char *)tc->id());
	return false;
    }
    CORBA::Any_var any = dynenum->to_any();
    *res = any;
    return true;
}

static bool
struct_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	warn ("Structure must be hash reference");
	return false;
    }

    HV *hv = (HV *)SvRV(sv);

    DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
    DynamicAny::DynStruct_var dynstruct
	= DynamicAny::DynStruct::_narrow(dynany);

    do {
	CORBA::String_var name = dynstruct->current_member_name();
	SV **valp = hv_fetch (hv, (char *)name, strlen(name), 0);
	if (!valp) {
	    warn ("Missing structure member '%s'", (const char *)name);
	    return false;
	}

	DynamicAny::DynAny_var e = dynstruct->current_component();
	
	CORBA::Any val;
	CORBA::TypeCode_var t = e->type();
	if (!sv_to_any (aTHX_ &val, t, *valp))
	    return false;
	
	e->from_any(val);	
    } while(dynstruct->next());

    CORBA::Any_var any = dynstruct->to_any();
    *res = any;

    return true;
}

static bool
sequence_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::ULong len;
    CORBA::TypeCode_var content_tc = tc->content_type();

    // get length, check type (FIXME: off by one???)
    if (content_tc->kind() == CORBA::tk_octet || 
	content_tc->kind() == CORBA::tk_char) {
	len = SvCUR(sv);
    } else {
	if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
	    warn("Sequence must be array reference");
	    return false;
	}
	len = 1+av_len((AV *)SvRV(sv));
    }

    if (tc->length() != 0 && len > tc->length()) {
	warn("Sequence length (%d) exceeds bound (%d)", len, tc->length());
	return false;
    }

    if (content_tc->kind() == CORBA::tk_octet) {
	CORBA::Octet *buf = (CORBA::Octet *)SvPVbyte(sv,PL_na);
	CORBA::OctetSeq seq(tc->length() == 0 ? len : tc->length(), len,
			    buf, false);
	*res <<= seq;
    }
    else if (content_tc->kind() == CORBA::tk_char) {
	CORBA::Char *buf = (CORBA::Char *)SvPV(sv,PL_na);
	CORBA::CharSeq seq(tc->length() == 0 ? len : tc->length(), len,
			   buf, false);
	*res <<= seq;
    }
    else {
	DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
	DynamicAny::DynSequence_var dynseq
	    = DynamicAny::DynSequence::_narrow(dynany);
	
	dynseq->set_length(len);
	
	AV *av = (AV *)SvRV(sv);
	for (CORBA::ULong i = 0 ; i < len ; i++) {
	    CORBA::Any val;
	    if (!sv_to_any (aTHX_ &val, content_tc, *av_fetch(av, i, 0))) 
		return false;
	    DynamicAny::DynAny_var e = dynseq->current_component();
	    e->from_any(val);
	    dynseq->next();
	}
	
	CORBA::Any_var any = dynseq->to_any();
	*res = any;
    }

    return true;
}

static bool
array_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::ULong len = tc->length();
    CORBA::TypeCode_var content_tc = tc->content_type();

    CM_DEBUG(("array_to_any length %lu\n", len));

    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
	warn("Array argument must be array reference");
	return false;
    }

    AV *av = (AV *)SvRV(sv);

    if (av_len(av)+1 != (I32)len) {
	warn("Array argument should be of length %d, is %d", len, av_len(av)+1);
	return false;
    }

    DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
    DynamicAny::DynArray_var dynarray = DynamicAny::DynArray::_narrow(dynany);

    for (CORBA::ULong i = 0 ; i < len ; i++) {
	CM_DEBUG(("array_to_any element %lu:\n", i));
	CORBA::Any val;
	if (!sv_to_any (aTHX_ &val, content_tc, *av_fetch(av, i, 0))) 
	    return false;
	DynamicAny::DynAny_var e = dynarray->current_component();
	e->from_any(val);

	dynarray->next();
    }

    CORBA::Any_var any = dynarray->to_any();
    *res = any;

    return true;
}

static bool
except_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
    DynamicAny::DynStruct_var dynstruct
	= DynamicAny::DynStruct::_narrow(dynany);
    
    if (tc->member_count() != 0) {
	if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	    warn ("Exception must be hash reference");
	    return false;
	}
	
	HV *hv = (HV *)SvRV(sv);

	do {
	    CORBA::String_var name = dynstruct->current_member_name();
	    SV **valp = hv_fetch (hv, (char *)name, strlen(name), 0);
	    if (!valp) {
		warn ("Missing exception member '%s'", (const char *) name);
		return false;
	    }
	    
	    DynamicAny::DynAny_var e = dynstruct->current_component();
	
	    CORBA::Any val;
	    CORBA::TypeCode_var t = e->type();
	    if (!sv_to_any (aTHX_ &val, t, *valp))
	    return false;
	
	    e->from_any(val);	
	} while(dynstruct->next());
    }

    CORBA::Any_var any = dynstruct->to_any();
    *res = any;

    return true;
}

static bool
objref_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!SvOK(sv)) {
	*res <<= CORBA::Object::_nil();
	return true;
    }
    
    if (!sv_derived_from (sv, "CORBA::Object")) {
        warn ("Value is not a CORBA::Object");
	return false;
    }

    CORBA::Object_ptr obj
	= (CORBA::Object_ptr)INT2PTR(void *, SvIV(SvRV(sv)));
    const char *obj_repoid = obj->_PR_getobj()->_mostDerivedRepoId();
    const char *any_repoid = tc->id();
    CM_DEBUG(("objref_to_any, repoid=%s, any->id()=%s\n",
	      obj_repoid, any_repoid));
    if (any_repoid[0] != '\0' && !pomni_is_a(aTHX_ obj_repoid, any_repoid)) {
        warn ("Object reference (repository id %s) is not a subtype of %s",
	      obj_repoid, any_repoid);
	return false;
    }

    // CDR for an Any consists of the tc followed by the object pointer.
    cdrMemoryStream s;
    CORBA::TypeCode::marshalTypeCode(tc, s);
    CORBA::Object::_marshalObjRef(obj, s);
    *res <<= s;

    return true;
}

static bool
union_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!SvROK(sv) || 
	(SvTYPE(SvRV(sv)) != SVt_PVAV) ||
	(av_len((AV *)SvRV(sv)) != 1)) {
	warn("Union must be array reference of length 2");
	return false;
    }

    AV *av = (AV *)SvRV(sv);

    DynamicAny::DynAny_var dynany = create_dyn_any_from_type_code(tc);
    DynamicAny::DynUnion_var dynunion = DynamicAny::DynUnion::_narrow(dynany);

    CORBA::Any discriminator;
    CORBA::TypeCode_var dtype = tc->discriminator_type();
    if (!sv_to_any (aTHX_ &discriminator, dtype, *av_fetch(av, 0, 0)))
	return false;
    DynamicAny::DynAny_var nd = create_dyn_any(discriminator);
    dynunion->set_discriminator(nd);

    if(dynunion->seek(1)) {	// point at member
	DynamicAny::DynAny_var e = dynunion->current_component();
	CORBA::TypeCode_var t = e->type();
	CORBA::Any member;
	if (!sv_to_any (aTHX_ &member, t, *av_fetch(av, 1, 0)))
	    return false;
	e->from_any(member);
    }

    CORBA::Any_var any = dynunion->to_any();
    *res = any;

    return true;
}


static bool
any_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    CORBA::Any a;
    if (!pomni_any_from_sv(aTHX_ &a, sv)) {
	warn ("any isn't a CORBA::Any");
	return false;
    }
    *res <<= a;
    return true;
}

static bool
alias_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::TypeCode_var t = tc->content_type();
    return sv_to_any (aTHX_ res, t, sv);
}

static bool
string_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    *res <<= CORBA::Any::from_string(SvPV(sv, PL_na), tc->length(), false);
    return true;
}

#ifdef HAS_LongLong
static bool
longlong_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
   *res <<= (CORBA::LongLong) SvLLV (sv);
   return true;
}

static bool
ulonglong_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    *res <<= (CORBA::ULongLong) SvULLV (sv);
    return true;
}
#endif

#ifdef HAS_LongDouble
static bool
longdouble_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    *res <<= (CORBA::LongDouble) SvLDV (sv);
    return true;
}
#endif


static bool
fixed_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    int digits = tc->fixed_digits();
    int scale = tc->fixed_scale();

    int count;
    STRLEN len;
    char *str;
    dSP;

    ENTER;
    SAVETMPS;

    if (!sv_isa (sv, "CORBA::Fixed"))
      {
	PUSHMARK(SP);
	XPUSHs(sv_2mortal (newSVpv ("CORBA::Fixed", 0)));
	XPUSHs(sv);
	PUTBACK;
	count = perl_call_method("from_string", G_SCALAR|G_EVAL);
	SPAGAIN;
	
	if (SvTRUE(ERRSV)) {
	    STRLEN n_a;
	    warn("CORBA::Fixed::from_string failed: %s\n", SvPV(ERRSV, n_a));
	    POPs;
	    PUTBACK;
	    FREETMPS;
	    LEAVE;
	    return false;
	}
	else if (count != 1) {
	   warn ("CORBA::Fixed::from_string returned %d items", count);
	   while (count--)
	     (void)POPs;

	   PUTBACK;
	   FREETMPS;
	   LEAVE;
	   return false;
	}

	sv = POPs;

	PUTBACK;
      }

    PUSHMARK(SP);
    XPUSHs(sv);
    XPUSHs(sv_2mortal (newSViv (digits)));
    XPUSHs(sv_2mortal (newSViv (scale)));
    PUTBACK;
    count = perl_call_method("to_digits", G_SCALAR|G_EVAL);
    SPAGAIN;
    
    if (SvTRUE(ERRSV)) {
	STRLEN n_a;
	warn("CORBA::Fixed::to_digits failed: %s\n", SvPV(ERRSV, n_a));
	(void) POPs;

	PUTBACK;
	FREETMPS;
	LEAVE;
	return false;
    }
    else if (count != 1) {
	warn ("CORBA::Fixed::to_digits returned %d items", count);
	while (count--)
	    (void) POPs;
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	return false;
    }
    
    sv = POPs;

    str = SvPV(sv,len);

    if (len != (STRLEN)(digits + 1)) {
      warn("CORBA::Fixed::to_digits returned an incorrect number of digits!\n");
      return false;
    }

    CORBA::Octet *val = new CORBA::Octet[digits];

    for (int i = 0 ; i < digits ; i++)
      val[digits - 1 - i] = str[i+1] - '0';

    FREETMPS;
    LEAVE;

    CORBA::Fixed fixed(val, digits, scale, (str[0] == '-'));
    delete [] val;

    *res <<= CORBA::Any::from_fixed(fixed, digits, scale);
    return true;
}

static bool
typecode_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    if (!sv_isa(sv, "CORBA::TypeCode")) {
	warn ("any isn't a CORBA::TypeCode");
	return false;
    }

    CORBA::TypeCode *typecode
	= (CORBA::TypeCode *)INT2PTR(void *, SvIV(SvRV(sv)));

    *res <<= typecode;
    return true;
}

static bool 
sv_to_any (pTHX_ CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CM_DEBUG(("sv_to_any(tc->kind='%s')\n", TCKind_to_str(tc->kind())));
    switch (tc->kind()) {
    case CORBA::tk_null:
    case CORBA::tk_void:
        return true;
    case CORBA::tk_short:
	return short_to_any (aTHX_ res, sv);
    case CORBA::tk_long:
	return long_to_any (aTHX_ res, sv);
    case CORBA::tk_ushort:
	return ushort_to_any (aTHX_ res, sv);
    case CORBA::tk_ulong:
	return ulong_to_any (aTHX_ res, sv);
    case CORBA::tk_float:
	return float_to_any (aTHX_ res, sv);
    case CORBA::tk_double:
	return double_to_any (aTHX_ res, sv);
    case CORBA::tk_char:
	return char_to_any (aTHX_ res, sv);
    case CORBA::tk_boolean:
	return boolean_to_any (aTHX_ res, sv);
    case CORBA::tk_octet:
	return octet_to_any (aTHX_ res, sv);
    case CORBA::tk_enum:
	return enum_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_struct:
	return struct_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_sequence:
	return sequence_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_except:
	return except_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_objref:
	return objref_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_union:
	return union_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_any:
	return any_to_any (aTHX_ res, sv);
    case CORBA::tk_alias:
	return alias_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_string:
	return string_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_array:
	return array_to_any (aTHX_ res, tc, sv);
#ifdef HAS_LongLong
    case CORBA::tk_longlong:
	return longlong_to_any (aTHX_ res, sv);
    case CORBA::tk_ulonglong:
	return ulonglong_to_any (aTHX_ res, sv);
#endif
#ifdef HAS_LongDouble
    case CORBA::tk_longdouble:
	return longdouble_to_any (aTHX_ res, sv);
#endif
    case CORBA::tk_fixed:
	return fixed_to_any (aTHX_ res, tc, sv);
    case CORBA::tk_TypeCode:
	return typecode_to_any (aTHX_ res, sv);
    case CORBA::tk_wchar:
    case CORBA::tk_wstring:
    case CORBA::tk_Principal:
    default:
	warn ("Unsupported output typecode %s\n", TCKind_to_str(tc->kind()));
	return false;
    }
}

bool
pomni_to_any (pTHX_ CORBA::Any *res, SV *sv)
{
    CORBA::TypeCode_var tc = res->type();
    return sv_to_any (aTHX_ res, tc, sv);
}

static SV *
short_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Short v;
    *any >>= v;

    return newSViv(v);
}

static SV *
long_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Long v;
    *any >>= v;

    return newSViv(v);
}

static SV *
ushort_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::UShort v;
    *any >>= v;

    return newSViv(v);
}

static SV *
ulong_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::ULong v;
    SV *sv = newSV(0);

    *any >>= v;
    sv_setuv (sv, v);

    return sv;
}

static SV *
float_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Float v;
    *any >>= v;

    return newSVnv((double)v);
}

static SV *
double_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Double v;
    *any >>= v;

    return newSVnv(v);
}

static SV *
boolean_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Boolean v;
    *any >>= CORBA::Any::to_boolean(v);

    return newSVsv(v?&PL_sv_yes:&PL_sv_no);
}

static SV *
char_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Char v;
    *any >>= CORBA::Any::to_char(v);

    return newSVpv((char *)&v,1);
}

static SV *
octet_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Octet v;
    *any >>= CORBA::Any::to_octet(v);

    return newSViv(v);
}

static SV *
enum_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    DynamicAny::DynAny_var dynany = create_dyn_any(*any);
    DynamicAny::DynEnum_var dynenum
	= DynamicAny::DynEnum::_narrow(dynany);

    CORBA::String_var name = dynenum->get_as_string();
    CM_DEBUG(("enum_from_any %s yields %s\n", (const char *)tc->id(), (const char *)name));
    
    return newSVpv(name, 0);
}

static SV *
struct_from_any (pTHX_ CORBA::Any *any)
{
    DynamicAny::DynAny_var dynany = create_dyn_any(*any);
    DynamicAny::DynStruct_var dynstruct
	    = DynamicAny::DynStruct::_narrow(dynany);

    HV *hv = newHV();

    do {
	CORBA::String_var name = dynstruct->current_member_name();
	DynamicAny::DynAny_var cm(dynstruct->current_component());
	CORBA::Any *vp = cm->to_any();
	CORBA::TypeCode_var t = vp->type();
    
	SV *val = sv_from_any (aTHX_ vp, t);
	delete vp;
	if (!val)
	    goto error;
	hv_store (hv, (char *)name, strlen(name), val, 0);
    } while(dynstruct->next());

    return newRV_noinc((SV *)hv);

 error:
    hv_undef (hv);
    return NULL;
}

static SV *
sequence_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *res;

    CORBA::TypeCode_var content_tc = tc->content_type();

    // FIXME: Check the length of the typecode
    CM_DEBUG(("sequence_from_any %s\n", TCKind_to_str(content_tc->kind())));

    if (content_tc->kind() == CORBA::tk_octet) {
        CORBA::OctetSeq *seq;
        if (*any >>= seq) {
            res = newSV(seq->length());
            if (seq->length() > 0) {
                sv_setpvn(res, (char *) seq->get_buffer(), seq->length());
            }
        }
        else {
            return NULL;
        }
    }
    else if (content_tc->kind() == CORBA::tk_char) {
        CORBA::CharSeq *seq;
        if (*any >>= seq) {
            res = newSV(seq->length());
            if (seq->length() > 0) {
                sv_setpvn(res, (char *) seq->get_buffer(), seq->length());
            }
        }
        else {
            return NULL;
        }
    }
    else {
        DynamicAny::DynAny_var dynany = create_dyn_any(*any);
        DynamicAny::DynSequence_var dynseq
            = DynamicAny::DynSequence::_narrow(dynany);
        
        CORBA::ULong len = dynseq->get_length();
        
	AV *av = newAV();
	av_extend(av, len);
	res = newRV_noinc((SV *)av);

	for (CORBA::ULong i = 0 ; i < len ; i++) {
	    CM_DEBUG(("sequence element %lu\n", i));
	    DynamicAny::DynAny_var cm(dynseq->current_component());
	    CORBA::Any *vp = cm->to_any();
	    SV *elem = sv_from_any (aTHX_ vp, content_tc);
	    delete vp;
	    if (!elem)
		goto error;
	    av_store (av, i, elem);
	    dynseq->next();
	}
    }

    return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

static SV *
array_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *res;

    CORBA::TypeCode_var content_tc = tc->content_type();
    CORBA::ULong len = tc->length();

    CM_DEBUG(("array_from_any length %lu\n", len));

    AV *av = newAV();
    av_extend(av, len);
    res = newRV_noinc((SV *)av);

    DynamicAny::DynAny_var dynany = create_dyn_any(*any);
    DynamicAny::DynArray_var dynarray = DynamicAny::DynArray::_narrow(dynany);

    for (CORBA::ULong i = 0 ; i < len ; i++) {
	DynamicAny::DynAny_var cm(dynarray->current_component());
	CORBA::Any *vp = cm->to_any();
	SV *elem = sv_from_any (aTHX_ vp, content_tc);
	delete vp;
	if (!elem)
	    goto error;
	av_store (av, i, elem);
	dynarray->next();
    }

    return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

static SV *
except_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    const char *repoid = tc->id();
    AV *av = NULL;

    DynamicAny::DynAny_var dynany = create_dyn_any(*any);
    DynamicAny::DynStruct_var dynstruct
	= DynamicAny::DynStruct::_narrow(dynany);

    // FIXME: Should we check the unmarshalled type against the static type?

    av = newAV();

    for (CORBA::ULong i = 0; i<tc->member_count(); i++) {
	CORBA::String_var name = dynstruct->current_member_name();
	DynamicAny::DynAny_var cm(dynstruct->current_component());
	CORBA::Any *vp = cm->to_any();
	CORBA::TypeCode_var t = vp->type();
    
	SV *val = sv_from_any (aTHX_ vp, t);
	delete vp;
	if (!val)
	    goto error;

	av_push (av, newSVpv((char *)name, 0));
	av_push (av, val);

	dynstruct->next();
    }

    return pomni_user_except (aTHX_ repoid, newRV_noinc((SV *)av));

 error:
    if (av)
	av_undef (av);

    return NULL;
}

static SV *
objref_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::Object_ptr obj;

    if (!(*any >>= CORBA::Any::to_object (obj)))
	return NULL;

    return pomni_objref_to_sv (aTHX_ obj);
}

static SV *
union_from_any (pTHX_ CORBA::Any *any)
{
    DynamicAny::DynAny_var dynany = create_dyn_any(*any);
    DynamicAny::DynUnion_var dynunion = DynamicAny::DynUnion::_narrow(dynany);

    DynamicAny::DynAny_var cm(dynunion->current_component());
    CORBA::Any *dp = cm->to_any();
    CORBA::TypeCode_var t = cm->type();
    SV *discriminator = sv_from_any (aTHX_ dp, t);
    delete dp;
    if (!discriminator)
	return NULL;

    AV *av = newAV();
    av_push (av, discriminator);

    if(dynunion->next()) {
	cm = dynunion->current_component();
	t = cm->type();
	CORBA::Any *ap = cm->to_any();
	SV *res = sv_from_any (aTHX_ ap, t);
	delete ap;
	if (!res)
	    goto error;
	
	av_push (av, res);

    } else {
	av_push (av, &PL_sv_undef);
    }
    
    return newRV_noinc((SV *)av);

 error:
    av_undef (av);
    return NULL;
}

static SV *
any_from_any (pTHX_ CORBA::Any *any)
{
    const CORBA::Any *extracted;
    *any >>= extracted;
    return pomni_any_to_sv(aTHX_ *extracted);
}

static SV *
alias_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::TypeCode_var t = tc->content_type();
    return sv_from_any (aTHX_ any, t);
}

static SV *
string_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    const char *result = 0;
    SV *sv = NULL;

    if (*any >>= CORBA::Any::to_string (result, tc->length()))
	sv = newSVpv (result, 0);
    else
	abort();
    CM_DEBUG(("string_from_any yields '%s'\n", result));
    
    return sv;
}

#ifdef HAS_LongLong
static SV *
longlong_from_any (pTHX_ CORBA::Any *any)
{
    SV *sv = NULL;
    CORBA::LongLong result;

    if (*any >>= result)
	sv = ll_from_longlong (aTHX_ result);
    
    return sv;
}

static SV *
ulonglong_from_any (pTHX_ CORBA::Any *any)
{
    SV *sv = NULL;
    CORBA::ULongLong result;

    if (*any >>= result)
	sv = ull_from_ulonglong (aTHX_ result);
    
    return sv;
}
#endif

#ifdef HAS_LongDouble
static SV *
longdouble_from_any (pTHX_ CORBA::Any *any)
{
    SV *sv = NULL;
    CORBA::LongDouble result;

    if (*any >>= result)
	sv = ld_from_longdouble (aTHX_ result);
    
    return sv;
}
#endif

static SV *
fixed_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *sv = NULL;

    CORBA::UShort digits = tc->fixed_digits();
    CORBA::Short scale = tc->fixed_scale();
    CORBA::Fixed fixed;

    if (*any >>= CORBA::Any::to_fixed (fixed, digits, scale)) {
	CORBA::String_var string = fixed.NP_asString();

	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs (sv_2mortal (newSVpv ("CORBA::Fixed", 0)));
	XPUSHs (sv_2mortal (newSVpv (string, 0)));
	XPUSHs (sv_2mortal (newSViv(scale)));
	PUTBACK;

	int count = perl_call_method("from_string", G_SCALAR | G_EVAL);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
	    STRLEN n_a;
	    warn("CORBA::Fixed::from_string failed: %s\n", SvPV(ERRSV, n_a));
	    (void) POPs;
	    
	    PUTBACK;
	    FREETMPS;
	    LEAVE;
	    return NULL;
	}
	else if (count != 1) {
	    warn ("CORBA::Fixed::new returned %d items", count);
	    while (count--)
		(void)POPs;
	    
	    PUTBACK;
	    FREETMPS;
	    LEAVE;
	    return NULL;
	}

	sv = newSVsv(POPs);

	PUTBACK;

	FREETMPS;
	LEAVE;
    }
    
    return sv;
}

static SV *
typecode_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::TypeCode_ptr r;
    *any >>= r;
    r = CORBA::TypeCode::_duplicate (r);

    SV *res = newSV(0);
    return sv_setref_pv (res, "CORBA::TypeCode", (void *)r);
}

static SV *
sv_from_any (pTHX_ CORBA::Any *any, CORBA::TypeCode *tc)
{
    switch (tc->kind()) {
    case CORBA::tk_null:
	return newSVsv(&PL_sv_undef);
    case CORBA::tk_void:
	return NULL;
    case CORBA::tk_short:
	return short_from_any (aTHX_ any);
    case CORBA::tk_long:
	return long_from_any (aTHX_ any);
    case CORBA::tk_ushort:
	return ushort_from_any (aTHX_ any);
    case CORBA::tk_ulong:
	return ulong_from_any (aTHX_ any);
    case CORBA::tk_float:
	return float_from_any (aTHX_ any);
    case CORBA::tk_double:
	return double_from_any (aTHX_ any);
    case CORBA::tk_char:
	return char_from_any (aTHX_ any);
    case CORBA::tk_boolean:
	return boolean_from_any (aTHX_ any);
    case CORBA::tk_octet:
	return octet_from_any (aTHX_ any);
    case CORBA::tk_struct:
        return struct_from_any (aTHX_ any);
    case CORBA::tk_except:
        return except_from_any (aTHX_ any, tc);
    case CORBA::tk_objref:
        return objref_from_any (aTHX_ any);
    case CORBA::tk_enum:
        return enum_from_any (aTHX_ any, tc);
    case CORBA::tk_sequence:
        return sequence_from_any (aTHX_ any, tc);
    case CORBA::tk_union:
        return union_from_any (aTHX_ any);
    case CORBA::tk_any:
        return any_from_any (aTHX_ any);
    case CORBA::tk_alias:
        return alias_from_any (aTHX_ any, tc);
    case CORBA::tk_string:
	return string_from_any (aTHX_ any, tc);
    case CORBA::tk_array:
	return array_from_any (aTHX_ any, tc);
#ifdef HAS_LongLong
    case CORBA::tk_longlong:
	return longlong_from_any (aTHX_ any);
    case CORBA::tk_ulonglong:
	return ulonglong_from_any (aTHX_ any);
#endif
#ifdef HAS_LongDouble
    case CORBA::tk_longdouble:
	return longdouble_from_any (aTHX_ any);
#endif
    case CORBA::tk_fixed:
	return fixed_from_any (aTHX_ any, tc);
    case CORBA::tk_TypeCode:
	return typecode_from_any (aTHX_ any);
    case CORBA::tk_wchar:
    case CORBA::tk_wstring:
    case CORBA::tk_Principal:
    case CORBA::tk_value:
    case CORBA::tk_value_box:
    case CORBA::tk_native:
    case CORBA::tk_abstract_interface:
    default:
	return NULL;
    }
}

SV *
pomni_from_any (pTHX_ CORBA::Any *any)
{
    CORBA::TypeCode_var tc = any->type();
    return sv_from_any (aTHX_ any, tc);
}


const char* const
TCKind_to_str( CORBA::TCKind kind ) {
  static const char *const kinds[] = {
      "tk_null",
      "tk_void",
      "tk_short",
      "tk_long",
      "tk_ushort",
      "tk_ulong",
      "tk_float",
      "tk_double",
      "tk_boolean",
      "tk_char",
      "tk_octet",
      "tk_any",
      "tk_TypeCode",
      "tk_Principal",
      "tk_objref",
      "tk_struct",
      "tk_union",
      "tk_enum",
      "tk_string",
      "tk_sequence",
      "tk_array",
      "tk_alias",
      "tk_except",
      "tk_longlong",
      "tk_ulonglong",
      "tk_longdouble",
      "tk_wchar",
      "tk_wstring",
      "tk_fixed",
      "tk_value",
      "tk_value_box",
      "tk_native",
      "tk_abstract_interface",
      "tk_local_interface"
  };
  return ( kind < (CORBA::TCKind)(sizeof(kinds) / sizeof(kinds[0])) ) ?
      kinds[kind] :
      NULL;
}

// Copy an Any from a "CORBA::Any" SV
bool
pomni_any_from_sv(pTHX_ CORBA::Any *res, SV *sv)
{
    if (!sv_isa(sv, "CORBA::Any"))
	return false;

    STRLEN len;
    char *ptr = SvPV(SvRV(sv), len);
    cdrMemoryStream s(ptr, len);

    *res <<= s;
    return true;
}

// Create a "CORBA::Any" SV from an Any
SV *
pomni_any_to_sv(pTHX_ const CORBA::Any &any)
{
    cdrMemoryStream s;
    any >>= s;
    SV *res = newSV(0);
    return sv_setref_pvn (res, "CORBA::Any", (char *) s.bufPtr(), s.bufSize());
}

// Create a "DynamicAny::DynAny" SV from an DynAny
SV *
pomni_dyn_any_to_sv(pTHX_ DynamicAny::DynAny *dynany)
{
    return pomni_local_objref_to_sv
	(aTHX_ DynamicAny::DynAny::_duplicate(dynany), "DynamicAny::DynAny");
}
