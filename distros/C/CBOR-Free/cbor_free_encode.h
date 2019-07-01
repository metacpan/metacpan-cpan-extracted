#ifndef CBOR_FREE_ENCODE
#define CBOR_FREE_ENCODE

#include "cbor_free_common.h"
#include "cbor_free_boolean.h"

#define MAX_ENCODE_RECURSE 98

#define ENCODE_ALLOC_CHUNK_SIZE 1024

typedef struct {
    char *buffer;
    STRLEN buflen;
    STRLEN len;
    uint8_t recurse_count;
    uint8_t scratch[9];
    bool is_canonical;
} encode_ctx;

SV * cbf_encode( pTHX_ SV *value, encode_ctx *encode_state, SV *RETVAL );

#endif
