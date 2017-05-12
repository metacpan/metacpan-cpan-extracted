#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perlmulticore.h"

#include "spritz/spritz.c"

typedef spritz_state *Crypt__Spritz;
#if 0
typedef spritz_state *Crypt__Spritz__CIPHER;
typedef spritz_state *Crypt__Spritz__CIPHER__XOR;
typedef spritz_state *Crypt__Spritz__HASH;
typedef spritz_state *Crypt__Spritz__MAC;
typedef spritz_state *Crypt__Spritz__AEAD;
typedef spritz_state *Crypt__Spritz__AEAD__XOR;
#endif

static SV *
alloc_pv (STRLEN len)
{
  SV *r = newSV (len);

  sv_upgrade (r, SVt_PV);
  SvCUR_set (r, len);
  SvPOK_only (r);
  *SvEND (r) = 0;

  return r;
}

static SV *
alloc_state (SV *klass)
{
  SV *r = alloc_pv (sizeof (spritz_state));

  return sv_bless (newRV_noinc (r), gv_stashsv (klass, GV_ADD));
}

static spritz_state *
get_state (SV *sv)
{
  if (!sv_derived_from (sv, "Crypt::Spritz::Base"))
    croak ("object is not of type Crypt::Spritz::Base");

  sv = SvRV (sv);

  /* this can happen when the objhetc is serialised, which isn't officially supported */
  if (SvUTF8 (sv))
    sv_utf8_downgrade (sv, 0);

  return (spritz_state *)SvPVX (sv);
}

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::Base

SV *
clone (SV *self)
	CODE:
        /* no type check... too bad */
        self = SvRV (self);
	RETVAL = sv_bless (newRV_noinc (newSVsv (self)), SvSTASH (self));
	OUTPUT:
	RETVAL

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz		PREFIX = spritz_

PROTOTYPES: ENABLE

SV *
new (SV *klass)
	CODE:
        RETVAL = alloc_state (klass);
        spritz_init ((spritz_state *)SvPVX (SvRV (RETVAL)));
	OUTPUT:
        RETVAL

void spritz_init (Crypt::Spritz self)

void spritz_update (Crypt::Spritz self)

void spritz_whip (Crypt::Spritz self, UV r)

void spritz_crush (Crypt::Spritz self)

void spritz_shuffle (Crypt::Spritz self)

void spritz_absorb_stop (Crypt::Spritz self)

void spritz_absorb (Crypt::Spritz self, SV *data)
	ALIAS:
        absorb_and_stop = 1
	CODE:
{
        STRLEN len; char *ptr = SvPVbyte (data, len);

        if (len > 400) perlinterp_release ();

        spritz_absorb (self, ptr, len);

        if (ix)
	  spritz_absorb_stop (self);

        if (len > 400) perlinterp_acquire ();
}

U8 spritz_output (Crypt::Spritz self)

U8 spritz_drip (Crypt::Spritz self)

SV *
spritz_squeeze (Crypt::Spritz self, STRLEN len)
	CODE:
        RETVAL = alloc_pv (len);
        spritz_squeeze (self, SvPVX (RETVAL), len);
	OUTPUT:
        RETVAL

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::Cipher			PREFIX = spritz_cipher_xor_

SV *
new (SV *klass, SV *K, SV *IV = 0)
	CODE:
{
	STRLEN k_len     ; char *k  =      SvPVbyte (K , k_len );
	STRLEN iv_len = 0; char *iv = IV ? SvPVbyte (IV, iv_len) : 0;
        RETVAL = alloc_state (klass);
        spritz_cipher_xor_init ((spritz_state *)SvPVX (SvRV (RETVAL)), k, k_len, iv, iv_len);
}
	OUTPUT:
        RETVAL

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::Cipher		PREFIX = spritz_cipher_

SV *
encrypt (Crypt::Spritz self, SV *I)
	ALIAS:
        encrypt                           = 0
        decrypt                           = 1
        Crypt::Spritz::Cipher::XOR::crypt = 2
        Crypt::Spritz::AEAD::encrypt      = 3
        Crypt::Spritz::AEAD::decrypt      = 4
        Crypt::Spritz::AEAD::XOR::crypt   = 5
	CODE:
        static void (*f[])(spritz_state *s, const void *I, void *O, size_t len) = {
          spritz_cipher_encrypt,
          spritz_cipher_decrypt,
          spritz_cipher_xor_crypt,
          spritz_aead_encrypt,
          spritz_aead_decrypt,
          spritz_aead_xor_crypt
        };
{
	STRLEN len; char *ptr = SvPVbyte (I, len);
        char *retval;
        STRLEN slow_len = ix < 3 ? 4000 : 400;
        RETVAL = alloc_pv (len);
        retval = SvPVX (RETVAL);
        if (len > slow_len) perlinterp_release ();
        f[ix](self, ptr, retval, len);
        if (len > slow_len) perlinterp_acquire ();
}
	OUTPUT:
        RETVAL

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::Cipher::XOR		PREFIX = spritz_cipher_xor_

# crypt == Spritz::Cipher::crypt (xs-alias)

void
crypt_inplace (Crypt::Spritz self, SV *I)
	CODE:
	sv_force_normal (I);
{
	STRLEN len; char *ptr = SvPVbyte (I, len);
        if (len > 4000) perlinterp_release ();
        spritz_cipher_xor_crypt (self, ptr, ptr, len);
        if (len > 4000) perlinterp_acquire ();
}

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::Hash	PREFIX = spritz_hash_

# new == Spritz::new (inherit)
# add == absorb (alias)

SV *
spritz_hash_finish (Crypt::Spritz self, STRLEN len)
	CODE:
        char *retval;
        RETVAL = alloc_pv (len);
        spritz_hash_finish (self, SvPVX (RETVAL), len);
	OUTPUT:
        RETVAL

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::MAC	PREFIX = spritz_mac_

SV *
new (SV *klass, SV *K)
	CODE:
{
	STRLEN len; char *ptr = SvPVbyte (K, len);
        RETVAL = alloc_state (klass);
        spritz_mac_init ((spritz_state *)SvPVX (SvRV (RETVAL)), ptr, len);
}
	OUTPUT:
        RETVAL

# add    == Spritz::HASH::add    (inherit)
# finish == Spritz::HASH::finish (inherit)

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::AEAD		PREFIX = spritz_aead_

# new             == Spritz::MAC::new      (inherit)
# nonce           == absorb_and_stop       (alias)
# associated_data == absorb_and_stop       (alias)
# encrypt         == Spritz::Cipher::crypt (xs-alias)
# decrypt         == Spritz::Cipher::crypt (xs-alias)
# finish          == Spritz::MAC::finish   (alias)

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::AEAD::XOR	PREFIX = spritz_aead_xor_

# new             == Spritz::MAC::new               (inherit)
# nonce           == Spritz::AEAD::nonce            (inherit)
# associated_data == Spritz::AEAD::associated_data  (inherit)
# crypt           == Spritz::Cipher::crypt          (xs-alias)
# finish          == Spritz::AEAD::finish           (inherit)

void
crypt_inplace (Crypt::Spritz self, SV *I)
	CODE:
	sv_force_normal (I);
{
	STRLEN len; char *ptr = SvPVbyte (I, len);
        if (len > 400) perlinterp_release ();
        spritz_aead_xor_crypt (self, ptr, ptr, len);
        if (len > 400) perlinterp_acquire ();
}

MODULE = Crypt::Spritz		PACKAGE = Crypt::Spritz::PRNG	PREFIX = spritz_prng_

SV *
new (SV *klass, SV *S = 0)
	CODE:
{
	STRLEN len = 0; char *ptr = S ? SvPVbyte (S, len) : 0;
        RETVAL = alloc_state (klass);
        spritz_prng_init ((spritz_state *)SvPVX (SvRV (RETVAL)), ptr, len);
}
	OUTPUT:
        RETVAL

# add == absorb  (alias)
# get == squeeze (alias)

