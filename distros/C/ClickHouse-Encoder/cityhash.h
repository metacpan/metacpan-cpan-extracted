#ifndef CHE_CITYHASH_H
#define CHE_CITYHASH_H

/* See buffer.h for the include-order convention (EXTERN.h + perl.h +
 * XSUB.h must be included by the caller before this header). */

#include <stdint.h>
#include <stddef.h>

/* CityHash128, v1.0.2 ("cityhash102"). This is the variant
 * ClickHouse bundles in contrib/cityhash102/ and uses for the
 * 16-byte block checksum at the head of every compressed block.
 *
 * Writes the 128-bit hash into out[0..15] as two little-endian
 * 64-bit halves: out[0..7] is the low half, out[8..15] is the high
 * half. CH's CompressedReadBuffer expects exactly this layout. */
void cityhash128_v102(const char *s, size_t len, unsigned char out[16]);

#endif
