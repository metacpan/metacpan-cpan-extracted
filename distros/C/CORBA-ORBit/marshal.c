/* -*- mode: C; c-file-style: "bsd" -*- */

#include "errors.h"
#include "exttypes.h"
#include "interfaces.h"
#include "porbit-perl.h"
#include "types.h"

#define buf_putn giop_send_buffer_append_mem_indirect_a

static CORBA_boolean
put_short (GIOPSendBuffer *buf, SV *sv)
{
    IV iv = SvIV(sv);
    CORBA_short v = iv;

    if (v != iv) {
	warn ("CORBA::Short out of range");
	return CORBA_FALSE;
    }
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_long (GIOPSendBuffer *buf, SV *sv)
{
    IV iv = SvIV(sv);
    CORBA_long v = iv;

    if (v != iv) {
	warn ("CORBA::Long out of range");
	return CORBA_FALSE;
    }
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_ushort (GIOPSendBuffer *buf, SV *sv)
{
    IV iv = SvIV(sv);
    CORBA_unsigned_short v = iv;

    if (v != iv) {
	warn ("CORBA::UShort out of range");
	return CORBA_FALSE;
    }
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_ulong (GIOPSendBuffer *buf, SV *sv)
{
    CORBA_unsigned_long v = SvUV(sv);

    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_float (GIOPSendBuffer *buf, SV *sv)
{
    double nv = SvNV(sv);
    CORBA_float v = nv;

    /* FIXME: add a correct warnings */
    /*    if ((CORBA::Float)v != v) {
	warn ("CORBA::Float out of range");
	return CORBA_FALSE;
	}*/
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_double (GIOPSendBuffer *buf, SV *sv)
{
    CORBA_double v = SvNV(sv);
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean 
put_char (GIOPSendBuffer *buf, SV *sv)
{
    char *str;
    STRLEN len;

    str = SvPV(sv, len);

    if (len < 1) {
	warn("Character must have length >= 1");
	return CORBA_FALSE;
    }

    /* FIXME: Is null character OK?
     */
    buf_putn (buf, str, 1);
    return CORBA_TRUE;
}

static CORBA_boolean
put_boolean (GIOPSendBuffer *buf, SV *sv)
{
    CORBA_octet v = SvTRUE(sv);
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_octet (GIOPSendBuffer *buf, SV *sv)
{
    IV iv = SvIV(sv);
    CORBA_octet v = iv;

    if (v != iv) {
	warn ("CORBA::Octet out of range");
	return CORBA_FALSE;
    }

    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_longlong (GIOPSendBuffer *buf, SV *sv)
{
    dTHR;
    CORBA_long_long v = SvLLV (sv);

    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_ulonglong (GIOPSendBuffer *buf, SV *sv)
{
    dTHR;
    CORBA_unsigned_long_long v = SvULLV (sv);

    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_longdouble (GIOPSendBuffer *buf, SV *sv)
{
    dTHR;
    CORBA_long_double v = SvLDV (sv);
    
    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

 
static CORBA_boolean
put_enum (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    dTHR;
    CORBA_unsigned_long v = porbit_enum_find_member (tc, sv);

    if (v < 0) {
	warn ("Invalid enumeration value '%s'", SvPV(sv, PL_na));
	return CORBA_FALSE;
    }

    buf_putn (buf, &v, sizeof (v));
    return CORBA_TRUE;
}

static CORBA_boolean
put_struct (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    HV *hv;
    CORBA_unsigned_long i;
    
    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	warn ("Structure must be hash reference");
	return CORBA_FALSE;
    }

    hv = (HV *)SvRV(sv);

    for (i = 0; i<tc->sub_parts; i++) {
	SV **valp = hv_fetch (hv, (char *)tc->subnames[i], strlen(tc->subnames[i]), 0);
	if (!valp) {
	    warn ("Missing structure member '%s'", tc->subnames[i]);
	    return CORBA_FALSE;
	}
	
	if (!porbit_put_sv (buf, tc->subtypes[i], *valp))
	    return CORBA_FALSE;
    }

    return CORBA_TRUE;
}

static CORBA_boolean
put_sequence (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    dTHR;
    
    CORBA_unsigned_long len, i;

    /* get length, check type (FIXME: off by one???)
     */
    if (tc->subtypes[0]->kind == CORBA_tk_octet ||
	tc->subtypes[0]->kind == CORBA_tk_char) {

	len = SvCUR(sv);
    } else {
	if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
	    warn("Sequence must be array reference");
	    return CORBA_FALSE;
	}
	len = 1+av_len((AV *)SvRV(sv));
    }

    if (tc->length != 0 && len > tc->length) {
	warn("Sequence length (%d) exceeds bound (%d)", len, tc->length);
	return CORBA_FALSE;
    }

    buf_putn (buf, &len, sizeof (len));

    if (tc->subtypes[0]->kind == CORBA_tk_octet ||
	tc->subtypes[0]->kind == CORBA_tk_char) {
	
	giop_send_buffer_append_mem_indirect (buf, SvPV(sv, PL_na), len);
	
    } else {
	AV *av = (AV *)SvRV(sv);
	for (i = 0; i < len; i++)
	    if (!porbit_put_sv (buf, tc->subtypes[0], *av_fetch(av, i, 0))) 
		return CORBA_FALSE;
    }

    return CORBA_TRUE;
}

static CORBA_boolean
put_array (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    AV *av;
    CORBA_unsigned_long i;

    if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
	warn("Array argument must be array reference");
	return CORBA_FALSE;
    }

    av = (AV *)SvRV(sv);

    if (av_len(av)+1 != (I32)tc->length) {
	warn("Array argument should be of length %d, is %d", tc->length, av_len(av)+1);
	return CORBA_FALSE;
    }
	
    for (i = 0; i < tc->length; i++)
	if (!porbit_put_sv (buf, tc->subtypes[0], *av_fetch(av, i, 0))) 
	    return CORBA_FALSE;

    return CORBA_TRUE;
}

/* FIXME: decroakify this
 */
static char *
porbit_exception_repoid (SV *exception)
{
    int count;
    char *result;
  
    dSP;
    PUSHMARK(sp);
    XPUSHs(exception);
    PUTBACK;
    
    count = perl_call_method("_repoid", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)                     /* sanity check */
        croak("exception->_repoid didn't return 1 argument");
    
    result = g_strdup (POPp);
    
    PUTBACK;

    return result;
}

/* Fake up a typecode structure for marshalling system exceptions
 */

static const char *status_subnames[] = { "COMPLETED_YES", "COMPLETED_NO", "COMPLETED_MAYBE" };

static struct CORBA_TypeCode_struct status_typecode = {
   {}, CORBA_tk_enum, NULL, NULL, 0, 3, status_subnames
};

static const char *sysex_subnames[] = { "-minor", "-status" };

static CORBA_TypeCode sysex_subtypes[] = { (CORBA_TypeCode)TC_CORBA_ulong, &status_typecode };

static struct CORBA_TypeCode_struct sysex_typecode = {
    {}, CORBA_tk_except, NULL, NULL, 0, 2, sysex_subnames, sysex_subtypes
};

SV *
porbit_put_exception (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv,
		      CORBA_ExcDescriptionSeq  *exceptions)
{
    CORBA_unsigned_long i, len;
    HV *hv;
    char *repoid;

    if (sv_derived_from(sv, "CORBA::UserException")) {
	repoid = porbit_exception_repoid (sv);
	if (!repoid) {
	    warn ("Cannot get repository ID for exception");
	    return porbit_system_except ("IDL:omg.org/CORBA/INTERNAL:1.0",
					 0, CORBA_COMPLETED_MAYBE);
	}

	if (!tc && exceptions) {
	    for (i=0; i<exceptions->_length; i++) {
		if (strcmp (exceptions->_buffer[i].id, repoid) == 0) {
		    tc = exceptions->_buffer[i].type;
		    break;
		}
	    }
	}
	
	if (!tc) {
	    warn ("Attempt to throw invalid user exception");
	    g_free (repoid);
	    return porbit_system_except ("IDL:omg.org/CORBA/UNKNOWN:1.0",
					 0, CORBA_COMPLETED_MAYBE);
	}

    } else if (sv_derived_from(sv, "CORBA::SystemException")) {
	tc = &sysex_typecode;

	repoid = porbit_exception_repoid (sv);
	if (!repoid) {
	    warn ("Cannot get repository ID for exception");
	    return porbit_system_except ("IDL:omg.org/CORBA/INTERNAL:1.0",
					 0, CORBA_COMPLETED_MAYBE);
	}
	
    } else {
	warn ("Exception thrown must derive from CORBA::UserException or\n"
	      "CORBA::SystemException.");
	
	return porbit_system_except ("IDL:omg.org/CORBA/UNKNOWN:1.0",
				     0, CORBA_COMPLETED_MAYBE);
    }

    len = strlen (repoid) + 1;
    buf_putn (buf, &len, sizeof (len));
    giop_send_buffer_append_mem_indirect (buf, repoid, len);
    
    g_free (repoid);
    
    if (tc->sub_parts != 0) {
	if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV)) {
	    warn ("Exception must be hash reference");
	    return porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
					 0, CORBA_COMPLETED_MAYBE);
	}
	
	hv = (HV *)SvRV(sv);
	
	for (i = 0; i < tc->sub_parts; i++) {
	    SV **valp = hv_fetch (hv, (char *)tc->subnames[i], strlen(tc->subnames[i]), 0);
	    if (!valp) {
		warn ("Missing exception member '%s'", tc->subnames[i]);
		return porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
					     0, CORBA_COMPLETED_MAYBE);
	    }
	    
	    if (!porbit_put_sv (buf, tc->subtypes[i], *valp))
		return porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
					     0, CORBA_COMPLETED_MAYBE);
	}
    }
    
    return NULL;
}

/* This will never get used, but we supply it just in case
 */
CORBA_boolean
put_except (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    SV *error_sv = porbit_put_exception (buf, tc, sv, NULL);
    if (error_sv) {
	SvREFCNT_dec (error_sv);
	return CORBA_FALSE;
    }

    return CORBA_TRUE;
}

static CORBA_boolean
put_objref (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    CORBA_Object obj;
    PORBitIfaceInfo *info = porbit_find_interface_description (tc->repo_id);

    if (!info)
	croak ("Attempt to marshall unknown object type");
    
    if (!SvOK(sv))
	obj = CORBA_OBJECT_NIL;
    else {
	/* FIXME: This check isn't right at all if the object
	 * is of an unknown type. (Or if the type we have
	 * for the object is not the most derived type.)
	 * We should call the server side ISA and then
	 * downcast in this case?
	 */
	if (!sv_derived_from (sv, info->pkg)) {
	    warn ("Value is not a %s", info->pkg);
	    return CORBA_FALSE;
	}

	obj = (CORBA_Object)SvIV((SV*)SvRV(sv));
    }
    
    ORBit_marshal_object (buf, obj);
    return CORBA_TRUE;
}

static CORBA_boolean
put_union (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    SV *discriminator;
    AV *av;
    CORBA_long arm;
    
    if (!SvROK(sv) || 
	(SvTYPE(SvRV(sv)) != SVt_PVAV) ||
	(av_len((AV *)SvRV(sv)) != 1)) {
	warn("Union must be array reference of length 2");
	return CORBA_FALSE;
    }

    av = (AV *)SvRV(sv);
    discriminator = *av_fetch(av, 0, 0); 

    if (!porbit_put_sv (buf, tc->discriminator, discriminator))
	return CORBA_FALSE;
    
    arm = porbit_union_find_arm (tc, discriminator);
    if (arm < 0) {
	warn("discrimator branch does not match any arm, and no default arm");
	return CORBA_FALSE;
    }

    return porbit_put_sv (buf, tc->subtypes[arm], *av_fetch(av, 1, 0));
}

static CORBA_boolean
put_any (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    AV *av;
    SV *tc_sv;
    CORBA_TypeCode output_tc;
    

    if (!SvROK(sv) || 
	(SvTYPE(SvRV(sv)) != SVt_PVAV) ||
	(av_len((AV *)SvRV(sv)) != 1)) {
	warn("Any must be array reference of length 2");
	return CORBA_FALSE;
    }

    av = (AV *)SvRV(sv);
    tc_sv = *av_fetch(av, 0, 0); 

    if (!sv_isa(tc_sv, "CORBA::TypeCode")) {
	warn ("First member of any isn't a CORBA::TypeCode");
	return CORBA_FALSE;
    }

    output_tc = (CORBA_TypeCode)SvIV(SvRV(tc_sv));
    ORBit_encode_CORBA_TypeCode (output_tc, buf);
    
    return porbit_put_sv (buf, output_tc, *av_fetch (av, 1, 0));
}

static CORBA_boolean
put_alias (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    return porbit_put_sv (buf, tc->subtypes[0], sv);
}

static CORBA_boolean
put_string (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    dTHR;
    char null = '\0';
    CORBA_unsigned_long len;
    char *str = SvPV(sv, PL_na);
    
    len = SvCUR(sv);
    if (tc->length != 0 && len > tc->length) {
	warn("string too long");
	return CORBA_FALSE;
    }
    if (strlen (str) != len) {
	warn("strings may not included embedded nulls");
	return CORBA_FALSE;
    }

    len++;			/* IOP length includes NUL */
    buf_putn (buf, &len, sizeof (len));

    giop_send_buffer_append_mem_indirect (buf, str, len-1);
    giop_send_buffer_append_mem_indirect (buf, &null, 1);
    
    return CORBA_TRUE;
}

static CORBA_boolean
put_fixed (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    CORBA_octet *outbuf;
    int count;
    STRLEN len;
    char *str;
    int index, i;
    int wire_length = (tc->digits + 2) / 2;

    /* If we have an even number of digits, first half-octet is 0 */
    gboolean offset = (tc->digits % 2 == 0);

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
	   return CORBA_FALSE;
	}

	sv = POPs;

	PUTBACK;
      }

    PUSHMARK(sp);
    XPUSHs(sv);
    XPUSHs(sv_2mortal (newSViv (tc->digits)));
    XPUSHs(sv_2mortal (newSViv (tc->scale)));
    PUTBACK;

    count = perl_call_method("to_digits", G_SCALAR);

    SPAGAIN;
    
    if (count != 1) {
      warn ("CORBA::Fixed::to_digits returned %d items", count);
      while (count--)
	(void)POPs;

      PUTBACK;
      return CORBA_FALSE;
    }
    
    sv = POPs;

    str = SvPV(sv,len);

    if (len != (STRLEN)(tc->digits + 1)) {
      warn ("CORBA::Fixed::to_digits return wrong number of digits!\n");
      return CORBA_FALSE;
    }

    outbuf = g_malloc ((tc->digits + 2) / 2);

    index = 1;
    for (i = 0; i < wire_length; i++) {
	CORBA_octet c;
	
	if (i == 0 && offset)
	    c = 0;
	else
	    c = (str[index++] - '0') << 4;

	if (i == wire_length - 1)
	    c |= (str[0] == '-') ? 0xd : 0xc;
	else
	    c |= str[index++] - '0';
	
	outbuf[i] = c;
    }

    giop_send_buffer_append_mem_indirect (buf, outbuf, wire_length);
    g_free (outbuf);

    return CORBA_TRUE;
}

static CORBA_boolean
put_typecode (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    if (!sv_isa(sv, "CORBA::TypeCode")) {
	warn ("typecode isn't a CORBA::TypeCode");
	return CORBA_FALSE;
    }

    ORBit_encode_CORBA_TypeCode ((CORBA_TypeCode)SvIV(SvRV(sv)), buf);
    return CORBA_TRUE;
}

CORBA_boolean 
porbit_put_sv (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv)
{
    switch (tc->kind) {
    case CORBA_tk_null:
    case CORBA_tk_void:
        return CORBA_TRUE;
    case CORBA_tk_short:
	return put_short (buf, sv);
    case CORBA_tk_long:
	return put_long (buf, sv);
    case CORBA_tk_ushort:
	return put_ushort (buf, sv);
    case CORBA_tk_ulong:
	return put_ulong (buf, sv);
    case CORBA_tk_float:
	return put_float (buf, sv);
    case CORBA_tk_double:
	return put_double (buf, sv);
    case CORBA_tk_char:
	return put_char (buf, sv);
    case CORBA_tk_boolean:
	return put_boolean (buf, sv);
    case CORBA_tk_octet:
	return put_octet (buf, sv);
    case CORBA_tk_enum:
	return put_enum (buf, tc, sv);
    case CORBA_tk_struct:
	return put_struct (buf, tc, sv);
    case CORBA_tk_sequence:
	return put_sequence (buf, tc, sv);
    case CORBA_tk_except:
	return put_except (buf, tc, sv);
    case CORBA_tk_objref:
	return put_objref (buf, tc, sv);
    case CORBA_tk_union:
	return put_union (buf, tc, sv);
    case CORBA_tk_alias:
	return put_alias (buf, tc, sv);
    case CORBA_tk_string:
	return put_string (buf, tc, sv);
    case CORBA_tk_array:
	return put_array (buf, tc, sv);
    case CORBA_tk_longlong:
	return put_longlong (buf, sv);
    case CORBA_tk_ulonglong:
	return put_ulonglong (buf, sv);
    case CORBA_tk_longdouble:
	return put_longdouble (buf, sv);
    case CORBA_tk_TypeCode:
	return put_typecode (buf, tc, sv);
    case CORBA_tk_any:
	return put_any (buf, tc, sv);
    case CORBA_tk_fixed:
	return put_fixed (buf, tc, sv);
    case CORBA_tk_wchar:
    case CORBA_tk_wstring:
    case CORBA_tk_Principal:
    default:
	warn ("Unsupported output typecode %d\n", tc->kind);
	return CORBA_FALSE;
    }
}
