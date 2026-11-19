#ifndef CHE_RUNTIME_H
#define CHE_RUNTIME_H

/* See buffer.h for the include-order convention (EXTERN.h + perl.h +
 * XSUB.h must be included by the caller before this header). */

#include "types.h"
#include "buffer.h"

enum { DEFAULT_EMPTY_STRING = 1, DEFAULT_EXPRESSION = 2 };

/* One column entry in an Encoder: name and type-string survive as
 * heap-owned NUL-padded buffers; type is the parsed TypeInfo tree. */
typedef struct {
    char *name;
    STRLEN name_len;
    char *type_str;
    STRLEN type_len;
    TypeInfo *type;
    SV *default_value; /* unresolved expression when DEFAULT_EXPRESSION is set */
    int default_flags;
} Column;

PERL_STATIC_INLINE SV *column_value(pTHX_ Column *col, SV *value) {
    if (col->default_value && (!SvOK(value)
        || ((col->default_flags & DEFAULT_EMPTY_STRING) && !SvROK(value) && SvPOK(value) && !SvCUR(value)))) {
        if (col->default_flags & DEFAULT_EXPRESSION)
            croak("Column '%.*s' has non-literal DEFAULT '%s'; pass defaults => {'%.*s' => ...}",
                  (int)col->name_len, col->name, SvPV_nolen(col->default_value),
                  (int)col->name_len, col->name);
        return col->default_value;
    }
    return value;
}

typedef struct {
    Column *columns;
    int num_columns;
    CHTimezone *zones;
    char *timezone;
    int empty_as_null;
} Encoder;

/* Streamer: collects rows in an AV and flushes one Native block per
 * batch. Holds strong refs to keep the underlying encoder/writer/buffer
 * AVs alive for the streamer's lifetime. */
typedef struct {
    SV *enc_sv;        /* strong ref to keep the encoder alive */
    Encoder *enc;      /* unowned cached pointer */
    SV *writer;        /* strong ref to the writer CV */
    AV *buffer;        /* strong ref - owned */
    int batch_size;
    /* When non-NULL, every emitted batch is wrapped in CH's
     * compressed-block framing via compress_native_block before being
     * passed to writer. compress_mode is one of "lz4" / "zstd" /
     * "auto" / "none"; hasher_sv (if non-NULL) overrides the default
     * cityhash128. Both are owned by the Streamer. */
    char *compress_mode;
    SV   *hasher_sv;
} Streamer;

/* Encode `rows_av` (an AV of arrayrefs, one per row) into `buf`. Validates
 * shape per Encoder schema; croaks on malformed input. */
void do_encode(pTHX_ Encoder *enc, AV *rows_av, Buffer *buf, const SSize_t *positions);
void configure_encoder(pTHX_ Encoder *enc, const char *timezone, int empty_as_null);
void configure_defaults(pTHX_ Encoder *enc, int empty_as_default, HV *defaults, HV *expressions);

/* Encode `batch` into a fresh Native block and pass the bytes to `writer`.
 * Wrapped in ENTER/SAVETMPS/FREETMPS/LEAVE so per-batch mortals don't
 * accumulate on the caller's tmps stack across a long stream() loop. */
void encode_and_emit(pTHX_ Encoder *enc, AV *batch, SV *writer);

/* Streamer flush: emits buffered rows (swap-before-emit so a writer croak
 * leaves the streamer in a clean state). No-op when buffer is empty. */
void streamer_flush(pTHX_ Streamer *s);

/* Free an Encoder and all its owned columns/types. NULL-safe. */
void free_encoder (pTHX_ Encoder *enc);
void free_streamer(pTHX_ Streamer *s);

/* Slot-indirection cleanup callbacks for SAVEDESTRUCTOR_X: pass &slot
 * where slot is the Encoder or Streamer pointer you just allocated.
 * After the construction succeeds and the SV takes ownership, set
 * slot = NULL to disarm. */
void cleanup_encoder_slot (pTHX_ void *p);
void cleanup_streamer_slot(pTHX_ void *p);

#endif
