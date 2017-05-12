/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include "server.h"

#undef op_name

#ifndef ERRSV
#define ERRSV GvSV(errgv)
#endif

// A table connecting PortableServer::Servant's to the 
// Perl servers. We store the objects here as IV's, not as SV's,
// since we don't hold a reference on the object, and need to
// remove them from here when reference count has dropped to zero
static HV *servant_table = 0;

static const U32 instvars_magic = 0x18981972;

// Used for ExcDescriptionSeq when calling ServantActivator functions
// that support ForwardRequest

static CORBA::ExcDescriptionSeq *forward_request_seq = NULL;

// Magic (adopted from DBI) to attach InstVars invisibly to perlobj
PMicoInstVars *
pmico_instvars_add (SV *perlobj) 
{
    SV *iv_sv = newSV (sizeof(PMicoInstVars));
    PMicoInstVars *iv = (PMicoInstVars *)SvPVX(iv_sv);

    SV *rv = newRV(iv_sv);	// just needed for sv_bless
    sv_bless (rv, gv_stashpv("CORBA::MICO::InstVars", TRUE));
    sv_free (rv);

    iv->magic = instvars_magic;
    iv->servant = NULL;

    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);
    
    sv_magic (perlobj, iv_sv, '~' , Nullch, 0);
    SvREFCNT_dec (iv_sv);	// sv_magic() incremented it
    // It looks from sv.c like this is now unecessary, but DBI does it
    // and it shouldn't do any harm
    SvRMAGICAL_on (perlobj);

    return iv;
}

PMicoInstVars *
pmico_instvars_get (SV *perlobj) 
{
    PMicoInstVars *iv = NULL;
    
    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);

    if (SvMAGICAL (perlobj)) {
        MAGIC *mg = mg_find (perlobj, '~');
    
        if (mg)
	    iv = (PMicoInstVars *)SvPVX(mg->mg_obj);
    }

    if (iv && (iv->magic == instvars_magic))
	return iv;
    else
	return NULL;
}

void
pmico_instvars_destroy (PMicoInstVars *instvars)
{
    char buf[24];
    assert (instvars->magic == instvars_magic);

    sprintf(buf, "%ld", (IV)instvars->servant);

    if (servant_table)
	hv_delete(servant_table, buf, strlen(buf), G_DISCARD);

    delete instvars->servant;

    // We don't free instvars itself here, because we have stuck
    // it inside an SV *
}

// Find or create a Perl object for this CORBA object.
SV *
pmico_servant_to_sv (PortableServer::Servant servant)
{
    if (servant) {
	char buf[24];
	sprintf(buf, "%ld", (IV)servant);
	
	if (servant_table) {
	    SV **svp = hv_fetch (servant_table, buf, strlen(buf), 0);
	    if (svp)
		return newRV_inc((SV *)SvIV(*svp));
	}
    }
    
    // FIXME: memory leaks?
    return newSVsv(&PL_sv_undef);
}

static string
pmico_get_repoid (SV *perlobj)
{
    char *result;
    
    dSP;
    PUSHMARK(sp);
    XPUSHs(perlobj);
    PUTBACK;
    
    int count = perl_call_method("_pmico_repoid", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_pmico_repoid didn't return 1 argument");
    
    result = POPp;
    
    PUTBACK;

    return result;
}

static PortableServer::Servant
pmico_get_mico_servant (SV *perlobj)
{
    PortableServer::Servant result;

    dSP;
    PUSHMARK(sp);
    XPUSHs(perlobj);
    PUTBACK;
	
    int count = perl_call_method("_pmico_servant", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_pmico_servant didn't return 1 argument");
    
    result  = (PortableServer::Servant) POPi;
    
    PUTBACK;

    return result;
}

PortableServer::Servant
pmico_sv_to_servant    (SV *perlobj)
{
    if (!SvOK(perlobj))
        return NULL;

    PMicoInstVars *iv = pmico_instvars_get (perlobj);
    
    if (!iv && !sv_derived_from (perlobj, "PortableServer::ServantBase"))
	croak ("Argument is not a PortableServer::ServantBase");

    if (!iv) {
	iv = pmico_instvars_add (perlobj);

	iv->servant = pmico_get_mico_servant (perlobj);

	if (!servant_table)
	    servant_table = newHV();
	
	char buf[24];
	sprintf(buf, "%ld", (IV)iv->servant);
	hv_store (servant_table, buf, strlen(buf), newSViv((IV)SvRV(perlobj)), 0);
    }

    return iv->servant;
}

// Utility routines for method invocation

static CORBA::Exception *
pmico_encode_exception (const char *               name, 
			SV *                       perl_except,
			CORBA::ExcDescriptionSeq  *exceptions) 
{
    dSP;

    PUSHMARK (sp);
    XPUSHs (perl_except);
    PUTBACK;

    int count = perl_call_method("_repoid", G_SCALAR | G_EVAL);
    SPAGAIN;
    
    if (SvTRUE(ERRSV) || count != 1) {
	while (count--)	/* empty stack */
	    (void)POPs;

	PUTBACK;

	warn("Error fetching exception repository ID");
	return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
    }

    char *repoid = POPp;
    PUTBACK;

    if (sv_derived_from (perl_except, "CORBA::SystemException")) {

	SV **svp;

	if (!SvROK(perl_except) || (SvTYPE(SvRV(perl_except)) != SVt_PVHV)) {
	    warn("panic: exception not a hash reference");
	    return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
	}

	CORBA::CompletionStatus status;
	svp = hv_fetch((HV *)SvRV(perl_except), "-status", 7, 0);
	if (svp) {
	    char *cstr = SvPV(*svp, PL_na);

	    if (!strcmp(cstr,"COMPLETED_YES"))
		status = CORBA::COMPLETED_YES;
	    else if (!strcmp(cstr,"COMPLETED_NO"))
		status = CORBA::COMPLETED_NO;
	    else if (!strcmp(cstr,"COMPLETED_MAYBE"))
		status = CORBA::COMPLETED_YES;
	    else {
		warn("Bad completion status '%s', assuming 'COMPLETED_NO'",
		     cstr);
		status = CORBA::COMPLETED_NO;
	    }
	}
	else
	    status = CORBA::COMPLETED_MAYBE;

	CORBA::ULong minor;
	svp = hv_fetch((HV *)SvRV(perl_except), "-minor", 6, 0);
	if (svp)
	    minor = (CORBA::ULong)SvNV(*svp);
	else
	    minor = 0;
	
	return CORBA::SystemException::_create_sysex(repoid, minor, status);
	
    } else if (sv_derived_from (perl_except, "CORBA::UserException")) {
	
	if (exceptions) {
	    for (CORBA::ULong i=0; i<exceptions->length(); i++) {
		if (!strcmp ((*exceptions)[i].id, repoid)) {
		    
		    CORBA::Any *any = new CORBA::Any;
		    any->set_type ((*exceptions)[i].type);
		    if (pmico_to_any (any, perl_except))
			return new CORBA::UnknownUserException (any);
		    else {
			warn ("Error creating exception object for '%s'", repoid);
			return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
		    }
		}
	    }
	}
	return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
    } else {
      warn ("Non-CORBA exception");
      return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
    }
}

static CORBA::Exception *
pmico_call_method (const char *name, int return_items, CORBA::ExcDescriptionSeq  *exceptions) 
{
    dSP;

    GV *throwngv = gv_fetchpv("Error::THROWN", TRUE, SVt_PV);
    save_scalar (throwngv);	// assume enclosing scope

    sv_setsv (GvSV(throwngv), &PL_sv_undef);

    int return_count = perl_call_method ((char *)name, G_EVAL |
					 ((return_items == 0) ? G_VOID :
					  ((return_items == 1) ? G_SCALAR : G_ARRAY)));

    SPAGAIN;

    if (SvOK(ERRSV) && (SvROK(ERRSV) || SvTRUE(ERRSV))) {
      
        /* an error or exception occurred */
	while (return_count--)	/* empty stack */
	    (void)POPs;

        if (SvOK(GvSV(throwngv))) {	// exception
	    return pmico_encode_exception (name, GvSV(throwngv), exceptions);
	    SPAGAIN;
	} else {
	    warn ("Error occured in implementation of '%s': %s", name, SvPV(ERRSV,PL_na));
	    return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
	}
    }

    /* Even when we specify G_VOID we may still get a response if the user
       didn't return with 'return;'! */
    if (return_items && return_count != return_items) {
	warn("Implementation of '%s' should return %d items", name, return_items);
	return CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/MARSHAL:1.0", 
						     0, CORBA::COMPLETED_YES);
    }

    return NULL;
}

// We implement the following three servant types by hand,
// because they are used in the POA, and we don't necessarily
// have their IDL, and because MICO hacks them anyways.

static SV *                      
pmico_oid_to_sv (const PortableServer::ObjectId *oid)
{
    SV *result;
    
    result = newSVpv("", 0);
    SvGROW(result, oid->length()+1);
    SvCUR_set(result, oid->length());
    char *pv = SvPVX (result);
    
    for (CORBA::ULong i = 0 ; i < oid->length() ; i++)
	pv[i] = (*oid)[i];
    pv[oid->length()] = '\0';

    return result;
}

static PortableServer::ObjectId *
pmico_sv_to_oid (SV *sv)
{
    STRLEN len;
    PortableServer::ObjectId *result;

    char *str = SvPV(sv, len);
    result = new PortableServer::ObjectId (len);
    result->length(len);
    for (CORBA::ULong i = 0 ; i < len ; i++)
	result[i] = str[i];

    return result;
}

static void
init_forward_request (void)
{
    if (!forward_request_seq) {

	forward_request_seq = new CORBA::ExcDescriptionSeq;
	forward_request_seq->length(1);

	(*forward_request_seq) [0].name = "PortableServer::ForwardRequest";
	(*forward_request_seq) [0].id =
	    "IDL:omg.org/PortableServer/ForwardRequest:1.0";
	(*forward_request_seq) [0].defined_in = "IDL:omg.org/PortableServer:1.0";
	(*forward_request_seq) [0].version = "1.0";
	(*forward_request_seq) [0].type = 
	    new CORBA::TypeCode (*PortableServer::_tc_ForwardRequest);
    }
}

CORBA::Boolean
PMicoAdapterActivator::unknown_adapter (PortableServer::POA_ptr parent, 
					const char *            name)
{
    CORBA::Exception *exception;
    CORBA::Boolean retval;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr prnt = PortableServer::POA::_duplicate(parent);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)prnt);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)name, 0)));

    PUTBACK;

    exception = pmico_call_method ("unknown_adapter", 1, NULL);

    if (!exception) {
	SPAGAIN;

	retval = SvTRUE (POPs);

	PUTBACK;
    }

    FREETMPS;
    LEAVE;

    if (exception)
	throw exception;
    else
	return retval;
}

PortableServer::Servant
PMicoServantActivator::incarnate (const PortableServer::ObjectId& oid,
				  PortableServer::POA_ptr         adapter)
{
    PortableServer::Servant retval;
    CORBA::Exception *exception;

    init_forward_request();
    
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pmico_oid_to_sv (&oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);

    PUTBACK;

    exception = pmico_call_method ("incarnate", 1, forward_request_seq);

    if (!exception) {
	SPAGAIN;
	
	retval = pmico_sv_to_servant (POPs);

	PUTBACK;
    }

    FREETMPS;
    LEAVE;

    if (exception)
	throw exception;
    else
	return retval;
}

void
PMicoServantActivator::etherealize (const PortableServer::ObjectId& oid,
				    PortableServer::POA_ptr         adapter,
				    PortableServer::Servant         serv,
				    CORBA::Boolean                  cleanup_in_progress,
				    CORBA::Boolean                  remaining_activations)
{
    CORBA::Exception *exception;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pmico_oid_to_sv (&oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(pmico_servant_to_sv (serv)));
    XPUSHs(cleanup_in_progress ? &PL_sv_yes : &PL_sv_no);
    XPUSHs(remaining_activations ? &PL_sv_yes : &PL_sv_no);

    PUTBACK;

    exception = pmico_call_method ("etherealize", 0, NULL);

    FREETMPS;
    LEAVE;

    if (exception)
	throw exception;
}

PortableServer::Servant
PMicoServantLocator::preinvoke (const PortableServer::ObjectId& oid,
				const PortableServer::POA_ptr   adapter,
				const char *                    operation,
				PortableServer::ServantLocator::Cookie& the_cookie)
{
    PortableServer::Servant retval;
    CORBA::Exception *exception;

    init_forward_request();

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pmico_oid_to_sv (&oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)operation, 0)));


    PUTBACK;

    exception = pmico_call_method ("preinvoke", 2, forward_request_seq);

    if (!exception) {
	SPAGAIN;
	
	retval = pmico_sv_to_servant (POPs);
	the_cookie = (void *)SvREFCNT_inc (POPs);

	PUTBACK;
    }

    FREETMPS;
    LEAVE;

    if (exception)
	throw exception;
    else
	return retval;
}

void
PMicoServantLocator::postinvoke (const PortableServer::ObjectId& oid,
 				 const PortableServer::POA_ptr   adapter,
				 const char *                    operation,
				 PortableServer::ServantLocator::Cookie the_cookie,
				 PortableServer::Servant         serv)

{
    CORBA::Exception *exception;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pmico_oid_to_sv (&oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)operation, 0)));
    XPUSHs(sv_2mortal(pmico_servant_to_sv (serv)));
    // We gave "cookie" an extra refcount in preinvoke, we take
    // it back here.
    XPUSHs(sv_2mortal((SV *)the_cookie));

    PUTBACK;

    exception = pmico_call_method ("postinvoke", 0, NULL);

    FREETMPS;
    LEAVE;

    if (exception)
	throw exception;
}

// 
// PMicoServant 
//
 

PMicoServant::PMicoServant (SV *_perlobj)
{
    assert (SvROK(_perlobj));

    string repoid = pmico_get_repoid (_perlobj);
    PMicoIfaceInfo *info = pmico_find_interface_description (repoid.c_str());
    
    if (!info)
	info = pmico_load_contained (NULL, NULL, repoid.c_str());

    perlobj = SvRV(_perlobj);
    desc = info->desc;
}

PMicoServant::~PMicoServant ()
{
}

CORBA::OperationDescription *
PMicoServant::find_operation (CORBA::InterfaceDef::FullInterfaceDescription *d,
			      const char *name) 
{
    for (CORBA::ULong i=0; i<d->operations.length(); i++) {
	if (!strcmp (name, d->operations[i].name))
	    return &d->operations[i];
    }
    for ( CORBA::ULong i = 0 ; i < d->base_interfaces.length() ; i++) {
        PMicoIfaceInfo *info = pmico_find_interface_description(d->base_interfaces[i]);
	if (info) {
	    CORBA::OperationDescription *res = find_operation(info->desc, name);
	    if (res)
		return res;
	}
    }

    return NULL;
}

CORBA::AttributeDescription *
PMicoServant::find_attribute (CORBA::InterfaceDef::FullInterfaceDescription *d,
				 const char *name, bool set) 
{
    for (CORBA::ULong i=0; i<d->attributes.length(); i++) {
	if (!strcmp (name, d->attributes[i].name)) {
	    if (!set || d->attributes[i].mode != CORBA::ATTR_READONLY)
		return &d->attributes[i];
	}
    }
    for ( CORBA::ULong i = 0 ; i < d->base_interfaces.length() ; i++) {
        PMicoIfaceInfo *info = pmico_find_interface_description(d->base_interfaces[i]);
	if (info)
	    {
	      CORBA::AttributeDescription *res = find_attribute(info->desc, name, set);
	      if (res)
		  return res;
	}
    }
    return NULL;
}

CORBA::NVList_ptr 
PMicoServant::build_args ( const char *name, int &return_items,
			   CORBA::TypeCode *&return_type,
			   int &inout_items, 
			   CORBA::ExcDescriptionSeq *&exceptions)
{
    CORBA::NVList_ptr args = NULL;
    return_items = 0;
    return_type = NULL;
    inout_items = 0;
    exceptions = NULL;

    // First build an NVList from the Interface description
    
    if (!strncmp( name, "_set_", 5)) {
	CORBA::AttributeDescription *attr_desc = find_attribute(desc, name+5, TRUE);
	if (attr_desc) {
	    args = new CORBA::NVList ();
	    args->add ( CORBA::ARG_IN );
	    args->item ( 0 )->value()->set_type( attr_desc->type );
	}
    } else if (!strncmp( name, "_get_", 5)) {
	CORBA::AttributeDescription *attr_desc = find_attribute(desc, name+5, FALSE);
	if (attr_desc) {
	    args = new CORBA::NVList ();
	    return_type = attr_desc->type;
	    return_items++;
	}
    } else {
	CORBA::OperationDescription *op_desc = find_operation(desc, name);
	if (op_desc) {
	    args = new CORBA::NVList ();

	    for (CORBA::ULong i=0; i<op_desc->parameters.length(); i++) {

		switch (op_desc->parameters[i].mode) {
		case CORBA::PARAM_IN:
		    args->add (CORBA::ARG_IN);
		    break;
		case CORBA::PARAM_OUT:
		    args->add (CORBA::ARG_OUT);
		    return_items++;
		    break;
		case CORBA::PARAM_INOUT:
		    args->add (CORBA::ARG_INOUT);
		    inout_items++;
		    break;
		}
		args->item(i)->value()->set_type(op_desc->parameters[i].type);

	    }
	    if (op_desc->result->kind() != CORBA::tk_void) {
		return_type = op_desc->result;
		return_items++;
	    }

	    exceptions = &op_desc->exceptions;
	}
    }
    return args;
}

// Temporary hack, until POA catches up

bool
PMicoServant::builtin_invoke (CORBA::ServerRequest_ptr svreq)
{
    // [12-17]
    if (!strcmp (svreq->op_name(), "_interface")) {
	CORBA::NVList_ptr args = new CORBA::NVList (0);
	if (svreq->params (args)) {
            CORBA::Any *res = new CORBA::Any;
            *res <<= pmico_find_interface_description (desc->id)->iface;
            svreq->result (res);
        }
	return true;
    }
    return false;
}

void    
PMicoServant::invoke ( CORBA::ServerRequest_ptr _req )
{
    dSP;

    int return_items = 0;	// includes return, if any
    CORBA::TypeCode *return_type = NULL;
    int inout_items = 0;
    AV *inout_args = NULL;
    CORBA::ExcDescriptionSeq *exceptions;

    const char *name = _req->op_name();

    if (!perlobj) {
	_req->exception (CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0", 
							       0, CORBA::COMPLETED_NO));
	return;
    }

    if (builtin_invoke (_req))
        return;

    ENTER;
    SAVETMPS;

    // Build an argument list for this method
  
    CORBA::NVList_ptr args = build_args ( name, return_items, return_type,
					  inout_items, exceptions );

    if (!args) {
	_req->exception (CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/BAD_OPERATION:1.0", 
					  0, CORBA::COMPLETED_NO));
	return;
    }

    // Now prepare the stack using that list

    _req->params (args);

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));

    for (CORBA::ULong i=0; i<args->count(); i++) {
	CORBA::Flags dir = args->item(i)->flags();
	if ((dir == CORBA::ARG_IN) || (dir == CORBA::ARG_INOUT)) {
	    /* We need the PUTBACK/SPAGAIN here, since the call to
	     * pmico_from_any might want the stack
	     */
	    PUTBACK;
	    SV *arg = pmico_from_any (args->item(i)->value());
	    SPAGAIN;
	    if (!arg) {
		_req->exception (CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/BAD_PARAM:1.0", 
								       0, CORBA::COMPLETED_NO));
		return;
	    }

	    if (dir == CORBA::ARG_INOUT) {
		if (inout_args == NULL)
		    inout_args = newAV();
	    
		av_push(inout_args,arg);
		XPUSHs(sv_2mortal(newRV_noinc(arg)));
	    } else {
		XPUSHs(sv_2mortal(arg));
	    }
	}
    }

    PUTBACK;

    CORBA::Exception *exception = pmico_call_method ((char *)name, 
						     return_items,
						     exceptions);

    if (exception)
	_req->exception (exception);
    else {
	/* The call succeeded -- decode the results */

	SPAGAIN;
	sp -= return_items;
	PUTBACK;
    
	if (return_type != NULL) {
	    CORBA::Any *res = new CORBA::Any;
	    res->set_type (return_type);
	    if (pmico_to_any (res, *(sp+1)))
		_req->result (res);
	    else {
		warn("Could not encode result");
		_req->exception (CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/MARSHAL:1.0", 
								       0, CORBA::COMPLETED_YES));
		goto out;
	    }
	}
    
	int stack_index = 2;
	int inout_index = 0;
	for (CORBA::ULong i=0; i<args->count(); i++) {
	    CORBA::Flags dir = args->item(i)->flags();
	    bool success = TRUE;
	    
	    if (dir == CORBA::ARG_IN) {
		continue;
	    } else if (dir == CORBA::ARG_OUT) {
		success = pmico_to_any (args->item(i)->value(),
					*(sp+stack_index++));
	    } else if (dir == CORBA::ARG_INOUT) {
		success = pmico_to_any (args->item(i)->value(),
					*av_fetch(inout_args, inout_index++, 0));
	    }
	    if (!success) {
		_req->exception (CORBA::SystemException::_create_sysex("IDL:omg.org/CORBA/MARSHAL:1.0", 
								       0, CORBA::COMPLETED_YES));
		goto out;
	    }
	}
    }

 out:
    
    FREETMPS;
    LEAVE;
}

CORBA::RepositoryId 
PMicoServant::_primary_interface (const PortableServer::ObjectId &oid, PortableServer::POA_ptr poa)
{
  return CORBA::string_dup (desc->id);
}
