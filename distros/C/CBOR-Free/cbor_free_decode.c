#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cbor_free_common.h"
#include "cbor_free_decode.h"

#include <stdlib.h>

// For ntohs and ntohl
#include <arpa/inet.h>

#define _DECODE_CHECK_FOR_OVERAGE( decstate, len) \
    if ((len + decstate->curbyte) > decstate->end) { \
        _croak_incomplete( aTHX_ decstate, (len + decstate->curbyte) - decstate->end ); \
    }

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

void _free_decode_state(decode_ctx* decode_state);

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

void _croak_incomplete( pTHX_ decode_ctx* decstate, STRLEN lack ) {
    _free_decode_state(decstate);

    char lackstr[24];
    _uv_to_str( lack, lackstr, sizeof(lackstr) );

    char * words[3] = { "Incomplete", lackstr, NULL };

    _die( G_DISCARD, words );
}

void _croak_invalid_control( pTHX_ decode_ctx* decstate ) {
    const uint8_t ord = (uint8_t) *(decstate->curbyte);
    STRLEN offset = decstate->curbyte - decstate->start;

    char ordstr[24];
    char offsetstr[24];

    _uv_to_str(ord, ordstr, sizeof(ordstr));
    _uv_to_str(offset, offsetstr, sizeof(offsetstr));

    char * words[] = { "InvalidControl", ordstr, offsetstr, NULL };

    _free_decode_state(decstate);

    _die( G_DISCARD, words );
}

void _croak_invalid_utf8( pTHX_ decode_ctx* decstate, char *string ) {
    _free_decode_state(decstate);

    char * words[3] = { "InvalidUTF8", string, NULL };

    _die( G_DISCARD, words);
}

void _croak_invalid_map_key( pTHX_ decode_ctx* decstate, const uint8_t byte, STRLEN offset ) {
    _free_decode_state(decstate);

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

    _die( G_DISCARD, words);
}

void _croak_cannot_decode_64bit( pTHX_ decode_ctx* decstate, const uint8_t *u64bytes, STRLEN offset ) {
    _free_decode_state(decstate);

    char numhex[20];
    numhex[19] = 0;

    my_snprintf( numhex, sizeof(numhex), "%02x%02x_%02x%02x_%02x%02x_%02x%02x", u64bytes[0], u64bytes[1], u64bytes[2], u64bytes[3], u64bytes[4], u64bytes[5], u64bytes[6], u64bytes[7] );

    char offsetstr[20];
    _uv_to_str( offset, offsetstr, sizeof(offsetstr) );

    char * words[] = { "CannotDecode64Bit", numhex, offsetstr, NULL };

    _die( G_DISCARD, words );
}

void _croak_cannot_decode_negative( pTHX_ decode_ctx* decstate, UV abs, STRLEN offset ) {
    _free_decode_state(decstate);

    char absstr[40];
    _uv_to_str( abs, absstr, sizeof(absstr) );

    char offsetstr[20];
    _uv_to_str( offset, offsetstr, sizeof(offsetstr) );

    char * words[] = { "NegativeIntTooLow", absstr, offsetstr, NULL };

    _die( G_DISCARD, words );
}

void _warn_unhandled_tag( pTHX_ UV tagnum, U8 value_major_type ) {
    char tmpl[255];
    my_snprintf( tmpl, sizeof(tmpl), "Ignoring unrecognized CBOR tag #%s (major type %%u, %%s)!", UV_TO_STR_TMPL );

    warn(tmpl, tagnum, value_major_type, MAJOR_TYPE_DESCRIPTION[value_major_type]);
}

//----------------------------------------------------------------------
// DECODER:
//----------------------------------------------------------------------

// Needed because of mutual recursion of functions.
SV *_decode( pTHX_ decode_ctx* decstate );

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
                _croak_cannot_decode_64bit( aTHX_ decstate, (const uint8_t *) decstate->curbyte, decstate->curbyte - decstate->start );
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
            _croak_invalid_map_key( aTHX_ decstate, decstate->curbyte[0], decstate->curbyte - decstate->start );
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

SV *_call_with_argument( pTHX_ SV* cb, SV* arg ) {
    // --- Almost all copy-paste from “perlcall” … blegh!
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);

    PUSHs( sv_2mortal(arg) );
    PUTBACK;

    call_sv(cb, G_SCALAR);

    SV *ret = newSVsv(POPs);

    FREETMPS;
    LEAVE;

    return ret;
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

            if (CBOR_TYPE_UTF8 == control->pieces.major_type) {

                // XXX: “perldoc perlapi” says this function is experimental.
                // Its use here is a calculated risk; the alternatives are
                // to invoke utf8::decode() via call_pv(), which is ugly,
                // or just to assume the UTF-8 is valid, which is wrong.
                //
                if ( !sv_utf8_decode(ret) ) {
                    _croak_invalid_utf8( aTHX_ decstate, SvPV_nolen(ret) );
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

            UV tagnum = _parse_for_uint_len2( aTHX_ decstate );

            U8 value_major_type = ((union control_byte *) decstate->curbyte)->pieces.major_type;

            if (tagnum == CBOR_TAG_SHAREDREF && decstate->reflist) {
                if (value_major_type != CBOR_TYPE_UINT) {
                    char tmpl[255];
                    my_snprintf( tmpl, sizeof(tmpl), "Shared ref type must be uint, not %%u (%%s)!" );
                    croak(tmpl, value_major_type, MAJOR_TYPE_DESCRIPTION[value_major_type]);
                }

                UV refnum = _parse_for_uint_len2( aTHX_ decstate );

                if (refnum >= decstate->reflistlen) {
                    _croak("Missing shareable!");
                }

                ret = decstate->reflist[refnum];
                SvREFCNT_inc(ret);
            }
            else {
                ret = _decode( aTHX_ decstate );

                if (tagnum == CBOR_TAG_INDIRECTION) {
                    ret = newRV_inc(ret);
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
                        ret = _call_with_argument( aTHX_ *handler_cr, ret );
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

decode_ctx _create_decode_state( pTHX_ SV *cbor, HV *tag_handler, bool preserve_refs ) {
    STRLEN cborlen;

    char *cborstr = SvPV(cbor, cborlen);

    decode_ctx decode_state = {
        cborstr,
        cborlen,
        cborstr,
        cborstr + cborlen,
        tag_handler,
        NULL,
        0,
    };

    if (preserve_refs) {
        Newx( decode_state.reflist, 0, void * );
    }

    return decode_state;
}

void _free_decode_state(decode_ctx* decode_state) {
    if (decode_state->reflist) {
        Safefree(decode_state->reflist);
    }
}

SV *cbf_decode( pTHX_ SV *cbor, HV *tag_handler, bool preserve_refs ) {

    decode_ctx decode_state = _create_decode_state( aTHX_ cbor, tag_handler, preserve_refs);

    SV *RETVAL = _decode( aTHX_ &decode_state );

    _free_decode_state(&decode_state);

    if (decode_state.curbyte != decode_state.end) {
        STRLEN bytes_count = decode_state.end - decode_state.curbyte;

        char numstr[24];
        _uv_to_str(bytes_count, numstr, 24);

        char * words[2] = { numstr, NULL };

        call_argv("CBOR::Free::_warn_decode_leftover", G_DISCARD, words);
    }

    return RETVAL;
}
