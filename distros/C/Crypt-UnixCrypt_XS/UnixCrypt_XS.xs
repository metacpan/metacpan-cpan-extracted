#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef bytes_from_utf8

/* 5.6.0 has UTF-8 scalars, but lacks the utility bytes_from_utf8() */

static U8 *
bytes_from_utf8(U8 *orig, STRLEN *len_p, bool *is_utf8_p)
{
	STRLEN orig_len = *len_p;
	U8 *orig_end = orig + orig_len;
	STRLEN new_len = orig_len;
	U8 *new;
	U8 *p, *q;
	if(!*is_utf8_p)
		return orig;
	for(p = orig; p != orig_end; ) {
		U8 fb = *p++, sb;
		if(fb <= 0x7f)
			continue;
		if(p == orig_end || !(fb >= 0xc2 && fb <= 0xc3))
			return orig;
		sb = *p++;
		if(!(sb >= 0x80 && sb <= 0xbf))
			return orig;
		new_len--;
	}
	if(new_len == orig_len) {
		*is_utf8_p = 0;
		return orig;
	}
	Newz(0, new, new_len+1, U8);
	for(p = orig, q = new; p != orig_end; ) {
		U8 fb = *p++;
		*q++ = fb <= 0x7f ? fb : ((fb & 0x03) << 6) | (*p++ & 0x3f);
	}
	*q = 0;
	*len_p = new_len;
	*is_utf8_p = 0;
	return new;
}

#endif /* !bytes_from_utf8 */

#include <./fcrypt/fcrypt.h>

static void
sv_to_octets(U8 **octets_p, STRLEN *len_p, bool *must_free_p, SV *sv)
{
  U8 *in_str = SvPV(sv, *len_p);
  bool is_utf8 = !!SvUTF8(sv);
  *octets_p = bytes_from_utf8(in_str, len_p, &is_utf8);
  if(is_utf8)
    croak("input must contain only octets");
  *must_free_p = *octets_p != in_str;
}

static void
sv_to_cblock(des_cblock block, SV *in_block)
{
  U8 *in_octets;
  STRLEN in_len;
  bool must_free;
  sv_to_octets(&in_octets, &in_len, &must_free, in_block);
  if(in_len != 8)
    croak("data block must be eight octets long");
  memcpy(block, in_octets, 8);
  if(must_free)
    Safefree(in_octets);
}

MODULE = Crypt::UnixCrypt_XS		PACKAGE = Crypt::UnixCrypt_XS		

char *
crypt( password, salt )
  SV *password
  SV *salt
  CODE:
    STRLEN password_len, salt_len;
    U8 *password_octets, *salt_octets;
    bool password_tofree, salt_tofree;
    char outbuf[21];
    sv_to_octets(&password_octets, &password_len, &password_tofree, password);
    sv_to_octets(&salt_octets, &salt_len, &salt_tofree, salt);
    des_fcrypt((char *)password_octets, password_len,
	(char *)salt_octets, salt_len, outbuf);
    if(password_tofree)
      Safefree(password_octets);
    if(salt_tofree)
      Safefree(salt_octets);
    RETVAL = outbuf;
  OUTPUT:
    RETVAL

SV *
crypt_rounds( password, nrounds, saltnum, in_block )
  SV *password
  unsigned long nrounds
  unsigned long saltnum
  SV *in_block
  CODE:
    STRLEN password_len;
    U8 *password_octets;
    bool password_tofree;
    des_cblock key, block;
    sv_to_octets(&password_octets, &password_len, &password_tofree, password);
    sv_to_cblock(block, in_block);
    trad_password_to_key(key, (char *)password_octets, password_len);
    if(password_tofree)
      Safefree(password_octets);
    crypt_rounds(key, nrounds, saltnum, block);
    RETVAL = newSVpvn(block, 8);
  OUTPUT:
    RETVAL

SV *
fold_password( password )
  SV *password
  CODE:
    STRLEN password_len;
    U8 *password_octets;
    bool password_tofree;
    des_cblock key;
    int i;
    sv_to_octets(&password_octets, &password_len, &password_tofree, password);
    ext_password_to_key(key, (char *)password_octets, password_len);
    if(password_tofree)
      Safefree(password_octets);
    for(i=0; i<8; i++)
      key[i] = (key[i] & 0xfe) >> 1;
    RETVAL = newSVpvn(key, 8);
  OUTPUT:
    RETVAL

SV *
base64_to_block( base64 )
  SV *base64
  CODE:
    STRLEN base64_len;
    U8 *base64_octets;
    bool base64_tofree;
    des_cblock block;
    sv_to_octets(&base64_octets, &base64_len, &base64_tofree, base64);
    if(base64_len != 11)
      croak("data block in base 64 must be eleven characters long");
    base64_to_block(block, (char *)base64_octets);
    if(base64_tofree)
      Safefree(base64_octets);
    RETVAL = newSVpvn(block, 8);
  OUTPUT:
    RETVAL

char *
block_to_base64( in_block )
  SV *in_block
  CODE:
    des_cblock block;
    char base64[12];
    sv_to_cblock(block, in_block);
    block_to_base64(block, base64);
    RETVAL = base64;
  OUTPUT:
    RETVAL

unsigned long
base64_to_int24( base64 )
  SV *base64
  CODE:
    STRLEN base64_len;
    U8 *base64_octets;
    bool base64_tofree;
    sv_to_octets(&base64_octets, &base64_len, &base64_tofree, base64);
    if(base64_len != 4)
      croak("24-bit integer in base 64 must be four characters long");
    RETVAL = base64_to_int24((char *)base64_octets);
    if(base64_tofree)
      Safefree(base64_octets);
  OUTPUT:
    RETVAL

char *
int24_to_base64( val )
  unsigned long val;
  CODE:
    char base64[5];
    int24_to_base64(val, base64);
    RETVAL = base64;
  OUTPUT:
    RETVAL

unsigned long
base64_to_int12( base64 )
  SV *base64
  CODE:
    STRLEN base64_len;
    U8 *base64_octets;
    bool base64_tofree;
    sv_to_octets(&base64_octets, &base64_len, &base64_tofree, base64);
    if(base64_len != 2)
      croak("12-bit integer in base 64 must be two characters long");
    RETVAL = base64_to_int12((char *)base64_octets);
    if(base64_tofree)
      Safefree(base64_octets);
  OUTPUT:
    RETVAL

char *
int12_to_base64( val )
  unsigned long val;
  CODE:
    char base64[3];
    int12_to_base64(val, base64);
    RETVAL = base64;
  OUTPUT:
    RETVAL
