#ifndef CHE_DECODE_H
#define CHE_DECODE_H

/* See buffer.h for the include-order convention (EXTERN.h + perl.h +
 * XSUB.h must be included by the caller before this header). */

#include "types.h"

/* Read one LEB128 varint from the byte stream, advancing *p. Croaks
 * on truncation or 64-bit overflow. The cursor pair (p, end) lets
 * the caller share one bounds check across many calls. */
UV dec_varint(pTHX_ const unsigned char **p, const unsigned char *end);

/* Read a length-prefixed string: varint length, then `length` raw bytes.
 * `*out_s` points into the same buffer (NOT copied); `*out_len` is the
 * byte length. Caller must not free the returned pointer. */
void dec_lenpfx_string(pTHX_ const unsigned char **p,
                       const unsigned char *end,
                       const char **out_s, STRLEN *out_len);

/* Shared prologue for decode_block / decode_block_rows: validate the
 * input SV, position the cursor at the requested offset, read the
 * block header (ncols + nrows), and run bounds checks. `fname` is
 * embedded in croak messages so each XSUB reports its own name. */
void decode_block_prologue(pTHX_ SV *bytes, UV start_offset,
                           const char *fname,
                           const unsigned char **out_start,
                           const unsigned char **out_p,
                           const unsigned char **out_end,
                           UV *out_ncols, UV *out_nrows);

/* Decode a single column of `nrows` values of type `t`. Returns a
 * mortal RV pointing to an AV; the caller owns the returned SV. */
SV *decode_column(pTHX_ const unsigned char **p,
                  const unsigned char *end,
                  TypeInfo *t, SSize_t nrows);

#endif
