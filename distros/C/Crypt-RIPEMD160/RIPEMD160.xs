/*
Perl Extension for the RIPEMD160 Message-Digest Algorithm

This module by Christian H. Geuer <christian.geuer@crypto.gun.de>
following example of MD5 module and SHA module.

This extension (wrapper code and perl-stuff) may be distributed 
under the same terms as Perl. 
*/

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
	    safefree((char *) ripemd160);
	}


void
reset(ripemd160)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    RIPEMD160_init(ripemd160);
	}

void
rmd160_add(ripemd160, ...)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    SV *svdata;
	    STRLEN len;
	    byte *strptr;
	    int i;

	    for (i = 1; i < items; i++) {
		strptr = (byte *) (SvPV(ST(i), len));
		RIPEMD160_update(ripemd160, strptr, len);
	    }
	}

SV *
rmd160_digest(ripemd160)
	Crypt::RIPEMD160	ripemd160
    CODE:
	{
	    unsigned char d_str[20];

	    RIPEMD160_final(ripemd160);

	    d_str[ 0] = (unsigned char) ((ripemd160->MDbuf[0]      ) & 0xff);
	    d_str[ 1] = (unsigned char) ((ripemd160->MDbuf[0] >>  8) & 0xff);
	    d_str[ 2] = (unsigned char) ((ripemd160->MDbuf[0] >> 16) & 0xff);
	    d_str[ 3] = (unsigned char) ((ripemd160->MDbuf[0] >> 24) & 0xff);
	    d_str[ 4] = (unsigned char) ((ripemd160->MDbuf[1]      ) & 0xff);
	    d_str[ 5] = (unsigned char) ((ripemd160->MDbuf[1] >>  8) & 0xff);
	    d_str[ 6] = (unsigned char) ((ripemd160->MDbuf[1] >> 16) & 0xff);
	    d_str[ 7] = (unsigned char) ((ripemd160->MDbuf[1] >> 24) & 0xff);
	    d_str[ 8] = (unsigned char) ((ripemd160->MDbuf[2]      ) & 0xff);
	    d_str[ 9] = (unsigned char) ((ripemd160->MDbuf[2] >>  8) & 0xff);
	    d_str[10] = (unsigned char) ((ripemd160->MDbuf[2] >> 16) & 0xff);
	    d_str[11] = (unsigned char) ((ripemd160->MDbuf[2] >> 24) & 0xff);
	    d_str[12] = (unsigned char) ((ripemd160->MDbuf[3]      ) & 0xff);
	    d_str[13] = (unsigned char) ((ripemd160->MDbuf[3] >>  8) & 0xff);
	    d_str[14] = (unsigned char) ((ripemd160->MDbuf[3] >> 16) & 0xff);
	    d_str[15] = (unsigned char) ((ripemd160->MDbuf[3] >> 24) & 0xff);
	    d_str[16] = (unsigned char) ((ripemd160->MDbuf[4]      ) & 0xff);
	    d_str[17] = (unsigned char) ((ripemd160->MDbuf[4] >>  8) & 0xff);
	    d_str[18] = (unsigned char) ((ripemd160->MDbuf[4] >> 16) & 0xff);
	    d_str[19] = (unsigned char) ((ripemd160->MDbuf[4] >> 24) & 0xff);

	    ST(0) = sv_2mortal(newSVpv(d_str, 20));
	}
