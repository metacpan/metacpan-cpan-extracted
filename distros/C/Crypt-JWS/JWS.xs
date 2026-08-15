#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "cjws/cjws_b64.h"
#include "cjws/cjws_rand.h"
#include "cjws/cjws_util.h"
#include "cjws/cjws_digest.h"
#include "cjws/cjws_compat.h"
#include "cjws/cjws_key.h"
#include "cjws/cjws_jws.h"
#include "cjws/cjws_compact.h"
#include "jws_abi.h"

/* ---- shared helpers ------------------------------------------------------ */

static cjws_key *cjws_key_of(pTHX_ SV *sv) {
  if (SvROK(sv) && sv_isobject(sv) && sv_derived_from(sv, "Crypt::JWS::Key"))
    return INT2PTR(cjws_key *, SvIV(SvRV(sv)));
  croak("Crypt::JWS: not a Crypt::JWS::Key object");
  return NULL;
}

static SV *cjws_bless_key(pTHX_ cjws_key *k) {
  SV *obj = newSV(0);
  sv_setref_pv(obj, "Crypt::JWS::Key", (void *)k);
  return obj;
}

/* owned SV from bytes */
static SV *cjws_new_bytes_sv(pTHX_ const unsigned char *p, STRLEN n) {
  return newSVpvn((const char *)p, n);
}

/* Fetch a JWK member and b64url-decode it into a mortal SV. Croaks when
 * a required member is missing or undecodable; optional absent -> NULL. */
static SV *cjws_jwk_b64_field(pTHX_ HV *hv, const char *name, int required) {
  SV **v = hv_fetch(hv, name, (I32)strlen(name), 0);
  SV *out;
  STRLEN len;
  const char *p;
  if (!v || !*v || !SvOK(*v)) {
    if (required)
      croak("Crypt::JWS::Key: JWK is missing '%s'", name);
    return NULL;
  }
  p = SvPV_const(*v, len);
  out = cjws_b64url_decode_sv(aTHX_ p, len);
  if (!out)
    croak("Crypt::JWS::Key: JWK member '%s' is not base64url", name);
  return sv_2mortal(out);
}

static int cjws_jwk_curve_bits(pTHX_ HV *hv) {
  SV **v = hv_fetchs(hv, "crv", 0);
  STRLEN len;
  const char *crv = (v && *v && SvOK(*v)) ? SvPV_const(*v, len) : NULL;
  if (crv && len == 5) {
    if (memEQ(crv, "P-256", 5)) return 256;
    if (memEQ(crv, "P-384", 5)) return 384;
    if (memEQ(crv, "P-521", 5)) return 521;
  }
  croak("Crypt::JWS::Key: unsupported EC curve '%s'", crv ? crv : "");
  return 0;
}

/* ---- ABI table ----------------------------------------------------------- */

static void *cjws_abi_key_from_pem(pTHX_ const char *pem, STRLEN len) {
  return (void *)cjws_key_from_pem(pem, len);
}
static void *cjws_abi_key_from_oct(pTHX_ const unsigned char *s, STRLEN len) {
  return (void *)cjws_key_from_oct(s, len);
}
static void cjws_abi_key_free(pTHX_ void *key) {
  cjws_key_free((cjws_key *)key);
}
static int cjws_abi_key_is_private(pTHX_ void *key) {
  return ((cjws_key *)key)->is_private;
}
static SV *cjws_abi_sign(pTHX_ void *key, const char *alg, STRLEN alglen,
                         const unsigned char *input, STRLEN inlen) {
  STRLEN outlen = 0;
  unsigned char *sig = cjws_sign_raw(aTHX_ (cjws_key *)key, alg, alglen,
                                     input, inlen, &outlen);
  SV *out;
  if (!sig) return NULL;
  out = cjws_new_bytes_sv(aTHX_ sig, outlen);
  OPENSSL_cleanse(sig, outlen);
  OPENSSL_free(sig);
  return out;
}
static int cjws_abi_verify(pTHX_ void *key, const char *alg, STRLEN alglen,
                           const unsigned char *input, STRLEN inlen,
                           const unsigned char *sig, STRLEN siglen) {
  return cjws_verify_raw(aTHX_ (cjws_key *)key, alg, alglen,
                         input, inlen, sig, siglen);
}
static SV *cjws_abi_sha256(pTHX_ const unsigned char *in, STRLEN len) {
  unsigned char out[EVP_MAX_MD_SIZE];
  unsigned n = cjws_digest(256, in, len, out);
  return n ? cjws_new_bytes_sv(aTHX_ out, n) : NULL;
}
static SV *cjws_abi_hmac_sha256(pTHX_ const unsigned char *key, STRLEN keylen,
                                const unsigned char *in, STRLEN len) {
  unsigned char out[EVP_MAX_MD_SIZE];
  STRLEN n = cjws_hmac(256, key, keylen, in, len, out);
  return n ? cjws_new_bytes_sv(aTHX_ out, n) : NULL;
}
static SV *cjws_abi_b64url(pTHX_ const unsigned char *in, STRLEN len) {
  SV *out = newSV(cjws_b64url_encoded_len(len) + 1);
  STRLEN n;
  SvPOK_on(out);
  n = cjws_b64url_encode(SvPVX(out), in, len);
  SvCUR_set(out, n);
  *SvEND(out) = '\0';
  return out;
}
static SV *cjws_abi_b64url_decode(pTHX_ const char *in, STRLEN len) {
  SV *out = newSV((len / 4 + 1) * 3 + 1);
  STRLEN n;
  SvPOK_on(out);
  n = cjws_b64url_decode((unsigned char *)SvPVX(out), in, len);
  if (n == (STRLEN)-1) {
    SvREFCNT_dec(out);
    return NULL;
  }
  SvCUR_set(out, n);
  *SvEND(out) = '\0';
  return out;
}
static int cjws_abi_ct_eq(pTHX_ const unsigned char *a, STRLEN alen,
                          const unsigned char *b, STRLEN blen) {
  return cjws_ct_eq(a, alen, b, blen);
}
static SV *cjws_abi_random_bytes(pTHX_ STRLEN n) {
  SV *out = newSV(n + 1);
  SvPOK_on(out);
  cjws_random_bytes(aTHX_ (unsigned char *)SvPVX(out), n);
  SvCUR_set(out, n);
  *SvEND(out) = '\0';
  return out;
}

static const jws_abi CJWS_ABI = {
  JWS_ABI_VERSION,
  cjws_abi_key_from_pem,
  cjws_abi_key_from_oct,
  cjws_abi_key_free,
  cjws_abi_key_is_private,
  cjws_abi_sign,
  cjws_abi_verify,
  cjws_abi_sha256,
  cjws_abi_hmac_sha256,
  cjws_abi_b64url,
  cjws_abi_b64url_decode,
  cjws_abi_ct_eq,
  cjws_abi_random_bytes,
};

MODULE = Crypt::JWS  PACKAGE = Crypt::JWS

PROTOTYPES: DISABLE

INCLUDE: xs/util.xs
INCLUDE: xs/digest.xs
INCLUDE: xs/jws.xs
INCLUDE: xs/key.xs
