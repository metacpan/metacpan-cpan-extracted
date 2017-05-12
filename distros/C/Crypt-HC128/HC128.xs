#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <cyassl/ctaocrypt/hc128.h>

#include "const-c.inc"

MODULE = Crypt::HC128		PACKAGE = Crypt::HC128		

INCLUDE: const-xs.inc


int
Hc128_Process(arg0, arg1, arg2, arg3)
	HC128 *	arg0
	byte *	arg1
	const byte *	arg2
	word32	arg3

int
Hc128_SetKey(arg0, key, iv)
	HC128 *	arg0
	const byte *	key
	const byte *	iv

