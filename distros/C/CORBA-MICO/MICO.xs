/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include "server.h"
#include "exttypes.h"
#include "dispatcher.h"
#include <mico/ir.h>
#undef minor			// AIX defines such a strange macros
#undef shutdown			// Win32 defines such a strange macros
#undef rewind			// Win32 defines such a strange macros

/* FIXME: Boot check screws up with egcs... */
#undef XS_VERSION_BOOTCHECK
#define XS_VERSION_BOOTCHECK

/* perl5.005_03 lacks INT2PTR macros */
#ifndef INT2PTR
#  define INT2PTR(any,d)        (any)(d)
#endif

typedef CORBA::Any *        CORBA__Any;
typedef CORBA::Object_ptr   CORBA__Object;
typedef CORBA::ORB_ptr      CORBA__ORB;
typedef CORBA::TypeCode_ptr CORBA__TypeCode;
typedef CORBA::Dispatcher * CORBA__Dispatcher;
typedef CORBA::DispatcherCallback * CORBA__DispatcherCallback;
typedef CORBA::LongLong     CORBA__LongLong;
typedef CORBA::ULongLong    CORBA__ULongLong;
typedef CORBA::LongDouble   CORBA__LongDouble;
typedef PortableServer::POA            PortableServer__POA;
typedef PortableServer::POAManager     PortableServer__POAManager;
typedef PortableServer::Current        PortableServer__Current;
typedef PortableServer::ObjectId_var   PortableServer__ObjectId;
typedef PortableServer::Servant        PortableServer__ServantBase;
typedef DynamicAny::DynAny_ptr		DynamicAny__DynAny;
typedef DynamicAny::DynFixed_ptr	DynamicAny__DynFixed;
typedef DynamicAny::DynEnum_ptr		DynamicAny__DynEnum;
typedef DynamicAny::DynStruct_ptr	DynamicAny__DynStruct;
typedef DynamicAny::DynUnion_ptr	DynamicAny__DynUnion;
typedef DynamicAny::DynSequence_ptr	DynamicAny__DynSequence;
typedef DynamicAny::DynArray_ptr	DynamicAny__DynArray;
typedef DynamicAny::DynValue_ptr	DynamicAny__DynValue;
typedef DynamicAny::DynAnyFactory	DynamicAny__DynAnyFactory;

#ifdef HAVE_GTK

#undef list
#include "gtkmico.h"

typedef GtkDispatcher *CORBA__MICO__GtkDispatcher;

void *get_c_func (char *name)
{
    SV *result;
    int count;
    
    dSP;

    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSVpv (name, 0)));
    PUTBACK;
    
    count = call_pv ("DynaLoader::dl_find_symbol_anywhere", 
			  G_SCALAR | G_EVAL);
    SPAGAIN;

    if (count != 1)
	croak ("Gtk::get_c_func returned %d items", count);

    result = POPs;

    if (!SvOK (result))
	croak ("Could not get C function for %s", name);

    PUTBACK;

    return (void *)SvIV(result);
}
#endif /* HAVE_GTK */

CORBA::Policy_ptr
make_policy (PortableServer::POA *poa, char *key, char *value)
{
  switch (key[0])
    {
    case 'i':
      if (!strcmp(key, "id_uniqueness"))
	{
	  if (!strcmp (value, "UNIQUE_ID"))
	    return poa->create_id_uniqueness_policy (PortableServer::UNIQUE_ID);
	  else if (!strcmp (value, "MULTIPLE_ID"))
	    return poa->create_id_uniqueness_policy (PortableServer::MULTIPLE_ID);
	  else
	    croak ("IdUniquenessPolicy should be \"UNIQUE_ID\" or \"MULTIPLE_ID\"");
	}
      else if (!strcmp(key, "id_assignment"))
	{
	  if (!strcmp (value, "USER_ID"))
	    return poa->create_id_assignment_policy (PortableServer::USER_ID);
	  else if (!strcmp (value, "SYSTEM_ID"))
	    return poa->create_id_assignment_policy (PortableServer::SYSTEM_ID);
	  else
	    croak ("IdAssignmentPolicy should be \"USER_ID\" or \"SYSTEM_ID\"");
	}
      else if (!strcmp(key, "implicit_activation"))
	{
	  if (!strcmp (value, "IMPLICIT_ACTIVATION"))
	    return poa->create_implicit_activation_policy (PortableServer::IMPLICIT_ACTIVATION);
	  else if (!strcmp (value, "NO_IMPLICIT_ACTIVATION"))
	    return poa->create_implicit_activation_policy (PortableServer::NO_IMPLICIT_ACTIVATION);
	  else
	    croak ("ImplicitActivationPolicy should be \"IMPLICIT_ACTIVATION\" or \"SYSTEM_ID\"");
	}
    case 'l':
      if (!strcmp(key, "lifespan"))
	{
	  if (!strcmp (value, "TRANSIENT"))
	    return poa->create_lifespan_policy (PortableServer::TRANSIENT);
	  else if (!strcmp (value, "PERSISTENT"))
	    return poa->create_lifespan_policy (PortableServer::PERSISTENT);
	  else
	    croak ("LifespanPolicy should be \"TRANSIENT\" or \"PERSISTENT\"");
	}
    case 'r':
      if (!strcmp(key, "request_processing"))
	{
	  if (!strcmp (value, "USE_ACTIVE_OBJECT_MAP_ONLY"))
	    return poa->create_request_processing_policy (PortableServer::USE_ACTIVE_OBJECT_MAP_ONLY);
	  else if (!strcmp (value, "USE_DEFAULT_SERVANT"))
	    return poa->create_request_processing_policy (PortableServer::USE_DEFAULT_SERVANT);
	  else if (!strcmp (value, "USE_SERVANT_MANAGER"))
	    return poa->create_request_processing_policy (PortableServer::USE_SERVANT_MANAGER);
	  else
	    croak ("RequestProcessingPolicy should be \"USE_ACTIVE_OBJECT_MAP_ONLY\", \"USE_DEFAULT_SERVANT\", or \"USE_SERVANT_MANAGER\"");
	}
    case 's':
      if (!strcmp(key, "servant_retention"))
	{
	  if (!strcmp (value, "RETAIN"))
	    return poa->create_servant_retention_policy (PortableServer::RETAIN);
	  else if (!strcmp (value, "NON_RETAIN"))
	    return poa->create_servant_retention_policy (PortableServer::NON_RETAIN);
	  else
	    croak ("ServantRetentionPolicy should be \"RETAIN\" or \"NON_RETAIN\"");
	}
      break;
    case 't':
      if (!strcmp(key, "thread"))
	{
	  if (!strcmp (value, "ORB_CTRL_MODEL"))
	    return poa->create_thread_policy (PortableServer::ORB_CTRL_MODEL);
	  else if (!strcmp (value, "SINGLE_THREAD_MODEL"))
	    return poa->create_thread_policy (PortableServer::ORB_CTRL_MODEL);
	  else
	    croak ("ThreadPolicyValue should be \"ORB_CTRL_MODEL\" or \"SINGLE_THREAD_MODEL\"");
	}
      break;
    }
  croak("Policy key should be one of \"id_uniqueness\", \"id_assignment\",  \"implicit_activation\",  \"lifespan\",  \"request_processing\",  \"servant_retention\" or \"thread\"");
}

MODULE = CORBA::MICO           PACKAGE = CORBA::MICO
    
char *
find_interface (repoid)
    char *repoid
    CODE:
    {
	PMicoIfaceInfo *info = pmico_find_interface_description (repoid);
	RETVAL = info ? (char *)info->pkg.c_str() : NULL;
    }
    OUTPUT:
    RETVAL

char *
load_interface (interface)
    CORBA::Object interface
    CODE:
    {
	CORBA::InterfaceDef_var iface = CORBA::InterfaceDef::_narrow (interface);
	PMicoIfaceInfo *info = pmico_load_contained (iface, NULL, NULL);
	RETVAL = info ? (char *)info->pkg.c_str() : NULL;
    }
    OUTPUT:
    RETVAL

char *
debug_wait ()
    CODE:
    {
	int wait = 1;
        RETVAL = NULL;
	fprintf(stderr, "Waiting...\n");
	while (wait)
	    ;
    }
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO           PACKAGE = CORBA

CORBA::ORB
ORB_init (id)
    char *		id
    CODE:
    {
	int argc, i;
	char ** argv;
	AV * ARGV;
	SV * ARGV0;

	RETVAL = CORBA::ORB_instance (id, FALSE);
	if (!RETVAL) {
	
	    ARGV = get_av("ARGV", FALSE);
	    ARGV0 = get_sv("0", FALSE);

	    AV* ARGV_copy = newAV();
	    sv_2mortal((SV*)ARGV_copy);
	    for( i=0; i<=av_len(ARGV); i++)
              av_store( ARGV_copy, i, newSVsv(*av_fetch(ARGV, i, 0)) );
	
	    argc = av_len(ARGV_copy)+2;
	    argv = (char **)malloc (sizeof(char *)*argc);
	    argv[0] = SvPV (ARGV0, PL_na);
	    for( i=0; i<=av_len(ARGV_copy); i++ )
	      argv[i+1] = SvPV( *av_fetch(ARGV_copy, i, 0), PL_na );

	    try {
	      RETVAL = CORBA::ORB_init (argc, argv, id);
	    } catch (CORBA::SystemException &ex) {
	      if (argv)
	          free (argv);
	      pmico_throw (pmico_system_except (ex._repoid (),
	      					ex.minor (),
						ex.completed ()));
	    }
	    
	    av_clear (ARGV);
	    
	    for (i=1;i<argc;i++)
		av_store (ARGV, i-1, newSVpv(argv[i],0));
	
	    if (argv)
		free (argv);
	}
    }
    OUTPUT:
    RETVAL

bool
is_nil (self)
    CORBA::Object self;
    CODE:
    RETVAL = CORBA::is_nil (self);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = CORBA::Any

CORBA::Any
new (pkg, type, value)
    CORBA::TypeCode type
    SV *value
    CODE:
    RETVAL = new CORBA::Any;
    RETVAL->set_type(type);
    if (!pmico_to_any (RETVAL, value)) {
        delete RETVAL;
	croak("Error constructing Any");
    }
    OUTPUT:
    RETVAL

SV *
value (self)
    CORBA::Any self
    CODE:
    RETVAL = pmico_from_any (self);
    OUTPUT:
    RETVAL

CORBA::TypeCode
type (self)
    CORBA::Any self
    CODE:
    RETVAL = self->type ();
    OUTPUT:
    RETVAL    

void
DESTROY (self)
    CORBA::Any self
    CODE:
    delete self;

MODULE = CORBA::MICO		PACKAGE = CORBA::ORB

void
dispatcher (self, disp)
    CORBA::ORB self;
    SV *       disp;
    CODE:
    {
	CORBA::Dispatcher *d;
	if (!SvROK (disp) || !sv_derived_from (disp, "CORBA::Dispatcher"))
	    croak ("Argument to CORBA::ORB::dispatcher is not a CORBA::Dispatcher");
	d = (CORBA::Dispatcher *)SvIV(SvRV(disp));
	if (!d)
	    croak ("Cannot use same CORBA::Dispatcher multiple times");

	self->dispatcher (d);
	sv_setiv (SvRV(disp), 0);		// ORB takes ownership 
    }

char *
object_to_string (self, obj)
    CORBA::ORB self
    CORBA::Object obj
    CODE:
    RETVAL = (char *)self->object_to_string (obj);
    OUTPUT:
    RETVAL

AV *
list_initial_services( self )
    CORBA::ORB self;
    CODE:
    CORBA::ORB::ObjectIdList_var ids = self->list_initial_services();
    RETVAL = newAV();
    av_extend(RETVAL, ids->length());
    for( CORBA::ULong i = 0; i < ids->length(); i++ ) {
      av_push( RETVAL, newSVpv(ids[i], 0) );
    }
    OUTPUT:
      RETVAL

SV *
resolve_initial_references (self, id)
    CORBA::ORB self;
    char *     id
    CODE:
    {
 	CORBA::Object *obj = CORBA::Object::_nil();
	try {
	  obj = self->resolve_initial_references (id);
	} catch (CORBA::SystemException &ex) {
	    pmico_throw (pmico_system_except (ex._repoid (),
					      ex.minor (),
					      ex.completed ()));
	} catch (CORBA::ORB_InvalidName &ex) {
	    pmico_throw (pmico_builtin_except (&ex));
	}
	if( strcmp( id, "DynAnyFactory" ) == 0 ) {
	  DynamicAny::DynAnyFactory_ptr dafact = DynamicAny::DynAnyFactory::_narrow(obj);
	  RETVAL = newSV(0);
	  sv_setref_pv(RETVAL, "DynamicAny::DynAnyFactory", (void*)dafact);
	} else {
	  // ugly hack
	  PortableServer::POA_ptr poa = PortableServer::POA::_narrow (obj);
	  
	  if (!CORBA::is_nil (poa)) {
	      RETVAL = newSV(0);
	      sv_setref_pv(RETVAL, "PortableServer::POA", (void *)poa);
	  } else {
	      PortableServer::Current_ptr current = PortableServer::Current::_narrow (obj);
	      if (!CORBA::is_nil (current)) {
		  RETVAL = newSV(0);
		  sv_setref_pv(RETVAL, "PortableServer::Current", (void *)current);
	      } else
		  RETVAL = pmico_objref_to_sv (obj);
	  }
	}
    }
    OUTPUT:
    RETVAL

CORBA::Object
string_to_object (self, str)
    CORBA::ORB self;
    char *     str;
    CODE:
    try {
        RETVAL = self->string_to_object (str);
    } catch (CORBA::SystemException &ex) {
	pmico_throw (pmico_system_except (ex._repoid (),
					  ex.minor (),
					  ex.completed ()));
    }
    OUTPUT:
    RETVAL

bool
preload (self, id)
    CORBA::ORB self;
    char *     id
    CODE:
    RETVAL = (pmico_load_contained (NULL, self, id) != 0);
    OUTPUT:
    RETVAL

void 
run (self)
    CORBA::ORB self;
    CODE:
    self->run();

void
shutdown (self, wait_for_completion)
    CORBA::ORB self;
    SV *wait_for_completion;
    CODE:
    self->shutdown (SvTRUE (wait_for_completion));

void
perform_work (self)
    CORBA::ORB self;
    CODE:
    self->perform_work ();

int
work_pending (self)
    CORBA::ORB self;
    CODE:
    RETVAL = self->work_pending ();
    OUTPUT:
    RETVAL

void
DESTROY (self)
    CORBA::ORB self
    CODE:
    CORBA::release (self);

MODULE = CORBA::MICO		PACKAGE = CORBA::Object

CORBA::Object
_get_interface (self)
    CORBA::Object self;
    CODE:
    try {
      RETVAL = self->_get_interface();
    } catch (CORBA::SystemException &ex) {
      pmico_throw (pmico_system_except(ex._repoid(),ex.minor(),ex.completed()));
    }
    OUTPUT:
    RETVAL

int
_non_existent (self)
    CORBA::Object self;
    CODE:
    RETVAL = self->_non_existent();
    OUTPUT:
    RETVAL

int
_is_a (self, repoId)
    CORBA::Object self;
    char * repoId;
    CODE:
    try {
      RETVAL = self->_is_a(repoId);
    } catch (CORBA::SystemException &ex) {
      pmico_throw (pmico_system_except(ex._repoid(),ex.minor(),ex.completed()));
    }
    OUTPUT:
    RETVAL

int
_is_equivalent (self, obj)
    CORBA::Object self;
    CORBA::Object obj;
    CODE:
    try {
      RETVAL = self->_is_equivalent((CORBA::Object_ptr)obj);
    } catch (CORBA::SystemException &ex) {
      pmico_throw (pmico_system_except(ex._repoid(),ex.minor(),ex.completed()));
    }
    OUTPUT:
    RETVAL

unsigned long
_hash (self, maximum)
    CORBA::Object self;
    unsigned long maximum;
    CODE:
    try {
      RETVAL = self->_hash(maximum);
    } catch (CORBA::SystemException &ex) {
      pmico_throw (pmico_system_except(ex._repoid(),ex.minor(),ex.completed()));
    }
    OUTPUT:
    RETVAL

char *
_repoid (self)
    CORBA::Object self;
    CODE:
    RETVAL = (char *)self->_repoid ();
    OUTPUT:
    RETVAL

char *
_ident (self)
    CORBA::Object self;
    CODE:
    RETVAL = (char *)self->_ident ();
    OUTPUT:
    RETVAL

CORBA::Object
_self (self)
    CORBA::Object self
    CODE:
    RETVAL = self;
    OUTPUT:
    RETVAL

void
DESTROY (self)
    CORBA::Object self
    CODE:
    pmico_objref_destroy (self);
    CORBA::release (self);

MODULE = CORBA::MICO		PACKAGE = CORBA::TypeCode

SV *
new (pkg, id)
    char *id
    CODE:
    RETVAL = pmico_lookup_typecode (id);
    if (RETVAL == NULL)
        croak("Cannot find typecode for '%s'", id);
    OUTPUT:
    RETVAL

char *
kind (self)
    CORBA::TypeCode self
    CODE:
    RETVAL = (char*)TCKind_to_str( self->kind () );
    OUTPUT:
    RETVAL

bool
equal (self, tc)
    CORBA::TypeCode self
    CORBA::TypeCode tc
    CODE:
    RETVAL = self->equal (tc);
    OUTPUT:
    RETVAL

bool 
equivalent (self, tc)
    CORBA::TypeCode self
    CORBA::TypeCode tc
    CODE:
    RETVAL = self->equivalent (tc);
    OUTPUT:
    RETVAL

CORBA::TypeCode
get_compact_typecode (self)
    CORBA::TypeCode self
    CODE:
    RETVAL = self->get_compact_typecode ();
    OUTPUT:
    RETVAL

char *
id (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = (char *)self->id ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char *
name (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = (char *)self->name ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
unsigned long
member_count (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->member_count ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char *
member_name (self, index)
    CORBA::TypeCode self
    unsigned long index
    CODE:
    try {
	RETVAL = (char *)self->member_name (index);
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::TypeCode
member_type (self, index)
    CORBA::TypeCode self
    unsigned long index
    CODE:
    try {
	RETVAL = self->member_type (index);
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::Any
member_label (self, index)
    CORBA::TypeCode self
    unsigned long index
    CODE:
    try {
	RETVAL = self->member_label (index);
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

CORBA::TypeCode
discriminator_type (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->discriminator_type ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

long
default_index (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->default_index ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
unsigned long
length (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->length ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

CORBA::TypeCode
content_type (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->content_type ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

int
fixed_digits (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->fixed_digits ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
int
fixed_scale (self)
    CORBA::TypeCode self
    CODE:
    try {
	RETVAL = self->fixed_scale ();
    } catch (CORBA::TypeCode::BadKind &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
void
DESTROY (self)
    CORBA::TypeCode self
    CODE:
    CORBA::release (self);

MODULE = CORBA::MICO            PACKAGE = CORBA::LongLong

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
	
MODULE = CORBA::MICO            PACKAGE = CORBA::ULongLong

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
	
MODULE = CORBA::MICO            PACKAGE = CORBA::LongDouble

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
	
MODULE = CORBA::MICO            PACKAGE = PortableServer::POA

char *
PortableServer::POA::_get_the_name ()
    CODE:
    RETVAL = (char *)THIS->the_name();
    OUTPUT:
    RETVAL

PortableServer::POA *
PortableServer::POA::_get_the_parent ()
    CODE:
    RETVAL = THIS->the_parent();
    OUTPUT:
    RETVAL

PortableServer::POAManager *
PortableServer::POA::_get_the_POAManager ()
    CODE:
    RETVAL = THIS->the_POAManager();
    OUTPUT:
    RETVAL

CORBA::Object
PortableServer::POA::_get_the_activator ()
    CODE:
    RETVAL = THIS->the_activator();
    OUTPUT:
    RETVAL

void
PortableServer::POA::_set_the_activator (obj)
    CORBA::Object obj
    CODE:
    PortableServer::AdapterActivator_var activator = 
        PortableServer::AdapterActivator::_narrow (obj);
    if (!activator)
	croak ("activator must be of type PortableServer::AdapterActivator");
    THIS->the_activator (activator);

PortableServer::POA *
PortableServer::POA::create_POA (adapter_name, mngr_sv, ...)
    char *adapter_name
    SV *mngr_sv
    CODE:
    CORBA::PolicyList_var policies;
    PortableServer::POAManager *mngr;
    MICO_ULong npolicies;
    if (items % 2 != 1)
        croak("PortableServer::POA::create_POA requires an even number of arguments\n");

    if (SvOK (mngr_sv)) {
	if (sv_derived_from(mngr_sv, "PortableServer::POAManager")) {
	    IV tmp = SvIV((SV*)SvRV(mngr_sv));
	    mngr = (PortableServer__POAManager *) tmp;
	}
	else
	    croak("mngr is not of type PortableServer::POAManager");
    } else {
        mngr = PortableServer::POAManager::_nil();
    }

    npolicies = (items - 3) / 2;
    policies = new CORBA::PolicyList (npolicies);
    policies->length (npolicies);
    for (MICO_ULong i=0 ; i<npolicies; i++)
        policies[i] = make_policy (THIS, SvPV(ST(3+i*2), PL_na), 
				   SvPV(ST(4+i*2), PL_na));

    try {
	RETVAL = THIS->create_POA (adapter_name, mngr, policies);
    } catch (PortableServer::POA::AdapterAlreadyExists &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::InvalidPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

    OUTPUT:
    RETVAL

void
PortableServer::POA::destroy (etherealize_objects, wait_for_completion)
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    THIS->destroy (SvTRUE (etherealize_objects),
		   SvTRUE (wait_for_completion));

CORBA::Object
PortableServer::POA::get_servant_manager ()
    CODE:
    try {
        RETVAL = THIS->get_servant_manager ();
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

void
PortableServer::POA::set_servant_manager (obj)
    CORBA::Object obj
    CODE:
    PortableServer::ServantManager *manager = PortableServer::ServantManager::_narrow(obj);
    if (CORBA::is_nil (manager))
	croak ("Servant manager must be a PortableServer::ServantManager\n");
    try {
	THIS->set_servant_manager (manager);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

PortableServer::ServantBase
PortableServer::POA::get_servant ()
    CODE:
    try {
        RETVAL = THIS->get_servant ();
    } catch (PortableServer::POA::NoServant &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

void
PortableServer::POA::set_servant (servant)
    PortableServer::ServantBase servant
    CODE:
    try {
        THIS->set_servant (servant);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

PortableServer::ObjectId
PortableServer::POA::activate_object (servant)
    PortableServer::ServantBase servant
    CODE:
    try {
        RETVAL = THIS->activate_object (servant);
    } catch (PortableServer::POA::ServantAlreadyActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

void
PortableServer::POA::activate_object_with_id (id, servant)
    PortableServer::ServantBase servant
    PortableServer::ObjectId id
    CODE:
    try {
        THIS->activate_object_with_id (id, servant);
    } catch (PortableServer::POA::ServantAlreadyActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::ObjectAlreadyActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
PortableServer::POA::deactivate_object (id)
    PortableServer::ObjectId id
    CODE:
    try {
        THIS->deactivate_object (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

CORBA::Object
PortableServer::POA::create_reference (intf)
    char *intf
    CODE:
    try {
        RETVAL = THIS->create_reference (intf);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
PortableServer::POA::create_reference_with_id (oid, intf)
    PortableServer::ObjectId oid
    char *intf
    CODE:
    try {
        RETVAL = THIS->create_reference_with_id (oid, intf);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ObjectId
PortableServer::POA::servant_to_id (servant)
    PortableServer::ServantBase servant
    CODE:
    try {
        RETVAL = THIS->servant_to_id (servant);
    } catch (PortableServer::POA::ServantNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
PortableServer::POA::servant_to_reference (servant)
    PortableServer::ServantBase servant
    CODE:
    try {
        RETVAL = THIS->servant_to_reference (servant);
    } catch (PortableServer::POA::ServantNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ServantBase
PortableServer::POA::reference_to_servant (reference)
    CORBA::Object       reference
    CODE:
    try {
        RETVAL = THIS->reference_to_servant (reference);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongAdapter &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ObjectId
PortableServer::POA::reference_to_id (reference)
    CORBA::Object       reference
    CODE:
    try {
        RETVAL = THIS->reference_to_id (reference);
    } catch (PortableServer::POA::WrongAdapter &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ServantBase
PortableServer::POA::id_to_servant (id)
    PortableServer::ObjectId id
    CODE:
    try {
        RETVAL = THIS->id_to_servant (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
PortableServer::POA::id_to_reference (id)
    PortableServer::ObjectId id
    CODE:
    try {
        RETVAL = THIS->id_to_reference (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

void
PortableServer::POA::DESTROY ()
    CODE:
    CORBA::release (THIS);

MODULE = CORBA::MICO            PACKAGE = PortableServer::POAManager

void
PortableServer::POAManager::activate ()
    CODE:
    try {
        THIS->activate ();
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
PortableServer::POAManager::hold_requests (wait_for_completion)
    SV *wait_for_completion
    CODE:
    try {
	THIS->hold_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
PortableServer::POAManager::discard_requests (wait_for_completion)
    SV *wait_for_completion
    CODE:
    try {
	THIS->discard_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
PortableServer::POAManager::deactivate (etherealize_objects, wait_for_completion)
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    try {
	THIS->deactivate (SvTRUE (etherealize_objects),
			  SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

char *
PortableServer::POAManager::get_state ()
    CODE:
		PortableServer::POAManager::State state;
		state = THIS->get_state();
		switch (state) {
			case PortableServer::POAManager::HOLDING:
				RETVAL = "HOLDING";
				break;

			case PortableServer::POAManager::ACTIVE:
				RETVAL = "ACTIVE";
				break;

			case PortableServer::POAManager::DISCARDING:
				RETVAL = "DISCARDING";
				break;

			case PortableServer::POAManager::INACTIVE:
			default: // compiler complains otherwise
				RETVAL = "INACTIVE";
				break;
		}
		OUTPUT:
		RETVAL

void
PortableServer::POAManager::DESTROY ()
    CODE:
    CORBA::release (THIS);

MODULE = CORBA::MICO            PACKAGE = PortableServer::Current

PortableServer::POA *
PortableServer::Current::get_POA ()
    CODE:
    try {
	RETVAL = THIS->get_POA ();
    } catch (PortableServer::Current::NoContext &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
    
PortableServer::ObjectId
PortableServer::Current::get_object_id ()
    CODE:
    try {
	RETVAL = THIS->get_object_id ();
    } catch (PortableServer::Current::NoContext &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
void
PortableServer::Current::DESTROY ()
    CODE:
    CORBA::release (THIS);


MODULE = CORBA::MICO            PACKAGE = PortableServer::ServantBase

IV
_pmico_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new PMicoServant (self);
    RETVAL = (IV)res;
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO            PACKAGE = POA_PortableServer::AdapterActivator

IV
_pmico_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new PMicoAdapterActivator (self);
    RETVAL = (IV)res;
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO            PACKAGE = POA_PortableServer::ServantActivator

IV
_pmico_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new PMicoServantActivator (self);
    RETVAL = (IV)res;
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO            PACKAGE = POA_PortableServer::ServantLocator

IV
_pmico_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new PMicoServantLocator (self);
    RETVAL = (IV)res;
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = CORBA::MICO::InstVars

void
DESTROY (self)
    SV *self;
    CODE:
    pmico_instvars_destroy ((PMicoInstVars *)SvPVX(SvRV(self)));

MODULE = CORBA::MICO		PACKAGE = CORBA::Dispatcher

CORBA::DispatcherCallback
rd_event (self, fd, callback, ...)
    CORBA::Dispatcher self
    I32 fd
    SV *callback
    CODE:
    AV *args = newAV();
    int i = 3;
    while (i < items)
	av_push (args, newSVsv(ST(i)));
	
    RETVAL = new PMicoDispatcherCallback (newSVsv(callback), args);
    self->rd_event (RETVAL, fd);
    OUTPUT:
    RETVAL

CORBA::DispatcherCallback
wr_event (self, fd, callback, ...)
    CORBA::Dispatcher self
    I32 fd
    SV *callback
    CODE:
    AV *args = newAV();
    int i = 3;
    while (i < items)
	av_push (args, newSVsv(ST(i)));
	
    RETVAL = new PMicoDispatcherCallback (callback, args);
    self->wr_event (RETVAL, fd);
    OUTPUT:
    RETVAL

CORBA::DispatcherCallback
ex_event (self, fd, callback, ...)
    CORBA::Dispatcher self
    I32 fd
    SV *callback
    CODE:
    AV *args = newAV();
    int i = 3;
    while (i < items)
	av_push (args, newSVsv(ST(i)));
	
    RETVAL = new PMicoDispatcherCallback (callback, args);
    self->ex_event (RETVAL, fd);
    OUTPUT:
    RETVAL

CORBA::DispatcherCallback
tm_event (self, timeout, callback, ...)
    CORBA::Dispatcher self
    U32 timeout
    SV *callback
    CODE:
    AV *args = newAV();
    int i = 3;
    while (i < items)
	av_push (args, newSVsv(ST(i)));
	
    RETVAL = new PMicoDispatcherCallback (callback, args);
    self->tm_event (RETVAL, timeout);
    OUTPUT:
    RETVAL

void
remove (self, cb)
    CORBA::Dispatcher self
    CORBA::DispatcherCallback cb
    CODE:
    self->remove (cb, CORBA::Dispatcher::All);

void
DESTROY (self)
    CORBA::Dispatcher self;
    CODE:
    if (self)
	delete self;

#ifdef HAVE_GTK

MODULE = CORBA::MICO		PACKAGE = CORBA::MICO::GtkDispatcher

CORBA::MICO::GtkDispatcher
new (self)
    CODE:
    {
	GtkFunctions funcs;
	
	funcs.gtk_main_iteration = 
	  (gint (*) (void))get_c_func ("gtk_main_iteration");
	funcs.gtk_timeout_add = 
	  (guint (*) (guint32, GtkFunction, gpointer))
	     get_c_func ("gtk_timeout_add");
	funcs.gtk_timeout_remove = 
	  (void (*) (guint))get_c_func ("gtk_timeout_remove");
	funcs.gdk_input_add = 
	  (gint (*) (gint, GdkInputCondition, GdkInputFunction, gpointer))
	     get_c_func ("gdk_input_add");
	funcs.gdk_input_remove = 
	  (void (*) (gint)) get_c_func ("gdk_input_remove");

	RETVAL = new GtkDispatcher (&funcs);
    }
    OUTPUT:
    RETVAL

#endif /* HAVE_GTK */

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynAny
void
DESTROY (self)
    DynamicAny::DynAny self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

CORBA::TypeCode
type (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->type();
    OUTPUT:
    RETVAL

void
assign (self, dyn_any)
    DynamicAny::DynAny self
    DynamicAny::DynAny dyn_any
    CODE:
    try {
         self->assign( dyn_any );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
from_any (self, any)
    DynamicAny::DynAny self
    CORBA::Any any
    CODE:
    try {
         self->from_any( *any );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

CORBA::Any
to_any (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->to_any();
    OUTPUT:
    RETVAL

bool
equal (self, dyn_any)
    DynamicAny::DynAny self
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = self->equal(dyn_any);
    OUTPUT:
    RETVAL

void
destroy (self)
    DynamicAny::DynAny self
    CODE:
    self->destroy();

DynamicAny::DynAny
copy (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->copy();
    OUTPUT:
    RETVAL

void
insert_boolean (self,value)
    DynamicAny::DynAny self
    bool value
    CODE:
    try {
      self->insert_boolean((CORBA::Boolean)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_octet (self,value)
    DynamicAny::DynAny self
    unsigned char value
    CODE:
    try {
      self->insert_octet((CORBA::Octet)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_char (self,value)
    DynamicAny::DynAny self
    char value
    CODE:
    try {
      self->insert_char((CORBA::Char)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_short (self,value)
    DynamicAny::DynAny self
    short value
    CODE:
    try {
      self->insert_short((CORBA::Short)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_ushort (self,value)
    DynamicAny::DynAny self
    unsigned short value
    CODE:
    try {
      self->insert_ushort((CORBA::UShort)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_long (self,value)
    DynamicAny::DynAny self
    long value
    CODE:
    try {
      self->insert_long((CORBA::Long)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_ulong (self,value)
    DynamicAny::DynAny self
    unsigned long value
    CODE:
    try {
      self->insert_ulong((CORBA::ULong)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_float (self,value)
    DynamicAny::DynAny self
    double value
    CODE:
    try {
      self->insert_float((CORBA::Float)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_double (self,value)
    DynamicAny::DynAny self
    double value
    CODE:
    try {
      self->insert_double((CORBA::Double)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_string (self,value)
    DynamicAny::DynAny self
    char* value
    CODE:
    try {
      self->insert_string((const char*)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_reference (self,value)
    DynamicAny::DynAny self
    CORBA::Object value
    CODE:
    try {
      self->insert_reference((CORBA::Object_ptr)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_typecode (self,value)
    DynamicAny::DynAny self
    CORBA::TypeCode value
    CODE:
    try {
      self->insert_typecode((CORBA::TypeCode_ptr)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_longlong (self,value)
    DynamicAny::DynAny self
    CORBA::LongLong value
    CODE:
    try {
      self->insert_longlong(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_ulonglong (self,value)
    DynamicAny::DynAny self
    CORBA::ULongLong value
    CODE:
    try {
      self->insert_ulonglong(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_longdouble (self,value)
    DynamicAny::DynAny self
    CORBA::LongDouble value
    CODE:
    try {
      self->insert_longdouble(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

# void insert_wchar(in wchar value)
# void insert_wstring(in wstring value)

void
insert_any (self,value)
    DynamicAny::DynAny self
    CORBA::Any value
    CODE:
    try {
      self->insert_any(*value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

void
insert_dyn_any (self,value)
    DynamicAny::DynAny self
    DynamicAny::DynAny value
    CODE:
    try {
      self->insert_dyn_any(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

# void insert_val(in ValueBase value)

bool
get_boolean (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_boolean();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
   
unsigned char
get_octet (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_octet();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char
get_char (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_char();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
short
get_short (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_short();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
unsigned short
get_ushort (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_ushort();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
long
get_long (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_long();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
unsigned long
get_ulong (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_ulong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
double
get_float (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_float();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
double
get_double (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_double();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char*
get_string (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_string();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::Object
get_reference (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_reference();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::TypeCode
get_typecode (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_typecode();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::LongLong
get_longlong (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_longlong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::ULongLong
get_ulonglong (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_ulonglong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::LongDouble
get_longdouble (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_longdouble();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
# wchar get_wchar()
# wstring get_wstring()

CORBA::Any
get_any (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_any();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
DynamicAny::DynAny
get_dyn_any (self)
    DynamicAny::DynAny self
    CODE:
    try {
      RETVAL = self->get_dyn_any();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
# ValueBase get_val()

bool
seek (self,index)
    DynamicAny::DynAny self
    long index
    CODE:
    RETVAL = self->seek(index);
    OUTPUT:
    RETVAL

void
rewind (self)
    DynamicAny::DynAny self
    CODE:
    self->rewind();

bool
next (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->next();
    OUTPUT:
    RETVAL

unsigned long
component_count (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->component_count();
    OUTPUT:
    RETVAL

DynamicAny::DynAny
current_component (self)
    DynamicAny::DynAny self
    CODE:
    RETVAL = self->current_component();
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynFixed
void
DESTROY (self)
    DynamicAny::DynFixed self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

char*
get_value (self)
    DynamicAny::DynFixed self
    CODE:
    RETVAL = self->get_value();
    OUTPUT:
    RETVAL

#bool	CORBA V2.3: boolean set_value(in string val) //XXX
void
set_value (self,val)
    DynamicAny::DynFixed self
    char* val
    CODE:
    try {
      self->set_value(val);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    
# narrow helper
DynamicAny::DynFixed
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynFixed::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynEnum
void
DESTROY (self)
    DynamicAny::DynEnum self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

char*
get_as_string(self)
    DynamicAny::DynEnum self
    CODE:
    RETVAL = self->get_as_string();
    OUTPUT:
    RETVAL

void
set_as_string(self,value)
    DynamicAny::DynEnum self
    char* value
    CODE:
    try {
      self->set_as_string(value);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }

unsigned long
get_as_ulong(self)
    DynamicAny::DynEnum self
    CODE:
    RETVAL = self->get_as_ulong();
    OUTPUT:
    RETVAL

void
set_as_ulong(self,value)
    DynamicAny::DynEnum self
    unsigned long value
    CODE:
    try {
      self->set_as_ulong(value);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }


# narrow helper
DynamicAny::DynEnum
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynEnum::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynStruct
void
DESTROY (self)
    DynamicAny::DynStruct self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);


char*
current_member_name(self)
    DynamicAny::DynStruct self
    CODE:
    try {
      RETVAL = self->current_member_name();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

char*
current_member_kind(self)
    DynamicAny::DynStruct self
    CODE:
    try {
      RETVAL = (char*) TCKind_to_str( self->current_member_kind() );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

AV*
get_members(self)
    DynamicAny::DynStruct self
    CODE:
      DynamicAny::NameValuePairSeq_var mbrs = self->get_members();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pmico_any_to_sv(&mbrs[i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    if( !SvROK(members) )
      croak("members - must be an array reference");
    members = SvRV(members);
    if( SvTYPE(members) != SVt_PVAV )
      croak("members - must be an array reference");
    DynamicAny::NameValuePairSeq_var mbrs = new DynamicAny::NameValuePairSeq;
    mbrs->length(av_len((AV*)members)+1);
    for( I32 i = 0; i <= av_len((AV*)members); i++ ) {
      SV* sv = *av_fetch( (AV*)members, i, 0 );
      if( !SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV) )
        croak("members - must be array of hashes");
      HV *hv = (HV *)SvRV(sv);

      SV** id    = hv_fetch( hv, "id",    2, 0 );
      if( !id || !SvPOK(*id) )
        croak("members - must contain string field 'id'");
      mbrs[(unsigned long)i].id = CORBA::string_dup( SvPV(*id, PL_na) );

      SV** value = hv_fetch( hv, "value", 5, 0 );
      if( !value || !sv_isa(*value, "CORBA::Any"))
        croak("members - must contain CORBA::Any field 'value'");
      IV tmp = SvIV((SV*)SvRV(*value));
      CORBA::Any *any = INT2PTR(CORBA::Any*,tmp);
      mbrs[(unsigned long)i].value = *any;
    }
    try {
      self->set_members( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
AV*
get_members_as_dyn_any(self)
    DynamicAny::DynStruct self
    CODE:
      DynamicAny::NameDynAnyPairSeq_var mbrs = self->get_members_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[(unsigned long)i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pmico_dyn_any_to_sv(mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members_as_dyn_any(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    if( !SvROK(members) )
      croak("members - must be an array reference");
    members = SvRV(members);
    if( SvTYPE(members) != SVt_PVAV )
      croak("members - must be an array reference");
    DynamicAny::NameDynAnyPairSeq_var mbrs = new DynamicAny::NameDynAnyPairSeq;
    mbrs->length(av_len((AV*)members)+1);
    for( I32 i = 0; i <= av_len((AV*)members); i++ ) {
      SV* sv = *av_fetch( (AV*)members, i, 0 );
      if( !SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV) )
        croak("members - must be array of hashes");
      HV *hv = (HV *)SvRV(sv);

      SV** id    = hv_fetch( hv, "id",    2, 0 );
      if( !id || !SvPOK(*id) )
        croak("members - must contain string field 'id'");
      mbrs[(unsigned long)i].id = CORBA::string_dup( SvPV(*id, PL_na) );

      SV** value = hv_fetch( hv, "value", 5, 0 );
      if( !value || !sv_isa(*value, "DynamicAny::DynAny"))
        croak("members - must contain DynamicAny::DynAny field 'value'");
      IV tmp = SvIV((SV*)SvRV(*value));
      DynamicAny::DynAny *dynany = INT2PTR(DynamicAny::DynAny*,tmp);
      mbrs[(unsigned long)i].value = dynany->copy();
    }
    try {
      self->set_members_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
# narrow helper
DynamicAny::DynStruct
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynStruct::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynUnion
void
DESTROY (self)
    DynamicAny::DynUnion self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

DynamicAny::DynAny
get_discriminator (self)
    DynamicAny::DynUnion self
    CODE:
    RETVAL = self->get_discriminator();
    OUTPUT:
    RETVAL

void
set_discriminator (self,d)
    DynamicAny::DynUnion self
    DynamicAny::DynAny d
    CODE:
    try {
      self->set_discriminator(d);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }

void
set_to_default_member (self)
    DynamicAny::DynUnion self
    CODE:
    try {
      self->set_to_default_member();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }

void
set_to_no_active_member (self)
    DynamicAny::DynUnion self
    CODE:
    try {
      self->set_to_no_active_member();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }

bool
has_no_active_member (self)
    DynamicAny::DynUnion self
    CODE:
    RETVAL = self->has_no_active_member();
    OUTPUT:
    RETVAL

char *
discriminator_kind (self)
    DynamicAny::DynUnion self
    CODE:
    RETVAL = (char*)TCKind_to_str( self->discriminator_kind() );
    OUTPUT:
    RETVAL

DynamicAny::DynAny
member (self)
    DynamicAny::DynUnion self
    CODE:
    try {
      RETVAL = self->member();
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char*
member_name (self)
    DynamicAny::DynUnion self
    CODE:
    try {
      RETVAL = self->member_name();
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
char*
member_kind (self)
    DynamicAny::DynUnion self
    CODE:
    try {
      RETVAL = (char*)TCKind_to_str( self->member_kind() );
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

# narrow helper
DynamicAny::DynUnion
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynUnion::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynSequence
void
DESTROY (self)
    DynamicAny::DynSequence self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

unsigned long
get_length (self)
    DynamicAny::DynSequence self
    CODE:
    RETVAL = self->get_length();
    OUTPUT:
    RETVAL

void
set_length (self,len)
    DynamicAny::DynSequence self
    unsigned long len
    CODE:
    try {
      self->set_length(len);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
      pmico_throw (pmico_builtin_except (&ex));
    }

AV*
get_elements (self)
    DynamicAny::DynSequence self
    CODE:
    DynamicAny::AnySeq_var els = self->get_elements();
    RETVAL = newAV();
    av_extend( RETVAL, els->length() );
    for( CORBA::ULong i = 0; i < els->length(); i++ ) {
      av_push( RETVAL, pmico_any_to_sv(&els[i]) );
    }
    OUTPUT:
    RETVAL

void
set_elements(self,elements)
    DynamicAny::DynSequence self
    SV* elements
    CODE:
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::AnySeq_var mbrs = new DynamicAny::AnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
      SV* sv = *av_fetch( (AV*)elements, i, 0 );
      if( !sv_isa(sv, "CORBA::Any"))
        croak("elements - must contain CORBA::Any values");
      IV tmp = SvIV((SV*)SvRV(sv));
      CORBA::Any *any = INT2PTR(CORBA::Any*,tmp);
      mbrs[(unsigned long)i] = *any;
    }
    try {
      self->set_elements( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
AV*
get_elements_as_dyn_any(self)
    DynamicAny::DynSequence self
    CODE:
      DynamicAny::DynAnySeq_var mbrs = self->get_elements_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        av_push( RETVAL, pmico_dyn_any_to_sv(mbrs[(unsigned long)i]) );
      }
    OUTPUT:
      RETVAL

void
set_elements_as_dyn_any(self,elements)
    DynamicAny::DynSequence self
    SV* elements
    CODE:
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::DynAnySeq_var mbrs = new DynamicAny::DynAnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
      SV* sv = *av_fetch( (AV*)elements, i, 0 );
      if( !sv_isa( sv, "DynamicAny::DynAny" ) )
        croak("elements - must contain DynamicAny::DynAny values");
      IV tmp = SvIV((SV*)SvRV(sv));
      DynamicAny::DynAny *dynany = INT2PTR(DynamicAny::DynAny*,tmp);
      mbrs[(unsigned long)i] = dynany->copy();
    }
    try {
      self->set_elements_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
# narrow helper
DynamicAny::DynSequence
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynSequence::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynArray
void
DESTROY (self)
    DynamicAny::DynArray self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

AV*
get_elements (self)
    DynamicAny::DynArray self
    CODE:
    DynamicAny::AnySeq_var els = self->get_elements();
    RETVAL = newAV();
    av_extend( RETVAL, els->length() );
    for( CORBA::ULong i = 0; i < els->length(); i++ ) {
      av_push( RETVAL, pmico_any_to_sv(&els[i]) );
    }
    OUTPUT:
    RETVAL

void
set_elements(self,elements)
    DynamicAny::DynArray self
    SV* elements
    CODE:
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::AnySeq_var mbrs = new DynamicAny::AnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
      SV* sv = *av_fetch( (AV*)elements, i, 0 );
      if( !sv_isa(sv, "CORBA::Any"))
        croak("elements - must contain CORBA::Any values");
      IV tmp = SvIV((SV*)SvRV(sv));
      CORBA::Any *any = INT2PTR(CORBA::Any*,tmp);
      mbrs[(unsigned long)i] = *any;
    }
    try {
      self->set_elements( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
AV*
get_elements_as_dyn_any(self)
    DynamicAny::DynArray self
    CODE:
      DynamicAny::DynAnySeq_var mbrs = self->get_elements_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        av_push( RETVAL, pmico_dyn_any_to_sv(mbrs[(unsigned long)i]) );
      }
    OUTPUT:
      RETVAL

void
set_elements_as_dyn_any(self,elements)
    DynamicAny::DynArray self
    SV* elements
    CODE:
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::DynAnySeq_var mbrs = new DynamicAny::DynAnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
      SV* sv = *av_fetch( (AV*)elements, i, 0 );
      if( !sv_isa( sv, "DynamicAny::DynAny" ) )
        croak("elements - must contain DynamicAny::DynAny values");
      IV tmp = SvIV((SV*)SvRV(sv));
      DynamicAny::DynAny *dynany = INT2PTR(DynamicAny::DynAny*,tmp);
      mbrs[(unsigned long)i] = dynany->copy();
    }
    try {
      self->set_elements_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
# narrow helper
DynamicAny::DynArray
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynArray::_narrow(dyn_any);
    OUTPUT:
    RETVAL

MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynValue
void
DESTROY (self)
    DynamicAny::DynValue self
    CODE:
//    self->destroy();		//XXX
    CORBA::release (self);

char*
current_member_name (self)
    DynamicAny::DynValue self
    CODE:
    try {
      RETVAL = self->current_member_name();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
	
char*
current_member_kind(self)
    DynamicAny::DynValue self
    CODE:
    try {
      RETVAL = (char*) TCKind_to_str( self->current_member_kind() );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL

AV*
get_members(self)
    DynamicAny::DynStruct self
    CODE:
      DynamicAny::NameValuePairSeq_var mbrs = self->get_members();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[(unsigned long)i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pmico_any_to_sv(&mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    if( !SvROK(members) )
      croak("members - must be an array reference");
    members = SvRV(members);
    if( SvTYPE(members) != SVt_PVAV )
      croak("members - must be an array reference");
    DynamicAny::NameValuePairSeq_var mbrs = new DynamicAny::NameValuePairSeq;
    mbrs->length(av_len((AV*)members)+1);
    for( I32 i = 0; i <= av_len((AV*)members); i++ ) {
      SV* sv = *av_fetch( (AV*)members, i, 0 );
      if( !SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV) )
        croak("members - must be array of hashes");
      HV *hv = (HV *)SvRV(sv);

      SV** id    = hv_fetch( hv, "id",    2, 0 );
      if( !id || !SvPOK(*id) )
        croak("members - must contain string field 'id'");
      mbrs[(unsigned long)i].id = CORBA::string_dup( SvPV(*id, PL_na) );

      SV** value = hv_fetch( hv, "value", 5, 0 );
      if( !value || !sv_isa(*value, "CORBA::Any"))
        croak("members - must contain CORBA::Any field 'value'");
      IV tmp = SvIV((SV*)SvRV(*value));
      CORBA::Any *any = INT2PTR(CORBA::Any*,tmp);
      mbrs[(unsigned long)i].value = *any;
    }
    try {
      self->set_members( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
AV*
get_members_as_dyn_any(self)
    DynamicAny::DynStruct self
    CODE:
      DynamicAny::NameDynAnyPairSeq_var mbrs = self->get_members_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[(unsigned long)i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pmico_dyn_any_to_sv(mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members_as_dyn_any(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    if( !SvROK(members) )
      croak("members - must be an array reference");
    members = SvRV(members);
    if( SvTYPE(members) != SVt_PVAV )
      croak("members - must be an array reference");
    DynamicAny::NameDynAnyPairSeq_var mbrs = new DynamicAny::NameDynAnyPairSeq;
    mbrs->length(av_len((AV*)members)+1);
    for( I32 i = 0; i <= av_len((AV*)members); i++ ) {
      SV* sv = *av_fetch( (AV*)members, i, 0 );
      if( !SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVHV) )
        croak("members - must be array of hashes");
      HV *hv = (HV *)SvRV(sv);

      SV** id    = hv_fetch( hv, "id",    2, 0 );
      if( !id || !SvPOK(*id) )
        croak("members - must contain string field 'id'");
      mbrs[(unsigned long)i].id = CORBA::string_dup( SvPV(*id, PL_na) );

      SV** value = hv_fetch( hv, "value", 5, 0 );
      if( !value || !sv_isa(*value, "DynamicAny::DynAny"))
        croak("members - must contain DynamicAny::DynAny field 'value'");
      IV tmp = SvIV((SV*)SvRV(*value));
      DynamicAny::DynAny *dynany = INT2PTR(DynamicAny::DynAny*,tmp);
      mbrs[(unsigned long)i].value = dynany->copy();
    }
    try {
      self->set_members_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
      
# narrow helper
DynamicAny::DynStruct
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = DynamicAny::DynStruct::_narrow(dyn_any);
    OUTPUT:
    RETVAL


MODULE = CORBA::MICO		PACKAGE = DynamicAny::DynAnyFactory

void
DynamicAny::DynAnyFactory::DESTROY ()
    CODE:
    CORBA::release (THIS);

DynamicAny::DynAny
DynamicAny::DynAnyFactory::create_dyn_any(value)
    CORBA::Any value
    CODE:
    try {
	RETVAL = THIS->create_dyn_any(*value);
    } catch (DynamicAny::DynAnyFactory::InconsistentTypeCode &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
DynamicAny::DynAny
DynamicAny::DynAnyFactory::create_dyn_any_from_type_code(type)
    CORBA::TypeCode type
    CODE:
    try {
	RETVAL = THIS->create_dyn_any_from_type_code(type);
    } catch (DynamicAny::DynAnyFactory::InconsistentTypeCode &ex) {
	pmico_throw (pmico_builtin_except (&ex));
    }
    OUTPUT:
    RETVAL
    
BOOT:
    pmico_init_exceptions();
    pmico_init_typecodes();
