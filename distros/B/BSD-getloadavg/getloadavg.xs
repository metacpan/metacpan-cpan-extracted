#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <stdlib.h>

SV *
getloadavg_as_aref(){
    SV*        sva[3];
    double loadavg[3];
    if (getloadavg(loadavg, 3) == -1){
	return &PL_sv_undef;
    }else{
	sva[0]  = sv_2mortal(newSVnv(loadavg[0]));
	sva[1]  = sv_2mortal(newSVnv(loadavg[1]));
	sva[2]  = sv_2mortal(newSVnv(loadavg[2]));
	return newRV_noinc((SV *)av_make(3, sva));
    }
}

MODULE = BSD::getloadavg		PACKAGE = BSD::getloadavg

PROTOTYPES: ENABLE

SV *
xs_getloadavg()
CODE:
        RETVAL = getloadavg_as_aref();
OUTPUT:
        RETVAL


