#ifndef CJWS_JWS_H
#define CJWS_JWS_H

#include <openssl/ecdsa.h>
#include "cjws_key.h"
#include "cjws_digest.h"
#include "cjws_util.h"

/* Raw JWS crypto over signing-input bytes. Compact serialization, header
 * JSON, and the alg allowlist policy live in the Perl layer; this file
 * signs and verifies, and refuses key/alg mismatches. */

#define CJWS_FAM_HS 'H'
#define CJWS_FAM_RS 'R'
#define CJWS_FAM_ES 'E'

/* "RS256" -> ('R', 256). Returns 0 on anything else. */
static int cjws_alg_parse(const char *alg, STRLEN len, char *fam, int *bits) {
  if (len != 5) return 0;
  if (alg[0] == 'H' && alg[1] == 'S') *fam = CJWS_FAM_HS;
  else if (alg[0] == 'R' && alg[1] == 'S') *fam = CJWS_FAM_RS;
  else if (alg[0] == 'E' && alg[1] == 'S') *fam = CJWS_FAM_ES;
  else return 0;
  if (memcmp(alg + 2, "256", 3) == 0) *bits = 256;
  else if (memcmp(alg + 2, "384", 3) == 0) *bits = 384;
  else if (memcmp(alg + 2, "512", 3) == 0) *bits = 512;
  else return 0;
  return 1;
}

/* ES curve for an alg: ES256=P-256, ES384=P-384, ES512=P-521. */
static int cjws_es_curve_bits(int alg_bits) {
  return alg_bits == 512 ? 521 : alg_bits;
}

/* The key/alg cross-check: an HS alg demands an oct key, RS demands RSA,
 * ES demands EC on the exact curve. This is what makes alg-confusion
 * attacks structurally impossible downstream. */
static int cjws_key_matches_alg(const cjws_key *k, char fam, int bits) {
  switch (fam) {
    case CJWS_FAM_HS: return k->kty == CJWS_KTY_OCT;
    case CJWS_FAM_RS: return k->kty == CJWS_KTY_RSA;
    case CJWS_FAM_ES: return k->kty == CJWS_KTY_EC
                          && k->curve_bits == cjws_es_curve_bits(bits);
  }
  return 0;
}

/* DER ECDSA_SIG -> JOSE r||s (each BN_bn2binpad'd to the coordinate
 * length). Returns JOSE length or 0. */
static STRLEN cjws_es_der_to_jose(const unsigned char *der, STRLEN derlen,
                                  int curve_bits, unsigned char *jose) {
  const unsigned char *p = der;
  ECDSA_SIG *sig = d2i_ECDSA_SIG(NULL, &p, (long)derlen);
  const BIGNUM *r, *s;
  int clen = cjws_curve_coord_len(curve_bits);
  if (!sig) return 0;
  ECDSA_SIG_get0(sig, &r, &s);
  if (BN_bn2binpad(r, jose, clen) != clen
      || BN_bn2binpad(s, jose + clen, clen) != clen) {
    ECDSA_SIG_free(sig);
    return 0;
  }
  ECDSA_SIG_free(sig);
  return (STRLEN)(2 * clen);
}

/* JOSE r||s -> DER. dst must hold ~(2*clen + 16). Returns DER length
 * or 0. A JOSE signature whose length is not exactly 2*clen fails here,
 * which is the RFC 7515 length check. */
static STRLEN cjws_es_jose_to_der(const unsigned char *jose, STRLEN joselen,
                                  int curve_bits, unsigned char *dst) {
  int clen = cjws_curve_coord_len(curve_bits);
  ECDSA_SIG *sig;
  BIGNUM *r, *s;
  unsigned char *p = dst;
  int derlen;
  if (joselen != (STRLEN)(2 * clen)) return 0;
  r = BN_bin2bn(jose, clen, NULL);
  s = BN_bin2bn(jose + clen, clen, NULL);
  sig = ECDSA_SIG_new();
  if (!r || !s || !sig || ECDSA_SIG_set0(sig, r, s) != 1) {
    BN_free(r); BN_free(s);
    ECDSA_SIG_free(sig);
    return 0;
  }
  derlen = i2d_ECDSA_SIG(sig, &p);
  ECDSA_SIG_free(sig);
  return derlen > 0 ? (STRLEN)derlen : 0;
}

/* Sign signing-input bytes. out is OPENSSL_malloc'd, caller frees; length
 * in *outlen. Returns NULL on failure (wrong key type, public key for a
 * signing op, OpenSSL error). */
static unsigned char *cjws_sign_raw(pTHX_ cjws_key *k,
                                    const char *alg, STRLEN alglen,
                                    const unsigned char *input, STRLEN inlen,
                                    STRLEN *outlen) {
  char fam;
  int bits;
  unsigned char *out = NULL;
  *outlen = 0;
  if (!cjws_alg_parse(alg, alglen, &fam, &bits)) return NULL;
  if (!cjws_key_matches_alg(k, fam, bits)) return NULL;
  if (!k->is_private) return NULL;

  if (fam == CJWS_FAM_HS) {
    unsigned char mac[EVP_MAX_MD_SIZE];
    STRLEN maclen = cjws_hmac(bits, k->oct, k->octlen, input, inlen, mac);
    if (!maclen) return NULL;
    out = (unsigned char *)OPENSSL_malloc(maclen);
    if (!out) return NULL;
    memcpy(out, mac, maclen);
    *outlen = maclen;
    return out;
  }

  {
    const EVP_MD *md = cjws_md_by_bits(bits);
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    size_t siglen = 0;
    unsigned char *sig = NULL;
    if (!md || !ctx) {
      EVP_MD_CTX_free(ctx);
      return NULL;
    }
    if (EVP_DigestSignInit(ctx, NULL, md, NULL, k->pkey) != 1
        || EVP_DigestSign(ctx, NULL, &siglen, input, inlen) != 1) {
      EVP_MD_CTX_free(ctx);
      return NULL;
    }
    sig = (unsigned char *)OPENSSL_malloc(siglen);
    if (!sig || EVP_DigestSign(ctx, sig, &siglen, input, inlen) != 1) {
      OPENSSL_free(sig);
      EVP_MD_CTX_free(ctx);
      return NULL;
    }
    EVP_MD_CTX_free(ctx);

    if (fam == CJWS_FAM_ES) {
      int curve = cjws_es_curve_bits(bits);
      int clen = cjws_curve_coord_len(curve);
      out = (unsigned char *)OPENSSL_malloc((size_t)(2 * clen));
      if (out) {
        *outlen = cjws_es_der_to_jose(sig, (STRLEN)siglen, curve, out);
        if (!*outlen) {
          OPENSSL_free(out);
          out = NULL;
        }
      }
      OPENSSL_free(sig);
      return out;
    }

    *outlen = (STRLEN)siglen;
    return sig;
  }
}

/* Verify. Returns 1 valid, 0 invalid (any reason - never says why). */
static int cjws_verify_raw(pTHX_ cjws_key *k,
                           const char *alg, STRLEN alglen,
                           const unsigned char *input, STRLEN inlen,
                           const unsigned char *sig, STRLEN siglen) {
  char fam;
  int bits;
  if (!cjws_alg_parse(alg, alglen, &fam, &bits)) return 0;
  if (!cjws_key_matches_alg(k, fam, bits)) return 0;

  if (fam == CJWS_FAM_HS) {
    unsigned char mac[EVP_MAX_MD_SIZE];
    STRLEN maclen = cjws_hmac(bits, k->oct, k->octlen, input, inlen, mac);
    if (!maclen) return 0;
    return cjws_ct_eq(mac, maclen, sig, siglen);
  }

  {
    const EVP_MD *md = cjws_md_by_bits(bits);
    EVP_MD_CTX *ctx;
    unsigned char derbuf[256];
    const unsigned char *use_sig = sig;
    STRLEN use_len = siglen;
    int ok;
    if (!md) return 0;
    if (fam == CJWS_FAM_ES) {
      int curve = cjws_es_curve_bits(bits);
      use_len = cjws_es_jose_to_der(sig, siglen, curve, derbuf);
      if (!use_len) return 0;
      use_sig = derbuf;
    }
    ctx = EVP_MD_CTX_new();
    if (!ctx) return 0;
    ok = EVP_DigestVerifyInit(ctx, NULL, md, NULL, k->pkey) == 1
      && EVP_DigestVerify(ctx, use_sig, use_len, input, inlen) == 1;
    EVP_MD_CTX_free(ctx);
    return ok ? 1 : 0;
  }
}

#endif
