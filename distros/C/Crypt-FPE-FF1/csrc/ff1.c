#include <stdint.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <openssl/aes.h>
#include <openssl/crypto.h>
#include <openssl/bn.h>
#include "fpe.h"
#include "fpe_locl.h"

// convert numeral string to number
void str2num(BIGNUM *Y, const unsigned int *X, unsigned long long radix, unsigned int len, BN_CTX *ctx)
{
    BN_CTX_start(ctx);
    BIGNUM *r = BN_CTX_get(ctx),
           *x = BN_CTX_get(ctx);

    BN_set_word(Y, 0);
    BN_set_word(r, radix);
    for (int i = 0; i < len; ++i) {
        // Y = Y * radix + X[i]
        BN_set_word(x, X[i]);
        BN_mul(Y, Y, r, ctx);
        BN_add(Y, Y, x);
    }

    BN_CTX_end(ctx);
    return;
}

// convert number to numeral string
void num2str(const BIGNUM *X, unsigned int *Y, unsigned int radix, int len, BN_CTX *ctx)
{
    BN_CTX_start(ctx);
    BIGNUM *dv = BN_CTX_get(ctx),
           *rem = BN_CTX_get(ctx),
           *r = BN_CTX_get(ctx),
           *XX = BN_CTX_get(ctx);

    BN_copy(XX, X);
    BN_set_word(r, radix);
    memset(Y, 0, len << 2);
    
    for (int i = len - 1; i >= 0; --i) {
        // XX / r = dv ... rem
        BN_div(dv, rem, XX, r, ctx);
        // Y[i] = XX % r
        Y[i] = BN_get_word(rem);
        // XX = XX / r
        BN_copy(XX, dv);
    }

    BN_CTX_end(ctx);
    return;
}

void FF1_encrypt(const unsigned int *plaintext, unsigned int *ciphertext, FPE_KEY *key, const unsigned char *tweak, size_t txtlen, size_t tweaklen)
{
    BIGNUM *bnum = BN_new(),
           *y = BN_new(),
           *c = BN_new(),
           *anum = BN_new(),
           *qpow_u = BN_new(),
           *qpow_v = BN_new();
    BN_CTX *ctx = BN_CTX_new();

    union {
        long one;
        char little;
    } is_endian = { 1 };

    // Calculate split point
    int u = floor2(txtlen, 1);
    int v = txtlen - u;

    // Split the message
    memcpy(ciphertext, plaintext, txtlen << 2);
    unsigned int *A = ciphertext;
    unsigned int *B = ciphertext + u;

    pow_uv(qpow_u, qpow_v, key->radix, u, v, ctx);

    unsigned int temp = (unsigned int)ceil(v * log2(key->radix));
    const int b = ceil2(temp, 3);
    const int d = 4 * ceil2(b, 2) + 4;

    int pad = ( (-tweaklen - b - 1) % 16 + 16 ) % 16;
    int Qlen = tweaklen + pad + 1 + b;
    unsigned char P[16];
    unsigned char *Q = (unsigned char *)OPENSSL_malloc(Qlen), *Bytes = (unsigned char *)OPENSSL_malloc(b);

    // initialize P
    P[0] = 0x1;
    P[1] = 0x2;
    P[2] = 0x1;
    P[7] = u % 256;
    if (is_endian.little) {
        temp = (key->radix << 8) | 10;
        P[3] = (temp >> 24) & 0xff;
        P[4] = (temp >> 16) & 0xff;
        P[5] = (temp >> 8) & 0xff;
        P[6] = temp & 0xff;
        P[8] = (txtlen >> 24) & 0xff;
        P[9] = (txtlen >> 16) & 0xff;
        P[10] = (txtlen >> 8) & 0xff;
        P[11] = txtlen & 0xff;
        P[12] = (tweaklen >> 24) & 0xff;
        P[13] = (tweaklen >> 16) & 0xff;
        P[14] = (tweaklen >> 8) & 0xff;
        P[15] = tweaklen & 0xff;
    } else {
        *( (unsigned int *)(P + 3) ) = (key->radix << 8) | 10;
        *( (unsigned int *)(P + 8) ) = txtlen;
        *( (unsigned int *)(P + 12) ) = tweaklen;
    }

    // initialize Q
    memcpy(Q, tweak, tweaklen);
    memset(Q + tweaklen, 0x00, pad);
    assert(tweaklen + pad - 1 <= Qlen);

    unsigned char R[16];
    int cnt = ceil2(d, 4) - 1;
    int Slen = 16 + cnt * 16;
    unsigned char *S = (unsigned char *)OPENSSL_malloc(Slen);
    for (int i = 0; i < FF1_ROUNDS; ++i) {
        // v
        int m = (i & 1)? v: u;

        // i
        Q[tweaklen + pad] = i & 0xff;
        str2num(bnum, B, key->radix, txtlen - m, ctx);
        int BytesLen = BN_bn2bin(bnum, Bytes);
        memset(Q + Qlen - b, 0x00, b);

        int qtmp = Qlen - BytesLen;
        memcpy(Q + qtmp, Bytes, BytesLen);

        // ii PRF(P || Q), P is always 16 bytes long
        AES_encrypt(P, R, &key->aes_enc_ctx);
        int count = Qlen / 16;
        unsigned char Ri[16];
        unsigned char *Qi = Q;
        for (int cc = 0; cc < count; ++cc) {
            for (int j = 0; j < 16; ++j)    Ri[j] = Qi[j] ^ R[j];
            AES_encrypt(Ri, R, &key->aes_enc_ctx);
            Qi += 16;
        }

        // iii 
        unsigned char tmp[16], SS[16];
        memset(S, 0x00, Slen);
        assert(Slen >= 16);
        memcpy(S, R, 16);
        for (int j = 1; j <= cnt; ++j) {
            memset(tmp, 0x00, 16);

            if (is_endian.little) {
                // convert to big endian
                // full unroll
                tmp[15] = j & 0xff;
                tmp[14] = (j >> 8) & 0xff;
                tmp[13] = (j >> 16) & 0xff;
                tmp[12] = (j >> 24) & 0xff;
            } else *( (unsigned int *)tmp + 3 ) = j;

            for (int k = 0; k < 16; ++k)    tmp[k] ^= R[k];
            AES_encrypt(tmp, SS, &key->aes_enc_ctx);
            assert((S + 16 * j)[0] == 0x00);
            assert(16 + 16 * j <= Slen);
            memcpy(S + 16 * j, SS, 16);
        }

        // iv
        BN_bin2bn(S, d, y);
        // vi
        // (num(A, key->radix, m) + y) % qpow(key->radix, m);
        str2num(anum, A, key->radix, m, ctx);
        // anum = (anum + y) mod qpow_uv
        if (m == u)    BN_mod_add(c, anum, y, qpow_u, ctx);
        else    BN_mod_add(c, anum, y, qpow_v, ctx);

        // swap A and B
        assert(A != B);
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        B = (unsigned int *)( (uintptr_t)B ^ (uintptr_t)A );
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        num2str(c, B, key->radix, m, ctx);
    }

    // free the space
    BN_clear_free(anum);
    BN_clear_free(bnum);
    BN_clear_free(c);
    BN_clear_free(y);
    BN_clear_free(qpow_u);
    BN_clear_free(qpow_v);
    BN_CTX_free(ctx);
    OPENSSL_free(Bytes);
    OPENSSL_free(Q);
    OPENSSL_free(S);
    return;
}

void FF1_decrypt(const unsigned int *ciphertext, unsigned int *plaintext, FPE_KEY *key, const unsigned char *tweak, size_t txtlen, size_t tweaklen)
{
    BIGNUM *bnum = BN_new(),
           *y = BN_new(),
           *c = BN_new(),
           *anum = BN_new(),
           *qpow_u = BN_new(),
           *qpow_v = BN_new();
    BN_CTX *ctx = BN_CTX_new();

    union {
        long one;
        char little;
    } is_endian = { 1 };

    // Calculate split point
    int u = floor2(txtlen, 1);
    int v = txtlen - u;

    // Split the message
    memcpy(plaintext, ciphertext, txtlen << 2);
    unsigned int *A = plaintext, *B = plaintext + u;
    pow_uv(qpow_u, qpow_v, key->radix, u, v, ctx);

    unsigned int temp = (unsigned int)ceil(v * log2(key->radix));
    const int b = ceil2(temp, 3);
    const int d = 4 * ceil2(b, 2) + 4;

    int pad = ( (-tweaklen - b - 1) % 16 + 16 ) % 16;
    int Qlen = tweaklen + pad + 1 + b;
    unsigned char P[16];
    unsigned char *Q = (unsigned char *)OPENSSL_malloc(Qlen), *Bytes = (unsigned char *)OPENSSL_malloc(b);
    // initialize P
    P[0] = 0x1;
    P[1] = 0x2;
    P[2] = 0x1;
    P[7] = u % 256;
    if (is_endian.little) {
        temp = (key->radix << 8) | 10;
        P[3] = (temp >> 24) & 0xff;
        P[4] = (temp >> 16) & 0xff;
        P[5] = (temp >> 8) & 0xff;
        P[6] = temp & 0xff;
        P[8] = (txtlen >> 24) & 0xff;
        P[9] = (txtlen >> 16) & 0xff;
        P[10] = (txtlen >> 8) & 0xff;
        P[11] = txtlen & 0xff;
        P[12] = (tweaklen >> 24) & 0xff;
        P[13] = (tweaklen >> 16) & 0xff;
        P[14] = (tweaklen >> 8) & 0xff;
        P[15] = tweaklen & 0xff;
    } else {
        *( (unsigned int *)(P + 3) ) = (key->radix << 8) | 10;
        *( (unsigned int *)(P + 8) ) = txtlen;
        *( (unsigned int *)(P + 12) ) = tweaklen;
    }

    // initialize Q
    memcpy(Q, tweak, tweaklen);
    memset(Q + tweaklen, 0x00, pad);
    assert(tweaklen + pad - 1 <= Qlen);

    unsigned char R[16];
    int cnt = ceil2(d, 4) - 1;
    int Slen = 16 + cnt * 16;
    unsigned char *S = (unsigned char *)OPENSSL_malloc(Slen);
    for (int i = FF1_ROUNDS - 1; i >= 0; --i) {
        // v
        int m = (i & 1)? v: u;

        // i
        Q[tweaklen + pad] = i & 0xff;
        str2num(anum, A, key->radix, txtlen - m, ctx);
        memset(Q + Qlen - b, 0x00, b);
        int BytesLen = BN_bn2bin(anum, Bytes);
        int qtmp = Qlen - BytesLen;
        memcpy(Q + qtmp, Bytes, BytesLen);

        // ii PRF(P || Q)
        memset(R, 0x00, sizeof(R));
        AES_encrypt(P, R, &key->aes_enc_ctx);
        int count = Qlen / 16;
        unsigned char Ri[16];
        unsigned char *Qi = Q;
        for (int cc = 0; cc < count; ++cc) {
            for (int j = 0; j < 16; ++j)    Ri[j] = Qi[j] ^ R[j];
            AES_encrypt(Ri, R, &key->aes_enc_ctx);
            Qi += 16;
        }

        // iii 
        unsigned char tmp[16], SS[16];
        memset(S, 0x00, Slen);
        memcpy(S, R, 16);
        for (int j = 1; j <= cnt; ++j) {
            memset(tmp, 0x00, 16);

            if (is_endian.little) {
                // convert to big endian
                // full unroll
                tmp[15] = j & 0xff;
                tmp[14] = (j >> 8) & 0xff;
                tmp[13] = (j >> 16) & 0xff;
                tmp[12] = (j >> 24) & 0xff;
            } else *( (unsigned int *)tmp + 3 ) = j;

            for (int k = 0; k < 16; ++k)    tmp[k] ^= R[k];
            AES_encrypt(tmp, SS, &key->aes_enc_ctx);
            assert((S + 16 * j)[0] == 0x00);
            memcpy(S + 16 * j, SS, 16);
        }

        // iv
        BN_bin2bn(S, d, y);
        // vi
        // (num(B, key->radix, m) - y) % qpow(key->radix, m);
        str2num(bnum, B, key->radix, m, ctx);
        if (m == u)    BN_mod_sub(c, bnum, y, qpow_u, ctx);
        else    BN_mod_sub(c, bnum, y, qpow_v, ctx);

        // swap A and B
        assert(A != B);
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        B = (unsigned int *)( (uintptr_t)B ^ (uintptr_t)A );
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        num2str(c, A, key->radix, m, ctx);

    }

    // free the space
    BN_clear_free(anum);
    BN_clear_free(bnum);
    BN_clear_free(y);
    BN_clear_free(c);
    BN_clear_free(qpow_u);
    BN_clear_free(qpow_v);
    BN_CTX_free(ctx);
    OPENSSL_free(Bytes);
    OPENSSL_free(Q);
    OPENSSL_free(S);
    return;
}

int create_ff1_key(const unsigned char *userKey, const int bits, const unsigned char *tweak, const unsigned int tweaklen, const unsigned int radix, FPE_KEY *key)
{
    int ret;
    if (bits != 128 && bits != 192 && bits != 256) {
        ret = -1;
        return ret;
    }
    key->tweaklen = tweaklen;
    key->tweak = (unsigned char *)OPENSSL_malloc(tweaklen ? tweaklen : 1);
    if (tweaklen)    memcpy(key->tweak, tweak, tweaklen);
    ret = AES_set_encrypt_key(userKey, bits, &key->aes_enc_ctx);
    key->radix = radix;
    return ret;
}

FPE_KEY* FPE_ff1_create_key(const char *key, const char *tweak, unsigned int radix)
{
    int klen = strlen(key) / 2;
    int tlen = strlen(tweak) / 2;

    unsigned char *k = (unsigned char *)OPENSSL_malloc(klen > 0 ? klen : 1);
    unsigned char *t = (unsigned char *)OPENSSL_malloc(tlen > 0 ? tlen : 1);

    hex2chars(key, k);
    hex2chars(tweak, t);

    FPE_KEY *keystruct  = (FPE_KEY *)OPENSSL_malloc(sizeof(FPE_KEY));
    create_ff1_key(k,klen*8,t,tlen,radix,keystruct);

    OPENSSL_clear_free(k, klen > 0 ? klen : 1);
    OPENSSL_clear_free(t, tlen > 0 ? tlen : 1);
    return keystruct;
}

void FPE_ff1_delete_key(FPE_KEY *key)
{
    OPENSSL_clear_free(key->tweak,key->tweaklen);
    OPENSSL_clear_free(key,sizeof(*key));
}

void FPE_ff1_encrypt(char *plaintext, char *ciphertext, FPE_KEY *key)
{
    int txtlen = strlen(plaintext);
    unsigned int *x = (unsigned int *)OPENSSL_malloc(txtlen * sizeof(unsigned int));
    unsigned int *y = (unsigned int *)OPENSSL_malloc(txtlen * sizeof(unsigned int));
    map_chars(plaintext, x);

    FF1_encrypt(x, y, key, key->tweak, txtlen, key->tweaklen);

    inverse_map_chars(y, ciphertext, txtlen);

    OPENSSL_free(x);
    OPENSSL_free(y);
}

void FPE_ff1_decrypt(char *ciphertext, char* plaintext, FPE_KEY *key)
{
    int txtlen = strlen(ciphertext);
    unsigned int *x = (unsigned int *)OPENSSL_malloc(txtlen * sizeof(unsigned int));
    unsigned int *y = (unsigned int *)OPENSSL_malloc(txtlen * sizeof(unsigned int));
    map_chars(ciphertext, x);

    FF1_decrypt(x, y, key, key->tweak, txtlen, key->tweaklen);

    inverse_map_chars(y, plaintext, txtlen);

    OPENSSL_free(x);
    OPENSSL_free(y);
}

