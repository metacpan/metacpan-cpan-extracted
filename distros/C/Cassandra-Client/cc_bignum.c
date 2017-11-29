#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include "cc_bignum.h"

/* I needed a bignum library but couldn't use GMP because I can't assume it's installed everywhere.
   Since the amount of things I need to do is really small, I rolled my own. */

void cc_bignum_init_bytes(struct cc_bignum *bn, unsigned char *bytes, size_t length)
{
    if (length > 0) {
        bn->number = malloc(length);
        bn->length = length;
        memcpy(bn->number, bytes, length);
        if (bn->number[length-1] & 0x80) {
            int i;
            for (i = 0; i < bn->length; i++) {
                bn->number[i] = ~bn->number[i];
            }
            bn->is_negative = 1;
            cc_bignum_add(bn, 1);
        } else {
            bn->is_negative = 0;
        }
    } else {
        bn->number = calloc(1, 1);
        bn->length = 1;
        bn->is_negative = 0;
    }
}

void cc_bignum_init_string(struct cc_bignum *bn, char *string, size_t length)
{
    size_t pos = 0;

    bn->number = calloc(1, 1);
    bn->length = 1;
    bn->is_negative = 0;

    if (string[pos] == '-') {
        pos++;
        bn->is_negative = 1;
    } else if (string[pos] == '+') {
        pos++;
    }

    for (; pos < length; pos++) {
        cc_bignum_mul(bn, 10);
        cc_bignum_add(bn, string[pos]-'0');
    }
}

void cc_bignum_destroy(struct cc_bignum *bn)
{
    if (bn->number)
        free(bn->number);
    bn->number = NULL;
}

void cc_bignum_copy(struct cc_bignum *out, struct cc_bignum *in)
{
    out->length = in->length;
    out->number = calloc(1, in->length);
    memcpy(out->number, in->number, in->length);
    out->is_negative = in->is_negative;
}

void cc_bignum_move(struct cc_bignum *out, struct cc_bignum *in)
{
    out->length = in->length;
    out->number = in->number;
    out->is_negative = in->is_negative;
    in->number = NULL;
    in->length = 0;
    in->is_negative = 0;
}

/*  https://stackoverflow.com/a/10525503 */
uint32_t cc_bignum_divide_8bit(struct cc_bignum *n, uint8_t d, struct cc_bignum *out)
{
    size_t i;
    uint32_t temp;

    temp = 0;
    out->number = calloc(1, n->length);
    i = n->length;
    while (i > 0) {
        i--;
        temp <<= 8;
        temp |= n->number[i];
        out->number[i] = temp / d;
        temp -= out->number[i] * d;
    }

    out->length = n->length;
    out->is_negative = n->is_negative;

    /* Probably not correct when the number is negative. But good enough for our use cases. */
    return temp;
}

void cc_bignum_mul(struct cc_bignum *n, uint8_t mul)
{
    size_t i;
    uint32_t temp;

    temp = 0;
    i = 0;
    while (i < n->length) {
        temp += (n->number[i] * mul);
        n->number[i] = temp % 256;
        temp >>= 8;
        i++;
    }
    if (temp) {
        assert(temp < 256);
        n->length++;
        n->number = realloc(n->number, n->length);
        n->number[i] = temp;
    }
}

void cc_bignum_add(struct cc_bignum *n, uint8_t howmuch)
{
    int i;
    uint8_t carry;
    carry = howmuch;
    if (!carry)
        return;
    for (i = 0; i < n->length; i++) {
        if (n->number[i] < 256-carry) {
            n->number[i] += carry;
            return;
        } else {
            n->number[i] += carry;
            carry = 1;
        }
    }
    n->number = realloc(n->number, n->length+1);
    n->length++;
    n->number[i] = carry;
}

int cc_bignum_is_zero(struct cc_bignum *n)
{
    int i;
    if (n->length == 1 && n->number[0] == 0)
        return 1;
    for (i = 0; i < n->length; i++) {
        if (n->number[i] != 0)
            return 0;
    }
    return 1;
}

/*
  void cc_bignum_dump(struct cc_bignum *bn)
  {
      int i;
      printf("BN: ");
      for (i = 0; i < bn->length; i++) {
          printf("%.2x ", bn->number[i]);
      }
      printf("\n");
  }
*/

void cc_bignum_stringify(struct cc_bignum *bn, char *out, size_t outlen)
{
    struct cc_bignum cur;
    size_t i, j, tmp_buf_len;
    char *tmp_buf;

    if (cc_bignum_is_zero(bn)) {
        out[0] = '0';
        out[1] = 0;
        assert(outlen >= 2);
        return;
    }

    tmp_buf_len = bn->length*4 + 2;
    tmp_buf = calloc(1, tmp_buf_len);

    cc_bignum_copy(&cur, bn);
    i = 0;

    while (!cc_bignum_is_zero(&cur)) {
        struct cc_bignum new;
        uint8_t remain = cc_bignum_divide_8bit(&cur, 10, &new);
        cc_bignum_destroy(&cur);
        cc_bignum_move(&cur, &new);
        tmp_buf[i++] = '0' + remain;
        assert(i < tmp_buf_len);
    }

    if (bn->is_negative)
        tmp_buf[i++] = '-';

    assert(i < outlen);

    for (j = 0; j < i; j++) {
        out[j] = tmp_buf[i-j-1];
    }
    out[i] = 0;

    free(tmp_buf);
    cc_bignum_destroy(&cur);
}

size_t cc_bignum_byteify(struct cc_bignum *bn, unsigned char *out, size_t outlen)
{
    struct cc_bignum copy;
    size_t needed_bytes;
    cc_bignum_copy(&copy, bn);

    assert(copy.length < outlen);

    if (copy.is_negative) {
        int i;
        for (i = 0; i < copy.length; i++) {
            copy.number[i] = ~copy.number[i];
        }
        cc_bignum_add(&copy, 1);
        out[copy.length] = 0xff;
    } else {
        out[copy.length] = 0;
    }

    memcpy(out, copy.number, copy.length);

    needed_bytes = copy.length+1;
    while (needed_bytes > 1) {
        if (out[needed_bytes-1] == out[copy.length]) {
            if ((out[needed_bytes-1]&0x80) == (out[needed_bytes-2]&0x80)) {
                needed_bytes--;
                continue;
            }
        }
        break;
    }

    cc_bignum_destroy(&copy);

    return needed_bytes;
}
