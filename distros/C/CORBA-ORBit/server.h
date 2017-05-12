#ifndef __PORBIT_SERVER_H__
#define __PORBIT_SERVER_H__

#include "porbit-perl.h"
#include <orb/orbit.h>

typedef struct _PORBitServant PORBitServant;
typedef struct _PORBitInstVars PORBitInstVars;

struct _PORBitServant {
    void *_private;
    PortableServer_ServantBase__vepv *vepv;

    SV *perlobj;
    CORBA_InterfaceDef_FullInterfaceDescription *desc;
};

/* Information attached to a Perl servant via '~' magic
 */
struct _PORBitInstVars
{
    U32 magic;	                // 0x18981972 
    PortableServer_Servant servant;
};

/* Magically add an InstVars structure to a perl servant */
PORBitInstVars *   porbit_instvars_add     (SV            *perl_obj);
/* Get the InstVars structure for an object */
PORBitInstVars *   porbit_instvars_get     (SV            *perl_obj);
/* Callback when perl servant is destroyed */
void              porbit_instvars_destroy (PORBitInstVars *instvars);

/* Find or create a Perl object for the given servant */
SV *              porbit_servant_to_sv    (PortableServer_Servant servant);
/* Given a Perl object which is a descendant of CORBA::Object, find
 * or create the corresponding C servant.
 */
PortableServer_Servant porbit_sv_to_servant    (SV            *perl_obj);

/* Ref and unref the Perl object corresponding to a servant
 */
void porbit_servant_ref   (PortableServer_Servant servant);
void porbit_servant_unref (PortableServer_Servant servant);

PORBitServant    *porbit_servant_create   (SV                *perlobj,
					   CORBA_Environment *ev);
void              porbit_servant_destroy  (PORBitServant      *servant,
					   CORBA_Environment  *ev);

/* Convert between SV * and PortableServer_ObjectId
 */
PortableServer_ObjectId *porbit_sv_to_objectid (SV *sv);
SV *porbit_objectid_to_sv (PortableServer_ObjectId *oid);

#endif /* __PORBIT_SERVER_H__ */



