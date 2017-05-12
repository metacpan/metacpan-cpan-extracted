/* -*- mode: C++; c-file-style: "bsd" c-basic-offset: 4 -*- */

#include "pomni.h"
#undef minor

const I32 OFFSET = 0x10000000;
const I32 OPERATION_BASE = 0;
const I32 GETTER_BASE = OPERATION_BASE + OFFSET;
const I32 SETTER_BASE = GETTER_BASE + OFFSET;

static char *repoid_key = "_repoid";
static CORBA::Repository_ptr iface_repository = CORBA::Repository::_nil();

POmniIfaceInfo *
pomni_find_interface_description (pTHX_ const char *repoid) 
{
    HV *hv = get_hv("CORBA::omniORB::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, strlen(repoid), 0);
    
    if (!result)
	return NULL;
    else
	return (POmniIfaceInfo *)INT2PTR(void *, SvIV(*result));
}

void
pomni_clear_interface (pTHX_ const char *repoid)
{
    HV *hv = get_hv("CORBA::omniORB::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, strlen(repoid), 0);
    if (result) {
	CM_DEBUG(("Clearing interface %s\n", repoid));
	delete (POmniIfaceInfo *)INT2PTR(void *, SvIV(*result));
    }
}

static POmniIfaceInfo *
store_interface_description (pTHX_ CORBA::InterfaceDef_ptr iface)
{
    assert (iface != NULL);

    CORBA::InterfaceDef::FullInterfaceDescription *desc = 
      iface->describe_interface();

    const char *repoid = desc->id;
    U32 len = strlen(repoid);

    HV *hv = get_hv("CORBA::omniORB::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, len, 0);

    if (result) {
	delete (POmniIfaceInfo *)INT2PTR(void *, SvIV(*result));
    }

    {
	CORBA::String_var pkg = iface->absolute_name();
	const char *pkgname;
	if (!strncmp(pkg, "::", 2))	//FIXME:: always starts from '::' ?
	    pkgname = pkg + 2;
	else
	    pkgname = pkg;
 
	POmniIfaceInfo *info = new POmniIfaceInfo (pkgname, 
						   CORBA::InterfaceDef::_duplicate(iface),
						   desc);
	hv_store (hv, (char *)repoid, len, newSViv(PTR2IV((void *)info)), 0);
	
	SV *pkg_sv = get_sv ( (char *)(std::string (pkg) + "::" + repoid_key).c_str(), TRUE );
	sv_setpv (pkg_sv, repoid);
	return info;
    }
    
    return NULL;
}

bool
pomni_is_a(pTHX_ const char *object_repoid, const char *interface_repoid)
{
    CM_DEBUG(("pomni_is_a(%s, %s)\n", object_repoid, interface_repoid));
	
    if(omni::ptrStrMatch(object_repoid, interface_repoid))
	return true;
    
    POmniIfaceInfo *object_info
	= pomni_find_interface_description (aTHX_ object_repoid);
    if(!object_info)
	object_info = pomni_load_contained (aTHX_
					    CORBA::Contained::_nil(), NULL,
					    object_repoid);
    if(!object_info)
	return false;

    CORBA::InterfaceDef::FullInterfaceDescription *desc = object_info->desc;

    for(unsigned i = 0; i < desc->base_interfaces.length(); i++) {
	if(pomni_is_a(aTHX_ desc->base_interfaces[i], interface_repoid))
	    return true;
    }
    return false;    
}

static SV *
decode_exception (pTHX_
		  CORBA::Exception *ex,
		  CORBA::OperationDescription *opr)
{
    CORBA::UnknownUserException *uuex
	= CORBA::UnknownUserException::_downcast(ex);
    CM_DEBUG(("decode_exception(ex='%s')\n", ex->_rep_id()));
    
    if (uuex) {
	// A user exception, check against the possible exceptions for
	// this call.
        CORBA::TypeCode_var tc = uuex->exception().type();
	const char *repoid = (const char *) tc->id();
        CM_DEBUG(("decode_exception():_except_repoid='%s')\n", repoid));
	if (opr) {
	    for (unsigned int i = 0 ; i<opr->exceptions.length() ; i++) {
		if (!strcmp(opr->exceptions[i].id, repoid)) {
		    SV *e = pomni_from_any (aTHX_ &uuex->exception());
		    delete ex;
		    return e;
		}
	    }
	}
	delete ex;
	return pomni_system_except (aTHX_
				    "IDL:omg.org/CORBA/UNKNOWN:1.0", 
				    0, CORBA::COMPLETED_MAYBE);

    }
    else {
	CORBA::SystemException *sysex = CORBA::SystemException::_downcast(ex);
	if (sysex) {
	    SV *e = pomni_system_except(aTHX_
					sysex->_rep_id(), 
					sysex->minor(), 
					sysex->completed());
	    delete ex;
	    return e;
	}
	else {
	    throw POmniCroak(aTHX_ "Panic: caught an impossible exception");
	}
    }
}

XS(_pomni_callStub)
{
    dXSARGS;

    try {
	CORBA::ULong i, j;

	I32 index = XSANY.any_i32;
    
	SV **repoidp
	    = hv_fetch(CvSTASH(cv), repoid_key, strlen(repoid_key), 0);
	if (!repoidp)
	    throw POmniCroak(aTHX_
			     "_pomni_callStub called with bad package (no %s)",
			     repoid_key);
    
	char *repoid = SvPV(GvSV(*repoidp), PL_na);
    
	POmniIfaceInfo *info = pomni_find_interface_description (aTHX_ repoid);
	if (!info)
	    throw POmniCroak(aTHX_
			     "_pomni_callStub called on undefined interface");

	CORBA::InterfaceDef::FullInterfaceDescription *desc = info->desc;
  
	std::string name;
	if (index >= OPERATION_BASE && index < GETTER_BASE) {
	    char *n = desc->operations[index - OPERATION_BASE].name;
	    name = std::string (n);
	}
	else if (index >= GETTER_BASE && index < SETTER_BASE) {
	    name = "_get_"
		+ std::string(desc->attributes[index - GETTER_BASE].name);
	}
	else if (index >= SETTER_BASE) {
	    name = "_set_"
		+ std::string(desc->attributes[index - SETTER_BASE].name);
	}
	CM_DEBUG(("calling operation %s (index %d) of %s\n",
		  name.c_str(), index, repoid));

	// Get the discriminator 
	if (items < 1)
	    throw POmniCroak(aTHX_ "%s::%s must have object as first argument",
			     HvNAME(CvSTASH(cv)), name.c_str());

	CORBA::Object_ptr obj = pomni_sv_to_objref(aTHX_ ST(0)); // may croak
	if( CORBA::is_nil (obj) )
	    throw POmniCroak(aTHX_ "%s::%s is nil object",
			     HvNAME(CvSTASH(cv)), name.c_str ());

	// Form the request
	CORBA::Request_var req = obj->_request(name.c_str());

	if (index >= OPERATION_BASE && index < GETTER_BASE) {
	    CORBA::OperationDescription *opr
		= &desc->operations[index - OPERATION_BASE];
	    j = 1;
	    for (i = 0 ; i < opr->parameters.length(); i++) {
		SV *arg = (j < (CORBA::ULong) items) ? ST(j) : &PL_sv_undef;

		switch (opr->parameters[i].mode) {
		case CORBA::PARAM_IN:
		    {
			CORBA::Any argany( opr->parameters[i].type, 0 );
			if (!pomni_to_any (aTHX_ &argany, arg))
			    throw POmniCroak (aTHX_
					      "Error marshalling "
					      "parameter '%s'",
					      (char *) opr->parameters[i].name);
			req->add_in_arg (opr->parameters[i].name) = argany;
		    }
		    j++;
		    break;
		
		case CORBA::PARAM_INOUT:
		    if (!SvROK(arg))
			throw POmniCroak(aTHX_
					 "INOUT parameter must be a reference");
		    {
			CORBA::Any argany(opr->parameters[i].type, 0 );
			if (!pomni_to_any (aTHX_ &argany , SvRV(arg)))
			    throw POmniCroak (aTHX_
					      "Error marshalling "
					      "parameter '%s'",
					      (char *) opr->parameters[i].name);
			req->add_inout_arg ( opr->parameters[i].name ) = argany;
		    }
		    j++;
		    break;
		
		case CORBA::PARAM_OUT:
		    {
			CORBA::Any argany(opr->parameters[i].type, 0 );
			req->add_out_arg(opr->parameters[i].name) = argany;
			break;
		    }
		}
	    }
	    req->set_return_type(opr->result);

	    for (i = 0; i < opr->exceptions.length(); i++) {
		req->exceptions()->add(opr->exceptions[i].type);
	    }
	}
	else if (index >= GETTER_BASE && index < SETTER_BASE) {
	    req->set_return_type ( desc->attributes[index-GETTER_BASE].type );
	}
	else if (index >= SETTER_BASE) {
	    if (items < 2)
		throw POmniCroak(aTHX_ "%s::%s called without second argument",
				 HvNAME(CvSTASH(cv)), name.c_str());
	    
	    CORBA::Any argany(desc->attributes[index - SETTER_BASE].type, 0);
	    if (!pomni_to_any (aTHX_ &argany, ST(1)))
		throw POmniCroak(aTHX_ "Error marshalling attribute value");
	    req->add_in_arg ( "_value" ) = argany;

	    req->set_return_type (CORBA::_tc_void);
	}

	// Invoke request
	PUTBACK;
	try {
	    POmniPerlEntryUnlocker ul(aTHX);
	    req->invoke();
	}
	catch (CORBA::Exception &e) {
	}
	SPAGAIN;

	CORBA::Exception *excp
	    = CORBA::Exception::_duplicate(req->env()->exception());
	if (excp) {
	    CM_DEBUG(("_pomni_callStub():excp->_repoid='%s'\n",
		      excp->_rep_id()));
	    CORBA::OperationDescription *opr;
	    if (index >= OPERATION_BASE && index < GETTER_BASE) {
		opr = &desc->operations[index - OPERATION_BASE];
	    }
	    else {
		opr = NULL;
	    }
	    throw POmniThrowable(decode_exception(aTHX_ excp, opr));
	    // Will not return
	}

	// Get return and inout, and inout parameters
	I32 return_count = 0;

        CORBA::Any *result = req->result()->value();
        CORBA::TypeCode_var result_tc = result->type();
	if (result_tc->kind() != CORBA::tk_void) {
	    // FIXME, do the right thing in array and scalar contexts
	    SV *res = pomni_from_any (aTHX_ result);
	    if (res)
		ST(0) = sv_2mortal(res); // we have at least 1 argument
	    else
		ST(0) = &PL_sv_undef;
	    return_count++;
	}

	j = 1;
	for (i = 0; i < req->arguments()->count() ; i++) {
	    CORBA::NamedValue *item = req->arguments()->item(i);
	    CM_DEBUG(("item %s has flags %#x\n",
		      (const char *) item->name(), item->flags()));
	    if (item->flags() == CORBA::ARG_INOUT) {
		SV *res = pomni_from_any (aTHX_ item->value());
		if (res)
		    sv_setsv (SvRV(ST(j)), res);
		else
		    sv_setsv (SvRV(ST(j)), &PL_sv_undef);
		j++;
	    } else if (item->flags () == CORBA::ARG_IN) {
		j++;
	    }
	}
	
	for (i = 0; i < req->arguments()->count() ; i++) {
	    CORBA::NamedValue *item = req->arguments()->item(i);
	    if (item->flags() == CORBA::ARG_OUT) {
		SV *res = pomni_from_any (aTHX_ item->value());
		if (return_count >= items)
		    EXTEND(sp,1);
		if (res)
		    ST(return_count) = sv_2mortal (res);
		else
		    ST(return_count) = &PL_sv_undef;
		return_count++;
	    }
	}
	
	XSRETURN(return_count);
    }
    CATCH_POMNI_TRAMPOLINE;
}

XS(_pomni_repoid) {
    dXSARGS;

    ST(0) = (SV *)CvXSUBANY(cv).any_ptr;

    XSRETURN(1);
}

XS(_pomni_narrow) {
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: $class->_narrow(obj)");

    try {
        CORBA::Object *obj = pomni_sv_to_objref (aTHX_ ST(1));
        if(!obj || obj->_NP_is_nil() || obj->_NP_is_pseudo()) {
            ST(1) = newSVsv(&PL_sv_undef);
        }
        else {
            char *narrow_repoid = SvPV_nolen((SV *)CvXSUBANY(cv).any_ptr);
            const char *obj_repoid = obj->_PR_getobj()->_mostDerivedRepoId();

            CM_DEBUG(("narrow %s to %s\n", obj_repoid, narrow_repoid));
            
            if(obj_repoid[0] != '\0'
               && pomni_is_a(aTHX_ obj_repoid, narrow_repoid)) {
                ST(0) = newSVsv(ST(1));
            }
            else if(obj->_is_a(narrow_repoid)) {
                omniObjRef *oosource = obj->_PR_getobj();
                omniIOR* ior = oosource->_getIOR()->duplicate();
                
                omniObjRef *oodest;
                {
                    omni_tracedmutex_lock sync(*omni::internalLock);
                    //oodest->pd_flags.forward_location
                    //  = oosource->pd_flags.forward_location;
                    oodest = omni::createObjRef(narrow_repoid, ior, 1,
                                                oosource->_identity());
                    oodest->_noExistentCheck();
                }

                void *e = oodest->_ptrToObjRef(CORBA::Object::_PD_repoId);
                ST(0) = pomni_objref_to_sv(aTHX_ (CORBA::Object_ptr) e,
                                           narrow_repoid);
            }
            else {
                ST(0) = newSVsv(&PL_sv_undef);
            }
        }
    }
    CATCH_POMNI_SYSTEMEXCEPTION;
	
    sv_2mortal(ST(0));
    XSRETURN(1);
}

static void
define_exception (pTHX_ const char *repoid)
{
    CM_DEBUG(("define_exception('%s')\n",repoid));
    if (pomni_find_exception(aTHX_ repoid))
	return;

    CORBA::Contained_var contained(iface_repository->lookup_id (repoid));
    CORBA::String_var pack(contained->absolute_name());

    char *pkg = pack;
    if (!strncmp(pkg, "::", 2))
	pkg += 2;

    pomni_setup_exception (aTHX_ repoid, pkg, "CORBA::UserException");
}

void
pomni_define_exception(pTHX_ const char *pkg, const char *repoid)
{
    pomni_setup_exception (aTHX_ repoid, pkg, "CORBA::UserException");
}

static void
define_method (pTHX_ const char *pkg, const char *prefix, const char *name, I32 index)
{
    std::string fullname = std::string (pkg) + prefix + name;
    if( get_cv( (char *)fullname.c_str(), 0 ) ) {
      return;
    }

    CV *method_cv = newXS ((char *)fullname.c_str(), 
			   _pomni_callStub, __FILE__);
    CvXSUBANY(method_cv).any_i32 = index;
    CvSTASH (method_cv) = gv_stashpv ((char *)pkg, 0);
}

static void
ensure_iface_repository (CORBA::ORB_ptr _orb)
{
    if (CORBA::is_nil(iface_repository)) {
	CORBA::ORB_var orb = CORBA::ORB::_duplicate(_orb);
	if (CORBA::is_nil(orb))
	    orb = CORBA::ORB::_duplicate(pomni_orb);
	
	CORBA::Object_var obj = 
	    orb->resolve_initial_references("InterfaceRepository");
	try {
	    iface_repository = CORBA::Repository::_narrow(obj);
	} catch(...) {
	    // exit below
	}
    }
    
    if (CORBA::is_nil(iface_repository))
	croak("Cannot contact interface repository");
}

#ifdef MEMCHECK
void
pomni_clear_iface_repository(pTHX)
{
    CORBA::release(iface_repository);
    iface_repository = CORBA::Repository::_nil();
}
#endif

static void
define_interface(pTHX_ POmniIfaceInfo *info, const char *id)
{
    CORBA::InterfaceDef::FullInterfaceDescription *desc = info->desc;

    if (!id)
	id = desc->id;

    // Set up the interface's operations and attributes
    unsigned int i;
    for ( i = 0 ; i < desc->operations.length() ; i++) {
        CORBA::OperationDescription *opr = &desc->operations[i];
	define_method (aTHX_ info->pkg.c_str(), "::", opr->name, OPERATION_BASE + i);
	for ( unsigned int j = 0 ; j < opr->exceptions.length() ; j++)
	  define_exception (aTHX_ opr->exceptions[j].id);
    }

    for ( i = 0 ; i < desc->attributes.length() ; i++) {
	if (desc->attributes[i].mode == CORBA::ATTR_NORMAL) {
	    define_method (aTHX_ info->pkg.c_str(), "::_set_", desc->attributes[i].name, 
			   SETTER_BASE + i);
	}
	define_method (aTHX_ info->pkg.c_str(), "::_get_", desc->attributes[i].name, 
		       GETTER_BASE + i);
    }

    // Register the base interfaces
    
    AV *isa_av = get_av ( (char *)(info->pkg + "::ISA").c_str(), TRUE );

    for ( i = 0 ; i < desc->base_interfaces.length() ; i++) {
	POmniIfaceInfo *info = pomni_find_interface_description(aTHX_ desc->base_interfaces[i]);
	if (!info) {
		CORBA::Contained_var base = iface_repository->lookup_id (desc->base_interfaces[i]);
		if (!CORBA::is_nil (base) && 
		    (base->def_kind() == CORBA::dk_Interface)) {
		    CORBA::InterfaceDef_var intf = CORBA::InterfaceDef::_narrow (base);
		    info = pomni_load_contained (aTHX_ intf, NULL, NULL);
		}
	}
	if (info)
	    av_push (isa_av, newSVpv((char *)info->pkg.c_str(), 0));
    }

    if (desc->base_interfaces.length() == 0) {
	av_push (isa_av, newSVpv("CORBA::Object", 0));
    }

    // Set up the server side package

    isa_av = get_av ( (char *)("POA_" + info->pkg + "::ISA").c_str(), TRUE );
    av_push (isa_av, newSVpv("PortableServer::ServantBase", 0));

    // Create a package method that will allow us to determine the
    // repository id before we have the omniORB object set up

    std::string fullname = "POA_" + info->pkg + "::_pomni_repoid";
    CV *method_cv = newXS ((char *)fullname.c_str(), _pomni_repoid, __FILE__);
    CvXSUBANY(method_cv).any_ptr = (void *)newSVpv((char *)id, 0);

    // Create a package method for performing a narrowing operation
    
    fullname = info->pkg + "::_narrow";
    method_cv = newXS ((char *)fullname.c_str(), _pomni_narrow, __FILE__);
    CvXSUBANY(method_cv).any_ptr = (void *)newSVpv((char *)id, 0);
}

static POmniIfaceInfo *
pomni_init_interface (pTHX_ CORBA::InterfaceDef_ptr iface, const char *id)
{
    // Save the interface description for later reference
    POmniIfaceInfo *info = store_interface_description (aTHX_ iface);
    define_interface(aTHX_ info, id);
    return info;
}

void
pomni_define_interface(pTHX_ const char *pkg,
		       CORBA::InterfaceDef::FullInterfaceDescription *desc)
{
    const char *repoid = desc->id;
    U32 len = strlen(repoid);

    POmniIfaceInfo *info
	= new POmniIfaceInfo (pkg, CORBA::InterfaceDef::_nil(), desc);

    HV *hv = get_hv("CORBA::omniORB::_interfaces", TRUE);
    hv_store (hv, (char *)repoid, len, newSViv(PTR2IV((void *) info)), 0);
    SV *pkg_sv = get_sv((char *)(std::string (pkg) + "::" + repoid_key).c_str(), TRUE );
    sv_setpv (pkg_sv, repoid);

    define_interface(aTHX_ info, NULL);
}

void
pomni_init_constant (pTHX_ const char *pkgname, CORBA::ConstantDef_ptr cd)
{
    CORBA::String_var name = cd->name();

    // Extract the value
    CORBA::Any *value = cd->value();
    SV *sv = pomni_from_any (aTHX_ value);
    delete value;

    // Create a constant-valued sub with that value
    
    HV *stash = gv_stashpv ((char *)pkgname, TRUE);
    newCONSTSUB (stash, name, sv);
}

POmniIfaceInfo *
pomni_load_contained (pTHX_
		      CORBA::Contained_ptr _contained, CORBA::ORB_ptr _orb,
		      const char *_id)
{
    assert (_contained != NULL || _id != NULL);
    CM_DEBUG(("pomni_load_contained(%p,%p,'%s')\n",_contained,_orb,_id));

    CORBA::Contained_var contained = CORBA::Contained::_duplicate (_contained);
    
    if (CORBA::is_nil(contained)) {
	ensure_iface_repository (_orb);

	contained = iface_repository->lookup_id((char *)_id);
	if (CORBA::is_nil(contained))
	    croak("Cannot find '%s' in interface repository", _id);
    }

    if (CORBA::is_nil(iface_repository))
	iface_repository = contained->containing_repository();

    // If the container is an interface, suck all the information
    // out of it for later use.

    POmniIfaceInfo *retval;
    CORBA::InterfaceDef_var iface = CORBA::InterfaceDef::_narrow (contained);
    if (!CORBA::is_nil(iface))
	retval = pomni_init_interface (aTHX_ iface, _id);
    else
	retval =  NULL;

    // If the container is an exception, define it
    CORBA::ExceptionDef_var excp = CORBA::ExceptionDef::_narrow (contained);
    if( !CORBA::is_nil(excp) )
	define_exception(aTHX_ excp->id());

    // Initialize all constants in the container, and all
    // enclosed interfaces.
    
    CORBA::Container_var container = CORBA::Container::_narrow (contained);
    if (!CORBA::is_nil(container)) {

	CORBA::ContainedSeq_var contents = 
	    container->contents (CORBA::dk_Constant, true);

	if (contents->length() > 0) {
	  std::string pkgname;

	    if (retval)
		pkgname = retval->pkg.c_str();
	    else {
		CORBA::String_var pkg = contained->absolute_name();
		if (!strncmp(pkg, "::", 2))
		    pkgname = &pkg[(CORBA::ULong)2];
		else
		    pkgname = pkg;
	    }

	    for (CORBA::ULong i = 0; i<contents->length(); i++) {
		CORBA::ConstantDef_var cd =
		    CORBA::ConstantDef::_narrow (contents[i]);
		pomni_init_constant (aTHX_ pkgname.c_str(), cd);
	    }
	}

	contents = container->contents (CORBA::dk_Interface, true);

	for (CORBA::ULong i = 0; i<contents->length(); i++) {
	    CORBA::String_var id = contents[i]->id();
	    if (!pomni_find_interface_description (aTHX_ id))
		pomni_load_contained (aTHX_ contents[i], _orb, NULL);
	}
    }

    return retval;
}

SV *
store_typecode (pTHX_ const char *id, CORBA::TypeCode_ptr tc)
{
    SV *res = newSV(0);
    sv_setref_iv (res, "CORBA::TypeCode", PTR2IV((void *) tc));

    HV *typecode_cache = get_hv("CORBA::TypeCode::_cache", TRUE);
    hv_store (typecode_cache, (char *)id, strlen(id), res, 0);
    
    return res;
}

SV *
pomni_lookup_typecode (pTHX_ const char *id)
{
    HV *typecode_cache = get_hv("CORBA::TypeCode::_cache", TRUE);
    SV **svp = hv_fetch (typecode_cache, (char *)id, strlen(id), 0);

    if (!svp) {
	ensure_iface_repository (NULL);

	CORBA::Contained_var c = iface_repository->lookup_id ((char *)id);
	CORBA::IDLType_var t = CORBA::IDLType::_narrow(c);
	
	if (CORBA::is_nil(t))
	    return NULL;

	CORBA::TypeCode_ptr tc = t->type();

	return SvREFCNT_inc(store_typecode (aTHX_ id, tc));
    }

    return SvREFCNT_inc(*svp);
}

void
pomni_init_typecodes (pTHX)
{
    store_typecode (aTHX_ "IDL:CORBA/Short:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_short));
    store_typecode (aTHX_ "IDL:CORBA/Long:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_long));
    store_typecode (aTHX_ "IDL:CORBA/UShort:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_ushort));
    store_typecode (aTHX_ "IDL:CORBA/ULong:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_ulong));
    store_typecode (aTHX_ "IDL:CORBA/Float:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_float));
    store_typecode (aTHX_ "IDL:CORBA/Double:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_double));
    store_typecode (aTHX_ "IDL:CORBA/Boolean:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_boolean));
    store_typecode (aTHX_ "IDL:CORBA/Char:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_char));
    store_typecode (aTHX_ "IDL:CORBA/Octet:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_octet));
    store_typecode (aTHX_ "IDL:CORBA/Any:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_any));
    store_typecode (aTHX_ "IDL:CORBA/TypeCode:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_TypeCode));
    store_typecode (aTHX_ "IDL:CORBA/Principal:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_Principal));
    store_typecode (aTHX_ "IDL:CORBA/Object:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_Object));
    store_typecode (aTHX_ "IDL:CORBA/String:1.0", 
		    CORBA::TypeCode::_duplicate(CORBA::_tc_string));
}

#ifdef MEMCHECK
void 
pomni_clear_typecodes(pTHX)
{
    HV *typecode_cache = get_hv("CORBA::TypeCode::_cache", FALSE);
    if(!typecode_cache)
	return;
    hv_undef(typecode_cache);
}
#endif

void
pomni_clone_typecodes(pTHX)
{
    HV *typecode_cache = get_hv("CORBA::TypeCode::_cache", FALSE);
    if(!typecode_cache)
	return;

    hv_iterinit(typecode_cache);
    HE *entry;
    while((entry = hv_iternext(typecode_cache)) != 0) {
	SV *ref = hv_iterval(typecode_cache, entry);
	if(SvROK(ref)) {
	    SV *iv = SvRV(ref);
	    CORBA::TypeCode_ptr tc
		= (CORBA::TypeCode_ptr) INT2PTR(void *, SvIV(iv));
	    sv_setiv(iv, PTR2IV((void *) CORBA::TypeCode::_duplicate(tc)));
	}
    }
}
