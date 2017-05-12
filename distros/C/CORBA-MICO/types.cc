/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include "exttypes.h"

// A table connecting CORBA::Object_ptr's to the surrogate 
// Perl object. We store the objects here as IV's, not as SV's,
// since we don't hold a reference on the object, and need to
// remove them from here when reference count has dropped to zero
static HV *pin_table = 0;

// Find or create a Perl object for this CORBA object.
// Takes over ownership of obj
SV *
pmico_objref_to_sv (CORBA::Object *obj)
{
    if (CORBA::is_nil (obj))
	// FIXME: memory leaks?
	return newSVsv(&PL_sv_undef);

    char buf[24];
    sprintf(buf, "%ld", (IV)obj);

    if (!pin_table)
	pin_table = newHV();
    else {
	SV **svp = hv_fetch (pin_table, buf, strlen(buf), 0);
	if (svp) {
	    CORBA::release (obj);
	    return newRV_inc((SV *)SvIV(*svp));
	}
    }

    SV *result = newRV_noinc(newSViv((IV)obj));

    PMicoIfaceInfo *info = pmico_find_interface_description (obj->_repoid());
    if (info)
	sv_bless (result, gv_stashpv((char *)info->pkg.c_str(), true));
    else
	sv_bless (result, gv_stashpv("CORBA::Object", true));

    hv_store (pin_table, buf, strlen(buf), newSViv((IV)SvRV(result)), 0);

    return result;
}

// Removes an object from the pin table
void
pmico_objref_destroy (CORBA::Object *obj)
{
    char buf[24];
    sprintf(buf, "%ld", (IV)obj);
    
    hv_delete (pin_table, buf, strlen(buf), G_DISCARD);
}

CORBA::Object_ptr
pmico_sv_to_objref (SV *perlobj)
{
    if (!SvOK(perlobj))
	return CORBA::Object::_nil();

    if (!sv_derived_from (perlobj, "CORBA::Object"))
	croak ("Argument is not a CORBA::Object");

    return (CORBA::Object_ptr)SvIV((SV*)SvRV(perlobj));
}

// The rest of this file implements mapping Perl data structures
// to and from MICO's Anys.

// We insert into using the <<= operators, which are standard
// but don't give us failure feedback. We could also use
// MICO's any.insert() which have a Boolean return value. However,
// we already do most or all of the checking that MICO
// will be doing anyways.

static bool sv_to_any   (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv);
static SV * sv_from_any (CORBA::Any *any, CORBA::TypeCode *tc);

static bool
short_to_any (CORBA::Any *res, SV *sv)
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
long_to_any (CORBA::Any *res, SV *sv)
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
ushort_to_any (CORBA::Any *res, SV *sv)
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
ulong_to_any (CORBA::Any *res, SV *sv)
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
float_to_any (CORBA::Any *res, SV *sv)
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
double_to_any (CORBA::Any *res, SV *sv)
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
char_to_any (CORBA::Any *res, SV *sv)
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
boolean_to_any (CORBA::Any *res, SV *sv)
{
    *res <<= CORBA::Any::from_boolean(SvTRUE(sv));
    return true;
}

static bool
octet_to_any (CORBA::Any *res, SV *sv)
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
enum_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::Long ind = tc->member_index (SvPV(sv, PL_na));

    if (ind < 0) {
	warn ("Invalid enumeration value '%s'", SvPV(sv,PL_na));
	return false;
    }

    return (res->enum_put ((CORBA::ULong)ind));
}

static bool
struct_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	warn ("Structure must be hash reference");
	return false;
    }

    HV *hv = (HV *)SvRV(sv);

    res->struct_put_begin();
    for (CORBA::ULong i = 0; i<tc->member_count(); i++) {
	const char *name = tc->member_name(i);
	SV **valp = hv_fetch (hv, (char *)name, strlen(name), 0);
	if (!valp) {
	    warn ("Missing structure member '%s'", name);
	    return false;
	}
	
	CORBA::TypeCode_var t = tc->member_type(i);
	if (!sv_to_any (res, t, *valp))
	    return false;
    }
    return (res->struct_put_end());
}

static bool
sequence_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
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

    if (!res->seq_put_begin(len)) return false;

    if (content_tc->kind() == CORBA::tk_octet) {
	CORBA::Octet *buf = (CORBA::Octet *)SvPV(sv,PL_na);
	for (CORBA::ULong i = 0 ; i < len ; i++)
	    *res <<= CORBA::Any::from_octet(buf[i]);
    }
    else if (content_tc->kind() == CORBA::tk_char) {
	CORBA::Char *buf = (CORBA::Char *)SvPV(sv,PL_na);
	for (CORBA::ULong i = 0 ; i < len ; i++)
	    *res <<= CORBA::Any::from_char(buf[i]);
    }
    else {
	AV *av = (AV *)SvRV(sv);
	for (CORBA::ULong i = 0 ; i < len ; i++)
	    if (!sv_to_any (res, content_tc, *av_fetch(av, i, 0))) 
		return false;
    }

    return res->seq_put_end();
}

static bool
array_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::ULong len = tc->length();
    CORBA::TypeCode_var content_tc = tc->content_type();

    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
	warn("Array argument must be array reference");
	return false;
    }

    AV *av = (AV *)SvRV(sv);

    if (av_len(av)+1 != (I32)len) {
	warn("Array argument should be of length %d, is %d", len, av_len(av)+1);
	return false;
    }
	
    if (!res->array_put_begin()) return false;

    for (CORBA::ULong i = 0 ; i < len ; i++)
	if (!sv_to_any (res, content_tc, *av_fetch(av, i, 0))) 
	    return false;

    return res->array_put_end();
}

static bool
except_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!res->except_put_begin(tc->id()))
	return false;

    if (tc->member_count() != 0) {
	if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	    warn ("Exception must be hash reference");
	    return false;
	}
	
	HV *hv = (HV *)SvRV(sv);
	
	for (CORBA::ULong i = 0; i<tc->member_count(); i++) {
	    const char *name = tc->member_name(i);
	    SV **valp = hv_fetch (hv, (char *)name, strlen(name), 0);
	    if (!valp) {
		warn ("Missing exception member '%s'", name);
		return false;
	    }

	    CORBA::TypeCode_var t = tc->member_type(i);
	    if (!sv_to_any (res, t, *valp))
		return false;
	}
    }

    return (res->except_put_end());
}

static bool
objref_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    // FIXME: check inheritance

    if (!SvOK(sv)) {
	*res <<= CORBA::Any::from_object (CORBA::Object::_nil(), tc->name());
	return true;
    }
    

    if (!sv_derived_from (sv, "CORBA::Object")) {
        warn ("Value is not a CORBA::Object");
	return false;
    }

    *res <<= CORBA::Any::from_object ((CORBA::Object_ptr)SvIV((SV*)SvRV(sv)),
				      tc->name());
    return true;
}

static CORBA::Long
union_find_arm (CORBA::TypeCode_ptr tc, SV *discriminator)
{
    // Slow and steady better win the day, because that's us here

    CORBA::Long defidx = tc->default_index();
    CORBA::TypeCode_var dtype = tc->discriminator_type();
    CORBA::TCKind dkind = tc->discriminator_type()->kind();

    CORBA::Long i = 0;
    bool found = false;

    for (i = 0; ((CORBA::ULong)i)<tc->member_count(); i++) {
	if (i != defidx) {
	    CORBA::Any_var labelany = tc->member_label(i);
	    SV *label = sv_from_any (labelany, dtype);

	    switch (dkind) {
	    case CORBA::tk_short:
	    case CORBA::tk_long:
	    case CORBA::tk_ushort:
	    case CORBA::tk_ulong:
		if (SvNV(discriminator) == SvNV(label))
		    found = true;
		break;
	    case CORBA::tk_enum:
		if (sv_eq (discriminator, label))
		    found = true;
		break;
	    case CORBA::tk_boolean:
		if (!SvTRUE (discriminator) == !SvTRUE (label))
		    found = true;
		break;
	    default:
		warn ("Unsupported discriminator type %d", dkind);
	    }
	    SvREFCNT_dec (label);

	    if (found)
	        break;
	}
    }

    if (!found && defidx >= 0)
        return defidx;
    else
        return found ? i : -1;
}

static bool
union_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!res->union_put_begin())
	return false;

    if (!SvROK(sv) || 
	(SvTYPE(SvRV(sv)) != SVt_PVAV) ||
	(av_len((AV *)SvRV(sv)) != 1)) {
	warn("Union must be array reference of length 2");
	return false;
    }

    AV *av = (AV *)SvRV(sv);
    
    SV *discriminator = *av_fetch(av, 0, 0);
    CORBA::TypeCode_var dtype = tc->discriminator_type();

    if (!sv_to_any (res, dtype, discriminator))
	return false;

    CORBA::Long i = union_find_arm (tc, discriminator);

    if (i >= 0) {
	if (!res->union_put_selection(i))
	    return false;

	CORBA::TypeCode_var t = tc->member_type(i);
	if (!sv_to_any (res, t, *av_fetch(av, 1, 0)))
	    return false;
    }
    
    if (!res->union_put_end())
	return false;

    return newRV_noinc((SV *)av);
}

static bool
any_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!sv_isa(sv, "CORBA::Any")) {
	warn ("any isn't a CORBA::Any");
	return false;
    }

    CORBA::Any *any = (CORBA::Any *)SvIV(SvRV(sv));

    *res <<= *any;
    return true;
}

static bool
alias_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    CORBA::TypeCode_var t = tc->content_type();
    return sv_to_any (res, t, sv);
}

static bool
string_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    *res <<= CORBA::Any::from_string(SvPV(sv, PL_na), tc->length(), false);
    return true;
}

static bool
longlong_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
   *res <<= SvLLV (sv);
   return true;
}

static bool
ulonglong_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    *res <<= SvULLV (sv);
    return true;
}

static bool
longdouble_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    *res <<= SvLDV (sv);
    return true;
}

static bool
fixed_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    int digits = tc->fixed_digits();
    int scale = tc->fixed_scale();
    FixedBase fixed(digits, scale);
    FixedBase::FixedValue val(digits + 1);

    int count;
    STRLEN len;
    char *str;
    dSP;

    ENTER;
    SAVETMPS;

    if (!sv_isa (sv, "CORBA::Fixed"))
      {
	PUSHMARK(sp);
	XPUSHs(sv_2mortal (newSVpv ("CORBA::Fixed", 0)));
	XPUSHs(sv);
	PUTBACK;

	count = perl_call_method("from_string", G_SCALAR);

	SPAGAIN;
	
	if (count != 1) {
	   warn ("CORBA::Fixed::from_string returned %d items", count);
	   while (count--)
	     (void)POPs;

	   PUTBACK;
	   return false;
	}

	sv = POPs;

	PUTBACK;
      }

    PUSHMARK(sp);
    XPUSHs(sv);
    XPUSHs(sv_2mortal (newSViv (digits)));
    XPUSHs(sv_2mortal (newSViv (tc->fixed_scale())));
    PUTBACK;

    count = perl_call_method("to_digits", G_SCALAR);

    SPAGAIN;
    
    if (count != 1) {
      warn ("CORBA::Fixed::to_digits returned %d items", count);
      while (count--)
	(void)POPs;

      PUTBACK;
      return false;
    }
    
    sv = POPs;

    str = SvPV(sv,len);

    if (len != (STRLEN)(digits + 1)) {
      warn ("CORBA::Fixed::to_digits return wrong number of digits!\n");
      return false;
    }

    // FIXME: going through Fixed as opposed to FixedBase
    //        (as we used to do, before MICO changed) loses,
    //        since MICO just stores in integral types

    val.length (digits+1);
    val[digits] = (str[0] == '-');
    for (int i = 0 ; i < digits ; i++)
      val[i] = str[i+1] - '0';

    fixed.from_digits (val);
    
    *res <<= CORBA::Any::from_fixed (fixed, digits, scale);
    return true;
}

static bool
typecode_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    if (!sv_isa(sv, "CORBA::TypeCode")) {
	warn ("any isn't a CORBA::TypeCode");
	return false;
    }

    CORBA::TypeCode *typecode = (CORBA::TypeCode *)SvIV(SvRV(sv));

    *res <<= typecode;
    return true;
}

static bool 
sv_to_any (CORBA::Any *res, CORBA::TypeCode *tc, SV *sv)
{
    switch (tc->kind()) {
    case CORBA::tk_null:
    case CORBA::tk_void:
        return true;
    case CORBA::tk_short:
	return short_to_any (res, sv);
    case CORBA::tk_long:
	return long_to_any (res, sv);
    case CORBA::tk_ushort:
	return ushort_to_any (res, sv);
    case CORBA::tk_ulong:
	return ulong_to_any (res, sv);
    case CORBA::tk_float:
	return float_to_any (res, sv);
    case CORBA::tk_double:
	return double_to_any (res, sv);
    case CORBA::tk_char:
	return char_to_any (res, sv);
    case CORBA::tk_boolean:
	return boolean_to_any (res, sv);
    case CORBA::tk_octet:
	return octet_to_any (res, sv);
    case CORBA::tk_enum:
	return enum_to_any (res, tc, sv);
    case CORBA::tk_struct:
	return struct_to_any (res, tc, sv);
    case CORBA::tk_sequence:
	return sequence_to_any (res, tc, sv);
    case CORBA::tk_except:
	return except_to_any (res, tc, sv);
    case CORBA::tk_objref:
	return objref_to_any (res, tc, sv);
    case CORBA::tk_union:
	return union_to_any (res, tc, sv);
    case CORBA::tk_any:
	return any_to_any (res, tc, sv);
    case CORBA::tk_alias:
	return alias_to_any (res, tc, sv);
    case CORBA::tk_string:
	return string_to_any (res, tc, sv);
    case CORBA::tk_array:
	return array_to_any (res, tc, sv);
    case CORBA::tk_longlong:
	return longlong_to_any (res, tc, sv);
    case CORBA::tk_ulonglong:
	return ulonglong_to_any (res, tc, sv);
    case CORBA::tk_longdouble:
	return longdouble_to_any (res, tc, sv);
    case CORBA::tk_fixed:
	return fixed_to_any (res, tc, sv);
    case CORBA::tk_TypeCode:
	return typecode_to_any (res, tc, sv);
    case CORBA::tk_wchar:
    case CORBA::tk_wstring:
    case CORBA::tk_Principal:
    default:
	warn ("Unsupported output typecode %d\n", tc->kind());
	return false;
    }
}

bool
pmico_to_any (CORBA::Any *res, SV *sv)
{
    return sv_to_any (res, res->type(), sv);
}

static SV *
short_from_any (CORBA::Any *any)
{
    CORBA::Short v;
    *any >>= v;

    return newSViv(v);
}

static SV *
long_from_any (CORBA::Any *any)
{
    CORBA::Long v;
    *any >>= v;

    return newSViv(v);
}

static SV *
ushort_from_any (CORBA::Any *any)
{
    CORBA::UShort v;
    *any >>= v;

    return newSViv(v);
}

static SV *
ulong_from_any (CORBA::Any *any)
{
    CORBA::ULong v;
    SV *sv = newSV(0);

    *any >>= v;
    sv_setuv (sv, v);

    return sv;
}

static SV *
float_from_any (CORBA::Any *any)
{
    CORBA::Float v;
    *any >>= v;

    return newSVnv((double)v);
}

static SV *
double_from_any (CORBA::Any *any)
{
    CORBA::Double v;
    *any >>= v;

    return newSVnv(v);
}

static SV *
boolean_from_any (CORBA::Any *any)
{
    CORBA::Boolean v;
    *any >>= CORBA::Any::to_boolean(v);

    return newSVsv(v?&PL_sv_yes:&PL_sv_no);
}

static SV *
char_from_any (CORBA::Any *any)
{
    CORBA::Char v;
    *any >>= CORBA::Any::to_char(v);

    return newSVpv((char *)&v,1);
}

static SV *
octet_from_any (CORBA::Any *any)
{
    CORBA::Octet v;
    *any >>= CORBA::Any::to_octet(v);

    return newSViv(v);
}

static SV *
enum_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::ULong ul;
    if (!any->enum_get (ul))
      return NULL;
    
    return newSVpv((char *)tc->member_name(ul), 0);
}

static SV *
struct_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    if (!any->struct_get_begin())
	return NULL;

    HV *hv = newHV();

    for (CORBA::ULong i = 0; i<tc->member_count(); i++) {
	const char *name = tc->member_name(i);
	CORBA::TypeCode_var t = tc->member_type(i);
	SV *val = sv_from_any (any, t);
	if (!val)
	    goto error;
	hv_store (hv, (char *)name, strlen(name), val, 0);
    }
    if (!any->struct_get_end())
	goto error;

    return newRV_noinc((SV *)hv);

 error:
    hv_undef (hv);
    return NULL;
}

static SV *
sequence_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::ULong len;
    SV *res;

    CORBA::TypeCode_var content_tc = tc->content_type();
    
    if (!any->seq_get_begin(len))
	return NULL;

    // FIXME: Check the length of the typecode
    
    if (content_tc->kind() == CORBA::tk_octet) {
	res = newSV(len);
	CORBA::Octet *buf = (CORBA::Octet *)SvPV(res,PL_na);
	SvCUR_set(res,len);
	for (CORBA::ULong i = 0 ; i < len ; i++)
	    if (!(*any >>= CORBA::Any::to_octet(buf[i]))) goto error;

    } else if (content_tc->kind() == CORBA::tk_char) {
	res = newSV(len);
	CORBA::Char *buf = (CORBA::Char *)SvPV(res,PL_na);
	SvCUR_set(res,len);
	for (CORBA::ULong i = 0 ; i < len ; i++)
	    if (!(*any >>= CORBA::Any::to_char(buf[i]))) goto error;

    } else {
	AV *av = newAV();
	av_extend(av, len);
	res = newRV_noinc((SV *)av);
	for (CORBA::ULong i = 0 ; i < len ; i++) {
	    SV *elem = sv_from_any (any, content_tc);
	    if (!elem)
		goto error;
	    av_store (av, i, elem);
	}
    }

    if (any->seq_get_end())
	return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

static SV *
array_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *res;

    CORBA::TypeCode_var content_tc = tc->content_type();
    CORBA::ULong len = tc->length();
    
    if (!any->array_get_begin())
	return NULL;

    AV *av = newAV();
    av_extend(av, len);
    res = newRV_noinc((SV *)av);
    for (CORBA::ULong i = 0 ; i < len ; i++) {
	SV *elem = sv_from_any (any, content_tc);
	if (!elem)
	    goto error;
	av_store (av, i, elem);
    }

    if (any->array_get_end())
	return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

static SV *
except_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    char *repoid;
    AV *av = NULL;

    if (!any->except_get_begin (repoid))
	return NULL;

    // FIXME: Should we check the unmarshalled type against the static type?

    av = newAV();

    for (CORBA::ULong i = 0; i<tc->member_count(); i++) {
	const char *name = tc->member_name(i);
	CORBA::TypeCode_var t = tc->member_type(i);
	SV *val = sv_from_any (any, t);
	if (!val)
	    goto error;

	av_push (av, newSVpv((char *)name, 0));
	av_push (av, val);
    }
    if (!any->except_get_end())
	goto error;

    return pmico_user_except (repoid, newRV_noinc((SV *)av));

 error:
    delete repoid;
    if (av)
	av_undef (av);

    return NULL;
}

static SV *
objref_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::Object_ptr obj;

    if (!(*any >>= CORBA::Any::to_object (obj)))
	return NULL;

    obj = CORBA::Object::_duplicate (obj);
    return pmico_objref_to_sv (obj);
}

static SV *
union_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    if (!any->union_get_begin())
	return NULL;

    // Slow and steady better win the day, because that's us here

    CORBA::TypeCode_var dtype = tc->discriminator_type();
    SV *discriminator = sv_from_any (any, dtype);
    if (!discriminator)
        return NULL;

    AV *av = newAV();
    av_push (av, discriminator);
    
    CORBA::Long i = union_find_arm (tc, discriminator);

    if (i >=  0) {
	if (!any->union_get_selection(i))
	    goto error;

	CORBA::TypeCode_var t = tc->member_type(i);
	SV *res = sv_from_any (any, t);
	if (!res)
	    goto error;
	
	av_push (av,res);

    } else {
	av_push (av, &PL_sv_undef);
    }
    
    if (!any->union_get_end())
	goto error;

    return newRV_noinc((SV *)av);

 error:
    av_undef (av);
    return NULL;
}

// FIXME: we use CORBA::Any::operator>>=(Any &a) which isn't OMG standard?
static SV *
any_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::Any *a = new CORBA::Any;
    *a = *any; //*any >>= *a;

    SV *res = newSV(0);
    return sv_setref_pv (res, "CORBA::Any", (void *)a);
}

static SV *
alias_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::TypeCode_var t = tc->content_type();
    return sv_from_any (any, t);
}

static SV *
string_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    const char *result = 0;
    SV *sv = NULL;

    if (*any >>= CORBA::Any::to_string (result, tc->length()))
	sv = newSVpv (result, 0);
    
    return sv;
}

static SV *
longlong_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *sv = NULL;
    CORBA::LongLong result;

    if (*any >>= result)
	sv = ll_from_longlong (result);
    
    return sv;
}

static SV *
ulonglong_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *sv = NULL;
    CORBA::ULongLong result;

    if (*any >>= result)
	sv = ull_from_ulonglong (result);
    
    return sv;
}

static SV *
longdouble_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    SV *sv = NULL;
    CORBA::LongDouble result;

    if (*any >>= result)
	sv = ld_from_longdouble (result);
    
    return sv;
}

static SV *
fixed_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    FixedBase::FixedValue_var v;
    CORBA::UShort digits = tc->fixed_digits();
    CORBA::Short scale = tc->fixed_scale();
    FixedBase fixed (digits, scale);

    SV *sv = NULL;

    // FIXME: going through Fixed as opposed to FixedBase
    //        (as we used to do, before MICO changed) loses,
    //         since MICO just stores in integral types
    if (*any >>= CORBA::Any::to_fixed (fixed, digits, scale)) {

	v = fixed.to_digits();

	int i;
	SV *tsv = newSV(digits+1);
	SvCUR_set (tsv, digits+1);
	SvPVX(tsv)[0] = (*v)[digits] ? '-' : '+';
	for (i = 0 ; i < digits ; i++)
	    SvPVX(tsv)[i+1] = '0' + (*v)[i];
	SvPVX(tsv)[i+1] = '\0';
	SvPOK_on(tsv);

	dSP;
	PUSHMARK(sp);
	XPUSHs (sv_2mortal (newSVpv ("CORBA::Fixed", 0)));
	XPUSHs (sv_2mortal (tsv));
	XPUSHs (sv_2mortal (newSViv(scale)));
	PUTBACK;

	int count = perl_call_method("new", G_SCALAR);

	SPAGAIN;
	
	if (count != 1) {
	   warn ("CORBA::Fixed::new returned %d items", count);
	   while (count--)
	     (void)POPs;

	   return NULL;
	}

	sv = newSVsv(POPs);

	PUTBACK;
    }
    
    return sv;
}

static SV *
typecode_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    CORBA::TypeCode_ptr r;
    *any >>= r;
    r = CORBA::TypeCode::_duplicate (r);

    SV *res = newSV(0);
    return sv_setref_pv (res, "CORBA::TypeCode", (void *)r);
}

static SV *
sv_from_any (CORBA::Any *any, CORBA::TypeCode *tc)
{
    switch (tc->kind()) {
    case CORBA::tk_null:
	return newSVsv(&PL_sv_undef);
    case CORBA::tk_void:
	return NULL;
    case CORBA::tk_short:
	return short_from_any (any);
    case CORBA::tk_long:
	return long_from_any (any);
    case CORBA::tk_ushort:
	return ushort_from_any (any);
    case CORBA::tk_ulong:
	return ulong_from_any (any);
    case CORBA::tk_float:
	return float_from_any (any);
    case CORBA::tk_double:
	return double_from_any (any);
    case CORBA::tk_char:
	return char_from_any (any);
    case CORBA::tk_boolean:
	return boolean_from_any (any);
    case CORBA::tk_octet:
	return octet_from_any (any);
    case CORBA::tk_struct:
        return struct_from_any (any, tc);
    case CORBA::tk_except:
        return except_from_any (any, tc);
    case CORBA::tk_objref:
        return objref_from_any (any, tc);
    case CORBA::tk_enum:
        return enum_from_any (any, tc);
    case CORBA::tk_sequence:
        return sequence_from_any (any, tc);
    case CORBA::tk_union:
        return union_from_any (any, tc);
    case CORBA::tk_any:
        return any_from_any (any, tc);
    case CORBA::tk_alias:
        return alias_from_any (any, tc);
    case CORBA::tk_string:
	return string_from_any (any, tc);
    case CORBA::tk_array:
	return array_from_any (any, tc);
    case CORBA::tk_longlong:
	return longlong_from_any (any, tc);
    case CORBA::tk_ulonglong:
	return ulonglong_from_any (any, tc);
    case CORBA::tk_longdouble:
	return longdouble_from_any (any, tc);
    case CORBA::tk_fixed:
	return fixed_from_any (any, tc);
    case CORBA::tk_TypeCode:
	return typecode_from_any (any, tc);
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
pmico_from_any (CORBA::Any *any)
{
    return sv_from_any (any, any->type());
}
