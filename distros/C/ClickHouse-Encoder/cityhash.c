/* CityHash128, v1.0.2 ("cityhash102"). Ported from Google CityHash
 * v1.0.2 (Geoff Pike, Jyrki Alakuijala; MIT license), the same revision
 * ClickHouse keeps under contrib/cityhash102/ and uses for its
 * compressed-block 16-byte checksum.
 *
 * This file only implements CityHash128 (without seed) - the seeded
 * helpers, CityHash64, and the CRC32-accelerated CityHashCrc128 are
 * all skipped because the only ClickHouse-Encoder caller is the
 * CompressedReadBuffer / CompressedWriteBuffer block-prefix hash. */

#include <stdint.h>
#include <string.h>
#include <stddef.h>

#include "cityhash.h"

/* Magic constants from CityHash v1.0.2. */
static const uint64_t k0 = 0xc3a5c85c97cb3127ULL;
static const uint64_t k1 = 0xb492b66fbe98f273ULL;
static const uint64_t k2 = 0x9ae16a3b2f90404fULL;
static const uint64_t k3 = 0xc949d7c7509e6557ULL;

/* Little-endian byte loads via memcpy. On LE hosts the compiler
 * collapses these to a single load; on BE hosts we explicitly byte-
 * swap so the algorithm sees identical integer values across hosts. */
static inline uint64_t Fetch64(const char *p) {
    uint64_t v;
    memcpy(&v, p, 8);
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    v = ((v & 0x00000000000000ffULL) << 56)
      | ((v & 0x000000000000ff00ULL) << 40)
      | ((v & 0x0000000000ff0000ULL) << 24)
      | ((v & 0x00000000ff000000ULL) <<  8)
      | ((v & 0x000000ff00000000ULL) >>  8)
      | ((v & 0x0000ff0000000000ULL) >> 24)
      | ((v & 0x00ff000000000000ULL) >> 40)
      | ((v & 0xff00000000000000ULL) >> 56);
#endif
    return v;
}

static inline uint32_t Fetch32(const char *p) {
    uint32_t v;
    memcpy(&v, p, 4);
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    v = ((v & 0x000000ffU) << 24)
      | ((v & 0x0000ff00U) <<  8)
      | ((v & 0x00ff0000U) >>  8)
      | ((v & 0xff000000U) >> 24);
#endif
    return v;
}

static inline uint64_t Rotate(uint64_t v, int n) {
    /* Reference impl returns `v` unchanged when n == 0 (avoiding UB
     * from `v >> 64`). All call sites pass n in 1..63, but mirror the
     * guard so a future-added caller doesn't trip on it. */
    return n == 0 ? v : ((v >> n) | (v << (64 - n)));
}

static inline uint64_t RotateByAtLeast1(uint64_t v, int n) {
    return (v >> n) | (v << (64 - n));
}

static inline uint64_t ShiftMix(uint64_t v) {
    return v ^ (v >> 47);
}

static inline uint64_t Hash128to64(uint64_t low, uint64_t high) {
    static const uint64_t kMul = 0x9ddfea08eb382d69ULL;
    uint64_t a = (low ^ high) * kMul;
    a ^= (a >> 47);
    uint64_t b = (high ^ a) * kMul;
    b ^= (b >> 47);
    b *= kMul;
    return b;
}

static inline uint64_t HashLen16(uint64_t u, uint64_t v) {
    return Hash128to64(u, v);
}

static uint64_t HashLen0to16(const char *s, size_t len) {
    if (len > 8) {
        uint64_t a = Fetch64(s);
        uint64_t b = Fetch64(s + len - 8);
        return HashLen16(a, RotateByAtLeast1(b + len, (int)len)) ^ b;
    }
    if (len >= 4) {
        uint64_t a = (uint64_t)Fetch32(s);
        return HashLen16(len + (a << 3),
                         (uint64_t)Fetch32(s + len - 4));
    }
    if (len > 0) {
        uint8_t a = (uint8_t)s[0];
        uint8_t b = (uint8_t)s[len >> 1];
        uint8_t c = (uint8_t)s[len - 1];
        uint32_t y = (uint32_t)a + ((uint32_t)b << 8);
        uint32_t z = (uint32_t)len + ((uint32_t)c << 2);
        return ShiftMix((uint64_t)y * k2 ^ (uint64_t)z * k3) * k2;
    }
    return k2;
}

/* Return a 16-byte hash for 32 bytes plus two seed words.
 * Out is written as out[0] = low, out[1] = high. */
static void WeakHashLen32WithSeeds_raw(
        uint64_t w, uint64_t x, uint64_t y, uint64_t z,
        uint64_t a, uint64_t b, uint64_t out[2]) {
    a += w;
    b = Rotate(b + a + z, 21);
    uint64_t c = a;
    a += x;
    a += y;
    b += Rotate(a, 44);
    out[0] = a + z;
    out[1] = b + c;
}

static inline void WeakHashLen32WithSeeds(
        const char *s, uint64_t a, uint64_t b, uint64_t out[2]) {
    WeakHashLen32WithSeeds_raw(Fetch64(s),
                               Fetch64(s + 8),
                               Fetch64(s + 16),
                               Fetch64(s + 24),
                               a, b, out);
}

/* CityMurmur: handles len < 128 inside CityHash128WithSeed. */
static void CityMurmur(const char *s, size_t len,
                       uint64_t seed_low, uint64_t seed_high,
                       uint64_t out[2]) {
    uint64_t a = seed_low;
    uint64_t b = seed_high;
    uint64_t c = 0;
    uint64_t d = 0;
    /* The reference uses `signed long l = len - 16` then `if (l <= 0)`
     * to bifurcate; with `size_t` we test `len <= 16` directly. */
    if (len <= 16) {
        a = ShiftMix(a * k1) * k1;
        c = b * k1 + HashLen0to16(s, len);
        d = ShiftMix(a + (len >= 8 ? Fetch64(s) : c));
    } else {
        c = HashLen16(Fetch64(s + len - 8) + k1, a);
        d = HashLen16(b + len, c + Fetch64(s + len - 16));
        a += d;
        size_t l = len - 16;
        do {
            a ^= ShiftMix(Fetch64(s) * k1) * k1;
            a *= k1;
            b ^= a;
            c ^= ShiftMix(Fetch64(s + 8) * k1) * k1;
            c *= k1;
            d ^= c;
            s += 16;
            l = (l > 16) ? (l - 16) : 0;
        } while (l > 0);
    }
    a = HashLen16(a, c);
    b = HashLen16(d, b);
    out[0] = a ^ b;
    out[1] = HashLen16(b, a);
}

static void CityHash128WithSeed(const char *s, size_t len,
                                uint64_t seed_low, uint64_t seed_high,
                                uint64_t out[2]) {
    if (len < 128) {
        CityMurmur(s, len, seed_low, seed_high, out);
        return;
    }
    /* Long-input path: 56 bytes of rolling state, eats input in
     * 128-byte chunks (two 64-byte halves per loop iteration). */
    uint64_t v[2], w[2];
    uint64_t x = seed_low;
    uint64_t y = seed_high;
    uint64_t z = len * k1;
    v[0] = Rotate(y ^ k1, 49) * k1 + Fetch64(s);
    v[1] = Rotate(v[0], 42) * k1 + Fetch64(s + 8);
    w[0] = Rotate(y + z, 35) * k1 + x;
    w[1] = Rotate(x + Fetch64(s + 88), 53) * k1;

    do {
        x = Rotate(x + y + v[0] + Fetch64(s + 8), 37) * k1;
        y = Rotate(y + v[1] + Fetch64(s + 48), 42) * k1;
        x ^= w[1];
        y ^= v[0];
        z = Rotate(z ^ w[0], 33);
        WeakHashLen32WithSeeds(s,      v[1] * k1, x + w[0], v);
        WeakHashLen32WithSeeds(s + 32, z + w[1], y,         w);
        { uint64_t t = z; z = x; x = t; }
        s += 64;
        x = Rotate(x + y + v[0] + Fetch64(s + 8), 37) * k1;
        y = Rotate(y + v[1] + Fetch64(s + 48), 42) * k1;
        x ^= w[1];
        y ^= v[0];
        z = Rotate(z ^ w[0], 33);
        WeakHashLen32WithSeeds(s,      v[1] * k1, x + w[0], v);
        WeakHashLen32WithSeeds(s + 32, z + w[1], y,         w);
        { uint64_t t = z; z = x; x = t; }
        s += 64;
        len -= 128;
    } while (len >= 128);

    y += Rotate(w[0], 37) * k0 + z;
    x += Rotate(v[0] + z, 49) * k0;
    /* If 0 < len < 128, hash the tail in 32-byte chunks from the END
     * of the input. tail_done starts at 0 and grows by 32 each iter. */
    {
        size_t tail_done = 0;
        while (tail_done < len) {
            tail_done += 32;
            y = Rotate(y - x, 42) * k0 + v[1];
            w[0] += Fetch64(s + len - tail_done + 16);
            x = Rotate(x, 49) * k0 + w[0];
            w[0] += v[0];
            WeakHashLen32WithSeeds(s + len - tail_done,
                                   v[0] + z, v[1], v);
        }
    }
    /* Final mix. */
    x = HashLen16(x, v[0]);
    y = HashLen16(y, w[0]);
    out[0] = HashLen16(x + v[1], w[1]) + y;
    out[1] = HashLen16(x + w[1], y + v[1]);
}

void cityhash128_v102(const char *s, size_t len, unsigned char out[16]) {
    uint64_t hash[2];
    if (len >= 16) {
        CityHash128WithSeed(s + 16, len - 16,
                            Fetch64(s) ^ k3, Fetch64(s + 8),
                            hash);
    } else if (len >= 8) {
        CityHash128WithSeed(NULL, 0,
                            Fetch64(s) ^ ((uint64_t)len * k0),
                            Fetch64(s + len - 8) ^ k1,
                            hash);
    } else {
        CityHash128WithSeed(s, len, k0, k1, hash);
    }
    /* Pack low half then high half as 16 little-endian bytes. */
    int i;
    for (i = 0; i < 8; i++) out[i]     = (unsigned char)(hash[0] >> (i * 8));
    for (i = 0; i < 8; i++) out[8 + i] = (unsigned char)(hash[1] >> (i * 8));
}
