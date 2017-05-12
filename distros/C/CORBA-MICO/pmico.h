/* -*- mode: C++; c-file-style: "bsd" -*- */

#undef bool

#include <CORBA.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Some variables changed names between perl5.004 and perl5.005 */
#ifdef PERL5004_COMPAT
#define PL_na na
#define PL_sv_yes sv_yes
#define PL_sv_no sv_no

/* this function was added in 5.005, so we provide it in constsub.c */
void newCONSTSUB(HV *stash, char *name, SV *sv);
#endif /* PERL5004_COMPAT */

#ifdef __cplusplus
}
#endif

// Encapsulates Perl/MICO's knowledge about a particular interface
struct PMicoIfaceInfo {
    PMicoIfaceInfo (string _pkg, 
		    CORBA::InterfaceDef *_iface,
		    CORBA::InterfaceDef::FullInterfaceDescription *_desc)

	: pkg(_pkg), iface(_iface), desc(_desc)
    {
    }
    string pkg;			// owned
    CORBA::InterfaceDef_var iface; // owned
    CORBA::InterfaceDef::FullInterfaceDescription_var desc; // owned
};

// Information attached to a Perl stub or true object via '~' magic
struct PMicoInstVars;

// ==== From errors.cc ====

// Find the package given the repoid of an exception
const char *      pmico_find_exception  (const char *repoid);
// Set up a package for a given exception. parent is the base package
// for this exception (CORBA::UserException or CORBA::SystemException
void              pmico_setup_exception (const char *repoid, 
					 const char *pkg,
					 const char *parent);
// Set up packages for all system exceptions
void              pmico_init_exceptions (void);
// Create a system exception object
SV *              pmico_system_except   (const char *repoid, 
					 CORBA::ULong minor, 
					 CORBA::CompletionStatus status);
// Create a user exception object
SV *              pmico_user_except     (const char *repoid, SV *value);
// Create an exception object for some exception that we
// are catching internally
SV *              pmico_builtin_except (CORBA::Exception *ex);
// Throw a user exception object as a Perl exception
void              pmico_throw           (SV *e);

// Create an exception object for an exception thrown by the POA

// ==== From interfaces.cc ====

// Given either a pointer to an IR object, or a repository ID, load
// the definition of the IR object from the repository. _orb optionally
// gives the orb to resolve the initial InterfaceRepository in
// if iface is not specified
PMicoIfaceInfo *  pmico_load_contained  (CORBA::Contained_ptr _container, 
					 CORBA::ORB_ptr _orb,
					 const char *_id);
// Look up interface information for a given repoid
PMicoIfaceInfo *  pmico_find_interface_description (const char *repo_id);

// Find or create a TypeCode object for the given object
SV *              pmico_lookup_typecode (const char *id);

// Initialize typecodes for the standard types
void              pmico_init_typecodes  (void);

// ==== From types.cc ====

// Find or create a Perl object for a given CORBA::Object
SV *              pmico_objref_to_sv     (CORBA::Object *obj);
// Given a Perl object which is a descendant of CORBA::Object, find
// or create the corresponding C++ CORBA::Object
CORBA::Object_ptr pmico_sv_to_objref     (SV            *perl_obj);
// Removes an object from the pin table
void              pmico_objref_destroy   (CORBA::Object *obj);

// Write the contents of sv into res, using res->type
bool              pmico_to_any           (CORBA::Any *res, SV *sv);
// Create a SV (perl data structure) from an Any
SV *              pmico_from_any         (CORBA::Any *any);
