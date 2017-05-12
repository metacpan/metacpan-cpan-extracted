#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AB_IN.h"
#include "Av_AB_INPtr.h"

#ifdef __cplusplus
}
#endif


MODULE = CookBookB::Struct2		PACKAGE = CookBookB::Struct2

void
hello(pAB)
	AB_IN *pAB
    CODE:
	printf("# Hello, string=(%s)\n", pAB->szDescription );


AB_IN *
makeone()
    CODE:
	RETVAL = (AB_IN*)safemalloc( sizeof( AB_IN ) );
	if( RETVAL == NULL ){
		warn("makeone: unable to malloc");
		XSRETURN_UNDEF;
	}
	RETVAL->lTrackId = 38;
	strcpy( RETVAL->szDescription, "J.L. Seagull" );
    OUTPUT:
	RETVAL
    CLEANUP:
	safefree( RETVAL );
