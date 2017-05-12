/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pomni.h"
#undef minor

struct SystemExceptionRec {
    char *repoid;
    char *package;
    char *text;
};

static SystemExceptionRec system_exceptions[] = {
    { "IDL:omg.org/CORBA/SystemException:1.0",
      "CORBA::SystemException",
      "Unspecified system exception" },
    { "IDL:omg.org/CORBA/UNKNOWN:1.0",
      "CORBA::UNKNOWN",
      "The unknown exception" },
    { "IDL:omg.org/CORBA/BAD_PARAM:1.0",
      "CORBA::BAD_PARAM",
      "An invalid parameter was passed" },
    { "IDL:omg.org/CORBA/NO_MEMORY:1.0",
      "CORBA::NO_MEMORY",
      "Dynamic memory allocation failure" },
    { "IDL:omg.org/CORBA/IMP_LIMIT:1.0",
      "CORBA::IMP_LIMIT",
      "Violated implementation limit" },
    { "IDL:omg.org/CORBA/COMM_FAILURE:1.0" ,
      "CORBA::COMM_FAILURE",
      "Communication failure" },
    { "IDL:omg.org/CORBA/INV_OBJREF:1.0",
      "CORBA::INV_OBJREF",
      "Invalid object reference" },
    { "IDL:omg.org/CORBA/NO_PERMISSION:1.0",
      "CORBA::NO_PERMISSION",
      "No permission for attempted operation" },
    { "IDL:omg.org/CORBA/INTERNAL:1.0",
      "CORBA::INTERNAL",
      "ORB internal error" },
    { "IDL:omg.org/CORBA/MARSHAL:1.0",
      "CORBA::MARSHAL",
      "Error marshalling parameter or result" },
    { "IDL:omg.org/CORBA/INITIALIZE:1.0",
      "CORBA::INITIALIZE",
      "ORB initialization failure" },
    { "IDL:omg.org/CORBA/NO_IMPLEMENT:1.0",
      "CORBA::NO_IMPLEMENT",
      "Operation implementation unavailable" },
    { "IDL:omg.org/CORBA/BAD_TYPECODE:1.0",
      "CORBA::BAD_TYPECODE",
      "Bad typecode" },
    { "IDL:omg.org/CORBA/BAD_OPERATION:1.0",
      "CORBA::BAD_OPERATION",
      "Invalid operation" },
    { "IDL:omg.org/CORBA/NO_RESOURCES:1.0",
      "CORBA::NO_RESOURCES",
      "Insufficient resources for request" },
    { "IDL:omg.org/CORBA/NO_RESPONSE:1.0",
      "CORBA::NO_RESPONSE",
      "Response to request not yet available" },
    { "IDL:omg.org/CORBA/PERSIST_STORE:1.0",
      "CORBA::PERSIST_STORE",
      "Persistant storage failure" },
    { "IDL:omg.org/CORBA/BAD_INV_ORDER:1.0",
      "CORBA::BAD_INV_ORDER",
      "Routine invocations out of order" },
    { "IDL:omg.org/CORBA/TRANSIENT:1.0",
      "CORBA::TRANSIENT",
      "Transient failure - reissue request" },
    { "IDL:omg.org/CORBA/FREE_MEM:1.0",
      "CORBA::FREE_MEM",
      "Cannot free memory" },
    { "IDL:omg.org/CORBA/INV_IDENT:1.0",
      "CORBA::INV_IDENT",
      "Invalid identifier syntax" },
    { "IDL:omg.org/CORBA/INV_FLAG:1.0",
      "CORBA::INV_FLAG",
      "Invalid flag was specified" },
    { "IDL:omg.org/CORBA/INTF_REPOS:1.0",
      "CORBA::INTF_REPOS",
      "Error accessing interface repository" },
    { "IDL:omg.org/CORBA/BAD_CONTEXT:1.0",
      "CORBA::BAD_CONTEXT",
      "Error processing context" },
    { "IDL:omg.org/CORBA/OBJ_ADAPTER:1.0",
      "CORBA::OBJ_ADAPTER",
      "Failure detected by object adapter" },
    { "IDL:omg.org/CORBA/DATA_CONVERSION:1.0",
      "CORBA::DATA_CONVERSION",
      "Data conversion error" },
    { "IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0",
      "CORBA::OBJECT_NOT_EXIST",
      "Non-existent object, delete reference" },
    { "IDL:omg.org/CORBA/TRANSACTION_REQUIRED",
      "CORBA::TRANSACTION_REQUIRED",
      "Transaction required" },
    { "IDL:omg.org/CORBA/TRANSACTION_ROLLBACK",
      "CORBA::TRANSACTION_ROLLBACK",
      "Transaction rolled back" },
    { "IDL:omg.org/CORBA/INVALID_TRANSACTION",
      "CORBA::INVALID_TRANSACTION",
      "Invalid transaction" },
};

static const int num_system_exceptions =
   sizeof(system_exceptions)/sizeof(SystemExceptionRec);

typedef enum {
    POMNI_ADAPTER_ALREADY_EXISTS = 1 << 0,
    POMNI_ADAPTER_INACTIVE       = 1 << 1,
    POMNI_ADAPTER_NON_EXISTANT   = 1 << 2,
    POMNI_INVALID_POLICY         = 1 << 3,
    POMNI_NO_SERVANT             = 1 << 4,
    POMNI_OBJECT_ALREADY_ACTIVE  = 1 << 5,
    POMNI_OBJECT_NOT_ACTIVE      = 1 << 6,
    POMNI_SERVANT_ALREADY_ACTIVE = 1 << 7,
    POMNI_SERVANT_NOT_ACTIVE     = 1 << 8,
    POMNI_WRONG_ADAPTER          = 1 << 9,
    POMNI_WRONG_POLICY           = 1 << 10,
    POMNI_MGR_ADAPTER_INACTIVE   = 1 << 11,
    POMNI_NO_CONTEXT             = 1 << 12,
    POMNI_TYPECODE_BOUNDS        = 1 << 13,
    POMNI_TYPECODE_BAD_KIND      = 1 << 14
} POmniBuiltinException;

struct BuiltinExceptionRec {
    char *repoid;
    char *package;
    POmniBuiltinException value;
};

static BuiltinExceptionRec builtin_exceptions[] = {
    { "IDL:omg.org/PortableServer/POA/AdapterAlreadyExists:1.0",
      "PortableServer::POA::AdapterAlreadyExists",
      POMNI_ADAPTER_ALREADY_EXISTS },
    { "IDL:omg.org/PortableServer/POA/AdapterInactive:1.0",
      "PortableServer::POA::AdapterInactive",
      POMNI_ADAPTER_INACTIVE },
    { "IDL:omg.org/PortableServer/POA/AdapterNonExistant:1.0",
      "PortableServer::POA::AdapterNonExistant",
      POMNI_ADAPTER_NON_EXISTANT },
    { "IDL:omg.org/PortableServer/POA/InvalidPolicy:1.0",
      "PortableServer::POA::InvalidPolicy",
      POMNI_INVALID_POLICY },
    { "IDL:omg.org/PortableServer/POA/NoServant:1.0",
      "PortableServer::POA::NoServant",
      POMNI_NO_SERVANT },
    { "IDL:omg.org/PortableServer/POA/ObjectAlreadyActive:1.0",
      "PortableServer::POA::ObjectAlreadyActive",
      POMNI_OBJECT_ALREADY_ACTIVE },
    { "IDL:omg.org/PortableServer/POA/ObjectNotActive:1.0",
      "PortableServer::POA::ObjectNotActive",
      POMNI_OBJECT_NOT_ACTIVE },
    { "IDL:omg.org/PortableServer/POA/ServantAlreadyActive:1.0",
      "PortableServer::POA::ServantAlreadyActive",
      POMNI_SERVANT_ALREADY_ACTIVE },
    { "IDL:omg.org/PortableServer/POA/ServantNotActive:1.0",
      "PortableServer::POA::ServantNotActive",
      POMNI_SERVANT_NOT_ACTIVE },
    { "IDL:omg.org/PortableServer/POA/WrongAdapter:1.0",
      "PortableServer::POA::WrongAdapter",
      POMNI_WRONG_ADAPTER },
    { "IDL:omg.org/PortableServer/POA/WrongPolicy:1.0",
      "PortableServer::POA::WrongPolicy",
      POMNI_WRONG_POLICY },
    { "IDL:omg.org/PortableServer/POAManager/AdapterInactive:1.0",
      "PortableServer::POAManager::AdapterInactive",
      POMNI_MGR_ADAPTER_INACTIVE },
    { "IDL:omg.org/PortableServer/Current/NoContext:1.0",
      "PortableServer::Current::NoContext",
      POMNI_NO_CONTEXT },
    { "IDL:omg.org/CORBA/TypeCode/Bounds:1.0",
      "CORBA::TypeCode::Bounds",
      POMNI_TYPECODE_BOUNDS },
    { "IDL:omg.org/CORBA/TypeCode/BadKind:1.0",
      "CORBA::TypeCode::BadKind",
      POMNI_TYPECODE_BAD_KIND },
    { "IDL:omg.org/DynamicAny/DynAny/InvalidValue:1.0",
      "DynamicAny::DynAny::InvalidValue",
      (POmniBuiltinException)0 },
    { "IDL:omg.org/DynamicAny/DynAny/TypeMismatch:1.0",
      "DynamicAny::DynAny::TypeMismatch",
      (POmniBuiltinException)0 },
    { "IDL:omg.org/DynamicAny/DynAnyFactory/InconsistentTypeCode:1.0",
      "DynamicAny::DynAnyFactory::InconsistentTypeCode",
      (POmniBuiltinException)0 },
    { "IDL:omg.org/CORBA/ORB/InvalidName:1.0",
      "CORBA::ORB::InvalidName",
      (POmniBuiltinException)0 },
    { "DL:omg.org/CORBA/TypeCode/InvalidName:1.0",
      "CORBA::TypeCode::InvalidName",
      (POmniBuiltinException)0 },
    { "IDL:omg.org/CORBA/TypeCode/BadKind:1.0",
      "CORBA::TypeCode::InvalidName",
      (POmniBuiltinException)0 },
};

static const int num_builtin_exceptions =
   sizeof(builtin_exceptions)/sizeof(BuiltinExceptionRec);

// Takes ownership of exception object
void 
pomni_throw (pTHX_ SV *e)
{
    dSP;

    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(e));
    PUTBACK;
  
    perl_call_pv("Error::throw", G_DISCARD);
    
    fprintf(stderr,"panic: Exception throw returned!");
    exit(1);
    
    SPAGAIN;
    
    FREETMPS;
    LEAVE;
}

const char *
pomni_find_exception (pTHX_ const char *repoid)
{
    SV **svp;
    
    CM_DEBUG(("pomni_find_exception(repoid='%s')\n",repoid));

    HV *exceptions_hv = get_hv("CORBA::omniORB::_exceptions", FALSE);;
    if (!exceptions_hv)
	return NULL;

    svp = hv_fetch (exceptions_hv, (char *)repoid, strlen(repoid), 0);
    if (!svp)
	return NULL;

    return SvPV(*svp, PL_na);
}

void
pomni_setup_exception (pTHX_
		       const char *repoid, const char *pkg,
		       const char *parent)
{
    std::string varname;
    SV *sv;

    CM_DEBUG(("pomni_setup_exception(repoid='%s',pkg='%s',parent='%s')\n",
	      repoid, pkg, parent));
    // Check if this package has been set up (FIXME: this isn't really
    // necessary, since we do it in define_exception)
    if (pomni_find_exception (aTHX_ repoid))
	return;
    
    varname = std::string ( pkg ) + "::_repoid";
    sv = get_sv ((char *)varname.c_str(), TRUE);
    sv_setsv (sv, newSVpv((char *)repoid, 0));
    
    varname = std::string ( pkg ) + "::ISA";
    AV *av = get_av ((char *)varname.c_str(), TRUE);
    av_push (av, newSVpv((char *)parent, 0));
    
    HV *exceptions_hv = get_hv("CORBA::omniORB::_exceptions", TRUE);;
    hv_store (exceptions_hv, (char *)repoid, strlen(repoid), 
	      newSVpv((char *)pkg, 0), 0);
}

void
pomni_init_exceptions (pTHX)
{
    int i;
    for ( i=1; i<num_system_exceptions; i++) {
	pomni_setup_exception (aTHX_
			       system_exceptions[i].repoid,
			       system_exceptions[i].package,
			       "CORBA::SystemException");
    }
    for ( i=1; i<num_builtin_exceptions; i++) {
	pomni_setup_exception (aTHX_
			       builtin_exceptions[i].repoid,
			       builtin_exceptions[i].package,
			       "CORBA::UserException");
    }
    pomni_setup_exception (aTHX_
			   "IDL:omg.org/CORBA/SystemException:1.0",
			   "CORBA::SystemException",
			   "CORBA::Exception");
    pomni_setup_exception (aTHX_
			   "IDL:omg.org/CORBA/UserException:1.0",
			   "CORBA::UserException",
			   "CORBA::Exception");
}

#ifdef MEMCHECK
void 
pomni_clear_exceptions(pTHX)
{
    HV *exceptions_hv = get_hv("CORBA::omniORB::_exceptions", TRUE);;
    hv_undef(exceptions_hv);
}
#endif

SV *
pomni_system_except (pTHX_
		     const char *repoid, CORBA::ULong minor, 
		     CORBA::CompletionStatus status)
{
    char *pkg = NULL;
    char *text = NULL;
    int i;
    dSP;

    for (i=0; i<num_system_exceptions; i++) {
	if (!strcmp(repoid, system_exceptions[i].repoid)) {
	    pkg = system_exceptions[i].package;
	    text = system_exceptions[i].text;
	    break;
	}
    }
    if (!pkg) {
	pkg = system_exceptions[0].package;
	text = system_exceptions[0].text;
    }

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(pkg, 0)));

    XPUSHs(sv_2mortal(newSVpv("-text", 0)));
    XPUSHs(sv_2mortal(newSVpv(text, 0)));

    XPUSHs(sv_2mortal(newSVpv("-minor",0)));

    SV *tmp = newSV(0);
    sv_setuv (tmp, minor);
    XPUSHs(sv_2mortal(tmp));
    
    XPUSHs(sv_2mortal(newSVpv("-status",0)));
    char *status_str;
    switch (status) {
    case CORBA::COMPLETED_YES:
        status_str = "COMPLETED_YES";
	break;
    case CORBA::COMPLETED_NO:
        status_str = "COMPLETED_NO";
	break;
    case CORBA::COMPLETED_MAYBE:
        status_str = "COMPLETED_MAYBE";
	break;
    default:
	status_str = "unknown_COMPLETED_status";
    }
    XPUSHs(sv_2mortal(newSVpv(status_str, 0)));
    
    PUTBACK;
    int count = perl_call_method("new", G_SCALAR);
    SPAGAIN;
    
    if (count != 1) {
	while (count--)
	    (void)POPs;
	PUTBACK;
	croak("Exception constructor returned wrong number of items");
    }
    
    SV *sv = POPs;
    PUTBACK;

    return newSVsv(sv);
}



SV *
pomni_user_except (pTHX_ const char *repoid, SV *value)
{
    dSP;

    CM_DEBUG(("pomni_user_except('%s')\n", repoid));
    if (value)
	sv_2mortal(value);
    const char *pkg = pomni_find_exception (aTHX_ repoid);

    if (!pkg)
	return 	pomni_system_except ( aTHX_
				      "IDL:omg.org/CORBA/UNKNOWN:1.0", 
				      0, CORBA::COMPLETED_MAYBE );

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSVpv((char *)pkg, 0)));

    if (value) {
      XPUSHs(value);
    }

    PUTBACK;
    int count = perl_call_method("new", G_SCALAR);
    SPAGAIN;
    
    if (count != 1) {
	while (count--)
	    (void)POPs;
	PUTBACK;
	croak("Exception constructor returned wrong number of items");
    }
    
    SV *sv = POPs;
    PUTBACK;
    
    return newSVsv(sv);
}

SV *
pomni_builtin_except (pTHX_ CORBA::Exception *ex)
{
    const char *repoid = ex->_rep_id();

    /* Special case InvalidPolicy because it takes a parameter */
    PortableServer::POA::InvalidPolicy *ipex =
	PortableServer::POA::InvalidPolicy::_downcast (ex);

    if (ipex) {
	AV *av = newAV();
	av_push(av, newSVpv("index", 0));
	av_push(av, newSViv(ipex->index));
	
	return pomni_user_except (aTHX_ repoid, (SV *)av);
    }

    CORBA::SystemException *sysex = CORBA::SystemException::_downcast(ex);
    if (sysex)
	return pomni_system_except (aTHX_
				    sysex->_rep_id(), 
				    sysex->minor(), 
				    sysex->completed());
    
    return pomni_user_except (aTHX_ repoid, (SV *)newAV());
}
