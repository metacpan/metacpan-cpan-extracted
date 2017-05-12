/*
* CAST5.xs
* Perl bindings for CAST5 cipher
*
* Copyright 2002-2004 by Bob Mathews
*
* This library is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "cast5.h"

#ifndef SvPVbyte
#define SvPVbyte SvPV
#endif

static void cast5_init_sv(Crypt__CAST5 cast5, SV *key)
{
  STRLEN keylen;
  char *keystr;

  keystr = SvPVbyte(key, keylen);
  if (keylen < 5 || keylen > 16) croak("Key must be 40 to 128 bits");

  cast5_init(cast5, keystr, keylen);
} /* cast5_init_sv */

MODULE = Crypt::CAST5		PACKAGE = Crypt::CAST5		

PROTOTYPES: DISABLE

Crypt::CAST5
new(class, key=NULL)
    SV *  class
    SV *  key
  CODE:
    New(0, RETVAL, 1, struct cast5_state);
    if (key) cast5_init_sv(RETVAL, key);
    else RETVAL->rounds = 0;
  OUTPUT:
    RETVAL

int
blocksize(...)
  CODE:
    RETVAL = 8;
  OUTPUT:
    RETVAL

int
keysize(...)
  CODE:
    RETVAL = 16;
  OUTPUT:
    RETVAL

void
init(cast5, key)
    Crypt::CAST5  cast5
    SV *          key
  CODE:
    cast5_init_sv(cast5, key);

SV *
encrypt(cast5, plaintext)
    Crypt::CAST5  cast5
    SV *          plaintext
  PREINIT:
    char *str;
    STRLEN len;
  CODE:
    if (cast5->rounds == 0) croak("Call init() first");
    str = SvPVbyte(plaintext, len);
    if (len != 8) croak("Block size must be 8");
    RETVAL = NEWSV(0, 8);
    SvPOK_only(RETVAL);
    SvCUR_set(RETVAL, 8);
    cast5_encrypt(cast5, str, SvPV(RETVAL, len));
  OUTPUT:
    RETVAL

SV *
decrypt(cast5, ciphertext)
    Crypt::CAST5  cast5
    SV *          ciphertext
  PREINIT:
    char *str;
    STRLEN len;
  CODE:
    if (cast5->rounds == 0) croak("Call init() first");
    str = SvPVbyte(ciphertext, len);
    if (len != 8) croak("Block size must be 8");
    RETVAL = NEWSV(0, 8);
    SvPOK_only(RETVAL);
    SvCUR_set(RETVAL, 8);
    cast5_decrypt(cast5, str, SvPV(RETVAL, len));
  OUTPUT:
    RETVAL

void
DESTROY(cast5)
    Crypt::CAST5  cast5
  CODE:
    Zero(cast5, 1, struct cast5_state);
    Safefree(cast5);

