/* -*- mode: C; c-file-style: "bsd" -*- */

#include "interfaces.h"
#include "types.h"

/* A table connecting CORBA_Object's to the surrogate 
 * Perl object. We store the objects here as IV's, not as SV's,
 * since we don't hold a reference on the object, and need to
 * remove them from here when reference count has dropped to zero
 */
static HV *pin_table = 0;

/* Find or create a Perl object for this CORBA object.
 * Takes over ownership of obj
 */
SV *
porbit_objref_to_sv (CORBA_Object obj)
{
    char buf[24];
    SV *result;
    PORBitIfaceInfo *info;

    if (!obj)
	/* FIXME: memory leaks? */
	return newSVsv(&PL_sv_undef);

    sprintf(buf, "%ld", (IV)obj);

    if (!pin_table)
	pin_table = newHV();
    else {
	SV **svp = hv_fetch (pin_table, buf, strlen(buf), 0);
	if (svp) {
	    CORBA_Object_release (obj, NULL);
	    return newRV_inc((SV *)SvIV(*svp));
	}
    }

    result  = newRV_noinc(newSViv((IV)obj));

    info = porbit_find_interface_description (obj->object_id);
    if (info)
	sv_bless (result, gv_stashpv(info->pkg, TRUE));
    else
	sv_bless (result, gv_stashpv("CORBA::Object", TRUE));

    hv_store (pin_table, buf, strlen(buf), newSViv((IV)SvRV(result)), 0);

    return result;
}

/* Removes an object from the pin table
 */
void
porbit_objref_destroy (CORBA_Object obj)
{
    char buf[24];
    sprintf(buf, "%ld", (IV)obj);
    
    hv_delete (pin_table, buf, strlen(buf), G_DISCARD);
}

CORBA_Object
porbit_sv_to_objref (SV *perlobj)
{
    if (!SvOK(perlobj))
	return CORBA_OBJECT_NIL;

    if (!sv_derived_from (perlobj, "CORBA::Object"))
	croak ("Argument is not a CORBA::Object");

    return (CORBA_Object)SvIV((SV*)SvRV(perlobj));
}

CORBA_long
porbit_enum_find_member (CORBA_TypeCode tc, SV *val)
{
    dTHR;
    char *str = SvPV (val, PL_na);
    CORBA_unsigned_long i;

    for (i=0; i<tc->sub_parts; i++) {
	if (!strcmp (tc->subnames[i], str))
	    return i;
    }

    return -1;
}

CORBA_long
porbit_union_find_arm (CORBA_TypeCode tc, SV *discriminator)
{
    CORBA_unsigned_long i = 0;

#define FIND_MEMBER(v, TYPE) {                                                      \
	TYPE val = v;                                                               \
	for (i = 0; i<tc->sub_parts; i++) {                                         \
	    TYPE label_val = *(TYPE *)tc->sublabels[i]._value;                      \
	    if (label_val == val)                                                   \
		return i;                                                           \
	}}
       

    switch (tc->discriminator->kind) {
    case CORBA_tk_short:
	FIND_MEMBER (SvIV (discriminator), CORBA_short);
	break;
    case CORBA_tk_long:
	FIND_MEMBER (SvIV (discriminator), CORBA_long);
	break;
    case CORBA_tk_ushort:
	FIND_MEMBER (SvIV (discriminator), CORBA_unsigned_short);
	break;
    case CORBA_tk_ulong:
	FIND_MEMBER (SvUV (discriminator), CORBA_unsigned_long);
	break;
    case CORBA_tk_longlong:
	FIND_MEMBER (SvUV (discriminator), CORBA_long_long);
	break;
    case CORBA_tk_ulonglong:
	FIND_MEMBER (SvUV (discriminator), CORBA_unsigned_long_long);
	break;
    case CORBA_tk_enum:
	/* This is slow, but easy */
	FIND_MEMBER (porbit_enum_find_member (tc->discriminator, discriminator),
		     CORBA_unsigned_long);
	break;
    case CORBA_tk_boolean:
        {
	    CORBA_boolean val = SvTRUE (discriminator);
	    for (i = 0; i<tc->sub_parts; i++) {
		CORBA_boolean label_val = *(CORBA_boolean *)tc->sublabels[i]._value;
		if (!label_val == !val)
		    return i;
	    }
        }
    default:
	warn ("Unsupported discriminator type %d", tc->discriminator->kind);
    }

    return (tc->default_index >= 0) ? tc->default_index : -1;
}
    

