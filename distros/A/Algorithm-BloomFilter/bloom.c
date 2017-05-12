#include "bloom.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

struct bl_bloom_filter {
  char *bitmap;
  size_t nbytes;
  bl_hash_function_t hash_function;
  unsigned int k;
  unsigned int significant_bits;
  unsigned char shift;
};

#define MAX_VARINT_LENGTH 11
#define BIT_TEST(bitfield, bit) ((bitfield)[(uint64_t)(bit) / 8] & (1 << ((uint64_t)(bit) % 8)))
#define BIT_SET(bitfield, bit) ((bitfield)[(uint64_t)(bit) / 8] |= (1 << ((uint64_t)(bit) % 8)))

/* round up to nearest power of 2 - not efficient, but who cares? */
static inline uint64_t
S_which_power_of_two(uint64_t n)
{
  uint64_t power = 1;
  uint64_t num = 1;
  while(num < n) {
    ++power;
    num *=2;
  }
  return power;
}

bloom_t *
bl_alloc(const size_t n_bits, const unsigned int k_hashes,
         bl_hash_function_t hashfun)
{

  bloom_t *bl = malloc(sizeof(bloom_t));
  if (!bl)
    return NULL;

  bl->significant_bits = (unsigned int)S_which_power_of_two(n_bits);
  bl->shift = 64 - bl->significant_bits;

  bl->nbytes = (1ll << bl->significant_bits) / 8ll;

  bl->bitmap = calloc(sizeof(char), bl->nbytes);
  if (!(bl->bitmap)) {
    free(bl);
    return NULL;
  }

  bl->hash_function = hashfun;
  bl->k = k_hashes;

  return bl;
}


void
bl_free(bloom_t *bl)
{
  free(bl->bitmap);
  free(bl);
}


void
bl_add(bloom_t *bl, const unsigned char *value, const size_t len)
{
  unsigned int i;
  const unsigned int k = bl->k;
  char *bitfield = bl->bitmap;
  const uint64_t l1 = bl_siphash(0, 0, value, len);
  const uint64_t l2 = bl_siphash(1, 0, value, len);

  for (i = 0; i < k; ++i)
  {
    const uint64_t l = (l1 + i*l2) >> bl->shift;
    BIT_SET(bitfield, l);
  }
}


int
bl_test(bloom_t *bl, const unsigned char *value, const size_t len)
{
  unsigned int i;
  const unsigned int k = bl->k;
  char *bitfield = bl->bitmap;
  const uint64_t l1 = bl_siphash(0, 0, value, len);
  const uint64_t l2 = bl_siphash(1, 0, value, len);

  for (i = 0; i < k; ++i)
  {
    const uint64_t l = (l1 + i*l2) >> bl->shift;
    if (! BIT_TEST(bitfield, l) )
      return 0;
  }

  return 1;
}


static void
S_uint64_to_varint(unsigned char **out, uint64_t value) {
  unsigned char *pos = *out;
  while (value >= 0x80) {              /* while we are larger than 7 bits long */
    *pos++ = (value & 0x7f) | 0x80;    /* write out the least significant 7 bits, set the high bit */
    value >>= 7;                       /* shift off the 7 least significant bits */
  }
  *pos++ = (unsigned char)value;       /* encode the last 7 bits without the high bit being set */
  *out = pos;
}

static uint64_t
S_varint_to_uint64_t(unsigned char **in, size_t max_input_len)
{
    uint64_t uv = 0;
    unsigned int lshift = 0;

    unsigned char *pos = *in;
    const unsigned char *end = *in + max_input_len;
    while (pos <= end && *pos & 0x80) {
        uv |= ((uint64_t)(*pos++ & 0x7F) << lshift);
        lshift += 7;
        if (lshift > (sizeof(uint64_t) * 8)) {
            *in = NULL;
            return 0;
        }
    }
    if (pos <= end) {
        uv |= ((uint64_t)*pos++ << lshift);
    } else {
        /* end of packet reached before varint parsed */
        *in = NULL;
        return 0;
    }

    *in = pos;
    return uv;
}


/* may over-allocate a bit */
int
bl_serialize(bloom_t *bl, char **out, size_t *out_len)
{
  /* Format is pretty simple:
   * - varint encoding number of hash functions
   * - varint encoding significant_bits
   * - X bytes - whatever the length in bytes for the bitmap is */

  char *cur;
  char *start;
  const uint64_t plength = MAX_VARINT_LENGTH /* length of packet, this number */
                           + bl->nbytes /* the actual data size */
                           + MAX_VARINT_LENGTH /* k */
                           + MAX_VARINT_LENGTH; /* significant_bits */

  *out_len = (size_t)plength; /* to be revised further down */
  start = cur = malloc(*out_len);
  if (!cur) {
    *out_len = 0;
    *out = 0;
    return 1;
  }
  *out = cur;

  S_uint64_to_varint((unsigned char **)&cur, (uint64_t)bl->k);
  S_uint64_to_varint((unsigned char **)&cur, (uint64_t)bl->significant_bits);

  memcpy(cur, bl->bitmap, bl->nbytes);
  cur += bl->nbytes;

  *out_len = (size_t)(cur-start) + 1;
  return 0;
}


bloom_t *
bl_deserialize(const char *blob, size_t blob_len, bl_hash_function_t hash_function)
{
  bloom_t *bl = NULL;
  const char const *end = blob + blob_len - 1;

  bl = malloc(sizeof(bloom_t));
  if (!bl)
    return NULL;
  bl->hash_function = hash_function;

  bl->k = (unsigned int) S_varint_to_uint64_t((unsigned char **)&blob, (size_t)(end-blob));
  if (blob == NULL) {
    free(bl);
    return NULL;
  }

  bl->significant_bits = (unsigned int) S_varint_to_uint64_t((unsigned char **)&blob, (size_t)(end-blob));
  if (blob == NULL) {
    free(bl);
    return NULL;
  }

  bl->shift = 64 - bl->significant_bits;
  bl->nbytes = end-blob;

  bl->bitmap = malloc(bl->nbytes);
  if (!bl->bitmap) {
    free(bl);
    return NULL;
  }

  memcpy(bl->bitmap, (char *)blob, bl->nbytes);
  blob += bl->nbytes;

  return bl;
}


int
bl_merge(bloom_t *into, const bloom_t * other)
{
  size_t i;
  size_t n;
  char *bf1;
  const char *bf2;

  if (into->k != other->k
      || into->significant_bits != other->significant_bits
      || into->nbytes != other->nbytes /* paranoia */
      || into->hash_function != other->hash_function)
  {
    return 1;
  }

  n = into->nbytes;
  bf1 = into->bitmap;
  bf2 = other->bitmap;
  for (i = 0; i < n; ++i) {
      bf1[i] |= bf2[i];
  }

  return 0;
}


/* Floodyberry's public-domain siphash: https://github.com/floodyberry/siphash */
static inline uint64_t
U8TO64_LE(const unsigned char *p)
{
  return *(const uint64_t *) p;
}

#define ROTL64(a,b) (((a)<<(b))|((a)>>(64-b)))

uint64_t
bl_siphash(uint64_t k0, uint64_t k1, const unsigned char *m, size_t len)
{
  uint64_t v0, v1, v2, v3;
  uint64_t mi;
  uint64_t last7;
  size_t i, blocks;

  v0 = k0 ^ 0x736f6d6570736575ull;
  v1 = k1 ^ 0x646f72616e646f6dull;
  v2 = k0 ^ 0x6c7967656e657261ull;
  v3 = k1 ^ 0x7465646279746573ull;

  last7 = (uint64_t) (len & 0xff) << 56;

#define sipcompress() \
  do { \
    v0 += v1; v2 += v3; \
    v1 = ROTL64(v1,13);  v3 = ROTL64(v3,16); \
    v1 ^= v0; v3 ^= v2; \
    v0 = ROTL64(v0,32); \
    v2 += v1; v0 += v3; \
    v1 = ROTL64(v1,17); v3 = ROTL64(v3,21); \
    v1 ^= v2; v3 ^= v0; \
    v2 = ROTL64(v2,32); \
  } while (0)

  for (i = 0, blocks = (len & ~7); i < blocks; i += 8) {
    mi = U8TO64_LE(m + i);
    v3 ^= mi;
    sipcompress();
    sipcompress();
    v0 ^= mi;
  }

  switch (len - blocks) {
    case 7:
      last7 |= (uint64_t) m[i + 6] << 48;
    case 6:
      last7 |= (uint64_t) m[i + 5] << 40;
    case 5:
      last7 |= (uint64_t) m[i + 4] << 32;
    case 4:
      last7 |= (uint64_t) m[i + 3] << 24;
    case 3:
      last7 |= (uint64_t) m[i + 2] << 16;
    case 2:
      last7 |= (uint64_t) m[i + 1] << 8;
    case 1:
      last7 |= (uint64_t) m[i + 0];
    case 0:
    default:;
  };
  v3 ^= last7;
  sipcompress();
  sipcompress();
  v0 ^= last7;
  v2 ^= 0xff;
  sipcompress();
  sipcompress();
  sipcompress();
  sipcompress();
  return v0 ^ v1 ^ v2 ^ v3;
}

