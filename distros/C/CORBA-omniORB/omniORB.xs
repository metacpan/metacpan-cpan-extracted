/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pomni.h"
#include "server.h"
#include "exttypes.h"
#undef minor			// AIX defines such strange macros
#undef shutdown			// Win32 defines such strange macros
#undef rewind			// Win32 defines such strange macros

#ifdef HAS_PPPORT_H
#  include "ppport.h"
#endif

/* FIXME: Boot check screws up with egcs... */
#undef XS_VERSION_BOOTCHECK
#define XS_VERSION_BOOTCHECK

typedef CORBA::Object_ptr   CORBA__Object;
typedef CORBA::ORB_ptr      CORBA__ORB;
typedef CORBA::TypeCode_ptr CORBA__TypeCode;
#ifdef HAS_LongLong
typedef CORBA::LongLong     CORBA__LongLong;
typedef CORBA::ULongLong    CORBA__ULongLong;
#endif
#ifdef HAS_LongDouble
typedef CORBA::LongDouble   CORBA__LongDouble;
#endif
typedef CORBA::Object_ptr		PortableServer__POA;
typedef CORBA::Object_ptr		PortableServer__POAManager;
typedef CORBA::Object_ptr		PortableServer__Current;
typedef PortableServer::ObjectId_var	PortableServer__ObjectId;
typedef PortableServer::Servant		PortableServer__ServantBase;
typedef CORBA::Object_ptr		DynamicAny__DynAny;
typedef CORBA::Object_ptr		DynamicAny__DynFixed;
typedef CORBA::Object_ptr		DynamicAny__DynEnum;
typedef CORBA::Object_ptr		DynamicAny__DynStruct;
typedef CORBA::Object_ptr		DynamicAny__DynUnion;
typedef CORBA::Object_ptr		DynamicAny__DynSequence;
typedef CORBA::Object_ptr		DynamicAny__DynArray;
#if 0
typedef CORBA::Object_ptr		DynamicAny__DynValue;
#endif
typedef CORBA::Object_ptr		DynamicAny__DynAnyFactory;

CORBA::ORB_ptr pomni_orb = CORBA::ORB::_nil();

// Private per-interpreter context, containing the interpreter entry lock
#define MY_CXT_KEY "CORBA::omniORB::_guts" XS_VERSION
typedef struct {
    POmniRatchetLock *entry_lock;
} my_cxt_t;

START_MY_CXT

// Instantiate an entry lock for the initial Perl interpreter
static void
pomni_init_entry_lock(pTHX)
{
    MY_CXT_INIT;
    MY_CXT.entry_lock = new POmniRatchetLock;

    // Create an un-anchored blessed reference to the entry lock
    // so that it can be destroyed when the Perl interpreter is.
    SV *rv = newSV(0);
    (void) sv_setref_iv(rv, "CORBA::omniORB::EntryLock",
			PTR2IV((void *) MY_CXT.entry_lock));
}

// Instantiate an entry lock for a cloned Perl interpreter
static void
pomni_clone_entry_lock(pTHX)
{
    MY_CXT_CLONE;
    MY_CXT.entry_lock = new POmniRatchetLock;

    // Create an un-anchored blessed reference to the entry lock
    // so that it can be destroyed when the Perl interpreter is.
    SV *rv = newSV(0);
    (void) sv_setref_iv(rv, "CORBA::omniORB::EntryLock",
			PTR2IV((void *) MY_CXT.entry_lock));
}

// Return a pointer to the entry lock of the current Perl interpreter
POmniRatchetLock *
pomni_entry_lock(pTHX)
{
    if (PL_dirty)
	return 0;
    
    dMY_CXT;
    return MY_CXT.entry_lock;
}

static UV
pomni_unlock(pTHX)
{
    if (PL_dirty)
	return 0;

    dMY_CXT;
    return MY_CXT.entry_lock->release();
}

static void
pomni_relock(pTHX_ UV token)
{
    if (PL_dirty)
	return;

    dMY_CXT;
    MY_CXT.entry_lock->resume(token);
}

// Clone the CORBA::ORB object reference.
static void
pomni_clone_orb(pTHX)
{
    SV *weakref = get_sv("CORBA::omniORB::_the_orb", FALSE);
    if (weakref && SvROK(weakref)) {
	SV *iv = SvRV(weakref);
	CORBA::ORB_ptr orb = (CORBA::ORB_ptr) INT2PTR(void *, SvIV(iv));
	sv_setiv(iv, PTR2IV((void *) CORBA::ORB::_duplicate(orb)));
    }
}

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
	    return poa->create_thread_policy (PortableServer::SINGLE_THREAD_MODEL);
	  else if (!strcmp (value, "MAIN_THREAD_MODEL"))
	    return poa->create_thread_policy (PortableServer::MAIN_THREAD_MODEL);
	  else
	    croak ("ThreadPolicyValue should be \"ORB_CTRL_MODEL\", \"SINGLE_THREAD_MODEL\", or \"MAIN_THREAD_MODEL\"");
	}
      break;
    }
  croak("Policy key should be one of \"id_uniqueness\", \"id_assignment\",  \"implicit_activation\",  \"lifespan\",  \"request_processing\",  \"servant_retention\" or \"thread\"");
}

MODULE = CORBA::omniORB           PACKAGE = CORBA::omniORB

PROTOTYPES: DISABLE

BOOT:
    pomni_init_entry_lock(aTHX);
    pomni_init_exceptions(aTHX);
    pomni_init_typecodes(aTHX);

void
CLONE(...)
    CODE:
    pomni_clone_entry_lock(aTHX);
    pomni_clone_orb(aTHX);
    pomni_clone_pins(aTHX);
    pomni_clone_typecodes(aTHX);
    
char *
find_interface (repoid)
    char *repoid
    CODE:
    {
	CM_DEBUG(("find_interface %s\n", repoid));
	POmniIfaceInfo *info = pomni_find_interface_description (aTHX_ repoid);
	RETVAL = info ? (char *)info->pkg.c_str() : NULL;
    }
    OUTPUT:
    RETVAL

void
clear_interface (repoid)
    char *repoid
    CODE:
    {
#ifdef MEMCHECK
	pomni_clear_interface(aTHX_ repoid);
#endif
    }

char *
load_interface (interface)
    CORBA::Object interface
    CODE:
    {
	CORBA::InterfaceDef_var iface
	    = CORBA::InterfaceDef::_narrow (interface);
	POmniIfaceInfo *info
	    = pomni_load_contained (aTHX_ iface, CORBA::ORB::_nil(), NULL);
	RETVAL = info ? (char *)info->pkg.c_str() : NULL;
    }
    OUTPUT:
    RETVAL

void
_entry_lock_hooks ()
    PPCODE:
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVuv(PTR2UV(pomni_unlock))));
    PUSHs(sv_2mortal(newSVuv(PTR2UV(pomni_relock))));


MODULE = CORBA::omniORB           PACKAGE = CORBA

SV *
ORB_init (id)
    char *id
    CODE:
    {
	SV *weakref = get_sv("CORBA::omniORB::_the_orb", TRUE);
	if (SvROK(weakref)) {
	    RETVAL = newSV(0);
	    sv_setsv(RETVAL, weakref);
	}
	else {
	    if (CORBA::is_nil(pomni_orb)) {
		int i;
		AV *ARGV = get_av("ARGV", FALSE);
		SV *ARGV0 = get_sv("0", FALSE);
		
		AV *ARGV_copy = newAV();
		sv_2mortal((SV*)ARGV_copy);
		for (i = 0; i <= av_len(ARGV); i++)
		    av_store(ARGV_copy, i, newSVsv(*av_fetch(ARGV, i, 0)));
		
		int argc = av_len(ARGV_copy) + 2;
		char **argv = (char **) malloc (sizeof(char *) * argc);
		argv[0] = SvPV (ARGV0, PL_na);
		for (i = 0; i <= av_len(ARGV_copy); i++ )
		    argv[i+1] = SvPV( *av_fetch(ARGV_copy, i, 0), PL_na );
		
		try {
		    pomni_orb = CORBA::ORB_init (argc, argv, id);
		} catch (CORBA::SystemException &ex) {
		    if (argv)
			free (argv);
		    pomni_throw (aTHX_
				 pomni_system_except (aTHX_
						      ex._rep_id(),
						      ex.minor(),
						      ex.completed()));
		}
	    
		av_clear (ARGV);
	    
		for (i = 1; i < argc; i++)
		    av_store (ARGV, i - 1, newSVpv(argv[i], 0));
	
		if (argv)
		    free (argv);
	    }

	    RETVAL = newSV(0);
	    sv_setref_pv(RETVAL, "CORBA::ORB",
			 (void *) CORBA::ORB::_duplicate(pomni_orb));

	    sv_setsv(weakref, RETVAL);
	    sv_rvweaken(weakref);
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

MODULE = CORBA::omniORB		PACKAGE = CORBA::Any

SV *
new (pkg, type, value)
    CORBA::TypeCode type
    SV *value
    CODE:
    CORBA::Any any(type, 0);
    if (!pomni_to_any (aTHX_ &any, value)) {
	croak("Error constructing Any");
    }
    RETVAL = pomni_any_to_sv(aTHX_ any);
    OUTPUT:
    RETVAL

SV *
value (self)
    SV *self
    CODE:
    CORBA::Any any;
    pomni_any_from_sv(aTHX_ &any, self);
    RETVAL = pomni_from_any (aTHX_ &any);
    OUTPUT:
    RETVAL

CORBA::TypeCode
type (self)
    SV *self
    CODE:
    CORBA::Any any;
    pomni_any_from_sv(aTHX_ &any, self);
    RETVAL = any.type();
    OUTPUT:
    RETVAL    

MODULE = CORBA::omniORB		PACKAGE = CORBA::ORB

char *
object_to_string (self, obj)
    CORBA::ORB self
    CORBA::Object obj
    CODE:
    CORBA::String_var string = self->object_to_string (obj);
    RETVAL = (char *) string;
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
	}
        CATCH_POMNI_SYSTEMEXCEPTION
	catch (CORBA::ORB::InvalidName &ex) {
	    pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
	}
	if( strcmp( id, "DynAnyFactory" ) == 0 ) {
	    RETVAL = pomni_local_objref_to_sv(aTHX_ obj,
					      "DynamicAny::DynAnyFactory");
	} else {
	  // ugly hack
	  PortableServer::POA_ptr poa = PortableServer::POA::_narrow (obj);
	  if (!CORBA::is_nil (poa)) {
              CORBA::release(poa);
	      RETVAL = pomni_local_objref_to_sv(aTHX_ obj,
						"PortableServer::POA");
	  } else {
	      PortableServer::Current_ptr current
		  = PortableServer::Current::_narrow (obj);
	      if (!CORBA::is_nil (current)) {
                  CORBA::release(current);
		  RETVAL = pomni_local_objref_to_sv(aTHX_ obj,
						    "PortableServer::Current");
	      } else
		  RETVAL = pomni_objref_to_sv (aTHX_ obj);
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
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

SV *
cdr_encode (self, val, tc)
    CORBA::ORB self;
    SV *val;
    CORBA::TypeCode tc;
    CODE:
    {
	CORBA::Any a(tc, 0);
	if(pomni_to_any(aTHX_ &a, val)) {
	    cdrMemoryStream s;
	    a.NP_marshalDataOnly(s);
	    RETVAL = newSVpvn((char *) s.bufPtr(), s.bufSize());
	}
	else {
	    croak("Error encoding value");
	}
    }
    OUTPUT:
    RETVAL

SV *
cdr_decode (self, cdr, tc)
    CORBA::ORB self;
    SV *cdr;
    CORBA::TypeCode tc;
    CODE:
    {
	STRLEN len;
	char *buf = SvPV(cdr, len);
	cdrMemoryStream s;
	s.put_octet_array((CORBA::Octet *) buf, len);
	CORBA::Any a(tc, 0);
	a.NP_unmarshalDataOnly(s);
	RETVAL = pomni_from_any(aTHX_ &a);
    }
    OUTPUT:
    RETVAL

bool
preload (self, id)
    CORBA::ORB self;
    char *     id
    CODE:
    RETVAL = (pomni_load_contained (aTHX_ CORBA::Contained::_nil(), self, id) != 0);
    OUTPUT:
    RETVAL

void
_define_interface (self, name, cdr)
    CORBA::ORB self;
    char *     name;
    SV *       cdr;
    CODE:
    STRLEN len;
    char *buf = SvPV(cdr, len);
    cdrMemoryStream s;
    s.put_octet_array((CORBA::Octet *) buf, len);
    CORBA::InterfaceDef::FullInterfaceDescription *desc
        = new CORBA::InterfaceDef::FullInterfaceDescription();
    *desc <<= s;
    pomni_define_interface(aTHX_ name, desc);

void
_define_exception (self, name, id)
    CORBA::ORB self;
    char *     name;
    char *     id;
    CODE:
    pomni_define_exception(aTHX_ name, id);

void 
run (self)
    CORBA::ORB self;
    CODE:
    PUTBACK;
    {
	POmniPerlEntryUnlocker ul(aTHX);
	self->run();
    }
    SPAGAIN;

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
    PUTBACK;
    {
	POmniPerlEntryUnlocker ul(aTHX);
	self->perform_work ();
    }
    SPAGAIN;

int
work_pending (self)
    CORBA::ORB self;
    CODE:
    PUTBACK;
    {
	POmniPerlEntryUnlocker ul(aTHX);
	RETVAL = self->work_pending ();
    }
    SPAGAIN;
    OUTPUT:
    RETVAL

void
destroy (self)
    CORBA::ORB self
    CODE:
    PUTBACK;
    {
	POmniPerlEntryUnlocker ul(aTHX);
	self->destroy();
    }
    SPAGAIN;
#ifdef MEMCHECK
    pomni_clear_servants(aTHX);
    pomni_clear_pins(aTHX);
    pomni_clear_typecodes(aTHX);
    pomni_clear_exceptions(aTHX);
    pomni_clear_iface_repository(aTHX);
#endif

    CORBA::release(pomni_orb);
    pomni_orb = CORBA::ORB::_nil();

CORBA::TypeCode
create_alias_tc (self, id, name, original_type)
    CORBA::ORB self
    const char *id
    const char *name
    CORBA::TypeCode original_type
    CODE:
    RETVAL = self->create_alias_tc(id, name, original_type);
    OUTPUT:
    RETVAL
    
CORBA::TypeCode
create_interface_tc (self, id, name)
    CORBA::ORB self
    const char *id
    const char *name
    CODE:
    RETVAL = self->create_interface_tc(id, name);
    OUTPUT:
    RETVAL

CORBA::TypeCode
create_string_tc (self, bound)
    CORBA::ORB self
    unsigned long bound
    CODE:
    RETVAL = self->create_string_tc(bound);
    OUTPUT:
    RETVAL


CORBA::TypeCode
create_fixed_tc (self, digits, scale)
    CORBA::ORB self
    unsigned short digits
    short scale
    CODE:
    RETVAL = self->create_fixed_tc(digits, scale);
    OUTPUT:
    RETVAL

CORBA::TypeCode
create_sequence_tc (self, bound, element_type)
    CORBA::ORB self
    unsigned long bound
    CORBA::TypeCode element_type
    CODE:
    RETVAL = self->create_sequence_tc(bound, element_type);
    OUTPUT:
    RETVAL

CORBA::TypeCode
create_array_tc (self, length, element_type)
    CORBA::ORB self
    unsigned long length
    CORBA::TypeCode element_type
    CODE:
    RETVAL = self->create_array_tc(length, element_type);
    OUTPUT:
    RETVAL

CORBA::TypeCode
create_recursive_tc (self, id)
    CORBA::ORB self
    const char *id
    CODE:
    RETVAL = self->create_recursive_tc(id);
    OUTPUT:
    RETVAL

void
DESTROY (self)
    CORBA::ORB self
    CODE:
    CORBA::release (self);

MODULE = CORBA::omniORB		PACKAGE = CORBA::Object

CORBA::Object
_get_interface (self)
    CORBA::Object self;
    CODE:
    try {
        RETVAL = self->_get_interface();
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

int
_non_existent (self)
    CORBA::Object self;
    CODE:
    try {
        RETVAL = self->_non_existent();
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

int
_is_a (self, repoId)
    CORBA::Object self;
    char * repoId;
    CODE:
    try {
        RETVAL = self->_is_a(repoId);
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

int
_is_equivalent (self, obj)
    CORBA::Object self;
    CORBA::Object obj;
    CODE:
    try {
        RETVAL = self->_is_equivalent((CORBA::Object_ptr)obj);
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

unsigned long
_hash (self, maximum)
    CORBA::Object self;
    unsigned long maximum;
    CODE:
    try {
        RETVAL = self->_hash(maximum);
    }
    CATCH_POMNI_SYSTEMEXCEPTION
    OUTPUT:
    RETVAL

char *
_repoid (self)
    CORBA::Object self;
    CODE:
    {
	const char *repoid = CORBA::Object::_PD_repoId;
	if (!CORBA::is_nil(self))
	    repoid = self->_PR_getobj()->_mostDerivedRepoId();
	RETVAL = (char *)repoid;
    }
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
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

MODULE = CORBA::omniORB		PACKAGE = CORBA::TypeCode

SV *
new (pkg, id)
    char *id
    CODE:
    RETVAL = pomni_lookup_typecode (aTHX_ id);
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
SV *
member_label (self, index)
    CORBA::TypeCode self
    unsigned long index
    CODE:
    try {
	CORBA::Any_var label = self->member_label (index);
	RETVAL = pomni_any_to_sv(aTHX_ label);
    } catch (CORBA::TypeCode::BadKind &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (CORBA::TypeCode::Bounds &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
void
DESTROY (self)
    CORBA::TypeCode self
    CODE:
    CORBA::release (self);

MODULE = CORBA::omniORB            PACKAGE = CORBA::LongLong

#ifdef HAS_LongLong

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

#endif
	
MODULE = CORBA::omniORB            PACKAGE = CORBA::ULongLong

#ifdef HAS_LongLong

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

#endif
	
MODULE = CORBA::omniORB            PACKAGE = CORBA::LongDouble

#ifdef HAS_LongDouble

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

#endif
	
MODULE = CORBA::omniORB            PACKAGE = PortableServer::POA

char *
_get_the_name (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    RETVAL = (char *)THIS->the_name();
    OUTPUT:
    RETVAL

PortableServer::POA
_get_the_parent (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    RETVAL = THIS->the_parent();
    OUTPUT:
    RETVAL

PortableServer::POAManager
_get_the_POAManager (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    RETVAL = THIS->the_POAManager();
    OUTPUT:
    RETVAL

CORBA::Object
_get_the_activator (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    RETVAL = THIS->the_activator();
    OUTPUT:
    RETVAL

void
_set_the_activator (self, obj)
    PortableServer::POA self
    CORBA::Object obj
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    PortableServer::AdapterActivator_var activator = 
        PortableServer::AdapterActivator::_narrow (obj);
    if (!activator)
	croak ("activator must be of type PortableServer::AdapterActivator");
    THIS->the_activator (activator);

PortableServer::POA
create_POA (self, adapter_name, mngr_obj, ...)
    PortableServer::POA self
    char *adapter_name
    CORBA::Object mngr_obj
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    CORBA::PolicyList_var policies;
    PortableServer::POAManager_var mngr
        = PortableServer::POAManager::_narrow(mngr_obj);
    CORBA::ULong npolicies;
    if (items % 2 != 1)
        croak("PortableServer::POA::create_POA requires an even number of arguments\n");


    npolicies = (items - 3) / 2;
    policies = new CORBA::PolicyList (npolicies);
    policies->length (npolicies);
    for (CORBA::ULong i = 0 ; i < npolicies; i++)
        policies[i] = make_policy (THIS, SvPV(ST(3+i*2), PL_na), 
				   SvPV(ST(4+i*2), PL_na));

    try {
	RETVAL = THIS->create_POA (adapter_name, mngr, policies);
    } catch (PortableServer::POA::AdapterAlreadyExists &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::InvalidPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

    OUTPUT:
    RETVAL

void
destroy (self, etherealize_objects, wait_for_completion)
    PortableServer::POA self
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    THIS->destroy (SvTRUE (etherealize_objects),
		   SvTRUE (wait_for_completion));

CORBA::Object
get_servant_manager (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->get_servant_manager ();
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

void
set_servant_manager (self, obj)
    PortableServer::POA self
    CORBA::Object obj
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    PortableServer::ServantManager_var manager
        = PortableServer::ServantManager::_narrow(obj);
    if (CORBA::is_nil (manager))
	croak ("Servant manager must be a PortableServer::ServantManager\n");
    try {
	THIS->set_servant_manager (manager);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

PortableServer::ServantBase
get_servant (self)
    PortableServer::POA self
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->get_servant ();
    } catch (PortableServer::POA::NoServant &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

void
set_servant (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        THIS->set_servant (servant);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

PortableServer::ObjectId
activate_object (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->activate_object (servant);
    } catch (PortableServer::POA::ServantAlreadyActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

void
activate_object_with_id (self, id, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    PortableServer::ObjectId id
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        THIS->activate_object_with_id (id, servant);
    } catch (PortableServer::POA::ServantAlreadyActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::ObjectAlreadyActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
deactivate_object (self, id)
    PortableServer::POA self
    PortableServer::ObjectId id
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        THIS->deactivate_object (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

CORBA::Object
create_reference (self, intf)
    PortableServer::POA self
    char *intf
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->create_reference (intf);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
create_reference_with_id (self, oid, intf)
    PortableServer::POA self
    PortableServer::ObjectId oid
    char *intf
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->create_reference_with_id (oid, intf);
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ObjectId
servant_to_id (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->servant_to_id (servant);
    } catch (PortableServer::POA::ServantNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
servant_to_reference (self, servant)
    PortableServer::POA self
    PortableServer::ServantBase servant
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->servant_to_reference (servant);
    } catch (PortableServer::POA::ServantNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ServantBase
reference_to_servant (self, reference)
    PortableServer::POA self
    CORBA::Object       reference
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->reference_to_servant (reference);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongAdapter &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ObjectId
reference_to_id (self, reference)
    PortableServer::POA self
    CORBA::Object       reference
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->reference_to_id (reference);
    } catch (PortableServer::POA::WrongAdapter &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

PortableServer::ServantBase
id_to_servant (self, id)
    PortableServer::POA self
    PortableServer::ObjectId id
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->id_to_servant (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

CORBA::Object
id_to_reference (self, id)
    PortableServer::POA self
    PortableServer::ObjectId id
    CODE:
    PortableServer::POA_var THIS = PortableServer::POA::_narrow(self);
    try {
        RETVAL = THIS->id_to_reference (id);
    } catch (PortableServer::POA::ObjectNotActive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (PortableServer::POA::WrongPolicy &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

void
DESTROY (self)
    PortableServer::POA self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

MODULE = CORBA::omniORB            PACKAGE = PortableServer::POAManager

void
activate (self)
    PortableServer::POAManager self
    CODE:
    PortableServer::POAManager_var THIS
        = PortableServer::POAManager::_narrow(self);
    try {
        THIS->activate ();
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
hold_requests (self, wait_for_completion)
    PortableServer::POAManager self
    SV *wait_for_completion
    CODE:
    PortableServer::POAManager_var THIS
        = PortableServer::POAManager::_narrow(self);
    try {
	THIS->hold_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
discard_requests (self, wait_for_completion)
    PortableServer::POAManager self
    SV *wait_for_completion
    CODE:
    PortableServer::POAManager_var THIS
        = PortableServer::POAManager::_narrow(self);
    try {
	THIS->discard_requests (SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
deactivate (self, etherealize_objects, wait_for_completion)
    PortableServer::POAManager self
    SV *etherealize_objects
    SV *wait_for_completion
    CODE:
    PortableServer::POAManager_var THIS
        = PortableServer::POAManager::_narrow(self);
    try {
	THIS->deactivate (SvTRUE (etherealize_objects),
			  SvTRUE (wait_for_completion));
    } catch (PortableServer::POAManager::AdapterInactive &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

char *
get_state (self)
    PortableServer::POAManager self
    CODE:
    PortableServer::POAManager_var THIS
        = PortableServer::POAManager::_narrow(self);
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
DESTROY (self)
    PortableServer::POAManager self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

MODULE = CORBA::omniORB            PACKAGE = PortableServer::Current

PortableServer::POA
get_POA (self)
    PortableServer::Current self
    CODE:
    PortableServer::Current_var THIS = PortableServer::Current::_narrow(self);
    try {
	RETVAL = THIS->get_POA ();
    } catch (PortableServer::Current::NoContext &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
    
PortableServer::ObjectId
get_object_id (self)
    PortableServer::Current self
    CODE:
    PortableServer::Current_var THIS = PortableServer::Current::_narrow(self);
    try {
	RETVAL = THIS->get_object_id ();
    } catch (PortableServer::Current::NoContext &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::Object
get_reference (self)
    PortableServer::Current self
    CODE:
    PortableServer::Current_var THIS = PortableServer::Current::_narrow(self);
    try {
	RETVAL = THIS->get_reference ();
    } catch (PortableServer::Current::NoContext &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
void
DESTROY (self)
    PortableServer::Current self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);


MODULE = CORBA::omniORB            PACKAGE = PortableServer::ServantBase

IV
_pomni_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new POmniServant (self);
    RETVAL = PTR2IV(res);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB            PACKAGE = POA_PortableServer::AdapterActivator

IV
_pomni_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new POmniAdapterActivator (self);
    RETVAL = PTR2IV(res);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB            PACKAGE = POA_PortableServer::ServantActivator

IV
_pomni_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new POmniServantActivator (self);
    RETVAL = PTR2IV(res);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB            PACKAGE = POA_PortableServer::ServantLocator

IV
_pomni_servant (self)
    SV *self
    CODE:
    PortableServer::Servant res = new POmniServantLocator (self);
    RETVAL = PTR2IV(res);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = CORBA::omniORB::InstVars

int
CLONE_SKIP(...)
    CODE:
    RETVAL = 1;
    OUTPUT:
    RETVAL

void
DESTROY (self)
    SV *self;
    CODE:
    pomni_instvars_destroy (aTHX_ (POmniInstVars *)SvPVX(SvRV(self)));

MODULE = CORBA::omniORB		PACKAGE = CORBA::omniORB::EntryLock

void
DESTROY (self)
    SV *self;
    CODE:
    SV *sv = SvRV(self);
    delete INT2PTR(POmniRatchetLock *, SvIV(sv));

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynAny

void
DESTROY (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

CORBA::TypeCode
type (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->type();
    OUTPUT:
    RETVAL

void
assign (self, dyn_any_obj)
    DynamicAny::DynAny self
    DynamicAny::DynAny dyn_any_obj
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    DynamicAny::DynAny_var dyn_any = DynamicAny::DynAny::_narrow(dyn_any_obj);
    try {
         THIS->assign( dyn_any );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
from_any (self, any)
    DynamicAny::DynAny self
    SV *any
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	CORBA::Any a;
	pomni_any_from_sv(aTHX_ &a, any);
	THIS->from_any(a);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

SV *
to_any (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    CORBA::Any_var any = THIS->to_any();
    RETVAL = pomni_any_to_sv(aTHX_ any);
    OUTPUT:
    RETVAL

bool
equal (self, dyn_any_obj)
    DynamicAny::DynAny self
    DynamicAny::DynAny dyn_any_obj
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    DynamicAny::DynAny_var dyn_any = DynamicAny::DynAny::_narrow(dyn_any_obj);
    RETVAL = THIS->equal(dyn_any);
    OUTPUT:
    RETVAL

void
destroy (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    THIS->destroy();

DynamicAny::DynAny
copy (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->copy();
    OUTPUT:
    RETVAL

void
insert_boolean (self, value)
    DynamicAny::DynAny self
    bool value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_boolean((CORBA::Boolean)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_octet (self,value)
    DynamicAny::DynAny self
    unsigned char value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_octet((CORBA::Octet)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_char (self,value)
    DynamicAny::DynAny self
    char value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_char((CORBA::Char)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_short (self,value)
    DynamicAny::DynAny self
    short value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_short((CORBA::Short)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_ushort (self,value)
    DynamicAny::DynAny self
    unsigned short value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_ushort((CORBA::UShort)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_long (self,value)
    DynamicAny::DynAny self
    long value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_long((CORBA::Long)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_ulong (self,value)
    DynamicAny::DynAny self
    unsigned long value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_ulong((CORBA::ULong)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_float (self,value)
    DynamicAny::DynAny self
    double value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_float((CORBA::Float)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_double (self,value)
    DynamicAny::DynAny self
    double value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_double((CORBA::Double)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_string (self,value)
    DynamicAny::DynAny self
    char* value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_string((const char*)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_reference (self,value)
    DynamicAny::DynAny self
    CORBA::Object value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_reference((CORBA::Object_ptr)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_typecode (self,value)
    DynamicAny::DynAny self
    CORBA::TypeCode value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_typecode((CORBA::TypeCode_ptr)value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

#ifdef HAS_LongLong

void
insert_longlong (self,value)
    DynamicAny::DynAny self
    CORBA::LongLong value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_longlong(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_ulonglong (self,value)
    DynamicAny::DynAny self
    CORBA::ULongLong value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_ulonglong(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

#endif

#ifdef HAS_LongDouble

void
insert_longdouble (self,value)
    DynamicAny::DynAny self
    CORBA::LongDouble value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	THIS->insert_longdouble(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

#endif

# void insert_wchar(in wchar value)
# void insert_wstring(in wstring value)

void
insert_any (self,value)
    DynamicAny::DynAny self
    SV *value
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	CORBA::Any v;
	pomni_any_from_sv(aTHX_ &v, value);
	THIS->insert_any(v);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
insert_dyn_any (self, value_obj)
    DynamicAny::DynAny self
    DynamicAny::DynAny value_obj
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    DynamicAny::DynAny_var value = DynamicAny::DynAny::_narrow(value_obj);
    try {
	THIS->insert_dyn_any(value);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

# void insert_val(in ValueBase value)

bool
get_boolean (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_boolean();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
   
unsigned char
get_octet (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_octet();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
char
get_char (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_char();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
short
get_short (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_short();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
unsigned short
get_ushort (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_ushort();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
long
get_long (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_long();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
unsigned long
get_ulong (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_ulong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
double
get_float (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_float();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
double
get_double (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_double();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
SV *
get_string (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	CORBA::String_var string = THIS->get_string();
	RETVAL = newSVpv((char *) string, 0);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::Object
get_reference (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_reference();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::TypeCode
get_typecode (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_typecode();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
#ifdef HAS_LongLong

CORBA::LongLong
get_longlong (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_longlong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
CORBA::ULongLong
get_ulonglong (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_ulonglong();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

#endif

#ifdef HAS_LongDouble
    
CORBA::LongDouble
get_longdouble (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	RETVAL = THIS->get_longdouble();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

#endif
    
# wchar get_wchar()
# wstring get_wstring()

SV *
get_any (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
	CORBA::Any_var any = THIS->get_any();
	RETVAL = pomni_any_to_sv(aTHX_ any);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
DynamicAny::DynAny
get_dyn_any (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    try {
      RETVAL = THIS->get_dyn_any();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
# ValueBase get_val()

bool
seek (self,index)
    DynamicAny::DynAny self
    long index
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->seek(index);
    OUTPUT:
    RETVAL

void
rewind (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    THIS->rewind();

bool
next (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->next();
    OUTPUT:
    RETVAL

unsigned long
component_count (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->component_count();
    OUTPUT:
    RETVAL

DynamicAny::DynAny
current_component (self)
    DynamicAny::DynAny self
    CODE:
    DynamicAny::DynAny_var THIS = DynamicAny::DynAny::_narrow(self);
    RETVAL = THIS->current_component();
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynFixed

void
DESTROY (self)
    DynamicAny::DynFixed self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

char *
get_value (self)
    DynamicAny::DynFixed self
    CODE:
    DynamicAny::DynFixed_var THIS = DynamicAny::DynFixed::_narrow(self);
    CORBA::String_var string = THIS->get_value();
    RETVAL = (char *) string;
    OUTPUT:
    RETVAL

#bool	CORBA V2.3: boolean set_value(in string val) //XXX
void
set_value (self,val)
    DynamicAny::DynFixed self
    char* val
    CODE:
    DynamicAny::DynFixed_var THIS = DynamicAny::DynFixed::_narrow(self);
    try {
	THIS->set_value(val);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    
# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynFixed::_narrow(dyn_any),
				       "DynamicAny::DynFixed", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynEnum

void
DESTROY (self)
    DynamicAny::DynEnum self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

char*
get_as_string(self)
    DynamicAny::DynEnum self
    CODE:
    DynamicAny::DynEnum_var THIS = DynamicAny::DynEnum::_narrow(self);
    CORBA::String_var string = THIS->get_as_string();
    RETVAL = (char *) string;
    OUTPUT:
    RETVAL

void
set_as_string(self,value)
    DynamicAny::DynEnum self
    char* value
    CODE:
    DynamicAny::DynEnum_var THIS = DynamicAny::DynEnum::_narrow(self);
    try {
	THIS->set_as_string(value);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

unsigned long
get_as_ulong(self)
    DynamicAny::DynEnum self
    CODE:
    DynamicAny::DynEnum_var THIS = DynamicAny::DynEnum::_narrow(self);
    RETVAL = THIS->get_as_ulong();
    OUTPUT:
    RETVAL

void
set_as_ulong(self,value)
    DynamicAny::DynEnum self
    unsigned long value
    CODE:
    DynamicAny::DynEnum_var THIS = DynamicAny::DynEnum::_narrow(self);
    try {
	THIS->set_as_ulong(value);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }


# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynEnum::_narrow(dyn_any),
				       "DynamicAny::DynEnum", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynStruct
void
DESTROY (self)
    DynamicAny::DynStruct self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);


SV *
current_member_name(self)
    DynamicAny::DynStruct self
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
    try {
	CORBA::String_var string = THIS->current_member_name();
	RETVAL = newSVpv((char *) string, 0);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

char*
current_member_kind(self)
    DynamicAny::DynStruct self
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
    try {
	RETVAL = (char*) TCKind_to_str( THIS->current_member_kind() );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

AV*
get_members(self)
    DynamicAny::DynStruct self
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
      DynamicAny::NameValuePairSeq_var mbrs = THIS->get_members();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pomni_any_to_sv(aTHX_ mbrs[i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
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

      CORBA::Any any;
      SV** value = hv_fetch( hv, "value", 5, 0 );
      if( !value || !pomni_any_from_sv(aTHX_ &any, *value))
	  croak("members - must contain CORBA::Any field 'value'");
      mbrs[(unsigned long)i].value = any;
    }
    try {
	THIS->set_members( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
AV*
get_members_as_dyn_any(self)
    DynamicAny::DynStruct self
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
    DynamicAny::NameDynAnyPairSeq_var mbrs = THIS->get_members_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[(unsigned long)i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pomni_dyn_any_to_sv(aTHX_ mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members_as_dyn_any(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    DynamicAny::DynStruct_var THIS = DynamicAny::DynStruct::_narrow(self);
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
	THIS->set_members_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynStruct::_narrow(dyn_any),
				       "DynamicAny::DynStruct", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynUnion

void
DESTROY (self)
    DynamicAny::DynUnion self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

DynamicAny::DynAny
get_discriminator (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    RETVAL = THIS->get_discriminator();
    OUTPUT:
    RETVAL

void
set_discriminator (self,d_obj)
    DynamicAny::DynUnion self
    DynamicAny::DynAny d_obj
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    DynamicAny::DynUnion_var d = DynamicAny::DynUnion::_narrow(d_obj);
    try {
	THIS->set_discriminator(d);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
set_to_default_member (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    try {
	THIS->set_to_default_member();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

void
set_to_no_active_member (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    try {
	THIS->set_to_no_active_member();
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

bool
has_no_active_member (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    RETVAL = THIS->has_no_active_member();
    OUTPUT:
    RETVAL

char *
discriminator_kind (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    RETVAL = (char *) TCKind_to_str( THIS->discriminator_kind() );
    OUTPUT:
    RETVAL

DynamicAny::DynAny
member (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    try {
	RETVAL = THIS->member();
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
SV *
member_name (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    try {
	CORBA::String_var string = THIS->member_name();
	RETVAL = newSVpv((char *) string, 0);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
char*
member_kind (self)
    DynamicAny::DynUnion self
    CODE:
    DynamicAny::DynUnion_var THIS = DynamicAny::DynUnion::_narrow(self);
    try {
	RETVAL = (char *) TCKind_to_str( THIS->member_kind() );
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
      pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynUnion::_narrow(dyn_any),
				       "DynamicAny::DynUnion", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynSequence

void
DESTROY (self)
    DynamicAny::DynSequence self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

unsigned long
get_length (self)
    DynamicAny::DynSequence self
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
    RETVAL = THIS->get_length();
    OUTPUT:
    RETVAL

void
set_length (self,len)
    DynamicAny::DynSequence self
    unsigned long len
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
    try {
	THIS->set_length(len);
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }

AV*
get_elements (self)
    DynamicAny::DynSequence self
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
    DynamicAny::AnySeq_var els = THIS->get_elements();
    RETVAL = newAV();
    av_extend( RETVAL, els->length() );
    for( CORBA::ULong i = 0; i < els->length(); i++ ) {
      av_push( RETVAL, pomni_any_to_sv(aTHX_ els[i]) );
    }
    OUTPUT:
    RETVAL

void
set_elements(self,elements)
    DynamicAny::DynSequence self
    SV* elements
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::AnySeq_var mbrs = new DynamicAny::AnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
	CORBA::Any any;
	SV* sv = *av_fetch( (AV*)elements, i, 0 );
	if (!pomni_any_from_sv(aTHX_ &any, sv))
	    croak("elements - must contain CORBA::Any values");
	mbrs[(unsigned long)i] = any;
    }
    try {
	THIS->set_elements( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
AV*
get_elements_as_dyn_any(self)
    DynamicAny::DynSequence self
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
    DynamicAny::DynAnySeq_var mbrs = THIS->get_elements_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        av_push( RETVAL, pomni_dyn_any_to_sv(aTHX_ mbrs[(unsigned long)i]) );
      }
    OUTPUT:
      RETVAL

void
set_elements_as_dyn_any(self,elements)
    DynamicAny::DynSequence self
    SV* elements
    CODE:
    DynamicAny::DynSequence_var THIS = DynamicAny::DynSequence::_narrow(self);
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
	THIS->set_elements_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL
        = pomni_local_objref_to_sv (aTHX_
				    DynamicAny::DynSequence::_narrow(dyn_any),
				    "DynamicAny::DynSequence", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynArray

void
DESTROY (self)
    DynamicAny::DynArray self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

AV*
get_elements (self)
    DynamicAny::DynArray self
    CODE:
    DynamicAny::DynArray_var THIS = DynamicAny::DynArray::_narrow(self);
    DynamicAny::AnySeq_var els = THIS->get_elements();
    RETVAL = newAV();
    av_extend( RETVAL, els->length() );
    for( CORBA::ULong i = 0; i < els->length(); i++ ) {
      av_push( RETVAL, pomni_any_to_sv(aTHX_ els[i]) );
    }
    OUTPUT:
    RETVAL

void
set_elements(self,elements)
    DynamicAny::DynArray self
    SV* elements
    CODE:
    DynamicAny::DynArray_var THIS = DynamicAny::DynArray::_narrow(self);
    if( !SvROK(elements) )
      croak("elements - must be an array reference");
    elements = SvRV(elements);
    if( SvTYPE(elements) != SVt_PVAV )
      croak("elements - must be an array reference");
    DynamicAny::AnySeq_var mbrs = new DynamicAny::AnySeq;
    mbrs->length(av_len((AV*)elements)+1);
    for( I32 i = 0; i <= av_len((AV*)elements); i++ ) {
	CORBA::Any any;
	SV *sv = *av_fetch( (AV*)elements, i, 0 );
	if (pomni_any_from_sv(aTHX_ &any, sv))
	    croak("elements - must contain CORBA::Any values");
	mbrs[(unsigned long)i] = any;
    }
    try {
	THIS->set_elements( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
AV*
get_elements_as_dyn_any(self)
    DynamicAny::DynArray self
    CODE:
    DynamicAny::DynArray_var THIS = DynamicAny::DynArray::_narrow(self);
    DynamicAny::DynAnySeq_var mbrs = THIS->get_elements_as_dyn_any();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        av_push( RETVAL, pomni_dyn_any_to_sv(aTHX_ mbrs[(unsigned long)i]) );
      }
    OUTPUT:
      RETVAL

void
set_elements_as_dyn_any(self,elements)
    DynamicAny::DynArray self
    SV* elements
    CODE:
    DynamicAny::DynArray_var THIS = DynamicAny::DynArray::_narrow(self);
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
	THIS->set_elements_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynArray::_narrow(dyn_any),
				       "DynamicAny::DynArray", true);
    OUTPUT:
    RETVAL

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynValue

#if 0

void
DESTROY (self)
    DynamicAny::DynValue self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

SV *
current_member_name (self)
    DynamicAny::DynValue self
    CODE:
    DynamicAny::DynValue_var THIS = DynamicAny::DynValue::_narrow(self);
    try {
	CORBA::String_var string = THIS->current_member_name();
	RETVAL = newSVpv((char *) string, 0);
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
	
char*
current_member_kind(self)
    DynamicAny::DynValue self
    CODE:
    DynamicAny::DynValue_var THIS = DynamicAny::DynValue::_narrow(self);
    try {
	RETVAL = (char*) TCKind_to_str( THIS->current_member_kind() );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL

AV*
get_members(self)
    DynamicAny::DynStruct self
    CODE:
    DynamicAny::DynValue_var THIS = DynamicAny::DynValue::_narrow(self);
    DynamicAny::NameValuePairSeq_var mbrs = THIS->get_members();
      RETVAL = newAV();
      av_extend(RETVAL, mbrs->length());
      for( CORBA::ULong i = 0; i < mbrs->length(); i++ ) {
        HV* p_mbr = newHV();
	sv_2mortal((SV*)p_mbr);
        
	hv_store(p_mbr, "id",    2, newSVpv(mbrs[(unsigned long)i].id, 0),          0);
	hv_store(p_mbr, "value", 5, pomni_any_to_sv(mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    DynamicAny::DynValue_var THIS = DynamicAny::DynValue::_narrow(self);
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

      CORBA::Any any;
      SV** value = hv_fetch( hv, "value", 5, 0 );
      if (!value || !pomni_any_from_sv(aTHX_ &any, sv))
	  croak("members - must contain CORBA::Any field 'value'");
      mbrs[(unsigned long)i].value = any;
    }
    try {
	THIS->set_members( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
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
	hv_store(p_mbr, "value", 5, pomni_dyn_any_to_sv(mbrs[(unsigned long)i].value), 0);

        av_push(RETVAL, newRV_inc((SV*)p_mbr));
      }
    OUTPUT:
      RETVAL

void
set_members_as_dyn_any(self,members)
    DynamicAny::DynStruct self
    SV* members
    CODE:
    DynamicAny::DynValue_var THIS = DynamicAny::DynValue::_narrow(self);
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
	THIS->set_members_as_dyn_any( mbrs );
    } catch (DynamicAny::DynAny::TypeMismatch &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    } catch (DynamicAny::DynAny::InvalidValue &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
      
# narrow helper
SV *
_narrow(dyn_any)
    DynamicAny::DynAny dyn_any
    CODE:
    RETVAL = pomni_local_objref_to_sv (aTHX_
				       DynamicAny::DynValue::_narrow(dyn_any),
				       "DynamicAny::DynValue", true);
    OUTPUT:
    RETVAL

#endif

MODULE = CORBA::omniORB		PACKAGE = DynamicAny::DynAnyFactory

void
DESTROY (self)
    DynamicAny::DynAnyFactory self
    CODE:
    pomni_objref_destroy (aTHX_ self);
    CORBA::release (self);

DynamicAny::DynAny
create_dyn_any(self, value)
    DynamicAny::DynAnyFactory self
    SV *value
    CODE:
    DynamicAny::DynAnyFactory_var THIS
        = DynamicAny::DynAnyFactory::_narrow(self);
    try {
	CORBA::Any v;
	pomni_any_from_sv(aTHX_ &v, value);
	RETVAL = THIS->create_dyn_any(v);
    } catch (DynamicAny::DynAnyFactory::InconsistentTypeCode &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
    
DynamicAny::DynAny
create_dyn_any_from_type_code(self, type)
    DynamicAny::DynAnyFactory self
    CORBA::TypeCode type
    CODE:
    DynamicAny::DynAnyFactory_var THIS
        = DynamicAny::DynAnyFactory::_narrow(self);
    try {
	RETVAL = THIS->create_dyn_any_from_type_code(type);
    } catch (DynamicAny::DynAnyFactory::InconsistentTypeCode &ex) {
	pomni_throw (aTHX_ pomni_builtin_except (aTHX_ &ex));
    }
    OUTPUT:
    RETVAL
