#ifndef CHE_ENCODE_H
#define CHE_ENCODE_H

/* See buffer.h for the include-order convention (EXTERN.h + perl.h +
 * XSUB.h must be included by the caller before this header). */

#include "types.h"
#include "buffer.h"

/* Allocate a transient SV** array of `n` slots, backed by a mortal SV
 * so it gets reclaimed automatically on croak. Used by the per-column
 * gather pass in do_encode and by the variant sub-column collection
 * inside encode_column. */
SV **alloc_sv_array(pTHX_ SSize_t n);

/* Encode `num_rows` values from `values[]` (column-major) of type
 * `t` into the wire-format buffer `b`. Croaks on shape/type errors. */
void encode_column(pTHX_ Buffer *b, SV **values, SSize_t num_rows,
                   TypeInfo *t);

#endif
