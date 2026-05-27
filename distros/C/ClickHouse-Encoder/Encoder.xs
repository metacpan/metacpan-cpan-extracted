#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdint.h>

#if IVSIZE < 8
#error "ClickHouse::Encoder requires a 64-bit Perl (IVSIZE >= 8)"
#endif

#include "types.h"
#include "buffer.h"
#include "encode.h"
#include "decode.h"
#include "runtime.h"
#include "cityhash.h"

/* Read one varint from an SV's byte buffer starting at *off; advances
 * *off past the consumed bytes. Croaks with TCP-style messages on
 * truncation or overflow. Used by the ClickHouse::Encoder::TCP XSUBs
 * which operate on offsets into a Perl scalar rather than the (p,end)
 * cursor pair used by the internal native decoder. */
static UV tcp_read_varint(pTHX_ const unsigned char *p, UV buf_len,
                          UV *off) {
    UV v = 0;
    int shift = 0;
    while (1) {
        if (*off >= buf_len)
            croak("varint: truncated at offset %lu", (unsigned long)*off);
        unsigned char b = p[(*off)++];
        v |= ((UV)(b & 0x7f)) << shift;
        if (!(b & 0x80)) break;
        shift += 7;
        if (shift >= 64) croak("varint exceeds 64 bits");
    }
    return v;
}

MODULE = ClickHouse::Encoder  PACKAGE = ClickHouse::Encoder

SV*
new(class, ...)
    const char *class
CODE:
{
    Encoder *enc = NULL;
    AV *cols_av;
    SSize_t i, n;
    SV *cols_sv = NULL;

    if (items % 2 == 0)
        croak("Expected key-value pairs");

    for (i = 1; i < items; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        if (klen == 7 && memcmp(key, "columns", 7) == 0)
            cols_sv = ST(i+1);
    }

    if (!cols_sv || !SvROK(cols_sv) || SvTYPE(SvRV(cols_sv)) != SVt_PVAV)
        croak("columns required and must be arrayref");

    cols_av = (AV*)SvRV(cols_sv);
    n = av_len(cols_av) + 1;

    /* Wrap allocation in our own ENTER/LEAVE so the cleanup destructor fires
     * before this XSUB returns (XSUBs don't get implicit ENTER/LEAVE). */
    ENTER;
    Newxz(enc, 1, Encoder);
    SAVEDESTRUCTOR_X(cleanup_encoder_slot, &enc);

    Newxz(enc->columns, n, Column);
    enc->num_columns = n;

    for (i = 0; i < n; i++) {
        SV **col_sv = av_fetch(cols_av, i, 0);
        AV *col_av;
        SV **name_sv, **type_sv;
        STRLEN len;
        const char *s;

        if (!col_sv || !SvROK(*col_sv) || SvTYPE(SvRV(*col_sv)) != SVt_PVAV)
            croak("Column must be [name, type]");

        col_av = (AV*)SvRV(*col_sv);
        name_sv = av_fetch(col_av, 0, 0);
        type_sv = av_fetch(col_av, 1, 0);

        if (!name_sv || !type_sv)
            croak("Column must be [name, type]");

        s = SvPV(*name_sv, len);
        Newx(enc->columns[i].name, len + 1, char);
        memcpy(enc->columns[i].name, s, len);
        enc->columns[i].name[len] = 0;
        enc->columns[i].name_len = len;

        s = SvPV(*type_sv, len);
        Newx(enc->columns[i].type_str, len + 1, char);
        memcpy(enc->columns[i].type_str, s, len);
        enc->columns[i].type_str[len] = 0;
        enc->columns[i].type_len = len;

        enc->columns[i].type = parse_type(aTHX_ enc->columns[i].type_str, len);
    }

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, class, (void*)enc);
    enc = NULL;  /* Disarm: the SV's DESTROY now owns the encoder. */
    LEAVE;
}
OUTPUT:
    RETVAL

SV*
encode(self, rows)
    SV *self
    SV *rows
CODE:
{
    Encoder *enc;
    Buffer buf;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("rows must be arrayref");

    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));
    buf_init(aTHX_ &buf);
    do_encode(aTHX_ enc, (AV *)SvRV(rows), &buf);
    RETVAL = newSVpvn(buf.ptr, buf.len);
}
OUTPUT:
    RETVAL

void
encode_into(self, target_ref, rows)
    SV *self
    SV *target_ref
    SV *rows
CODE:
{
    Encoder *enc;
    Buffer buf;
    SV *target;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(target_ref))
        croak("encode_into: first argument must be a scalar reference");
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("rows must be arrayref");

    target = SvRV(target_ref);
    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));

    buf_init(aTHX_ &buf);
    do_encode(aTHX_ enc, (AV *)SvRV(rows), &buf);

    if (!SvOK(target)) sv_setpvn(target, "", 0);
    sv_catpvn(target, buf.ptr, buf.len);
}

void
encode_to_handle(self, fh, rows)
    SV *self
    SV *fh
    SV *rows
CODE:
{
    Encoder *enc;
    Buffer buf;
    IO *io;
    PerlIO *pio;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("rows must be arrayref");
    io = sv_2io(fh);
    if (!io) croak("encode_to_handle: not a filehandle");
    pio = IoOFP(io);
    if (!pio) croak("encode_to_handle: filehandle not open for writing");

    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));
    buf_init(aTHX_ &buf);
    do_encode(aTHX_ enc, (AV *)SvRV(rows), &buf);

    if (PerlIO_write(pio, buf.ptr, buf.len) != (SSize_t)buf.len)
        croak("encode_to_handle: short write: %s", strerror(errno));
}

SV*
encode_columns(self, cols_hv)
    SV *self
    SV *cols_hv
CODE:
{
    /* Column-oriented input: cols_hv is a hashref { name => [v0, v1, ...] }
     * with one array per column, all the same length. Skips the row->column
     * permutation step that encode() does for arrayref-of-arrayref input. */
    Encoder *enc;
    HV *cols;
    Buffer buf;
    SSize_t num_rows = -1;
    int c;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(cols_hv) || SvTYPE(SvRV(cols_hv)) != SVt_PVHV)
        croak("encode_columns: arg must be hashref { name => [...] }");

    cols = (HV *)SvRV(cols_hv);
    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));

    /* Validate: every declared column must be present and same length. */
    for (c = 0; c < enc->num_columns; c++) {
        Column *col = &enc->columns[c];
        SV **slot = hv_fetch(cols, col->name, col->name_len, 0);
        if (!slot || !SvOK(*slot))
            croak("encode_columns: missing column '%.*s'",
                  (int)col->name_len, col->name);
        if (!SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVAV)
            croak("encode_columns: column '%.*s' must be an arrayref",
                  (int)col->name_len, col->name);
        AV *av = (AV *)SvRV(*slot);
        SSize_t n = av_len(av) + 1;
        if (num_rows == -1) num_rows = n;
        else if (n != num_rows)
            croak("encode_columns: column '%.*s' has %" IVdf " rows, "
                  "expected %" IVdf, (int)col->name_len, col->name,
                  (IV)n, (IV)num_rows);
    }
    if (num_rows == -1) num_rows = 0;

    buf_init(aTHX_ &buf);
    buf_varint(aTHX_ &buf, enc->num_columns);
    buf_varint(aTHX_ &buf, num_rows);

    SV **col_values = alloc_sv_array(aTHX_ num_rows);
    for (c = 0; c < enc->num_columns; c++) {
        Column *col = &enc->columns[c];
        SV **slot = hv_fetch(cols, col->name, col->name_len, 0);
        AV *av = (AV *)SvRV(*slot);
        SSize_t r;

        buf_string(aTHX_ &buf, col->name, col->name_len);
        buf_string(aTHX_ &buf, col->type_str, col->type_len);

        for (r = 0; r < num_rows; r++) {
            SV **e = av_fetch(av, r, 0);
            if (e) {
                /* Same magic-realization step as do_encode's gather:
                 * tied per-column AVs return magical placeholders that
                 * downstream SvIV / SvPV won't see until SvGETMAGIC. */
                SvGETMAGIC(*e);
                col_values[r] = *e;
            } else {
                col_values[r] = &PL_sv_undef;
            }
        }
        encode_column(aTHX_ &buf, col_values, num_rows, col->type);
    }

    RETVAL = newSVpvn(buf.ptr, buf.len);
}
OUTPUT:
    RETVAL

void
stream(self, iter, writer, ...)
    SV *self
    SV *iter
    SV *writer
CODE:
{
    /* XS-side iterator loop: pull rows via call_sv, batch them in an AV,
     * encode and call writer on threshold. Saves per-row Perl method
     * dispatch compared to driving the loop from Perl. */
    Encoder *enc;
    int batch_size = 10000;
    AV *batch;
    int n;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(iter)   || SvTYPE(SvRV(iter))   != SVt_PVCV)
        croak("stream: iter must be a coderef");
    if (!SvROK(writer) || SvTYPE(SvRV(writer)) != SVt_PVCV)
        croak("stream: writer must be a coderef");

    /* Optional named arg: batch_size => N */
    if (items > 3) {
        int i;
        for (i = 3; i < items - 1; i += 2) {
            STRLEN klen;
            const char *key = SvPV(ST(i), klen);
            if (klen == 10 && memcmp(key, "batch_size", 10) == 0)
                batch_size = (int)SvIV(ST(i+1));
        }
        if (batch_size < 1) batch_size = 1;
    }

    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));
    batch = (AV *)sv_2mortal((SV *)newAV());

    for (;;) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); PUTBACK;
        n = call_sv(iter, G_SCALAR);
        SPAGAIN;
        SV *row = (n > 0) ? POPs : &PL_sv_undef;
        int got = SvOK(row);
        if (got) SvREFCNT_inc(row);
        PUTBACK;
        FREETMPS; LEAVE;

        if (!got) break;
        av_push(batch, row);
        if (av_len(batch) + 1 >= batch_size) {
            encode_and_emit(aTHX_ enc, batch, writer);
            av_clear(batch);
        }
    }

    if (av_len(batch) >= 0)
        encode_and_emit(aTHX_ enc, batch, writer);
}

SV*
streamer(self, writer, ...)
    SV *self
    SV *writer
CODE:
{
    /* Constructor for ClickHouse::Encoder::Streamer. */
    Streamer *s;
    int batch_size = 10000;
    const char *compress_mode = NULL;
    STRLEN      compress_mode_len = 0;
    SV         *hasher_sv = NULL;

    if (!sv_isobject(self)) croak("Not an object");
    if (!SvROK(writer) || SvTYPE(SvRV(writer)) != SVt_PVCV)
        croak("streamer: writer must be a coderef");

    if (items > 2) {
        int i;
        for (i = 2; i < items - 1; i += 2) {
            STRLEN klen;
            const char *key = SvPV(ST(i), klen);
            if (klen == 10 && memcmp(key, "batch_size", 10) == 0) {
                batch_size = (int)SvIV(ST(i+1));
            }
            else if (klen == 8 && memcmp(key, "compress", 8) == 0
                  && SvOK(ST(i+1))) {
                compress_mode = SvPV(ST(i+1), compress_mode_len);
            }
            else if (klen == 6 && memcmp(key, "hasher", 6) == 0
                  && SvROK(ST(i+1))
                  && SvTYPE(SvRV(ST(i+1))) == SVt_PVCV) {
                hasher_sv = ST(i+1);
            }
        }
        if (batch_size < 1) batch_size = 1;
    }

    /* Construct under our own ENTER/LEAVE so a croak partway through
     * (e.g. OOM in newAV) frees the partially-built struct. */
    ENTER;
    Newxz(s, 1, Streamer);
    SAVEDESTRUCTOR_X(cleanup_streamer_slot, &s);

    /* Hold an owned RV pointing at the same blessed inner SV, so the
     * encoder survives even if the user's $enc goes out of scope. */
    s->enc_sv     = newRV_inc(SvRV(self));
    s->enc        = INT2PTR(Encoder*, SvIV(SvRV(s->enc_sv)));
    s->writer     = newSVsv(writer);
    s->buffer     = newAV();
    s->batch_size = batch_size;

    /* Copy the compress mode into Streamer-owned memory. NULL / "none" /
     * "raw" are all treated as "no compression" by streamer_flush. */
    if (compress_mode
        && !(compress_mode_len == 0)
        && !(compress_mode_len == 4 && memcmp(compress_mode, "none", 4) == 0)
        && !(compress_mode_len == 3 && memcmp(compress_mode, "raw",  3) == 0)) {
        Newx(s->compress_mode, compress_mode_len + 1, char);
        memcpy(s->compress_mode, compress_mode, compress_mode_len);
        s->compress_mode[compress_mode_len] = '\0';
    }
    if (hasher_sv) s->hasher_sv = newSVsv(hasher_sv);

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "ClickHouse::Encoder::Streamer", (void *)s);
    s = NULL;  /* disarm: SV's DESTROY now owns the streamer */
    LEAVE;
}
OUTPUT:
    RETVAL

SV*
_columns(self)
    SV *self
CODE:
{
    Encoder *enc;
    AV *cols;
    int i;

    if (!sv_isobject(self))
        croak("Not an object");

    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));
    cols = newAV();

    for (i = 0; i < enc->num_columns; i++) {
        AV *col = newAV();
        av_push(col, newSVpvn(enc->columns[i].name, enc->columns[i].name_len));
        av_push(col, newSVpvn(enc->columns[i].type_str, enc->columns[i].type_len));
        av_push(cols, newRV_noinc((SV*)col));
    }

    RETVAL = newRV_noinc((SV*)cols);
}
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
{
    Encoder *enc;
    if (!sv_isobject(self)) return;
    enc = INT2PTR(Encoder*, SvIV(SvRV(self)));
    free_encoder(aTHX_ enc);
}

SV *
decode_block(class, bytes, ...)
    SV *class
    SV *bytes
CODE:
{
    PERL_UNUSED_VAR(class);
    /* Optional 3rd arg: byte offset into the input. Lets callers walk
     * a concatenated multi-block stream in O(N) instead of O(N*K) - the
     * Perl-side decode_blocks wrapper relies on this to avoid substr
     * copies on each iteration.
     *
     * Optional 4th arg: hashref of column names to KEEP. When provided,
     * columns whose name isn't in the set get a placeholder values
     * arrayref (one undef per row) and the wire bytes are still consumed
     * for that column's data, but no SVs are allocated for the values.
     * Memory win on wide SELECT * when caller wants a few columns. */
    UV start_offset = 0;
    HV *keep_set = NULL;
    if (items >= 3) {
        IV signed_off = SvIV(ST(2));
        if (signed_off < 0)
            croak("decode_block: offset must be non-negative (got %"
                  IVdf ")", signed_off);
        start_offset = (UV)signed_off;
    }
    if (items >= 4 && SvOK(ST(3))) {
        if (!SvROK(ST(3)) || SvTYPE(SvRV(ST(3))) != SVt_PVHV)
            croak("decode_block: columns filter must be a hashref "
                  "(got %s)",
                  SvROK(ST(3)) ? sv_reftype(SvRV(ST(3)), 0)
                               : "non-reference");
        keep_set = (HV *)SvRV(ST(3));
    }
    const unsigned char *start, *p, *end;
    UV ncols, nrows;
    decode_block_prologue(aTHX_ bytes, start_offset, "decode_block",
                          &start, &p, &end, &ncols, &nrows);

    /* Mortalize cols so a mid-loop croak (from decode_column,
     * dec_lenpfx_string, etc.) reclaims it instead of leaking. We
     * SvREFCNT_inc when transferring ownership to the result HV. */
    AV *cols = (AV *)sv_2mortal((SV *)newAV());
    if (ncols > 0) av_extend(cols, ncols - 1);
    UV c;
    for (c = 0; c < ncols; c++) {
        const char *name; STRLEN name_len;
        const char *tstr; STRLEN tlen;
        dec_lenpfx_string(aTHX_ &p, end, &name, &name_len);
        dec_lenpfx_string(aTHX_ &p, end, &tstr, &tlen);
        /* parse_type uses heap-slot SAVEDESTRUCTOR_X for cleanup on
         * croak; on success the slot is disarmed. We're in the XSUB's
         * implicit save scope, so a croak from any nested decode
         * unwinds the type back through this cleanup. */
        TypeInfo *t = parse_type(aTHX_ tstr, tlen);

        int keep = 1;
        if (keep_set && !hv_exists(keep_set, name, name_len))
            keep = 0;

        SV *values;
        if (keep) {
            values = decode_column(aTHX_ &p, end, t, (SSize_t)nrows);
        } else {
            /* Decode then discard - we still must consume the wire
             * bytes to keep the cursor aligned for the next column.
             * The AV is freed immediately so peak memory is one
             * column's values, not the full block's. */
            SV *tmp = decode_column(aTHX_ &p, end, t, (SSize_t)nrows);
            SvREFCNT_dec(tmp);
            AV *placeholder = newAV();
            if (nrows > 0) {
                av_extend(placeholder, nrows - 1);
                SSize_t r;
                for (r = 0; r < (SSize_t)nrows; r++)
                    av_store(placeholder, r, newSV(0));
            }
            values = newRV_noinc((SV *)placeholder);
        }
        /* Free this column's TypeInfo eagerly to avoid piling them up
         * on the save stack for wide blocks. */
        free_typeinfo(aTHX_ t);

        HV *col_hv = newHV();
        (void)hv_stores(col_hv, "name",   newSVpvn(name, name_len));
        (void)hv_stores(col_hv, "type",   newSVpvn(tstr, tlen));
        (void)hv_stores(col_hv, "values", values);
        if (!keep) (void)hv_stores(col_hv, "skipped", newSViv(1));
        av_store(cols, c, newRV_noinc((SV *)col_hv));
    }

    HV *result = newHV();
    (void)hv_stores(result, "ncols",    newSVuv(ncols));
    (void)hv_stores(result, "nrows",    newSVuv(nrows));
    /* Transfer ownership out of the mortal: bump refcount, then the
     * mortal-stack cleanup at scope exit drops one back, leaving the
     * net refcount at 1 (owned by `result`). */
    (void)hv_stores(result, "columns",
                    newRV_inc((SV *)cols));
    (void)hv_stores(result, "consumed", newSVuv((UV)(p - start)));
    RETVAL = newRV_noinc((SV *)result);
}
OUTPUT: RETVAL

# Row-oriented decoder: same wire walk as decode_block, but values are
# distributed into row-major arrayrefs as each column is decoded, then
# the per-column AV is freed. Peak memory holds one column's values
# plus all row AVs (vs decode_rows-via-Perl which holds both
# representations + does the transpose in Perl).
SV *
decode_block_rows(class, bytes, ...)
    SV *class
    SV *bytes
CODE:
{
    PERL_UNUSED_VAR(class);
    UV start_offset = 0;
    if (items >= 3) {
        IV signed_off = SvIV(ST(2));
        if (signed_off < 0)
            croak("decode_block_rows: offset must be non-negative "
                  "(got %" IVdf ")", signed_off);
        start_offset = (UV)signed_off;
    }
    const unsigned char *start, *p, *end;
    UV ncols, nrows;
    decode_block_prologue(aTHX_ bytes, start_offset, "decode_block_rows",
                          &start, &p, &end, &ncols, &nrows);

    /* Mortalize so a mid-loop croak unwinds and reclaims these
     * (and, via the row RVs they hold, all populated row AVs).
     * SvREFCNT_inc-via-newRV_inc transfers them to the result HV
     * on the success path. */
    AV *names = (AV *)sv_2mortal((SV *)newAV());
    AV *types = (AV *)sv_2mortal((SV *)newAV());
    AV *rows  = (AV *)sv_2mortal((SV *)newAV());
    if (ncols > 0) { av_extend(names, ncols - 1); av_extend(types, ncols - 1); }
    if (nrows > 0) av_extend(rows, nrows - 1);

    /* Pre-create row AVs - we'll fill column c into row_av[c] as we
     * decode each column. Stash AV pointers for fast access. */
    AV **row_avs = NULL;
    if (nrows > 0) {
        Newx(row_avs, nrows, AV *);
        SAVEFREEPV(row_avs);
        UV r;
        for (r = 0; r < nrows; r++) {
            AV *row_av = newAV();
            if (ncols > 0) av_extend(row_av, ncols - 1);
            row_avs[r] = row_av;
            av_store(rows, r, newRV_noinc((SV *)row_av));
        }
    }

    UV c;
    for (c = 0; c < ncols; c++) {
        const char *name; STRLEN name_len;
        const char *tstr; STRLEN tlen;
        dec_lenpfx_string(aTHX_ &p, end, &name, &name_len);
        dec_lenpfx_string(aTHX_ &p, end, &tstr, &tlen);
        TypeInfo *t = parse_type(aTHX_ tstr, tlen);
        SV *col_rv = decode_column(aTHX_ &p, end, t, (SSize_t)nrows);
        free_typeinfo(aTHX_ t);

        AV *col_av = (AV *)SvRV(col_rv);
        UV r;
        for (r = 0; r < nrows; r++) {
            SV **e = av_fetch(col_av, r, 0);
            av_store(row_avs[r], c, e ? SvREFCNT_inc(*e) : newSV(0));
        }
        /* Free the column AV eagerly; we no longer need it. */
        SvREFCNT_dec(col_rv);

        av_store(names, c, newSVpvn(name, name_len));
        av_store(types, c, newSVpvn(tstr, tlen));
    }

    HV *result = newHV();
    (void)hv_stores(result, "ncols",    newSVuv(ncols));
    (void)hv_stores(result, "nrows",    newSVuv(nrows));
    /* Transfer ownership out of the mortal stack: newRV_inc bumps
     * the AV refcount so when the mortal cleanup drops one, the net
     * count stays at 1 (owned by `result`). */
    (void)hv_stores(result, "names", newRV_inc((SV *)names));
    (void)hv_stores(result, "types", newRV_inc((SV *)types));
    (void)hv_stores(result, "rows",  newRV_inc((SV *)rows));
    (void)hv_stores(result, "consumed", newSVuv((UV)(p - start)));
    RETVAL = newRV_noinc((SV *)result);
}
OUTPUT: RETVAL

# CityHash128 in the "cityhash102" variant used by ClickHouse's
# compressed-block prefix. Returns a 16-byte string (8 bytes low,
# then 8 bytes high; matches the wire layout CH expects). Exposed
# so compress_native_block can default its `hasher` to this XSUB
# instead of forcing every caller to supply one.
SV *
_cityhash128(class_or_bytes, ...)
    SV *class_or_bytes
CODE:
{
    SV *input_sv;
    /* Accept both class-method ($class->_cityhash128($bytes)) and
     * function-style (\&_cityhash128 passed as a hasher coderef)
     * call shapes. A class-method call has items >= 2 and the first
     * arg is a non-reference string (the class name); a coderef call
     * has items == 1 and the first arg IS the bytes. */
    if (items >= 2 && SvPOK(class_or_bytes) && !SvROK(class_or_bytes)) {
        input_sv = ST(1);
    } else {
        input_sv = class_or_bytes;
    }
    STRLEN len;
    const char *s = SvPVbyte(input_sv, len);
    unsigned char out[16];
    cityhash128_v102(s, (size_t)len, out);
    RETVAL = newSVpvn((const char *)out, 16);
}
OUTPUT: RETVAL

MODULE = ClickHouse::Encoder  PACKAGE = ClickHouse::Encoder::Streamer

void
push_row(self, row)
    SV *self
    SV *row
CODE:
{
    Streamer *s;
    if (!sv_isobject(self)) croak("Not an object");
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    av_push(s->buffer, SvREFCNT_inc(row));
    if (av_len(s->buffer) + 1 >= s->batch_size)
        streamer_flush(aTHX_ s);
}

void
finish(self)
    SV *self
CODE:
{
    Streamer *s;
    if (!sv_isobject(self)) croak("Not an object");
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    streamer_flush(aTHX_ s);
}

void
reset(self)
    SV *self
CODE:
{
    /* Discard buffered rows without flushing -- useful for error recovery
     * after an upstream failure when the in-flight batch should be dropped. */
    Streamer *s;
    if (!sv_isobject(self)) croak("Not an object");
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    if (av_len(s->buffer) >= 0) av_clear(s->buffer);
}

UV
buffered_count(self)
    SV *self
CODE:
{
    Streamer *s;
    if (!sv_isobject(self)) croak("Not an object");
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    RETVAL = (UV)(av_len(s->buffer) + 1);
}
OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
CODE:
{
    Streamer *s;
    if (!sv_isobject(self)) croak("Not an object");
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    RETVAL = (av_len(s->buffer) < 0);
}
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
{
    Streamer *s;
    if (!sv_isobject(self)) return;
    s = INT2PTR(Streamer *, SvIV(SvRV(self)));
    free_streamer(aTHX_ s);
}

MODULE = ClickHouse::Encoder  PACKAGE = ClickHouse::Encoder::TCP

# Pack an unsigned varint (LEB128 / CH varuint form). Used by the
# protocol-packet builders in ClickHouse::Encoder::TCP. Equivalent
# to the buf_varint() internal helper but exposed as a Perl callable
# so the pure-Perl module can produce wire-format bytes via XS rather
# than a per-byte chr/shift loop.
SV *
pack_varint(v)
    UV v
CODE:
{
    char buf[10];
    int i = 0;
    while (v >= 0x80) {
        buf[i++] = (char)((v & 0x7f) | 0x80);
        v >>= 7;
    }
    buf[i++] = (char)v;
    RETVAL = newSVpvn(buf, i);
}
OUTPUT:
    RETVAL

# Unpack one varint from a byte string starting at the given offset.
# Returns (value, new_offset). Croaks on truncated input or a varint
# wider than 64 bits.
void
unpack_varint(bytes, offset)
    SV *bytes
    UV offset
PPCODE:
{
    STRLEN len;
    const unsigned char *p = (const unsigned char *)SvPVbyte(bytes, len);
    UV v = tcp_read_varint(aTHX_ p, (UV)len, &offset);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVuv(v)));
    PUSHs(sv_2mortal(newSVuv(offset)));
}

# Pack a length-prefixed string (varint length + UTF-8 bytes). The
# caller should pass Perl strings; we encode to UTF-8 explicitly so
# non-ASCII chars get the right byte length on the wire.
SV *
pack_string(s)
    SV *s
CODE:
{
    STRLEN len;
    const char *p;
    if (!SvOK(s)) {
        p = ""; len = 0;
    } else {
        /* SvPVutf8 returns the UTF-8 byte form */
        p = SvPVutf8(s, len);
    }
    /* Build prefix + bytes. */
    char prefix[10];
    int pi = 0;
    UV vv = (UV)len;
    while (vv >= 0x80) {
        prefix[pi++] = (char)((vv & 0x7f) | 0x80);
        vv >>= 7;
    }
    prefix[pi++] = (char)vv;
    RETVAL = newSVpvn(prefix, pi);
    sv_catpvn(RETVAL, p, len);
}
OUTPUT:
    RETVAL

# Unpack a length-prefixed string at the given offset. Returns (string,
# new_offset). String bytes are returned without decoding (caller
# decides UTF-8 vs binary).
void
unpack_string(bytes, offset)
    SV *bytes
    UV offset
PPCODE:
{
    STRLEN buf_len;
    const unsigned char *p = (const unsigned char *)SvPVbyte(bytes, buf_len);
    UV slen = tcp_read_varint(aTHX_ p, (UV)buf_len, &offset);
    /* Subtraction form: addition (offset + slen) can wrap UV_MAX when
     * slen is attacker-controlled via a crafted varint. tcp_read_varint
     * guarantees offset <= buf_len on return, so buf_len - offset is
     * safe. */
    if (slen > (UV)buf_len - offset)
        croak("string: truncated at offset %lu (need %lu)",
              (unsigned long)offset, (unsigned long)slen);
    SV *out = newSVpvn((const char *)(p + offset), (STRLEN)slen);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(out));
    PUSHs(sv_2mortal(newSVuv(offset + slen)));
}

