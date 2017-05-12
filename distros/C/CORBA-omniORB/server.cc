/* -*- mode: C++; c-file-style: "bsd"; c-basic-offset: 4 -*- */

#include "pomni.h"
#include "server.h"

#undef op_name

#ifndef ERRSV
#define ERRSV GvSV(errgv)
#endif

// A table connecting PortableServer::Servant's to the 
// Perl servers. We store the objects here as IV's, not as SV's,
// since we don't hold a reference on the object, and need to
// remove them from here when reference count has dropped to zero

static const U32 instvars_magic = 0x18981972;

// Used for ExcDescriptionSeq when calling ServantActivator functions
// that support ForwardRequest

static CORBA::ExcDescriptionSeq *forward_request_seq = NULL;

// Magic (adopted from DBI) to attach InstVars invisibly to perlobj
POmniInstVars *
pomni_instvars_add (pTHX_ SV *perlobj) 
{
    SV *iv_sv = newSV (sizeof(POmniInstVars));
    POmniInstVars *iv = (POmniInstVars *)SvPVX(iv_sv);

    SV *rv = newRV(iv_sv);	// just needed for sv_bless
    sv_bless (rv, gv_stashpv("CORBA::omniORB::InstVars", TRUE));
    sv_free (rv);

    iv->magic = instvars_magic;
    iv->servant = NULL;

    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);
    
    sv_magic (perlobj, iv_sv, PERL_MAGIC_ext, Nullch, 0);
    SvREFCNT_dec (iv_sv);	// sv_magic() incremented it
    // It looks from sv.c like this is now unecessary, but DBI does it
    // and it shouldn't do any harm
    SvRMAGICAL_on (perlobj);

    return iv;
}

POmniInstVars *
pomni_instvars_get (pTHX_ SV *perlobj) 
{
    POmniInstVars *iv = NULL;
    
    if (SvROK(perlobj))
	perlobj = SvRV(perlobj);

    if (SvMAGICAL (perlobj)) {
        MAGIC *mg = mg_find (perlobj, PERL_MAGIC_ext);
    
        if (mg)
	    iv = (POmniInstVars *)SvPVX(mg->mg_obj);
    }

    if (iv && (iv->magic == instvars_magic))
	return iv;
    else
	return NULL;
}

void
pomni_instvars_destroy (pTHX_ POmniInstVars *instvars)
{
    char buf[24];
    assert (instvars->magic == instvars_magic);

    int n = sprintf(buf, "%lu", PTR2ul(instvars->servant));

    HV *servant_table = get_hv("CORBA::omniORB::_servant_table", FALSE);
    if (servant_table)
	hv_delete(servant_table, buf, n, G_DISCARD);

    instvars->servant->_remove_ref();

    // We don't free instvars itself here, because we have stuck
    // it inside an SV *
}

// Find or create a Perl object for this CORBA object.
SV *
pomni_servant_to_sv (pTHX_ PortableServer::Servant servant)
{
    if (servant) {
	char buf[24];
	int n = sprintf(buf, "%lu", PTR2ul(servant));
	
	HV *servant_table = get_hv("CORBA::omniORB::_servant_table", FALSE);
	if (servant_table) {
	    SV **svp = hv_fetch (servant_table, buf, n, 0);
	    if (svp)
		return newRV_inc(INT2PTR(SV *, SvIV(*svp)));
	}
    }
    
    // FIXME: memory leaks?
    return newSVsv(&PL_sv_undef);
}

static std::string
pomni_get_repoid (pTHX_ SV *perlobj)
{
    char *result;
    
    dSP;
    PUSHMARK(SP);
    XPUSHs(perlobj);
    PUTBACK;
    
    int count = perl_call_method("_pomni_repoid", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_pomni_repoid didn't return 1 argument");
    
    result = POPp;
    
    PUTBACK;

    CM_DEBUG(("_pomni_repoid(%p) returned %s\n", perlobj, result));

    return result;
}

static PortableServer::Servant
pomni_get_omni_servant (pTHX_ SV *perlobj)
{
    PortableServer::Servant result;

    dSP;
    PUSHMARK(SP);
    XPUSHs(perlobj);
    PUTBACK;
	
    int count = perl_call_method("_pomni_servant", G_SCALAR);
    SPAGAIN;
    
    if (count != 1)			/* sanity check */
	croak("object->_pomni_servant didn't return 1 argument");
    
    result  = INT2PTR(PortableServer::Servant, POPi);
    
    PUTBACK;

    CM_DEBUG(("_pomni_servant(%p) returned %p\n", perlobj, result));

    return result;
}

PortableServer::Servant
pomni_sv_to_servant (pTHX_ SV *perlobj)
{
    if (!SvOK(perlobj))
        return NULL;

    POmniInstVars *iv = pomni_instvars_get (aTHX_ perlobj);
    
    if (!iv && !sv_derived_from (perlobj, "PortableServer::ServantBase"))
	croak ("Argument is not a PortableServer::ServantBase");

    if (!iv) {
	iv = pomni_instvars_add (aTHX_ perlobj);

	iv->servant = pomni_get_omni_servant (aTHX_ perlobj);

	HV *servant_table = get_hv("CORBA::omniORB::_servant_table", TRUE);
	
	char buf[24];
	int n = sprintf(buf, "%lu", PTR2ul(iv->servant));
	hv_store (servant_table, buf, n, newSViv(PTR2IV(SvRV(perlobj))), 0);
    }

    return iv->servant;
}

#ifdef MEMCHECK
void 
pomni_clear_servants(pTHX)
{
    HV *servant_table = get_hv("CORBA::omniORB::_servant_table", FALSE);
    if (servant_table)
	hv_undef(servant_table);
}
#endif


// Utility routines for method invocation

static CORBA::Exception *
pomni_encode_exception (pTHX_
			const char *               name, 
			SV *                       perl_except,
			CORBA::ExcDescriptionSeq  *exceptions) 
{
    dSP;

    PUSHMARK (SP);
    XPUSHs (perl_except);
    PUTBACK;

    CM_DEBUG(("pomni_encode_exception(name='%s')\n",name));
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
    CM_DEBUG(("pomni_encode_exception():repoid='%s'\n",repoid));

    if (sv_derived_from (perl_except, "CORBA::SystemException")) {
        CM_DEBUG(("pomni_encode_exception():repoid='%s' "
		  "CORBA::SystemException\n", repoid));

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

#define CHECK_SYSEX_AND_RETURN(name) \
	if (strcmp("IDL:omg.org/CORBA/" #name ":1.0", repoid) == 0) \
 	    return new CORBA::name(minor, status);

	OMNIORB_FOR_EACH_SYS_EXCEPTION(CHECK_SYSEX_AND_RETURN);

#undef CHECK_SYSEX_AND_RETURN

	return 0;
    } else if (sv_derived_from (perl_except, "CORBA::UserException")) {
        CM_DEBUG(("pomni_encode_exception():repoid='%s' "
		  "CORBA::UserException\n", repoid));
	
	if (exceptions) {
	    for (CORBA::ULong i=0; i<exceptions->length(); i++) {
                CM_DEBUG(("pomni_encode_exception():repoid='%s' is '%s'\n",
			  repoid, (*exceptions)[i].id.in()));
		if (!strcmp ((*exceptions)[i].id, repoid)) {
		    CORBA::Any *any = new CORBA::Any;
		    any->replace ((*exceptions)[i].type, 0);
		    if (pomni_to_any (aTHX_ any, perl_except))
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
pomni_call_method (pTHX_ const char *name, int return_items, CORBA::ExcDescriptionSeq  *exceptions) 
{
    dSP;
    CM_DEBUG(("pomni_call_method(%s)\n",name));

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
	    CM_DEBUG(("pomni_call_method exits with exception\n"));
	    return pomni_encode_exception (aTHX_ name, GvSV(throwngv), exceptions);
	    //SPAGAIN;
	} else {
	    warn ("Error occured in implementation of '%s': %s", name, SvPV(ERRSV,PL_na));
	    return new CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
	}
    }

    /* Even when we specify G_VOID we may still get a response if the user
       didn't return with 'return;'! */
    if (return_items && return_count != return_items) {
	warn("Implementation of '%s' should return %d items",
	     name, return_items);
	return new CORBA::MARSHAL(0, CORBA::COMPLETED_YES);
    }

    return NULL;
}

// We implement the following three servant types by hand,
// because they are used in the POA, and we don't necessarily
// have their IDL, and because omniORB hacks them anyways.

static SV *                      
pomni_oid_to_sv (pTHX_ const PortableServer::ObjectId *oid)
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
pomni_sv_to_oid (pTHX_ SV *sv)
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
        const char * const name
            = "PortableServer::ForwardRequest";
        const char * const id
            = "IDL:omg.org/PortableServer/ForwardRequest:1.0";

	forward_request_seq = new CORBA::ExcDescriptionSeq;
	forward_request_seq->length(1);

	(*forward_request_seq)[0].name = name;
	(*forward_request_seq)[0].id = id;
	(*forward_request_seq)[0].defined_in
            = "IDL:omg.org/PortableServer:1.0";
	(*forward_request_seq)[0].version = "1.0";

        CORBA::StructMemberSeq members;
        members.length(1);
        members[0].name = CORBA::string_dup("forward_reference");
        members[0].type = CORBA::TypeCode::_duplicate(CORBA::_tc_Object);
        members[0].type_def = CORBA::IDLType::_nil();
        
	(*forward_request_seq) [0].type
            = pomni_orb->create_exception_tc(id, name, members);
    }
}

// Class for controlling the Perl interpreter context and the Perl
// entry lock.  On entry to a server callback, we acquire the Perl
// entry lock and set the thread-local Perl context to the interpreter
// context stored in the servant when it was created.  On exit, we
// reset the Perl context and release the lock.

class POmniPerlServerContext {
    void *outer_thx_;
    void *server_thx_;
    POmniRatchetLock *entry_lock_;
    SV *Sv_;
    OP *op_;
    XPV *Xpv_;
public:
    POmniPerlServerContext(PerlInterpreter *thx)
	: outer_thx_(PERL_GET_CONTEXT),
	  server_thx_(thx) {
	if(thx != outer_thx_) {
	    PERL_SET_CONTEXT(thx);
	}
	entry_lock_ = pomni_entry_lock(thx);
	entry_lock_->enter();

	// Now that we've entered the server context, save various
	// interpreter values so we can restore them later
	dTHXa(thx);
	Sv_ = PL_Sv;
	op_ = PL_op;
	Xpv_ = PL_Xpv;

	// Switch to a different stack so we don't break any local
	// stack pointer references should we have to grow the stack in
	// the server context.
	dSP;
        ENTER;
        SAVETMPS;
	PUSHSTACKi(PERLSI_SIGNAL);
    }
    
    ~POmniPerlServerContext() {
	dTHXa(server_thx_);

        FREETMPS;
        LEAVE;

	// Restore the server context's previous stack
	POPSTACK;

	// Restore interpreter state variables
	PL_Sv = Sv_;
	PL_op = op_;
	PL_Xpv = Xpv_;
	
	entry_lock_->leave();
	if(server_thx_ != outer_thx_) {
	    PERL_SET_CONTEXT(outer_thx_);
	}
    }

    void *context(void) {
	return server_thx_;
    }
};

CORBA::Boolean
POmniAdapterActivator::unknown_adapter (PortableServer::POA_ptr parent, 
					const char *            name)
{
    CORBA::Exception *exception;
    CORBA::Boolean retval = 0;

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr prnt = PortableServer::POA::_duplicate(parent);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)prnt);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)name, 0)));

    PUTBACK;

    exception = pomni_call_method (aTHX_ "unknown_adapter", 1, NULL);

    if (!exception) {
	SPAGAIN;

	retval = SvTRUE (POPs);

	PUTBACK;
    }

    if (exception)
	throw exception;

    return retval;
}

POmniServantActivator::POmniServantActivator(SV *_perlobj)
{
    assert (SvROK(_perlobj));

    this->thx = (PerlInterpreter*)PERL_GET_THX;
    this->perlobj = SvRV(_perlobj);
}

POmniServantActivator::~POmniServantActivator()
{
}

PortableServer::Servant
POmniServantActivator::incarnate (const PortableServer::ObjectId& oid,
				  PortableServer::POA_ptr         adapter)
{
    PortableServer::Servant retval = 0;
    CORBA::Exception *exception;

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    init_forward_request();
    
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pomni_oid_to_sv (aTHX_ &oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);

    PUTBACK;

    exception = pomni_call_method (aTHX_ "incarnate", 1, forward_request_seq);

    if (!exception) {
	SPAGAIN;
	
	retval = pomni_sv_to_servant (aTHX_ POPs);

	PUTBACK;
    }
    else {
	throw exception;
    }

    return retval;
}

void
POmniServantActivator::etherealize (const PortableServer::ObjectId& oid,
				    PortableServer::POA_ptr         adapter,
				    PortableServer::Servant         serv,
				    CORBA::Boolean                  cleanup_in_progress,
				    CORBA::Boolean                  remaining_activations)
{
    CORBA::Exception *exception;

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pomni_oid_to_sv (aTHX_ &oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(pomni_servant_to_sv (aTHX_ serv)));
    XPUSHs(cleanup_in_progress ? &PL_sv_yes : &PL_sv_no);
    XPUSHs(remaining_activations ? &PL_sv_yes : &PL_sv_no);

    PUTBACK;

    exception = pomni_call_method (aTHX_ "etherealize", 0, NULL);

    if (exception)
	throw exception;
}

PortableServer::Servant
POmniServantLocator::preinvoke (const PortableServer::ObjectId& oid,
				PortableServer::POA_ptr   adapter,
				const char *                    operation,
				PortableServer::ServantLocator::Cookie& the_cookie)
{
    PortableServer::Servant retval;
    CORBA::Exception *exception;

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    init_forward_request();

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pomni_oid_to_sv (aTHX_ &oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)operation, 0)));


    PUTBACK;

    exception = pomni_call_method (aTHX_ "preinvoke", 2, forward_request_seq);

    if (!exception) {
	SPAGAIN;
	
	retval = pomni_sv_to_servant (aTHX_ POPs);
	the_cookie = (void *)SvREFCNT_inc (POPs);

	PUTBACK;
    }
    else {
        throw exception;
    }

    return retval;
}

void
POmniServantLocator::postinvoke (const PortableServer::ObjectId& oid,
 				 PortableServer::POA_ptr   adapter,
				 const char *                    operation,
				 PortableServer::ServantLocator::Cookie the_cookie,
				 PortableServer::Servant         serv)

{
    CORBA::Exception *exception;

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));
    
    XPUSHs(sv_2mortal(pomni_oid_to_sv (aTHX_ &oid)));
    SV *tmp = sv_newmortal();
    PortableServer::POA_ptr adptr = PortableServer::POA::_duplicate(adapter);
    sv_setref_pv(tmp, "PortableServer::POA", (void *)adptr);
    XPUSHs(tmp);
    XPUSHs(sv_2mortal(newSVpv((char *)operation, 0)));
    XPUSHs(sv_2mortal(pomni_servant_to_sv (aTHX_ serv)));
    // We gave "cookie" an extra refcount in preinvoke, we take
    // it back here.
    XPUSHs(sv_2mortal((SV *)the_cookie));

    PUTBACK;

    exception = pomni_call_method (aTHX_ "postinvoke", 0, NULL);
    if (exception)
	throw exception;
}

// 
// POmniServant 
//
 

POmniServant::POmniServant (SV *_perlobj)
{
    assert (SvROK(_perlobj));

    this->thx = (PerlInterpreter*)PERL_GET_THX;
    dTHXa(this->thx);

    std::string repoid = pomni_get_repoid (aTHX_ _perlobj);
    POmniIfaceInfo *info
	= pomni_find_interface_description (aTHX_ repoid.c_str());
    
    if (!info)
	info = pomni_load_contained (aTHX_ NULL, NULL, repoid.c_str());

    perlobj = SvRV(_perlobj);
    desc = info->desc;

    CM_DEBUG(("creating POmniServant %p for %p, name=%s, id=%s\n",
	      this, _perlobj, (char *) desc->name, (char *) desc->id));
}

POmniServant::~POmniServant ()
{
    CM_DEBUG(("finalizing POmniServant %p, name=%s, id=%s\n",
	      this, (char *) desc->name, (char *) desc->id));
}

CORBA::OperationDescription *
POmniServant::find_operation (pTHX_
			      CORBA::InterfaceDef::FullInterfaceDescription *d,
			      const char *name) 
{
    CM_DEBUG(("find_operation(%p) %s\n", this, name));
    
    CORBA::ULong i;
    for ( i = 0; i<d->operations.length(); i++) {
	if (!strcmp (name, d->operations[i].name))
	    return &d->operations[i];
    }
    for ( i = 0 ; i < d->base_interfaces.length() ; i++) {
        POmniIfaceInfo *info
	    = pomni_find_interface_description(aTHX_ d->base_interfaces[i]);
	if (info) {
	    CORBA::OperationDescription *res
		= find_operation(aTHX_ info->desc, name);
	    if (res)
		return res;
	}
    }

    return NULL;
}

CORBA::AttributeDescription *
POmniServant::find_attribute (pTHX_
			      CORBA::InterfaceDef::FullInterfaceDescription *d,
			      const char *name, bool set) 
{
    CORBA::ULong i;
    for ( i = 0; i<d->attributes.length(); i++) {
	if (!strcmp (name, d->attributes[i].name)) {
	    if (!set || d->attributes[i].mode != CORBA::ATTR_READONLY)
		return &d->attributes[i];
	}
    }
    for ( i = 0; i < d->base_interfaces.length() ; i++) {
        POmniIfaceInfo *info
	    = pomni_find_interface_description(aTHX_ d->base_interfaces[i]);
	if (info)
	    {
	      CORBA::AttributeDescription *res
		  = find_attribute(aTHX_ info->desc, name, set);
	      if (res)
		  return res;
	}
    }
    return NULL;
}

CORBA::NVList_ptr 
POmniServant::build_args (pTHX_
			  const char *name, int &return_items,
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
	CORBA::AttributeDescription *attr_desc
	    = find_attribute(aTHX_ desc, name+5, TRUE);
	if (attr_desc) {
	    pomni_orb->create_list(0, args);
	    args->add (CORBA::ARG_IN)->value()->replace(attr_desc->type, 0);
	}
    } else if (!strncmp( name, "_get_", 5)) {
	CORBA::AttributeDescription *attr_desc
	    = find_attribute(aTHX_ desc, name+5, FALSE);
	if (attr_desc) {
	    pomni_orb->create_list(0, args);
	    return_type = attr_desc->type;
	    return_items++;
	}
    } else {
	CORBA::OperationDescription *op_desc = find_operation(aTHX_ desc, name);
	if (op_desc) {
	    pomni_orb->create_list(0, args);

	    for (CORBA::ULong i = 0; i<op_desc->parameters.length(); i++) {
		switch (op_desc->parameters[i].mode) {
		case CORBA::PARAM_IN:
		    args->add(CORBA::ARG_IN);
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

		args->item(i)->value()->replace(op_desc->parameters[i].type, 0);
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
POmniServant::builtin_invoke (pTHX_ CORBA::ServerRequest_ptr svreq)
{
    // [12-17]
    if (!strcmp (svreq->operation(), "_interface")) {
	CORBA::NVList_ptr args;
	pomni_orb->create_list(0, args);
	svreq->arguments (args);
	CORBA::Any res;
	res <<= pomni_find_interface_description (aTHX_ desc->id)->iface;
	svreq->set_result (res);
	return true;
    }
    return false;
}

void    
POmniServant::invoke ( CORBA::ServerRequest_ptr _req )
{
    int return_items = 0;	// includes return, if any
    CORBA::TypeCode *return_type = NULL;
    int inout_items = 0;
    AV *inout_args = NULL;
    CORBA::ExcDescriptionSeq *exceptions;

    const char *name = _req->operation();
    CM_DEBUG(("POmniServant::invoke(%p, %s)\n", this, name));

    if (!perlobj) {
	CORBA::OBJECT_NOT_EXIST object_not_exist_ex(0, CORBA::COMPLETED_NO);
	CORBA::Any ex;
	ex <<= object_not_exist_ex;
	_req->set_exception (ex);
							       
	return;
    }

    POmniPerlServerContext psc(this->thx);
    dTHXa(psc.context());
    dSP;

    if (builtin_invoke (aTHX_ _req))
        return;

    // Build an argument list for this method
  
    CORBA::NVList_ptr args = build_args (aTHX_
					 name, return_items, return_type,
					 inout_items, exceptions );

    if (!args) {
	CORBA::BAD_OPERATION bad_operation_ex(0, CORBA::COMPLETED_NO);
	CORBA::Any ex;
	ex <<= bad_operation_ex;
	_req->set_exception (ex);
								   
	return;
    }

    // Now prepare the stack using that list

    _req->arguments (args);

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(perlobj)));

    for (CORBA::ULong i=0; i<args->count(); i++) {
	CORBA::Flags dir = args->item(i)->flags();
	if ((dir == CORBA::ARG_IN) || (dir == CORBA::ARG_INOUT)) {
	    /* We need the PUTBACK/SPAGAIN here, since the call to
	     * pomni_from_any might want the stack
	     */
	    PUTBACK;
	    SV *arg = pomni_from_any (aTHX_ args->item(i)->value());
	    SPAGAIN;
	    if (!arg) {
		CORBA::BAD_PARAM bad_param_ex(0, CORBA::COMPLETED_NO);
		CORBA::Any ex;
		ex <<= bad_param_ex;
		_req->set_exception (ex);
								       
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

    CORBA::Exception *exception
	= pomni_call_method (aTHX_ (char *)name, return_items, exceptions);

    if (exception) {
        CM_DEBUG(("POmniServant::invoke():exception->_repoid()='%s'\n",
		  exception->_rep_id()));
	CORBA::Any ex;
        CORBA::UnknownUserException *uuex
	    = CORBA::UnknownUserException::_downcast(exception);
	if( uuex ) {
	    ex = uuex->exception();
	    _req->set_exception (uuex->exception());
	} else {
	    ex <<= *exception;
	    _req->set_exception (ex);
	}
    } else {
	/* The call succeeded -- decode the results */

	SPAGAIN;
	SP -= return_items;
	PUTBACK;
    
	int stack_index;
	if (return_type != NULL) {
	    CORBA::Any res;
	    res.replace (return_type, 0);
	    if (pomni_to_any (aTHX_ &res, *(SP+1)))
		_req->set_result (res);
	    else {
		warn("Could not encode result");
		CORBA::MARSHAL marshal_ex(0,CORBA::COMPLETED_YES);
		CORBA::Any ex;
		ex <<= marshal_ex;
		_req->set_exception (ex);
                return;
	    }
	    stack_index = 2;
	} else {
	    stack_index = 1;
	}
    
	int inout_index = 0;
	for (CORBA::ULong i=0; i<args->count(); i++) {
	    CORBA::Flags dir = args->item(i)->flags();
	    bool success = TRUE;
	    
	    if (dir == CORBA::ARG_IN) {
		continue;
	    } else if (dir == CORBA::ARG_OUT) {
		success = pomni_to_any (aTHX_
					args->item(i)->value(),
					*(SP+stack_index++));
	    } else if (dir == CORBA::ARG_INOUT) {
		success = pomni_to_any (aTHX_
					args->item(i)->value(),
					*av_fetch(inout_args, inout_index++, 0));
	    }
	    if (!success) {
		CORBA::MARSHAL marshal_ex(0,CORBA::COMPLETED_YES);
		CORBA::Any ex;
		ex <<= marshal_ex;
		_req->set_exception (ex);
                return;
	    }
	}
    }
}

CORBA::RepositoryId 
POmniServant::_primary_interface (const PortableServer::ObjectId &oid, PortableServer::POA_ptr poa)
{
    return CORBA::string_dup (desc->id);
}
