/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "errors.h"
#include "porbit-perl.h"

typedef struct _SystemExceptionRec SystemExceptionRec;
typedef struct _BuiltinExceptionRec BuiltinExceptionRec;

struct _SystemExceptionRec {
    char *repoid;
    char *package;
    char *text;
};

struct _BuiltinExceptionRec {
    char *repoid;
    char *package;
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

static BuiltinExceptionRec builtin_exceptions[] = {
    { "IDL:omg.org/PortableServer/POA/AdapterAlreadyExists:1.0",
      "PortableServer::POA::AdapterAlreadyExists" },
    { "IDL:omg.org/PortableServer/POA/AdapterInactive:1.0",
      "PortableServer::POA::AdapterInactive" },
    { "IDL:omg.org/PortableServer/POA/AdapterNonExistant:1.0",
      "PortableServer::POA::AdapterNonExistant" },
    { "IDL:omg.org/PortableServer/POA/InvalidPolicy:1.0",
      "PortableServer::POA::InvalidPolicy" },
    { "IDL:omg.org/PortableServer/POA/NoServant:1.0",
      "PortableServer::POA::NoServant" },
    { "IDL:omg.org/PortableServer/POA/ObjectAlreadyActive:1.0",
      "PortableServer::POA::ObjectAlreadyActive" },
    { "IDL:omg.org/PortableServer/POA/ObjectNotActive:1.0",
      "PortableServer::POA::ObjectNotActive" },
    { "IDL:omg.org/PortableServer/POA/ServantAlreadyActive:1.0",
      "PortableServer::POA::ServantAlreadyActive" },
    { "IDL:omg.org/PortableServer/POA/ServantNotActive:1.0",
      "PortableServer::POA::ServantNotActive" },
    { "IDL:omg.org/PortableServer/POA/WrongAdapter:1.0",
      "PortableServer::POA::WrongAdapter" },
    { "IDL:omg.org/PortableServer/POA/WrongPolicy:1.0",
      "PortableServer::POA::WrongPolicy" },
    { "IDL:omg.org/PortableServer/POAManager/AdapterInactive:1.0",
      "PortableServer::POAManager::AdapterInactive" },
    { "IDL:omg.org/PortableServer/Current/NoContext:1.0",
      "PortableServer::Current::NoContext" },
    { "IDL:omg.org/CORBA/TypeCode/Bounds:1.0",
      "CORBA::TypeCode::Bounds" },
    { "IDL:omg.org/CORBA/TypeCode/BadKind:1.0",
      "CORBA::TypeCode::BadKind" },
};

static const int num_builtin_exceptions =
   sizeof(builtin_exceptions)/sizeof(BuiltinExceptionRec);

static HV *exceptions_hv;

/* Takes ownership of exception object
 */
void 
porbit_throw (SV *e)
{
    dSP;

    SAVETMPS;
    
    PUSHMARK(sp);
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
porbit_find_exception (const char *repoid)
{
    dTHR;
    SV **svp;
    
    if (!exceptions_hv)
	return NULL;

    svp = hv_fetch (exceptions_hv, (char *)repoid, strlen(repoid), 0);
    if (!svp)
	return NULL;

    return SvPV(*svp, PL_na);
}

void
porbit_setup_exception (const char *repoid, const char *pkg,
			const char *parent)
{
   char *varname;
   SV *sv;
   AV *av;
   
   if (!exceptions_hv)
       exceptions_hv = newHV();

   /* Check if this package has been set up (FIXME: this isn't really
    * necessary, since we do it in define_exception)
    */
   if (porbit_find_exception (repoid))
       return;

   varname = g_strconcat (pkg, "::_repoid", NULL);
   sv = perl_get_sv (varname, TRUE);
   sv_setsv (sv, newSVpv((char *)repoid, 0));
   g_free (varname);

   varname = g_strconcat (pkg, "::ISA", NULL);
   av = perl_get_av (varname, TRUE);
   av_push (av, newSVpv((char *)parent, 0));
   g_free (varname);

   hv_store (exceptions_hv, (char *)repoid, strlen(repoid), 
	     newSVpv((char *)pkg, 0), 0);
}

void
porbit_init_exceptions (void)
{
    int i;
    
    for (i=1; i<num_system_exceptions; i++) {
	porbit_setup_exception (system_exceptions[i].repoid,
			       system_exceptions[i].package,
			       "CORBA::SystemException");
    }
    for (i=1; i<num_builtin_exceptions; i++) {
	porbit_setup_exception (builtin_exceptions[i].repoid,
			       builtin_exceptions[i].package,
			       "CORBA::UserException");
    }
    porbit_setup_exception ("IDL:omg.org/CORBA/SystemException:1.0",
			     "CORBA::SystemException",
			     "CORBA::Exception");
    porbit_setup_exception ("IDL:omg.org/CORBA/UserException:1.0",
			     "CORBA::UserException",
			     "CORBA::Exception");
}

SV *
porbit_system_except (const char *repoid, CORBA_unsigned_long minor, 
		      CORBA_completion_status status)
{
    char *pkg = NULL;
    char *text = NULL;
    int i;
    SV *tmp_sv;
    char *status_str;
    char *tmp_str = NULL;
    int count;
    dSP;

    /* HACK: ORBit omits the omg.org from repoid names */
    if (strncmp (repoid, "IDL:CORBA", 9) == 0) {
	tmp_str = g_strconcat ("IDL:omg.org/", repoid + 4, NULL);
	repoid = tmp_str;
    }
    
    for (i=0; i<num_system_exceptions; i++) {
	if (!strcmp(repoid, system_exceptions[i].repoid)) {
	    pkg = system_exceptions[i].package;
	    text = system_exceptions[i].text;
	    break;
	}
    }
    if (tmp_str)
	g_free (tmp_str);
    
    if (!pkg) {
	pkg = system_exceptions[0].package;
	text = system_exceptions[0].text;
    }

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(pkg, 0)));

    XPUSHs(sv_2mortal(newSVpv("-text", 0)));
    XPUSHs(sv_2mortal(newSVpv(text, 0)));

    XPUSHs(sv_2mortal(newSVpv("-minor",0)));

    tmp_sv = newSV(0);
    sv_setuv (tmp_sv, minor);
    XPUSHs(sv_2mortal(tmp_sv));
    
    XPUSHs(sv_2mortal(newSVpv("-status",0)));

    switch (status) {
    case CORBA_COMPLETED_YES:
        status_str = "COMPLETED_YES";
	break;
    case CORBA_COMPLETED_NO:
        status_str = "COMPLETED_NO";
	break;
    case CORBA_COMPLETED_MAYBE:
        status_str = "COMPLETED_MAYBE";
	break;
    }
    XPUSHs(sv_2mortal(newSVpv(status_str, 0)));
    
    PUTBACK;
    count = perl_call_method("new", G_SCALAR);
    SPAGAIN;
    
    if (count != 1) {
	while (count--)
	    (void)POPs;
	PUTBACK;
	croak("Exception constructor returned wrong number of items");
    }
    
    tmp_sv = POPs;
    PUTBACK;

    return newSVsv(tmp_sv);
}



SV *
porbit_user_except (const char *repoid, SV *value)
{
    dSP;
    const char *pkg;
    int count;
    SV *tmp_sv;
    
    if (value)
	sv_2mortal(value);
    pkg = porbit_find_exception (repoid);

    if (!pkg)
	return 	porbit_system_except ( "IDL:omg.org/CORBA/UNKNOWN:1.0", 
				      0, CORBA_COMPLETED_MAYBE );

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newSVpv((char *)pkg, 0)));

    if (value) {
      XPUSHs(value);
    }

    PUTBACK;
    count = perl_call_method("new", G_SCALAR);
    SPAGAIN;
    
    if (count != 1) {
	while (count--)
	    (void)POPs;
	PUTBACK;
	croak("Exception constructor returned wrong number of items");
    }
    
    tmp_sv = POPs;
    PUTBACK;
    
    return newSVsv(tmp_sv);
}

SV *
porbit_builtin_except (CORBA_Environment *ev)
{
    const char *repoid = CORBA_exception_id (ev);
    CORBA_SystemException *sysex;
    
    switch (ev->_major) {
    case CORBA_NO_EXCEPTION:
	return NULL;
	
    case CORBA_USER_EXCEPTION:
	if (!strcmp (repoid, ex_PortableServer_POA_InvalidPolicy)) {
	    PortableServer_POA_InvalidPolicy *ipex =
		(PortableServer_POA_InvalidPolicy *)CORBA_exception_value (ev);
	    
	    AV *av = newAV();
	    av_push(av, newSVpv("index", 0));
	    av_push(av, newSViv(ipex->index));
	    
	    return porbit_user_except (repoid, (SV *)av);
	} else
	    return porbit_user_except (repoid, (SV *)newAV());

    default:
	sysex = (CORBA_SystemException *)CORBA_exception_value (ev);
	return porbit_system_except (repoid, sysex->minor, sysex->completed);
    }
    
}
