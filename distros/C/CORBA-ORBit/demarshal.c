/* -*- mode: C; buf-file-style: "bsd" -*- */

#include "porbit-perl.h"
#include "errors.h"
#include "exttypes.h"
#include "globals.h"
#include "types.h"

#define RECV_BUFFER_LEFT(buf) \
 (((guchar *)buf->message_body + GIOP_MESSAGE_BUFFER(buf)->message_header.message_size) - (guchar *)buf->cur)


static CORBA_boolean
buf_getn (GIOPRecvBuffer *buf, void *dest, size_t n)
{
    buf->cur = ALIGN_ADDRESS(buf->cur, n);
    if (RECV_BUFFER_LEFT(buf) < n) {
	warn ("incomplete message received");
	return CORBA_FALSE;
    }
    
    buf->decoder(dest, (buf->cur), n);
    buf->cur = ((guchar *)buf->cur) + n;

    return CORBA_TRUE;
}

static SV *
get_short (GIOPRecvBuffer *buf)
{
    CORBA_short v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSViv(v);
    else
	return NULL;
}

static SV *
get_long (GIOPRecvBuffer *buf)
{
    CORBA_long v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSViv(v);
    else
	return NULL;
}

static SV *
get_ushort (GIOPRecvBuffer *buf)
{
    CORBA_unsigned_short v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSViv(v);
    else
	return NULL;
}

static SV *
get_ulong (GIOPRecvBuffer *buf)
{
    CORBA_unsigned_long v;

    if (buf_getn (buf, &v, sizeof (v))) {
	SV *sv = newSV(0);
	sv_setuv (sv, v);

	return sv;
    } else
	return NULL;
}

static SV *
get_float (GIOPRecvBuffer *buf)
{
    CORBA_float v;

    /* FIXME: typical ORBit float/double breakage
     */
    if (buf_getn (buf, &v, sizeof (v)))
	return newSVnv((double)v);
    else
	return NULL;
}

static SV *
get_double (GIOPRecvBuffer *buf)
{
    CORBA_double v;

    /* FIXME: typical ORBit float/double breakage
     */
    if (buf_getn (buf, &v, sizeof (v)))
	return newSVnv(v);
    else
	return NULL;
}

static SV *
get_boolean (GIOPRecvBuffer *buf)
{
    CORBA_octet v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSVsv(v?&PL_sv_yes:&PL_sv_no);
    else
	return NULL;
}

static SV *
get_char (GIOPRecvBuffer *buf)
{
    CORBA_char v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSVpv((char *)&v,1);
    else
	return NULL;
}

static SV *
get_octet (GIOPRecvBuffer *buf)
{
    CORBA_octet v;

    if (buf_getn (buf, &v, sizeof (v)))
	return newSViv(v);
    else
	return NULL;
}

static SV *
get_longlong (GIOPRecvBuffer *buf)
{
    CORBA_long_long v;

    if (buf_getn (buf, &v, sizeof (v)))
	return ll_from_longlong (v);
    else
	return NULL;
}

static SV *
get_ulonglong (GIOPRecvBuffer *buf)
{
    CORBA_unsigned_long_long v;

    if (buf_getn (buf, &v, sizeof (v)))
	return ull_from_ulonglong (v);
    else
	return NULL;
}

static SV *
get_longdouble (GIOPRecvBuffer *buf)
{
    CORBA_long_double v;

    /* FIXME: typical ORBit float/double breakage
     */
    if (buf_getn (buf, &v, sizeof (v)))
	return ld_from_longdouble (v);
    else
	return NULL;
}

static SV *
get_enum (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_unsigned_long v;
    
    if (!buf_getn (buf, &v, sizeof (v)))
	return NULL;

    if (v > tc->sub_parts) {
	warn ("enumeration received with invalid value");
	return NULL;
    }
	
    return newSVpv((char *)tc->subnames[v], 0);
}

static SV *
get_struct (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_unsigned_long i;
    
    HV *hv = newHV();

    for (i = 0; i < tc->sub_parts; i++) {
	SV *val = porbit_get_sv (buf, tc->subtypes[i]);
	if (!val)
	    goto error;
	hv_store (hv, (char *)tc->subnames[i], strlen(tc->subnames[i]), val, 0);
    }
    return newRV_noinc((SV *)hv);

 error:
    hv_undef (hv);
    return NULL;
}

static SV *
get_sequence (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_unsigned_long len, i;
    char *strbuf;
    SV *res;

    /* FIXME: Check the length of the typecode
     */	
    
    if (!buf_getn (buf, &len, sizeof (len)))
	return NULL;

    if (tc->subtypes[0]->kind == CORBA_tk_octet ||
	tc->subtypes[0]->kind == CORBA_tk_char) {

	res = newSV(len+1);
	SvCUR_set(res, len);
	SvPOK_on (res);
	strbuf = SvPVX(res);

	memcpy (strbuf, buf->cur, len);
	buf->cur = ((guchar *)buf->cur) + len;

	/* NULL terminate it, just to be safe.
	 */
	strbuf[len] = '\0';

    } else {
	AV *av = newAV();
	av_extend(av, len);
	res = newRV_noinc((SV *)av);
	for (i = 0; i < len; i++) {
	    SV *elem = porbit_get_sv (buf, tc->subtypes[0]);
	    if (!elem)
		goto error;
	    av_store (av, i, elem);
	}
    }
    
    return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

static SV *
get_array (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_unsigned_long i;
    SV *res;
    AV *av;

    av = newAV();
    av_extend(av, tc->length);
    res = newRV_noinc((SV *)av);
    
    for (i = 0; i < tc->length; i++) {
	SV *elem = porbit_get_sv (buf, tc->subtypes[0]);
	if (!elem)
	    goto error;
	av_store (av, i, elem);
    }
    return res;

 error:
    SvREFCNT_dec (res);
    return NULL;
}

SV *
porbit_get_exception (GIOPRecvBuffer *buf, CORBA_TypeCode tc,
		      CORBA_exception_type type,
		      CORBA_OperationDescription *opr)
{
    CORBA_unsigned_long str_len, minor, completion_status;
    char *repoid;
    AV *av;

    g_return_val_if_fail (type != CORBA_NO_EXCEPTION, NULL);

    /* Get the repoid
     */
    if (!buf_getn (buf, &str_len, sizeof (str_len)))
	return NULL;

    if (*((char *)buf->cur + str_len - 1) != '\0') {
	warn ("Unterminated repository ID in exception");
	return NULL;
    }

    repoid = (char *)buf->cur;
    buf->cur += str_len;

    if (type == CORBA_USER_EXCEPTION) {
	CORBA_unsigned_long i;
	
	if (!tc && opr) {
	    for (i=0; i < opr->exceptions._length; i++) {
		if (strcmp (opr->exceptions._buffer[i].id, repoid) == 0) {
		    tc = opr->exceptions._buffer[i].type;
		    break;
		}
	    }
	}

	if (!tc) {
	    warn ("Unknown exception of type '%s' received", repoid);
	    return porbit_system_except ("IDL:omg.org/CORBA/UNKNOWN:1.0", 
					 0, CORBA_COMPLETED_MAYBE);
	}

	av = newAV();
	
	for (i = 0; i < tc->sub_parts; i++) {
	    SV *val = porbit_get_sv (buf, tc->subtypes[i]);
	    if (!val) {
		av_undef (av);
		return NULL;
	    }
	    
	    av_push (av, newSVpv(tc->subnames[i], 0));
	    av_push (av, val);
	}
	
	return porbit_user_except (repoid, newRV_noinc((SV *)av));
    } else {
	/* System exception */

	/* HACK: Older ORBit versions are buggy and omit the minor */
	buf->cur = ALIGN_ADDRESS(buf->cur, sizeof(&minor));
	if (RECV_BUFFER_LEFT(buf) >= sizeof(&completion_status) &&
	    RECV_BUFFER_LEFT(buf) < sizeof(&minor) + sizeof(&completion_status)) {
	    minor = 0;
	} else {
	    if (!buf_getn (buf, &minor, sizeof (&minor))) {
		warn ("Error demarshalling system exception");
		return NULL;
	    }
	}

	if (!buf_getn (buf, &completion_status, sizeof (&completion_status))) {
	    warn ("Error demarshalling system exception");
	    return NULL;
	}

	return porbit_system_except (repoid, minor, completion_status);
    }
}

static SV *
get_objref (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_Object obj = ORBit_demarshal_object(buf, porbit_orb);

    /* FIXME: Check type against tc? Would be expensive.
     */
    return porbit_objref_to_sv (obj);
}

static SV *
get_union (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    AV *av;
    SV *discriminator;
    CORBA_long arm;

    discriminator = porbit_get_sv (buf, tc->discriminator);
    if (!discriminator)
        return NULL;

    av = newAV();
    av_push (av, discriminator);
    
    arm = porbit_union_find_arm (tc, discriminator);

    if (arm >= 0) {
	SV *res = porbit_get_sv (buf, tc->subtypes[arm]);
	if (!res)
	    goto error;
	
	av_push (av,res);

    } else {
	av_push (av, newSVsv(&PL_sv_undef));
    }
    
    return newRV_noinc((SV *)av);

 error:
    av_undef (av);
    return NULL;
}

static SV *
get_any (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    AV *av;
    CORBA_TypeCode res_tc;
    SV *temp, *value, *result;
    HV *stash;
    
    ORBit_decode_CORBA_TypeCode(&res_tc, buf);
    CORBA_Object_duplicate((CORBA_Object)res_tc, NULL);

    av = newAV();

    temp = newSV(0);
    av_push (av, sv_setref_pv (temp, "CORBA::TypeCode", (void *)res_tc));

    value = porbit_get_sv (buf, res_tc);
    if (!value) {
	av_undef (av);
	return NULL;
    }

    av_push (av, value);

    result = newRV_noinc((SV *)av);
    stash = gv_stashpv("CORBA::Any", TRUE);
    return sv_bless (result, stash);
}

static SV *
get_alias (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    return porbit_get_sv (buf, tc->subtypes[0]);
}

static SV *
get_string (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    char *strbuf;
    SV *res = NULL;

    CORBA_unsigned_long len;

    if (!buf_getn (buf, &len, sizeof (len)))
	return NULL;

    if (tc->length != 0 && len-1 > tc->length) {
	warn ("string received is longer than typecode allows");
	return NULL;
    }

    res = newSV(len);
    SvCUR_set(res, len-1);
    SvPOK_on (res);
    strbuf = SvPVX(res);

    memcpy (strbuf, buf->cur, len);
    buf->cur += len;

    /* This should already be a NULL according to the spec
     * but we'll play it safe here.
     */
    strbuf[len-1] = '\0';

    return res;
}

static SV *
get_fixed (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    int wire_length = (tc->digits + 2) / 2;
    SV *digits_sv;
    int index, i, count;

    /* If we have an even number of digits, first half-octet is 0 */
    gboolean offset = (tc->digits % 2 == 0);

    dSP;

    if (RECV_BUFFER_LEFT (buf) < wire_length) {
	warn ("incomplete message received");
	return NULL;
    }
    
    digits_sv = newSV(tc->digits+1);
    SvCUR_set (digits_sv, tc->digits+1);
    SvPOK_on(digits_sv);

    index = 1;
    for (i = 0; i < wire_length; i++) {
        CORBA_octet c = *(char *)(buf->cur++);

	if (!(i == 0 && offset))
	    SvPVX(digits_sv)[index++] = '0' + ((c & 0xf0) >> 4);

	if (i == wire_length - 1)
	    SvPVX(digits_sv)[0] = ((c & 0xf) == 0xd) ? '-' : '+';
	else
	    SvPVX(digits_sv)[index++] = '0' + (c & 0xf);
    }

    PUSHMARK(sp);
    XPUSHs (sv_2mortal (newSVpv ("CORBA::Fixed", 0)));
    XPUSHs (sv_2mortal (digits_sv));
    XPUSHs (sv_2mortal (newSViv(tc->scale)));
    PUTBACK;

    count = perl_call_method("new", G_SCALAR);

    SPAGAIN;
	
    if (count != 1) {
	warn ("CORBA::Fixed::new returned %d items", count);
	while (count--)
	    (void)POPs;
	
	return NULL;
    }

    return newSVsv(POPs);
}

static SV *
get_typecode (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    CORBA_TypeCode res_tc;
    SV *res;

    ORBit_decode_CORBA_TypeCode(&res_tc, buf);
    CORBA_Object_duplicate((CORBA_Object)res_tc, NULL);

    res = newSV(0);
    return sv_setref_pv (res, "CORBA::TypeCode", (void *)res_tc);
}

SV *
porbit_get_sv (GIOPRecvBuffer *buf, CORBA_TypeCode tc)
{
    switch (tc->kind) {
    case CORBA_tk_null:
	return newSVsv(&PL_sv_undef);
    case CORBA_tk_void:
	return NULL;
    case CORBA_tk_short:
	return get_short (buf);
    case CORBA_tk_long:
	return get_long (buf);
    case CORBA_tk_ushort:
	return get_ushort (buf);
    case CORBA_tk_ulong:
	return get_ulong (buf);
    case CORBA_tk_float:
	return get_float (buf);
    case CORBA_tk_double:
	return get_double (buf);
    case CORBA_tk_char:
	return get_char (buf);
    case CORBA_tk_boolean:
	return get_boolean (buf);
    case CORBA_tk_octet:
	return get_octet (buf);
    case CORBA_tk_struct:
        return get_struct (buf, tc);
    case CORBA_tk_except:
	/* This should never be hit, but we implement it just in case
	 */
        return porbit_get_exception (buf, tc, CORBA_USER_EXCEPTION, NULL);
    case CORBA_tk_objref:
        return get_objref (buf, tc);
    case CORBA_tk_enum:
        return get_enum (buf, tc);
    case CORBA_tk_sequence:
        return get_sequence (buf, tc);
    case CORBA_tk_union:
        return get_union (buf, tc);
    case CORBA_tk_alias:
        return get_alias (buf, tc);
    case CORBA_tk_string:
	return get_string (buf, tc);
    case CORBA_tk_array:
	return get_array (buf, tc);
    case CORBA_tk_longlong:
	return get_longlong (buf);
    case CORBA_tk_ulonglong:
	return get_ulonglong (buf);
    case CORBA_tk_longdouble:
	return get_longdouble (buf);
    case CORBA_tk_TypeCode:
	return get_typecode (buf, tc);
    case CORBA_tk_any:
        return get_any (buf, tc);
    case CORBA_tk_fixed:
        return get_fixed (buf, tc);
    case CORBA_tk_wchar:
    case CORBA_tk_wstring:
    case CORBA_tk_Principal:
    default:
	warn ("Unsupported input typecode %d\n", tc->kind);
	return NULL;
    }
}
