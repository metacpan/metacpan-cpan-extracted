/* LZO.xs -- Perl bindings for the LZO data compression library

   This file is part of the LZO real-time data compression library.

   Copyright (C) 2002 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2001 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2000 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1999 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1998 Markus Franz Xaver Johannes Oberhumer
   All Rights Reserved.

   The LZO library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of
   the License, or (at your option) any later version.

   The LZO library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with the LZO library; see the file COPYING.
   If not, write to the Free Software Foundation, Inc.,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

   Markus F.X.J. Oberhumer
   <markus@oberhumer.com>
   http://www.oberhumer.com/opensource/lzo/
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <lzo/lzoconf.h>
#include <lzo/lzo1x.h>

#if !defined(LZO_VERSION) || (LZO_VERSION < 0x1070)
#  error "Need LZO v1.07 or newer"
#endif

#undef UNUSED
#define UNUSED(x)       ((void)&x)


/* If the buffer is a reference, dereference it */
static SV *deRef(SV *sv, const char *method)
{
	SV *last_sv = NULL;
	while (SvROK(sv) && sv != last_sv)
	{
		last_sv = sv;
		sv = SvRV(sv);
	}
	if (!SvOK(sv))
		croak("Compress::LZO::%s: buffer parameter is not a SCALAR", method);
	return sv;
}


static double constant(const char *name, int arg)
{
    UNUSED(name);
    UNUSED(arg);
	errno = EINVAL;
	return 0;
}


/***********************************************************************
// XSUB start
************************************************************************/

MODULE = Compress::LZO   PACKAGE = Compress::LZO   PREFIX = X_

REQUIRE:	1.924
PROTOTYPES:	ENABLE

BOOT:
	if (lzo_init() != LZO_E_OK)
		croak("Compress::LZO lzo_init() failed\n");


#define X_LZO_VERSION()         lzo_version()
unsigned
X_LZO_VERSION()

#define X_LZO_VERSION_STRING()  (const char *)lzo_version_string()
const char *
X_LZO_VERSION_STRING()

#define X_LZO_VERSION_DATE()    (const char *)lzo_version_date()
const char *
X_LZO_VERSION_DATE()

double
constant(name, arg)
		const char *     name
		int        arg


#/***********************************************************************
#// compress
#************************************************************************/

SV *
X_compress(string, level = 1)
	PREINIT:
		SV *       sv;
		STRLEN     len;
		int        level = 1;
		lzo_bytep  in;
		lzo_bytep  out;
		lzo_voidp  wrkmem;
		lzo_uint   in_len;
		lzo_uint   out_len;
		lzo_uint   new_len;
		int        err;
	CODE:
		sv = deRef(ST(0), "compress");
		in = (lzo_bytep) SvPV(sv, len);
		if (items == 2 && SvOK(ST(1)))
			level = SvIV(ST(1));
		in_len = len;
		out_len = in_len + in_len / 64 + 16 + 3;
		RETVAL = newSV(5+out_len);
		SvPOK_only(RETVAL);
		if (level == 1)
			wrkmem = safemalloc(LZO1X_1_MEM_COMPRESS);
		else
			wrkmem = safemalloc(LZO1X_999_MEM_COMPRESS);
		out = SvPVX(RETVAL);
		new_len = out_len;
		if (level == 1)	{
			out[0] = 0xf0;
			err = lzo1x_1_compress(in,in_len,out+5,&new_len,wrkmem);
		} else {
			out[0] = 0xf1;
			err = lzo1x_999_compress(in,in_len,out+5,&new_len,wrkmem);
		}
		safefree(wrkmem);
		if (err != LZO_E_OK || new_len > out_len)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL,5+new_len);
		out[1] = (in_len >> 24) & 0xff;
		out[2] = (in_len >> 16) & 0xff;
		out[3] = (in_len >>  8) & 0xff;
		out[4] = (in_len >>  0) & 0xff;
	OUTPUT:
		RETVAL


#/***********************************************************************
#// decompress
#************************************************************************/

SV *
X_decompress(string)
	PREINIT:
		SV *       sv;
		STRLEN     len;
		lzo_bytep  in;
		lzo_bytep  out;
		lzo_uint   in_len;
		lzo_uint   out_len;
		lzo_uint   new_len;
		int        err;
	CODE:
		sv = deRef(ST(0), "decompress");
		in = (lzo_bytep) SvPV(sv, len);
		if (len < 5 + 3 || in[0] < 0xf0 || in[0] > 0xf1)
			XSRETURN_UNDEF;
		in_len = len - 5;
		out_len = (in[1] << 24) | (in[2] << 16) | (in[3] << 8) | in[4];
		RETVAL = newSV(out_len > 0 ? out_len : 1);
		SvPOK_only(RETVAL);
		out = SvPVX(RETVAL);
		new_len = out_len;
		err = lzo1x_decompress_safe(in+5,in_len,out,&new_len,NULL);
		if (err != LZO_E_OK || new_len != out_len)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL, new_len);
	OUTPUT:
		RETVAL


#/***********************************************************************
#// optimize
#************************************************************************/

SV *
X_optimize(string)
	PREINIT:
		SV *       sv;
		STRLEN     len;
		lzo_bytep  in;
		lzo_bytep  out;
		lzo_uint   in_len;
		lzo_uint   out_len;
		lzo_uint   new_len;
		int        err;
	CODE:
		sv = deRef(ST(0), "optimize");
		RETVAL = newSVsv(sv);
		SvPOK_only(RETVAL);
		in = (lzo_bytep) SvPV(RETVAL, len);
		if (len < 5 + 3 || in[0] < 0xf0 || in[0] > 0xf1)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
		in_len = len - 5;
		out_len = (in[1] << 24) | (in[2] << 16) | (in[3] << 8) | in[4];
		out = (lzo_bytep) safemalloc(out_len > 0 ? out_len : 1);
		new_len = out_len;
		err = lzo1x_optimize(in+5,in_len,out,&new_len,NULL);
		safefree(out);
		if (err != LZO_E_OK || new_len != out_len)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL


#/***********************************************************************
#// checksums
#************************************************************************/

lzo_uint32
X_adler32(string, adler = adlerInitial)
	PREINIT:
		SV *       sv;
		STRLEN     len;
		lzo_bytep  buf;
	CODE:
		sv = deRef(ST(0), "adler32");
		buf = (lzo_bytep) SvPV(sv, len);
		if (items == 2 && SvOK(ST(1)))
			RETVAL = SvUV(ST(1));
		else
			RETVAL = 1;
		RETVAL = lzo_adler32(RETVAL, buf, (lzo_uint)len);
	OUTPUT:
		RETVAL


lzo_uint32
X_crc32(string, crc = crcInitial)
	PREINIT:
		SV *       sv;
		STRLEN     len;
		lzo_bytep  buf;
	CODE:
		sv = deRef(ST(0), "crc32");
		buf = (lzo_bytep) SvPV(sv, len);
		if (items == 2 && SvOK(ST(1)))
			RETVAL = SvUV(ST(1));
		else
			RETVAL = 0;
		RETVAL = lzo_crc32(RETVAL, buf, (lzo_uint)len);
	OUTPUT:
		RETVAL



# vi:ts=4
