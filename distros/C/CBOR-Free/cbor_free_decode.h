#ifndef CBOR_FREE_DECODE
#define CBOR_FREE_DECODE

#include "cbor_free_common.h"
#include "cbor_free_boolean.h"

#define CBF_FLAG_PRESERVE_REFERENCES 1
#define CBF_FLAG_NAIVE_UTF8 2
#define CBF_FLAG_PERSIST_STATE 4

//----------------------------------------------------------------------
// Definitions

enum cbf_string_decode_mode {
    CBF_STRING_DECODE_CBOR,     // i.e., decode if the CBOR is text
    CBF_STRING_DECODE_NEVER,
    CBF_STRING_DECODE_ALWAYS
};

typedef struct {
    char* start;
    STRLEN size;
    char* curbyte;
    char* end;

    HV * tag_handler;

    void **reflist;
    UV reflistlen;

    enum cbf_string_decode_mode string_decode_mode;

    UV flags;

    STRLEN incomplete_by;

    union {
        uint8_t bytes[30];  // used for num -> key conversions
        float as_float;
        double as_double;
    } scratch;

} decode_ctx;

typedef struct {
    decode_ctx* decode_state;
    SV* cbor;
} seqdecode_ctx;

union uviv {
    UV uv;
    IV iv;
};

struct numbuf {
    union uviv num;

    char *buffer;
};

union numbuf_or_sv {
    SV *sv;
    struct numbuf numbuf;
};

//----------------------------------------------------------------------

SV *cbf_decode( pTHX_ SV *cbor, HV *tag_handler, UV flags );

SV *cbf_decode_one( pTHX_ decode_ctx* decstate );
SV *cbf_decode_document( pTHX_ decode_ctx *decode_state );

void ensure_reflist_exists( pTHX_ decode_ctx* decode_state);
void delete_reflist( pTHX_ decode_ctx* decode_state);
void reset_reflist_if_needed( pTHX_ decode_ctx* decode_state);

decode_ctx* create_decode_state( pTHX_ SV *cbor, HV *tag_handler, UV flags );
void free_decode_state( pTHX_ decode_ctx* decode_state);

void renew_decode_state_buffer( pTHX_ decode_ctx *decode_state, SV *cbor );
void advance_decode_state_buffer( pTHX_ decode_ctx *decode_state );

#endif
