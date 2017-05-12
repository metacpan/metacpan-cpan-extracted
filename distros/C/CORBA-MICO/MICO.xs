/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include "server.h"
#include "exttypes.h"
#include "dispatcher.h"
#include <mico/ir.h>

/* FIXME: Boot check screws up with egcs... */
#undef XS_VERSION_BOOTCHECK
#define XS_VERSION_BOOTCHECK

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

#ifdef HAVE_GTK

#undef list
#include "gtkmico.h"

typedef GtkDispatcher *CORBA__MICO__GtkDispatcher;

void *get_c_func (char *name)
{
    SV *result;
    int count;
    
    dSP;

    PUSHMARK(sp);
    XPUSHs (sv_2mortal (newSVpv (name, 0)));
    PUTBACK;
    
    count = perl_call_pv ("DynaLoader::dl_find_symbol_anywhere", 
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
	
	    ARGV = perl_get_av("ARGV", FALSE);
	    ARGV0 = perl_get_sv("0", FALSE);
	
	    argc = av_len(ARGV)+2;
	    argv = (char **)malloc (sizeof(char *)*argc);
	    argv[0] = SvPV (ARGV0, PL_na);
	    for (i=0;i<=av_len(ARGV);i++)
		argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), PL_na);
	
	    RETVAL = CORBA::ORB_init (argc, argv, id);
	    
	    av_clear (ARGV);
	    
	    for (i=1;i<argc;i++)
		av_store (ARGV, i-1, newSVpv(argv[i],0));
	
	    if (argv)
		free (argv);
	}
    }
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

SV *
resolve_initial_references (self, id)
    CORBA::ORB self;
    char *     id
    CODE:
    {
	CORBA::Object *obj = self->resolve_initial_references (id);
	
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
    OUTPUT:
    RETVAL

CORBA::Object
string_to_object (self, str)
    CORBA::ORB self;
    char *     str;
    CODE:
    RETVAL = self->string_to_object (str);
    OUTPUT:
    RETVAL

int
preload (self, id)
    CORBA::ORB self;
    char *     id
    CODE:
    pmico_load_contained (NULL, self, id);
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
	pmico_throw (pmico_system_except (ex->_repoid (),
					  ex->minor (),
					  ex->completed ()));
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
    static const char *const kinds[] = {
	"tk_null",
	"tk_void",
	"tk_short",
	"tk_long",
	"tk_ushort",
	"tk_ulong",
	"tk_float",
	"tk_double",
	"tk_boolean",
	"tk_char",
	"tk_octet",
	"tk_any",
	"tk_TypeCode",
	"tk_Principal",
	"tk_objref",
	"tk_struct",
	"tk_union",
	"tk_enum",
	"tk_string",
	"tk_sequence",
	"tk_array",
	"tk_alias",
	"tk_except",
	"tk_longlong",
	"tk_ulonglong",
	"tk_longdouble",
	"tk_wchar",
	"tk_wstring",
	"tk_fixed",
	"tk_value",
	"tk_value_box",
	"tk_native",
	"tk_abstract_interface",
    };
    CORBA::TCKind kind = self->kind ();
    if (kind < sizeof(kinds) / sizeof(kinds[0]))
	RETVAL = (char *)kinds[self->kind ()];
    else
        RETVAL = NULL;
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
    int npolicies;
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
    for (int i=0 ; i<npolicies; i++)
        policies[i] = make_policy (THIS, SvPV(ST(3+i*2), PL_na), 
				   SvPV(ST(4+i*2), PL_na));

    try {
	RETVAL = THIS->create_POA (adapter_name, mngr, policies);
    } catch (PortableServer::POA::AdapterAlreadyExists &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::InvalidPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    }

PortableServer::ServantBase
PortableServer::POA::get_servant ()
    CODE:
    try {
        RETVAL = THIS->get_servant ();
    } catch (PortableServer::POA::NoServant &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    }

PortableServer::ObjectId
PortableServer::POA::activate_object (servant)
    PortableServer::ServantBase servant
    CODE:
    try {
        RETVAL = THIS->activate_object (servant);
    } catch (PortableServer::POA::ServantAlreadyActive &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::ObjectAlreadyActive &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
    }

void
PortableServer::POA::deactivate_object (id)
    PortableServer::ObjectId id
    CODE:
    try {
        THIS->deactivate_object (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
    }

CORBA::Object
PortableServer::POA::create_reference (intf)
    char *intf
    CODE:
    try {
        RETVAL = THIS->create_reference (intf);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongAdapter &ex) {
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    }

void
PortableServer::POAManager::hold_requests (wait_for_completion)
    SV *wait_for_completion
    CODE:
    try {
	THIS->hold_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (ex));
    }

void
PortableServer::POAManager::discard_requests (wait_for_completion)
    SV *wait_for_completion
    CODE:
    try {
	THIS->discard_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pmico_throw (pmico_builtin_except (ex));
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
	pmico_throw (pmico_builtin_except (ex));
    }

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
	pmico_throw (pmico_builtin_except (ex));
    }
    OUTPUT:
    RETVAL
    
    
PortableServer::ObjectId
PortableServer::Current::get_object_id ()
    CODE:
    try {
	RETVAL = THIS->get_object_id ();
    } catch (PortableServer::Current::NoContext &ex) {
	pmico_throw (pmico_builtin_except (ex));
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


BOOT:
    pmico_init_exceptions();
    pmico_init_typecodes();
