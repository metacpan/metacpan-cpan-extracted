#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "types.h"
#include "buffer.h"
#include "encode.h"
#include "runtime.h"
#include "datetime.h"
#include "scalar_kind.h"

static void configure_type(pTHX_ Encoder *enc, TypeInfo *t,
                            CHTimezone *default_tz, int empty_as_null) {
    int i;
    if (t->code == T_DATETIME || t->code == T_DATETIME64) {
        if (t->timezone) t->zones = &enc->zones;
        else t->tz = default_tz;
    }
    if (t->code == T_NULLABLE)
        t->empty_as_null = empty_as_null && t->inner->code != T_STRING
                                         && t->inner->code != T_FIXEDSTRING;
    if (t->inner) configure_type(aTHX_ enc, t->inner, default_tz, empty_as_null);
    for (i = 0; i < t->tuple_len; i++)
        configure_type(aTHX_ enc, t->tuple[i], default_tz, empty_as_null);
}

void configure_encoder(pTHX_ Encoder *enc, const char *timezone, int empty_as_null) {
    CHTimezone *default_tz = timezone_load(aTHX_ &enc->zones, timezone);
    int i;
    enc->timezone = savepv(timezone);
    enc->empty_as_null = empty_as_null;
    for (i = 0; i < enc->num_columns; i++)
        configure_type(aTHX_ enc, enc->columns[i].type, default_tz, empty_as_null);
}

#define CHE_GATHER_COLUMNS 16

static SV *type_default(pTHX_ TypeInfo *t) {
    int i;
    AV *av;
    switch (t->code) {
        case T_NULLABLE: case T_VARIANT: case T_DYNAMIC:
        case T_ENUM8: case T_ENUM16:
            return sv_2mortal(newSV(0));
        case T_LOWCARDINALITY:
            return type_default(aTHX_ t->inner);
        case T_ARRAY: case T_MAP:
            return sv_2mortal(newRV_noinc((SV *)newAV()));
        case T_TUPLE:
            av = (AV *)sv_2mortal((SV *)newAV());
            for (i = 0; i < t->tuple_len; i++)
                av_push(av, SvREFCNT_inc(type_default(aTHX_ t->tuple[i])));
            return sv_2mortal(newRV_inc((SV *)av));
        case T_JSON:
            return sv_2mortal(newRV_noinc((SV *)newHV()));
        case T_STRING: case T_FIXEDSTRING:
            return sv_2mortal(newSVpvs(""));
        case T_UUID: case T_IPV6:
            return sv_2mortal(newSVpvn("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 16));
        default:
            return sv_2mortal(newSViv(0));
    }
}

void configure_defaults(pTHX_ Encoder *enc, int empty_as_default, HV *defaults, HV *expressions) {
    int c;
    HE *entry;
    if (defaults) {
        HV *snapshot = (HV *)sv_2mortal((SV *)newHV());
        hv_iterinit(defaults);
        while ((entry = hv_iternext(defaults))) {
            SV *key = hv_iterkeysv(entry);
            SV *value;
            STRLEN len;
            const char *name = SvPV(key, len);
            for (c = 0; c < enc->num_columns; c++)
                if (enc->columns[c].name_len == len && !memcmp(enc->columns[c].name, name, len)) break;
            if (c == enc->num_columns)
                croak("defaults key '%.*s' matches no column", (int)len, name);
            value = hv_iterval(defaults, entry);
            hv_store_ent(snapshot, key, newSVsv(value), 0);
        }
        defaults = snapshot;
    }
    for (c = 0; c < enc->num_columns; c++) {
        Column *col = &enc->columns[c];
        TypeInfo *t = col->type;
        SV **value = defaults ? fetch_named_value(aTHX_ defaults, col->name, col->name_len) : NULL;
        while (t->code == T_LOWCARDINALITY) t = t->inner;
        if (t->code == T_NULLABLE) continue;
        col->default_flags = t->code != T_STRING && t->code != T_FIXEDSTRING ? DEFAULT_EMPTY_STRING : 0;
        if (value) col->default_value = newSVsv(*value);
        else if (empty_as_default) {
            SV **expr = expressions ? fetch_named_value(aTHX_ expressions, col->name, col->name_len) : NULL;
            if (expr) {
                col->default_flags |= DEFAULT_EXPRESSION;
                col->default_value = newSVsv(*expr);
            } else col->default_value = newSVsv(type_default(aTHX_ col->type));
        }
    }
}

typedef struct {
    Buffer data, nulls;
    TypeInfo *scalar;
    int nullable, complex_slot;
} RowColumn;

static SV *row_value(pTHX_ AV *row, SSize_t pos, AV *owned) {
    int magical = SvMAGICAL(row);
    SV **slot = magical ? pos <= av_len(row) ? av_fetch(row, pos, 0) : NULL
                        : pos <= AvFILLp(row) ? AvARRAY(row) + pos : NULL;
    SV *value = slot && *slot ? *slot : &PL_sv_undef;
    if (magical || SvGMAGICAL(value)) {
        SvGETMAGIC(value);
        value = newSVsv(value);
        if (owned) av_push(owned, value);
        else sv_2mortal(value);
    } else if (owned) av_push(owned, SvREFCNT_inc_simple_NN(value));
    return value;
}

void do_encode(pTHX_ Encoder *enc, AV *rows_av, Buffer *buf, const SSize_t *positions) {
    SSize_t num_rows = av_len(rows_av) + 1;
    SSize_t r, c, required = enc->num_columns;
    int complex_count = 0, group, *complex_columns = NULL;
    SV **gathered;
    RowColumn *states = NULL;
    AV *owned;

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
        if (!positions && row_cols != required)
            croak("Row %" IVdf " has %" IVdf " columns, expected %" IVdf,
                  (IV)r, (IV)row_cols, (IV)required);
        row_avs[r] = row_av;
        if (SvMAGICAL(rows_av) || SvGMAGICAL(*row_sv))
            sv_2mortal(SvREFCNT_inc((SV *)row_av));
    }

    buf_varint(aTHX_ buf, enc->num_columns);
    buf_varint(aTHX_ buf, num_rows);

    if (enc->num_columns) {
        Newxz(states, enc->num_columns, RowColumn);
        SAVEFREEPV(states);
        Newx(complex_columns, enc->num_columns, int);
        SAVEFREEPV(complex_columns);
    }
    for (c = 0; c < enc->num_columns; c++) {
        TypeInfo *type = enc->columns[c].type;
        RowColumn *state = &states[c];
        state->nullable = type->code == T_NULLABLE;
        state->scalar = state->nullable ? type->inner : type;
        if (!is_simple_type(state->scalar)) {
            state->scalar = NULL;
            state->complex_slot = complex_count;
            complex_columns[complex_count++] = c;
        } else if (num_rows) {
            STRLEN width;
            buf_init(aTHX_ &state->data);
            encode_null_scalar(aTHX_ &state->data, state->scalar);
            width = state->data.len;
            state->data.len = 0;
            if ((UV)num_rows > (UV)SSize_t_MAX / width) croak("Too many rows to encode");
            buf_grow(aTHX_ &state->data, num_rows * width);
            if (state->nullable) {
                buf_init(aTHX_ &state->nulls);
                buf_grow(aTHX_ &state->nulls, num_rows);
            }
        }
    }
    group = complex_count < CHE_GATHER_COLUMNS ? complex_count : CHE_GATHER_COLUMNS;
    if (num_rows > SSize_t_MAX / (group ? group : 1) / (SSize_t)sizeof(SV *))
        croak("Too many rows to gather");
    gathered = alloc_sv_array(aTHX_ num_rows * group);
    ENTER;
    SAVETMPS;
    owned = (AV *)sv_2mortal((SV *)newAV());
    for (r = 0; r < num_rows; r++) {
        AV *row = row_avs[r];
        ENTER;
        SAVETMPS;
        for (c = 0; c < enc->num_columns; c++) {
            RowColumn *state = &states[c];
            SSize_t pos = positions ? positions[c] : c;
            SV *value;
            if (state->scalar) {
                value = column_value(aTHX_ &enc->columns[c], row_value(aTHX_ row, pos, NULL));
                if (state->nullable) {
                    int is_null = nullable_is_null(value, enc->columns[c].type);
                    buf_byte(aTHX_ &state->nulls, is_null);
                    if (is_null) {
                        encode_null_scalar(aTHX_ &state->data, state->scalar);
                        continue;
                    }
                }
                encode_scalar(aTHX_ &state->data, value, state->scalar);
            } else if (state->complex_slot < group) {
                value = row_value(aTHX_ row, pos, owned);
                gathered[state->complex_slot * num_rows + r] = column_value(aTHX_ &enc->columns[c], value);
            }
        }
        FREETMPS;
        LEAVE;
    }
    for (c = 0; c < enc->num_columns; c++) {
        Column *col = &enc->columns[c];
        RowColumn *state = &states[c];
        buf_string(aTHX_ buf, col->name, col->name_len);
        buf_string(aTHX_ buf, col->type_str, col->type_len);
        if (state->scalar) {
            if (num_rows) {
                if (state->nullable) buf_append(aTHX_ buf, state->nulls.ptr, state->nulls.len);
                buf_append(aTHX_ buf, state->data.ptr, state->data.len);
            }
        } else {
            int index = state->complex_slot;
            if (index && index % CHE_GATHER_COLUMNS == 0) {
                int end = complex_count - index;
                int j;
                if (end > CHE_GATHER_COLUMNS) end = CHE_GATHER_COLUMNS;
                FREETMPS;
                LEAVE;
                ENTER;
                SAVETMPS;
                owned = (AV *)sv_2mortal((SV *)newAV());
                for (r = 0; r < num_rows; r++) {
                    AV *row = row_avs[r];
                    for (j = 0; j < end; j++) {
                        int column = complex_columns[index + j];
                        SSize_t pos = positions ? positions[column] : column;
                        gathered[j * num_rows + r] = column_value(aTHX_ &enc->columns[column], row_value(aTHX_ row, pos, owned));
                    }
                }
            }
            ENTER;
            SAVETMPS;
            encode_column(aTHX_ buf, num_rows ? gathered + (index % CHE_GATHER_COLUMNS) * num_rows : NULL,
                          num_rows, col->type);
            FREETMPS;
            LEAVE;
        }
    }
    FREETMPS;
    LEAVE;
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
    do_encode(aTHX_ enc, batch, &buf, NULL);

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
        do_encode(aTHX_ s->enc, batch, &buf, NULL);
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
            SvREFCNT_dec(enc->columns[i].default_value);
        }
        Safefree(enc->columns);
    }
    timezone_free(aTHX_ enc->zones);
    Safefree(enc->timezone);
    Safefree(enc);
}

void cleanup_encoder_slot(pTHX_ void *p) {
    Encoder **slot = (Encoder **)p;
    if (*slot) free_encoder(aTHX_ *slot);
}
