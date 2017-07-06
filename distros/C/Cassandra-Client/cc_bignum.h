#include <stdint.h>
#include <stdio.h>

struct cc_bignum {
    uint8_t *number; /* Little-endian! */
    size_t length;
    int is_negative;
};

void cc_bignum_add_1(struct cc_bignum *n);
void cc_bignum_init_bytes(struct cc_bignum *bn, char *bytes, size_t length);
void cc_bignum_destroy(struct cc_bignum *bn);
void cc_bignum_copy(struct cc_bignum *out, struct cc_bignum *in);
void cc_bignum_move(struct cc_bignum *out, struct cc_bignum *in);
uint32_t cc_bignum_divide_8bit(struct cc_bignum *n, uint8_t d, struct cc_bignum *out);
void cc_bignum_stringify(struct cc_bignum *bn, char *out, size_t outlen);
int cc_bignum_is_zero(struct cc_bignum *n);
