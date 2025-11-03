
// hexsimd.h
#pragma once
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#if defined(_WIN32) || defined(__CYGWIN__)
  #if defined(HEXSIMD_BUILD)
    #define HEXSIMD_API __declspec(dllexport)
  #else
    #define HEXSIMD_API __declspec(dllimport)
  #endif
#else
  #define HEXSIMD_API __attribute__((visibility("default")))
#endif

// Returns number of output bytes/chars written.
// hex_to_bytes: len must be even; returns -1 on strict parse failure.
// bytes_to_hex: out_len must be >= 2*len; returns -1 on failure.
HEXSIMD_API ptrdiff_t hex_to_bytes(const char *src, size_t len, uint8_t *dst, bool strict);
HEXSIMD_API ptrdiff_t bytes_to_hex(const uint8_t *src, size_t len, char *dst);

// Optional: return the chosen implementation names (for debugging).
HEXSIMD_API const char* hexsimd_hex2bin_impl_name(void);
HEXSIMD_API const char* hexsimd_bin2hex_impl_name(void);


