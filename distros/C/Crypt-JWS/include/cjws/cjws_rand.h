#ifndef CJWS_RAND_H
#define CJWS_RAND_H

#include <openssl/rand.h>

/* CSPRNG via RAND_bytes. Failure croaks - a weak token is worse than no
 * token (pk_random_bytes precedent: never degrade). */
static void cjws_random_bytes(pTHX_ unsigned char *buf, STRLEN n) {
  if (RAND_bytes(buf, (int)n) != 1)
    croak("Crypt::JWS: RAND_bytes failed");
}

#endif
