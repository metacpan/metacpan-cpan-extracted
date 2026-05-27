#ifndef CHE_BUFFER_H
#define CHE_BUFFER_H

/* Include order: callers must already have included EXTERN.h + perl.h
 * + XSUB.h (the SV/STRLEN/UV typedefs and pTHX_ macros come from there).
 * This header intentionally does not include perl.h itself so that
 * PERL_NO_GET_CONTEXT can be defined consistently in each .c file. */

/* Append-only byte buffer backed by a mortal SV - auto-freed on croak.
 * Used to assemble Native-format wire bytes during encode. The SV's
 * SvLEN is the underlying allocation; SvCUR is left at 0 until we
 * "publish" the buffer back into an SV (sv_setpvn at end of encode). */
typedef struct {
    SV *sv;
    char *ptr;
    STRLEN len;
    STRLEN cap;
} Buffer;

void buf_init    (pTHX_ Buffer *b);
void buf_grow    (pTHX_ Buffer *b, STRLEN need);
void buf_append  (pTHX_ Buffer *b, const char *data, STRLEN len);
void buf_byte    (pTHX_ Buffer *b, uint8_t v);
void buf_le16    (pTHX_ Buffer *b, uint16_t v);
void buf_le32    (pTHX_ Buffer *b, uint32_t v);
void buf_le64    (pTHX_ Buffer *b, uint64_t v);
void buf_lefloat (pTHX_ Buffer *b, float f);
void buf_ledouble(pTHX_ Buffer *b, double d);
void buf_varint  (pTHX_ Buffer *b, UV n);
void buf_string  (pTHX_ Buffer *b, const char *s, STRLEN len);

#endif
