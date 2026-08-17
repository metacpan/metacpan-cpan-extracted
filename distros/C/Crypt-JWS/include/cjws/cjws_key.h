#ifndef CJWS_KEY_H
#define CJWS_KEY_H

#include <string.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include "cjws_compat.h"
#include "cjws_digest.h"
#include "cjws_b64.h"

#define CJWS_KTY_RSA 1
#define CJWS_KTY_EC  2
#define CJWS_KTY_OCT 3

typedef struct {
  EVP_PKEY *pkey;            /* RSA/EC; NULL for oct */
  unsigned char *oct;        /* oct (HS*) secret bytes; NULL otherwise */
  STRLEN octlen;
  int kty;                   /* CJWS_KTY_* */
  int curve_bits;            /* EC only: 256/384/521 */
  int is_private;
} cjws_key;

static void cjws_key_free(cjws_key *k) {
  if (!k) return;
  EVP_PKEY_free(k->pkey);
  if (k->oct) {
    OPENSSL_cleanse(k->oct, k->octlen);
    OPENSSL_free(k->oct);
  }
  OPENSSL_free(k);
}

/* Not OPENSSL_zalloc: LibreSSL (OpenBSD base) has no such symbol, and the
 * implicit declaration only bites at dlopen time as an undefined symbol. */
static cjws_key *cjws_key_alloc(void) {
  cjws_key *k = (cjws_key *)OPENSSL_malloc(sizeof *k);
  if (k) memset(k, 0, sizeof *k);
  return k;
}

/* Fill kty/curve_bits/is_private from a freshly adopted EVP_PKEY.
 * Returns 0 (and does not adopt) for unsupported key types. */
static int cjws_key_classify(cjws_key *k, EVP_PKEY *pkey, int is_private) {
  int base = EVP_PKEY_base_id(pkey);
  if (base == EVP_PKEY_RSA) {
    k->kty = CJWS_KTY_RSA;
  }
  else if (base == EVP_PKEY_EC) {
    BIGNUM *x = NULL, *y = NULL;
    int bits = 0;
    k->kty = CJWS_KTY_EC;
    if (!cjws_pkey_get_ec(pkey, &bits, &x, &y)) return 0;
    BN_free(x); BN_free(y);
    k->curve_bits = bits;
  }
  else {
    return 0;
  }
  k->pkey = pkey;
  k->is_private = is_private;
  return 1;
}

/* ---- PEM ------------------------------------------------------------- */

static cjws_key *cjws_key_from_pem(const char *pem, STRLEN len) {
  BIO *bio = BIO_new_mem_buf(pem, (int)len);
  EVP_PKEY *pkey = NULL;
  cjws_key *k = NULL;
  int is_private = 0;
  if (!bio) return NULL;
  pkey = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
  if (pkey) {
    is_private = 1;
  }
  else {
    BIO_free(bio);
    bio = BIO_new_mem_buf(pem, (int)len);
    if (!bio) return NULL;
    pkey = PEM_read_bio_PUBKEY(bio, NULL, NULL, NULL);
  }
  BIO_free(bio);
  if (!pkey) return NULL;
  k = cjws_key_alloc();
  if (!k || !cjws_key_classify(k, pkey, is_private)) {
    EVP_PKEY_free(pkey);
    OPENSSL_free(k);
    return NULL;
  }
  return k;
}

/* Returned PEM is written into a fresh SV by the XS layer; here we hand
 * back an OPENSSL_malloc'd buffer + length. Private keys export as
 * unencrypted PKCS8, public as SPKI. */
static unsigned char *cjws_key_to_pem(cjws_key *k, int want_private,
                                      STRLEN *outlen) {
  BIO *bio;
  unsigned char *out = NULL;
  char *pdata;
  long plen;
  *outlen = 0;
  if (!k->pkey) return NULL;                 /* oct keys have no PEM form */
  if (want_private && !k->is_private) return NULL;
  bio = BIO_new(BIO_s_mem());
  if (!bio) return NULL;
  if (want_private
      ? PEM_write_bio_PKCS8PrivateKey(bio, k->pkey, NULL, NULL, 0, NULL, NULL) != 1
      : PEM_write_bio_PUBKEY(bio, k->pkey) != 1) {
    BIO_free(bio);
    return NULL;
  }
  plen = BIO_get_mem_data(bio, &pdata);
  if (plen > 0) {
    out = (unsigned char *)OPENSSL_malloc((size_t)plen);
    if (out) {
      memcpy(out, pdata, (size_t)plen);
      *outlen = (STRLEN)plen;
    }
  }
  BIO_free(bio);
  return out;
}

/* ---- JWK params ------------------------------------------------------ */

/* b64url-decoded big-endian byte strings in, key out. d may be NULL. */
static cjws_key *cjws_key_from_rsa_params(const unsigned char *n, STRLEN nl,
                                          const unsigned char *e, STRLEN el,
                                          const unsigned char *d, STRLEN dl) {
  BIGNUM *bn = BN_bin2bn(n, (int)nl, NULL);
  BIGNUM *be = BN_bin2bn(e, (int)el, NULL);
  BIGNUM *bd = d ? BN_bin2bn(d, (int)dl, NULL) : NULL;
  EVP_PKEY *pkey = NULL;
  cjws_key *k = NULL;
  if (bn && be && (!d || bd))
    pkey = cjws_pkey_from_rsa(bn, be, bd);
  BN_clear_free(bd);
  BN_free(bn);
  BN_free(be);
  if (!pkey) return NULL;
  k = cjws_key_alloc();
  if (!k || !cjws_key_classify(k, pkey, d ? 1 : 0)) {
    EVP_PKEY_free(pkey);
    OPENSSL_free(k);
    return NULL;
  }
  return k;
}

static cjws_key *cjws_key_from_ec_params(int bits,
                                         const unsigned char *x, STRLEN xl,
                                         const unsigned char *y, STRLEN yl,
                                         const unsigned char *d, STRLEN dl) {
  BIGNUM *bx = BN_bin2bn(x, (int)xl, NULL);
  BIGNUM *by = BN_bin2bn(y, (int)yl, NULL);
  BIGNUM *bd = d ? BN_bin2bn(d, (int)dl, NULL) : NULL;
  EVP_PKEY *pkey = NULL;
  cjws_key *k = NULL;
  if (bx && by && (!d || bd))
    pkey = cjws_pkey_from_ec(bits, bx, by, bd);
  BN_clear_free(bd);
  BN_free(bx);
  BN_free(by);
  if (!pkey) return NULL;
  k = cjws_key_alloc();
  if (!k || !cjws_key_classify(k, pkey, d ? 1 : 0)) {
    EVP_PKEY_free(pkey);
    OPENSSL_free(k);
    return NULL;
  }
  k->curve_bits = bits;
  return k;
}

static cjws_key *cjws_key_from_oct(const unsigned char *secret, STRLEN len) {
  cjws_key *k = cjws_key_alloc();
  if (!k) return NULL;
  k->oct = (unsigned char *)OPENSSL_malloc(len ? len : 1);
  if (!k->oct) {
    OPENSSL_free(k);
    return NULL;
  }
  memcpy(k->oct, secret, len);
  k->octlen = len;
  k->kty = CJWS_KTY_OCT;
  k->is_private = 1;
  return k;
}

/* ---- generation ------------------------------------------------------ */

static cjws_key *cjws_key_generate_rsa(int bits) {
  EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_RSA, NULL);
  EVP_PKEY *pkey = NULL;
  cjws_key *k = NULL;
  if (!ctx) return NULL;
  if (EVP_PKEY_keygen_init(ctx) != 1
      || EVP_PKEY_CTX_set_rsa_keygen_bits(ctx, bits) != 1
      || EVP_PKEY_keygen(ctx, &pkey) != 1) {
    EVP_PKEY_CTX_free(ctx);
    return NULL;
  }
  EVP_PKEY_CTX_free(ctx);
  k = cjws_key_alloc();
  if (!k || !cjws_key_classify(k, pkey, 1)) {
    EVP_PKEY_free(pkey);
    OPENSSL_free(k);
    return NULL;
  }
  return k;
}

static cjws_key *cjws_key_generate_ec(int curve_bits) {
  int nid = cjws_curve_nid(curve_bits);
  EVP_PKEY_CTX *ctx;
  EVP_PKEY *pkey = NULL;
  cjws_key *k = NULL;
  if (nid == NID_undef) return NULL;
  ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
  if (!ctx) return NULL;
  if (EVP_PKEY_keygen_init(ctx) != 1
      || EVP_PKEY_CTX_set_ec_paramgen_curve_nid(ctx, nid) != 1
      || EVP_PKEY_keygen(ctx, &pkey) != 1) {
    EVP_PKEY_CTX_free(ctx);
    return NULL;
  }
  EVP_PKEY_CTX_free(ctx);
  k = cjws_key_alloc();
  if (!k || !cjws_key_classify(k, pkey, 1)) {
    EVP_PKEY_free(pkey);
    OPENSSL_free(k);
    return NULL;
  }
  k->curve_bits = curve_bits;
  return k;
}

/* ---- RFC 7638 thumbprint --------------------------------------------- */

/* sha256 over the canonical JSON of the required public members, in
 * lexicographic key order. Every value is b64url (JSON-safe, no
 * escaping). out must hold 32 bytes; returns 1 on success. */
static int cjws_key_thumbprint(cjws_key *k, unsigned char *out) {
  unsigned char *json = NULL;
  STRLEN jlen = 0;
  int ok = 0;

  if (k->kty == CJWS_KTY_RSA) {
    BIGNUM *n = NULL, *e = NULL;
    if (!cjws_pkey_get_rsa(k->pkey, &n, &e)) return 0;
    {
      int nlen = BN_num_bytes(n), elen = BN_num_bytes(e);
      unsigned char *nb = (unsigned char *)OPENSSL_malloc((size_t)(nlen ? nlen : 1));
      unsigned char *eb = (unsigned char *)OPENSSL_malloc((size_t)(elen ? elen : 1));
      if (nb && eb) {
        STRLEN maxj;
        BN_bn2bin(n, nb);
        BN_bn2bin(e, eb);
        maxj = cjws_b64url_encoded_len((STRLEN)nlen)
             + cjws_b64url_encoded_len((STRLEN)elen) + 64;
        json = (unsigned char *)OPENSSL_malloc(maxj);
        if (json) {
          STRLEN o = 0;
          memcpy(json + o, "{\"e\":\"", 6); o += 6;
          o += cjws_b64url_encode((char *)json + o, eb, (STRLEN)elen);
          memcpy(json + o, "\",\"kty\":\"RSA\",\"n\":\"", 19); o += 19;
          o += cjws_b64url_encode((char *)json + o, nb, (STRLEN)nlen);
          memcpy(json + o, "\"}", 2); o += 2;
          jlen = o;
        }
      }
      OPENSSL_free(nb);
      OPENSSL_free(eb);
    }
    BN_free(n);
    BN_free(e);
  }
  else if (k->kty == CJWS_KTY_EC) {
    BIGNUM *x = NULL, *y = NULL;
    int bits = 0;
    if (!cjws_pkey_get_ec(k->pkey, &bits, &x, &y)) return 0;
    {
      int clen = cjws_curve_coord_len(bits);
      unsigned char *xb = (unsigned char *)OPENSSL_malloc((size_t)clen);
      unsigned char *yb = (unsigned char *)OPENSSL_malloc((size_t)clen);
      const char *crv = bits == 256 ? "P-256" : bits == 384 ? "P-384" : "P-521";
      if (xb && yb
          && BN_bn2binpad(x, xb, clen) == clen
          && BN_bn2binpad(y, yb, clen) == clen) {
        STRLEN maxj = 2 * cjws_b64url_encoded_len((STRLEN)clen) + 64;
        json = (unsigned char *)OPENSSL_malloc(maxj);
        if (json) {
          STRLEN o = 0;
          memcpy(json + o, "{\"crv\":\"", 8); o += 8;
          memcpy(json + o, crv, 5); o += 5;
          memcpy(json + o, "\",\"kty\":\"EC\",\"x\":\"", 18); o += 18;
          o += cjws_b64url_encode((char *)json + o, xb, (STRLEN)clen);
          memcpy(json + o, "\",\"y\":\"", 7); o += 7;
          o += cjws_b64url_encode((char *)json + o, yb, (STRLEN)clen);
          memcpy(json + o, "\"}", 2); o += 2;
          jlen = o;
        }
      }
      OPENSSL_free(xb);
      OPENSSL_free(yb);
    }
    BN_free(x);
    BN_free(y);
  }
  else if (k->kty == CJWS_KTY_OCT) {
    STRLEN maxj = cjws_b64url_encoded_len(k->octlen) + 32;
    json = (unsigned char *)OPENSSL_malloc(maxj);
    if (json) {
      STRLEN o = 0;
      memcpy(json + o, "{\"k\":\"", 6); o += 6;
      o += cjws_b64url_encode((char *)json + o, k->oct, k->octlen);
      memcpy(json + o, "\",\"kty\":\"oct\"}", 14); o += 14;
      jlen = o;
    }
  }

  if (json && jlen) {
    ok = cjws_digest(256, json, jlen, out) == 32;
    OPENSSL_cleanse(json, jlen);
  }
  OPENSSL_free(json);
  return ok;
}

#endif
