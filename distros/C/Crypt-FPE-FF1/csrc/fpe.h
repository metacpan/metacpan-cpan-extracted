#ifndef HEADER_FPE_H
# define HEADER_FPE_H

# include <openssl/aes.h>

# ifdef __cplusplus
extern "C" {
# endif

# define FF1_ROUNDS 10
# define FF3_ROUNDS 8
# define FF3_TWEAK_SIZE 8

struct fpe_key_st {
    unsigned int tweaklen;
    unsigned char *tweak;
    unsigned int radix;
    AES_KEY aes_enc_ctx;
};

typedef struct fpe_key_st FPE_KEY;

/*** FF1 ***/
/* map_chars()/inverse_map_chars() (fpe_locl.c) encode input characters as
 * '0'-'9' -> 0-9, 'a'-'z' -> 10-35, 'A'-'Z' -> 36-61, with no bounds check
 * against radix. Callers using this C API directly (rather than through
 * the validated Perl layer) must ensure every character's mapped value is
 * < radix -- e.g. radix=26 only safely accepts 'a'-'p', not 'q'-'z'. */
FPE_KEY* FPE_ff1_create_key(const char *key, const char *tweak, unsigned int radix);

void FPE_ff1_delete_key(FPE_KEY *key);

void FPE_ff1_encrypt(char *plaintext, char *ciphertext, FPE_KEY *key);
//void FPE_ff1_encrypt(unsigned int *plaintext, unsigned int *ciphertext, unsigned int txtlen, FPE_KEY *key);
//void FPE_ff1_decrypt(unsigned int *ciphertext, unsigned int *plaintext, unsigned int txtlen, FPE_KEY *key);
void FPE_ff1_decrypt(char *ciphertext, char *plaintext, FPE_KEY *key);

/*** FF3 ***/
FPE_KEY* FPE_ff3_create_key(const char *key, const char *tweak, unsigned int radix);
FPE_KEY* FPE_ff3_1_create_key(const char *key, const char *tweak, unsigned int radix);

void FPE_ff3_delete_key(FPE_KEY *key);

void FPE_ff3_encrypt(char *plaintext, char *ciphertext, FPE_KEY *key);
void FPE_ff3_decrypt(char *ciphertext, char *plaintext, FPE_KEY *key);
//void FPE_ff3_decrypt(unsigned int *ciphertext, unsigned int *plaintext, unsigned int inlen, FPE_KEY *key);

# ifdef __cplusplus
}
# endif

#endif
