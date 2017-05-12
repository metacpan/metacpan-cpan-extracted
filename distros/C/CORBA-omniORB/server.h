/* -*- mode: C++; c-file-style: "bsd" -*- */

#ifndef __SERVER_H__
#define __SERVER_H__

// Magically add an InstVars structure to a perl servant
POmniInstVars *   pomni_instvars_add     (pTHX_
					  SV            *perl_obj);
// Get the InstVars structure for an object
POmniInstVars *   pomni_instvars_get     (pTHX_
					  SV            *perl_obj);
// Callback when perl servant is destroyed
void              pomni_instvars_destroy (pTHX_
					  POmniInstVars *instvars);

// Find or create a Perl object for a given CORBA::Object
SV *              pomni_servant_to_sv    (pTHX_
					  PortableServer::Servant servant);
// Given a Perl object which is a descendant of CORBA::Object, find
// or create the corresponding C++ CORBA::Object
PortableServer::Servant pomni_sv_to_servant (pTHX_
					     SV         *perl_obj);

// Class that handles method invocations for a object incarnated
// in a Perl object.
class POmniServant : public PortableServer::DynamicImplementation,
		     public PortableServer::RefCountServantBase {
public:
    POmniServant (SV *_perlobj);
    virtual void invoke ( CORBA::ServerRequest_ptr _req );
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

private:
    virtual ~POmniServant ();	// allocate in heap only
    bool builtin_invoke               (pTHX_
				       CORBA::ServerRequest_ptr svreq);

    CORBA::OperationDescription *find_operation (pTHX_
						 CORBA::InterfaceDef::FullInterfaceDescription *d, 
						 const char  *name);
    CORBA::AttributeDescription *find_attribute (pTHX_
						 CORBA::InterfaceDef::FullInterfaceDescription *d, 
						 const char  *name, 
						 bool         set);
    CORBA::NVList_ptr  build_args               (pTHX_
						 const char  *name, 
						 int         &return_items,
						 CORBA::TypeCode *&return_type,
						 int         &inout_items,
						 CORBA::ExcDescriptionSeq  *&exceptions);
    PerlInterpreter* thx;	//! Perl context
    SV *perlobj;
    CORBA::InterfaceDef::FullInterfaceDescription *desc;
};

// Specialized skeleton classes for the POA

class POmniAdapterActivator : public POA_PortableServer::AdapterActivator {
public:
    POmniAdapterActivator          (SV *_perlobj) {
	thx = (PerlInterpreter*)PERL_GET_THX;
	perlobj = SvRV(_perlobj);
    }

    CORBA::Boolean unknown_adapter (PortableServer::POA_ptr parent, 
				    const char *            name);

private:
    PerlInterpreter* thx;	//! Perl context
    SV *perlobj;
};

class POmniServantActivator : public virtual POA_PortableServer::ServantActivator {
public:
    POmniServantActivator(SV *_perlobj);

    PortableServer::Servant incarnate   (const PortableServer::ObjectId& oid,
				         PortableServer::POA_ptr         adapter);
    void                    etherealize (const PortableServer::ObjectId& oid,
					 PortableServer::POA_ptr         adapter,
					 PortableServer::Servant         serv,
					 CORBA::Boolean                  cleanup_in_progress,
					 CORBA::Boolean                  remaining_activations);
private:
    virtual ~POmniServantActivator (); // allocate in heap only
    PerlInterpreter* thx;	//! Perl context
    SV *perlobj;
};

class POmniServantLocator : public POA_PortableServer::ServantLocator {
public:
    POmniServantLocator                (SV *_perlobj) {
	thx = (PerlInterpreter*)PERL_GET_THX;
	perlobj = SvRV(_perlobj);
    }

    PortableServer::Servant preinvoke  (const PortableServer::ObjectId& oid,
				        PortableServer::POA_ptr   adapter,
				        const char *                    operation,
				        PortableServer::ServantLocator::Cookie &the_cookie);
    void                    postinvoke (const PortableServer::ObjectId& oid,
					PortableServer::POA_ptr   adapter,
					const char *                    operation,
					PortableServer::ServantLocator::Cookie  the_cookie,
					PortableServer::Servant         serv);
private:
    PerlInterpreter* thx;	//! Perl context
    SV *perlobj;
};

// Information attached to a Perl servant via PERL_MAGIC_ext magic
struct POmniInstVars
{
    U32 magic;	                // 0x18981972 
    PortableServer::Servant servant;
};

#endif /* __SERVER_H__ */
