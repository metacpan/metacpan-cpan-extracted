#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perlmulticore.h"

/* work around unportable mess in fixedint.h */
/* taken from libecb */
#ifdef _WIN32
  typedef   signed char   int8_t;
  typedef unsigned char  uint8_t;
  typedef   signed short  int16_t;
  typedef unsigned short uint16_t;
  typedef   signed int    int32_t;
  typedef unsigned int   uint32_t;
  #if __GNUC__
    typedef   signed long long int64_t;
    typedef unsigned long long uint64_t;
  #else /* _MSC_VER || __BORLANDC__ */
    typedef   signed __int64   int64_t;
    typedef unsigned __int64   uint64_t;
  #endif
  #define UINT64_C(v) v
#else
  #include <inttypes.h>
#endif
#define FIXEDINT_H_INCLUDED
#include "ed25519/src/fixedint.h"

#include "ed25519/src/ed25519.h"

/*#include "ed25519/src/add_scalar.c"*/
#include "ed25519/src/fixedint.h"
#include "ed25519/src/keypair.c"
#include "ed25519/src/key_exchange.c"
#include "ed25519/src/seed.c"
#include "ed25519/src/sha512.c"
#include "ed25519/src/sha512.h"
#include "ed25519/src/sign.c"
#include "ed25519/src/verify.c"

#define select(a,b,c) ed25519_select (a, b, c)
#include "ed25519/src/ge.c"

#include "ed25519/src/fe.c"
#define load_3(x) sc_load_3(x)
#define load_4(x) sc_load_4(x)
#include "ed25519/src/sc.c"

MODULE = Crypt::Ed25519		PACKAGE = Crypt::Ed25519

PROTOTYPES: ENABLE

BOOT:
	perlmulticore_support ();

SV *
eddsa_secret_key ()
	CODE:
{
        unsigned char seed[32];

        perlinterp_release ();
        int err = ed25519_create_seed (seed);
        perlinterp_acquire ();

        if (err)
          croak ("Crypt::Ed25519::eddsa_secret_key: ed25519_create_seed failed");

        RETVAL = newSVpvn (seed, sizeof seed);
}
	OUTPUT:
        RETVAL

void
generate_keypair (SV *secret = 0)
	ALIAS:
        eddsa_public_key = 1
	PPCODE:
{
        STRLEN secret_l; char *secret_p;

        unsigned char seed[32];
        unsigned char public_key[32];
        unsigned char private_key[64];

	if (secret)
          {
            secret_p = SvPVbyte (secret, secret_l);

            if (secret_l != 32)
              croak ("Crypt::Ed25519::eddsa_public_key: secret has wrong length (!= 32)");

            perlinterp_release ();
            ed25519_create_keypair (public_key, private_key, secret_p);
            perlinterp_acquire ();
          }
        else
          {
            perlinterp_release ();

            if (ed25519_create_seed (seed))
              {
                perlinterp_acquire ();
                croak ("Crypt::Ed25519::generate_keypair: ed25519_create_seed failed");
              }

            secret_p = seed;

            ed25519_create_keypair (public_key, private_key, secret_p);

            perlinterp_acquire ();
          }

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVpvn (public_key, sizeof public_key)));

        if (!ix)
          PUSHs (sv_2mortal (newSVpvn (private_key, sizeof private_key)));
}

SV *
sign (SV *message, SV *public_key, SV *private_key)
	ALIAS:
        eddsa_sign = 1
	CODE:
{
	unsigned char hash[64]; /* result of sha512 */
	unsigned char signature[64];

        STRLEN message_l    ; char *message_p     = SvPVbyte (message    , message_l    );
        STRLEN public_key_l ; char *public_key_p  = SvPVbyte (public_key , public_key_l );
        STRLEN private_key_l; char *private_key_p = SvPVbyte (private_key, private_key_l);

        if (public_key_l != 32)
          croak ("Crypt::Ed25519::sign: public key has wrong length (!= 32)");

        if (ix)
          {
            if (private_key_l != 32)
              croak ("Crypt::Ed25519::eddsa_sign: secret key has wrong length (!= 32)");

            sha512 (private_key_p, 32, hash);

            hash[ 0] &= 248;
            hash[31] &= 63;
            hash[31] |= 64;

            private_key_p = hash;
          }
        else
          {
            if (private_key_l != 64)
              croak ("Crypt::Ed25519::sign: private key has wrong length (!= 64)");
          }

        perlinterp_release ();
        ed25519_sign (signature, message_p, message_l, public_key_p, private_key_p);
        perlinterp_acquire ();

        RETVAL = newSVpvn (signature, sizeof signature);
}
	OUTPUT:
        RETVAL

bool
verify (SV *message, SV *public_key, SV *signature)
	ALIAS:
        eddsa_verify       = 0
        verify_croak       = 1
        eddsa_verify_croak = 1
	CODE:
{
        STRLEN signature_l ; char *signature_p  = SvPVbyte (signature , signature_l );
        STRLEN message_l   ; char *message_p    = SvPVbyte (message   , message_l   );
        STRLEN public_key_l; char *public_key_p = SvPVbyte (public_key, public_key_l);

        if (public_key_l != 32)
          croak ("Crypt::Ed25519::verify: public key has wrong length (!= 32)");

        perlinterp_release ();
        RETVAL = ed25519_verify (signature_p, message_p, message_l, public_key_p);
        perlinterp_acquire ();

        if (!RETVAL && ix)
          croak ("Crypt::Ed25519::verify_croak: signature verification failed");
}
	OUTPUT:
        RETVAL

SV *
key_exchange (SV *public_key, SV *private_key)
	CODE:
{
        STRLEN public_key_l ; char *public_key_p  = SvPVbyte (public_key , public_key_l );
        STRLEN private_key_l; char *private_key_p = SvPVbyte (private_key, private_key_l);

        if (public_key_l  != 32)
          croak ("Crypt::Ed25519::key_exchange: public key has wrong length (!= 32)");

        if (private_key_l != 64)
          croak ("Crypt::Ed25519::key_exchange: private key has wrong length (!= 64)");

        unsigned char shared_secret[32];

        perlinterp_release ();
        ed25519_key_exchange (shared_secret, public_key_p, private_key_p);
        perlinterp_acquire ();

        RETVAL = newSVpvn (shared_secret, sizeof shared_secret);
}
        OUTPUT:
        RETVAL

