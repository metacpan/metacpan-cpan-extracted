#ifndef CJWS_UTIL_H
#define CJWS_UTIL_H

#include <openssl/crypto.h>

/* Constant-time equality. Length inequality returns 0 immediately - the
 * lengths of the values compared here (digests, signatures) are public. */
static int cjws_ct_eq(const unsigned char *a, STRLEN alen,
                      const unsigned char *b, STRLEN blen) {
  if (alen != blen) return 0;
  return CRYPTO_memcmp(a, b, alen) == 0;
}

#endif
