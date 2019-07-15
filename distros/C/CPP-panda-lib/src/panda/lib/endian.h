#pragma once
#include <stdint.h>

#ifdef _MSC_VER
#  include <stdlib.h>
#endif

namespace panda { namespace lib {

namespace {
    union _check_endianess { unsigned x; unsigned char c; };
    static const bool _am_i_little = (_check_endianess{1}).c;

#ifdef _MSC_VER

    inline uint16_t bswap16 (uint16_t x) { return _byteswap_ushort(x); }
    inline uint32_t bswap32 (uint32_t x) { return _byteswap_ulong(x); }
    inline uint64_t bswap64 (uint64_t x) { return _byteswap_uint64(x); }

#elif defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3)) && 0

    inline uint16_t bswap16 (uint16_t x) { return __builtin_bswap16(x); }
    inline uint32_t bswap32 (uint32_t x) { return __builtin_bswap32(x); }
    inline uint64_t bswap64 (uint64_t x) { return __builtin_bswap64(x); }

#else

    inline uint16_t bswap16 (uint16_t x) {
        return ((x >> 8) & 0xff) | (x << 8);
    }

    inline uint32_t bswap32 (uint32_t x) {
        return ((x & 0xff000000) >> 24) | ((x & 0x00ff0000) >> 8) | ((x & 0x0000ff00) << 8) | (x << 24);
    }

    inline uint64_t bswap64 (uint64_t x) {
        union { uint64_t u64; uint32_t u32[2]; } v1, v2;
        v1.u64 = x;
        v2.u32[0] = bswap32(v1.u32[1]);
        v2.u32[1] = bswap32(v1.u32[0]);
        return v2.u64;
    }

#endif

}

inline uint16_t h2be16 (uint16_t x) { return _am_i_little ? bswap16(x) : x; }
inline uint16_t h2le16 (uint16_t x) { return _am_i_little ? x : bswap16(x); }
inline uint16_t be2h16 (uint16_t x) { return _am_i_little ? bswap16(x) : x; }
inline uint16_t le2h16 (uint16_t x) { return _am_i_little ? x : bswap16(x); }

inline uint32_t h2be32 (uint32_t x) { return _am_i_little ? bswap32(x) : x; }
inline uint32_t h2le32 (uint32_t x) { return _am_i_little ? x : bswap32(x); }
inline uint32_t be2h32 (uint32_t x) { return _am_i_little ? bswap32(x) : x; }
inline uint32_t le2h32 (uint32_t x) { return _am_i_little ? x : bswap32(x); }

inline uint64_t h2be64 (uint64_t x) { return _am_i_little ? bswap64(x) : x; }
inline uint64_t h2le64 (uint64_t x) { return _am_i_little ? x : bswap64(x); }
inline uint64_t be2h64 (uint64_t x) { return _am_i_little ? bswap64(x) : x; }
inline uint64_t le2h64 (uint64_t x) { return _am_i_little ? x : bswap64(x); }

// just to make templates simpler
inline uint8_t h2be (uint8_t x) { return x; }
inline uint8_t h2le (uint8_t x) { return x; }
inline uint8_t be2h (uint8_t x) { return x; }
inline uint8_t le2h (uint8_t x) { return x; }

inline uint16_t h2be (uint16_t x) { return h2be16(x); }
inline uint16_t h2le (uint16_t x) { return h2le16(x); }
inline uint16_t be2h (uint16_t x) { return be2h16(x); }
inline uint16_t le2h (uint16_t x) { return le2h16(x); }

inline uint32_t h2be (uint32_t x) { return h2be32(x); }
inline uint32_t h2le (uint32_t x) { return h2le32(x); }
inline uint32_t be2h (uint32_t x) { return be2h32(x); }
inline uint32_t le2h (uint32_t x) { return le2h32(x); }

inline uint64_t h2be (uint64_t x) { return h2be64(x); }
inline uint64_t h2le (uint64_t x) { return h2le64(x); }
inline uint64_t be2h (uint64_t x) { return be2h64(x); }
inline uint64_t le2h (uint64_t x) { return le2h64(x); }

}}
