#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Mstruct.h"
#include "Av_MystructPtr.h"

#ifdef __cplusplus
}
#endif

int myfunc _(( Mystruct *p ));
static int myInt = 2001;

int
myfunc( p )
Mystruct *p;
{
	p->mymember1 = 1451;
	p->mymember2 = 1452;
	p->iData[0] = 1957;
	p->iData[1] = 1958;
	p->iData[2] = 1959;
	p->Data = &myInt;

	return 42;
}

MODULE = CookBookB::Mstruct		PACKAGE = CookBookB::Mstruct

int
myfunc(p)
	Mystruct *p = NO_INIT
    CODE:
	p = (Mystruct *)safemalloc(sizeof(Mystruct));
	if (p == NULL ){
		warn("Unable to allocate pMystruct");
		XSRETURN_UNDEF;
	}
	RETVAL = myfunc( p );
    OUTPUT:
	p
	RETVAL
    CLEANUP:
	safefree((char*)p);

int
myfunc2(av)
    PREINIT:
	Mystruct *p;
    INPUT:
	AV *av
    CODE:
	p = (Mystruct *)safemalloc(sizeof(Mystruct));
	if (p == NULL ){
		warn("Unable to allocate pMystruct");
		XSRETURN_UNDEF;
	}
	RETVAL = myfunc( p );
	Packav( av, p );
	safefree((char*)p);
    OUTPUT:
	RETVAL

