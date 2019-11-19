#ifndef CBOR_FREE_ENCODE
#define CBOR_FREE_ENCODE

#include <stdbool.h>

#include "cbor_free_common.h"
#include "cbor_free_boolean.h"

#define MAX_ENCODE_RECURSE 98

#define ENCODE_ALLOC_CHUNK_SIZE 1024

#define ENCODE_FLAG_CANONICAL       1
#define ENCODE_FLAG_PRESERVE_REFS   2
#define ENCODE_FLAG_SCALAR_REFS     4

typedef struct {
    STRLEN buflen;
    STRLEN len;
    char *buffer;
    void **reftracker;
    uint8_t recurse_count;
    uint8_t scratch[9];
    bool is_canonical;
    bool encode_scalar_refs;
} encode_ctx;

struct string_and_length {
    char *buffer;
    I32 length;
};

SV * cbf_encode( pTHX_ SV *value, encode_ctx *encode_state, SV *RETVAL );

encode_ctx cbf_encode_ctx_create( uint8_t flags );

void cbf_encode_ctx_free_reftracker( encode_ctx* encode_state );
void cbf_encode_ctx_free_all( encode_ctx* encode_state );

#endif
