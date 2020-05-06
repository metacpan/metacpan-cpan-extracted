#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cbor_free_common.h"
#include "cbor_free_decode.h"

#include <stdlib.h>
#include <stdbool.h>

// For ntohs and ntohl
#include <arpa/inet.h>

#define _IS_INCOMPLETE(decstate, len) \
    ((len + decstate->curbyte) > decstate->end)

#define _SET_INCOMPLETE(decstate, len) \
    decstate->incomplete_by = (len + decstate->curbyte) - decstate->end;

#define _RETURN_IF_INCOMPLETE( decstate, len, toreturn ) \
    if (_IS_INCOMPLETE(decstate, len)) { \
        _SET_INCOMPLETE(decstate, len); \
        return toreturn; \
    }

#define _RETURN_IF_SET_INCOMPLETE(decstate, toreturn) \
    if (decstate->incomplete_by) return toreturn;

#define SHOULD_VALIDATE_UTF8(decstate, major_type) \
    major_type == CBOR_TYPE_UTF8 \
    || decstate->string_decode_mode == CBF_STRING_DECODE_ALWAYS

//----------------------------------------------------------------------

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

const char *MAJOR_TYPE_DESCRIPTION[] = {
    "unsigned integer",
    "negative integer",
    "byte string",
    "text string",
    "array",
    "map",
    "tag",
    "miscellaneous",
};

//----------------------------------------------------------------------
// Croakers

static const char* UV_TO_STR_TMPL = (sizeof(UV) == 8 ? "%llu" : "%lu");
static const char* IV_TO_STR_TMPL = (sizeof(UV) == 8 ? "%lld" : "%ld");

UV _uv_to_str(UV num, char *numstr, const char strlen) {
    return my_snprintf( numstr, strlen, UV_TO_STR_TMPL, num );
}

UV _iv_to_str(IV num, char *numstr, const char strlen) {
    return my_snprintf( numstr, strlen, IV_TO_STR_TMPL, num );
}

void _free_decode_state_if_not_persistent( pTHX_ decode_ctx* decstate ) {
    if (!(decstate->flags & CBF_FLAG_PERSIST_STATE)) {
        free_decode_state(aTHX_ decstate);
    }
}

static inline void _croak_incomplete( pTHX_ decode_ctx* decstate ) {

    SV* args[2] = {
        newSVpvs("Incomplete"),
        newSVuv(decstate->incomplete_by),
    };

    _free_decode_state_if_not_persistent(aTHX_ decstate);

    cbf_die_with_arguments( aTHX_ 2, args );
}

static inline void _croak_invalid_control( pTHX_ decode_ctx* decstate ) {
    const uint8_t ord = (uint8_t) *(decstate->curbyte);
    UV offset = decstate->curbyte - decstate->start;

    _free_decode_state_if_not_persistent(aTHX_ decstate);

    SV* args[3] = {
        newSVpvs("InvalidControl"),
        newSVuv(ord),
        newSVuv(offset),
    };

    cbf_die_with_arguments( aTHX_ 3, args );

    assert(0);
}

void _croak_invalid_utf8( pTHX_ decode_ctx* decstate, char *string, STRLEN len ) {
    _free_decode_state_if_not_persistent(aTHX_ decstate);

    SV* args[2] = {
        newSVpvs("InvalidUTF8"),
        newSVpvn(string, len),
    };

    cbf_die_with_arguments( aTHX_ 2, args );

    assert(0);
}

void _croak_invalid_map_key( pTHX_ decode_ctx* decstate ) {
    const uint8_t byte = decstate->curbyte[0];
    UV offset = decstate->curbyte - decstate->start;

    _free_decode_state_if_not_persistent(aTHX_ decstate);

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
        case CBOR_HALF_FLOAT:
            bytestr = "half-float";
        case CBOR_FLOAT:
            bytestr = "float";
        case CBOR_DOUBLE:
            bytestr = "double float";
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

    SV* args[3] = {
        newSVpvs("InvalidMapKey"),
        newSVpv(bytestr, 0),
        newSVuv(offset),
    };

    cbf_die_with_arguments( aTHX_ 3, args );

    assert(0);
}

void _croak_cannot_decode_64bit( pTHX_ decode_ctx* decstate ) {
    UV offset = decstate->curbyte - decstate->start;

    _free_decode_state_if_not_persistent(aTHX_ decstate);

    SV* args[3] = {
        newSVpvs("CannotDecode64Bit"),
        newSVpvn( decstate->curbyte, 8),
        newSVuv(offset),
    };

    cbf_die_with_arguments( aTHX_ 3, args );

    assert(0);
}

void _croak_cannot_decode_negative( pTHX_ decode_ctx* decstate, UV abs, STRLEN offset ) {
    _free_decode_state_if_not_persistent(aTHX_ decstate);

    SV* args[3] = {
        newSVpvs("NegativeIntTooLow"),
        newSVuv(abs),
        newSVuv(offset),
    };

    cbf_die_with_arguments( aTHX_ 3, args );

    assert(0);
}

void _warn_unhandled_tag( pTHX_ UV tagnum, U8 value_major_type ) {
    char tmpl[255];
    my_snprintf( tmpl, sizeof(tmpl), "Ignoring unrecognized CBOR tag #%s (major type %%u, %%s)!", UV_TO_STR_TMPL );

    warn(tmpl, tagnum, value_major_type, MAJOR_TYPE_DESCRIPTION[value_major_type]);
}

//----------------------------------------------------------------------

static inline void _validate_utf8_string_if_needed( pTHX_ decode_ctx* decstate, char *buffer, STRLEN len ) {

    if (!(decstate->flags & CBF_FLAG_NAIVE_UTF8) && !is_utf8_string( (U8 *)buffer, len)) {
        _croak_invalid_utf8( aTHX_ decstate, buffer, len );
    }
}

//----------------------------------------------------------------------
// DECODER:
//----------------------------------------------------------------------

// Sets incomplete_by.
static inline UV _parse_for_uint_len2( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    UV ret;

    switch (control->pieces.length_type) {
        case CBOR_LENGTH_SMALL:

            _RETURN_IF_INCOMPLETE( decstate, 2, 0 );

            ++decstate->curbyte;

            ret = (uint8_t) decstate->curbyte[0];

            ++decstate->curbyte;

            break;

        case CBOR_LENGTH_MEDIUM:
            _RETURN_IF_INCOMPLETE( decstate, 3, 0);

            ++decstate->curbyte;

            ret = ntohs( *((uint16_t *) decstate->curbyte) );

            decstate->curbyte += 2;

            break;

        case CBOR_LENGTH_LARGE:
            _RETURN_IF_INCOMPLETE( decstate, 5, 0);

            ++decstate->curbyte;

            ret = ntohl( *((uint32_t *) decstate->curbyte) );

            decstate->curbyte += 4;

            break;

        case CBOR_LENGTH_HUGE:
            _RETURN_IF_INCOMPLETE( decstate, 9, 0);

            ++decstate->curbyte;

#if !IS_64_BIT

            if (decstate->curbyte[0] || decstate->curbyte[1] || decstate->curbyte[2] || decstate->curbyte[3]) {
                _croak_cannot_decode_64bit( aTHX_ decstate );
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
            return 0; // Silence compiler warning.

        default:
            ret = (uint8_t) control->pieces.length_type;

            decstate->curbyte++;
    }

    return ret;
}

//----------------------------------------------------------------------

// Sets incomplete_by.
SV *_decode_array( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    AV *array = newAV();
    sv_2mortal( (SV *) array );

    SV *cur = NULL;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        while (1) {
            _RETURN_IF_INCOMPLETE( decstate, 1, NULL );

            if ( decstate->curbyte[0] == '\xff') {
                ++decstate->curbyte;
                break;
            }

            cur = cbf_decode_one( aTHX_ decstate );

            _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

            av_push(array, cur);
        }
    }
    else {
        SSize_t array_length = _parse_for_uint_len2( aTHX_ decstate );
        _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

        if (array_length) {
            av_fill(array, array_length - 1);

            SSize_t i;
            for (i=0; i<array_length; i++) {
                cur = cbf_decode_one( aTHX_ decstate );
                _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

                if (!av_store(array, i, cur)) {
                    _croak("Failed to store item in array!");
                }
            }
        }
    }

    return newRV_inc( (SV *) array );
}

// Sets incomplete_by.
UV _decode_uint( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        _croak_invalid_control( aTHX_ decstate );
    }

    return _parse_for_uint_len2( aTHX_ decstate );
}

// Sets incomplete_by.
IV _decode_negint( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        _croak_invalid_control( aTHX_ decstate );
    }

    UV positive = _parse_for_uint_len2( aTHX_ decstate );
    _RETURN_IF_SET_INCOMPLETE(decstate, 0);

#if IS_64_BIT
    if (positive >= 0x8000000000000000U) {
        _croak_cannot_decode_negative( aTHX_ decstate, positive, decstate->curbyte - decstate->start - 8 );
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

        _croak_cannot_decode_negative( aTHX_ decstate, positive, offset );
    }
#endif

    return( -1 - (int64_t) positive );
}

// Sets incomplete_by.
// Return indicates whether string_h has SV.
bool _decode_str( pTHX_ decode_ctx* decstate, union numbuf_or_sv* string_u ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        SV *string = newSVpvs("");  /* 5.10.0 lacks newSVpvs_flags() */
        sv_2mortal(string);
        string_u->sv = string;

        while (1) {
            _RETURN_IF_INCOMPLETE( decstate, 1, false );

            if (decstate->curbyte[0] == '\xff') {
                ++decstate->curbyte;
                break;
            }

            //TODO: Require the same major type.

            SV *cur = cbf_decode_one( aTHX_ decstate );

            _RETURN_IF_SET_INCOMPLETE( decstate, false );

            sv_2mortal(cur);

            sv_catsv(string, cur);
        }

        SvREFCNT_inc(string);

        return true;
    }

    string_u->numbuf.num.uv = _parse_for_uint_len2( aTHX_ decstate );
    _RETURN_IF_SET_INCOMPLETE(decstate, false);

    _RETURN_IF_INCOMPLETE( decstate, string_u->numbuf.num.uv, false );

    string_u->numbuf.buffer = decstate->curbyte;

    decstate->curbyte += string_u->numbuf.num.uv;

    return false;
}

// Sets incomplete_by.
void _decode_hash_entry( pTHX_ decode_ctx* decstate, HV *hash ) {
    _RETURN_IF_INCOMPLETE( decstate, 1,  );

    union control_byte *control = (union control_byte *) decstate->curbyte;

    union numbuf_or_sv my_key;
    my_key.numbuf.buffer = NULL;

    // This is going to be a hash key, so it can’t usefully be
    // anything but a string/PV.
    I32 keylen;
    char *keystr;

    bool my_key_has_sv = false;

    switch (control->pieces.major_type) {
        case CBOR_TYPE_UINT:
            my_key.numbuf.num.uv = _decode_uint( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, );

            keystr = (char *) decstate->scratch.bytes;
            keylen = _uv_to_str( my_key.numbuf.num.uv, keystr, sizeof(decstate->scratch.bytes));
            // fprintf(stderr, "key (%p) is uint: %.*s\n", keystr, keylen, keystr);

            break;

        case CBOR_TYPE_NEGINT:
            my_key.numbuf.num.iv = _decode_negint( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, );

            keystr = (char *) decstate->scratch.bytes;
            keylen = _iv_to_str( my_key.numbuf.num.iv, keystr, sizeof(decstate->scratch.bytes));

            break;

        case CBOR_TYPE_BINARY:
        case CBOR_TYPE_UTF8:
            my_key_has_sv = _decode_str( aTHX_ decstate, &my_key );
            _RETURN_IF_SET_INCOMPLETE(decstate, );

            if (!my_key_has_sv) {
                if (my_key.numbuf.num.uv > 0x7fffffffU) {
                    _croak("key too long!");
                }

                keystr = my_key.numbuf.buffer;

                if (SHOULD_VALIDATE_UTF8(decstate, control->pieces.major_type)) {
                    _validate_utf8_string_if_needed( aTHX_ decstate, keystr, my_key.numbuf.num.uv );

                    keylen = decstate->string_decode_mode == CBF_STRING_DECODE_NEVER ? my_key.numbuf.num.uv : -my_key.numbuf.num.uv;
                }
                else {
                    keylen = my_key.numbuf.num.uv;
                }
            }

            break;

        default:
            _croak_invalid_map_key( aTHX_ decstate);
            return; // Silence compiler warning.
    }

    SV *curval = cbf_decode_one( aTHX_ decstate );

    if (decstate->incomplete_by) {
        if (my_key_has_sv) {
            SvREFCNT_dec( my_key.sv );
        }
    }
    else if (my_key_has_sv) {
        hv_store_ent(hash, my_key.sv, curval, 0);
    }
    else {
        hv_store(hash, keystr, keylen, curval, 0);
    }
}

// Sets incomplete_by.
SV *_decode_map( pTHX_ decode_ctx* decstate ) {
    union control_byte *control = (union control_byte *) decstate->curbyte;

    HV *hash = newHV();
    sv_2mortal( (SV *) hash );

    if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
        ++decstate->curbyte;

        while (1) {
            _RETURN_IF_INCOMPLETE( decstate, 1, NULL );

            if (decstate->curbyte[0] == '\xff') {
                ++decstate->curbyte;
                break;
            }

            _decode_hash_entry( aTHX_ decstate, hash );

            // TODO: Recursively decref all hash members.
            if ( decstate->incomplete_by ) {
                return NULL;
            }
        }
    }
    else {
        SSize_t keycount = _parse_for_uint_len2( aTHX_ decstate );
        if ( decstate->incomplete_by ) {
            return NULL;
        }

        if (keycount) {
            while (keycount > 0) {
                _decode_hash_entry( aTHX_ decstate, hash );

                // TODO: Recursively decref all hash members.
                if ( decstate->incomplete_by ) {
                    return NULL;
                }

                --keycount;
            }
        }
    }

    return newRV_inc( (SV *) hash);
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

// Sets incomplete_by.
static inline SV *_decode_str_to_sv( pTHX_ decode_ctx* decstate ) {
    union numbuf_or_sv string;

    if (_decode_str( aTHX_ decstate, &string )) {
        return string.sv;
    }

    _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

    return newSVpvn( string.numbuf.buffer, string.numbuf.num.uv );
}

// Sets incomplete_by.
SV *cbf_decode_one( pTHX_ decode_ctx* decstate ) {
    SV *ret = NULL;

    _RETURN_IF_INCOMPLETE( decstate, 1, NULL );

    union control_byte *control = (union control_byte *) decstate->curbyte;

    // fprintf(stderr, "major type: %d\n", control->pieces.major_type);

    switch (control->pieces.major_type) {
        case CBOR_TYPE_UINT:
            ret = newSVuv( _decode_uint( aTHX_ decstate ) );
            if ( decstate->incomplete_by ) {
                SvREFCNT_dec(ret);
                return NULL;
            }

            break;
        case CBOR_TYPE_NEGINT:
            ret = newSViv( _decode_negint( aTHX_ decstate ) );
            if ( decstate->incomplete_by ) {
                SvREFCNT_dec(ret);
                return NULL;
            }

            break;
        case CBOR_TYPE_BINARY:
        case CBOR_TYPE_UTF8:
            ret = _decode_str_to_sv( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

            if (SHOULD_VALIDATE_UTF8(decstate, control->pieces.major_type)) {
                _validate_utf8_string_if_needed( aTHX_ decstate, SvPV_nolen(ret), SvCUR(ret));

                // Always set the UTF8 flag, even if it’s not needed.
                // This helps ensure that text strings will round-trip
                // through Perl.
                if (decstate->string_decode_mode != CBF_STRING_DECODE_NEVER) SvUTF8_on(ret);
            }

            break;
        case CBOR_TYPE_ARRAY:
            ret = _decode_array( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

            break;
        case CBOR_TYPE_MAP:
            ret = _decode_map( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

            break;
        case CBOR_TYPE_TAG:

            if (control->pieces.length_type == CBOR_LENGTH_INDEFINITE) {
                _croak_invalid_control( aTHX_ decstate );
            }

            UV tagnum = _parse_for_uint_len2( aTHX_ decstate );
            _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

            U8 value_major_type = ((union control_byte *) decstate->curbyte)->pieces.major_type;

            if (tagnum == CBOR_TAG_SHAREDREF && decstate->reflist) {
                if (value_major_type != CBOR_TYPE_UINT) {
                    char tmpl[255];
                    my_snprintf( tmpl, sizeof(tmpl), "Shared ref type must be uint, not %%u (%%s)!" );
                    croak(tmpl, value_major_type, MAJOR_TYPE_DESCRIPTION[value_major_type]);
                }

                UV refnum = _parse_for_uint_len2( aTHX_ decstate );
                _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

                if (refnum >= decstate->reflistlen) {
                    _croak("Missing shareable!");
                }

                ret = decstate->reflist[refnum];
                SvREFCNT_inc(ret);
            }
            else {
                ret = cbf_decode_one( aTHX_ decstate );
                _RETURN_IF_SET_INCOMPLETE(decstate, NULL);

                if (tagnum == CBOR_TAG_INDIRECTION) {
                    ret = newRV_noinc(ret);
                }
                else if (tagnum == CBOR_TAG_SHAREABLE && decstate->reflist) {
                    ++decstate->reflistlen;
                    Renew( decstate->reflist, decstate->reflistlen, void * );

                    decstate->reflist[ decstate->reflistlen - 1 ] = (SV *) ret;
                }

                else if (decstate->tag_handler) {
                    HV *my_tag_handler = decstate->tag_handler;

                    SV **handler_cr = hv_fetch( my_tag_handler, (char *) &tagnum, sizeof(UV), 0 );

                    if (handler_cr && *handler_cr && SvOK(*handler_cr)) {
                        ret = cbf_call_scalar_with_arguments( aTHX_ *handler_cr, 1, &ret );
                    }
                    else {
                        _warn_unhandled_tag( aTHX_ tagnum, value_major_type );
                    }
                }
                else {
                    _warn_unhandled_tag( aTHX_ tagnum, value_major_type );
                }
            }

            break;
        case CBOR_TYPE_OTHER:
            switch (control->u8) {
                case CBOR_FALSE:
                    ret = newSVsv( cbf_get_false() );
                    ++decstate->curbyte;
                    break;

                case CBOR_TRUE:
                    ret = newSVsv( cbf_get_true() );
                    ++decstate->curbyte;
                    break;

                case CBOR_NULL:
                case CBOR_UNDEFINED:
                    ret = &PL_sv_undef;
                    ++decstate->curbyte;
                    break;

                case CBOR_HALF_FLOAT:
                    _RETURN_IF_INCOMPLETE( decstate, 3, NULL );

                    ret = newSVnv( decode_half_float( (uint8_t *) (1 + decstate->curbyte) ) );

                    decstate->curbyte += 3;
                    break;

                case CBOR_FLOAT:
                    _RETURN_IF_INCOMPLETE( decstate, 5, NULL );

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
                    _RETURN_IF_INCOMPLETE( decstate, 9, NULL );

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

/*
 * Possible states:
 *
 * 1) We’re initializing.
 * 2) We just concat’ed two SVPVs (same as initializing).
 * 3) We just shortened from the beginning.
 */

void renew_decode_state_buffer( pTHX_ decode_ctx *decode_state, SV *cbor ) {
    STRLEN cborlen = SvCUR(cbor);

    char *cborstr = SvPVX(cbor);

    STRLEN offset;
    if (decode_state->curbyte == NULL) {
        offset = 0;
    }
    else {
        offset = decode_state->curbyte - decode_state->start;
    }

    decode_state->start = cborstr;
    decode_state->size = cborlen;
    decode_state->curbyte = cborstr + offset;
    decode_state->end = cborstr + cborlen;
}

void advance_decode_state_buffer( pTHX_ decode_ctx *decode_state ) {
    STRLEN diff = decode_state->curbyte - decode_state->start;

    decode_state->start = decode_state->curbyte;
    decode_state->size -= diff;
}

decode_ctx* create_decode_state( pTHX_ SV *cbor, HV *tag_handler, UV flags ) {
    decode_ctx *decode_state;
    Newx( decode_state, 1, decode_ctx );

    decode_state->curbyte = NULL;

    if (cbor) {
        renew_decode_state_buffer( aTHX_ decode_state, cbor );
    }

    decode_state->tag_handler = tag_handler;
    if (NULL != tag_handler) {
        SvREFCNT_inc((SV *) tag_handler);
    }

    decode_state->reflist = NULL;
    decode_state->reflistlen = 0;
    decode_state->flags = flags;
    decode_state->incomplete_by = 0;

    decode_state->string_decode_mode = CBF_STRING_DECODE_CBOR;

    if (flags & CBF_FLAG_PRESERVE_REFERENCES) {
        ensure_reflist_exists( aTHX_ decode_state );
    }

    return decode_state;
}

void ensure_reflist_exists( pTHX_ decode_ctx* decode_state) {
    if (NULL == decode_state->reflist) {
        Newx( decode_state->reflist, 0, void * );
    }
}

void delete_reflist( pTHX_ decode_ctx* decode_state) {
    if (NULL != decode_state->reflist) {
        Safefree(decode_state->reflist);
        decode_state->reflist = NULL;
        decode_state->reflistlen = 0;
    }
}

void reset_reflist_if_needed( pTHX_ decode_ctx* decode_state) {
    if (decode_state->reflistlen) {
        delete_reflist( aTHX_ decode_state );
        ensure_reflist_exists( aTHX_ decode_state );
    }
}

void free_decode_state( pTHX_ decode_ctx* decode_state) {
    delete_reflist( aTHX_ decode_state );

    if (NULL != decode_state->tag_handler) {
        SvREFCNT_dec((SV *) decode_state->tag_handler);
        decode_state->tag_handler = NULL;
    }

    Safefree(decode_state);
}

SV *cbf_decode_document( pTHX_ decode_ctx *decode_state ) {
    SV *RETVAL = cbf_decode_one( aTHX_ decode_state );

    if (decode_state->incomplete_by) {
        _croak_incomplete( aTHX_ decode_state );
    }

    if (decode_state->curbyte != decode_state->end) {
        STRLEN bytes_count = decode_state->end - decode_state->curbyte;

        char numstr[24];
        _uv_to_str(bytes_count, numstr, 24);

        char * words[2] = { numstr, NULL };

        call_argv("CBOR::Free::_warn_decode_leftover", G_DISCARD, words);
    }

    return RETVAL;
}

SV *cbf_decode( pTHX_ SV *cbor, HV *tag_handler, UV flags ) {

    decode_ctx *decode_state = create_decode_state( aTHX_ cbor, tag_handler, flags);

    SV *RETVAL = cbf_decode_document( aTHX_ decode_state );

    free_decode_state( aTHX_ decode_state);

    return RETVAL;
}
