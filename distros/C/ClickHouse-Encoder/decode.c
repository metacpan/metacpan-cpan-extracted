#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdint.h>

#include "types.h"
#include "decimal.h"
#include "datetime.h"
#include "json_kind.h"
#include "decode.h"


/* ===== DECODER ============================================================
 * Symmetric counterpart to encode_column. Reads raw Native bytes through
 * a (cursor, end) pair, recursively building SVs. parse_type() returns
 * the same TypeInfo* used on the encode side, so the type tree is shared. */

/* Subtraction form: the more obvious `(*p) + (needed) > end` form
 * overflows the pointer when `needed` is attacker-controlled via a
 * crafted varint (CH varints can encode up to ~2^63). All call sites
 * maintain the invariant `*p <= end`, so `end - *p` is a safe pointer
 * difference yielding a non-negative `ptrdiff_t` we can compare against
 * `needed` as a UV. */
#define DEC_NEED(needed)                                                     \
    do {                                                                     \
        if ((UV)(needed) > (UV)(end - (*p)))                                 \
            croak("decode: buffer truncated (need %lu more bytes)",          \
                  (unsigned long)(needed));                                  \
    } while (0)

/* Read a little-endian multi-byte unsigned integer from a byte buffer.
 * Endianness-portable replacement for `memcpy(&v, ptr, N)`, which would
 * read big-endian values on a BE host and silently misdecode the wire
 * (CH Native is LE everywhere). For signed and floating-point reads,
 * the caller bit-casts via memcpy from the unsigned result. */
static inline uint16_t dec_le16(const unsigned char *b) {
    return (uint16_t)b[0] | ((uint16_t)b[1] << 8);
}
static inline uint32_t dec_le32(const unsigned char *b) {
    return (uint32_t)b[0]
         | ((uint32_t)b[1] << 8)
         | ((uint32_t)b[2] << 16)
         | ((uint32_t)b[3] << 24);
}
static inline uint64_t dec_le64(const unsigned char *b) {
    return (uint64_t)b[0]
         | ((uint64_t)b[1] << 8)
         | ((uint64_t)b[2] << 16)
         | ((uint64_t)b[3] << 24)
         | ((uint64_t)b[4] << 32)
         | ((uint64_t)b[5] << 40)
         | ((uint64_t)b[6] << 48)
         | ((uint64_t)b[7] << 56);
}

UV dec_varint(pTHX_ const unsigned char **p, const unsigned char *end) {
    UV v = 0;
    int shift = 0;
    while (1) {
        DEC_NEED(1);
        unsigned char b = *(*p)++;
        v |= ((UV)(b & 0x7f)) << shift;
        if (!(b & 0x80)) break;
        shift += 7;
        if (shift >= 64) croak("decode: varint exceeds 64 bits");
    }
    return v;
}

void dec_lenpfx_string(pTHX_ const unsigned char **p,
                              const unsigned char *end,
                              const char **out_s, STRLEN *out_len) {
    UV len = dec_varint(aTHX_ p, end);
    DEC_NEED(len);
    *out_s   = (const char *)(*p);
    *out_len = (STRLEN)len;
    *p      += len;
}

/* Shared prologue for decode_block / decode_block_rows: validate the
 * input SV, position the cursor at the requested offset, read the
 * block header (ncols + nrows), and run bounds checks. `fname` is
 * embedded in croak messages so each XSUB reports its own name.
 * Returns ncols/nrows by out-param; the cursor pair (p, end) is set
 * up so the caller can resume column-by-column decoding. */
void decode_block_prologue(pTHX_ SV *bytes, UV start_offset,
                                  const char *fname,
                                  const unsigned char **out_start,
                                  const unsigned char **out_p,
                                  const unsigned char **out_end,
                                  UV *out_ncols, UV *out_nrows) {
    /* Materialize lvalue / magical SVs (e.g. the PVLV returned by 2-arg
     * substr) before inspecting. SvOK on a fresh substr-LV returns
     * false until SvGETMAGIC has run; SvPVbyte itself triggers the
     * magic, so we just go straight to it and let buf_len = 0 cover
     * the genuine empty-bytes case. Reject only true undef. */
    SvGETMAGIC(bytes);
    if (!SvOK(bytes)) croak("%s: bytes argument is undef", fname);
    STRLEN buf_len;
    const char *buf = SvPVbyte(bytes, buf_len);
    if (start_offset > buf_len)
        croak("%s: offset %lu past end of buffer (%lu bytes)",
              fname, (unsigned long)start_offset, (unsigned long)buf_len);
    const unsigned char *p     = (const unsigned char *)buf + start_offset;
    const unsigned char *start = p;
    const unsigned char *end   = (const unsigned char *)buf + buf_len;

    UV ncols = dec_varint(aTHX_ &p, end);
    UV nrows = dec_varint(aTHX_ &p, end);

    /* Defensive bounds: ncols and nrows from the wire could be
     * arbitrarily large in a malicious or corrupted block. Each column
     * needs at least 2 bytes of name+type header; each row of the
     * smallest type takes at least 1 byte. Reject obviously-impossible
     * counts up front so we never allocate gigabytes for fuzz input. */
    if (ncols > (UV)(end - p))
        croak("%s: ncols=%lu exceeds remaining buffer (%lu bytes)",
              fname, (unsigned long)ncols, (unsigned long)(end - p));
    UV remaining_after_headers = (UV)(end - p);
    if (nrows > remaining_after_headers && nrows > 0)
        croak("%s: nrows=%lu exceeds remaining buffer (%lu bytes)",
              fname, (unsigned long)nrows,
              (unsigned long)remaining_after_headers);

    *out_start = start;
    *out_p     = p;
    *out_end   = end;
    *out_ncols = ncols;
    *out_nrows = nrows;
}

/* Build a JSON-style boolean SV: bless(\(b ? 1 : 0), 'JSON::PP::Boolean').
 * Used when decoding JSON/Dynamic Bool variant slots so that re-encoding
 * the round-tripped value picks the same Bool wire variant instead of
 * widening it to Int64 (which a naked newSViv(0|1) would trigger). The
 * blessed package matches what json_pkg_is_bool() recognizes on the
 * encode side. */
static SV *make_json_bool_sv(pTHX_ int b) {
    SV *inner = newSViv(b ? 1 : 0);
    SV *rv    = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv("JSON::PP::Boolean", GV_ADD));
    return rv;
}

/* Decode one Dynamic/JSON variant wire slot into `sub`. `kind` is a
 * JsonValueKind (or -1 for SharedVariant, which we read as String).
 * Shared by both T_JSON and T_DYNAMIC decode paths; `ctx` is "JSON" or
 * "Dynamic" for diagnostic context. The caller has already extended
 * `sub` and mortalized it. */
static void decode_dynamic_variant_slot(pTHX_ const unsigned char **p,
                                        const unsigned char *end,
                                        AV *sub, int kind, SSize_t nv_rows,
                                        const char *ctx) {
    SSize_t k;
    if (kind < 0 || kind == JV_STRING) {
        /* SharedVariant (-1) is a String column on the wire; same path. */
        for (k = 0; k < nv_rows; k++) {
            const char *vs; STRLEN vl;
            dec_lenpfx_string(aTHX_ p, end, &vs, &vl);
            av_store(sub, k, newSVpvn(vs, vl));
        }
        return;
    }
    if (kind == JV_INT64) {
        /* Division-form bounds check avoids overflow when nv_rows is
         * attacker-controlled (variant disc bytes determine it). */
        if ((UV)nv_rows > (UV)(end - *p) / 8)
            croak("decode: buffer truncated (need %lu more bytes)",
                  (unsigned long)((UV)nv_rows * 8));
        for (k = 0; k < nv_rows; k++) {
            uint64_t u = dec_le64(*p); *p += 8;
            int64_t v;  memcpy(&v, &u, 8);
            av_store(sub, k, newSViv((IV)v));
        }
        return;
    }
    if (kind == JV_FLOAT64) {
        if ((UV)nv_rows > (UV)(end - *p) / 8)
            croak("decode: buffer truncated (need %lu more bytes)",
                  (unsigned long)((UV)nv_rows * 8));
        for (k = 0; k < nv_rows; k++) {
            uint64_t u = dec_le64(*p); *p += 8;
            double v;  memcpy(&v, &u, 8);
            av_store(sub, k, newSVnv(v));
        }
        return;
    }
    if (kind == JV_BOOL) {
        if ((UV)nv_rows > (UV)(end - *p))
            croak("decode: buffer truncated (need %lu more bytes)",
                  (unsigned long)nv_rows);
        for (k = 0; k < nv_rows; k++) {
            unsigned char b = *(*p)++;
            av_store(sub, k, make_json_bool_sv(aTHX_ b));
        }
        return;
    }
    if (kind == JV_ARRAY_BOOL || kind == JV_ARRAY_FLOAT64
     || kind == JV_ARRAY_INT64 || kind == JV_ARRAY_STRING) {
        /* Array variant column: N UInt64 offsets, then offsets[N-1]
         * inner-type elements concatenated. */
        if (nv_rows == 0) return;
        if ((UV)nv_rows > (UV)(end - *p) / 8)
            croak("decode: buffer truncated (need %lu more bytes)",
                  (unsigned long)((UV)nv_rows * 8));
        uint64_t *offs;
        Newx(offs, nv_rows, uint64_t);
        SAVEFREEPV(offs);
        uint64_t prev_o = 0;
        for (k = 0; k < nv_rows; k++) {
            offs[k] = dec_le64(*p); *p += 8;
            /* Per-offset overflow + monotonicity; protects later casts to
             * SSize_t (e.g. av_extend) from negative-wrap. */
            if (offs[k] > (uint64_t)SSize_t_MAX || offs[k] < prev_o)
                croak("decode JSON: Array variant offset[%ld]=%lu invalid "
                      "(prev=%lu)",
                      (long)k, (unsigned long)offs[k], (unsigned long)prev_o);
            prev_o = offs[k];
        }
        uint64_t total = offs[nv_rows - 1];
        /* Defensive: total elements must fit into the remaining buffer
         * (1+ bytes per element minimum). Catches corrupted offset
         * lists before they trigger huge AV allocations. */
        if (total > (uint64_t)(end - *p))
            croak("decode JSON: Array variant total=%lu exceeds remaining "
                  "buffer (%lu bytes)",
                  (unsigned long)total, (unsigned long)(end - *p));
        for (k = 0; k < nv_rows; k++)
            av_store(sub, k, newRV_noinc((SV*)newAV()));

        /* Inner cursor walks through elements while row_idx advances
         * each time we hit the cumulative offset boundary. */
        uint64_t prev = 0;
        SSize_t row_idx = 0;
        AV *inner = (AV*)SvRV(*av_fetch(sub, 0, 0));
        if (offs[0] > 0) av_extend(inner, (SSize_t)offs[0] - 1);
        SSize_t inner_cursor = 0;

        STRLEN per_elem = (kind == JV_ARRAY_BOOL) ? 1 : 8;
        /* `total` is attacker-controlled (sum of wire offsets); use the
         * division-form check to avoid the multiplication overflowing. */
        if (kind != JV_ARRAY_STRING
            && total > (uint64_t)(end - *p) / per_elem)
            croak("decode: buffer truncated (need %lu more bytes)",
                  (unsigned long)(per_elem * total));

        uint64_t i;
        for (i = 0; i < total; i++) {
            while (inner_cursor >= (SSize_t)(offs[row_idx] - prev)) {
                prev = offs[row_idx];
                row_idx++;
                /* If a corrupted offset list has trailing zero-length
                 * rows that the outer total didn't cover, row_idx
                 * could walk past the populated entries. Bail before
                 * av_fetch returns NULL and we deref it. */
                if (row_idx >= nv_rows)
                    croak("decode: array variant offsets advanced past "
                          "nv_rows=%ld (corrupted block)", (long)nv_rows);
                inner_cursor = 0;
                inner = (AV*)SvRV(*av_fetch(sub, row_idx, 0));
                uint64_t n2 = offs[row_idx] - prev;
                if (n2 > 0) av_extend(inner, (SSize_t)n2 - 1);
            }
            SV *ev;
            switch (kind) {
                case JV_ARRAY_BOOL: {
                    unsigned char b = *(*p)++;
                    ev = make_json_bool_sv(aTHX_ b);
                    break;
                }
                case JV_ARRAY_INT64: {
                    uint64_t u = dec_le64(*p); *p += 8;
                    int64_t v;  memcpy(&v, &u, 8);
                    ev = newSViv((IV)v);
                    break;
                }
                case JV_ARRAY_FLOAT64: {
                    uint64_t u = dec_le64(*p); *p += 8;
                    double v;  memcpy(&v, &u, 8);
                    ev = newSVnv(v);
                    break;
                }
                case JV_ARRAY_STRING: {
                    const char *vs; STRLEN vl;
                    dec_lenpfx_string(aTHX_ p, end, &vs, &vl);
                    ev = newSVpvn(vs, vl);
                    break;
                }
                default: ev = newSV(0);  /* unreachable */
            }
            av_store(inner, inner_cursor++, ev);
        }
        return;
    }
    croak("decode %s: internal: unknown kind %d", ctx, kind);
}

/* Helpers that bulk-read same-size scalars into the array, since the per-
 * row dispatch overhead of unpack-style XS loops dwarfs the data read. */
#define DEC_SCALAR_LOOP(av, nrows, sv_expr) do {                             \
    SSize_t r;                                                               \
    for (r = 0; r < (nrows); r++) av_store(av, r, (sv_expr));                \
} while (0)

SV *decode_column(pTHX_ const unsigned char **p,
                         const unsigned char *end,
                         TypeInfo *t, SSize_t nrows) {
    AV *av = newAV();
    if (nrows > 0) av_extend(av, nrows - 1);
    SSize_t r;

    switch (t->code) {
        case T_INT8: {
            DEC_NEED((STRLEN)nrows);
            DEC_SCALAR_LOOP(av, nrows, newSViv((IV)(int8_t)*(*p)++));
            break;
        }
        case T_UINT8: case T_BOOL: case T_ENUM8: {
            DEC_NEED((STRLEN)nrows);
            DEC_SCALAR_LOOP(av, nrows, newSVuv((UV)*(*p)++));
            break;
        }
        case T_INT16: {
            DEC_NEED((STRLEN)(2 * nrows));
            for (r = 0; r < nrows; r++) {
                /* Use dec_le16 + memcpy bit-cast (same pattern as INT32
                 * and INT64) to keep the signed conversion well-defined
                 * across compilers; the inline (int16_t)(...) cast on
                 * a promoted-int high-bit value is implementation-
                 * defined in C99/C11. */
                uint16_t u = dec_le16(*p);
                int16_t  v;  memcpy(&v, &u, 2);
                av_store(av, r, newSViv((IV)v));
                *p += 2;
            }
            break;
        }
        case T_UINT16: case T_DATE: case T_ENUM16: {
            DEC_NEED((STRLEN)(2 * nrows));
            for (r = 0; r < nrows; r++) {
                uint16_t v = dec_le16(*p);
                av_store(av, r, newSVuv((UV)v));
                *p += 2;
            }
            break;
        }
        case T_INT32: case T_DATE32: case T_DECIMAL32: {
            DEC_NEED((STRLEN)(4 * nrows));
            for (r = 0; r < nrows; r++) {
                uint32_t u = dec_le32(*p);
                int32_t v;  memcpy(&v, &u, 4);
                av_store(av, r, newSViv((IV)v));
                *p += 4;
            }
            break;
        }
        case T_UINT32: case T_DATETIME: {
            DEC_NEED((STRLEN)(4 * nrows));
            for (r = 0; r < nrows; r++) {
                uint32_t v = dec_le32(*p);
                av_store(av, r, newSVuv((UV)v));
                *p += 4;
            }
            break;
        }
        case T_INT64: case T_DATETIME64: case T_DECIMAL64: {
            DEC_NEED((STRLEN)(8 * nrows));
            for (r = 0; r < nrows; r++) {
                uint64_t u = dec_le64(*p);
                int64_t v;  memcpy(&v, &u, 8);
                av_store(av, r, newSViv((IV)v));
                *p += 8;
            }
            break;
        }
        case T_UINT64: {
            DEC_NEED((STRLEN)(8 * nrows));
            for (r = 0; r < nrows; r++) {
                uint64_t v = dec_le64(*p);
                av_store(av, r, newSVuv((UV)v));
                *p += 8;
            }
            break;
        }
        case T_FLOAT32: {
            DEC_NEED((STRLEN)(4 * nrows));
            for (r = 0; r < nrows; r++) {
                uint32_t u = dec_le32(*p);
                float v;  memcpy(&v, &u, 4);
                av_store(av, r, newSVnv((NV)v));
                *p += 4;
            }
            break;
        }
        case T_FLOAT64: {
            DEC_NEED((STRLEN)(8 * nrows));
            for (r = 0; r < nrows; r++) {
                uint64_t u = dec_le64(*p);
                double v;  memcpy(&v, &u, 8);
                av_store(av, r, newSVnv((NV)v));
                *p += 8;
            }
            break;
        }
        case T_BFLOAT16: {
            /* Reconstruct a Float32 by shifting 16 wire bits into the high half. */
            DEC_NEED((STRLEN)(2 * nrows));
            for (r = 0; r < nrows; r++) {
                uint32_t bits = (uint32_t)((*p)[0] | ((*p)[1] << 8)) << 16;
                float fv;
                memcpy(&fv, &bits, 4);
                av_store(av, r, newSVnv((NV)fv));
                *p += 2;
            }
            break;
        }
        case T_STRING: {
            for (r = 0; r < nrows; r++) {
                const char *s; STRLEN l;
                dec_lenpfx_string(aTHX_ p, end, &s, &l);
                av_store(av, r, newSVpvn(s, l));
            }
            break;
        }
        case T_FIXEDSTRING: {
            STRLEN n = (STRLEN)t->param;
            /* `n * nrows` is the only multiplicative bound here whose
             * multiplier is fully user-controlled (FixedString(N) for
             * any N up to ~2^31). Defend against overflow explicitly
             * rather than relying on prologue's per-row bound. */
            if (n > 0 && (UV)nrows > ((UV)(end - *p)) / n)
                croak("decode: FixedString(%lu) x %ld rows exceeds "
                      "remaining buffer (%lu bytes)",
                      (unsigned long)n, (long)nrows,
                      (unsigned long)(end - *p));
            DEC_NEED(n * (STRLEN)nrows);
            for (r = 0; r < nrows; r++) {
                av_store(av, r, newSVpvn((const char *)*p, n));
                *p += n;
            }
            break;
        }
        case T_DECIMAL128: {
            /* Division-form guard against `16 * nrows` overflow when
             * nrows is attacker-controlled. */
            if ((UV)nrows > (UV)(end - *p) / 16)
                croak("decode: Decimal128 x %ld rows exceeds buffer",
                      (long)nrows);
            DEC_NEED((STRLEN)(16 * nrows));
            for (r = 0; r < nrows; r++) {
                uint64_t lo = dec_le64(*p);
                uint64_t hu = dec_le64(*p + 8);
                int64_t  hi; memcpy(&hi, &hu, 8);
                AV *pair = newAV();
                av_extend(pair, 1);
                av_store(pair, 0, newSVuv((UV)lo));
                av_store(pair, 1, newSViv((IV)hi));
                av_store(av, r, newRV_noinc((SV*)pair));
                *p += 16;
            }
            break;
        }
        case T_DECIMAL256: {
            if ((UV)nrows > (UV)(end - *p) / 32)
                croak("decode: Decimal256 x %ld rows exceeds buffer",
                      (long)nrows);
            DEC_NEED((STRLEN)(32 * nrows));
            for (r = 0; r < nrows; r++) {
                AV *limbs = newAV();
                av_extend(limbs, 3);
                int i;
                for (i = 0; i < 4; i++) {
                    uint64_t l = dec_le64(*p + 8 * i);
                    av_store(limbs, i, newSVuv((UV)l));
                }
                av_store(av, r, newRV_noinc((SV*)limbs));
                *p += 32;
            }
            break;
        }
        case T_UUID: {
            /* Wire: two LE UInt64 halves with bytes reversed within each
             * half. Reassemble to standard 8-4-4-4-12 hex form. */
            if ((UV)nrows > (UV)(end - *p) / 16)
                croak("decode: UUID x %ld rows exceeds buffer",
                      (long)nrows);
            DEC_NEED((STRLEN)(16 * nrows));
            for (r = 0; r < nrows; r++) {
                unsigned char b[16];
                int i;
                for (i = 0; i < 8; i++) b[i]    = (*p)[7 - i];
                for (i = 0; i < 8; i++) b[8+i]  = (*p)[15 - i];
                *p += 16;
                char hex[37];
                static const char H[] = "0123456789abcdef";
                int j = 0, k;
                for (k = 0; k < 16; k++) {
                    hex[j++] = H[(b[k] >> 4) & 0xf];
                    hex[j++] = H[b[k] & 0xf];
                    if (k == 3 || k == 5 || k == 7 || k == 9) hex[j++] = '-';
                }
                hex[36] = '\0';
                av_store(av, r, newSVpvn(hex, 36));
            }
            break;
        }
        case T_IPV4: {
            DEC_NEED((STRLEN)(4 * nrows));
            for (r = 0; r < nrows; r++) {
                /* Wire is LE uint32 = [oct4][oct3][oct2][oct1]. Read the
                 * bytes directly so the output order is endianness-
                 * independent. */
                const unsigned char *b = *p;
                char buf[16];
                int n = my_snprintf(buf, sizeof buf, "%u.%u.%u.%u",
                                    b[3], b[2], b[1], b[0]);
                av_store(av, r, newSVpvn(buf, n));
                *p += 4;
            }
            break;
        }
        case T_IPV6: {
            if ((UV)nrows > (UV)(end - *p) / 16)
                croak("decode: IPv6 x %ld rows exceeds buffer",
                      (long)nrows);
            DEC_NEED((STRLEN)(16 * nrows));
            for (r = 0; r < nrows; r++) {
                av_store(av, r, newSVpvn((const char *)*p, 16));
                *p += 16;
            }
            break;
        }
        case T_ARRAY: {
            /* Read nrows UInt64 offsets, then decode flat inner array
             * of total = offsets[nrows-1] elements, then slice. */
            if ((UV)nrows > (UV)(end - *p) / 8)
                croak("decode: Array offsets x %ld rows exceeds buffer",
                      (long)nrows);
            DEC_NEED((STRLEN)(8 * nrows));
            SSize_t *offsets;
            Newx(offsets, nrows + 1, SSize_t);
            SAVEFREEPV(offsets);
            offsets[0] = 0;
            for (r = 0; r < nrows; r++) {
                uint64_t o = dec_le64(*p);
                /* Per-offset overflow + monotonicity check; the final-only
                 * check below is insufficient because an intermediate
                 * offset with bit 63 set narrows to a negative SSize_t and
                 * later produces an enormous stop-start span in av_extend. */
                if (o > (uint64_t)SSize_t_MAX || (SSize_t)o < offsets[r])
                    croak("decode: Array offset[%ld]=%lu invalid (prev=%ld)",
                          (long)r, (unsigned long)o, (long)offsets[r]);
                offsets[r + 1] = (SSize_t)o;
                *p += 8;
            }
            SSize_t total = offsets[nrows];
            /* Defensive: a corrupted offset must not allocate gigabytes
             * for the inner array. */
            if ((UV)total > (UV)(end - *p))
                croak("decode: Array total=%ld exceeds remaining buffer "
                      "(%lu bytes)",
                      (long)total, (unsigned long)(end - *p));
            SV *flat_rv = decode_column(aTHX_ p, end, t->inner, total);
            AV *flat    = (AV *)SvRV(flat_rv);
            for (r = 0; r < nrows; r++) {
                AV *slice = newAV();
                SSize_t start = offsets[r], stop = offsets[r + 1];
                if (stop > start) av_extend(slice, stop - start - 1);
                SSize_t i;
                for (i = start; i < stop; i++) {
                    SV **elem = av_fetch(flat, i, 0);
                    av_store(slice, i - start,
                             elem ? SvREFCNT_inc(*elem) : newSV(0));
                }
                av_store(av, r, newRV_noinc((SV*)slice));
            }
            SvREFCNT_dec(flat_rv);
            break;
        }
        case T_TUPLE: {
            /* Decode each element type as a column of `nrows`, then
             * transpose into per-row tuples. */
            int i;
            SV **cols;
            Newx(cols, t->tuple_len, SV*);
            SAVEFREEPV(cols);
            for (i = 0; i < t->tuple_len; i++)
                cols[i] = decode_column(aTHX_ p, end, t->tuple[i], nrows);
            for (r = 0; r < nrows; r++) {
                AV *row = newAV();
                if (t->tuple_len > 0) av_extend(row, t->tuple_len - 1);
                for (i = 0; i < t->tuple_len; i++) {
                    SV **elem = av_fetch((AV *)SvRV(cols[i]), r, 0);
                    av_store(row, i, elem ? SvREFCNT_inc(*elem) : newSV(0));
                }
                av_store(av, r, newRV_noinc((SV*)row));
            }
            for (i = 0; i < t->tuple_len; i++) SvREFCNT_dec(cols[i]);
            break;
        }
        case T_NULLABLE: {
            DEC_NEED((STRLEN)nrows);
            unsigned char *nulls;
            Newx(nulls, nrows, unsigned char);
            SAVEFREEPV(nulls);
            for (r = 0; r < nrows; r++) nulls[r] = *(*p)++;
            SV *inner_rv = decode_column(aTHX_ p, end, t->inner, nrows);
            AV *inner    = (AV *)SvRV(inner_rv);
            for (r = 0; r < nrows; r++) {
                if (nulls[r]) {
                    av_store(av, r, newSV(0));
                } else {
                    SV **elem = av_fetch(inner, r, 0);
                    av_store(av, r, elem ? SvREFCNT_inc(*elem) : newSV(0));
                }
            }
            SvREFCNT_dec(inner_rv);
            break;
        }
        case T_MAP: {
            /* Map(K, V) on the wire is Array(Tuple(K, V)). Re-dispatch
             * through a synthetic Array(Tuple) type. */
            TypeInfo array_t, tuple_t;
            memset(&array_t, 0, sizeof array_t);
            memset(&tuple_t, 0, sizeof tuple_t);
            tuple_t.code      = T_TUPLE;
            tuple_t.tuple     = t->tuple;
            tuple_t.tuple_len = t->tuple_len;
            array_t.code      = T_ARRAY;
            array_t.inner     = &tuple_t;
            SV *rv = decode_column(aTHX_ p, end, &array_t, nrows);
            SvREFCNT_dec((SV *)av);
            return rv;
        }
        case T_LOWCARDINALITY: {
            DEC_NEED(24);
            uint64_t version = dec_le64(*p);
            uint64_t flags   = dec_le64(*p +  8);
            uint64_t dict_n  = dec_le64(*p + 16);
            *p += 24;
            if (version != 1) croak("decode: LowCardinality version != 1 (got %lu)", (unsigned long)version);
            /* Defensive: a corrupted dict_n must not allocate gigabytes. */
            if (dict_n > (uint64_t)(end - *p))
                croak("decode: LowCardinality dict_n=%lu exceeds remaining "
                      "buffer (%lu bytes)",
                      (unsigned long)dict_n, (unsigned long)(end - *p));
            int idx_type   = (int)(flags & 0xff);
            /* Only TUInt8=0..TUInt64=3 are defined; reject the rest
             * loudly instead of silently aliasing to UInt64. */
            if (idx_type > 3)
                croak("decode: LowCardinality: unknown index type %d in flags",
                      idx_type);
            TypeInfo *inner = t->inner;
            int is_null    = (inner->code == T_NULLABLE);
            TypeInfo *leaf = is_null ? inner->inner : inner;
            SV *dict_rv    = decode_column(aTHX_ p, end, leaf, (SSize_t)dict_n);
            AV *dict       = (AV *)SvRV(dict_rv);
            DEC_NEED(8);
            uint64_t idx_n = dec_le64(*p);
            *p += 8;
            /* Surface the meaningful error before DEC_NEED would croak on
             * a truncated buffer for an absurdly large idx_n. */
            if (idx_n > (uint64_t)SSize_t_MAX || (SSize_t)idx_n != nrows)
                croak("decode: LowCardinality index count (%lu) != nrows (%ld)",
                      (unsigned long)idx_n, (long)nrows);
            size_t idx_bytes = (idx_type == 0) ? 1 :
                               (idx_type == 1) ? 2 :
                               (idx_type == 2) ? 4 : 8;
            DEC_NEED((STRLEN)(idx_bytes * idx_n));
            for (r = 0; r < nrows; r++) {
                uint64_t i = 0;
                switch (idx_bytes) {
                    case 1: i = (uint64_t)(*p)[0]; break;
                    case 2: i = (uint64_t)dec_le16(*p); break;
                    case 4: i = (uint64_t)dec_le32(*p); break;
                    case 8: i = dec_le64(*p); break;
                }
                *p += idx_bytes;
                if (is_null && i == 0) {
                    av_store(av, r, newSV(0));
                } else {
                    if (i >= dict_n)
                        croak("decode: LowCardinality index %lu out of range "
                              "(dict_n=%lu) at row %ld",
                              (unsigned long)i, (unsigned long)dict_n, (long)r);
                    SV **elem = av_fetch(dict, (SSize_t)i, 0);
                    av_store(av, r, elem ? SvREFCNT_inc(*elem) : newSV(0));
                }
            }
            SvREFCNT_dec(dict_rv);
            break;
        }
        case T_VARIANT: {
            DEC_NEED(8);
            uint64_t mode = dec_le64(*p);
            *p += 8;
            if (mode != 0) croak("decode: Variant mode != 0 (got %lu)", (unsigned long)mode);
            DEC_NEED((STRLEN)nrows);
            unsigned char *wire_disc;
            Newx(wire_disc, nrows, unsigned char);
            SAVEFREEPV(wire_disc);
            for (r = 0; r < nrows; r++) wire_disc[r] = *(*p)++;
            int nvar = t->tuple_len;
            SSize_t *counts;
            Newxz(counts, nvar, SSize_t);
            SAVEFREEPV(counts);
            for (r = 0; r < nrows; r++) {
                unsigned char w = wire_disc[r];
                if (w != 255) {
                    if (w >= nvar) croak("decode: Variant wire idx %u out of range", w);
                    counts[w]++;
                }
            }
            /* Decode each sub-column in wire (alphabetical) order; the
             * decl index of wire position w is t->variant_wire_to_decl[w]. */
            SV **subcols;
            Newx(subcols, nvar, SV*);
            SAVEFREEPV(subcols);
            int w;
            for (w = 0; w < nvar; w++) {
                int decl = t->variant_wire_to_decl[w];
                subcols[w] = decode_column(aTHX_ p, end, t->tuple[decl], counts[w]);
            }
            SSize_t *cursors;
            Newxz(cursors, nvar, SSize_t);
            SAVEFREEPV(cursors);
            for (r = 0; r < nrows; r++) {
                unsigned char wd = wire_disc[r];
                if (wd == 255) {
                    av_store(av, r, newSV(0));
                } else {
                    int decl = t->variant_wire_to_decl[wd];
                    SV **elem = av_fetch((AV *)SvRV(subcols[wd]), cursors[wd]++, 0);
                    AV *pair = newAV();
                    av_extend(pair, 1);
                    av_store(pair, 0, newSViv(decl));
                    av_store(pair, 1, elem ? SvREFCNT_inc(*elem) : newSV(0));
                    av_store(av, r, newRV_noinc((SV*)pair));
                }
            }
            for (w = 0; w < nvar; w++) SvREFCNT_dec(subcols[w]);
            break;
        }

        case T_JSON: {
            /* Object structure prefix. Versions: V1=0, V2=2, V3=4. */
            DEC_NEED(8);
            uint64_t obj_ver = dec_le64(*p); *p += 8;
            if (obj_ver != 0 && obj_ver != 2 && obj_ver != 4)
                croak("decode JSON: unsupported Object version %lu "
                      "(known: 0, 2, 4); upgrade ClickHouse::Encoder",
                      (unsigned long)obj_ver);
            if (obj_ver == 0) {
                /* V1: extra max_dynamic_paths varint before count. */
                (void)dec_varint(aTHX_ p, end);
            }
            UV num_paths = dec_varint(aTHX_ p, end);
            /* Defensive: each path takes at least 2 bytes (1-byte varint
             * length prefix + 1-byte name). Reject obviously-impossible
             * counts before allocating arrays sized by num_paths. */
            if (num_paths > (UV)(end - *p))
                croak("decode JSON: num_paths=%lu exceeds remaining buffer "
                      "(%lu bytes)",
                      (unsigned long)num_paths, (unsigned long)(end - *p));

            char **paths = NULL;
            STRLEN *path_lens = NULL;
            if (num_paths > 0) {
                Newx(paths, num_paths, char*);
                SAVEFREEPV(paths);
                Newx(path_lens, num_paths, STRLEN);
                SAVEFREEPV(path_lens);
            }
            UV pi;
            for (pi = 0; pi < num_paths; pi++) {
                const char *ps;
                STRLEN pl;
                dec_lenpfx_string(aTHX_ p, end, &ps, &pl);
                paths[pi]     = (char*)ps;  /* aliases input buffer */
                path_lens[pi] = pl;
            }
            if (obj_ver == 4) {
                /* V3 adds shared_data_serialization_version, and a
                 * buckets count when that version is MAP_WITH_BUCKETS
                 * (=1) or ADVANCED (=2). Native format with statistics
                 * disabled (the default) skips the stats afterwards. */
                UV shared_ver = dec_varint(aTHX_ p, end);
                if (shared_ver == 1 || shared_ver == 2)
                    (void)dec_varint(aTHX_ p, end);
            }

            /* Per-path Dynamic prefix: collect type-name lists. */
            int **path_kind_list = NULL;  /* path_kind_list[p][i] = JsonValueKind */
            int *path_kind_count = NULL;
            if (num_paths > 0) {
                Newxz(path_kind_list, num_paths, int*);
                SAVEFREEPV(path_kind_list);
                Newxz(path_kind_count, num_paths, int);
                SAVEFREEPV(path_kind_count);
            }
            for (pi = 0; pi < num_paths; pi++) {
                DEC_NEED(8);
                uint64_t dyn_ver = dec_le64(*p); *p += 8;
                if (dyn_ver != 1 && dyn_ver != 2 && dyn_ver != 4)
                    croak("decode JSON: unsupported Dynamic version %lu "
                          "(known: 1, 2, 4); upgrade ClickHouse::Encoder",
                          (unsigned long)dyn_ver);
                if (dyn_ver == 1)
                    (void)dec_varint(aTHX_ p, end);
                UV ntypes = dec_varint(aTHX_ p, end);
                /* Each type name needs at least 2 bytes (length varint
                 * + name byte). Reject implausibly large counts. */
                if (ntypes > (UV)(end - *p))
                    croak("decode JSON: ntypes=%lu exceeds remaining "
                          "buffer (%lu bytes)",
                          (unsigned long)ntypes, (unsigned long)(end - *p));

                int *kinds_in_order = NULL;
                if (ntypes > 0) {
                    Newx(kinds_in_order, ntypes, int);
                    SAVEFREEPV(kinds_in_order);
                }
                UV ti;
                for (ti = 0; ti < ntypes; ti++) {
                    const char *ts;
                    STRLEN tl;
                    dec_lenpfx_string(aTHX_ p, end, &ts, &tl);
                    int k = json_kind_from_type_name(ts, tl);
                    if (k < 0)
                        croak("decode JSON: unsupported variant type '%.*s' "
                              "for path '%.*s' (supported: Bool, Float64, "
                              "Int64, String, Array(...) of those)",
                              (int)tl, ts, (int)path_lens[pi], paths[pi]);
                    kinds_in_order[ti] = k;
                }
                path_kind_list[pi]  = kinds_in_order;
                path_kind_count[pi] = (int)ntypes;

                /* Variant prefix: 8-byte mode. */
                DEC_NEED(8);
                uint64_t var_mode = dec_le64(*p); *p += 8;
                if (var_mode != 0)
                    croak("decode JSON: only BASIC variant mode supported "
                          "(got %lu)", (unsigned long)var_mode);
            }

            /* Build result: AV of HV refs, one per row. */
            for (r = 0; r < nrows; r++)
                av_store(av, r, newRV_noinc((SV*)newHV()));

            /* Typed path data (when t was declared as JSON(name Type, ...)):
             * the inner column data comes on the wire right after all
             * Dynamic prefixes and before any dynamic Variant data, in
             * name-sorted order. Decode each typed path's column,
             * distribute into per-row hashes by path name. */
            {
                int tp;
                for (tp = 0; tp < t->tuple_len; tp++) {
                    SV *col_rv = decode_column(aTHX_ p, end, t->tuple[tp],
                                               nrows);
                    AV *col_av = (AV*)SvRV(col_rv);
                    STRLEN nlen = strlen(t->tuple_names[tp]);
                    for (r = 0; r < nrows; r++) {
                        SV **e = av_fetch(col_av, r, 0);
                        if (!e) continue;
                        SV *row_rv = *av_fetch(av, r, 0);
                        HV *row_hv = (HV*)SvRV(row_rv);
                        hv_store(row_hv, t->tuple_names[tp], (I32)nlen,
                                 SvREFCNT_inc(*e), 0);
                    }
                    SvREFCNT_dec(col_rv);
                }
            }

            /* Per-path Variant data: discs + per-variant values. */
            for (pi = 0; pi < num_paths; pi++) {
                /* Read N disc bytes. */
                DEC_NEED((STRLEN)nrows);
                unsigned char *discs;
                Newx(discs, nrows, unsigned char);
                SAVEFREEPV(discs);
                for (r = 0; r < nrows; r++) discs[r] = *(*p)++;

                /* Compute per-variant row counts and lex-position table.
                 * The wire variant list has (kind_count + 1) entries (the
                 * +1 is SharedVariant inserted at its lex position 7).
                 * Rebuild the kind mask from the type-name list we just
                 * parsed and reuse the same lex-table helper as encode. */
                int nv = path_kind_count[pi];
                int wire_slots = nv + 1;
                SSize_t *var_counts;
                Newxz(var_counts, wire_slots, SSize_t);
                SAVEFREEPV(var_counts);

                int slot_to_kind_or_shared[JSON_LEX_SLOTS];
                {
                    unsigned mask = 0;
                    int i;
                    for (i = 0; i < nv; i++)
                        mask |= 1u << path_kind_list[pi][i];
                    (void)json_build_lex_table(mask, slot_to_kind_or_shared);
                }

                for (r = 0; r < nrows; r++) {
                    unsigned char d = discs[r];
                    if (d == 0xff) continue;
                    if (d >= wire_slots)
                        croak("decode JSON: path '%.*s' disc %u out of range "
                              "(wire_slots=%d)",
                              (int)path_lens[pi], paths[pi], d, wire_slots);
                    var_counts[d]++;
                }

                /* Decode each wire-slot's column data. SharedVariant
                 * (kind=-1) is a String column on the wire, which our
                 * encoder never populates (0 rows here in practice). */
                AV **var_avs;
                Newxz(var_avs, wire_slots, AV*);
                SAVEFREEPV(var_avs);
                int slot;
                for (slot = 0; slot < wire_slots; slot++) {
                    SSize_t nv_rows = var_counts[slot];
                    AV *sub = newAV();
                    var_avs[slot] = sub;
                    sv_2mortal((SV*)sub);
                    if (nv_rows > 0) av_extend(sub, nv_rows - 1);
                    decode_dynamic_variant_slot(aTHX_ p, end, sub,
                        slot_to_kind_or_shared[slot], nv_rows, "JSON");
                }

                /* Distribute values into per-row hashes. */
                SSize_t *cursors;
                Newxz(cursors, wire_slots, SSize_t);
                SAVEFREEPV(cursors);
                for (r = 0; r < nrows; r++) {
                    unsigned char d = discs[r];
                    if (d == 0xff) continue;
                    SV **e = av_fetch(var_avs[d], cursors[d]++, 0);
                    if (!e) continue;
                    SV *row_rv = *av_fetch(av, r, 0);
                    HV *row_hv = (HV*)SvRV(row_rv);
                    SV *val = SvREFCNT_inc(*e);
                    hv_store(row_hv, paths[pi], (I32)path_lens[pi], val, 0);
                }
            }

            /* Trailing shared data: N UInt64 offsets, then if final
             * offset > 0, offsets[N-1] key strings + value strings.
             * Only the last offset determines downstream parsing; skip
             * the rest with a single pointer bump. */
            uint64_t last_offset = 0;
            if (nrows > 0) {
                DEC_NEED((STRLEN)(8 * nrows));
                last_offset = dec_le64(*p + 8 * (nrows - 1));
                *p += 8 * nrows;
            }
            if (last_offset > 0) {
                /* Each string is a length varint + bytes (>= 1 byte
                 * total). A corrupted last_offset must not let us spin
                 * calling dec_lenpfx_string 2^32 times before each one
                 * croaks on the truncated buffer. */
                if (last_offset > (uint64_t)(end - *p))
                    croak("decode JSON: shared-data last_offset=%lu "
                          "exceeds remaining buffer (%lu bytes)",
                          (unsigned long)last_offset,
                          (unsigned long)(end - *p));
                uint64_t i;
                for (i = 0; i < last_offset; i++) {
                    const char *s; STRLEN l;
                    dec_lenpfx_string(aTHX_ p, end, &s, &l);
                }
                for (i = 0; i < last_offset; i++) {
                    const char *s; STRLEN l;
                    dec_lenpfx_string(aTHX_ p, end, &s, &l);
                }
            }

            /* Unflatten dotted-path keys into nested hashes. Symmetric to the
             * encoder which flattens nested hashrefs into dotted paths on the
             * wire. Collision-safe: if an intermediate hop is already a
             * non-HV (some path emitted a leaf at "a" while another emitted
             * "a.b"), the dotted form is left intact at the top level. */
            for (r = 0; r < nrows; r++) {
                SV *row_rv = *av_fetch(av, r, 0);
                HV *row_hv = (HV*)SvRV(row_rv);
                /* Snapshot keys: we may mutate row_hv during iteration. */
                AV *keys = (AV*)sv_2mortal((SV*)newAV());
                hv_iterinit(row_hv);
                HE *he;
                while ((he = hv_iternext(row_hv))) {
                    I32 klen;
                    char *kstr = hv_iterkey(he, &klen);
                    if (memchr(kstr, '.', klen))
                        av_push(keys, newSVpvn(kstr, klen));
                }
                SSize_t nk = av_len(keys) + 1;
                SSize_t ki;
                for (ki = 0; ki < nk; ki++) {
                    SV *ksv = *av_fetch(keys, ki, 0);
                    STRLEN klen;
                    const char *kstr = SvPV(ksv, klen);
                    /* Walk dotted segments. */
                    HV *cur = row_hv;
                    STRLEN seg_start = 0, off;
                    int conflict = 0;
                    for (off = 0; off <= klen; off++) {
                        if (off == klen || kstr[off] == '.') {
                            const char *seg = kstr + seg_start;
                            STRLEN slen = off - seg_start;
                            if (off == klen) {
                                /* Final segment: move value here. */
                                SV **leaf = hv_fetch(row_hv, kstr,
                                                     (I32)klen, 0);
                                if (!leaf) { conflict = 1; break; }
                                SV *val = SvREFCNT_inc(*leaf);
                                if (!hv_store(cur, seg, (I32)slen,
                                              val, 0)) {
                                    SvREFCNT_dec(val);
                                    conflict = 1;
                                }
                            } else {
                                SV **next = hv_fetch(cur, seg, (I32)slen,
                                                     0);
                                HV *next_hv;
                                if (next && SvROK(*next)
                                    && SvTYPE(SvRV(*next)) == SVt_PVHV) {
                                    next_hv = (HV*)SvRV(*next);
                                } else if (next) {
                                    conflict = 1;
                                    break;
                                } else {
                                    next_hv = newHV();
                                    hv_store(cur, seg, (I32)slen,
                                             newRV_noinc((SV*)next_hv), 0);
                                }
                                cur = next_hv;
                            }
                            seg_start = off + 1;
                        }
                    }
                    if (!conflict)
                        hv_delete(row_hv, kstr, (I32)klen, G_DISCARD);
                }
            }
            break;
        }

        case T_DYNAMIC: {
            /* Dynamic V1/V2/V3 prefix + Variant data, no Object wrapper. */
            DEC_NEED(8);
            uint64_t dyn_ver = dec_le64(*p); *p += 8;
            if (dyn_ver != 1 && dyn_ver != 2 && dyn_ver != 4)
                croak("decode Dynamic: unsupported version %lu "
                      "(known: 1, 2, 4); upgrade ClickHouse::Encoder",
                      (unsigned long)dyn_ver);
            if (dyn_ver == 1)
                (void)dec_varint(aTHX_ p, end);
            UV ntypes = dec_varint(aTHX_ p, end);
            /* Same bound as the JSON path's per-path Dynamic prefix:
             * each type name takes at least 2 bytes on the wire. */
            if (ntypes > (UV)(end - *p))
                croak("decode Dynamic: ntypes=%lu exceeds remaining "
                      "buffer (%lu bytes)",
                      (unsigned long)ntypes, (unsigned long)(end - *p));

            int *kinds_in_order = NULL;
            if (ntypes > 0) {
                Newx(kinds_in_order, ntypes, int);
                SAVEFREEPV(kinds_in_order);
            }
            UV ti;
            for (ti = 0; ti < ntypes; ti++) {
                const char *ts; STRLEN tl;
                dec_lenpfx_string(aTHX_ p, end, &ts, &tl);
                int k = json_kind_from_type_name(ts, tl);
                if (k < 0)
                    croak("decode Dynamic: unsupported variant type '%.*s' "
                          "(supported: Bool, Float64, Int64, String, "
                          "Array(...) of those)",
                          (int)tl, ts);
                kinds_in_order[ti] = k;
            }

            DEC_NEED(8);
            uint64_t var_mode = dec_le64(*p); *p += 8;
            if (var_mode != 0)
                croak("decode Dynamic: only BASIC variant mode supported "
                      "(got %lu)", (unsigned long)var_mode);

            int nv = (int)ntypes;
            int wire_slots = nv + 1;
            unsigned mask = 0;
            int i;
            for (i = 0; i < nv; i++) mask |= 1u << kinds_in_order[i];

            int slot_to_kind[JSON_LEX_SLOTS];
            (void)json_build_lex_table(mask, slot_to_kind);

            DEC_NEED((STRLEN)nrows);
            unsigned char *discs;
            Newx(discs, nrows, unsigned char);
            SAVEFREEPV(discs);
            for (r = 0; r < nrows; r++) discs[r] = *(*p)++;

            SSize_t *var_counts;
            Newxz(var_counts, wire_slots, SSize_t);
            SAVEFREEPV(var_counts);
            for (r = 0; r < nrows; r++) {
                if (discs[r] == 0xff) continue;
                if (discs[r] >= wire_slots)
                    croak("decode Dynamic: disc %u out of range "
                          "(wire_slots=%d)", discs[r], wire_slots);
                var_counts[discs[r]]++;
            }

            AV **var_avs;
            Newxz(var_avs, wire_slots, AV*);
            SAVEFREEPV(var_avs);
            int slot;
            for (slot = 0; slot < wire_slots; slot++) {
                SSize_t nv_rows = var_counts[slot];
                AV *sub = newAV();
                var_avs[slot] = sub;
                sv_2mortal((SV*)sub);
                if (nv_rows > 0) av_extend(sub, nv_rows - 1);
                decode_dynamic_variant_slot(aTHX_ p, end, sub,
                    slot_to_kind[slot], nv_rows, "Dynamic");
            }

            SSize_t *cursors;
            Newxz(cursors, wire_slots, SSize_t);
            SAVEFREEPV(cursors);
            for (r = 0; r < nrows; r++) {
                unsigned char d = discs[r];
                if (d == 0xff) { av_store(av, r, newSV(0)); continue; }
                SV **e = av_fetch(var_avs[d], cursors[d]++, 0);
                av_store(av, r, e ? SvREFCNT_inc(*e) : newSV(0));
            }
            break;
        }

        default:
            croak("decode: unhandled type code %d", t->code);
    }
    return newRV_noinc((SV *)av);
}

#undef DEC_NEED
#undef DEC_SCALAR_LOOP
