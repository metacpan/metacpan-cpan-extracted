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
#define ENCODE_FLAG_TEXT_KEYS       8

// HeKWASUTF8(he) is undocumented, but the UTF8 flag can be stored
// there as well as in HeUTF8().
#define CBF_HeUTF8(h_entry) (HeUTF8(h_entry) || (!HeSVKEY(h_entry) && HeKWASUTF8(h_entry)))

typedef struct {
    STRLEN buflen;
    STRLEN len;
    char *buffer;
    void **reftracker;
    uint8_t recurse_count;
    uint8_t scratch[9];
    bool is_canonical;
    bool text_keys;
    bool encode_scalar_refs;
} encode_ctx;

struct sortable_hash_entry {
    bool is_utf8;
    char *buffer;
    STRLEN length;
    SV *value;
};

SV * cbf_encode( pTHX_ SV *value, encode_ctx *encode_state, SV *RETVAL );

encode_ctx cbf_encode_ctx_create( uint8_t flags );

void cbf_encode_ctx_free_reftracker( encode_ctx* encode_state );
void cbf_encode_ctx_free_all( encode_ctx* encode_state );

#endif
