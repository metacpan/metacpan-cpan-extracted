#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

struct PerlObjectRecord {
	char *record;
	int length;
};

typedef struct PerlObjectRecord Record;

MODULE = CookBookB::Opaque		PACKAGE = CookBookB::Opaque

Record *
new(CLASS,len)
	char *CLASS
	int len
    CODE:
	RETVAL = (Record *)safemalloc( sizeof(Record) );
	if( RETVAL == NULL ){
		warn("unable to malloc Record");
		XSRETURN_UNDEF;
	}
	RETVAL->record = (char*)safemalloc( len );
	if( RETVAL->record == NULL ){
		warn("unable to malloc string");
		safefree( (char*)RETVAL );
		XSRETURN_UNDEF;
	}
	RETVAL->length = len;
	strncpy( RETVAL->record, "Alternative-Rock Doppelgaengers", len );
    OUTPUT:
	RETVAL

void
DESTROY(self)
	Record *self
    CODE:
	safefree(self->record);
	safefree(self);

void
function(self,par1,offset,par4)
	Record *self
	int	par1
	int	offset
	int	par4
    CODE:
	printf("(%s) %d\n", self->record, self->length );
	

