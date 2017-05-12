#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

MODULE = DSP::LinPred_XS    PACKAGE = DSP::LinPred_XS

PROTOTYPES: DISABLE

void
get_stat(...)
PPCODE:
{
    if(items != 1){
	croak("Invalid argument");
    }
    SV* input = ST(0);
    AV* av = (AV*)SvRV(input);
    IV length = av_len(av) + 1;
    IV k;
    NV sum = 0;
    NV variance = 0;
    NV mean,stddev,temp;
    SV** avv_ptr;
    SV* av_val;

    for(k=0;k <= length -1;k++){
	avv_ptr = av_fetch(av,k,FALSE);
	av_val = avv_ptr ? *avv_ptr : &PL_sv_undef;
	sum = sum + SvNV(av_val);
    }
    mean = sum / length;
    for(k=0;k <= length -1;k++){
	avv_ptr = av_fetch(av,k,FALSE);
	av_val = avv_ptr ? *avv_ptr : &PL_sv_undef;
	temp = SvNV(av_val);
	variance = variance + (temp - mean)*(temp - mean);
    }
    variance = variance / length;
    stddev = sqrt(variance);
    mXPUSHs(newSVnv(sum));
    mXPUSHs(newSVnv(mean));
    mXPUSHs(newSVnv(variance));
    mXPUSHs(newSVnv(stddev));
    XSRETURN(4);
}
