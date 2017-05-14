#pragma once
#include <stdint.h>
#include <stddef.h>

namespace panda { namespace lib {

uint64_t hash_murmur64a             (const char* str, size_t len);
uint32_t hash_jenkins_one_at_a_time (const char* str, size_t len);

inline uint64_t hash64 (const char* str, size_t len) { return hash_murmur64a(str, len); }
inline uint32_t hash32 (const char* str, size_t len) { return hash_jenkins_one_at_a_time(str, len); }

namespace {
    template <int T> struct _hashXX;
    template <> struct _hashXX<4> { uint32_t operator() (const char* str, size_t len) { return hash32(str, len); } };
    template <> struct _hashXX<8> { uint64_t operator() (const char* str, size_t len) { return hash64(str, len); } };
}

template <typename T = size_t> inline T hashXX (const char* str, size_t len);
template <> inline unsigned           hashXX<unsigned>           (const char* str, size_t len) { return _hashXX<sizeof(unsigned)>()(str, len); }
template <> inline unsigned long      hashXX<unsigned long>      (const char* str, size_t len) { return _hashXX<sizeof(unsigned long)>()(str, len); }
template <> inline unsigned long long hashXX<unsigned long long> (const char* str, size_t len) { return _hashXX<sizeof(unsigned long long)>()(str, len); }

}}
