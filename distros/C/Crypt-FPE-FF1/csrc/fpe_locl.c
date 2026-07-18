#include <assert.h>
#include "fpe_locl.h"

// quick power: result = x ^ e
void pow_uv(BIGNUM *pow_u, BIGNUM *pow_v, unsigned int x, int u, int v, BN_CTX *ctx)
{
    BN_CTX_start(ctx);
    BIGNUM *base = BN_CTX_get(ctx),
           *e = BN_CTX_get(ctx);

    BN_set_word(base, x);
    if (u > v) {
        BN_set_word(e, v);
        BN_exp(pow_v, base, e, ctx);
        BN_mul(pow_u, pow_v, base, ctx);
    } else {
        BN_set_word(e, u);
        BN_exp(pow_u, base, e, ctx);
        if (u == v)    BN_copy(pow_v, pow_u);
        else    BN_mul(pow_v, pow_u, base, ctx);
    }

    BN_CTX_end(ctx);
    return;

    /*
    // old veresion, classical quick power
    mpz_t temp;
    mpz_init_set_ui(result, 1);
    mpz_init_set_ui(temp, x);
    while (e) {
        if (e & 1)    mpz_mul(result, result, temp);
        mpz_mul(temp, temp, temp);
        e >>= 1;
    }
    mpz_clear(temp);
    return;
    */
}

void hex2chars(const char hex[], unsigned char result[])
{
    int len = strlen(hex);
    char temp[3];
    temp[2] = 0x00;

    int j = 0;
    for (int i = 0; i < len; i += 2) {
        temp[0] = hex[i];
        temp[1] = hex[i + 1];
        result[j] = (char)strtol(temp, NULL, 16);
        ++j;
    }
}

void map_chars(char str[], unsigned int result[])
{
    int len = strlen(str);

    for (int i = 0; i < len; ++i) {
        if (str[i] >= 'a' && str[i] <= 'z') 
            result[i] = str[i] - 'a' + 10;
        else if (str[i] >= 'A' && str[i] <= 'Z') 
            result[i] = str[i] - 'A' + 36;
        else 
            result[i] = str[i] - '0';
    }
}

void inverse_map_chars(unsigned int result[], char str[], int len)
{
    for (int i = 0; i < len; ++i) {
        if (result[i] < 10)
            str[i] = (result[i] + '0');
        else if (result[i] < 36)
            str[i] = result[i] - 10 + 'a';
        else
            str[i] = result[i] - 36 + 'A';
	}
    str[len] = '\0';
}

void display_as_hex(char* name, unsigned char *val, unsigned int vlen) 
{
    printf("%s:",name);
    for (int i = 0; i < vlen; ++i)    printf(" %02x", val[i]);
    puts("");
}
