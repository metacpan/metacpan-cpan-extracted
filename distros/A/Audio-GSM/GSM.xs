#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gsm.h>

#include "const-c.inc"

int gsm_setoption(gsm handle, int option, int value) {
    return gsm_option(handle, option, &value);
}

int gsm_getoption(gsm handle, int option) {
    return gsm_option(handle, option, NULL);
}

void gsm_encode2(gsm handle, const char * pcmData, char * gsmData) {
    gsm_encode(handle, (gsm_signal *)pcmData, (gsm_byte *)gsmData);
    gsm_encode(handle, (gsm_signal *)(pcmData + 320), (gsm_byte *)(gsmData + 32));
}

int gsm_decode2(gsm handle, const char * gsmData, char * pcmData) {
    int rv = gsm_decode(handle, (gsm_byte *)gsmData, (gsm_signal *)pcmData);
    rv = rv || gsm_decode(handle, (gsm_byte *)(gsmData + 33), (gsm_signal *)(pcmData + 320));
    return rv;
}

MODULE = Audio::GSM		PACKAGE = Audio::GSM

INCLUDE: const-xs.inc

gsm
gsm_create()

#int
#gsm_decode(arg0, arg1, arg2)
#	gsm	arg0
#	gsm_byte *	arg1
#	gsm_signal *	arg2

void
gsm_destroy(handle)
	gsm	handle

#void
#gsm_encode(arg0, arg1, arg2)
#	gsm	arg0
#	gsm_signal *	arg1
#	gsm_byte *	arg2

#int
#gsm_explode(arg0, arg1, arg2)
#	gsm	arg0
#	gsm_byte *	arg1
#	gsm_signal *	arg2

#void
#gsm_implode(arg0, arg1, arg2)
#	gsm	arg0
#	gsm_signal *	arg1
#	gsm_byte *	arg2

#int
#gsm_option(arg0, arg1, arg2)
#	gsm	arg0
#	int	arg1
#	int *	arg2

int
gsm_setoption(handle, option, value)
	gsm	handle
	int	option
	int	value

int
gsm_getoption(handle, option)
	gsm	handle
	int	option

void
gsm_encode2(handle, pcmData, gsmData)
        gsm     handle
        const char *    pcmData
        char *  gsmData
        
int
gsm_decode2(handle, gsmData, pcmData)
        gsm     handle
        const char *    gsmData
        char *  pcmData
