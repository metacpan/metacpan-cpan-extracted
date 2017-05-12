#include "../DCE_Perl.h"

MODULE = DCE::UUID PACKAGE = DCE::UUID

void
uuid_create()

    PPCODE:
    {
    error_status_t	status;
    uuid_t	uuid;
    SV *uuid_sv;

    uuid_create(&uuid, &status);
    BLESS_UUID(uuid);
    XPUSHs(uuid_sv);
    if(WANTARRAY)
	DCESTATUS;
    }

void
uuid_hash(uuid, status)
SV *uuid

    PPCODE:
    {
    uuid_t	uuid_struct;
    unsigned16  hash;
    error_status_t	status;

    UUIDmagic_sv(uuid_struct, uuid);
    hash = uuid_hash(&uuid_struct, &status);
    XPUSHs_iv(hash);
    if(WANTARRAY)
	DCESTATUS;
    }

unsigned_char_t *
as_string(uuid_p)
DCE::UUID uuid_p

   CODE:
   {
   unsigned_char_t *uuid;
   error_status_t   status;
   uuid_to_string(uuid_p, &uuid, &status);
   RETVAL = uuid;
   }

   OUTPUT:
   RETVAL

DCE::UUID
uuid_from_string(uuid)
char *uuid

   CODE:
   {
   uuid_t  *uuid_p = (uuid_t *)safemalloc(sizeof(uuid_t));
   error_status_t status;

   uuid_from_string(uuid, uuid_p, &status);
   if(status != 0)
       croak("couldn't convert uuid_from_string\n");
   RETVAL = uuid_p;
   }
   
   OUTPUT:
   RETVAL
 
void
DESTROY(uuid)
DCE::UUID uuid

    CODE:
    safefree((DCE__UUID)uuid);


