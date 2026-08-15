#ifndef CJWS_COMPAT_H
#define CJWS_COMPAT_H

/* The one file that knows OpenSSL 1.1 and 3.x import/export keys
 * differently. Everything here is selected by the Makefile.PL FEATURE
 * probes (CJWS_HAVE_FROMDATA / CJWS_HAVE_SET0), never by version
 * macros. Four operations diverge:
 *   - RSA key from n/e(/d) BIGNUMs
 *   - EC key from curve + x/y(/d)
 *   - RSA n/e extraction
 *   - EC curve/x/y extraction
 * Callers own every BIGNUM they pass in and free what they get back. */

#include <openssl/evp.h>
#include <openssl/bn.h>
#include <openssl/ec.h>
#include <openssl/obj_mac.h>

#if defined(CJWS_HAVE_FROMDATA)
#include <openssl/core_names.h>
#include <openssl/param_build.h>
#elif defined(CJWS_HAVE_SET0)
#include <openssl/rsa.h>
#else
#error "Crypt::JWS: neither CJWS_HAVE_FROMDATA nor CJWS_HAVE_SET0 defined"
#endif

static int cjws_curve_nid(int bits) {
  switch (bits) {
    case 256: return NID_X9_62_prime256v1;
    case 384: return NID_secp384r1;
    case 521: return NID_secp521r1;
  }
  return NID_undef;
}

static const char *cjws_curve_group_name(int bits) {
  switch (bits) {
    case 256: return "prime256v1";
    case 384: return "secp384r1";
    case 521: return "secp521r1";
  }
  return NULL;
}

/* EC coordinate byte length (P-521 rounds up). */
static int cjws_curve_coord_len(int bits) {
  return (bits + 7) / 8;
}

#if defined(CJWS_HAVE_FROMDATA)

static EVP_PKEY *cjws_pkey_from_rsa(const BIGNUM *n, const BIGNUM *e,
                                    const BIGNUM *d) {
  EVP_PKEY *pkey = NULL;
  EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name(NULL, "RSA", NULL);
  OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
  OSSL_PARAM *params = NULL;
  if (!ctx || !bld) goto done;
  if (OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_RSA_N, n) != 1) goto done;
  if (OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_RSA_E, e) != 1) goto done;
  if (d && OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_RSA_D, d) != 1) goto done;
  params = OSSL_PARAM_BLD_to_param(bld);
  if (!params) goto done;
  if (EVP_PKEY_fromdata_init(ctx) != 1) goto done;
  if (EVP_PKEY_fromdata(ctx, &pkey,
        d ? EVP_PKEY_KEYPAIR : EVP_PKEY_PUBLIC_KEY, params) != 1)
    pkey = NULL;
done:
  OSSL_PARAM_free(params);
  OSSL_PARAM_BLD_free(bld);
  EVP_PKEY_CTX_free(ctx);
  return pkey;
}

static EVP_PKEY *cjws_pkey_from_ec(int bits, const BIGNUM *x, const BIGNUM *y,
                                   const BIGNUM *d) {
  EVP_PKEY *pkey = NULL;
  EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name(NULL, "EC", NULL);
  OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
  OSSL_PARAM *params = NULL;
  const char *group = cjws_curve_group_name(bits);
  int clen = cjws_curve_coord_len(bits);
  unsigned char *pub = NULL;
  if (!ctx || !bld || !group) goto done;
  pub = (unsigned char *)OPENSSL_malloc((size_t)(1 + 2 * clen));
  if (!pub) goto done;
  pub[0] = 0x04;   /* uncompressed point */
  if (BN_bn2binpad(x, pub + 1, clen) != clen) goto done;
  if (BN_bn2binpad(y, pub + 1 + clen, clen) != clen) goto done;
  if (OSSL_PARAM_BLD_push_utf8_string(bld, OSSL_PKEY_PARAM_GROUP_NAME,
                                      group, 0) != 1) goto done;
  if (OSSL_PARAM_BLD_push_octet_string(bld, OSSL_PKEY_PARAM_PUB_KEY,
                                       pub, (size_t)(1 + 2 * clen)) != 1) goto done;
  if (d && OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_PRIV_KEY, d) != 1) goto done;
  params = OSSL_PARAM_BLD_to_param(bld);
  if (!params) goto done;
  if (EVP_PKEY_fromdata_init(ctx) != 1) goto done;
  if (EVP_PKEY_fromdata(ctx, &pkey,
        d ? EVP_PKEY_KEYPAIR : EVP_PKEY_PUBLIC_KEY, params) != 1)
    pkey = NULL;
done:
  OPENSSL_free(pub);
  OSSL_PARAM_free(params);
  OSSL_PARAM_BLD_free(bld);
  EVP_PKEY_CTX_free(ctx);
  return pkey;
}

/* Extract public RSA params as fresh BIGNUMs (caller frees). */
static int cjws_pkey_get_rsa(EVP_PKEY *pkey, BIGNUM **n, BIGNUM **e) {
  *n = *e = NULL;
  if (EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_RSA_N, n) != 1) return 0;
  if (EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_RSA_E, e) != 1) {
    BN_free(*n); *n = NULL;
    return 0;
  }
  return 1;
}

/* Extract EC curve bits + affine coordinates (caller frees x/y). */
static int cjws_pkey_get_ec(EVP_PKEY *pkey, int *bits, BIGNUM **x, BIGNUM **y) {
  char group[64];
  *x = *y = NULL;
  if (EVP_PKEY_get_utf8_string_param(pkey, OSSL_PKEY_PARAM_GROUP_NAME,
                                     group, sizeof group, NULL) != 1)
    return 0;
  if (strcmp(group, "prime256v1") == 0 || strcmp(group, "P-256") == 0)
    *bits = 256;
  else if (strcmp(group, "secp384r1") == 0 || strcmp(group, "P-384") == 0)
    *bits = 384;
  else if (strcmp(group, "secp521r1") == 0 || strcmp(group, "P-521") == 0)
    *bits = 521;
  else return 0;
  if (EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_EC_PUB_X, x) != 1) return 0;
  if (EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_EC_PUB_Y, y) != 1) {
    BN_free(*x); *x = NULL;
    return 0;
  }
  return 1;
}

#else /* CJWS_HAVE_SET0: OpenSSL 1.1 struct API */

static EVP_PKEY *cjws_pkey_from_rsa(const BIGNUM *n, const BIGNUM *e,
                                    const BIGNUM *d) {
  RSA *rsa = RSA_new();
  EVP_PKEY *pkey = NULL;
  BIGNUM *nn, *ee, *dd = NULL;
  if (!rsa) return NULL;
  nn = BN_dup(n);
  ee = BN_dup(e);
  if (d) dd = BN_dup(d);
  if (!nn || !ee || (d && !dd)
      || RSA_set0_key(rsa, nn, ee, dd) != 1) {
    BN_free(nn); BN_free(ee); BN_free(dd);
    RSA_free(rsa);
    return NULL;
  }
  pkey = EVP_PKEY_new();
  if (!pkey || EVP_PKEY_assign_RSA(pkey, rsa) != 1) {
    EVP_PKEY_free(pkey);
    RSA_free(rsa);
    return NULL;
  }
  return pkey;
}

static EVP_PKEY *cjws_pkey_from_ec(int bits, const BIGNUM *x, const BIGNUM *y,
                                   const BIGNUM *d) {
  int nid = cjws_curve_nid(bits);
  EC_KEY *ec;
  EVP_PKEY *pkey = NULL;
  if (nid == NID_undef) return NULL;
  ec = EC_KEY_new_by_curve_name(nid);
  if (!ec) return NULL;
  if (EC_KEY_set_public_key_affine_coordinates(ec, (BIGNUM *)x,
                                               (BIGNUM *)y) != 1) {
    EC_KEY_free(ec);
    return NULL;
  }
  if (d && EC_KEY_set_private_key(ec, d) != 1) {
    EC_KEY_free(ec);
    return NULL;
  }
  pkey = EVP_PKEY_new();
  if (!pkey || EVP_PKEY_assign_EC_KEY(pkey, ec) != 1) {
    EVP_PKEY_free(pkey);
    EC_KEY_free(ec);
    return NULL;
  }
  return pkey;
}

static int cjws_pkey_get_rsa(EVP_PKEY *pkey, BIGNUM **n, BIGNUM **e) {
  const RSA *rsa = EVP_PKEY_get0_RSA(pkey);
  const BIGNUM *cn, *ce;
  *n = *e = NULL;
  if (!rsa) return 0;
  RSA_get0_key(rsa, &cn, &ce, NULL);
  if (!cn || !ce) return 0;
  *n = BN_dup(cn);
  *e = BN_dup(ce);
  if (!*n || !*e) {
    BN_free(*n); BN_free(*e);
    *n = *e = NULL;
    return 0;
  }
  return 1;
}

static int cjws_pkey_get_ec(EVP_PKEY *pkey, int *bits, BIGNUM **x, BIGNUM **y) {
  const EC_KEY *ec = EVP_PKEY_get0_EC_KEY(pkey);
  const EC_GROUP *grp;
  const EC_POINT *pt;
  BN_CTX *bnctx;
  int nid, ok = 0;
  *x = *y = NULL;
  if (!ec) return 0;
  grp = EC_KEY_get0_group(ec);
  pt  = EC_KEY_get0_public_key(ec);
  if (!grp || !pt) return 0;
  nid = EC_GROUP_get_curve_name(grp);
  if (nid == NID_X9_62_prime256v1) *bits = 256;
  else if (nid == NID_secp384r1)   *bits = 384;
  else if (nid == NID_secp521r1)   *bits = 521;
  else return 0;
  *x = BN_new();
  *y = BN_new();
  bnctx = BN_CTX_new();
  if (*x && *y && bnctx
      && EC_POINT_get_affine_coordinates(grp, pt, *x, *y, bnctx) == 1)
    ok = 1;
  BN_CTX_free(bnctx);
  if (!ok) {
    BN_free(*x); BN_free(*y);
    *x = *y = NULL;
  }
  return ok;
}

#endif

#endif
