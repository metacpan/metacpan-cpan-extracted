// PERL_NO_GET_CONTEXT is not used here, so it's OK to define it after inculding these files
#include "EXTERN.h"
#include "perl.h"

// There are a lot of macro about threads: USE_ITHREADS, USE_5005THREADS, I_PTHREAD, I_MACH_CTHREADS, OLD_PTHREADS_API
// This symbol, if defined, indicates that Perl should be built to use the interpreter-based threading implementation.
#ifndef USE_ITHREADS
#   define PERL_NO_GET_CONTEXT
#endif

#include "XSUB.h"
#include "ppport.h"

#ifdef I_PTHREAD
#   include "pthread.h"
#endif

#ifdef I_MACH_CTHREADS
#   include "mach/cthreads.h"
#endif


/* define int64_t and uint64_t when using MinGW compiler */
#ifdef __MINGW32__
#include <stdint.h>
#endif

/* define int64_t and uint64_t when using MS compiler */
#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

#include "xxhash.h"
#include <inttypes.h>
#include <stdio.h>

#ifdef HAS_INT64_T
#endif

#ifdef CPP
using namespace std;
#endif

MODULE = Crypt::xxHash  PACKAGE = Crypt::xxHash 

PROTOTYPES: DISABLE

U32
xxhash32( const char *input, int length(input), UV seed )
    CODE:
#ifdef CPP
        RETVAL = XXH32(input, STRLEN_length_of_input, move(seed));
#else
        RETVAL = XXH32(input, STRLEN_length_of_input, seed);
#endif
    OUTPUT:
        RETVAL

UV
xxhash64( const char *input, int length(input), UV seed )
    CODE:
#ifdef CPP
        RETVAL = (UV) XXH64(input, STRLEN_length_of_input, move(seed));
#else
        RETVAL = (UV) XXH64(input, STRLEN_length_of_input, seed);
#endif
    OUTPUT:
        RETVAL

UV
xxhash3_64bits( const char *input, int length(input), UV seed )
    CODE:
#ifdef CPP
        RETVAL = (UV) XXH3_64bits_withSeed(input, STRLEN_length_of_input, move(seed));
#else
        RETVAL = (UV) XXH3_64bits_withSeed(input, STRLEN_length_of_input, seed);
#endif
    OUTPUT:
        RETVAL

char*
xxhash32_hex ( const char *input, int length(input), UV seed )
    CODE:
        static char value32[9];
        static const char *format = "%08x";
#ifdef CPP
        sprintf(value32, format, (uint32_t) XXH32(input, STRLEN_length_of_input, move(seed)) );
#else
        sprintf(value32, format, (uint32_t) XXH32(input, STRLEN_length_of_input, seed) );
#endif
        RETVAL = value32;
    OUTPUT:
        RETVAL

char*
xxhash64_hex( const char *input, int length(input), UV seed )
    CODE:
        static char value64[17];
        static const char *format = "%016" PRIx64;
#ifdef CPP
        sprintf(value64, format, (uint64_t) XXH64(input, STRLEN_length_of_input, move(seed)) );
#else
        sprintf(value64, format, (uint64_t) XXH64(input, STRLEN_length_of_input, seed) );
#endif
        RETVAL = value64;
    OUTPUT:
        RETVAL

char*
xxhash3_64bits_hex( const char *input, int length(input), UV seed )
    CODE:
        static char value64[17];
        static const char *format = "%016" PRIx64;
#ifdef CPP
        sprintf(value64, format, (uint64_t) XXH3_64bits_withSeed(input, STRLEN_length_of_input, move(seed)) );
#else
        sprintf(value64, format, (uint64_t) XXH3_64bits_withSeed(input, STRLEN_length_of_input, seed) );
#endif
        RETVAL = value64;
    OUTPUT:
        RETVAL

char*
xxhash3_128bits_hex( const char *input, int length(input), UV seed )
    CODE:
        static char value64[33];
        static const char *format = "%016" PRIx64 "%016" PRIx64;
#ifdef CPP
        XXH128_hash_t hash = XXH3_128bits_withSeed(input, STRLEN_length_of_input, move(seed));
#else
        XXH128_hash_t hash = XXH3_128bits_withSeed(input, STRLEN_length_of_input, seed);
#endif
        sprintf(value64, format, (uint64_t) hash.high64, (uint64_t) hash.low64 );
        RETVAL = value64;
    OUTPUT:
        RETVAL

