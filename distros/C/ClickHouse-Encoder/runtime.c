#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "types.h"
#include "buffer.h"
#include "encode.h"
#include "runtime.h"

void do_encode(pTHX_ Encoder *enc, AV *rows_av, Buffer *buf) {
    SSize_t num_rows = av_len(rows_av) + 1;
    SSize_t r, c;

    /* Validate every row up front and cache the dereffed AV*. Caching
     * avoids a second av_fetch per row in the column loop and removes
     * any concern about tied / magic arrays returning different values
     * across passes. */
    AV **row_avs = NULL;
    if (num_rows > 0) {
        Newx(row_avs, num_rows, AV*);
        SAVEFREEPV(row_avs);
    }
    for (r = 0; r < num_rows; r++) {
        SV **row_sv = av_fetch(rows_av, r, 0);
        AV *row_av;
        SSize_t row_cols;
        if (!row_sv)
            croak("Row %" IVdf " must be arrayref", (IV)r);
        /* Materialize any magic on the fetched SV - for tied AVs the
         * FETCH result is delivered through magic and SvROK / SvTYPE
         * see the unrealized magical placeholder until SvGETMAGIC has
         * been called. Common in DBI-driven ingest (fetchall_arrayref
         * may return magical AVs at either level). */
        SvGETMAGIC(*row_sv);
        if (!SvROK(*row_sv) || SvTYPE(SvRV(*row_sv)) != SVt_PVAV)
            croak("Row %" IVdf " must be arrayref", (IV)r);
        row_av = (AV*)SvRV(*row_sv);
        row_cols = av_len(row_av) + 1;
        if (row_cols != enc->num_columns)
            croak("Row %" IVdf " has %" IVdf " columns, expected %d",
                  (IV)r, (IV)row_cols, enc->num_columns);
        row_avs[r] = row_av;
    }

    buf_varint(aTHX_ buf, enc->num_columns);
    buf_varint(aTHX_ buf, num_rows);

    SV **col_values = alloc_sv_array(aTHX_ num_rows);

    for (c = 0; c < enc->num_columns; c++) {
        Column *col = &enc->columns[c];
        buf_string(aTHX_ buf, col->name, col->name_len);
        buf_string(aTHX_ buf, col->type_str, col->type_len);
        for (r = 0; r < num_rows; r++) {
            SV **val_sv = av_fetch(row_avs[r], c, 0);
            if (val_sv) {
                /* Same magic-realization step as the row-level loop:
                 * tied inner AVs return magical placeholders whose
                 * SvPVbyte / SvIV / SvNV downstream won't pick up the
                 * real value until SvGETMAGIC has fired. */
                SvGETMAGIC(*val_sv);
                col_values[r] = *val_sv;
            } else {
                col_values[r] = &PL_sv_undef;
            }
        }
        encode_column(aTHX_ buf, col_values, num_rows, col->type);
    }
}

/* Route `bytes` through ClickHouse::Encoder->compress_native_block
 * and return a freshly-allocated SV with the compressed-block-framed
 * result. Caller takes ownership (refcount 1) and is responsible for
 * mortalizing or freeing. mode == NULL / "none" / "raw" -> just bumps
 * the input's refcount and returns it. */
static SV *maybe_compress(pTHX_ SV *bytes,
                          const char *mode, SV *hasher_sv) {
    if (!mode || strcmp(mode, "none") == 0 || strcmp(mode, "raw") == 0)
        return SvREFCNT_inc(bytes);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("ClickHouse::Encoder")));
    XPUSHs(bytes);
    XPUSHs(sv_2mortal(newSVpvs("mode")));
    XPUSHs(sv_2mortal(newSVpv(mode, 0)));
    if (hasher_sv) {
        XPUSHs(sv_2mortal(newSVpvs("hasher")));
        XPUSHs(hasher_sv);
    }
    PUTBACK;
    int n = call_method("compress_native_block", G_SCALAR);
    SPAGAIN;
    SV *out = NULL;
    if (n == 1) {
        /* POPs gives a mortal SV; copy its body via newSVsv into a
         * non-mortal SV that survives the FREETMPS below. */
        out = newSVsv(POPs);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (!out) croak("streamer: compress_native_block returned nothing");
    return out;
}

void encode_and_emit(pTHX_ Encoder *enc, AV *batch, SV *writer) {
    dSP;
    ENTER;
    SAVETMPS;

    Buffer buf;
    buf_init(aTHX_ &buf);
    do_encode(aTHX_ enc, batch, &buf);

    SV *bytes = sv_2mortal(newSVpvn(buf.ptr, buf.len));

    PUSHMARK(SP);
    XPUSHs(bytes);
    PUTBACK;
    call_sv(writer, G_VOID | G_DISCARD);

    FREETMPS;
    LEAVE;
}

void streamer_flush(pTHX_ Streamer *s) {
    if (av_len(s->buffer) < 0) return;
    /* Swap in a fresh buffer BEFORE the (potentially croaking) emit so that
     * if the writer dies and the user catches it via eval{}, the streamer
     * is left in a clean state instead of replaying the failed batch's rows
     * on the next push. The old buffer is mortalized so it's reclaimed
     * either way. */
    AV *batch  = s->buffer;
    s->buffer  = newAV();
    sv_2mortal((SV *)batch);

    /* If compression is enabled, build the bytes locally then route them
     * through compress_native_block before invoking the user's writer.
     * Otherwise fall through to encode_and_emit's direct call. */
    if (s->compress_mode) {
        dSP;
        ENTER;
        SAVETMPS;
        Buffer buf;
        buf_init(aTHX_ &buf);
        do_encode(aTHX_ s->enc, batch, &buf);
        SV *bytes = sv_2mortal(newSVpvn(buf.ptr, buf.len));
        /* maybe_compress returns an owned SV (refcount 1); mortalize it
         * here so it's cleaned up after the writer call. */
        SV *out = sv_2mortal(
            maybe_compress(aTHX_ bytes, s->compress_mode, s->hasher_sv));
        PUSHMARK(SP);
        XPUSHs(out);
        PUTBACK;
        call_sv(s->writer, G_VOID | G_DISCARD);
        FREETMPS;
        LEAVE;
        return;
    }
    encode_and_emit(aTHX_ s->enc, batch, s->writer);
}

void free_streamer(pTHX_ Streamer *s) {
    if (!s) return;
    if (s->enc_sv)        SvREFCNT_dec(s->enc_sv);
    if (s->writer)        SvREFCNT_dec(s->writer);
    if (s->buffer)        SvREFCNT_dec((SV *)s->buffer);
    if (s->compress_mode) Safefree(s->compress_mode);
    if (s->hasher_sv)     SvREFCNT_dec(s->hasher_sv);
    Safefree(s);
}

void cleanup_streamer_slot(pTHX_ void *p) {
    Streamer **slot = (Streamer **)p;
    if (*slot) free_streamer(aTHX_ *slot);
}

void free_encoder(pTHX_ Encoder *enc) {
    int i;
    if (!enc) return;
    if (enc->columns) {
        for (i = 0; i < enc->num_columns; i++) {
            if (enc->columns[i].name)     Safefree(enc->columns[i].name);
            if (enc->columns[i].type_str) Safefree(enc->columns[i].type_str);
            if (enc->columns[i].type)     free_typeinfo(aTHX_ enc->columns[i].type);
        }
        Safefree(enc->columns);
    }
    Safefree(enc);
}

void cleanup_encoder_slot(pTHX_ void *p) {
    Encoder **slot = (Encoder **)p;
    if (*slot) free_encoder(aTHX_ *slot);
}
