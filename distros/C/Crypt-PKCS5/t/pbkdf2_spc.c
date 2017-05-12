#include <stdio.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <sys/types.h>  /* for netinet/in.h on some platforms */
#include <netinet/in.h> /* for arpa/inet.h on some platforms */
#include <arpa/inet.h>  /* for htonl */

#ifdef WIN32
typedef unsigned __int64 spc_uint64_t;
#else
typedef unsigned long long spc_uint64_t;
#endif

/* This value needs to be the output size of your pseudo-random function (PRF)! */
#define PRF_OUT_LEN 20

/* This is an implementation of the PKCS#5 PBKDF2 PRF using HMAC-SHA1.  It
 * always gives 20-byte outputs.
 */

/* The first three functions are internal helper functions. */
static void pkcs5_initial_prf(unsigned char *p, size_t plen, unsigned char *salt,
                               size_t saltlen, size_t i, unsigned char *out,
                               size_t *outlen) {
  size_t        swapped_i;
  HMAC_CTX      ctx;

  HMAC_CTX_init(&ctx);
  HMAC_Init(&ctx, p, plen, EVP_sha1());
  HMAC_Update(&ctx, salt, saltlen);
  swapped_i = htonl(i);
  HMAC_Update(&ctx, (unsigned char *)&swapped_i, 4);
  HMAC_Final(&ctx, out, (unsigned int *)outlen);
}

/* The PRF doesn't *really* change in subsequent calls, but above we handled the
 * concatenation of the salt and i within the function, instead of external to it,
 * because the implementation is easier that way.
 */
static void pkcs5_subsequent_prf(unsigned char *p, size_t plen, unsigned char *v,
                                  size_t vlen, unsigned char *o, size_t *olen) {
  HMAC_CTX ctx;

  HMAC_CTX_init(&ctx);
  HMAC_Init(&ctx, p, plen, EVP_sha1());
  HMAC_Update(&ctx, v, vlen);
  HMAC_Final(&ctx, o, (unsigned int *)olen);
}

static void pkcs5_F(unsigned char *p, size_t plen, unsigned char *salt,
                     size_t saltlen, size_t ic, size_t bix, unsigned char *out) {
  size_t        i = 1, j, outlen;
  unsigned char ulast[PRF_OUT_LEN];

  memset(out,0,  PRF_OUT_LEN);
  pkcs5_initial_prf(p, plen, salt, saltlen, bix, ulast, &outlen);
  while (i++ < ic) {
    for (j = 0;  j < PRF_OUT_LEN;  j++) out[j] ^= ulast[j];

    pkcs5_subsequent_prf(p, plen, ulast, PRF_OUT_LEN, ulast, &outlen);
  }
  for (j = 0;  j < PRF_OUT_LEN;  j++) out[j] ^= ulast[j];

}

void spc_pbkdf2(unsigned char *pw, unsigned int pwlen, char *salt,
                 spc_uint64_t saltlen, unsigned int ic, unsigned char *dk,
                 spc_uint64_t dklen) {
  unsigned long i, l, r;
  unsigned char final[PRF_OUT_LEN] = {0,};

  if (dklen > ((((spc_uint64_t)1) << 32) - 1) * PRF_OUT_LEN) {
    /* Call an error handler. */
    abort();
  }
  l = dklen / PRF_OUT_LEN;
  r = dklen % PRF_OUT_LEN;
  for (i = 1;  i <= l;  i++)
    pkcs5_F(pw, pwlen, salt, saltlen, ic, i, dk + (i - 1) * PRF_OUT_LEN);
  if (r) {
    pkcs5_F(pw, pwlen, salt, saltlen, ic, i, final);
    for (l = 0;  l < r;  l++) *(dk + (i - 1) * PRF_OUT_LEN + l) = final[l];
  }
}

void print_hex(const char *label, unsigned char *buff, size_t l)
{
    printf("%s", label);
    while (l > 0) {
        printf("%02x", *buff);
        buff++;
        l--;
    }
    printf("\n");
}



int main(int argc, char *argv[])
{
    unsigned char *P = argv[1];
    unsigned char *S = argv[2];
    unsigned char *DK; 
    int i = atoi(argv[3]);
    int dkLen = atoi(argv[4]);
    DK = malloc(dkLen);
    memset(DK, 0, dkLen);

    print_hex("P: ", P, strlen(P));
    print_hex("S: ", S, strlen(S));
    printf("c: %u\n", i);
    printf("dkLen: %u\n", dkLen);

    spc_pbkdf2(P, strlen(P), S, 8, i, DK, dkLen);
    print_hex("DK: ", DK, dkLen);
    free(DK);

    return 0;
}

