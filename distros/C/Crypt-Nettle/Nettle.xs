/*
 ===========================================================================
 Crypt::Nettle

 Perl interface to the nettle Cryptographic library
 
 Author: Daniel Kahn Gillmor <dkg@fifthhorseman.net>
 
 Copyright © Daniel Kahn Gillmor

 Crypt::Nettle is free software, you may redistribute it and/or modify
 it under the GPL version 2 or later (your choice).  Please see the
 COPYING file for the full text of the GPL.


 Use this software AT YOUR OWN RISK.
 ===========================================================================
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <nettle/nettle-meta.h>
#include <nettle/hmac.h>
#include <nettle/ctr.h>
#include <nettle/cbc.h>
#include <nettle/yarrow.h>
#include <nettle/base16.h>
#include <nettle/rsa.h>
#include <gmp.h>
#include <string.h>

static const char my_name[] = "Crypt::Nettle";
static const char author[] = "Daniel Kahn Gillmor <dkg@fifthhorseman.net>";


enum cnc_cipher_mode {
  CNC_MODE_UNKNOWN,
  CNC_MODE_ECB,
  CNC_MODE_CBC,
  CNC_MODE_CTR
};
struct cnc_cipher_mode_name {
  enum cnc_cipher_mode mode;
  const char * name;
};

const struct cnc_cipher_mode_name cipher_modes_available[] = {
  { CNC_MODE_ECB, "ecb" },
  { CNC_MODE_CBC, "cbc" },
  { CNC_MODE_CTR, "ctr" }
};

STATIC
enum cnc_cipher_mode
_cnc_cipher_mode_lookup(const char* name) {
  int i;
  for (i = 0; i < sizeof(cipher_modes_available)/sizeof(*cipher_modes_available); i++)
    if (0 == strcasecmp(name, cipher_modes_available[i].name))
      return cipher_modes_available[i].mode;
  croak("Crypt::Nettle::Cipher: Bad Cipher Block Mode: %s", name);
  return CNC_MODE_UNKNOWN;
};

STATIC
const char *
_cnc_cipher_mode_name_lookup(enum cnc_cipher_mode mode) {
  int i;
  for (i = 0; i < sizeof(cipher_modes_available)/sizeof(*cipher_modes_available); i++)
    if (mode == cipher_modes_available[i].mode)
      return cipher_modes_available[i].name;

  croak("Crypt::Nettle::Cipher: Bad Cipher Block ID: %d (checked %d)", mode, i);
  return NULL;
}

struct Crypt_Nettle_Hash_s {
  const struct nettle_hash * hashtype;
  int is_hmac;
  void* hash_context;
};
typedef struct Crypt_Nettle_Hash_s *Crypt_Nettle_Hash;

struct Crypt_Nettle_Cipher_s {
  const struct nettle_cipher * ciphertype;
  int is_encrypt;
  enum cnc_cipher_mode mode;
  void* cipher_context;
  void* chain_state;
};
typedef struct Crypt_Nettle_Cipher_s *Crypt_Nettle_Cipher;

struct Crypt_Nettle_RSA_s {
  struct rsa_public_key * public_key;
  struct rsa_private_key * private_key;
};
typedef struct Crypt_Nettle_RSA_s *Crypt_Nettle_RSA;

typedef int(*_cnrsa_sign_func)(const struct rsa_private_key*, void*, mpz_t);
typedef int(*_cnrsa_verify_func)(const struct rsa_public_key*, void*, const mpz_t);

struct cnrsa_hash {
   const struct nettle_hash * hash;
   _cnrsa_sign_func sign;
   int (*sign_digest)(const struct rsa_private_key*, const uint8_t*, mpz_t);
   _cnrsa_verify_func verify;
   int (*verify_digest)(const struct rsa_public_key*, const uint8_t*, const mpz_t);
};

const struct cnrsa_hash 
_cnrsa_hashes_available[] = {
  { &nettle_md5, (_cnrsa_sign_func)rsa_md5_sign, rsa_md5_sign_digest, (_cnrsa_verify_func)rsa_md5_verify, rsa_md5_verify_digest },
  { &nettle_sha1, (_cnrsa_sign_func)rsa_sha1_sign, rsa_sha1_sign_digest, (_cnrsa_verify_func)rsa_sha1_verify, rsa_sha1_verify_digest },
  { &nettle_sha256, (_cnrsa_sign_func)rsa_sha256_sign, rsa_sha256_sign_digest, (_cnrsa_verify_func)rsa_sha256_verify, rsa_sha256_verify_digest },
  { &nettle_sha512, (_cnrsa_sign_func)rsa_sha512_sign, rsa_sha512_sign_digest, (_cnrsa_verify_func)rsa_sha512_verify, rsa_sha512_verify_digest }
};

STATIC
const struct cnrsa_hash *
_cnrsa_hash_lookup(const char* name) {
  int i;
  for (i = 0; i < sizeof(_cnrsa_hashes_available)/sizeof(*_cnrsa_hashes_available); i++)
    if (0 == strcasecmp(name, _cnrsa_hashes_available[i].hash->name))
      return _cnrsa_hashes_available+i;
  croak("Crypt::Nettle::RSA: Bad Digest: %s", name);
  return NULL;
};

STATIC
const struct cnrsa_hash *
_cnrsa_hash_lookup_by_hash(const struct nettle_hash * hash) {
  int i;
  if (NULL == hash)
     croak("Crypt::Nettle::RSA: Bad (NULL) Digest");
  for (i = 0; i < sizeof(_cnrsa_hashes_available)/sizeof(*_cnrsa_hashes_available); i++)
    if (hash == _cnrsa_hashes_available[i].hash)
      return _cnrsa_hashes_available+i;
  croak("Crypt::Nettle::RSA: Bad Digest: %s", hash->name);
  return NULL;
};

struct Crypt_Nettle_Yarrow_s {
  struct yarrow256_ctx  yarrow_ctx;
  /* FIXME: include sources here? */
};
typedef struct Crypt_Nettle_Yarrow_s *Crypt_Nettle_Yarrow;

STATIC
Crypt_Nettle_Hash
dereference_cnh(SV* sv_cnh) {
    if (!sv_derived_from(sv_cnh, "Crypt::Nettle::Hash"))
        croak("Not a Crypt::Nettle::Hash object");
    IV tmp = SvIV((SV*)SvRV(sv_cnh));
    return INT2PTR(Crypt_Nettle_Hash, tmp);
}

STATIC
Crypt_Nettle_Cipher
dereference_cnc(SV* sv_cnc) {
    if (!sv_derived_from(sv_cnc, "Crypt::Nettle::Cipher"))
        croak("Not a Crypt::Nettle::Cipher object");
    IV tmp = SvIV((SV*)SvRV(sv_cnc));
    return INT2PTR(Crypt_Nettle_Cipher, tmp);
}

STATIC
Crypt_Nettle_Yarrow
dereference_cny(SV* sv_cny) {
    if (!sv_derived_from(sv_cny, "Crypt::Nettle::Yarrow"))
        croak("Not a Crypt::Nettle::Yarrow object");
    IV tmp = SvIV((SV*)SvRV(sv_cny));
    return INT2PTR(Crypt_Nettle_Yarrow, tmp);
}

STATIC
Crypt_Nettle_RSA
dereference_cnrsa(SV* sv_cnrsa) {
    if (!sv_derived_from(sv_cnrsa, "Crypt::Nettle::RSA"))
        croak("Not a Crypt::Nettle::RSA object");
    IV tmp = SvIV((SV*)SvRV(sv_cnrsa));
    return INT2PTR(Crypt_Nettle_RSA, tmp);
}

const struct nettle_hash *
hash_algos_available[] = {
  &nettle_md2,
  &nettle_md4,
  &nettle_md5,
  &nettle_sha1,
  &nettle_sha224,
  &nettle_sha256,
  &nettle_sha384,
  &nettle_sha512
};

/* absurd unrolled optimization -- could be written more simply with strcasecmp */
STATIC
const struct nettle_hash*
_cnh_hash_lookup(const char* name) {
  const struct nettle_hash* ret = NULL;
  int suffixpos, suffixend;
  if (name) {
    switch (tolower(name[0])) {
    case 'm':
      if ('d' == tolower(name[1])) {
        suffixpos = ('-' == name[2] ? 3 : 2);
        switch (name[suffixpos]) {
        case '2':
          ret = &nettle_md2;
          break;
        case '4':
          ret = &nettle_md4;
          break;
        case '5':
          ret = &nettle_md5;
          break;
        }
        if (ret && name[suffixpos + 1] != 0)
          ret = NULL;
      }
    break;
  case 's':
    if ('h' == tolower(name[1]) && 'a' == tolower(name[2])) {
      suffixpos = ('-' == name[3] ? 4 : 3);
      suffixend = suffixpos + 3;
      switch (name[suffixpos]) {
      case '1':
        ret = &nettle_sha1;
        suffixend = suffixpos + 1;
        break;
      case '2':
        switch (name[suffixpos + 1]) {
        case '2':
          if ('4' == name[suffixpos + 2])
            ret = &nettle_sha224;
          break;
        case '5':
          if ('6' == name[suffixpos + 2])
            ret = &nettle_sha256;
          break;
        }
        break;
      case '3':
        if ('8' == name[suffixpos + 1] && '4' == name[suffixpos + 2])
          ret = &nettle_sha384;        
        break;
      case '5':
        if ('1' == name[suffixpos + 1] && '2' == name[suffixpos + 2])
          ret = &nettle_sha512;
        break;
      }
      if (ret && name[suffixend] != 0)
        ret = NULL;
      break;
    }
    }
  }
  return ret;
}


const struct nettle_cipher *
cipher_algos_available[] = {
  &nettle_aes128,
  &nettle_aes192,
  &nettle_aes256,
  &nettle_arctwo40,
  &nettle_arctwo64,
  &nettle_arctwo128,
  &nettle_arctwo_gutmann128,
  &nettle_arcfour128,
  &nettle_camellia128,
  &nettle_camellia192,
  &nettle_camellia256,
  &nettle_cast128,
  &nettle_serpent128,
  &nettle_serpent192,
  &nettle_serpent256,
  &nettle_twofish128,
  &nettle_twofish192,
  &nettle_twofish256
};

STATIC
const struct nettle_cipher*
_cnc_cipher_lookup(const char* name) {
  int i;
  if (NULL == name)
    return NULL;
  for (i = 0; i < sizeof(cipher_algos_available)/sizeof(*cipher_algos_available); i++)
    if (0 == strncasecmp(name, cipher_algos_available[i]->name, 20))
      return cipher_algos_available[i];
  return NULL;
}



STATIC
void
_cnc_process(Crypt_Nettle_Cipher cnc, int datalen, const uint8_t * databuf, uint8_t * outbuf) {
  switch(cnc->mode) {
  case CNC_MODE_ECB:
    if (cnc->is_encrypt)
      cnc->ciphertype->encrypt(cnc->cipher_context, datalen, outbuf, databuf);
    else
      cnc->ciphertype->decrypt(cnc->cipher_context, datalen, outbuf, databuf);
    break;
  case CNC_MODE_CTR: /* encrypt and decrypt are the same function by definition in CTR mode */
    ctr_crypt(cnc->cipher_context, 
              cnc->ciphertype->encrypt,
              cnc->ciphertype->block_size,
              cnc->chain_state, 
              datalen,
              outbuf,
              databuf);
    break;
  case CNC_MODE_CBC:
    if (cnc->is_encrypt)
      cbc_encrypt(cnc->cipher_context, 
                  cnc->ciphertype->encrypt,
                  cnc->ciphertype->block_size,
                  cnc->chain_state, 
                  datalen,
                  outbuf,
                  databuf);
    else
      cbc_decrypt(cnc->cipher_context, 
                  cnc->ciphertype->encrypt,
                  cnc->ciphertype->block_size,
                  cnc->chain_state, 
                  datalen,
                  outbuf,
                  databuf);
    break;
  }
};


STATIC
void
_cnrsa_wipe(Crypt_Nettle_RSA cnrsa) {
  if (cnrsa->public_key) {
      rsa_public_key_clear(cnrsa->public_key);
      Safefree(cnrsa->public_key);
      cnrsa->public_key = NULL;
  }
  if (cnrsa->private_key) {
     rsa_private_key_clear(cnrsa->private_key);
     Safefree(cnrsa->private_key);
     cnrsa->private_key = NULL;
   }
   Safefree(cnrsa);
   cnrsa = NULL;
}


/* returns 1 if successful, 0 if there was a problem parsing */
STATIC
int
_mpz_setSV(mpz_t dst, SV* src) {
  if (SVt_IV == SvTYPE(src)) {
    mpz_set_ui(dst, SvIV(src));
    return 1;
  } else if (SVt_PV == SvTYPE(src)) {
    return (0 == mpz_set_str(dst, SvPV_nolen(src), 0));
  }
  return 0;
}

STATIC
int
_mpz_setSVraw(mpz_t dst, SV* src) {
  const char* sigdata;
  int siglen;
  char* hexdata;
  int ret;

  if (SVt_PV == SvTYPE(src)) {
    sigdata = SvPV(src, siglen);
    Newx(hexdata, BASE16_ENCODE_LENGTH(siglen) + 1, char);
    hexdata[BASE16_ENCODE_LENGTH(siglen)] = '\0';
    base16_encode_update(hexdata, siglen, sigdata);
    ret = (0 == mpz_set_str(dst, hexdata, 16));
    Safefree(hexdata);
    return ret;
  }
  return _mpz_setSV(dst, src);
}

STATIC
SV *
_newSV_from_mpz(mpz_t src) {
    int sz;
    char* buf;
    SV * ret;
    int offset = 0;

    sz = mpz_sizeinbase(src, 16) + 4;
 /* add two bytes for leading '0x' plus one byte for minus sign (shouldn't ever be set?)
    and for the trailing NULL */
    ret = newSVpv("", sz);
    buf = (char*) SvPV_nolen(ret);
    mpz_get_str(buf + 2, 16, src);
    if (mpz_sgn(src) < 0) {
      offset = 1;
      buf[0] = '-';
    }
    buf[offset] = '0';
    buf[offset + 1] = 'x';
    SvCUR_set(ret, sz - (2 - offset)); /* get rid of the trailing NULL */
    return ret;
}

STATIC
SV *
_newSVraw_from_mpz(mpz_t src) {
    int sz;
    char* buf;
    char* retout;
    SV * ret;
    int offset = 0;
    struct base16_decode_ctx armor;
    unsigned retlen;

    if (mpz_sgn(src) < 0)
       croak("Expected a non-negative value here!");
    sz = mpz_sizeinbase(src, 16);
    if (sz % 2) {
       sz++;
       offset = 1;
    }
    Newxz(buf, sz, char);
    if (offset)
       buf[0] = '0';
    mpz_get_str(buf + offset, 16, src);

    retlen = sz/2;
    ret = newSVpv("", retlen);
    retout = SvPV_nolen(ret);
    base16_decode_init(&armor);
    if (0 == base16_decode_update(&armor, &retlen, retout, sz, buf))
       croak("Failed to decode mpz_t");
    if (retlen != sz/2)
       croak("size of decoded mpz_t was unexpected");
    if (0 == base16_decode_final(&armor))
       croak("Failed to finalize mpz_t decoding");
    Safefree(buf);

    return ret;
}


MODULE = Crypt::Nettle        PACKAGE = Crypt::Nettle::Hash    PREFIX = cnh_

Crypt_Nettle_Hash
cnh_new(classname, algoname)
    const char * classname;
    const char * algoname;
    PREINIT:
        Crypt_Nettle_Hash src;
        const struct nettle_hash* algo;
    CODE:
        if (0 != strcmp("Crypt::Nettle::Hash", classname))
           croak("Crypt::Nettle::Hash->new() was somehow called wrong");
        algo = _cnh_hash_lookup(algoname);
        if (NULL == algo) XSRETURN_UNDEF;
        Newxz(RETVAL, 1, struct Crypt_Nettle_Hash_s);
        if (NULL == RETVAL) XSRETURN_UNDEF;
        RETVAL->hashtype = algo;
        RETVAL->is_hmac = 0;
        Newx(RETVAL->hash_context, algo->context_size, char);
        if (NULL == RETVAL->hash_context) { Safefree(RETVAL); XSRETURN_UNDEF; };
        algo->init(RETVAL->hash_context);
    OUTPUT:
        RETVAL

Crypt_Nettle_Hash
cnh_new_hmac(classname, algoname, key)
    const char * classname;
    const char * algoname;
    SV* key;
    PREINIT:
        Crypt_Nettle_Hash src;
        const struct nettle_hash* algo;
        const uint8_t * keydata;
        int keylen;
    CODE:
        if (0 != strcmp("Crypt::Nettle::Hash", classname))
           croak("Crypt::Nettle::Hash->new_hmac() was somehow called wrong");
        keydata = SvPV(key, keylen);
        algo = _cnh_hash_lookup(algoname);
        if (NULL == algo) XSRETURN_UNDEF;
        Newxz(RETVAL, 1, struct Crypt_Nettle_Hash_s);
        if (NULL == RETVAL) XSRETURN_UNDEF;
        RETVAL->hashtype = algo;
        RETVAL->is_hmac = 1;
        Newx(RETVAL->hash_context, algo->context_size * 3, char); /* ??? will we run into alignment issues? */
        if (NULL == RETVAL->hash_context) { Safefree(RETVAL); XSRETURN_UNDEF; };
        hmac_set_key(RETVAL->hash_context + algo->context_size, 
                     RETVAL->hash_context + algo->context_size*2,
                     RETVAL->hash_context,
                     RETVAL->hashtype,
                     keylen, keydata
                     );
    OUTPUT:
        RETVAL


int
cnh_is_hmac(cnh)
    Crypt_Nettle_Hash cnh;
    CODE:
        RETVAL=cnh->is_hmac;
    OUTPUT:
        RETVAL

Crypt_Nettle_Hash
cnh_copy(cnh)
    Crypt_Nettle_Hash cnh;
    CODE:
        Newxz(RETVAL, 1, struct Crypt_Nettle_Hash_s);
        RETVAL->hashtype = cnh->hashtype;
        Newx(RETVAL->hash_context, RETVAL->hashtype->context_size, char);
        if (NULL == RETVAL->hash_context) { Safefree(RETVAL); XSRETURN_UNDEF; };
        Copy(cnh->hash_context, RETVAL->hash_context, RETVAL->hashtype->context_size, char);
    OUTPUT:
        RETVAL

void
cnh_update(cnh, data)
    Crypt_Nettle_Hash cnh;
    SV* data;
    PREINIT:
        const uint8_t* buf;
        unsigned len;
    PPCODE:
        buf = SvPV(data, len);
        cnh->hashtype->update(cnh->hash_context, len, buf);
        XSRETURN(1);

SV *
cnh_digest(cnh)
    Crypt_Nettle_Hash cnh;
    PREINIT:
        uint8_t* outbuf;
    CODE:
        RETVAL = newSVpv("", cnh->hashtype->digest_size);
        outbuf = (uint8_t*) SvPV_nolen(RETVAL);
        if (cnh->is_hmac)
            hmac_digest(cnh->hash_context + cnh->hashtype->context_size,
                        cnh->hash_context + cnh->hashtype->context_size * 2,
                        cnh->hash_context,
                        cnh->hashtype,
                        cnh->hashtype->digest_size, outbuf);
        else
            cnh->hashtype->digest(cnh->hash_context, cnh->hashtype->digest_size, outbuf);
    OUTPUT:
        RETVAL

const char *
cnh_name(cnh)
    Crypt_Nettle_Hash cnh;
    CODE:
        RETVAL = cnh->hashtype->name;
    OUTPUT:
        RETVAL

int
cnh_digest_size(...)
    PROTOTYPE: @
    PREINIT:
        Crypt_Nettle_Hash cnh;
        const struct nettle_hash* algo;
    CODE:
        if (0 == strcmp(SvPV_nolen(ST(0)), "Crypt::Nettle::Hash")) {
            if (items != 2)
              croak("Crypt::Nettle::Hash->digest_size() needs one argument");
            algo = _cnh_hash_lookup(SvPV_nolen(ST(1)));
        } else {
          if (items != 1)
            croak("Calling digest_size() on a Crypt::Nettle::Hash object needs no additional argument");
          cnh = dereference_cnh(ST(0));
          algo = cnh->hashtype;
        }
        if (NULL == algo) XSRETURN_UNDEF;
        RETVAL = algo->digest_size;
    OUTPUT:
        RETVAL

int
cnh_block_size(...)
    PROTOTYPE: @
    PREINIT:
        Crypt_Nettle_Hash cnh;
        const struct nettle_hash* algo;
    CODE:
        if (0 == strcmp(SvPV_nolen(ST(0)), "Crypt::Nettle::Hash")) {
            if (items != 2)
              croak("Crypt::Nettle::Hash->block_size() needs one argument");
            algo = _cnh_hash_lookup(SvPV_nolen(ST(1)));
        } else {
          if (items != 1)
            croak("Calling block_size() on a Crypt::Nettle::Hash object needs no additional argument");
          cnh = dereference_cnh(ST(0));
          algo = cnh->hashtype;
        }
        if (NULL == algo) XSRETURN_UNDEF;
        RETVAL = algo->block_size;
    OUTPUT:
        RETVAL

void
cnh_algos_available()
    PREINIT:
        int i;
    PPCODE:
        for (i = 0; i < sizeof(hash_algos_available)/sizeof(*hash_algos_available); i++)
          XPUSHs(sv_2mortal(newSVpv(hash_algos_available[i]->name, 0)));

void
cnh_DESTROY(cnh)
    Crypt_Nettle_Hash cnh;
    CODE:
        Safefree(cnh->hash_context);
        Safefree(cnh);
        cnh = NULL;



MODULE = Crypt::Nettle        PACKAGE = Crypt::Nettle::Cipher    PREFIX = cnc_



Crypt_Nettle_Cipher
cnc_new(classname, is_encrypt, algoname, key, mode="ecb", iv=&PL_sv_undef)
    const char * classname;
    SV * is_encrypt;
    const char * algoname;
    SV * key;
    const char * mode;
    SV * iv;
    PREINIT:
        Crypt_Nettle_Cipher src;
        const struct nettle_cipher * algo;
        const char * encstr;
        int keylen;
        const uint8_t * keydata;
        int ivlen;
        const uint8_t * ivdata;
    CODE:
        if (0 != strcmp("Crypt::Nettle::Cipher", classname))
           croak("Crypt::Nettle::Cipher->new() was somehow called wrong");
        algo = _cnc_cipher_lookup(algoname);
        if (NULL == algo) XSRETURN_UNDEF;
        Newxz(RETVAL, 1, struct Crypt_Nettle_Cipher_s);
        if (NULL == RETVAL) XSRETURN_UNDEF;
        RETVAL->ciphertype = algo;
        keydata = SvPV(key, keylen);
        RETVAL->is_encrypt = 1;
        RETVAL->mode = _cnc_cipher_mode_lookup(mode);
        if (RETVAL->mode == CNC_MODE_UNKNOWN) { Safefree(RETVAL); XSRETURN_UNDEF; };
        if (((SVt_IV == SvTYPE(is_encrypt)) && (0 == SvIV(is_encrypt))) ||
            ((SVt_PV == SvTYPE(is_encrypt)) && tolower((SvPV_nolen(is_encrypt))[0]) == 'd'))
          RETVAL->is_encrypt = 0;
        Newx(RETVAL->cipher_context, algo->context_size, char);
        if (NULL == RETVAL->cipher_context) { Safefree(RETVAL); XSRETURN_UNDEF; };
        if (RETVAL->mode == CNC_MODE_ECB) {
          RETVAL->chain_state = NULL;
        } else {
          /* initialize chain_state with IV */
          Newxz(RETVAL->chain_state, algo->block_size, char);
          if (NULL == RETVAL->chain_state) { Safefree(RETVAL->cipher_context); Safefree(RETVAL); XSRETURN_UNDEF; };
          ivdata = SvPV(iv, ivlen);
          Copy(ivdata, RETVAL->chain_state, MIN(ivlen, algo->block_size), char);
        }
        if (RETVAL->is_encrypt) 
            algo->set_encrypt_key(RETVAL->cipher_context, keylen, keydata);
        else
            algo->set_decrypt_key(RETVAL->cipher_context, keylen, keydata);
    OUTPUT:
        RETVAL

const char *
cnc_name(cnc)
    Crypt_Nettle_Cipher cnc;
    CODE:
        RETVAL = cnc->ciphertype->name;
    OUTPUT:
        RETVAL


int
cnc_is_encrypt(cnc)
    Crypt_Nettle_Cipher cnc;
    CODE:
        RETVAL=cnc->is_encrypt;
    OUTPUT:
        RETVAL

const char *
cnc_mode(cnc)
    Crypt_Nettle_Cipher cnc;
    CODE:
        RETVAL=_cnc_cipher_mode_name_lookup(cnc->mode);
    OUTPUT:
        RETVAL


Crypt_Nettle_Cipher
cnc_copy(cnc)
    Crypt_Nettle_Cipher cnc;
    CODE:
        Newxz(RETVAL, 1, struct Crypt_Nettle_Cipher_s);
        RETVAL->ciphertype = cnc->ciphertype;
        Newx(RETVAL->cipher_context, RETVAL->ciphertype->context_size, char);
        if (NULL == RETVAL->cipher_context) { Safefree(RETVAL); XSRETURN_UNDEF; };
        Copy(cnc->cipher_context, RETVAL->cipher_context, RETVAL->ciphertype->context_size, char);
    OUTPUT:
        RETVAL



SV *
cnc_process(cnc, data)
    Crypt_Nettle_Cipher cnc;
    SV * data;
    PREINIT:
        uint8_t* outbuf;
        const uint8_t * databuf;
        int datalen;
    CODE:
        databuf = SvPV(data, datalen);
        RETVAL = newSVpv("", datalen);
        outbuf = (uint8_t*) SvPV_nolen(RETVAL);
        _cnc_process(cnc, datalen, databuf, outbuf);
    OUTPUT:
        RETVAL

void
cnc_process_in_place(cnc, data)
    Crypt_Nettle_Cipher cnc;
    SV * data;
    PREINIT:
        uint8_t * databuf;
        int datalen;
    PPCODE:
        databuf = SvPV(data, datalen);
        _cnc_process(cnc, datalen, databuf, databuf);


int
cnc_key_size(...)
    PROTOTYPE: @
    PREINIT:
        Crypt_Nettle_Cipher cnc;
        const struct nettle_cipher* algo;
    CODE:
        if (0 == strcmp(SvPV_nolen(ST(0)), "Crypt::Nettle::Cipher")) {
            if (items != 2)
              croak("Crypt::Nettle::Cipher->key_size() needs one argument");
            algo = _cnc_cipher_lookup(SvPV_nolen(ST(1)));
        } else {
          if (items != 1)
            croak("Calling key_size() on a Crypt::Nettle::Cipher object needs no additional argument");
          cnc = dereference_cnc(ST(0));
          algo = cnc->ciphertype;
        }
        if (NULL == algo) XSRETURN_UNDEF;
        RETVAL = algo->key_size;
    OUTPUT:
        RETVAL

int
cnc_block_size(...)
    PROTOTYPE: @
    PREINIT:
        Crypt_Nettle_Cipher cnc;
        const struct nettle_cipher* algo;
    CODE:
        if (0 == strcmp(SvPV_nolen(ST(0)), "Crypt::Nettle::Cipher")) {
            if (items != 2)
              croak("Crypt::Nettle::Cipher->block_size() needs one argument");
            algo = _cnc_cipher_lookup(SvPV_nolen(ST(1)));
        } else {
          if (items != 1)
            croak("Calling block_size() on a Crypt::Nettle::Cipher object needs no additional argument");
          cnc = dereference_cnc(ST(0));
          algo = cnc->ciphertype;
        }
        if (NULL == algo) XSRETURN_UNDEF;
        RETVAL = algo->block_size;
    OUTPUT:
        RETVAL

void
cnc_algos_available()
    PREINIT:
        int i;
    PPCODE:
        for (i = 0; i < sizeof(cipher_algos_available)/sizeof(*cipher_algos_available); i++)
          XPUSHs(sv_2mortal(newSVpv(cipher_algos_available[i]->name, 0)));

void
cnc_modes_available()
    PREINIT:
        int i;
    PPCODE:
        for (i = 0; i < sizeof(cipher_modes_available)/sizeof(*cipher_modes_available); i++)
          XPUSHs(sv_2mortal(newSVpv(cipher_modes_available[i].name, 0)));

void
cnc_DESTROY(cnc)
    Crypt_Nettle_Cipher cnc;
    CODE:
        Safefree(cnc->cipher_context);
        Safefree(cnc);
        cnc = NULL;


MODULE = Crypt::Nettle        PACKAGE = Crypt::Nettle::Yarrow    PREFIX = cny_

BOOT:
    {
    HV *stash;
    
    stash = gv_stashpv("Crypt::Nettle::Yarrow", TRUE);
    newCONSTSUB(stash, "SEED_FILE_SIZE", newSViv(YARROW256_SEED_FILE_SIZE));
    }

Crypt_Nettle_Yarrow
cny_new(classname)
    const char * classname;
    CODE:
        if (0 != strcmp("Crypt::Nettle::Yarrow", classname))
            croak("Crypt::Nettle::Yarrow->new() was somehow called wrong");
        Newxz(RETVAL, 1, struct Crypt_Nettle_Yarrow_s);
        yarrow256_init(&RETVAL->yarrow_ctx, 0, NULL);
    OUTPUT:
        RETVAL

void
cny_seed(cny, seed)
    Crypt_Nettle_Yarrow cny;
    SV * seed;
    PREINIT:
        int seedlen;
        const uint8_t * seeddata;
    PPCODE:
        seeddata = SvPV(seed, seedlen);
        yarrow256_seed(&cny->yarrow_ctx, seedlen, seeddata);


SV*
cny_random(cny, len)
    Crypt_Nettle_Yarrow cny;
    int len;
    PREINIT:
        uint8_t * outbuf;
    CODE:
        RETVAL = newSVpv("", len);
        outbuf = SvPV_nolen(RETVAL);
        yarrow256_random(&cny->yarrow_ctx, len, outbuf);
    OUTPUT:
        RETVAL

int
cny_is_seeded(cny)
    Crypt_Nettle_Yarrow cny;
    CODE:
        RETVAL=yarrow256_is_seeded(&cny->yarrow_ctx);
    OUTPUT:
        RETVAL

void
cny_DESTROY(cny)
  Crypt_Nettle_Yarrow cny;
CODE:
{
  Safefree(cny);
  cny = NULL;
}


MODULE = Crypt::Nettle        PACKAGE = Crypt::Nettle::RSA    PREFIX = cnrsa_

void
cnrsa_hashes_available()
    PREINIT:
        int i;
    PPCODE:
        for (i = 0; i < sizeof(_cnrsa_hashes_available)/sizeof(*_cnrsa_hashes_available); i++)
          XPUSHs(sv_2mortal(newSVpv(_cnrsa_hashes_available[i].hash->name, 0)));


Crypt_Nettle_RSA
cnrsa_new_public_key(classname, n, e)
    const char * classname;
    SV * n;
    SV * e;
    CODE:
        if (0 != strcmp("Crypt::Nettle::RSA", classname))
            croak("Crypt::Nettle::RSA->new_public_key() was somehow called wrong");
        Newxz(RETVAL, 1, struct Crypt_Nettle_RSA_s);
        Newxz(RETVAL->public_key, 1, struct rsa_public_key);
        rsa_public_key_init(RETVAL->public_key);
        if (_mpz_setSV(RETVAL->public_key->n, n) &&
            _mpz_setSV(RETVAL->public_key->e, e) &&
            rsa_public_key_prepare(RETVAL->public_key)) {
          /* success setting everything up!  we don't need to do anything */
        } else {
          _cnrsa_wipe(RETVAL); XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

Crypt_Nettle_RSA
cnrsa_new_private_key(classname, d, p, q)
    const char * classname;
    SV * d;
    SV * p;
    SV * q;
    PREINIT:
        mpz_t p1,q1,phi;
    CODE:
        if (0 != strcmp("Crypt::Nettle::RSA", classname))
            croak("Crypt::Nettle::RSA->new_private_key() was somehow called wrong");
        Newxz(RETVAL, 1, struct Crypt_Nettle_RSA_s);
        Newxz(RETVAL->private_key, 1, struct rsa_private_key);
        Newxz(RETVAL->public_key, 1, struct rsa_public_key);
        rsa_private_key_init(RETVAL->private_key);
        rsa_public_key_init(RETVAL->public_key);
        if (_mpz_setSV(RETVAL->private_key->d, d) &&
            _mpz_setSV(RETVAL->private_key->p, p) &&
            _mpz_setSV(RETVAL->private_key->q, q) &&
            mpz_invert(RETVAL->private_key->c, RETVAL->private_key->q, RETVAL->private_key->p) /* c = q^{-1} (mod p) */
           ) {
          /* success setting up the standard parameters!
             now fill in the auxiliary ones: */
          mpz_init(p1); mpz_init(q1); mpz_init(phi);
          mpz_sub_ui(p1, RETVAL->private_key->p, 1);
          mpz_sub_ui(q1, RETVAL->private_key->q, 1);
          mpz_mul(phi, p1, q1);
          /* a = d % (p-1) */
          mpz_fdiv_r(RETVAL->private_key->a, RETVAL->private_key->d, p1);
          /* b = d % (q-1) */
          mpz_fdiv_r(RETVAL->private_key->b, RETVAL->private_key->d, q1);
          mpz_mul(RETVAL->public_key->n, RETVAL->private_key->p, RETVAL->private_key->q);
          mpz_invert(RETVAL->public_key->e, RETVAL->private_key->d, phi);
          mpz_clear(p1); mpz_clear(q1); mpz_clear(phi);
          if (!(rsa_private_key_prepare(RETVAL->private_key) &&
                rsa_public_key_prepare(RETVAL->public_key))) {
            _cnrsa_wipe(RETVAL); XSRETURN_UNDEF;
          }
        } else {
            _cnrsa_wipe(RETVAL); XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


Crypt_Nettle_RSA
cnrsa_generate_keypair(classname, y, n_size, e=65537)
    const char * classname;
    Crypt_Nettle_Yarrow y;
    unsigned n_size;
    unsigned e;
    CODE:
        if (0 != strcmp("Crypt::Nettle::RSA", classname))
            croak("Crypt::Nettle::RSA->new_private_key() was somehow called wrong");
        Newxz(RETVAL, 1, struct Crypt_Nettle_RSA_s);
        Newxz(RETVAL->private_key, 1, struct rsa_private_key);
        rsa_private_key_init(RETVAL->private_key);
        Newxz(RETVAL->public_key, 1, struct rsa_public_key);
        rsa_public_key_init(RETVAL->public_key);
        mpz_set_ui(RETVAL->public_key->e, e);
        if (!rsa_generate_keypair(RETVAL->public_key,
                                  RETVAL->private_key,
                                  &y->yarrow_ctx, /* yarrow the only PRNG we allow at the moment */
                                  (nettle_random_func *) yarrow256_random,
                                  NULL, NULL, /* No progress meters */
                                  n_size, 0)) {
           _cnrsa_wipe(RETVAL); XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

SV *
cnrsa_rsa_sign_hash_context(cnrsa, cnh)
    Crypt_Nettle_RSA cnrsa;
    Crypt_Nettle_Hash cnh;
    PREINIT:
        mpz_t sig;
        const struct cnrsa_hash * hashtype;
        int ret;
    CODE:
        if (NULL == cnrsa->private_key)
           XSRETURN_UNDEF;
        if (cnh->is_hmac)
           XSRETURN_UNDEF;
        hashtype = _cnrsa_hash_lookup_by_hash(cnh->hashtype);
        if (NULL == hashtype)
           XSRETURN_UNDEF;
        mpz_init(sig);
        ret = hashtype->sign(cnrsa->private_key, cnh->hash_context, sig);
        if (0 == ret) {
           mpz_clear(sig);
           XSRETURN_UNDEF;
        }        
        RETVAL = _newSVraw_from_mpz(sig);
        mpz_clear(sig);
OUTPUT:
    RETVAL

SV *
cnrsa_rsa_sign_digest(cnrsa, algo, digest)
    Crypt_Nettle_RSA cnrsa;
    const char * algo;
    SV * digest;
    PREINIT:
        mpz_t sig;
        int ret;
        const struct cnrsa_hash * hashtype;
        int digestlen;
        const char* digestdata;
    CODE:
        if (NULL == cnrsa->private_key)
           XSRETURN_UNDEF;
        hashtype = _cnrsa_hash_lookup(algo);
        if (NULL == hashtype)
           XSRETURN_UNDEF;
        digestdata = SvPV(digest, digestlen);
        if (digestlen != hashtype->hash->digest_size) {
           croak("Digest should have been %d length; was %d", hashtype->hash->digest_size, digestlen); XSRETURN_UNDEF;
        }
        mpz_init(sig);
        ret = hashtype->sign_digest(cnrsa->private_key, digestdata, sig);
        if (0 == ret) {
           mpz_clear(sig);
           XSRETURN_UNDEF;
        }        
        RETVAL = _newSVraw_from_mpz(sig);
        mpz_clear(sig);
OUTPUT:
    RETVAL

int
cnrsa_rsa_verify_hash_context(cnrsa, cnh, signature)
    Crypt_Nettle_RSA cnrsa;
    Crypt_Nettle_Hash cnh;
    SV * signature;
    PREINIT:
        mpz_t sig;
        const struct cnrsa_hash * hashtype;
    CODE:
        if (NULL == cnrsa->public_key)
           XSRETURN_UNDEF;
        if (cnh->is_hmac)
           XSRETURN_UNDEF;
        hashtype = _cnrsa_hash_lookup_by_hash(cnh->hashtype);
        if (NULL == hashtype)
           XSRETURN_UNDEF;
        mpz_init(sig);
        if (!_mpz_setSVraw(sig, signature)) {
           mpz_clear(sig); XSRETURN_UNDEF;
        }
        RETVAL = hashtype->verify(cnrsa->public_key, cnh->hash_context, sig);
        mpz_clear(sig);
OUTPUT:
    RETVAL

int
cnrsa_rsa_verify_digest(cnrsa, algo, digest, signature)
    Crypt_Nettle_RSA cnrsa;
    const char* algo;
    SV * digest;
    SV * signature;
    PREINIT:
        mpz_t sig;
        int digestlen;
        const char* digestdata;
        const struct cnrsa_hash * hashtype;
    CODE:
        if (NULL == cnrsa->public_key)
           XSRETURN_UNDEF;
        hashtype = _cnrsa_hash_lookup(algo);
        if (NULL == hashtype)
           XSRETURN_UNDEF;
        digestdata = SvPV(digest, digestlen);
        if (digestlen != hashtype->hash->digest_size) {
           croak("Digest should have been %d length; was %d", hashtype->hash->digest_size, digestlen); XSRETURN_UNDEF;
        }

        mpz_init(sig);
        if (!_mpz_setSVraw(sig, signature)) {
           mpz_clear(sig); XSRETURN_UNDEF;
        }
        RETVAL = hashtype->verify_digest(cnrsa->public_key, digestdata, sig);
        mpz_clear(sig);
OUTPUT:
    RETVAL



SV *
cnrsa_key_params(cnrsa)
    Crypt_Nettle_RSA cnrsa;
    PREINIT:
        HV * targ;
    CODE:
        targ = (HV *)sv_2mortal((SV *)newHV());
        if (NULL != cnrsa->public_key) {
           if (mpz_sgn(cnrsa->public_key->n)) hv_store(targ, "n", 1, _newSV_from_mpz(cnrsa->public_key->n), 0);
           if (mpz_sgn(cnrsa->public_key->e)) hv_store(targ, "e", 1, _newSV_from_mpz(cnrsa->public_key->e), 0);
        }
        if (NULL != cnrsa->private_key) {
           if (mpz_sgn(cnrsa->private_key->d)) hv_store(targ, "d", 1, _newSV_from_mpz(cnrsa->private_key->d), 0);
           if (mpz_sgn(cnrsa->private_key->p)) hv_store(targ, "p", 1, _newSV_from_mpz(cnrsa->private_key->p), 0);
           if (mpz_sgn(cnrsa->private_key->q)) hv_store(targ, "q", 1, _newSV_from_mpz(cnrsa->private_key->q), 0);
           if (mpz_sgn(cnrsa->private_key->a)) hv_store(targ, "a", 1, _newSV_from_mpz(cnrsa->private_key->a), 0);
           if (mpz_sgn(cnrsa->private_key->b)) hv_store(targ, "b", 1, _newSV_from_mpz(cnrsa->private_key->b), 0);
           if (mpz_sgn(cnrsa->private_key->c)) hv_store(targ, "c", 1, _newSV_from_mpz(cnrsa->private_key->c), 0);
         }
        RETVAL = newRV((SV*)targ);
    OUTPUT:
        RETVAL

void
cnrsa_DESTROY(cnrsa)
    Crypt_Nettle_RSA cnrsa;
    CODE:
        _cnrsa_wipe(cnrsa);
