#include <orb/orbit.h>
#include "interfaces.h"
#include "errors.h"
#include "extras.h"
#include "exttypes.h"
#include "globals.h"
#include "idl.h"
#include "server.h"
#include "types.h"
#include "porbit-perl.h"

typedef CORBA_ORB              CORBA__ORB;
typedef CORBA_Object           CORBA__Object;
typedef CORBA_TypeCode         CORBA__TypeCode;
typedef ORBit_RootObject       CORBA__ORBit__RootObject;

typedef CORBA_long_long     CORBA__LongLong;
typedef CORBA_unsigned_long_long    CORBA__ULongLong;
typedef CORBA_long_double   CORBA__LongDouble;

typedef PortableServer_POA            PortableServer__POA;
typedef PortableServer_POAManager     PortableServer__POAManager;
typedef PortableServer_ObjectId       PortableServer__ObjectId;
typedef PortableServer_Servant        PortableServer__ServantBase;

#define DEFINE_EXCEPTION(ev)                  \
   CORBA_Environment ev;                      \
   CORBA_exception_init (&ev);

#define CHECK_EXCEPTION(ev)                   \
   if (ev._major != CORBA_NO_EXCEPTION) {     \
      SV *__sv = porbit_builtin_except (&ev); \
      porbit_throw (__sv);                    \
   }

#define TRY(expr)                             \
   G_STMT_START {                             \
       DEFINE_EXCEPTION(ev)                   \
       expr;                                  \
       CHECK_EXCEPTION(ev)                    \
   } G_STMT_END

/*** GLOBALS ****/
CORBA_ORB porbit_orb;

/* As an extension to CORBA, we support a recursive stack of
 * main loops
 */
static GSList *main_loops;

CORBA_Policy
make_policy (PortableServer_POA poa, char *key, char *value, CORBA_Environment *ev)
{
  switch (key[0])
    {
    case 'i':
      if (!strcmp(key, "id_uniqueness"))
	{
	  if (!strcmp (value, "UNIQUE_ID"))
	    return (CORBA_Policy) PortableServer_POA_create_id_uniqueness_policy (poa, PortableServer_UNIQUE_ID, ev);
	  else if (!strcmp (value, "MULTIPLE_ID"))
	    return (CORBA_Policy) PortableServer_POA_create_id_uniqueness_policy (poa, PortableServer_MULTIPLE_ID, ev);
	  else
	    croak ("IdUniquenessPolicy should be \"UNIQUE_ID\" or \"MULTIPLE_ID\"");
	}
      else if (!strcmp(key, "id_assignment"))
	{
	  if (!strcmp (value, "USER_ID"))
	    return (CORBA_Policy) PortableServer_POA_create_id_assignment_policy (poa, PortableServer_USER_ID, ev);
	  else if (!strcmp (value, "SYSTEM_ID"))
	    return (CORBA_Policy) PortableServer_POA_create_id_assignment_policy (poa, PortableServer_SYSTEM_ID, ev);
	  else
	    croak ("IdAssignmentPolicy should be \"USER_ID\" or \"SYSTEM_ID\"");
	}
      else if (!strcmp(key, "implicit_activation"))
	{
	  if (!strcmp (value, "IMPLICIT_ACTIVATION"))
	    return (CORBA_Policy) PortableServer_POA_create_implicit_activation_policy (poa, PortableServer_IMPLICIT_ACTIVATION, ev);
	  else if (!strcmp (value, "NO_IMPLICIT_ACTIVATION"))
	    return (CORBA_Policy) PortableServer_POA_create_implicit_activation_policy (poa, PortableServer_NO_IMPLICIT_ACTIVATION, ev);
	  else
	    croak ("ImplicitActivationPolicy should be \"IMPLICIT_ACTIVATION\" or \"SYSTEM_ID\"");
	}
    case 'l':
      if (!strcmp(key, "lifespan"))
	{
	  if (!strcmp (value, "TRANSIENT"))
	    return (CORBA_Policy) PortableServer_POA_create_lifespan_policy (poa, PortableServer_TRANSIENT, ev);
	  else if (!strcmp (value, "PERSISTENT"))
	    return (CORBA_Policy) PortableServer_POA_create_lifespan_policy (poa, PortableServer_PERSISTENT, ev);
	  else
	    croak ("LifespanPolicy should be \"TRANSIENT\" or \"PERSISTENT\"");
	}
    case 'r':
      if (!strcmp(key, "request_processing"))
	{
	  if (!strcmp (value, "USE_ACTIVE_OBJECT_MAP_ONLY"))
	    return (CORBA_Policy) PortableServer_POA_create_request_processing_policy (poa, PortableServer_USE_ACTIVE_OBJECT_MAP_ONLY, ev);
	  else if (!strcmp (value, "USE_DEFAULT_SERVANT"))
	    return (CORBA_Policy) PortableServer_POA_create_request_processing_policy (poa, PortableServer_USE_DEFAULT_SERVANT, ev);
	  else if (!strcmp (value, "USE_SERVANT_MANAGER"))
	    return (CORBA_Policy) PortableServer_POA_create_request_processing_policy (poa, PortableServer_USE_SERVANT_MANAGER, ev);
	  else
	    croak ("RequestProcessingPolicy should be \"USE_ACTIVE_OBJECT_MAP_ONLY\", \"USE_DEFAULT_SERVANT\", or \"USE_SERVANT_MANAGER\"");
	}
    case 's':
      if (!strcmp(key, "servant_retention"))
	{
	  if (!strcmp (value, "RETAIN"))
	    return (CORBA_Policy) PortableServer_POA_create_servant_retention_policy (poa, PortableServer_RETAIN, ev);
	  else if (!strcmp (value, "NON_RETAIN"))
	    return (CORBA_Policy) PortableServer_POA_create_servant_retention_policy (poa, PortableServer_NON_RETAIN, ev);
	  else
	    croak ("ServantRetentionPolicy should be \"RETAIN\" or \"NON_RETAIN\"");
	}
      break;
    case 't':
      if (!strcmp(key, "thread"))
	{
	  if (!strcmp (value, "ORB_CTRL_MODEL"))
	    return (CORBA_Policy) PortableServer_POA_create_thread_policy (poa, PortableServer_ORB_CTRL_MODEL, ev);
	  else if (!strcmp (value, "SINGLE_THREAD_MODEL"))
	    return (CORBA_Policy) PortableServer_POA_create_thread_policy (poa, PortableServer_ORB_CTRL_MODEL, ev);
	  else
	    croak ("ThreadPolicyValue should be \"ORB_CTRL_MODEL\" or \"SINGLE_THREAD_MODEL\"");
	}
      break;
    }
  croak("Policy key should be one of \"id_uniqueness\", \"id_assignment\",  \"implicit_activation\",  \"lifespan\",  \"request_processing\",  \"servant_retention\" or \"thread\"");
}

MODULE = CORBA::ORBit                     PACKAGE = CORBA

CORBA::ORB
ORB_init (id)
    char *		id
    CODE:
    {
	int argc, i;
	char ** argv;
        SV ** new_argv;
	AV * ARGV;
	SV * ARGV0;

	RETVAL = porbit_orb;
	if (!RETVAL) {

	    DEFINE_EXCEPTION (ev);
	
	    ARGV = perl_get_av("ARGV", FALSE);
	    ARGV0 = perl_get_sv("0", FALSE);
	
	    argc = av_len(ARGV)+2;
	    argv = (char **)malloc (sizeof(char *)*argc);
	    argv[0] = SvPV (ARGV0, PL_na);
	    for (i=0;i<=av_len(ARGV);i++)
                argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), PL_na);
	    
	    RETVAL = CORBA_ORB_init (&argc, argv, id, &ev);

	    /* Note that we must create the new strings before
             * we clear the array and free the old ones.
	     */
            new_argv = (SV**)malloc(sizeof(SV*)*(argc-1));
            for (i=1;i<argc;i++)
                new_argv[i-1] = newSVpv(argv[i],0);
            av_clear (ARGV);
 
            for (i=1;i<argc;i++)
                av_store (ARGV, i-1, new_argv[i-1]);
 
            if (argv)
                free (argv);
            if (new_argv)
                free (new_argv);

	    CHECK_EXCEPTION (ev);

	    porbit_orb = (CORBA_ORB)CORBA_Object_duplicate ((CORBA_Object)RETVAL, NULL);
	}
    }

    OUTPUT:
    RETVAL

MODULE = CORBA::ORBit                    PACKAGE = CORBA::Object

CORBA::Object
_get_interface (self)
    CORBA::Object self;
    CODE:
    {
	DEFINE_EXCEPTION (ev);
	RETVAL = CORBA_Object_get_interface (self, &ev); 
	CHECK_EXCEPTION (ev);
    }
    OUTPUT:
    RETVAL

char *
_repoid (self)
    CORBA::Object self;
    CODE:
    RETVAL = self->object_id;
    OUTPUT:
    RETVAL

void
DESTROY (self)
    CORBA::Object self
    CODE:
    porbit_objref_destroy (self);
    CORBA_Object_release (self, NULL);

MODULE = CORBA::ORBit                    PACKAGE = CORBA::ORB

CORBA_char *
object_to_string (self, object)
    CORBA::ORB self
    CORBA::Object object
    CODE:
    {
        DEFINE_EXCEPTION (ev);
	RETVAL = CORBA_ORB_object_to_string (self, object, &ev);
	CHECK_EXCEPTION (ev);
    }
    OUTPUT:
    RETVAL

SV *
resolve_initial_references (self, str)
    CORBA::ORB self
    CORBA_char *str
    CODE:
    {
	CORBA_Object result;
	
        DEFINE_EXCEPTION (ev);

	result = CORBA_ORB_resolve_initial_references (self, str, &ev);
	CHECK_EXCEPTION (ev);

	/* Ugly hack. unfortunately, ORBit Psueudo-objects are typeless */
	if (!result) {
	    RETVAL = newSVsv(&PL_sv_undef);
	} else if (strcmp (str, "RootPOA") == 0) {
	    RETVAL = newSV(0);
	    sv_setref_pv(RETVAL, "PortableServer::POA", result);
	} else if (strcmp (str, "POACurrent") == 0) {
	    RETVAL = newSV(0);
	    sv_setref_pv(RETVAL, "PortableServer::Current", result);
	} else {
	    RETVAL = porbit_objref_to_sv (result);
	}
    }
    OUTPUT:
    RETVAL

CORBA::Object
string_to_object (self, str)
    CORBA::ORB self
    CORBA_char *str
    CODE:
    {
        DEFINE_EXCEPTION (ev);
	RETVAL = CORBA_ORB_string_to_object (self, str, &ev);
	CHECK_EXCEPTION (ev);
    }
    OUTPUT:
    RETVAL

void
load_idl_file (self, filename)
    CORBA::ORB self
    char *     filename
    CODE:
    porbit_parse_idl_file (filename);

void
preload (self, id)
    CORBA::ORB self
    char *     id
    CODE:
    TRY(porbit_load_contained (NULL, id, &ev));


SV *
work_pending (self)
    CORBA::ORB self
    CODE:
    RETVAL = newSVsv(g_main_pending() ? &PL_sv_yes : &PL_sv_no);
    OUTPUT:
    RETVAL

void
perform_work (self)
    CORBA::ORB self
    CODE:
    g_main_iteration(TRUE); /* Is the FALSE here correct? */

void 
run (self)
    CORBA::ORB self
    CODE:
    {
       GMainLoop *loop = g_main_new (FALSE);
       main_loops = g_slist_prepend (main_loops, loop);
       g_main_run (loop);
       g_main_destroy (loop);
    }

void 
shutdown (self, wait_for_completion)
    CORBA::ORB self
    SV* wait_for_completion
    CODE:
    if (main_loops) {
        GSList *tmp_list;
	DEFINE_EXCEPTION(ev)
      
        if (SvTRUE(wait_for_completion))
            while (g_main_iteration(FALSE))
                /* nothing */;
	
	g_main_quit (main_loops->data);
	
	tmp_list = main_loops;
	main_loops = main_loops->next;
	g_slist_free_1 (tmp_list);

	if (!main_loops)
	  CORBA_ORB_shutdown (porbit_orb, SvTRUE(wait_for_completion), &ev);
	
	CHECK_EXCEPTION (ev)

    } else {
        croak("CORBA::shutdown: No main loop active!");
    }
    
MODULE = CORBA::ORBit            PACKAGE = CORBA::LongLong

CORBA::LongLong
new (Class, str)
    char *str
    CODE:
    RETVAL = longlong_from_string (str);
    OUTPUT:
    RETVAL

SV *
stringify (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CODE:
    {
	char *result = longlong_to_string (self);
        RETVAL = newSVpv (result, 0);
	Safefree (result);
    }
    OUTPUT:
    RETVAL

CORBA::LongLong
add (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    CODE:
    RETVAL = self+other;
    OUTPUT:
    RETVAL

CORBA::LongLong
subtract (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other - self;
    else
        RETVAL = self - other;
    OUTPUT:
    RETVAL

CORBA::LongLong
div (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other / self;
    else
        RETVAL = self / other;
    OUTPUT:
    RETVAL

CORBA::LongLong
mul (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    CODE:
    RETVAL = self*other;
    OUTPUT:
    RETVAL

CORBA::LongLong
mod (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other % self;
    else
        RETVAL = self % other;
    OUTPUT:
    RETVAL

CORBA::LongLong
neg (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CODE:
    RETVAL = -self;
    OUTPUT:
    RETVAL

CORBA::LongLong
abs (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CODE:
    RETVAL = (self > 0) ? self : -self;
    OUTPUT:
    RETVAL

int
cmp (self, other, reverse=&PL_sv_undef)
    CORBA::LongLong self
    CORBA::LongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
      RETVAL = (self == other) ? 0 : ((self > other) ? 1 : -1);
    else
      RETVAL = (other == self) ? 0 : ((other > self) ? 1 : -1);
    OUTPUT:
    RETVAL
	
MODULE = CORBA::ORBit            PACKAGE = CORBA::ULongLong

CORBA::ULongLong
new (Class, str)
    char *str
    CODE:
    RETVAL = ulonglong_from_string (str);
    OUTPUT:
    RETVAL

SV *
stringify (self, other=0, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CODE:
    {
	char *result = ulonglong_to_string (self);
        RETVAL = newSVpv (result, 0);
	Safefree (result);
    }
    OUTPUT:
    RETVAL

CORBA::ULongLong
add (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    CODE:
    RETVAL = self+other;
    OUTPUT:
    RETVAL

CORBA::ULongLong
subtract (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other - self;
    else
        RETVAL = self - other;
    OUTPUT:
    RETVAL

CORBA::ULongLong
div (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other / self;
    else
        RETVAL = self / other;
    OUTPUT:
    RETVAL

CORBA::ULongLong
mul (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    CODE:
    RETVAL = self*other;
    OUTPUT:
    RETVAL

CORBA::ULongLong
mod (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other % self;
    else
        RETVAL = self % other;
    OUTPUT:
    RETVAL

int
cmp (self, other, reverse=&PL_sv_undef)
    CORBA::ULongLong self
    CORBA::ULongLong other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
      RETVAL = (self == other) ? 0 : ((self > other) ? 1 : -1);
    else
      RETVAL = (other == self) ? 0 : ((other > self) ? 1 : -1);
    OUTPUT:
    RETVAL
	
MODULE = CORBA::ORBit            PACKAGE = CORBA::LongDouble

CORBA::LongDouble
new (Class, str)
    char *str
    CODE:
    RETVAL = longdouble_from_string (str);
    OUTPUT:
    RETVAL

SV *
stringify (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CODE:
    {
	char *result = longdouble_to_string (self);
        RETVAL = newSVpv (result, 0);
	Safefree (result);
    }
    OUTPUT:
    RETVAL

CORBA::LongDouble
add (self, other, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CORBA::LongDouble other
    CODE:
    RETVAL = self+other;
    OUTPUT:
    RETVAL

CORBA::LongDouble
subtract (self, other, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CORBA::LongDouble other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other - self;
    else
        RETVAL = self - other;
    OUTPUT:
    RETVAL

CORBA::LongDouble
div (self, other, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CORBA::LongDouble other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
        RETVAL = other / self;
    else
        RETVAL = self / other;
    OUTPUT:
    RETVAL

CORBA::LongDouble
mul (self, other, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CORBA::LongDouble other
    CODE:
    RETVAL = self*other;
    OUTPUT:
    RETVAL

CORBA::LongDouble
neg (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CODE:
    RETVAL = -self;
    OUTPUT:
    RETVAL

CORBA::LongDouble
abs (self, other=0, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CODE:
    RETVAL = (self > 0) ? self : -self;
    OUTPUT:
    RETVAL

int
cmp (self, other, reverse=&PL_sv_undef)
    CORBA::LongDouble self
    CORBA::LongDouble other
    SV *reverse
    CODE:
    if (SvTRUE (reverse))
      RETVAL = (self == other) ? 0 : ((self > other) ? 1 : -1);
    else
      RETVAL = (other == self) ? 0 : ((other > self) ? 1 : -1);
    OUTPUT:
    RETVAL
	

MODULE = CORBA::ORBit                    PACKAGE = CORBA::TypeCode

CORBA::TypeCode
new (pkg, id)
    char *id
    CODE:
    RETVAL = porbit_find_typecode (id);
    if (!RETVAL)
        croak ("Cannot find typecode for '%s'", id);
    RETVAL = (CORBA_TypeCode)CORBA_Object_duplicate ((CORBA_Object)RETVAL, NULL);
    OUTPUT:
    RETVAL
    
MODULE = CORBA::ORBit           PACKAGE = CORBA::ORBit

char *
find_interface (repoid)
    char *repoid
    CODE:
    {
	PORBitIfaceInfo *info = porbit_find_interface_description (repoid);
	RETVAL = info ? info->pkg : NULL;
    }
    OUTPUT:
    RETVAL

char *
load_interface (interface)
    CORBA::Object interface
    CODE:
    {
	PORBitIfaceInfo *info;
        DEFINE_EXCEPTION (ev);

	info = porbit_load_contained (interface, NULL, &ev);
	CHECK_EXCEPTION (ev);

	RETVAL = info ? info->pkg : NULL;
    }
    OUTPUT:
    RETVAL

void
debug_wait ()
    CODE:
    {
	int wait = 1;
	fprintf(stderr, "%d: Waiting...\n", getpid());
	while (wait)
	    ;
    }

void 
set_cookie (cookie)
    char *cookie
    CODE:
    porbit_set_cookie (cookie);

void 
set_use_gmain (set)
    SV *set
    CODE:
    porbit_set_use_gmain (SvTRUE(set));

void
set_check_cookies (set)
    SV *set
    CODE:
    porbit_set_check_cookies (SvTRUE (set));


MODULE = CORBA::ORBit		PACKAGE = CORBA::ORBit::InstVars

void
DESTROY (self)
    SV *self;
    CODE:
    porbit_instvars_destroy ((PORBitInstVars *)SvPVX(SvRV(self)));

MODULE = CORBA::ORBit                    PACKAGE = CORBA::ORBit::RootObject    

void
DESTROY (self)
    CORBA::ORBit::RootObject self
    CODE:
    CORBA_Object_release ((CORBA_Object)self, NULL);

MODULE = CORBA::ORBit                    PACKAGE = PortableServer::POA

CORBA_char *
_get_the_name (self)
    PortableServer::POA self
    CODE:
    TRY(RETVAL = PortableServer_POA__get_the_name (self, &ev));
    OUTPUT:
    RETVAL

PortableServer::POA
_get_the_parent (self)
    PortableServer::POA self
    CODE:
    TRY(RETVAL = PortableServer_POA__get_the_parent (self, &ev));
    OUTPUT:
    RETVAL

PortableServer::POAManager
_get_the_POAManager (self)
    PortableServer::POA self
    CODE:
    TRY(RETVAL = PortableServer_POA__get_the_POAManager (self, &ev));
    OUTPUT:
    RETVAL

PortableServer::POA 
create_POA (self, adapter_name, mngr_sv, ...)
    PortableServer::POA self
    char *adapter_name
    SV *mngr_sv
    CODE:
    {
	CORBA_PolicyList policies;
	PortableServer_POAManager mngr;
	int npolicies, i;
	DEFINE_EXCEPTION (ev);
	
	if (items % 2 != 1)
	    croak("PortableServer::POA::create_POA requires an even number of arguments\n");
	
	if (SvOK (mngr_sv)) {
	    if (sv_derived_from(mngr_sv, "PortableServer::POAManager"))
		mngr = (PortableServer_POAManager) SvIV((SV*)SvRV(mngr_sv));
	    else
		croak("mngr is not of type PortableServer::POAManager");
	} else {
	    mngr = CORBA_OBJECT_NIL;
	}
	
	npolicies = (items - 3) / 2;

	policies._length = npolicies;
	policies._buffer = g_new0 (CORBA_Policy, npolicies) ;
	policies._release = CORBA_TRUE;
	
	for (i = 0 ; i<npolicies; i++) {
	    policies._buffer[i] = make_policy (self, SvPV(ST(3+i*2), PL_na), 
					       SvPV(ST(4+i*2), PL_na), &ev);
	    if (ev._major != CORBA_NO_EXCEPTION)
		goto exception;
	}
	
	RETVAL = PortableServer_POA_create_POA (self, adapter_name, mngr, &policies, &ev);

    exception:
	for (i=0; i<npolicies; i++)
	    if (policies._buffer[i])
		CORBA_Object_release ((CORBA_Object)policies._buffer[i], NULL);
	g_free (policies._buffer);

	CHECK_EXCEPTION (ev);
    }
    OUTPUT:
    RETVAL

void
destroy (self, etherealize_objects, wait_for_completion)
    PortableServer::POA self
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    TRY(PortableServer_POA_destroy (self,
				    SvTRUE (etherealize_objects),
				    SvTRUE (wait_for_completion),
				    &ev));

SV *
activate_object (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    {
	PortableServer_ObjectId *oid;
	DEFINE_EXCEPTION(ev);
	oid = PortableServer_POA_activate_object (self, servant, &ev);
	CHECK_EXCEPTION(ev);
        porbit_servant_ref (servant);
	RETVAL = porbit_objectid_to_sv (oid);
	CORBA_free (oid);
    }
    OUTPUT:
    RETVAL

void
activate_object_with_id (self, perl_id, servant)
    PortableServer::POA self
    SV *perl_id
    PortableServer::ServantBase servant
    CODE:
    {
	PortableServer_ObjectId *oid = porbit_sv_to_objectid (perl_id);
	DEFINE_EXCEPTION(ev);
	PortableServer_POA_activate_object_with_id (self, servant, oid, &ev);
	CORBA_free (oid);
	CHECK_EXCEPTION(ev);
        porbit_servant_ref (servant);
    }

void
deactivate_object (self, perl_id)
    PortableServer::POA self
    SV *perl_id
    CODE:
    {
	PortableServer_ObjectId *oid = porbit_sv_to_objectid (perl_id);
	PortableServer_Servant servant;
	DEFINE_EXCEPTION(ev);

	servant = PortableServer_POA_id_to_servant (self, oid, &ev);
        if (ev._major == CORBA_NO_EXCEPTION)
	    PortableServer_POA_deactivate_object (self, oid, &ev);

        if (ev._major == CORBA_NO_EXCEPTION)
            porbit_servant_unref (servant);

	CORBA_free (oid);
	CHECK_EXCEPTION(ev);
    }

CORBA::Object
create_reference (self, intf)
    PortableServer::POA self
    char *intf
    CODE:
    TRY(RETVAL = PortableServer_POA_create_reference (self, intf, &ev));
    OUTPUT:
    RETVAL

CORBA::Object
create_reference_object_with_id (self, perl_id, intf)
    PortableServer::POA self
    SV *perl_id
    char *intf
    CODE:
    {
	PortableServer_ObjectId *oid = porbit_sv_to_objectid (perl_id);
	DEFINE_EXCEPTION(ev);
	PortableServer_POA_create_reference_with_id (self, oid, intf, &ev);
	CORBA_free (oid);
	CHECK_EXCEPTION(ev);
    }
    OUTPUT:
    RETVAL

SV *
servant_to_id (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    {
	PortableServer_ObjectId *oid;
	DEFINE_EXCEPTION(ev);
	oid = PortableServer_POA_servant_to_id (self, servant, &ev);
	CHECK_EXCEPTION(ev);
	RETVAL = porbit_objectid_to_sv (oid);
	CORBA_free (oid);
    }
    OUTPUT:
    RETVAL

CORBA::Object
servant_to_reference (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    TRY(RETVAL = PortableServer_POA_servant_to_reference (self, servant, &ev));
    OUTPUT:
    RETVAL

CORBA::Object
reference_to_servant (self, reference)
    PortableServer::POA self
    CORBA::Object reference
    CODE:
    TRY(RETVAL = PortableServer_POA_reference_to_servant (self, reference, &ev));
    OUTPUT:
    RETVAL

SV *
reference_to_id (self, reference)
    PortableServer::POA self
    CORBA::Object reference
    CODE:
    {
	PortableServer_ObjectId *oid;
	DEFINE_EXCEPTION(ev);
	oid = PortableServer_POA_reference_to_id (self, reference, &ev);
	CHECK_EXCEPTION(ev);
	RETVAL = porbit_objectid_to_sv (oid);
	CORBA_free (oid);
    }
    OUTPUT:
    RETVAL

PortableServer::ServantBase
id_to_servant (self, perl_id)
    PortableServer::POA self
    SV *perl_id
    CODE:
    {
	PortableServer_ObjectId *oid = porbit_sv_to_objectid (perl_id);
	DEFINE_EXCEPTION(ev);
	RETVAL = PortableServer_POA_id_to_servant (self, oid, &ev);
	CORBA_free (oid);
	CHECK_EXCEPTION(ev);
    }
    OUTPUT:
    RETVAL

CORBA::Object
id_to_reference (self, perl_id)
    PortableServer::POA self
    SV *perl_id
    CODE:
    {
	PortableServer_ObjectId *oid = porbit_sv_to_objectid (perl_id);
	DEFINE_EXCEPTION(ev);
	RETVAL = PortableServer_POA_id_to_reference (self, oid, &ev);
	CORBA_free (oid);
	CHECK_EXCEPTION(ev);
    }
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO            PACKAGE = PortableServer::POAManager

void
activate (self)
    PortableServer::POAManager self
    CODE:
    TRY(PortableServer_POAManager_activate (self, &ev));

void
hold_requests (self, wait_for_completion)
    PortableServer::POAManager self
    SV *wait_for_completion
    CODE:
    TRY(PortableServer_POAManager_hold_requests (self,
						 SvTRUE (wait_for_completion),
						 &ev));

void
discard_requests (self, wait_for_completion)
    PortableServer::POAManager self
    SV *wait_for_completion
    CODE:
    TRY(PortableServer_POAManager_discard_requests (self,
						    SvTRUE (wait_for_completion),
						    &ev));

void
deactivate (self, etherealize_objects, wait_for_completion)
    PortableServer::POAManager self
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    TRY(PortableServer_POAManager_deactivate (self,
					      SvTRUE (etherealize_objects),
					      SvTRUE (wait_for_completion),
					      &ev));

MODULE = CORBA::ORBit            PACKAGE = PortableServer::ServantBase

IV
_porbit_servant (self)
    SV *self
    CODE:
    TRY(RETVAL = (IV)(PortableServer_Servant)porbit_servant_create (self, &ev));
    OUTPUT:
    RETVAL

BOOT:
    porbit_init_exceptions();
    porbit_init_typecodes();
    porbit_set_use_gmain(1);

