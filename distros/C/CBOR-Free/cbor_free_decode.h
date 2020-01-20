#ifndef CBOR_FREE_DECODE
#define CBOR_FREE_DECODE

#include "cbor_free_common.h"
#include "cbor_free_boolean.h"

#define CBF_FLAG_PRESERVE_REFERENCES 1
#define CBF_FLAG_NAIVE_UTF8 2

//----------------------------------------------------------------------
// Definitions

typedef struct {
    char* start;
    STRLEN size;
    char* curbyte;
    char* end;

    HV * tag_handler;

    void **reflist;
    UV reflistlen;

    bool naive_utf8;

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

SV *cbf_decode( pTHX_ SV *cbor, HV *tag_handler, UV flags );

#endif
