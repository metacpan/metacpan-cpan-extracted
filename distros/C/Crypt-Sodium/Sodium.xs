#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "string.h"
#include "sodium.h"

MODULE = Crypt::Sodium      PACKAGE = Crypt::Sodium     

PROTOTYPES: ENABLE

SV *
crypto_stream_NONCEBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_stream_NONCEBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_stream_KEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_stream_KEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_box_NONCEBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_box_NONCEBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_box_PUBLICKEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_box_PUBLICKEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_box_SECRETKEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_box_SECRETKEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_box_SEEDBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_box_SEEDBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_sign_BYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_sign_BYTES);

    OUTPUT:
        RETVAL

SV *
crypto_sign_PUBLICKEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_sign_PUBLICKEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_secretbox_MACBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_secretbox_MACBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_secretbox_KEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_secretbox_KEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_secretbox_NONCEBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_secretbox_NONCEBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_box_MACBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_box_MACBYTES);

    OUTPUT:
        RETVAL


SV *
crypto_sign_SECRETKEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_sign_SECRETKEYBYTES);

    OUTPUT:
        RETVAL

SV *
crypto_pwhash_SALTBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_SALTBYTES);

    OUTPUT:
        RETVAL      

SV *
crypto_pwhash_OPSLIMIT()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE);

    OUTPUT:
        RETVAL      

SV *
crypto_pwhash_OPSLIMIT_SENSITIVE()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE);

    OUTPUT:
        RETVAL

SV *
crypto_pwhash_MEMLIMIT()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE);

    OUTPUT:
        RETVAL    

SV *
crypto_pwhash_MEMLIMIT_SENSITIVE()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE);

    OUTPUT:
        RETVAL    

SV *
crypto_pwhash_STRBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_pwhash_scryptsalsa208sha256_STRBYTES);

    OUTPUT:
        RETVAL    

SV *
crypto_generichash_BYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_BYTES);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_BYTES_MIN()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_BYTES_MIN);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_BYTES_MAX()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_BYTES_MAX);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_KEYBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_KEYBYTES);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_KEYBYTES_MIN()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_KEYBYTES_MIN);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_KEYBYTES_MAX()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_KEYBYTES_MAX);
    OUTPUT:
        RETVAL

SV *
crypto_generichash_statebytes()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_generichash_statebytes());
    OUTPUT:
        RETVAL

SV *
crypto_scalarmult_SCALARBYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_scalarmult_SCALARBYTES);
    OUTPUT:
        RETVAL

SV *
crypto_scalarmult_BYTES()
    CODE:
        RETVAL = newSVuv((unsigned int) crypto_scalarmult_BYTES);
    OUTPUT:
        RETVAL

SV *
real_sodium_init()
    CODE:
        RETVAL = newSViv(sodium_init());
    OUTPUT:
        RETVAL

SV *
randombytes_random()
    CODE:
        uint32_t r_bytes = randombytes_random();
        RETVAL = newSVuv((int) r_bytes);

    OUTPUT:
        RETVAL

SV *
randombytes_uniform(upper_bound)
    unsigned int upper_bound

    CODE:
        uint32_t r_bytes = randombytes_uniform(upper_bound);
        RETVAL = newSVuv((int) r_bytes);

    OUTPUT:
        RETVAL

SV *
randombytes_buf(size)
    unsigned long size

    CODE:
        unsigned char *buf = sodium_malloc(size);
        randombytes_buf(buf, size);
        RETVAL = newSVpvn((const char * const)buf, size);
        sodium_free(buf);
    OUTPUT:
        RETVAL

SV *
real_crypto_scalarmult_base(n)
    unsigned char *n
    
    CODE:
        unsigned char *q = sodium_malloc(crypto_scalarmult_BYTES);
        if (crypto_scalarmult_base(q, n) == 0) {
            RETVAL = newSVpvn((unsigned char *)q, crypto_scalarmult_BYTES);
        } else {
            RETVAL = &PL_sv_undef;
        }
        sodium_free(q);
    OUTPUT:
        RETVAL

SV *
real_crypto_scalarmult(n, p)
    unsigned char *n
    unsigned char *p
    
    CODE:
        unsigned char *q = sodium_malloc(crypto_scalarmult_BYTES);
        if (crypto_scalarmult(q, n, p) == 0) {
            RETVAL = newSVpvn((unsigned char *)q, crypto_scalarmult_BYTES);
        } else {
            RETVAL = &PL_sv_undef;
        }
        sodium_free(q);
    OUTPUT:
        RETVAL

SV *
real_crypto_stream(clen, n, k)
    unsigned long clen
    unsigned char *n
    unsigned char *k

    CODE:
        unsigned char c[clen];
        crypto_stream(c, clen, n, k);
        RETVAL = newSVpvn((unsigned char *)c, clen);

    OUTPUT:
        RETVAL

SV *
real_crypto_stream_xor(m, clen, n, k)
    unsigned char *m
    unsigned long clen
    unsigned char *n
    unsigned char *k

    CODE:
        unsigned char c[clen];
        crypto_stream_xor(c, m, clen, n, k);
        RETVAL = newSVpvn((unsigned char *)c, clen);

    OUTPUT:
        RETVAL

SV *
real_crypto_box_open(c, clen, n, pk, sk)
    unsigned char *c 
    unsigned long clen
    unsigned char *n
    unsigned char *pk
    unsigned char *sk

    CODE:
        unsigned char *m = sodium_malloc(clen - crypto_box_MACBYTES);

        int status = crypto_box_open_easy((unsigned char*)m, (const unsigned char*)c, 
            (unsigned long long) clen, (const unsigned char*)n, (const unsigned char*)pk, (const unsigned char*)sk);

        if (status == 0) {
            RETVAL = newSVpvn( m, clen - crypto_box_MACBYTES );
        } else {
            RETVAL = &PL_sv_undef;
        }
        
        sodium_free(m);

    OUTPUT:
        RETVAL

SV *
real_crypto_box(m, mlen, n, pk, sk)
    unsigned char *m 
    unsigned long mlen
    unsigned char *n
    unsigned char *pk
    unsigned char *sk

    CODE:
        unsigned char *c = sodium_malloc(mlen + crypto_box_MACBYTES);

        int status = crypto_box_easy((unsigned char*)c, (const unsigned char*)m, 
            (unsigned long long) mlen, (const unsigned char*)n, (const unsigned char*)pk, (const unsigned char*)sk);

        if (status == 0) {
            RETVAL = newSVpvn( c, mlen + crypto_box_MACBYTES );
        } else {
            RETVAL = &PL_sv_undef;
        }   
    
        sodium_free(c);

    OUTPUT:
        RETVAL


SV *
real_crypto_secretbox_open(c, clen, n, sk)
    unsigned char *c 
    unsigned long clen
    unsigned char *n
    unsigned char *sk

    CODE:
        unsigned char *m = sodium_malloc(clen - crypto_secretbox_MACBYTES);

        int status = crypto_secretbox_open_easy((unsigned char *)m, (const unsigned char*)c, 
            (unsigned long long) clen, (const unsigned char*)n, (const unsigned char*)sk);

        if (status == 0) {
            RETVAL = newSVpvn( m, clen - crypto_secretbox_MACBYTES );
        } else {
            RETVAL = &PL_sv_undef;
        }
    
        sodium_free(m);

    OUTPUT:
        RETVAL


SV *
real_crypto_secretbox(m, mlen, n, sk)
    unsigned char *m 
    unsigned long mlen
    unsigned char *n
    unsigned char *sk

    CODE:
        unsigned char *c = sodium_malloc(mlen + crypto_secretbox_MACBYTES);

        int status = crypto_secretbox_easy((unsigned char*)c, (const unsigned char*)m, 
            (unsigned long long) mlen, (const unsigned char*)n, (const unsigned char*)sk);

        if (status == 0) {
            RETVAL = newSVpvn( c, mlen + crypto_secretbox_MACBYTES );
        } else {
            RETVAL = &PL_sv_undef;
        }
    
        sodium_free(c);

    OUTPUT:
        RETVAL

SV *
real_crypto_hash(in, inlen)
    unsigned char * in
    unsigned long inlen

    CODE:
        unsigned char out[crypto_hash_BYTES];
        crypto_hash(out, in, (unsigned long long) inlen);

        // returning unsigned char * was truncating the data on NUL bytes, pack it 
        // in to an SV like this:
        RETVAL = newSVpvn(out, crypto_hash_BYTES);
    
    OUTPUT:
        RETVAL

SV *
real_crypto_generichash(in, inlen, outlen, key, keylen)
    unsigned char * in
    unsigned long inlen
    size_t outlen
    unsigned char * key
    size_t keylen

    CODE:
        unsigned char *out = sodium_malloc(crypto_generichash_BYTES_MAX);

        /* always declare failure */
        int result = -1;

        if (keylen == 0) {
            result = crypto_generichash(out, outlen, in, (unsigned long long)inlen, NULL, 0);
        } else {
            result = crypto_generichash(out, outlen, in, (unsigned long long)inlen, key, keylen);
        }

        if (result == 0) {
            RETVAL = newSVpvn(out, outlen);
        } else {
            RETVAL = &PL_sv_undef;
        }

        sodium_free(out);

    OUTPUT:
        RETVAL

TYPEMAP: <<EOT
crypto_generichash_state * T_PTRREF
EOT

crypto_generichash_state *
real_crypto_generichash_init(key, keylen, outlen)
    unsigned char *key
    size_t keylen
    size_t outlen

    CODE:
        crypto_generichash_state *state = sodium_malloc(crypto_generichash_statebytes());

        if (crypto_generichash_init(state, key, keylen, outlen) == 0) {
            RETVAL = state;
        } else {
            sodium_free(state);
            RETVAL = NULL;
        }

    OUTPUT:
        RETVAL

NO_OUTPUT int
real_crypto_generichash_update(state, in, inlen)
    crypto_generichash_state *state
    unsigned char *in
    size_t inlen

    CODE:
        crypto_generichash_update(state, in, inlen);

SV *
real_crypto_generichash_final(state, outlen)
    crypto_generichash_state *state
    size_t outlen

    CODE:
        unsigned char *out = sodium_malloc(outlen);
        if (crypto_generichash_final(state, out, outlen) == 0) {
            RETVAL = newSVpvn(out, outlen);
        } else {
            RETVAL = &PL_sv_undef;
        }
        sodium_free(state);

    OUTPUT:
        RETVAL

AV *
crypto_box_keypair()
    CODE:
        unsigned char pk[crypto_box_PUBLICKEYBYTES];
        unsigned char sk[crypto_box_SECRETKEYBYTES];

        crypto_box_keypair(pk, sk);

        SV* pk_sv = newSVpvn(pk, crypto_box_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn(sk, crypto_box_PUBLICKEYBYTES);

        RETVAL = newAV();

        av_push(RETVAL, pk_sv);
        av_push(RETVAL, sk_sv);

    OUTPUT:
        RETVAL

AV *
crypto_sign_keypair()
    CODE:
        unsigned char pk[crypto_sign_PUBLICKEYBYTES];
        unsigned char sk[crypto_sign_SECRETKEYBYTES];

        crypto_sign_keypair(pk, sk);

        SV* pk_sv = newSVpvn(pk, crypto_sign_PUBLICKEYBYTES);
        SV* sk_sv = newSVpvn(sk, crypto_sign_SECRETKEYBYTES);

        RETVAL = newAV();

        av_push(RETVAL, pk_sv);
        av_push(RETVAL, sk_sv);

    OUTPUT:
        RETVAL

SV *
real_crypto_sign(m, mlen, sk)
    unsigned char * m
    unsigned long mlen
    unsigned char * sk

    CODE:
        unsigned char * sm = sodium_malloc(mlen + crypto_sign_BYTES);
        unsigned long long smlen;
        int status = crypto_sign((unsigned char *)sm, &smlen, (const unsigned char *)m, 
            (unsigned long long)mlen, (const unsigned char *)sk);

        if (status == 0) {
            RETVAL = newSVpvn((unsigned char *)sm, smlen);
        } else {
            RETVAL = &PL_sv_undef;
        }
        
        sodium_free(sm);

    OUTPUT:
        RETVAL

SV *
real_crypto_sign_detached(m, mlen, sk)
    unsigned char * m
    unsigned long mlen
    unsigned char * sk

    CODE:
    unsigned char sig[crypto_sign_BYTES];
    
    unsigned long long siglen;
    int status = crypto_sign_detached(sig, &siglen, (const unsigned char *)m, (unsigned long long)mlen,(const unsigned char *) sk);
    
    if (status == 0) {
        RETVAL = newSVpvn((unsigned char *)sig, crypto_sign_BYTES);
    } else {
        RETVAL = &PL_sv_undef;
    }

    OUTPUT:
        RETVAL

SV *
real_crypto_sign_verify_detached(sig, m, mlen, pk)
    unsigned char * sig
    unsigned char * m
    unsigned long mlen
    unsigned char * pk

    CODE:
    int status = crypto_sign_verify_detached((const unsigned char *)sig, (const unsigned char *)m, (unsigned long long) mlen, (const unsigned char *)pk);

    if (status == 0) {
        RETVAL = newSVuv(1);
    } else {
        RETVAL = &PL_sv_undef;
    }

    OUTPUT:
        RETVAL

SV *
real_crypto_sign_open(sm, smlen, pk)
    unsigned char * sm
    unsigned long smlen
    unsigned char * pk

    CODE:
        unsigned char * m = sodium_malloc(smlen);
        unsigned long long mlen;

        int status = crypto_sign_open((unsigned char *)m, &mlen, (const unsigned char *)sm, 
            (unsigned long long)smlen, (const unsigned char *)pk);

        if (status == 0) {
            RETVAL = newSVpvn((unsigned char *)m, mlen);
        } else {
            RETVAL = &PL_sv_undef;
        }
        
        sodium_free(m);

    OUTPUT:
        RETVAL

SV *
real_crypto_pwhash_scrypt(klen, p, salt, opslimit, memlimit)
    unsigned long klen
    unsigned char *p
    unsigned char *salt
    unsigned long opslimit
    unsigned long memlimit

    CODE:
        unsigned char *k = sodium_malloc(klen);

        int status = crypto_pwhash_scryptsalsa208sha256((unsigned char*)k, klen,
            (unsigned char*)p, strlen(p), (const unsigned char*)salt, opslimit, memlimit);

        if (status == 0) {
            RETVAL = newSVpvn((unsigned char *)k, klen);
        } else {
            RETVAL = &PL_sv_undef;
        }
    
        sodium_free(k);

    OUTPUT:
        RETVAL

SV *
real_crypto_pwhash_scrypt_str(p, salt, opslimit, memlimit)
    unsigned char *p
    unsigned char *salt
    unsigned long opslimit
    unsigned long memlimit

    CODE:
        unsigned char *hp = sodium_malloc(crypto_pwhash_scryptsalsa208sha256_STRBYTES);

        int status = crypto_pwhash_scryptsalsa208sha256_str((unsigned char*)hp, (unsigned char*)p, 
            strlen(p), opslimit, memlimit);

        if (status == 0) {
            RETVAL = newSVpvn((unsigned char *)hp, crypto_pwhash_scryptsalsa208sha256_STRBYTES);
        } else {
            RETVAL = &PL_sv_undef;
        }
    
        sodium_free(hp);

    OUTPUT:
        RETVAL

SV *
real_crypto_pwhash_scrypt_str_verify(hp, p)
    unsigned char *hp
    unsigned char *p

    CODE:
        int status = crypto_pwhash_scryptsalsa208sha256_str_verify((unsigned char*)hp, (unsigned char*)p, 
            strlen(p));

        if (status == 0) {
            RETVAL = newSVuv((unsigned int) 1);
        } else {
            RETVAL = &PL_sv_undef;
        }

    OUTPUT:
        RETVAL
