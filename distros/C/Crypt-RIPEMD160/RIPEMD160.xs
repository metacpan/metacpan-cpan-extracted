/*
Perl Extension for the RIPEMD160 Message-Digest Algorithm

This module by Christian H. Geuer <christian.geuer@crypto.gun.de>
following example of MD5 module and SHA module.

This extension (wrapper code and perl-stuff) may be distributed
under the same terms as Perl.
*/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wrap_160.h"

MODULE = Crypt::RIPEMD160	PACKAGE = Crypt::RIPEMD160	PREFIX = rmd160_

PROTOTYPES: DISABLE

Crypt::RIPEMD160
rmd160_new(packname = "Crypt::RIPEMD160")
	char *		packname
    CODE:
	{
	    PERL_UNUSED_VAR(packname);
	    RETVAL = (Crypt__RIPEMD160) safemalloc(sizeof(RIPEMD160_INFO));
	    RIPEMD160_init(RETVAL);
	}
    OUTPUT:
	RETVAL


void
rmd160_DESTROY(ripemd160)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    secure_memzero(ripemd160, sizeof(RIPEMD160_INFO));
	    safefree((char *) ripemd160);
	}


void
reset(ripemd160)
	Crypt::RIPEMD160	ripemd160
    PPCODE:
	{
	    RIPEMD160_init(ripemd160);
	    /* return self for method chaining */
	    XSRETURN(1);
	}

Crypt::RIPEMD160
rmd160_clone(ripemd160)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    RETVAL = (Crypt__RIPEMD160) safemalloc(sizeof(RIPEMD160_INFO));
	    memcpy(RETVAL, ripemd160, sizeof(RIPEMD160_INFO));
	}
    OUTPUT:
	RETVAL


void
rmd160_add(ripemd160, ...)
	Crypt::RIPEMD160	ripemd160
    PPCODE:
	{
	    STRLEN len;
	    byte *strptr;
	    int i;

	    for (i = 1; i < items; i++) {
		strptr = (byte *) (SvPVbyte(ST(i), len));
#if PTRSIZE > 4
		/* STRLEN is 64-bit on 64-bit systems but RIPEMD160_update
		   takes a 32-bit dword length; chunk to avoid truncation */
		while (len > (STRLEN)0xFFFFFFFFU) {
		    RIPEMD160_update(ripemd160, strptr, (dword)0xFFFFFFFFU);
		    strptr += 0xFFFFFFFFU;
		    len -= 0xFFFFFFFFU;
		}
#endif
		RIPEMD160_update(ripemd160, strptr, (dword)len);
	    }
	    /* return self for method chaining */
	    XSRETURN(1);
	}

SV *
rmd160_digest(ripemd160)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    unsigned char d_str[20];
	    int i;

	    RIPEMD160_final(ripemd160);

	    for (i = 0; i < 5; i++) {
		d_str[4*i  ] = (unsigned char)(ripemd160->MDbuf[i]       & 0xff);
		d_str[4*i+1] = (unsigned char)(ripemd160->MDbuf[i] >>  8 & 0xff);
		d_str[4*i+2] = (unsigned char)(ripemd160->MDbuf[i] >> 16 & 0xff);
		d_str[4*i+3] = (unsigned char)(ripemd160->MDbuf[i] >> 24 & 0xff);
	    }

	    RETVAL = newSVpvn((const char *)d_str, 20);
	}
    OUTPUT:
	RETVAL
