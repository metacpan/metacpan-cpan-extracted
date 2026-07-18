#include <stdint.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <openssl/aes.h>
#include <openssl/bn.h>
#include <openssl/crypto.h>
#include "fpe.h"
#include "fpe_locl.h"

// If this flag is set, the user is opting out of the 128-bit integer mode
#ifdef FPE_USE_BIGNUM
    #undef _FPE_FEAT_USE_U128
    #ifdef FPE_U128_TYPEDEF
        #warning "FPE_USE_BIGNUM is set, but FPE_U128_TYPEDEF is also defined. Falling back to BIGNUM."
    #endif
#else 
    // 128-bit integers are a widely supported extension in modern compilers
    // for 64-bit targets.
    // To detect support for 128-bit integers, we check for the __SIZEOF_INT128__ macro,
    // which is defined starting at these version of the respective compilers
    // (as verified on Godbolt):
    //
    // x86-64 GCC      ^=4.6.?         https://godbolt.org/z/qM8hs9WE4
    //  ARM64 GCC      ^=4.9.?         https://godbolt.org/z/e46YYd1MG
    // x86-64 Clang    ^=3.3           https://godbolt.org/z/d5fzTv75o
    //  ARMv8 Clang    ^=9.0           https://godbolt.org/z/YT66EYq8P
    // x86-64 ICC      ^=16.0.3        https://godbolt.org/z/dM44bashq
    // x86-64 MSVC     No support.     MSVC does not support 128-bit integers.
    //
    // Note: certain compilers make 128-bit integers available *before* __SIZEOF_INT128__ 
    // was widely defined, so in those special cases we make the FPE_U128_TYPEDEF macro 
    // available.
    #if defined(__SIZEOF_INT128__) || defined(FPE_U128_TYPEDEF)
        #define _FPE_FEAT_USE_U128
    #else
        #warning "This compiler does not support 128-bit integers, falling back to BIGNUM."
    #endif
#endif

// If the library is being built in 128-bit mode,
// we need to define the necessary types.
#ifdef _FPE_FEAT_USE_U128
    #define _TYPEDEF(type, name) typedef type name

    #ifdef FPE_U128_TYPEDEF
        _TYPEDEF(FPE_U128_TYPEDEF, uint128);
    #else
        _TYPEDEF(__uint128_t, uint128);
    #endif

    #undef _TYPEDEF
#endif

inline void rev_bytes(unsigned char X[], int len)
{
    int hlen = len >> 1;
    for (int i = 0; i < hlen; ++i) {
        unsigned char tmp = X[i];
        X[i] = X[len - i - 1];
        X[len - i - 1] = tmp;
    }
    return;
}

#ifdef _FPE_FEAT_USE_U128

inline int num2str_u128_rev(uint128 x, unsigned int *Y, unsigned int radix, int len)
{
    uint128 radix_ull = (uint128)radix;

    memset(Y, 0, len << 2);

    int i = 0;
    for (; i < len && x >= radix_ull; ++i) {
        unsigned int rr = (unsigned int)(x % radix_ull);
        Y[i] = rr;
        x /= radix_ull;
    }

    Y[i] = (unsigned int)x;

    return i;
}

inline uint128 str2num_u128_rev(const unsigned int *X, unsigned int radix, unsigned int len)
{
    uint128 it = 0;
    for (int i = len - 1; i >= 0; --i) {
        it *= radix;
        it += X[i];
    }

    return it;
}

// void print_u128_hex(uint128 x, const char *msg)
// {
//     printf("%s: %016lx%016lx\n",msg,(uint64_t)(x>>64),(uint64_t)x);
// }

// void print_u128_dec(uint128 x, const char *msg)
// {
//     char buf[100] = {'\0'};
//     int wlen = 1;
//     while (x > 0) {
//         unsigned int rr = (unsigned int)(x % 10);
//         x /= 10;
//         char c = '0' + (char)rr;
//         buf[100 - wlen - 1] = c;
//         wlen += 1;
//     }
//     printf("%s: %s\n", msg, buf + 100 - wlen);
// }

inline uint128 bytes_be_to_uint128_t(const unsigned char bytes[16])
{
    unsigned long acc[2];
    acc[0] =    (((unsigned long)(bytes[15]) << 0))     |
                (((unsigned long)(bytes[14]) << 8))     |
                (((unsigned long)(bytes[13]) << 16))    |
                (((unsigned long)(bytes[12]) << 24))    |
                (((unsigned long)(bytes[11]) << 32))    |
                (((unsigned long)(bytes[10]) << 40))    |
                (((unsigned long)(bytes[9]) << 48))     |
                (((unsigned long)(bytes[8]) << 56));

    acc[1] =    (((unsigned long)(bytes[7]) << 0))      |
                (((unsigned long)(bytes[6]) << 8))      |
                (((unsigned long)(bytes[5]) << 16))     |
                (((unsigned long)(bytes[4]) << 24))     |
                (((unsigned long)(bytes[3]) << 32))     |
                (((unsigned long)(bytes[2]) << 40))     |
                (((unsigned long)(bytes[1]) << 48))     |
                (((unsigned long)(bytes[0]) << 56));

    uint128 o = (((uint128)acc[1]) << 64) | (((uint128)acc[0]));

    return o;
}

inline void uint128_t_to_bytes_be(uint128 n, unsigned char *bytes) {
    *(bytes + 0) = (unsigned char)((n >> 120));
    *(bytes + 1) = (unsigned char)((n >> 112));
    *(bytes + 2) = (unsigned char)((n >> 104));
    *(bytes + 3) = (unsigned char)((n >> 96));
    *(bytes + 4) = (unsigned char)((n >> 88));
    *(bytes + 5) = (unsigned char)((n >> 80));
    *(bytes + 6) = (unsigned char)((n >> 72));
    *(bytes + 7) = (unsigned char)((n >> 64));
    *(bytes + 8) = (unsigned char)((n >> 56));
    *(bytes + 9) = (unsigned char)((n >> 48));
    *(bytes + 10) = (unsigned char)((n >> 40));
    *(bytes + 11) = (unsigned char)((n >> 32));
    *(bytes + 12) = (unsigned char)((n >> 24));
    *(bytes + 13) = (unsigned char)((n >> 16));
    *(bytes + 14) = (unsigned char)((n >> 8));
    *(bytes + 15) = (unsigned char)((n >> 0));
}

inline void qpow_uv(uint128 *pow_u, uint128 *pow_v, unsigned int radix, int u, int v)
{
    *pow_u = (uint128)1;
    *pow_v = (uint128)1;

    // Since we know that u and v are always equal or
    // within 1 of each other, we can calculate the power
    // exactly once.

    // Calculate the power of the lesser of u and v
    int mul_to = (u > v) ? u : v;
    for (int i = 1; i < mul_to; ++i) {
        *pow_u *= radix;
    }
    *pow_v = *pow_u;

    // And raise up either u or v to the next power,
    // or both if they are equal.
    if (v > u) {
        *pow_v *= radix;
    } else if (u > v) {
        *pow_u *= radix;
    } else {
        *pow_u *= radix;
        *pow_v = *pow_u;
    }
}

#else

// convert numeral string in reverse order to number
void str2num_rev(BIGNUM *Y, const unsigned int *X, unsigned int radix, unsigned int len, BN_CTX *ctx)
{
    BN_CTX_start(ctx);
    BIGNUM *r = BN_CTX_get(ctx),
           *x = BN_CTX_get(ctx);

    BN_set_word(Y, 0);
    BN_set_word(r, radix);
    for (int i = len - 1; i >= 0; --i) {
        // Y = Y * radix + X[i]
        BN_set_word(x, X[i]);
        BN_mul(Y, Y, r, ctx);
        BN_add(Y, Y, x);
    }

    BN_CTX_end(ctx);
    return;
}

// convert number to numeral string in reverse order
void num2str_rev(const BIGNUM *X, unsigned int *Y, unsigned int radix, int len, BN_CTX *ctx)
{
    BN_CTX_start(ctx);
    BIGNUM *dv = BN_CTX_get(ctx),
           *rem = BN_CTX_get(ctx),
           *r = BN_CTX_get(ctx),
           *XX = BN_CTX_get(ctx);

    BN_copy(XX, X);
    BN_set_word(r, radix);
    memset(Y, 0, len << 2);
    
    for (int i = 0; i < len; ++i) {
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

// void print_bn(const BIGNUM *bn, const char *msg)
// {
//     char *bn_str = BN_bn2dec(bn);
//     printf("%s: %s\n", msg, bn_str);
//     OPENSSL_free(bn_str);
// }
#endif


void FF3_encrypt(unsigned int *plaintext, unsigned int *ciphertext, FPE_KEY *key, const unsigned char *tweak, unsigned int txtlen)
{
#ifdef _FPE_FEAT_USE_U128
    uint128 
        qpow_u = (uint128)1,
        qpow_v = (uint128)1;
#else
    BIGNUM *bnum = BN_new(),
           *y = BN_new(),
           *c = BN_new(),
           *anum = BN_new(),
           *qpow_u = BN_new(),
           *qpow_v = BN_new();
    BN_CTX *ctx = BN_CTX_new();
#endif

    // Calculate split point
    int u = ceil2(txtlen, 1);
    int v = txtlen - u;

    // Split the message
    memcpy(ciphertext, plaintext, txtlen << 2); 
    unsigned int *A = ciphertext;
    unsigned int *B = ciphertext + u;

#ifdef _FPE_FEAT_USE_U128
    qpow_uv(&qpow_u, &qpow_v, key->radix, u, v);
#else
    unsigned int temp = (unsigned int)ceil(u * log2(key->radix));
    const int b = ceil2(temp, 3);

    pow_uv(qpow_u, qpow_v, key->radix, u, v, ctx);

    unsigned char *Bytes = (unsigned char *)OPENSSL_malloc(b);
#endif

    unsigned char S[16], P[16];

    for (int round = 0; round < FF3_ROUNDS; ++round) {
        memset(P, 0, 16);

        // i
        unsigned int m;
        if (round & 1) {
            m = v;
            memcpy(P, tweak, 4);
        } else {
            m = u;
            memcpy(P, tweak + 4, 4);
        }
        P[3] ^= round & 0xff;

    #ifdef _FPE_FEAT_USE_U128
        uint128 bnum = str2num_u128_rev(B, key->radix, txtlen - m);

        unsigned char b_bytes[16] = {0};
        uint128_t_to_bytes_be(bnum, b_bytes);
        int i = 4;
        while (i < 16 && b_bytes[i] == 0) { i += 1; }

        memcpy(P + i, b_bytes + i, 16 - i);
    #else
        str2num_rev(bnum, B, key->radix, txtlen - m, ctx);

        memset(Bytes, 0x00, b);
        int BytesLen = BN_bn2bin(bnum, Bytes);
        BytesLen = BytesLen > 12? 12: BytesLen;
        memset(P + 4, 0x00, 12);
        memcpy(P + 16 - BytesLen, Bytes, BytesLen);
    #endif

        // iii
        rev_bytes(P, 16);
        memset(S, 0x00, sizeof(S));
        AES_encrypt(P, S, &key->aes_enc_ctx);
        rev_bytes(S, 16);

    #ifdef _FPE_FEAT_USE_U128
        // iv
        uint128 y = bytes_be_to_uint128_t(S);

        // v
        uint128 c = str2num_u128_rev(A, key->radix, m);
        c += y;
        c %= (round & 1) ? qpow_v : qpow_u;
    #else
        // iv
        BN_bin2bn(S, 16, y);

        // v
        str2num_rev(anum, A, key->radix, m, ctx);
        if (round & 1)    BN_mod_add(c, anum, y, qpow_v, ctx);
        else    BN_mod_add(c, anum, y, qpow_u, ctx);
    #endif

        assert(A != B);
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        B = (unsigned int *)( (uintptr_t)B ^ (uintptr_t)A );
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );

    #ifdef _FPE_FEAT_USE_U128
        num2str_u128_rev(c, B, key->radix, m);
    #else
        num2str_rev(c, B, key->radix, m, ctx);
    #endif

    }

#ifndef _FPE_FEAT_USE_U128
    // free the space
    BN_clear_free(anum);
    BN_clear_free(bnum);
    BN_clear_free(c);
    BN_clear_free(y);
    BN_clear_free(qpow_u);
    BN_clear_free(qpow_v);
    BN_CTX_free(ctx);
    OPENSSL_free(Bytes);
#endif

    return;
}

void FF3_decrypt(unsigned int *ciphertext, unsigned int *plaintext, FPE_KEY *key, const unsigned char *tweak, unsigned int txtlen)
{
#ifdef _FPE_FEAT_USE_U128
    uint128 
        qpow_u = (uint128)1,
        qpow_v = (uint128)1;
#else
    BIGNUM *bnum = BN_new(),
           *y = BN_new(),
           *c = BN_new(),
           *anum = BN_new(),
           *qpow_u = BN_new(),
           *qpow_v = BN_new();
    BN_CTX *ctx = BN_CTX_new();
#endif

    memcpy(plaintext, ciphertext, txtlen << 2);

    // Calculate split point
    int u = ceil2(txtlen, 1);
    int v = txtlen - u;

    // Split the message
    unsigned int *A = plaintext;
    unsigned int *B = plaintext + u;


#ifdef _FPE_FEAT_USE_U128
    qpow_uv(&qpow_u, &qpow_v, key->radix, u, v);
#else
    unsigned int temp = (unsigned int)ceil(u * log2(key->radix));
    const int b = ceil2(temp, 3);

    pow_uv(qpow_u, qpow_v, key->radix, u, v, ctx);

    unsigned char *Bytes = (unsigned char *)OPENSSL_malloc(b);
#endif

    unsigned char S[16], P[16];

    for (int round = FF3_ROUNDS - 1; round >= 0; --round) {
        memset(P, 0, 16);

        // i
        int m;
        if (round & 1) {
            m = v;
            memcpy(P, tweak, 4);
        } else {
            m = u;
            memcpy(P, tweak + 4, 4);
        }
        P[3] ^= round & 0xff;

        // ii

    #ifdef _FPE_FEAT_USE_U128
        uint128 anum = str2num_u128_rev(A, key->radix, txtlen - m);
        unsigned char a_bytes[16] = {0};
        uint128_t_to_bytes_be(anum, a_bytes);
        int i = 4;
        while (i < 16 && a_bytes[i] == 0) { i += 1; }

        memcpy(P + i, a_bytes + i, 16 - i);
    #else
        str2num_rev(anum, A, key->radix, txtlen - m, ctx);
        memset(Bytes, 0x00, b);
        int BytesLen = BN_bn2bin(anum, Bytes);
        BytesLen = BytesLen > 12? 12: BytesLen;
        memset(P + 4, 0x00, 12);
        memcpy(P + 16 - BytesLen, Bytes, BytesLen);
    #endif
       
        // iii
        rev_bytes(P, 16);
        memset(S, 0x00, sizeof(S));
        AES_encrypt(P, S, &key->aes_enc_ctx);
        rev_bytes(S, 16);

    #ifdef _FPE_FEAT_USE_U128
        // iv
        uint128 y = bytes_be_to_uint128_t(S);

        // v
        uint128 c = str2num_u128_rev(B, key->radix, m);

        uint128 qpow = (round & 1) ? qpow_v : qpow_u;

        // since `c` is unsigned, we can't naively subtract
        // `y` from it and do normal modulo arithmetic. Instead,
        // we check if `y` is greater than `c`, and if so, we
        // subtract `c` from `y`, and then use the inverse of
        // the modulo to get the correct value.
        // As an example, imagine the following calculations
        // with untyped numbers:
        //
        // Given: c = 7, y = 94, m = 4
        // c - y = -87; -87 % m = 1;
        // y - c = 87;  87 % m = 3; m - 3 = 1;
        //
        // Note that the modulo should not be inverted
        // if it is 0 because it would be equal to zero if
        // modulo'ed again.
        // Given: m = 4
        // m - 0 = 4; 4 % 4 = 0;
        if (y > c) {
            c = y - c;
            c %= qpow;
            if (c > 0) {
                c = qpow - c;
            }
        } else {
            c -= y;
            c %= qpow;
        }
    #else
        // iv
        BN_bin2bn(S, 16, y);

        // v
        str2num_rev(bnum, B, key->radix, m, ctx);
        if (round & 1)    BN_mod_sub(c, bnum, y, qpow_v, ctx);
        else    BN_mod_sub(c, bnum, y, qpow_u, ctx);
    #endif

        assert(A != B);
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );
        B = (unsigned int *)( (uintptr_t)B ^ (uintptr_t)A );
        A = (unsigned int *)( (uintptr_t)A ^ (uintptr_t)B );

    #ifdef _FPE_FEAT_USE_U128
        num2str_u128_rev(c, A, key->radix, m);
    #else
        num2str_rev(c, A, key->radix, m, ctx);
    #endif

    }

#ifndef _FPE_FEAT_USE_U128
    // free the space
    BN_clear_free(anum);
    BN_clear_free(bnum);
    BN_clear_free(c);
    BN_clear_free(y);
    BN_clear_free(qpow_u);
    BN_clear_free(qpow_v);
    BN_CTX_free(ctx);
    OPENSSL_free(Bytes);
#endif

    return;
}

int create_ff3_key(const unsigned char *userKey, const int bits, const unsigned char *tweak, unsigned int radix, FPE_KEY *key)
{
    int ret;
    if (bits != 128 && bits != 192 && bits != 256) {
        ret = -1;
        return ret;
    }
    key->tweaklen = 64;
    key->tweak = (unsigned char *)OPENSSL_malloc(8);
    memcpy(key->tweak, tweak, 8);
	key->radix = radix;

    unsigned char tmp[32];
    memcpy(tmp, userKey, bits >> 3);
    rev_bytes(tmp, bits >> 3);
    ret = AES_set_encrypt_key(tmp, bits, &key->aes_enc_ctx);
    return ret;
}

FPE_KEY* FPE_ff3_create_key(const char *key, const char *tweak, unsigned int radix)
{
    unsigned char k[100],
                  t[100];
    int klen = strlen(key) / 2;

    hex2chars(key, k);
    hex2chars(tweak, t);

    FPE_KEY *keystruct  = (FPE_KEY *)OPENSSL_malloc(sizeof(FPE_KEY));
    create_ff3_key(k,klen*8,t,radix,keystruct);
    return keystruct;
}


int create_ff3_1_key(const unsigned char *userKey, const int bits, const unsigned char *tweak, unsigned int radix, FPE_KEY *key)
{
    int ret;
    if (bits != 128 && bits != 192 && bits != 256) {
        ret = -1;
        return ret;
    }
    key->tweaklen = 56;
    key->tweak = (unsigned char *)OPENSSL_malloc(7);
    memcpy(key->tweak, tweak, 7);
	key->radix = radix;

    // FF3-1: transform 56-bit to 64-bit tweak
    unsigned char byte = tweak[3];
    key->tweak[3] = (byte & 0xF0);
    key->tweak[7] = (byte & 0x0F) << 4;

    unsigned char tmp[32];
    memcpy(tmp, userKey, bits >> 3);
    rev_bytes(tmp, bits >> 3);
    ret = AES_set_encrypt_key(tmp, bits, &key->aes_enc_ctx);
    return ret;
}

FPE_KEY* FPE_ff3_1_create_key(const char *key, const char *tweak, unsigned int radix)
{
    unsigned char k[100],
                  t[100];
    int klen = strlen(key) / 2;

    hex2chars(key, k);
    hex2chars(tweak, t);

    //display_as_hex("key", k, klen);
    //display_as_hex("tweak", t, 56);

    FPE_KEY *keystruct  = (FPE_KEY *)OPENSSL_malloc(sizeof(FPE_KEY));
    create_ff3_1_key(k,klen*8,t,radix,keystruct);
    return keystruct;
}

void FPE_ff3_delete_key(FPE_KEY *key)
{
    // zero out and then free the tweak and key values
    OPENSSL_clear_free(key->tweak,key->tweaklen/8);
    OPENSSL_clear_free(key,sizeof(key));
}

void FPE_ff3_encrypt(char *plaintext, char *ciphertext, FPE_KEY *key)
{
    int txtlen = strlen(plaintext);
    unsigned int x[100],
                 y[txtlen];
    map_chars(plaintext, x);

    FF3_encrypt(x, y, key, key->tweak, txtlen);

    inverse_map_chars(y, ciphertext, txtlen);
}

void FPE_ff3_decrypt(char *ciphertext, char *plaintext, FPE_KEY *key)
{
    int txtlen = strlen(ciphertext);
    unsigned int x[100],
                 y[txtlen];
    map_chars(ciphertext, x);

    FF3_decrypt(x, y, key, key->tweak, txtlen);

    inverse_map_chars(y, plaintext, txtlen);
}
