/* -*- mode: C; c-file-style: "bsd" -*- */

#include "errors.h"
#include "interfaces.h"
#include "server.h"
#include "types.h"

typedef struct _PORBitParam PORBitParam;

struct _PORBitParam {
    CORBA_TypeCode type;
    CORBA_ParameterMode mode;
};

/* Hackaround for breakage in some unstable versions of perl 
 */
#if (PERL_VERSION == 5) && (PERL_SUBVERSION > 57) && defined (USE_THREADS)
#  undef ERRSV
#  define ERRSV (aTHX->errsv)
#else
#  ifndef ERRSV
#    define ERRSV GvSV(errgv)
#  endif
#endif

#define INSTVARS_MAGIC 0x18981972

/* Magic (adopted from DBI) to attach InstVars invisibly to perlobj
 */
PORBitInstVars *
porbit_instvars_add (SV *perlobj) 
{
    SV *iv_sv = newSV (sizeof(PORBitInstVars));
    PORBitInstVars *iv = (PORBitInstVars *)SvPVX(iv_sv);

    SV *rv = newRV(iv_sv);	/* just needed for sv_bless */
    sv_bless (rv, gv_stashpv("CORBA::ORBit::InstVars", TRUE));
    sv_free (rv);

    iv->magic = INSTVARS_MAGIC;
    iv->servant = NULL;

    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);
    
    sv_magic (perlobj, iv_sv, '~' , Nullch, 0);
    SvREFCNT_dec (iv_sv);	/* sv_magic() incremented it */
    /* It looks from sv.c like this is now unecessary, but DBI does it
     * and it shouldn't do any harm
     */
    SvRMAGICAL_on (perlobj);

    return iv;
}

PORBitInstVars *
porbit_instvars_get (SV *perlobj) 
{
    PORBitInstVars *iv = NULL;
    
    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);

    if (SvMAGICAL (perlobj)) {
        MAGIC *mg = mg_find (perlobj, '~');
    
        if (mg)
	    iv = (PORBitInstVars *)SvPVX(mg->mg_obj);
    }

    if (iv && (iv->magic == INSTVARS_MAGIC))
	return iv;
    else
	return NULL;
}

void
porbit_instvars_destroy (PORBitInstVars *instvars)
{
    CORBA_Environment ev;
    CORBA_exception_init (&ev);
    
    
    assert (instvars->magic == INSTVARS_MAGIC);

    porbit_servant_destroy (instvars->servant, &ev);
    if (ev._major != CORBA_NO_EXCEPTION) {
	warn ("error while destroying servant");
    }

    /* We don't free instvars itself here, because we have stuck
     * it inside an SV *
     */
}

/* Find a Perl object for this CORBA object.
 */
SV *
porbit_servant_to_sv (PortableServer_Servant servant)
{
    if (servant) {
	PORBitServant *porbit_servant = (PORBitServant *)servant;
	return newRV_inc(porbit_servant->perlobj);
    }
    
    /* FIXME: memory leaks? */
    return newSVsv(&PL_sv_undef);
}

static gchar *
porbit_get_repoid (SV *perlobj)
{
    char *result;
    int count;
 
    dSP;
    PUSHMARK(sp);
    XPUSHs(perlobj);
    PUTBACK;
    
    count = perl_call_method("_porbit_repoid", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_porbit_repoid didn't return 1 argument");
    
    result = g_strdup (POPp);
    
    PUTBACK;

    return result;
}


static PortableServer_Servant
porbit_get_orbit_servant (SV *perlobj)
{
    PortableServer_Servant result;
    int count;

    dSP;
    PUSHMARK(sp);
    XPUSHs(perlobj);
    PUTBACK;
	
    count = perl_call_method("_porbit_servant", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_porbit_servant didn't return 1 argument");
    
    result  = (PortableServer_Servant) POPi;
    
    PUTBACK;

    return result;
}

PortableServer_Servant
porbit_sv_to_servant (SV *perlobj)
{
    PORBitInstVars *iv;

    if (!SvOK(perlobj))
        return NULL;

    iv = porbit_instvars_get (perlobj);
    
    if (!iv && !sv_derived_from (perlobj, "PortableServer::ServantBase"))
	croak ("Argument is not a PortableServer::ServantBase");

    if (!iv) {
	iv = porbit_instvars_add (perlobj);
	iv->servant = porbit_get_orbit_servant (perlobj);
    }

    return iv->servant;
}

void
porbit_servant_ref (PortableServer_Servant servant)
{
    PORBitServant *porbit_servant = (PORBitServant *)servant;
    SvREFCNT_inc (porbit_servant->perlobj);
}

void
porbit_servant_unref (PortableServer_Servant servant)
{
    PORBitServant *porbit_servant = (PORBitServant *)servant;
    SvREFCNT_dec (porbit_servant->perlobj);
}

PortableServer_ObjectId *
porbit_sv_to_objectid (SV *sv)
{
    STRLEN len;
    char *str;
    PortableServer_ObjectId *result;
    
    str = SvPV(sv, len);
    result = (PortableServer_ObjectId *)CORBA_sequence_octet__alloc();

    result->_length = len + 1;
    result->_buffer = CORBA_octet_allocbuf (result->_length);
    result->_release = CORBA_TRUE;

    memcpy (result->_buffer, str, len);
    result->_buffer[len] = '\0';

    return result;
}

SV *
porbit_objectid_to_sv (PortableServer_ObjectId *oid)
{
    SV *sv;
    char *strbuf;

    sv = newSV(oid->_length);
    SvCUR_set(sv, oid->_length-1);
    SvPOK_on (sv);

    strbuf = SvPVX(sv);

    memcpy (strbuf, oid->_buffer, oid->_length - 1);
    strbuf[oid->_length - 1] = '\0';

    return sv;
}

/*********************
 * Stub calling code *
 *********************/

/* Utility function used for error reporting */
static char *
servant_classname (PORBitServant *servant)
{
    return HvNAME(SvSTASH(servant->perlobj));
}

static SV *
porbit_call_method (PORBitServant *servant, const char *name, int return_items)
{
    int return_count;
    
    dSP;

    GV *throwngv = gv_fetchpv("Error::THROWN", TRUE, SVt_PV);
    save_scalar (throwngv);	/* assume enclosing scope */

    sv_setsv (GvSV(throwngv), &PL_sv_undef);

    return_count = perl_call_method ((char *)name, G_EVAL |
				     ((return_items == 0) ? G_VOID :
				      ((return_items == 1) ? G_SCALAR : G_ARRAY)));

    SPAGAIN;

    if (SvOK(ERRSV) && (SvROK(ERRSV) || SvTRUE(ERRSV))) {
      
        /* an error or exception occurred */
	while (return_count--)	/* empty stack */
	    (void)POPs;
	PUTBACK;

        if (SvOK(GvSV(throwngv))) {	/* exception */
	    return newSVsv(GvSV(throwngv));
	    
	} else {
	    warn ("Error occured in implementation '%s::%s': %s",
		servant_classname (servant), name, SvPV(ERRSV, PL_na));
	    return porbit_system_except("IDL:omg.org/CORBA/UNKNOWN:1.0", 
					0, CORBA_COMPLETED_MAYBE);
	}
    }

    /* Even when we specify G_VOID we may still get a response if the user
       didn't return with 'return;'! */
    if (!return_items) {
	
	if (return_count) {
	    while (return_count--)
		(void)POPs;
	    PUTBACK;
	}
	
    } else if (return_count != return_items) {
	warn("Implementation '%s::%s' should return %d items",
	    servant_classname (servant), name, return_items);
	
	while (return_count--)
	    (void)POPs;
	PUTBACK;

	return porbit_system_except("IDL:omg.org/CORBA/MARSHAL:1.0", 
				    0, CORBA_COMPLETED_YES);
    }

    return NULL;
}

static void 
call_implementation (PORBitServant           *servant,
		     GIOPRecvBuffer          *recv_buffer,
		     CORBA_Environment       *ev,
		     const char              *name,
		     PORBitParam             *params,
		     CORBA_unsigned_long      nparams,
		     CORBA_ExcDescriptionSeq *exceptions)
{
    dSP;

    GIOPSendBuffer *send_buffer = NULL;
    CORBA_unsigned_long i;
    AV *inout_args = NULL;
    SV *error_sv;
    int exception_level = 0;
    int stack_index;
    int inout_index;
    int return_items = 0;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(servant->perlobj)));

    for (i=0; i < nparams; i++) {
	if (params[i].mode == CORBA_PARAM_IN || params[i].mode == CORBA_PARAM_INOUT) {
	    SV *arg;
	    
	    /* We need the PUTBACK/SPAGAIN here, since the call to
	     * porbit_get_sv might want the stack
	     */
	    PUTBACK;
	    arg = porbit_get_sv (recv_buffer, params[i].type);
	    SPAGAIN;
	    if (!arg) {
		error_sv = porbit_system_except("IDL:omg.org/CORBA/BAD_PARAM:1.0", 
						0, CORBA_COMPLETED_NO);
		goto cleanup;
	    }

	    if (params[i].mode == CORBA_PARAM_INOUT) {
		if (inout_args == NULL)
		    inout_args = newAV();
	    
		av_push(inout_args,arg);
		XPUSHs(sv_2mortal(newRV_noinc(arg)));

		return_items++;
	    } else {
		XPUSHs(sv_2mortal(arg));
	    }
	} else {
	    return_items++;
	}
    }
    
    PUTBACK;
    error_sv = porbit_call_method (servant, name, return_items);
    if (error_sv)
	goto cleanup;

    /* The call succeeded -- decode the results */

    SPAGAIN;
    sp -= return_items;
    PUTBACK;
    
    if (!recv_buffer->message.u.request.response_expected) {
	/* FIXME: free stack items */
	goto cleanup;
    }

    send_buffer = giop_send_reply_buffer_use(GIOP_MESSAGE_BUFFER(recv_buffer)->connection,
					     NULL,
					     recv_buffer->message.u.request.request_id, 
					     CORBA_NO_EXCEPTION);

    if (!send_buffer) {
	warn ("Lost connection to client while sending result of call to %s::%s", servant_classname (servant), name);
	goto cleanup;
    }
    
    stack_index = 1;
    inout_index = 0;
    for (i = 0; i < nparams; i++) {
	CORBA_boolean success;
	
	switch (params[i].mode) {
	case CORBA_PARAM_IN:
	    continue;
	case CORBA_PARAM_OUT:
	    success = porbit_put_sv (send_buffer, params[i].type, *(sp+stack_index++));
	    break;
	case CORBA_PARAM_INOUT:
	    success = porbit_put_sv (send_buffer, params[i].type, *av_fetch(inout_args, inout_index++, 0));
	    break;
	}
	
	if (!success) {
	    warn ("Error marshalling result of call to %s::%s", servant_classname (servant), name);
	    error_sv = porbit_system_except("IDL:omg.org/CORBA/MARSHAL:1.0", 
					    0, CORBA_COMPLETED_YES);
	    goto cleanup;
	}
    }

    giop_send_buffer_write (send_buffer);

 cleanup:
    if (inout_args) {
	av_undef (inout_args);
	inout_args = NULL;
    }
    
    if (send_buffer) {
	giop_send_buffer_unuse (send_buffer);
	send_buffer = NULL;
    }
    
    if (error_sv) {
	SV *new_error;
	CORBA_exception_type type;
	
	exception_level++;
	if (exception_level > 2) {
	    warn ("Panic: recursion marshalling error from %s::%s",
		  servant_classname (servant), name);
	    SvREFCNT_dec (error_sv);
	    
	    goto out;
	}

	if (sv_derived_from(error_sv, "CORBA::UserException"))
	    type = CORBA_USER_EXCEPTION;
	else if (sv_derived_from(error_sv, "CORBA::SystemException"))
	    type = CORBA_SYSTEM_EXCEPTION;
	else {
	    warn ("Exception thrown from %s::%s must derive from CORBA::UserException or CORBA::SystemException", servant_classname (servant), name);
	    SvREFCNT_dec (error_sv);
	    error_sv = porbit_system_except("IDL:omg.org/CORBA/UNKNOWN:1.0", 
					    0, CORBA_COMPLETED_MAYBE);
	    goto cleanup;
	}
	    
	send_buffer = giop_send_reply_buffer_use(GIOP_MESSAGE_BUFFER(recv_buffer)->connection,
						 NULL,
						 recv_buffer->message.u.request.request_id, 
						 type);

	if (!send_buffer) {
	    warn ("Lost connection to client while sending exception from call to %s::%s.\n   %s", servant_classname (servant), name, SvPV (error_sv, PL_na));
	    SvREFCNT_dec (error_sv);
	    
	    goto out;
	}

	new_error = porbit_put_exception (send_buffer, NULL, error_sv, exceptions);
	
	SvREFCNT_dec (error_sv);

	if (new_error) {
	    error_sv = new_error;
	    goto cleanup;
	}

	giop_send_buffer_write (send_buffer);
	giop_send_buffer_unuse (send_buffer);
    }
    
 out:
    FREETMPS;
    LEAVE;
}

static void 
porbit_attr_set_skel (PORBitServant     *servant,
		      GIOPRecvBuffer    *recv_buffer,
		      CORBA_Environment *ev,
		      gpointer           implementation)
{
    PORBitParam param;
    gchar *name;
    
    CORBA_AttributeDescription *attr = implementation;
    
    param.type = attr->type;
    param.mode = CORBA_PARAM_IN;

    name = g_strconcat ("_set_", attr->name, NULL);
    call_implementation (servant, recv_buffer, ev, name, &param, 1, NULL);
    g_free (name);
}

static void 
porbit_attr_get_skel (PORBitServant     *servant,
		      GIOPRecvBuffer    *recv_buffer,
		      CORBA_Environment *ev,
		      gpointer           implementation)
{
    gchar *name;
    PORBitParam param;
    CORBA_AttributeDescription *attr = implementation;

    param.type = attr->type;
    param.mode = CORBA_PARAM_OUT;

    name = g_strconcat ("_get_", attr->name, NULL);
    call_implementation (servant, recv_buffer, ev, name, &param, 1, NULL);
    g_free (name);
}

static void 
porbit_operation_skel (PORBitServant     *servant,
		       GIOPRecvBuffer    *recv_buffer,
		       CORBA_Environment *ev,
		       gpointer           implementation)
{
    CORBA_OperationDescription *opr = implementation;
    PORBitParam *params;
    CORBA_unsigned_long nparams = opr->parameters._length;
    CORBA_unsigned_long i,j;
    
    if (opr->result->kind != CORBA_tk_void)
	nparams++;

    params = g_new (PORBitParam, nparams);

    i = 0;
    if (opr->result->kind != CORBA_tk_void) {
	params[0].type = opr->result;
	params[i].mode = CORBA_PARAM_OUT;
	i++;
    }
    for (j=0; j<opr->parameters._length; j++) {
	params[i].type = opr->parameters._buffer[j].type;
	params[i].mode = opr->parameters._buffer[j].mode;
	i++;
    }

    call_implementation (servant, recv_buffer, ev,
			 opr->name, params, nparams, &opr->exceptions);
    g_free (params);
}


static CORBA_OperationDescription *
find_operation (CORBA_InterfaceDef_FullInterfaceDescription *d, const char *name) 
{
    CORBA_unsigned_long i;
    
    for (i=0; i < d->operations._length; i++) {
	if (strcmp (name, d->operations._buffer[i].name) == 0)
	    return &d->operations._buffer[i];
    }
    for (i = 0; i < d->base_interfaces._length; i++) {
        PORBitIfaceInfo *info = porbit_find_interface_description(d->base_interfaces._buffer[i]);
	if (info) {
	    CORBA_OperationDescription *res = find_operation(info->desc, name);
	    if (res)
		return res;
	}
    }
    return NULL;
}

CORBA_AttributeDescription *
find_attribute (CORBA_InterfaceDef_FullInterfaceDescription *d,
		const char *name, bool set) 
{
    CORBA_unsigned_long i;
    
    for (i=0; i < d->attributes._length; i++) {
	if (!strcmp (name, d->attributes._buffer[i].name)) {
	    if (!set || d->attributes._buffer[i].mode != CORBA_ATTR_READONLY)
		return &d->attributes._buffer[i];
	}
    }
    for (i = 0; i < d->base_interfaces._length; i++) {
        PORBitIfaceInfo *info = porbit_find_interface_description(d->base_interfaces._buffer[i]);
	if (info) {
	    CORBA_AttributeDescription *res = find_attribute(info->desc, name, set);
	    if (res)
		return res;
	}
    }
    return NULL;
}


static ORBitSkeleton
porbit_get_skel (PORBitServant  *servant,
		 GIOPRecvBuffer *recv_buffer,
		 gpointer       *impl)
{
   gchar *opname = recv_buffer->message.u.request.operation;

    if (strncmp(opname, "_set_", 5) == 0) {
	CORBA_AttributeDescription *attr_desc = find_attribute(servant->desc, opname+5, TRUE);
	if (attr_desc) {
	    *impl = attr_desc;
	    return (ORBitSkeleton)porbit_attr_set_skel;
	}

    } else if (strncmp(opname, "_get_", 5) == 0) {
	CORBA_AttributeDescription *attr_desc = find_attribute(servant->desc, opname+5, FALSE);
	if (attr_desc) {
	    *impl = attr_desc;
	    return (ORBitSkeleton)porbit_attr_get_skel;
	}

    } else {
	CORBA_OperationDescription *op_desc = find_operation(servant->desc, opname);
	if (op_desc) {
	    *impl = op_desc;
	    return (ORBitSkeleton)porbit_operation_skel;
	}
    }

   return (ORBitSkeleton)NULL;
}  

PORBitServant *
porbit_servant_create (SV *perlobj, CORBA_Environment *ev)
{
    char *repoid;
    PORBitIfaceInfo *info;
    PORBitServant *servant;
    
    assert (SvROK(perlobj));
    
    repoid = porbit_get_repoid(perlobj);

    info = porbit_find_interface_description (repoid);
    if (!info) {
	info = porbit_load_contained (NULL, repoid, ev);
	if (ev->_major != CORBA_NO_EXCEPTION) {
	    g_free (repoid);
	    return NULL;
	}
    }
    g_free (repoid);

    servant = g_new (PORBitServant, 1);

    servant->_private = NULL;
    servant->vepv = NULL;
    servant->perlobj = SvRV(perlobj);
    servant->desc = info->desc;
    
    PortableServer_ServantBase__init((PortableServer_ServantBase *)servant, ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	goto exception;

    if (!info->class_id) {
	info->class_info.relay_call = (ORBit_impl_finder)porbit_get_skel;
	info->class_info.class_name = info->desc->id;
	info->class_info.init_local_objref = NULL;
	
	info->class_id = ORBit_register_class(&info->class_info);
    }
    
    ORBIT_OBJECT_KEY(servant->_private)->class_info = &info->class_info;

 exception:
    if (ev->_major != CORBA_NO_EXCEPTION) {
	g_free (servant);
	servant = NULL;
    }

    return servant;
}

void
porbit_servant_destroy (PORBitServant *servant, CORBA_Environment *ev)
{
    PortableServer_ServantBase__fini((PortableServer_Servant *)servant, ev);
    g_free (servant);
}
