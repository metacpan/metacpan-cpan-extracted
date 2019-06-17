#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>

// For ntohs and ntohl
#include <arpa/inet.h>

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

#define BOOLEAN_CLASS   "Types::Serialiser::Boolean"
#define TAGGED_CLASS    "CBOR::Free::Tagged"

#define MAX_ENCODE_RECURSE 98

#define ENCODE_ALLOC_CHUNK_SIZE 1024

#define IS_LITTLE_ENDIAN (BYTEORDER == 0x1234 || BYTEORDER == 0x12345678)
#define IS_64_BIT        (BYTEORDER > 0x10000)

static const unsigned char NUL = 0;
static const unsigned char CBOR_NULL_U8  = CBOR_NULL;
static const unsigned char CBOR_FALSE_U8 = CBOR_FALSE;
static const unsigned char CBOR_TRUE_U8  = CBOR_TRUE;

static const unsigned char CBOR_INF_SHORT[3] = { 0xf9, 0x7c, 0x00 };
static const unsigned char CBOR_NAN_SHORT[3] = { 0xf9, 0x7e, 0x00 };
static const unsigned char CBOR_NEGINF_SHORT[3] = { 0xf9, 0xfc, 0x00 };

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

static HV *boolean_stash;
static HV *tagged_stash;

static const char* UV_TO_STR_TMPL = sizeof(UV) == 8 ? "%llu" : "%lu";
static const char* IV_TO_STR_TMPL = sizeof(UV) == 8 ? "%lld" : "%ld";

//----------------------------------------------------------------------
// Definitions

typedef struct {
    char *buffer;
    STRLEN buflen;
    STRLEN len;
    uint8_t recurse_count;
    uint8_t scratch[9];
    bool is_canonical;
} encode_ctx;

typedef struct {
    char* start;
    STRLEN size;
    char* curbyte;
    char* end;

    union {
        uint8_t bytes[30];  // used for num -> key conversions
        float as_float;
        double as_double;
    } scratch;
} decode_ctx;

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

union control_byte {
    uint8_t u8;

    struct {
        unsigned int length_type : 5;
        unsigned int major_type : 3;
    } pieces;
};

//----------------------------------------------------------------------
// Prototypes
// TODO: Be C99-compliant.

SV *_decode( pTHX_ decode_ctx* decstate );

//----------------------------------------------------------------------

UV _uv_to_str(UV num, char *numstr, const char strlen) {
    return my_snprintf( numstr, strlen, UV_TO_STR_TMPL, num );
}

UV _iv_to_str(IV num, char *numstr, const char strlen) {
    return my_snprintf( numstr, strlen, IV_TO_STR_TMPL, num );
}

#define _croak croak

void _die( pTHX_ I32 flags, char **argv ) {
    call_argv( "CBOR::Free::_die", G_EVAL | flags, argv );

    _croak(NULL);
}

void _croak_unrecognized(pTHX_ SV *value) {
    char * words[3] = { "Unrecognized", SvPV_nolen(value), NULL };

    _die( aTHX_ G_DISCARD, words );
}

void _croak_incomplete( pTHX_ STRLEN lack ) {
    char lackstr[24];
    _uv_to_str( lack, lackstr, sizeof(lackstr) );

    char * words[3] = { "Incomplete", lackstr, NULL };

    _die( aTHX_ G_DISCARD, words );
}

void _croak_invalid_control( pTHX_ decode_ctx* decstate ) {
    const uint8_t ord = (uint8_t) *(decstate->curbyte);
    STRLEN offset = decstate->curbyte - decstate->start;

    char ordstr[24];
    char offsetstr[24];

    _uv_to_str(ord, ordstr, sizeof(ordstr));
    _uv_to_str(offset, offsetstr, sizeof(offsetstr));

    char * words[] = { "InvalidControl", ordstr, offsetstr, NULL };

    _die( aTHX_ G_DISCARD, words );
}

void _croak_invalid_utf8( pTHX_ char *string ) {
    char * words[3] = { "InvalidUTF8", string, NULL };

    _die( aTHX_ G_DISCARD, words);
}

void _croak_invalid_map_key( pTHX_ const uint8_t byte, STRLEN offset ) {
    char bytebuf[5];

    char *bytestr;

    switch (byte) {
        case CBOR_FALSE:
            bytestr = "false";
            break;
        case CBOR_TRUE:
            bytestr = "true";
            break;
        case CBOR_NULL:
            bytestr = "null";
            break;
        case CBOR_UNDEFINED:
            bytestr = "undefined";
            break;
        default:
            switch ((byte & 0xe0) >> 5) {
                case CBOR_TYPE_ARRAY:
                    bytestr = "array";
                    break;
                case CBOR_TYPE_MAP:
                    bytestr = "map";
                    break;
                default:
                    my_snprintf( bytebuf, 5, "0x%02x", byte );
                    bytestr = bytebuf;
            }
    }

    char offsetstr[20];
    _uv_to_str( offset, offsetstr, sizeof(offsetstr) );

    char * words[] = { "InvalidMapKey", bytestr, offsetstr, NULL };

    _die( aTHX_ G_DISCARD, words);
}

void _croak_cannot_decode_64bit( pTHX_ const uint8_t *u64bytes, STRLEN offset ) {
    char numhex[20];
    numhex[19] = 0;

    my_snprintf( numhex, 20, "%02x%02x_%02x%02x_%02x%02x_%02x%02x", u64bytes[0], u64bytes[1], u64bytes[2], u64bytes[3], u64bytes[4], u64bytes[5], u64bytes[6], u64bytes[7] );

    char offsetstr[20];
    _uv_to_str( offset, offsetstr, sizeof(offsetstr) );

    char * words[] = { "CannotDecode64Bit", numhex, offsetstr, NULL };

    _die( aTHX_ G_DISCARD, words );
}

void _croak_cannot_decode_negative( pTHX_ UV abs, STRLEN offset ) {
    char absstr[40];
    _uv_to_str( abs, absstr, sizeof(absstr) );

    char offsetstr[20];
    _uv_to_str( offset, offsetstr, sizeof(offsetstr) );

    char * words[] = { "NegativeIntTooLow", absstr, offsetstr, NULL };

    _die( aTHX_ G_DISCARD, words );
}

#define _DECODE_CHECK_FOR_OVERAGE( decstate, len) \
    if ((len + decstate->curbyte) > decstate->end) { \
        _croak_incomplete( aTHX_ (len + decstate->curbyte) - decstate->end ); \
    }


//----------------------------------------------------------------------

static inline void _COPY_INTO_ENCODE( encode_ctx *encode_state, const unsigned char *hdr, STRLEN len) {
    if ( (len + encode_state->len) > encode_state->buflen ) {
        Renew( encode_state->buffer, encode_state->buflen + len + ENCODE_ALLOC_CHUNK_SIZE, char );
        encode_state->buflen += len + ENCODE_ALLOC_CHUNK_SIZE;
    }

    Copy( hdr, encode_state->buffer + encode_state->len, len, char );
    encode_state->len += len;
}

//----------------------------------------------------------------------

// These encode num as big-endian into buffer.
// Importantly, on big-endian systems this is just a memcpy,
// while on little-endian systems it’s a bswap.

static inline void _u16_to_buffer( UV num, uint8_t *buffer ) {
    *(buffer++) = num >> 8;
    *(buffer++) = num;
}

static inline void _u32_to_buffer( UV num, unsigned char *buffer ) {
    *(buffer++) = num >> 24;
    *(buffer++) = num >> 16;
    *(buffer++) = num >> 8;
    *(buffer++) = num;
}

static inline void _u64_to_buffer( UV num, unsigned char *buffer ) {
    *(buffer++) = num >> 56;
    *(buffer++) = num >> 48;
    *(buffer++) = num >> 40;
    *(buffer++) = num >> 32;
    *(buffer++) = num >> 24;
    *(buffer++) = num >> 16;
    *(buffer++) = num >> 8;
    *(buffer++) = num;
}

// Basically ntohll(), but it accepts a pointer.
static inline UV _buffer_u64_to_uv( unsigned char *buffer ) {
    UV num = 0;

#if IS_64_BIT
    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);
    num <<= 8;
#else
    buffer += 4;
#endif

    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);
    num <<= 8;

    num |= *(buffer++);

    return num;
}

//----------------------------------------------------------------------

// NOTE: Contrary to what we’d ordinarily expect, for canonical CBOR
// keys are only byte-sorted if their lengths are identical. Thus,
// “z” sorts EARLIER than “aa”. (cf. section 3.9 of the RFC)
I32 sortstring( pTHX_ SV *a, SV *b ) {
    return (SvCUR(a) < SvCUR(b)) ? -1 : (SvCUR(a) > SvCUR(b)) ? 1 : memcmp( SvPV_nolen(a), SvPV_nolen(b), SvCUR(a) );
}

//----------------------------------------------------------------------

// TODO? This could be a macro … it’d just be kind of unwieldy as such.
static inline void _init_length_buffer( pTHX_ UV num, enum CBOR_TYPE major_type, encode_ctx *encode_state ) {
    union control_byte *scratch0 = (void *) encode_state->scratch;
    scratch0->pieces.major_type = major_type;

    if ( num < CBOR_LENGTH_SMALL ) {
        scratch0->pieces.length_type = (uint8_t) num;

        _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 1);
    }
    else if ( num <= 0xff ) {
        scratch0->pieces.length_type = CBOR_LENGTH_SMALL;
        encode_state->scratch[1] = (uint8_t) num;

        _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 2);
    }
    else if ( num <= 0xffff ) {
        scratch0->pieces.length_type = CBOR_LENGTH_MEDIUM;

        _u16_to_buffer( num, 1 + encode_state->scratch );

        _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 3);
    }
    else if ( num <= 0xffffffffU ) {
        scratch0->pieces.length_type = CBOR_LENGTH_LARGE;

        _u32_to_buffer( num, 1 + encode_state->scratch );

        _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 5);
    }
    else {
        scratch0->pieces.length_type = CBOR_LENGTH_HUGE;

        _u64_to_buffer( num, 1 + encode_state->scratch );

        _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 9);
    }
}

void _encode( pTHX_ SV *value, encode_ctx *encode_state ) {
    ++encode_state->recurse_count;

    if (encode_state->recurse_count > MAX_ENCODE_RECURSE) {

        // call_pv() killed the process in Win32; this seems to fix that.
        static char * words[] = { NULL };
        call_argv("CBOR::Free::_die_recursion", G_EVAL|G_DISCARD, words);

        _croak(NULL);
    }

    if (!SvROK(value)) {

        if (SvIOK(value)) {
            IV val = SvIVX(value);

            // In testing, Perl’s (0 + ~0) evaluated as < 0 here,
            // but the SvUOK() check fixes that.
            if (val < 0 && !SvUOK(value)) {
                _init_length_buffer( aTHX_ -(++val), CBOR_TYPE_NEGINT, encode_state );
            }
            else {
                // NB: SvUOK doesn’t work to identify nonnegatives … ?
                _init_length_buffer( aTHX_ val, CBOR_TYPE_UINT, encode_state );
            }
        }
        else if (SvNOK(value)) {
            NV val_nv = SvNVX(value);

            if (Perl_isnan(val_nv)) {
                _COPY_INTO_ENCODE(encode_state, CBOR_NAN_SHORT, 3);
            }
            else if (Perl_isinf(val_nv)) {
                if (val_nv > 0) {
                    _COPY_INTO_ENCODE(encode_state, CBOR_INF_SHORT, 3);
                }
                else {
                    _COPY_INTO_ENCODE(encode_state, CBOR_NEGINF_SHORT, 3);
                }
            }
            else {

                // Typecast to a double to accommodate long-double perls.
                double val = (double) val_nv;

                char *valptr = (char *) &val;

#if IS_LITTLE_ENDIAN
                encode_state->scratch[0] = CBOR_DOUBLE;
                encode_state->scratch[1] = valptr[7];
                encode_state->scratch[2] = valptr[6];
                encode_state->scratch[3] = valptr[5];
                encode_state->scratch[4] = valptr[4];
                encode_state->scratch[5] = valptr[3];
                encode_state->scratch[6] = valptr[2];
                encode_state->scratch[7] = valptr[1];
                encode_state->scratch[8] = valptr[0];

                _COPY_INTO_ENCODE(encode_state, encode_state->scratch, 9);
#else
                char bytes[9] = { CBOR_DOUBLE, valptr[0], valptr[1], valptr[2], valptr[3], valptr[4], valptr[5], valptr[6], valptr[7] };
                _COPY_INTO_ENCODE(encode_state, bytes, 9);
#endif
            }
        }
        else if (!SvOK(value)) {
            _COPY_INTO_ENCODE(encode_state, &CBOR_NULL_U8, 1);
        }
        else {
            char *val = SvPOK(value) ? SvPVX(value) : SvPV_nolen(value);

            STRLEN len = SvCUR(value);

            bool encode_as_text = !!SvUTF8(value);

            /*
            if (!encode_as_text) {
                STRLEN i;
                for (i=0; i<len; i++) {
                    if (val[i] & 0x80) break;
                }

                // Encode as text if there were no high-bit octets.
                encode_as_text = (i == len);
            }
            */

            _init_length_buffer( aTHX_
                len,
                (encode_as_text ? CBOR_TYPE_UTF8 : CBOR_TYPE_BINARY),
                encode_state
            );

            _COPY_INTO_ENCODE( encode_state, (unsigned char *) val, len );
        }
    }
    else if (sv_isobject(value)) {
        HV *stash = SvSTASH ( SvRV(value) );

        if (boolean_stash == stash) {
            _COPY_INTO_ENCODE(
                encode_state,
                SvTRUE(SvRV(value)) ? &CBOR_TRUE_U8 : &CBOR_FALSE_U8,
                1
            );
        }
        else if (tagged_stash == stash) {
            AV *array = (AV *)SvRV(value);
            SV **tag = av_fetch(array, 0, 0);
            IV tagnum = SvIV(*tag);

            _init_length_buffer( aTHX_ tagnum, CBOR_TYPE_TAG, encode_state );
            _encode( aTHX_ *(av_fetch(array, 1, 0)), encode_state );
        }

        // TODO: Support TO_JSON() method?

        else _croak_unrecognized(aTHX_ value);
    }
    else if (SVt_PVAV == SvTYPE(SvRV(value))) {
        AV *array = (AV *)SvRV(value);
        SSize_t len;
        len = 1 + av_len(array);

        _init_length_buffer( aTHX_ len, CBOR_TYPE_ARRAY, encode_state );

        SSize_t i;

        SV **cur;
        for (i=0; i<len; i++) {
            cur = av_fetch(array, i, 0);
            _encode( aTHX_ *cur, encode_state );
        }
    }
    else if (SVt_PVHV == SvTYPE(SvRV(value))) {
        HV *hash = (HV *)SvRV(value);

        char *key;
        I32 key_length;
        SV *cur;

        I32 keyscount = hv_iterinit(hash);

        _init_length_buffer( aTHX_ keyscount, CBOR_TYPE_MAP, encode_state );

        if (encode_state->is_canonical) {
            SV *keys[keyscount];

            I32 curkey = 0;

            while (hv_iternextsv(hash, &key, &key_length)) {
                keys[curkey] = newSVpvn(key, key_length);
                ++curkey;
            }

            sortsv(keys, keyscount, sortstring);

            for (curkey=0; curkey < keyscount; ++curkey) {
                cur = keys[curkey];
                key = SvPV_nolen(cur);
                key_length = SvCUR(cur);

                // Store the key.
                _init_length_buffer( aTHX_ key_length, CBOR_TYPE_BINARY, encode_state );
                _COPY_INTO_ENCODE( encode_state, (unsigned char *) key, key_length );

                cur = *( hv_fetch(hash, key, key_length, 0) );

                _encode( aTHX_ cur, encode_state );
            }
        }
        else {
            while ((cur = hv_iternextsv(hash, &key, &key_length))) {

                // Store the key.
                _init_length_buffer( aTHX_ key_length, CBOR_TYPE_BINARY, encode_state );

                _COPY_INTO_ENCODE( encode_state, (unsigned char *) key, key_length );

                _encode( aTHX_ cur, encode_state );
            }
        }
    }
    else {
        _croak_unrecognized(aTHX_ value);
    }

    --encode_state->recurse_count;
}

//----------------------------------------------------------------------
// DECODER:
//----------------------------------------------------------------------

static inline UV _parse_for_uint_len2( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    UV ret;

    switch (control->pieces.length_type) {
        case CBOR_LENGTH_SMALL:

            _DECODE_CHECK_FOR_OVERAGE( decstate, 2);

            ++decstate->curbyte;

            ret = (uint8_t) decstate->curbyte[0];

            ++decstate->curbyte;

            break;

        case CBOR_LENGTH_MEDIUM:
            _DECODE_CHECK_FOR_OVERAGE( decstate, 3);

            ++decstate->curbyte;

            ret = ntohs( *((uint16_t *) decstate->curbyte) );

            decstate->curbyte += 2;

            break;

        case CBOR_LENGTH_LARGE:
            _DECODE_CHECK_FOR_OVERAGE( decstate, 5);

            ++decstate->curbyte;

            ret = ntohl( *((uint32_t *) decstate->curbyte) );

            decstate->curbyte += 4;

            break;

        case CBOR_LENGTH_HUGE:
            _DECODE_CHECK_FOR_OVERAGE( decstate, 9);

            ++decstate->curbyte;

#if !IS_64_BIT

            if (decstate->curbyte[0] || decstate->curbyte[1] || decstate->curbyte[2] || decstate->curbyte[3]) {
                _croak_cannot_decode_64bit( aTHX_ (const uint8_t *) decstate->curbyte, decstate->curbyte - decstate->start );
            }
#endif
            ret = _buffer_u64_to_uv( (uint8_t *) decstate->curbyte );

            decstate->curbyte += 8;

            break;

        case 0x1c:
        case 0x1d:
        case 0x1e:
        case 0x1f:  // indefinite must be handled outside this function.
            _croak_invalid_control( aTHX_ decstate );
            break;

        default:
            ret = (uint8_t) control->pieces.length_type;

            decstate->curbyte++;
    }

    return ret;
}

//----------------------------------------------------------------------

SV *_decode_array( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    AV *array = newAV();
    SV *cur = NULL;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        while (*(decstate->curbyte) != '\xff') {

            cur = _decode( aTHX_ decstate );
            av_push(array, cur);
            //sv_2mortal(cur);
        }

        _DECODE_CHECK_FOR_OVERAGE( decstate, 1 );

        ++decstate->curbyte;
    }
    else {
        SSize_t array_length = _parse_for_uint_len2( aTHX_ decstate );

        if (array_length) {
            av_fill(array, array_length - 1);

            SSize_t i;
            for (i=0; i<array_length; i++) {
                cur = _decode( aTHX_ decstate );

                if (!av_store(array, i, cur)) {
                    _croak("Failed to store item in array!");
                }
            }
        }
    }

    return newRV_noinc( (SV *) array);
}

//----------------------------------------------------------------------

struct numbuf {
    union {
        UV uv;
        IV iv;
    } num;

    char *buffer;
};

UV _decode_uint( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        _croak_invalid_control( aTHX_ decstate );
    }

    return _parse_for_uint_len2( aTHX_ decstate );
}

IV _decode_negint( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        _croak_invalid_control( aTHX_ decstate );
    }

    UV positive = _parse_for_uint_len2( aTHX_ decstate );

#if IS_64_BIT
    if (positive >= 0x8000000000000000U) {
        _croak_cannot_decode_negative( aTHX_ positive, decstate->curbyte - decstate->start - 8 );
    }
#else
    if (positive >= 0x80000000U) {
        STRLEN offset = decstate->curbyte - decstate->start;

        if (control->pieces.length_type == 0x1a) {
            offset -= 4;
        }
        else {
            offset -= 8;
        }

        _croak_cannot_decode_negative( aTHX_ positive, offset );
    }
#endif

    return( -1 - (int64_t) positive );
}

struct numbuf _decode_str( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    struct numbuf ret;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        //TODO: Parse it as a string, not an SV.
        SV *tempsv = newSVpvs("");

        while (*(decstate->curbyte) != '\xff') {
            //TODO: Require the same major type.

            SV *cur = _decode( aTHX_ decstate );

            sv_catsv(tempsv, cur);
        }

        _DECODE_CHECK_FOR_OVERAGE( decstate, 1 );

        ++decstate->curbyte;

        ret.buffer = SvPV_nolen(tempsv);
        ret.num.uv = SvCUR(tempsv);

        return ret;
    }

    ret.num.uv = _parse_for_uint_len2( aTHX_ decstate );

    _DECODE_CHECK_FOR_OVERAGE( decstate, ret.num.uv );

    ret.buffer = decstate->curbyte;

    decstate->curbyte += ret.num.uv;

    return ret;
}

void _decode_to_hash( pTHX_ decode_ctx* decstate, HV *hash ) {
    _DECODE_CHECK_FOR_OVERAGE( decstate, 1 );

    union control_byte *control = (union control_byte *) decstate->curbyte;

    struct numbuf my_key;
    my_key.buffer = NULL;

    // This is going to be a hash key, so it can’t usefully be
    // anything but a string/PV.
    I32 keylen;
    char *keystr;

    switch (control->pieces.major_type) {
        case CBOR_TYPE_UINT:
            my_key.num.uv = _decode_uint( aTHX_ decstate );

            keystr = (char *) decstate->scratch.bytes;
            keylen = _uv_to_str( my_key.num.uv, keystr, sizeof(decstate->scratch.bytes));

            break;

        case CBOR_TYPE_NEGINT:
            my_key.num.iv = _decode_negint( aTHX_ decstate );

            keystr = (char *) decstate->scratch.bytes;
            keylen = _iv_to_str( my_key.num.iv, keystr, sizeof(decstate->scratch.bytes));

            break;

        case CBOR_TYPE_BINARY:
        case CBOR_TYPE_UTF8:
            my_key = _decode_str( aTHX_ decstate );

            if (my_key.num.uv > 0x7fffffffU) {
                _croak("key too long!");
            }

            keystr = my_key.buffer;

            if (control->pieces.major_type == CBOR_TYPE_UTF8) {
                keylen = -my_key.num.uv;
            }
            else {
                keylen = my_key.num.uv;
            }

            break;

        default:
            _croak_invalid_map_key( aTHX_ decstate->curbyte[0], decstate->curbyte - decstate->start );
    }

    SV *curval = _decode( aTHX_ decstate );

    hv_store(hash, keystr, keylen, curval, 0);
}

SV *_decode_map( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    HV *hash = newHV();

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        while (decstate->curbyte[0] != '\xff') {
            _decode_to_hash( aTHX_ decstate, hash );
        }

        _DECODE_CHECK_FOR_OVERAGE( decstate, 1 );

        ++decstate->curbyte;
    }
    else {
        SSize_t keycount = _parse_for_uint_len2( aTHX_ decstate );

        if (keycount) {
            while (keycount > 0) {
                _decode_to_hash( aTHX_ decstate, hash );
                --keycount;
            }
        }
    }

    return newRV_noinc( (SV *) hash);
}

//----------------------------------------------------------------------

// Taken from RFC 7049:
double decode_half_float(uint8_t *halfp) {
    int half = (halfp[0] << 8) + halfp[1];
    int exp = (half >> 10) & 0x1f;
    int mant = half & 0x3ff;
    double val;
    if (exp == 0) val = ldexp(mant, -24);
    else if (exp != 31) val = ldexp(mant + 1024, exp - 25);
    else val = mant == 0 ? INFINITY : NAN;
    return half & 0x8000 ? -val : val;
}

static inline float _decode_float_to_host( pTHX_ decode_ctx* decstate, uint8_t *ptr ) {
    *((uint32_t *) decstate->scratch.bytes) = ntohl( *((uint32_t *) ptr) );

    return decstate->scratch.as_float;
}

static inline double _decode_double_to_le( decode_ctx* decstate, uint8_t *ptr ) {
    decstate->scratch.bytes[0] = ptr[7];
    decstate->scratch.bytes[1] = ptr[6];
    decstate->scratch.bytes[2] = ptr[5];
    decstate->scratch.bytes[3] = ptr[4];
    decstate->scratch.bytes[4] = ptr[3];
    decstate->scratch.bytes[5] = ptr[2];
    decstate->scratch.bytes[6] = ptr[1];
    decstate->scratch.bytes[7] = ptr[0];

    return decstate->scratch.as_double;
}

//----------------------------------------------------------------------

static inline SV *_decode_str_to_sv( pTHX_ decode_ctx* decstate ) {
    struct numbuf decoded_str = _decode_str( aTHX_ decstate );

    return newSVpvn( decoded_str.buffer, decoded_str.num.uv );
}

SV *_decode( pTHX_ decode_ctx* decstate ) {
    SV *ret = NULL;

    _DECODE_CHECK_FOR_OVERAGE( decstate, 1);

    union control_byte *control = (union control_byte *) decstate->curbyte;

    switch (control->pieces.major_type) {
        case CBOR_TYPE_UINT:
            ret = newSVuv( _decode_uint( aTHX_ decstate ) );

            break;
        case CBOR_TYPE_NEGINT:
            ret = newSViv( _decode_negint( aTHX_ decstate ) );

            break;
        case CBOR_TYPE_BINARY:
        case CBOR_TYPE_UTF8:
            ret = _decode_str_to_sv( aTHX_ decstate );

            // XXX: “perldoc perlapi” says this function is experimental.
            // Its use here is a calculated risk; the alternatives are
            // to invoke utf8::decode() via call_pv(), which is ugly,
            // or just to assume the UTF-8 is valid, which is wrong.
            //
            if (CBOR_TYPE_UTF8 == control->pieces.major_type) {
                if ( !sv_utf8_decode(ret) ) {
                    _croak_invalid_utf8( aTHX_ SvPV_nolen(ret) );
                }
            }

            break;
        case CBOR_TYPE_ARRAY:
            ret = _decode_array( aTHX_ decstate );

            break;
        case CBOR_TYPE_MAP:
            ret = _decode_map( aTHX_ decstate );

            break;
        case CBOR_TYPE_TAG:

            if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
                _croak_invalid_control( aTHX_ decstate );
            }

            // For now, just throw this tag value away.
            _parse_for_uint_len2( aTHX_ decstate );

            ret = _decode( aTHX_ decstate );

            break;
        case CBOR_TYPE_OTHER:
            switch (control->u8) {
                case CBOR_FALSE:
                    ret = newSVsv( get_sv("CBOR::Free::false", 0) );
                    ++decstate->curbyte;
                    break;

                case CBOR_TRUE:
                    ret = newSVsv( get_sv("CBOR::Free::true", 0) );
                    ++decstate->curbyte;
                    break;

                case CBOR_NULL:
                case CBOR_UNDEFINED:
                    ret = newSVsv( &PL_sv_undef );
                    ++decstate->curbyte;
                    break;

                case CBOR_HALF_FLOAT:
                    _DECODE_CHECK_FOR_OVERAGE( decstate, 3 );

                    ret = newSVnv( decode_half_float( (uint8_t *) (1 + decstate->curbyte) ) );

                    decstate->curbyte += 3;
                    break;

                case CBOR_FLOAT:
                    _DECODE_CHECK_FOR_OVERAGE( decstate, 5 );

                    float decoded_flt;

#if IS_LITTLE_ENDIAN
                    decoded_flt = _decode_float_to_host( aTHX_ decstate, (uint8_t *) (1 + decstate->curbyte ) );
#else
                    decoded_flt = *( (float *) (1 + decstate->curbyte) );
#endif

                    ret = newSVnv( (NV) decoded_flt );

                    decstate->curbyte += 5;
                    break;

                case CBOR_DOUBLE:
                    _DECODE_CHECK_FOR_OVERAGE( decstate, 9 );

                    double decoded_dbl;

#if IS_LITTLE_ENDIAN
                    decoded_dbl = _decode_double_to_le( decstate, (uint8_t *) (1 + decstate->curbyte ) );
#else
                    decoded_dbl = *( (double *) (1 + decstate->curbyte) );
#endif

                    ret = newSVnv( (NV) decoded_dbl );

                    decstate->curbyte += 9;
                    break;

                default:
                    _croak_invalid_control( aTHX_ decstate );
            }

            break;

        default:
            _croak("Unknown type!");
    }

    return ret;
}

//----------------------------------------------------------------------

MODULE = CBOR::Free           PACKAGE = CBOR::Free

PROTOTYPES: DISABLE

BOOT:
    HV *stash = gv_stashpv("CBOR::Free", FALSE);
    newCONSTSUB(stash, "_MAX_RECURSION", newSVuv( MAX_ENCODE_RECURSE ));

    boolean_stash = gv_stashpv(BOOLEAN_CLASS, 1);
    tagged_stash = gv_stashpv(TAGGED_CLASS, 1);

SV *
encode( SV * value, ... )
    CODE:
        encode_ctx encode_state[1];

        encode_state->buffer = NULL;
        Newx( encode_state->buffer, ENCODE_ALLOC_CHUNK_SIZE, char );

        encode_state->buflen = ENCODE_ALLOC_CHUNK_SIZE;
        encode_state->len = 0;
        encode_state->recurse_count = 0;

        encode_state->is_canonical = false;

        U8 i;
        for (i=1; i<items; i++) {
            if (!(i % 2)) break;

            if ((SvCUR(ST(i)) == 9) && !memcmp( SvPV_nolen(ST(i)), "canonical", 9)) {
                ++i;
                if (i<items) encode_state->is_canonical = SvTRUE(ST(i));
                break;
            }
        }

        _encode(aTHX_ value, encode_state);

        // Don’t use newSVpvn here because that will copy the string.
        // Instead, create a new SV and manually assign its pieces.
        // This follows the example from ext/POSIX/POSIX.xs:

        // Ensure that there’s a trailing NUL:
        _COPY_INTO_ENCODE( encode_state, &NUL, 1 );

        RETVAL = newSV(0);
        SvUPGRADE(RETVAL, SVt_PV);
        SvPV_set(RETVAL, encode_state->buffer);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, encode_state->len - 1);
        SvLEN_set(RETVAL, encode_state->buflen);

    OUTPUT:
        RETVAL


SV *
decode( SV *cbor )
    CODE:
        char *cborstr;
        STRLEN cborlen;

        cborstr = SvPV(cbor, cborlen);

        decode_ctx decode_state = {
            cborstr,
            cborlen,
            cborstr,
            cborstr + cborlen,
        };

        RETVAL = _decode( aTHX_ &decode_state );

        if (decode_state.curbyte != decode_state.end) {
            STRLEN bytes_count = decode_state.end - decode_state.curbyte;

            char numstr[24];
            _uv_to_str(bytes_count, numstr, 24);

            char * words[2] = { numstr, NULL };

            call_argv("CBOR::Free::_warn_decode_leftover", G_DISCARD, words);
        }

    OUTPUT:
        RETVAL
