#ifndef __PORBIT_INTERFACES_H__
#define __PORBIT_INTERFACES_H__

#include <orb/interface_repository.h>
#include "porbit-perl.h"

typedef struct _PORBitIfaceInfo PORBitIfaceInfo;

/* Encapsulates knowledge about a particular interface
 */
struct _PORBitIfaceInfo {
    char *pkg;
    CORBA_InterfaceDef_FullInterfaceDescription *desc;

    /* Information for servers */
    CORBA_unsigned_long class_id;
    PortableServer_ClassInfo class_info;
};

/* Given either a pointer to an IR object, or a repository ID, load
 * the definition of the IR object from the repository. _orb optionally
 * gives the orb to resolve the initial InterfaceRepository in
 * if iface is not specified
 */
PORBitIfaceInfo  *porbit_load_contained  (CORBA_Contained    container, 
					  const char        *id,
					  CORBA_Environment *ev);
/* Look up interface information for a given repoid
 */
PORBitIfaceInfo  *porbit_find_interface_description (const char *repo_id);

/* Store a new interface into the type system, desc will be used or freed.
 */
PORBitIfaceInfo *porbit_init_interface (CORBA_InterfaceDef_FullInterfaceDescription *desc,
					const char                                  *package_name,
					CORBA_Environment                           *ev);

/* Initialize a constant. Assumes ownership of SV's refcount
 */
void porbit_init_constant (const char *pkgname, const char *name, SV *sv);

/* Find or create a TypeCode object for the given ID
 */
CORBA_TypeCode porbit_find_typecode (const char *id);

/* Store a TypeCode object for the given repoid
 */
void      porbit_store_typecode  (const char *repoid, CORBA_TypeCode tc);

/* Initialize typecodes for the standard types
 */
void      porbit_init_typecodes  (void);

#define PORBIT_REPOID_KEY "_repoid"

#define PORBIT_OFFSET 0x10000000
#define PORBIT_OPERATION_BASE 0
#define PORBIT_GETTER_BASE (PORBIT_OPERATION_BASE + PORBIT_OFFSET)
#define PORBIT_SETTER_BASE (PORBIT_GETTER_BASE + PORBIT_OFFSET)

#endif /* __PORBIT_INTERFACES_H__ */
