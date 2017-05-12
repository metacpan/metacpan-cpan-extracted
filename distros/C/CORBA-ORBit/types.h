#ifndef __PORBIT_TYPES_H__
#define __PORBIT_TYPES_H__

#include <orb/orbit.h>
#include "porbit-perl.h"

SV *porbit_objref_to_sv (CORBA_Object obj);
void porbit_objref_destroy (CORBA_Object obj);
CORBA_Object porbit_sv_to_objref (SV *perlobj);

/* Helper functions for marshalling and demarshalling.
 */
CORBA_long porbit_union_find_arm (CORBA_TypeCode tc, SV *discriminator);
CORBA_long porbit_enum_find_member (CORBA_TypeCode tc, SV *val);

/* [De]marshalling functions
 */
SV *porbit_get_sv (GIOPRecvBuffer *buf, CORBA_TypeCode tc);
SV *porbit_get_exception (GIOPRecvBuffer *buf, CORBA_TypeCode tc,
			  CORBA_exception_type type,
			  CORBA_OperationDescription *opr);
CORBA_boolean porbit_put_sv (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv);
SV *porbit_put_exception (GIOPSendBuffer *buf, CORBA_TypeCode tc, SV *sv,
			  CORBA_ExcDescriptionSeq  *exceptions);

#endif /* __PORBIT_TYPES_H__ */
