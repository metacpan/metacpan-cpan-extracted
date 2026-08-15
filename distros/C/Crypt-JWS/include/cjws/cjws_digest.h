#ifndef CJWS_DIGEST_H
#define CJWS_DIGEST_H

#include <openssl/evp.h>

/* One-shot SHA-2 digests and HMAC. HMAC runs through the same
 * EVP_DigestSign machinery the asymmetric algorithms use
 * (EVP_PKEY_new_raw_private_key exists on 1.1 and 3.x alike), so the
 * whole JWS algorithm table is one code path. */

static const EVP_MD *cjws_md_by_bits(int bits) {
  switch (bits) {
    case 256: return EVP_sha256();
    case 384: return EVP_sha384();
    case 512: return EVP_sha512();
  }
  return NULL;
}

/* out must hold EVP_MAX_MD_SIZE. Returns digest length or 0 on error. */
static unsigned cjws_digest(int bits, const unsigned char *in, STRLEN n,
                            unsigned char *out) {
  const EVP_MD *md = cjws_md_by_bits(bits);
  unsigned outlen = 0;
  if (!md) return 0;
  if (EVP_Digest(in, n, out, &outlen, md, NULL) != 1) return 0;
  return outlen;
}

/* HMAC-SHA-2. out must hold EVP_MAX_MD_SIZE. Returns MAC length or 0. */
static STRLEN cjws_hmac(int bits, const unsigned char *key, STRLEN keylen,
                        const unsigned char *in, STRLEN n,
                        unsigned char *out) {
  const EVP_MD *md = cjws_md_by_bits(bits);
  EVP_PKEY *pk = NULL;
  EVP_MD_CTX *ctx = NULL;
  size_t maclen = 0;
  if (!md) return 0;
  pk = EVP_PKEY_new_raw_private_key(EVP_PKEY_HMAC, NULL, key, keylen);
  if (!pk) return 0;
  ctx = EVP_MD_CTX_new();
  if (!ctx) { EVP_PKEY_free(pk); return 0; }
  if (EVP_DigestSignInit(ctx, NULL, md, NULL, pk) == 1
      && EVP_DigestSign(ctx, NULL, &maclen, in, n) == 1
      && maclen <= EVP_MAX_MD_SIZE
      && EVP_DigestSign(ctx, out, &maclen, in, n) == 1) {
    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(pk);
    return (STRLEN)maclen;
  }
  EVP_MD_CTX_free(ctx);
  EVP_PKEY_free(pk);
  return 0;
}

#endif
