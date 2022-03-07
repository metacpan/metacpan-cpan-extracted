#ifndef CBOR_FREE_COMMON
#define CBOR_FREE_COMMON

#include <stdint.h>

#define CBOR_HALF_FLOAT 0xf9
#define CBOR_FLOAT      0xfa
#define CBOR_DOUBLE     0xfb

#define CBOR_FALSE      0xf4
#define CBOR_TRUE       0xf5
#define CBOR_NULL       0xf6
#define CBOR_UNDEFINED  0xf7

#define CBOR_LENGTH_SMALL       0x18
#define CBOR_LENGTH_MEDIUM      0x19
#define CBOR_LENGTH_LARGE       0x1a
#define CBOR_LENGTH_HUGE        0x1b
#define CBOR_LENGTH_INDEFINITE  0x1f

#define CBOR_TAG_SHAREABLE 28
#define CBOR_TAG_SHAREDREF 29
#define CBOR_TAG_INDIRECTION 22098

#define IS_LITTLE_ENDIAN (BYTEORDER == 0x1234 || BYTEORDER == 0x12345678)
#define IS_64_BIT        (BYTEORDER > 0x10000)

#define CONTROL_BYTE_MAJOR_TYPE_SHIFT 5

#define _CONTROL_BYTE_LENGTH_MASK 0x1f

#define CONTROL_BYTE_LENGTH_TYPE(byte) (((uint8_t) byte) & _CONTROL_BYTE_LENGTH_MASK)
#define CONTROL_BYTE_MAJOR_TYPE(byte) (((uint8_t) byte) >> CONTROL_BYTE_MAJOR_TYPE_SHIFT)

#define _croak croak

/* Compatibility for 5.10.0 --------------------------------------------- */
#ifndef HeUTF8
#   define HeUTF8(he) ((HeKLEN(he) == HEf_SVKEY) ?  \
        SvUTF8(HeKEY_sv(he)) :                      \
        (U32)HeKUTF8(he))
#endif
/* ---------------------------------------------------------------------- */

enum CBOR_TYPE {
    CBOR_TYPE_UINT,
    CBOR_TYPE_NEGINT,
    CBOR_TYPE_BINARY,
    CBOR_TYPE_UTF8,
    CBOR_TYPE_ARRAY,
    CBOR_TYPE_MAP,
    CBOR_TYPE_TAG,
    CBOR_TYPE_OTHER,
};

enum enum_sizetype {
    //tiny = 0,
    small = 1,
    medium = 2,
    large = 4,
    huge = 8,
    indefinite = 255,
};

union anyint {
    uint8_t u8;
    uint16_t u16;
    uint32_t u32;
    uint64_t u64;
};

#define _croak croak

// I32 flags, char **argv
#define _die( flags, argv ) { \
    call_argv( "CBOR::Free::_die", G_EVAL | flags, argv ); \
    _croak(NULL); \
}

SV *cbf_call_scalar_with_arguments( pTHX_ SV* cb, const U8 count, SV** args );
void cbf_die_with_arguments( pTHX_ const U8 count, SV** args );

#endif
