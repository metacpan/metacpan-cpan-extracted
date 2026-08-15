#ifndef JWS_ABI_H
#define JWS_ABI_H

/*
 * Crypt::JWS C ABI - a versioned function-pointer table for C-level
 * consumers (the house _abi_ptr pattern: resolve Crypt::JWS::_abi_ptr at
 * runtime, INT2PTR to const jws_abi *, check version).
 *
 * The table is append-only: new entries go at the end, JWS_ABI_VERSION
 * bumps, existing offsets never move. Consumers written against version
 * N work against every N+k.
 *
 * Keys are opaque (void *, really a cjws_key *). Buffers returned as
 * SV * are owned by the caller (REFCNT 1, not mortal).
 */

#define JWS_ABI_VERSION 1

typedef struct jws_abi {
  int version;

  /* key lifecycle - NULL on failure */
  void *(*key_from_pem)(pTHX_ const char *pem, STRLEN len);
  void *(*key_from_oct)(pTHX_ const unsigned char *secret, STRLEN len);
  void  (*key_free)(pTHX_ void *key);
  int   (*key_is_private)(pTHX_ void *key);

  /* raw JWS ops over signing-input bytes; alg is "RS256" etc.
   * sign returns an owned SV of signature bytes or NULL; verify
   * returns 1 valid / 0 invalid. */
  SV  *(*sign)(pTHX_ void *key, const char *alg, STRLEN alglen,
               const unsigned char *input, STRLEN inlen);
  int  (*verify)(pTHX_ void *key, const char *alg, STRLEN alglen,
                 const unsigned char *input, STRLEN inlen,
                 const unsigned char *sig, STRLEN siglen);

  /* primitives - out SVs owned by the caller */
  SV  *(*sha256)(pTHX_ const unsigned char *in, STRLEN len);
  SV  *(*hmac_sha256)(pTHX_ const unsigned char *key, STRLEN keylen,
                      const unsigned char *in, STRLEN len);
  SV  *(*b64url)(pTHX_ const unsigned char *in, STRLEN len);
  SV  *(*b64url_decode)(pTHX_ const char *in, STRLEN len);  /* NULL on bad input */
  int  (*ct_eq)(pTHX_ const unsigned char *a, STRLEN alen,
                const unsigned char *b, STRLEN blen);
  SV  *(*random_bytes)(pTHX_ STRLEN n);
} jws_abi;

#endif
