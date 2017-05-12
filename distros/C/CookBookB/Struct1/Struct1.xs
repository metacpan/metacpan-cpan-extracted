#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

typedef struct ab_input {
	long lTrackId;
	char szDescription[80];
} AB_IN;


MODULE = CookBookB::Struct1		PACKAGE = CookBookB::Struct1

AB_IN *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = (AB_IN*)safemalloc( sizeof( AB_IN ) );
	if( RETVAL == NULL ){
		warn("unable to allocate AB_IN");
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

void
DESTROY(self)
	AB_IN *self
    CODE:
	safefree( (char*)self );

int
hello(pAB)
	AB_IN *pAB
    CODE:
	printf("# Hello, string=(%s)\n", pAB->szDescription );
	RETVAL=100;
    OUTPUT:
	RETVAL

void
desc(pAB,str)
	AB_IN *pAB
	char *str
    CODE:
	strcpy( pAB->szDescription,  str );
