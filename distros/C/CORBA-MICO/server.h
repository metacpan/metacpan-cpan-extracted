/* -*- mode: C++; c-file-style: "bsd" -*- */

#ifndef __SERVER_H__
#define __SERVER_H__

// Magically add an InstVars structure to a perl servant
PMicoInstVars *   pmico_instvars_add     (SV            *perl_obj);
// Get the InstVars structure for an object
PMicoInstVars *   pmico_instvars_get     (SV            *perl_obj);
// Callback when perl servant is destroyed
void              pmico_instvars_destroy (PMicoInstVars *instvars);

// Find or create a Perl object for a given CORBA::Object
SV *              pmico_servant_to_sv    (PortableServer::Servant servant);
// Given a Perl object which is a descendant of CORBA::Object, find
// or create the corresponding C++ CORBA::Object
PortableServer::Servant pmico_sv_to_servant    (SV            *perl_obj);

// Class that handles method invocations for a object incarnated
// in a Perl object.
class PMicoServant : public PortableServer::DynamicImplementation {
public:
    PMicoServant (SV *_perlobj);
    virtual ~PMicoServant ();
    virtual void invoke ( CORBA::ServerRequest_ptr _req );
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);
    
private:
    bool builtin_invoke (CORBA::ServerRequest_ptr svreq);

    CORBA::OperationDescription *find_operation(
	CORBA::InterfaceDef::FullInterfaceDescription *d, 
	const char  *name);
    CORBA::AttributeDescription *find_attribute(
	CORBA::InterfaceDef::FullInterfaceDescription *d, 
	const char  *name, 
	bool         set);
    CORBA::NVList_ptr build_args(
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

class PMicoAdapterActivator : public POA_PortableServer::AdapterActivator {
public:
    PMicoAdapterActivator          (SV *_perlobj) {
	perlobj = SvRV(_perlobj);
    }

    CORBA::Boolean unknown_adapter (PortableServer::POA_ptr parent, 
				    const char *            name);

private:
    SV *perlobj;
};

class PMicoServantActivator : public virtual POA_PortableServer::ServantActivator {
public:
    PMicoServantActivator(SV *_perlobj);

    PortableServer::Servant incarnate   (const PortableServer::ObjectId& oid,
				         PortableServer::POA_ptr         adapter);
    void                    etherealize (const PortableServer::ObjectId& oid,
					 PortableServer::POA_ptr         adapter,
					 PortableServer::Servant         serv,
					 CORBA::Boolean                  cleanup_in_progress,
					 CORBA::Boolean                  remaining_activations);
private:
    PerlInterpreter* thx;	//! Perl context
    SV *perlobj;
};

class PMicoServantLocator : public POA_PortableServer::ServantLocator {
public:
    PMicoServantLocator                (SV *_perlobj) {
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
    SV *perlobj;
};

// Information attached to a Perl servant via '~' magic
struct PMicoInstVars
{
    U32 magic;	                // 0x18981972 
    PortableServer::Servant servant;
};

#endif /* __SERVER_H__ */
