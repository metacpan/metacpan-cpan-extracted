#ifndef CBOR_FREE_DECODE
#define CBOR_FREE_DECODE

#include "cbor_free_common.h"
#include "cbor_free_boolean.h"

//----------------------------------------------------------------------
// Definitions

typedef struct {
    char* start;
    STRLEN size;
    char* curbyte;
    char* end;

    HV * tag_handler;

    union {
        uint8_t bytes[30];  // used for num -> key conversions
        float as_float;
        double as_double;
    } scratch;

} decode_ctx;

struct numbuf {
    union {
        UV uv;
        IV iv;
    } num;

    char *buffer;
};

//----------------------------------------------------------------------

SV *cbf_decode( pTHX_ SV *cbor, HV *tag_handler );

#endif
