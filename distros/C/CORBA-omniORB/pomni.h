/* -*- mode: C++; c-file-style: "bsd" -*- */

#undef bool

#define ENABLE_CLIENT_IR_SUPPORT
#include <omniORB4/CORBA.h>
#include <string>
#include <vector>

#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef wait			/* defined by win32iop.h */

#ifdef __cplusplus
}
#endif

#if !defined(USE_ITHREADS)
#error Unsupported threading model
#endif

// Encapsulates Perl/omniORB's knowledge about a particular interface
struct POmniIfaceInfo {
    std::string pkg;			// owned
    CORBA::InterfaceDef_var iface; // owned
    CORBA::InterfaceDef::FullInterfaceDescription *desc; // owned

    POmniIfaceInfo (std::string _pkg, 
		    CORBA::InterfaceDef_ptr _iface,
		    CORBA::InterfaceDef::FullInterfaceDescription *_desc)
	: pkg(_pkg), iface(_iface), desc(_desc)
    {
    }
    ~POmniIfaceInfo()
    {
	delete desc;
    }
};

// Information attached to a Perl stub or true object via PERL_MAGIC_ext magic
struct POmniInstVars;

// ==== From errors.cc ====

// Find the package given the repoid of an exception
const char *      pomni_find_exception  (pTHX_ const char *repoid);
// Set up a package for a given exception. parent is the base package
// for this exception (CORBA::UserException or CORBA::SystemException
void              pomni_setup_exception (pTHX_
					 const char *repoid, 
					 const char *pkg,
					 const char *parent);
// Set up packages for all system exceptions
void              pomni_init_exceptions (pTHX);

#ifdef MEMCHECK
void              pomni_clear_exceptions(pTHX);
#endif

// Create a system exception object
SV *              pomni_system_except   (pTHX_
					 const char *repoid, 
					 CORBA::ULong minor, 
					 CORBA::CompletionStatus status);
// Create a user exception object
SV *              pomni_user_except     (pTHX_ const char *repoid, SV *value);
// Create an exception object for some exception that we
// are catching internally
SV *              pomni_builtin_except  (pTHX_ CORBA::Exception *ex);
// Throw a user exception object as a Perl exception
void              pomni_throw           (pTHX_ SV *e) __attribute__((noreturn));

// Create an exception object for an exception thrown by the POA

// ==== From interfaces.cc ====

// Given either a pointer to an IR object, or a repository ID, load
// the definition of the IR object from the repository. _orb optionally
// gives the orb to resolve the initial InterfaceRepository in
// if iface is not specified
POmniIfaceInfo *  pomni_load_contained  (pTHX_
					 CORBA::Contained_ptr _container, 
					 CORBA::ORB_ptr _orb,
					 const char *_id);
// Look up interface information for a given repoid
POmniIfaceInfo *  pomni_find_interface_description (pTHX_
						    const char *repo_id);

#ifdef MEMCHECK
void              pomni_clear_interface (pTHX_
					 const char *repo_id);
void              pomni_clear_iface_repository(pTHX);
#endif

// Define an interface
void pomni_define_interface(pTHX_
			    const char *pkg,
			    CORBA::InterfaceDef::FullInterfaceDescription *desc);

// Define an exception
void pomni_define_exception(pTHX_ const char *pkg, const char *repoid);

// Determine whether a given repoid is a subtype of another repoid
bool pomni_is_a(pTHX_
		const char *object_repoid,
		const char *interface_repoid);

// Find or create a TypeCode object for the given object
SV *              pomni_lookup_typecode (pTHX_
					 const char *id);

// Initialize typecodes for the standard types
void              pomni_init_typecodes  (pTHX);

// Clean up typecodes
#ifdef MEMCHECK
void              pomni_clear_typecodes (pTHX);
#endif

// Duplicates typecode cache items for use within a new thread
void              pomni_clone_typecodes (pTHX);

// ==== From types.cc ====

// Find or create a Perl object for a given CORBA::Object
SV *              pomni_objref_to_sv     (pTHX_
					  CORBA::Object *obj,
					  const char *repoid = 0);

SV *              pomni_local_objref_to_sv (pTHX_
					    CORBA::Object *obj,
					    const char *classname,
					    bool force = false);

// Given a Perl object which is a descendant of CORBA::Object, find
// the corresponding C++ CORBA::Object
CORBA::Object_ptr pomni_sv_to_objref     (pTHX_
					  SV            *perl_obj);

CORBA::Object_ptr pomni_sv_to_local_objref (pTHX_
					    SV *perlobj,
					    char *classname);

// Removes an object from the pin table
void              pomni_objref_destroy   (pTHX_
					  CORBA::Object *obj);

#ifdef MEMCHECK
void              pomni_clear_pins       (pTHX);
#endif

// Duplicates object references for use within a new thread
void              pomni_clone_pins       (pTHX);


// Write the contents of sv into res, using res->type
bool              pomni_to_any           (pTHX_
					  CORBA::Any *res, SV *sv);
// Create a SV (perl data structure) from an Any
SV *              pomni_from_any         (pTHX_
					  CORBA::Any *any);
// Copy an Any from a "CORBA::Any" SV
bool              pomni_any_from_sv      (pTHX_
					  CORBA::Any *res, SV *sv);
// Create a "CORBA::Any" SV from an Any
SV *              pomni_any_to_sv        (pTHX_
					  const CORBA::Any &any);
// Create a "DynamicAny::DynAny" SV from an DynAny
SV *		  pomni_dyn_any_to_sv	 (pTHX_
					  DynamicAny::DynAny *dynany);
// Convert CORBA::TCKind to string representation
const char* const TCKind_to_str( CORBA::TCKind kind );

// ==== From server.cc ====

#ifdef MEMCHECK
void              pomni_clear_servants   (pTHX);
#endif

//-------------------------------------------------------------------
void cm_log( const char* format, ... );
#ifdef NDEBUG
#define CM_DEBUG(v)
#else
#define CM_DEBUG(v)	cm_log v
#endif

//-------------------------------------------------------------------

// C++-friendly croak()

// Trampoline classes

class POmniCroak {
public:
    POmniCroak(pTHX_ const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);

	SV *errsv = get_sv("@", TRUE);
	sv_vsetpvf(errsv, fmt, &ap);

	va_end(ap);
    }
};

class POmniThrowable {
    SV *e_;
public:
    POmniThrowable(SV *e)
	: e_(e) {
    }

    SV *exception_object(void) {
	return e_;
    }
};

#define CATCH_POMNI_TRAMPOLINE \
    catch (POmniCroak) { \
	croak(Nullch); \
    } \
    catch (POmniThrowable &throwable) { \
	pomni_throw(aTHX_ throwable.exception_object()); \
    }

#define CATCH_POMNI_SYSTEMEXCEPTION \
    catch (CORBA::SystemException &sysex) { \
        pomni_throw(aTHX_ pomni_system_except(aTHX_ \
                                              sysex._rep_id(), \
                                              sysex.minor(), \
                                              sysex.completed())); \
    }


//-------------------------------------------------------------------

/** Mutex to serialize servant calls from omniORB.  Allows the mutex
 * to be temporarily released to allow callbacks with a deeper
 * recursion level to execute.
 */

class POmniRatchetLock {
    omni_mutex mutex_;
    volatile bool locked_;
    omni_condition entry_cond_;
    volatile unsigned awaiting_entry_;

    struct Entry {
	bool waiting;
	omni_condition *cond;
	Entry(omni_mutex *mutex)
	    : waiting(false), cond(new omni_condition(mutex)) {
	}
    };

    typedef std::vector<Entry> _T;
    _T stack_;
    _T::iterator top_;		// Stack top
    
    inline void grow() {
	_T::size_type top = top_ - stack_.begin();
	stack_.push_back(Entry(&mutex_)); // Invalidates iterators
	top_ = stack_.begin() + top;
    }
    
public:
    POmniRatchetLock(void)
	: locked_(true),
	  entry_cond_(&mutex_),
	  awaiting_entry_(0),
	  top_(stack_.begin()) {
	grow();			// initial entry
    }
    ~POmniRatchetLock(void) {
	for(_T::iterator i = stack_.begin(); i != stack_.end(); ++i) {
	    delete i->cond;
	}
    }

    //! Enter a new recursion level.
    void enter(void) {
	mutex_.lock();
	++awaiting_entry_;
	while(locked_)
	    entry_cond_.wait();
	--awaiting_entry_;
	++top_;
	if(top_ == stack_.end())
	    grow();
	locked_ = true;
	mutex_.unlock();
    }

    //! Exit the current recursion level.
    void leave(void) {
	mutex_.lock();
	locked_ = false;
	--top_;
	if(awaiting_entry_ > 0)
	    entry_cond_.signal();
	else if(top_->waiting)
	    top_->cond->signal();
	mutex_.unlock();
    }

    //! Token used to indicate the current recursion level for later
    // resumption.
    typedef _T::size_type token;

    //! Release the lock for use by deeper recursion levels.
    token release(void) {
	mutex_.lock();
	locked_ = false;
	if(awaiting_entry_ > 0)
	    entry_cond_.signal();
	token t = top_ - stack_.begin();
	mutex_.unlock();
	return t;
    }

    //! Resume the specified recursion level.
    void resume(token t) {
	mutex_.lock();
	_T::iterator ti = stack_.begin() + t;
	ti->waiting = true;
	while(locked_ || ti != top_) {
	    ti->cond->wait();
	    ti = stack_.begin() + t;
	}
	ti->waiting = false;
	locked_ = true;
	mutex_.unlock();
    }
};

// Return the entry lock for the current Perl interpreter
POmniRatchetLock *pomni_entry_lock(pTHX);

/** Object to temporarily unlock the Perl interpreter during a blocking
 * operation, allowing other threads to make use of the interpreter.
 * Usage should follow the pattern:
 *
 *  PUTBACK;
 *  {
 *      POmniPerlEntryUnlocker ul(aTHX);
 *      <some potentially blocking operation>
 *  }
 *  SPAGAIN;
 */
class POmniPerlEntryUnlocker {
    POmniRatchetLock *entry_lock_;
    POmniRatchetLock::token t_;
public:
    POmniPerlEntryUnlocker(pTHX)
	: entry_lock_(pomni_entry_lock(aTHX)),
	  t_(entry_lock_ ? entry_lock_->release() : 0) {
    }
    ~POmniPerlEntryUnlocker(void) {
	if (entry_lock_)
	    entry_lock_->resume(t_);
    }
};

/*!
 * ORB instance
 */
extern CORBA::ORB_ptr pomni_orb;

