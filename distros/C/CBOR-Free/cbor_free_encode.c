#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cbor_free_encode.h"

#define TAGGED_CLASS    "CBOR::Free::Tagged"

#define IS_SCALAR_REFERENCE(value) SvTYPE(SvRV(value)) <= SVt_PVMG

static const unsigned char NUL = 0;
static const unsigned char CBOR_NULL_U8  = CBOR_NULL;
static const unsigned char CBOR_FALSE_U8 = CBOR_FALSE;
static const unsigned char CBOR_TRUE_U8  = CBOR_TRUE;

static const unsigned char CBOR_INF_SHORT[3] = { 0xf9, 0x7c, 0x00 };
static const unsigned char CBOR_NAN_SHORT[3] = { 0xf9, 0x7e, 0x00 };
static const unsigned char CBOR_NEGINF_SHORT[3] = { 0xf9, 0xfc, 0x00 };

static HV *tagged_stash = NULL;

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

//----------------------------------------------------------------------
// Croakers

void _croak_unrecognized(pTHX_ SV *value) {
    char * words[3] = { "Unrecognized", SvPV_nolen(value), NULL };

    _die( G_DISCARD, words );
}

//----------------------------------------------------------------------

// NOTE: Contrary to what we’d ordinarily expect, for canonical CBOR
// keys are only byte-sorted if their lengths are identical. Thus,
// “z” sorts EARLIER than “aa”. (cf. section 3.9 of the RFC)
static I32 _sortstring( pTHX_ SV *a, SV *b ) {
    return (SvCUR(a) < SvCUR(b)) ? -1 : (SvCUR(a) > SvCUR(b)) ? 1 : memcmp( SvPV_nolen(a), SvPV_nolen(b), SvCUR(a) );
}

//----------------------------------------------------------------------

static inline HV *_get_tagged_stash() {
    if (!tagged_stash) {
        dTHX;
        tagged_stash = gv_stashpv(TAGGED_CLASS, 1);
    }

    return tagged_stash;
}

static inline void _COPY_INTO_ENCODE( encode_ctx *encode_state, const unsigned char *hdr, STRLEN len) {
    if ( (len + encode_state->len) > encode_state->buflen ) {
        Renew( encode_state->buffer, encode_state->buflen + len + ENCODE_ALLOC_CHUNK_SIZE, char );
        encode_state->buflen += len + ENCODE_ALLOC_CHUNK_SIZE;
    }

    Copy( hdr, encode_state->buffer + encode_state->len, len, char );
    encode_state->len += len;
}

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

static inline void _encode_tag( pTHX_ IV tagnum, SV *value, encode_ctx *encode_state );

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
        HV *stash = SvSTASH( SvRV(value) );

        if (_get_tagged_stash() == stash) {
            AV *array = (AV *)SvRV(value);
            SV **tag = av_fetch(array, 0, 0);
            IV tagnum = SvIV(*tag);

            _encode_tag( aTHX_ tagnum, *(av_fetch(array, 1, 0)), encode_state );
        }
        else if (cbf_get_boolean_stash() == stash) {
            _COPY_INTO_ENCODE(
                encode_state,
                SvTRUE(SvRV(value)) ? &CBOR_TRUE_U8 : &CBOR_FALSE_U8,
                1
            );
        }

        // TODO: Support TO_JSON() or TO_CBOR() method?

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

            sortsv(keys, keyscount, _sortstring);

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
    else if (encode_state->encode_scalar_refs && IS_SCALAR_REFERENCE(value)) {
        SV *referent = SvRV(value);

        _encode_tag( aTHX_ CBOR_TAG_INDIRECTION, referent, encode_state );
    }
    else {
        _croak_unrecognized(aTHX_ value);
    }

    --encode_state->recurse_count;
}

static inline void _encode_tag( pTHX_ IV tagnum, SV *value, encode_ctx *encode_state ) {
    _init_length_buffer( aTHX_ tagnum, CBOR_TYPE_TAG, encode_state );
    _encode( aTHX_ value, encode_state );
}

SV *cbf_encode( pTHX_ SV *value, encode_ctx *encode_state, SV *RETVAL ) {
    _encode(aTHX_ value, encode_state);

    // Ensure that there’s a trailing NUL:
    _COPY_INTO_ENCODE( encode_state, &NUL, 1 );

    return RETVAL;
}
