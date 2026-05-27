#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdint.h>

#include "buffer.h"

void buf_init(pTHX_ Buffer *b) {
    b->sv = sv_2mortal(newSVpvn("", 0));
    SvGROW(b->sv, 256);
    b->ptr = SvPVX(b->sv);
    b->len = 0;
    b->cap = SvLEN(b->sv) - 1;
}

void buf_grow(pTHX_ Buffer *b, STRLEN need) {
    if (b->len + need > b->cap) {
        STRLEN newcap = b->cap ? b->cap : 256;
        while (b->len + need > newcap) newcap *= 2;
        SvGROW(b->sv, newcap + 1);
        b->ptr = SvPVX(b->sv);
        b->cap = SvLEN(b->sv) - 1;
    }
}

void buf_append(pTHX_ Buffer *b, const char *data, STRLEN len) {
    buf_grow(aTHX_ b, len);
    memcpy(b->ptr + b->len, data, len);
    b->len += len;
}

void buf_byte(pTHX_ Buffer *b, uint8_t v) {
    buf_grow(aTHX_ b, 1);
    b->ptr[b->len++] = (char)v;
}

void buf_le16(pTHX_ Buffer *b, uint16_t v) {
    buf_grow(aTHX_ b, 2);
    b->ptr[b->len++] = (char)(v & 0xff);
    b->ptr[b->len++] = (char)((v >> 8) & 0xff);
}

void buf_le32(pTHX_ Buffer *b, uint32_t v) {
    buf_grow(aTHX_ b, 4);
    b->ptr[b->len++] = (char)(v & 0xff);
    b->ptr[b->len++] = (char)((v >> 8) & 0xff);
    b->ptr[b->len++] = (char)((v >> 16) & 0xff);
    b->ptr[b->len++] = (char)((v >> 24) & 0xff);
}

void buf_le64(pTHX_ Buffer *b, uint64_t v) {
    int i;
    buf_grow(aTHX_ b, 8);
    for (i = 0; i < 8; i++) b->ptr[b->len++] = (char)((v >> (i * 8)) & 0xff);
}

void buf_lefloat(pTHX_ Buffer *b, float f) {
    uint32_t v;
    memcpy(&v, &f, 4);
    buf_le32(aTHX_ b, v);
}

void buf_ledouble(pTHX_ Buffer *b, double d) {
    uint64_t v;
    memcpy(&v, &d, 8);
    buf_le64(aTHX_ b, v);
}

void buf_varint(pTHX_ Buffer *b, UV n) {
    buf_grow(aTHX_ b, 10);
    while (n >= 0x80) {
        b->ptr[b->len++] = (char)((n & 0x7f) | 0x80);
        n >>= 7;
    }
    b->ptr[b->len++] = (char)n;
}

void buf_string(pTHX_ Buffer *b, const char *s, STRLEN len) {
    buf_varint(aTHX_ b, len);
    buf_append(aTHX_ b, s, len);
}
