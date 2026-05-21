/* DMS::XS::Parser — XS wrapper around the C DMS parser.
 *
 * Translates dms_value trees into Perl structures that are byte-compatible
 * with DMS::Parser (pure Perl): Tie::IxHash tables, blessed DMS::*
 * sentinels for scalar types, plain scalars for strings.
 *
 * Tier-0 only. Surfaces the C parser's attached-comment AST as a
 * `comments` arrayref on the returned document, mirroring the pure-Perl
 * parser's `{ meta, body, comments }` shape.
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "dms.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>

#if defined(WIN32) || defined(_WIN32)
#  include <windows.h>
#else
#  include <unistd.h>
#endif

/* --- Tie::IxHash table construction ----------------------------------- */

/* Cached stash pointers. Filled on first use. */
static HV *stash_Bool, *stash_Integer, *stash_Float;
static HV *stash_LocalDate, *stash_LocalTime, *stash_LocalDateTime, *stash_OffsetDateTime;
static HV *stash_Index;

static HV *get_stash_cached(pTHX_ HV **slot, const char *name) {
    if (!*slot) *slot = gv_stashpv(name, GV_ADD);
    return *slot;
}

/* Build a blessed scalar-ref sentinel: bless \$inner, <stash>.
 * One alloc (the RV) on top of the inner SV the caller provides — the
 * earlier blessed-hash shape cost three (HV + HV entry + RV) and showed
 * up as the Perl-XS marshaling tax on wide-flat integer docs.
 * The Perl-side classes (DMS::Integer, DMS::Float, DMS::Bool,
 * DMS::LocalDate, etc.) are now defined against scalar refs accordingly. */
static SV *bless_sentinel(pTHX_ HV *stash, SV *inner) {
    return sv_bless(newRV_noinc(inner), stash);
}

/* Cached Tie::IxHash stash. Filled on first use. */
static HV *stash_IxHash;

/* ---- Fast IxHash construction ----
 * A Tie::IxHash tied object is a blessed arrayref with the documented
 * layout:
 *   [ HV{key => index}, AV[keys], AV[values], IV iter ]
 *
 * We build that structure directly in C, bypassing Tie::IxHash::TIEHASH /
 * STORE / FETCH method dispatch. Appending a k/v pair becomes three cheap
 * C ops (hv_store + av_push + av_push) instead of a full Perl method call
 * per key. This is the single biggest speedup in the XS port — for tables
 * with N keys, it collapses N Perl-VM trips into zero.
 *
 * Caller gets back the wrapper hashref plus raw pointers to the internal
 * AV/HV so they can append without re-dereferencing through mg_find on
 * every insert. Iteration works through the normal tied interface because
 * the tied object we built is a proper Tie::IxHash instance. */
static SV *new_ixhash_fast(pTHX_ HV **out_idx, AV **out_keys, AV **out_vals) {
    HV *idx_hv  = newHV();
    AV *keys_av = newAV();
    AV *vals_av = newAV();

    AV *ix_obj = newAV();
    av_extend(ix_obj, 3);
    av_store(ix_obj, 0, newRV_noinc((SV *)idx_hv));
    av_store(ix_obj, 1, newRV_noinc((SV *)keys_av));
    av_store(ix_obj, 2, newRV_noinc((SV *)vals_av));
    av_store(ix_obj, 3, newSViv(0));

    if (!stash_IxHash) {
        /* Lazy-load Tie::IxHash on first full-mode parse — Parser.pm
         * no longer `use`s it at compile time, so lite-mode-only callers
         * (bench drivers) don't pay the ~7 ms .pm load. The require
         * defines Tie::IxHash::FIRSTKEY/NEXTKEY/FETCH/etc., which Perl
         * looks up lazily when user code does `keys %$tied`. */
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Tie::IxHash"), NULL);
        stash_IxHash = gv_stashpv("Tie::IxHash", GV_ADD);
    }
    SV *tied_rv = newRV_noinc((SV *)ix_obj);
    sv_bless(tied_rv, stash_IxHash);

    HV *wrapper = newHV();
    sv_magic((SV *)wrapper, tied_rv, PERL_MAGIC_tied, NULL, 0);
    SvREFCNT_dec(tied_rv);

    if (out_idx)  *out_idx  = idx_hv;
    if (out_keys) *out_keys = keys_av;
    if (out_vals) *out_vals = vals_av;

    return newRV_noinc((SV *)wrapper);
}

/* Append a k/v pair to an IxHash built via new_ixhash_fast. Caller owns
   the val refcount; we transfer it into the vals AV. Key is UTF-8 bytes;
   we flag the resulting key SV as UTF-8 for lookup correctness on
   non-ASCII keys. */
static void ixhash_append(pTHX_ HV *idx, AV *keys, AV *vals,
                          const char *key, STRLEN klen, SV *val) {
    SSize_t pos = av_len(keys) + 1;

    SV *key_sv = newSVpvn(key, klen);
    sv_utf8_decode(key_sv);
    hv_store_ent(idx, key_sv, newSViv((IV)pos), 0);
    av_push(keys, key_sv);
    av_push(vals, val);
}

/* --- dms_value → SV -------------------------------------------------- *
 *
 * Two construction shapes:
 *   - Full mode (value_to_sv): tables are Tie::IxHash (preserves key
 *     order under the standard `keys %$h` interface). Required for the
 *     full-mode round-trip path because comments + original_forms get
 *     attached by path-key, and re-walking the document on emit needs
 *     stable insertion order.
 *
 *   - Lite mode (value_to_sv_lite): tables are plain HVs with a sidecar
 *     `__dms_keys` arrayref stored at key "\0__dms_keys" (NUL prefix
 *     can never collide with a real DMS key). Iterators that care
 *     about order read the sidecar; iterators that don't can use plain
 *     `keys %$h` (with the implicit understanding that they'll see
 *     the sidecar key).
 *
 * Skipping Tie::IxHash setup saves ~6 SV allocations per table — on
 * bench_realistic that's the dominant residual gap vs YAML::XS. */

static SV *value_to_sv_lite(pTHX_ const dms_value *v);

static SV *value_to_sv(pTHX_ const dms_value *v) {
    switch (v->type) {
        case DMS_BOOL: {
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Bool, "DMS::Parser::Bool"),
                newSViv(v->u.b ? 1 : 0));
        }
        case DMS_INTEGER: {
            /* Store as a native IV — 64-bit on 64-bit Perl. bstr() on the
             * Perl side stringifies on demand. Skips snprintf + newSVpv. */
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Integer, "DMS::Parser::Integer"),
                newSViv((IV)v->u.i));
        }
        case DMS_FLOAT: {
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Float, "DMS::Parser::Float"),
                newSVnv(v->u.f));
        }
        case DMS_STRING: {
            SV *sv = newSVpv(v->u.s ? v->u.s : "", 0);
            sv_utf8_decode(sv);
            return sv;
        }
        case DMS_OFFSET_DT:
        case DMS_LOCAL_DT:
        case DMS_LOCAL_DATE:
        case DMS_LOCAL_TIME: {
            HV **slot;
            const char *name;
            if (v->type == DMS_OFFSET_DT) { slot = &stash_OffsetDateTime; name = "DMS::Parser::OffsetDateTime"; }
            else if (v->type == DMS_LOCAL_DT) { slot = &stash_LocalDateTime; name = "DMS::Parser::LocalDateTime"; }
            else if (v->type == DMS_LOCAL_DATE) { slot = &stash_LocalDate; name = "DMS::Parser::LocalDate"; }
            else { slot = &stash_LocalTime; name = "DMS::Parser::LocalTime"; }
            SV *inner = newSVpv(v->u.s ? v->u.s : "", 0);
            sv_utf8_decode(inner);
            return bless_sentinel(aTHX_ get_stash_cached(aTHX_ slot, name), inner);
        }
        case DMS_TABLE: {
            HV *idx_hv; AV *keys_av; AV *vals_av;
            SV *href = new_ixhash_fast(aTHX_ &idx_hv, &keys_av, &vals_av);
            /* Pre-size the AVs so av_push doesn't reallocate during build. */
            if (v->u.t.len > 0) {
                av_extend(keys_av, (SSize_t)v->u.t.len - 1);
                av_extend(vals_av, (SSize_t)v->u.t.len - 1);
            }
            for (size_t i = 0; i < v->u.t.len; i++) {
                SV *val_sv = value_to_sv(aTHX_ v->u.t.items[i].value);
                ixhash_append(aTHX_ idx_hv, keys_av, vals_av,
                              v->u.t.items[i].key,
                              strlen(v->u.t.items[i].key),
                              val_sv);
            }
            return href;
        }
        case DMS_LIST: {
            AV *av = newAV();
            av_extend(av, (SSize_t)v->u.l.len);
            for (size_t i = 0; i < v->u.l.len; i++) {
                av_push(av, value_to_sv(aTHX_ v->u.l.items[i]));
            }
            return newRV_noinc((SV *)av);
        }
    }
    return &PL_sv_undef;
}

/* Lite-mode table construction: plain HV + sidecar __dms_keys AV.
 * Skips Tie::IxHash setup (saves ~6 SVs per table). Sidecar key is
 * "\0__dms_keys" — the NUL prefix guarantees no collision with any
 * real DMS key, and `keys %$h` iteration order doesn't matter in lite
 * mode (consumers read the sidecar AV for order). */
static const char SIDECAR_KEY[] = "\0__dms_keys";
#define SIDECAR_KEY_LEN 11

static SV *value_to_sv_lite(pTHX_ const dms_value *v) {
    switch (v->type) {
        case DMS_BOOL: {
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Bool, "DMS::Parser::Bool"),
                newSViv(v->u.b ? 1 : 0));
        }
        case DMS_INTEGER: {
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Integer, "DMS::Parser::Integer"),
                newSViv((IV)v->u.i));
        }
        case DMS_FLOAT: {
            return bless_sentinel(aTHX_
                get_stash_cached(aTHX_ &stash_Float, "DMS::Parser::Float"),
                newSVnv(v->u.f));
        }
        case DMS_STRING: {
            SV *sv = newSVpv(v->u.s ? v->u.s : "", 0);
            sv_utf8_decode(sv);
            return sv;
        }
        case DMS_OFFSET_DT:
        case DMS_LOCAL_DT:
        case DMS_LOCAL_DATE:
        case DMS_LOCAL_TIME: {
            HV **slot;
            const char *name;
            if (v->type == DMS_OFFSET_DT) { slot = &stash_OffsetDateTime; name = "DMS::Parser::OffsetDateTime"; }
            else if (v->type == DMS_LOCAL_DT) { slot = &stash_LocalDateTime; name = "DMS::Parser::LocalDateTime"; }
            else if (v->type == DMS_LOCAL_DATE) { slot = &stash_LocalDate; name = "DMS::Parser::LocalDate"; }
            else { slot = &stash_LocalTime; name = "DMS::Parser::LocalTime"; }
            SV *inner = newSVpv(v->u.s ? v->u.s : "", 0);
            sv_utf8_decode(inner);
            return bless_sentinel(aTHX_ get_stash_cached(aTHX_ slot, name), inner);
        }
        case DMS_TABLE: {
            HV *hv = newHV();
            AV *keys_av = newAV();
            if (v->u.t.len > 0) {
                av_extend(keys_av, (SSize_t)v->u.t.len - 1);
                hv_ksplit(hv, (U32)(v->u.t.len + 1));
            }
            for (size_t i = 0; i < v->u.t.len; i++) {
                const char *key = v->u.t.items[i].key;
                STRLEN klen = strlen(key);
                SV *val_sv = value_to_sv_lite(aTHX_ v->u.t.items[i].value);
                /* Store value into HV. hv_store consumes the value SV's
                 * refcount (one). */
                hv_store(hv, key, (I32)klen, val_sv, 0);
                /* Append a UTF-8-flagged key SV to the sidecar. */
                SV *key_sv = newSVpvn(key, klen);
                sv_utf8_decode(key_sv);
                av_push(keys_av, key_sv);
            }
            /* Sidecar at "\0__dms_keys" — NUL prefix avoids collision. */
            hv_store(hv, SIDECAR_KEY, (I32)SIDECAR_KEY_LEN,
                     newRV_noinc((SV *)keys_av), 0);
            return newRV_noinc((SV *)hv);
        }
        case DMS_LIST: {
            AV *av = newAV();
            av_extend(av, (SSize_t)v->u.l.len);
            for (size_t i = 0; i < v->u.l.len; i++) {
                av_push(av, value_to_sv_lite(aTHX_ v->u.l.items[i]));
            }
            return newRV_noinc((SV *)av);
        }
    }
    return &PL_sv_undef;
}

/* --- comment AST → SV -------------------------------------------------- */

/* Build the comment hashref { content, kind } mirroring the pure-Perl
 * parser. `content` is the raw source text (UTF-8) including delimiters.
 * `kind` is "line" or "block". */
static SV *comment_to_sv(pTHX_ const dms_attached_comment *ac) {
    HV *h = newHV();
    SV *content_sv = newSVpv(ac->content ? ac->content : "", 0);
    sv_utf8_decode(content_sv);
    hv_store(h, "content", 7, content_sv, 0);
    const char *kind = (ac->kind == DMS_COMMENT_BLOCK) ? "block" : "line";
    hv_store(h, "kind", 4, newSVpv(kind, 0), 0);
    return newRV_noinc((SV *)h);
}

/* Build a path arrayref from a dms_breadcrumb_seg array. String segments
 * are plain Perl scalars (UTF-8 decoded); index segments are blessed
 * DMS::Index scalar refs (matching the pure-Perl parser's wrapper).
 * Used by both attached-comment paths and original-form-entry paths. */
static SV *path_segs_to_sv(pTHX_ const dms_breadcrumb_seg *segs, size_t n) {
    AV *av = newAV();
    if (n > 0) av_extend(av, (SSize_t)n - 1);
    for (size_t i = 0; i < n; i++) {
        const dms_breadcrumb_seg *seg = &segs[i];
        if (seg->is_index) {
            HV *st = get_stash_cached(aTHX_ &stash_Index, "DMS::Parser::Index");
            av_push(av, bless_sentinel(aTHX_ st, newSViv((IV)seg->idx)));
        } else {
            SV *k = newSVpv(seg->key ? seg->key : "", 0);
            sv_utf8_decode(k);
            av_push(av, k);
        }
    }
    return newRV_noinc((SV *)av);
}

static SV *path_to_sv(pTHX_ const dms_attached_comment *ac) {
    return path_segs_to_sv(aTHX_ ac->path, ac->path_len);
}

/* Build the `string_form` hashref for an original-literal record whose
 * lit.is_string_form == 1. Mirrors the shape DMS::Emitter expects:
 *   { kind => 'basic'|'literal'|'heredoc',
 *     flavor => 'basic_triple'|'literal_triple' (heredoc only),
 *     label => "...",                            (heredoc only)
 *     modifiers => [ { name => "...", args => [...] }, ... ] (heredoc only) }
 * The `args` array is left empty for now — the C struct stores
 * `dms_value **args`, but heredoc modifier args round-trip through the
 * lexeme buffer in dms-c, and the Perl Emitter currently only inspects
 * `name` (it re-applies the modifier via dispatch on name). */
static SV *string_form_to_sv(pTHX_ const dms_string_form *sf) {
    HV *h = newHV();
    const char *kind =
        (sf->kind == DMS_STRING_BASIC)   ? "basic"   :
        (sf->kind == DMS_STRING_LITERAL) ? "literal" :
                                           "heredoc";
    hv_store(h, "kind", 4, newSVpv(kind, 0), 0);
    if (sf->kind == DMS_STRING_HEREDOC) {
        const char *flavor = (sf->heredoc_flavor == DMS_HEREDOC_BASIC_TRIPLE)
                             ? "basic_triple" : "literal_triple";
        hv_store(h, "flavor", 6, newSVpv(flavor, 0), 0);
        if (sf->label) {
            SV *lbl = newSVpv(sf->label, 0);
            sv_utf8_decode(lbl);
            hv_store(h, "label", 5, lbl, 0);
        } else {
            hv_store(h, "label", 5, newSV(0), 0);
        }
        AV *mods = newAV();
        if (sf->num_modifiers > 0) av_extend(mods, (SSize_t)sf->num_modifiers - 1);
        for (size_t i = 0; i < sf->num_modifiers; i++) {
            HV *m = newHV();
            const dms_heredoc_modifier_call *mc = &sf->modifiers[i];
            SV *name = newSVpv(mc->name ? mc->name : "", 0);
            sv_utf8_decode(name);
            hv_store(m, "name", 4, name, 0);
            /* args: marshal the dms_value array to a Perl arrayref via the
             * existing value_to_sv() so heredoc modifier args (e.g. "\n",
             * ">") survive the round-trip. */
            AV *args = newAV();
            if (mc->num_args > 0) av_extend(args, (SSize_t)mc->num_args - 1);
            for (size_t j = 0; j < mc->num_args; j++) {
                if (mc->args[j]) {
                    av_push(args, value_to_sv(aTHX_ mc->args[j]));
                } else {
                    av_push(args, newSV(0));
                }
            }
            hv_store(m, "args", 4, newRV_noinc((SV *)args), 0);
            av_push(mods, newRV_noinc((SV *)m));
        }
        hv_store(h, "modifiers", 9, newRV_noinc((SV *)mods), 0);
    }
    return newRV_noinc((SV *)h);
}

/* Build the per-entry lit hashref. The Emitter checks for the presence
 * of `integer_lit` vs `string_form` keys to dispatch — exactly one is
 * populated per entry, matching the C struct's `is_string_form` flag. */
static SV *original_lit_to_sv(pTHX_ const dms_original_literal *lit) {
    HV *h = newHV();
    if (lit->is_string_form) {
        if (lit->string_form) {
            hv_store(h, "string_form", 11, string_form_to_sv(aTHX_ lit->string_form), 0);
        }
    } else {
        if (lit->integer_lit) {
            SV *s = newSVpv(lit->integer_lit, 0);
            /* integer_lit is ASCII (digits + 0x/0o/0b prefixes + underscores)
             * — no UTF-8 decode needed. */
            hv_store(h, "integer_lit", 11, s, 0);
        }
    }
    return newRV_noinc((SV *)h);
}

/* Convert the C original-forms array to the Perl `[[path, lit], ...]`
 * shape DMS::Emitter expects. Returns an empty arrayref (not undef) when
 * `n == 0` so the Emitter's `|| []` guard is the only fallback path. */
static SV *original_forms_to_sv(pTHX_ const dms_original_form_entry *items, size_t n) {
    AV *av = newAV();
    if (n > 0) av_extend(av, (SSize_t)n - 1);
    for (size_t i = 0; i < n; i++) {
        const dms_original_form_entry *e = &items[i];
        AV *pair = newAV();
        av_extend(pair, 1);
        av_push(pair, path_segs_to_sv(aTHX_ e->path, e->path_len));
        av_push(pair, original_lit_to_sv(aTHX_ &e->lit));
        av_push(av, newRV_noinc((SV *)pair));
    }
    return newRV_noinc((SV *)av);
}

static SV *comments_to_sv(pTHX_ const dms_attached_comment *items, size_t n) {
    AV *av = newAV();
    if (n > 0) av_extend(av, (SSize_t)n - 1);
    for (size_t i = 0; i < n; i++) {
        const dms_attached_comment *ac = &items[i];
        HV *h = newHV();
        hv_store(h, "comment",  7, comment_to_sv(aTHX_ ac), 0);
        const char *pos =
            (ac->position == DMS_COMMENT_LEADING)  ? "leading"  :
            (ac->position == DMS_COMMENT_INNER)    ? "inner"    :
            (ac->position == DMS_COMMENT_TRAILING) ? "trailing" :
                                                     "floating";
        hv_store(h, "position", 8, newSVpv(pos, 0), 0);
        hv_store(h, "path",     4, path_to_sv(aTHX_ ac), 0);
        av_push(av, newRV_noinc((SV *)h));
    }
    return newRV_noinc((SV *)av);
}

/* --- Direct DMS -> conformance JSON streaming emit -------------------------
 *
 * For workloads where the only consumer of the parse tree is a JSON-emit
 * step (e.g. the conformance encoder, dms-tests harness), building the
 * full Perl SV/HV/AV/Tie::IxHash tree just to walk it once is pure waste.
 * `parse_to_json_bytes(src)` skips that round trip: it parses, then
 * serializes the dms_value tree directly into a single Perl string buffer
 * in C. No blessed sentinels, no IxHash tied magic, no per-leaf Perl call
 * frame.
 *
 * Output shape matches encoder.pl's `encode_json_value` byte-for-byte at
 * the structural level (the conformance runner re-parses the JSON, so
 * exact whitespace doesn't matter, only key order in objects). Tagged
 * scalars look like { "type": "...", "value": "..." }; tables are objects
 * preserving source key order; lists are arrays. Front matter, when
 * present, is wrapped as { "_meta": ..., "_body": ... } per the spec. */

typedef struct {
    char *buf;
    size_t len;
    size_t cap;
} jbuf;

/* XSUB.h #defines `realloc`/`free` as Perl's PerlMem_* macros which
 * require a thread-context argument. Our jbuf doesn't need that
 * indirection — it's a leaf C buffer with no Perl interaction — so we
 * #undef the macros and route through small libc-direct wrappers. The
 * Perl-side allocator is irrelevant here: jbuf memory lives only across
 * one XS call and is freed before returning. */
#ifdef realloc
#  undef realloc
#endif
#ifdef free
#  undef free
#endif

static void *libc_realloc(void *p, size_t n) { return realloc(p, n); }
static void  libc_free(void *p) { free(p); }

static void jbuf_grow(jbuf *j, size_t need) {
    size_t want = j->len + need;
    if (want <= j->cap) return;
    size_t cap = j->cap ? j->cap : 4096;
    while (cap < want) cap *= 2;
    j->buf = (char *)libc_realloc(j->buf, cap);
    j->cap = cap;
}

static inline void jbuf_putc(jbuf *j, char c) {
    if (j->len + 1 > j->cap) jbuf_grow(j, 1);
    j->buf[j->len++] = c;
}

static inline void jbuf_puts(jbuf *j, const char *s, size_t n) {
    if (j->len + n > j->cap) jbuf_grow(j, n);
    memcpy(j->buf + j->len, s, n);
    j->len += n;
}

static inline void jbuf_putcstr(jbuf *j, const char *s) {
    jbuf_puts(j, s, strlen(s));
}

/* Indent: 2 spaces per level. */
static void jbuf_indent(jbuf *j, int n) {
    if (n <= 0) return;
    size_t need = (size_t)n * 2;
    if (j->len + need > j->cap) jbuf_grow(j, need);
    memset(j->buf + j->len, ' ', need);
    j->len += need;
}

/* JSON-quote a UTF-8 string. We escape only the JSON-mandated control
 * characters and quote/backslash; bytes >= 0x20 are passed through
 * verbatim (they're already valid UTF-8 from the parser). */
static void jbuf_quote(jbuf *j, const char *s, size_t n) {
    jbuf_putc(j, '"');
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        switch (c) {
            case '"':  jbuf_puts(j, "\\\"", 2); break;
            case '\\': jbuf_puts(j, "\\\\", 2); break;
            case '\n': jbuf_puts(j, "\\n", 2); break;
            case '\r': jbuf_puts(j, "\\r", 2); break;
            case '\t': jbuf_puts(j, "\\t", 2); break;
            case '\b': jbuf_puts(j, "\\b", 2); break;
            case '\f': jbuf_puts(j, "\\f", 2); break;
            default:
                if (c < 0x20) {
                    char tmp[8];
                    int k = snprintf(tmp, sizeof(tmp), "\\u%04x", c);
                    jbuf_puts(j, tmp, (size_t)k);
                } else {
                    jbuf_putc(j, (char)c);
                }
        }
    }
    jbuf_putc(j, '"');
}

static void jbuf_quote_cstr(jbuf *j, const char *s) {
    jbuf_quote(j, s, strlen(s));
}

/* Render a 64-bit integer. Faster than snprintf for the common case. */
static void jbuf_int64(jbuf *j, int64_t v) {
    char tmp[24];
    int n;
    if (v == INT64_MIN) {
        n = snprintf(tmp, sizeof(tmp), "%" PRId64, v);
    } else {
        int neg = v < 0;
        uint64_t u = neg ? (uint64_t)(-v) : (uint64_t)v;
        char *p = tmp + sizeof(tmp);
        do { *--p = (char)('0' + (u % 10)); u /= 10; } while (u);
        if (neg) *--p = '-';
        n = (int)((tmp + sizeof(tmp)) - p);
        jbuf_puts(j, p, (size_t)n);
        return;
    }
    jbuf_puts(j, tmp, (size_t)n);
}

/* Render a double in shortest-round-trippable form, matching the
 * encoder.pl `shortest_float` rules:
 *   - nan / inf / -inf are emitted as literals
 *   - search %.1g..%.17g for the shortest representation that round-trips
 *   - normalize exponent: "e+12" -> "e12", "e-04" -> "e-4", "e07" -> "e7"
 *   - if the result has no '.' or 'e'/'E', append ".0" */
static void jbuf_float(jbuf *j, double v) {
    /* nan / inf */
    if (v != v) { jbuf_putcstr(j, "nan"); return; }
    if (v > 1.7976931348623157e308) { jbuf_putcstr(j, "inf"); return; }
    if (v < -1.7976931348623157e308) { jbuf_putcstr(j, "-inf"); return; }

    char buf[64];
    int chosen_n = 0;
    for (int p = 1; p <= 17; p++) {
        int n = snprintf(buf, sizeof(buf), "%.*g", p, v);
        double back = strtod(buf, NULL);
        if (back == v) { chosen_n = n; break; }
    }
    if (chosen_n == 0) {
        chosen_n = snprintf(buf, sizeof(buf), "%.17g", v);
    }

    /* Post-process exponent. */
    char out[64];
    int oi = 0;
    int has_dot_or_e = 0;
    for (int i = 0; i < chosen_n; i++) {
        char c = buf[i];
        if (c == '.') has_dot_or_e = 1;
        if (c == 'e' || c == 'E') {
            has_dot_or_e = 1;
            out[oi++] = c;
            i++;
            int sign = 1;
            if (i < chosen_n && buf[i] == '+') { i++; }
            else if (i < chosen_n && buf[i] == '-') { sign = -1; i++; }
            /* skip leading zeros */
            while (i < chosen_n && buf[i] == '0') i++;
            if (i >= chosen_n || buf[i] < '0' || buf[i] > '9') {
                /* exponent collapsed to zero — drop it */
                /* Pop the 'e' we already wrote. */
                oi--;
                continue;
            }
            if (sign < 0) out[oi++] = '-';
            while (i < chosen_n) out[oi++] = buf[i++];
            break;
        }
        out[oi++] = c;
    }
    if (!has_dot_or_e) {
        out[oi++] = '.';
        out[oi++] = '0';
    }
    jbuf_puts(j, out, (size_t)oi);
}

static void emit_value(jbuf *j, const dms_value *v, int indent);

/* Emit a tagged scalar:
 *   {
 *     "type": "<t>",
 *     "value": "<v>"
 *   }
 * with the same indentation rules as encoder.pl. */
static void emit_tagged(jbuf *j, const char *type, int indent,
                        void (*write_value)(jbuf *, const dms_value *),
                        const dms_value *v) {
    jbuf_puts(j, "{\n", 2);
    jbuf_indent(j, indent + 1);
    jbuf_puts(j, "\"type\": \"", 9);
    jbuf_putcstr(j, type);
    jbuf_puts(j, "\",\n", 3);
    jbuf_indent(j, indent + 1);
    jbuf_puts(j, "\"value\": \"", 10);
    write_value(j, v);
    jbuf_puts(j, "\"\n", 2);
    jbuf_indent(j, indent);
    jbuf_putc(j, '}');
}

/* write_value callbacks — write the inner string of a tagged scalar
 * (no surrounding quotes; the caller already wrote them). */
static void wv_bool(jbuf *j, const dms_value *v) {
    jbuf_putcstr(j, v->u.b ? "true" : "false");
}

static void wv_int(jbuf *j, const dms_value *v) {
    jbuf_int64(j, v->u.i);
}

static void wv_float(jbuf *j, const dms_value *v) {
    jbuf_float(j, v->u.f);
}

/* Datetime values: stored as a UTF-8 NUL-terminated string in v->u.s.
 * No JSON escaping is needed (datetime/date/time strings are ASCII), but
 * for safety we run them through the same escape code as other strings. */
static void wv_str_escape(jbuf *j, const dms_value *v) {
    const char *s = v->u.s ? v->u.s : "";
    for (const char *p = s; *p; p++) {
        unsigned char c = (unsigned char)*p;
        switch (c) {
            case '"':  jbuf_puts(j, "\\\"", 2); break;
            case '\\': jbuf_puts(j, "\\\\", 2); break;
            case '\n': jbuf_puts(j, "\\n", 2); break;
            case '\r': jbuf_puts(j, "\\r", 2); break;
            case '\t': jbuf_puts(j, "\\t", 2); break;
            case '\b': jbuf_puts(j, "\\b", 2); break;
            case '\f': jbuf_puts(j, "\\f", 2); break;
            default:
                if (c < 0x20) {
                    char tmp[8];
                    int k = snprintf(tmp, sizeof(tmp), "\\u%04x", c);
                    jbuf_puts(j, tmp, (size_t)k);
                } else {
                    jbuf_putc(j, (char)c);
                }
        }
    }
}

static void emit_value(jbuf *j, const dms_value *v, int indent) {
    switch (v->type) {
        case DMS_BOOL:
            emit_tagged(j, "bool", indent, wv_bool, v); return;
        case DMS_INTEGER:
            emit_tagged(j, "integer", indent, wv_int, v); return;
        case DMS_FLOAT:
            emit_tagged(j, "float", indent, wv_float, v); return;
        case DMS_STRING:
            emit_tagged(j, "string", indent, wv_str_escape, v); return;
        case DMS_OFFSET_DT:
            emit_tagged(j, "offset-datetime", indent, wv_str_escape, v); return;
        case DMS_LOCAL_DT:
            emit_tagged(j, "local-datetime", indent, wv_str_escape, v); return;
        case DMS_LOCAL_DATE:
            emit_tagged(j, "local-date", indent, wv_str_escape, v); return;
        case DMS_LOCAL_TIME:
            emit_tagged(j, "local-time", indent, wv_str_escape, v); return;
        case DMS_TABLE: {
            if (v->u.t.len == 0) { jbuf_puts(j, "{}", 2); return; }
            jbuf_puts(j, "{\n", 2);
            for (size_t i = 0; i < v->u.t.len; i++) {
                jbuf_indent(j, indent + 1);
                const char *k = v->u.t.items[i].key;
                jbuf_quote(j, k, strlen(k));
                jbuf_puts(j, ": ", 2);
                emit_value(j, v->u.t.items[i].value, indent + 1);
                if (i + 1 < v->u.t.len) jbuf_putc(j, ',');
                jbuf_putc(j, '\n');
            }
            jbuf_indent(j, indent);
            jbuf_putc(j, '}');
            return;
        }
        case DMS_LIST: {
            if (v->u.l.len == 0) { jbuf_puts(j, "[]", 2); return; }
            jbuf_puts(j, "[\n", 2);
            for (size_t i = 0; i < v->u.l.len; i++) {
                jbuf_indent(j, indent + 1);
                emit_value(j, v->u.l.items[i], indent + 1);
                if (i + 1 < v->u.l.len) jbuf_putc(j, ',');
                jbuf_putc(j, '\n');
            }
            jbuf_indent(j, indent);
            jbuf_putc(j, ']');
            return;
        }
    }
}

/* Top-level: wrap with { "_meta": ..., "_body": ... } when meta is
 * present, otherwise just emit the body. Always trailing '\n'. */
static void emit_document(jbuf *j, const dms_document *doc) {
    if (doc->meta) {
        dms_value mv;
        mv.type = DMS_TABLE;
        mv.u.t = *doc->meta;
        jbuf_puts(j, "{\n", 2);
        jbuf_indent(j, 1);
        jbuf_puts(j, "\"_meta\": ", 9);
        emit_value(j, &mv, 1);
        jbuf_puts(j, ",\n", 2);
        jbuf_indent(j, 1);
        jbuf_puts(j, "\"_body\": ", 9);
        emit_value(j, doc->body, 1);
        jbuf_puts(j, "\n}", 2);
    } else {
        emit_value(j, doc->body, 0);
    }
    jbuf_putc(j, '\n');
}

/* --- C-side to_dms_lite emitter ---------------------------------------- *
 *
 * Walks a Perl Document tree (the shape returned by parse_document_lite)
 * and emits canonical DMS source bytes directly into a Perl SV. Skips
 * the per-kvpair Perl-VM trips of the pure-Perl emitter — for the
 * realistic 25 KB fixture this drops emit cost from ~2 ms (post-pure-
 * Perl-optimisation) to a fraction of that, finally beating YAML::XS's
 * libyaml-backed Dump.
 *
 * Scope: lite mode only. Skips comment-AST + original_forms by
 * construction (those maps are empty in lite mode anyway). For full-
 * mode round-trip, the pure-Perl Emitter still owns the path: comment
 * walking and per-path original-form lookups are easier to express in
 * Perl and the 25 KB fixture isn't the worst case for full mode. */

typedef struct {
    char *buf;
    STRLEN len;
    STRLEN cap;
} dbuf;

static void dbuf_init(pTHX_ dbuf *d, STRLEN cap) {
    Newx(d->buf, cap, char);
    d->len = 0;
    d->cap = cap;
}

static void dbuf_free(pTHX_ dbuf *d) {
    if (d->buf) Safefree(d->buf);
    d->buf = NULL;
    d->len = d->cap = 0;
}

static void dbuf_grow(pTHX_ dbuf *d, STRLEN need) {
    STRLEN newcap = d->cap;
    if (newcap < 256) newcap = 256;
    while (newcap < d->len + need) newcap *= 2;
    Renew(d->buf, newcap, char);
    d->cap = newcap;
}

static inline void dbuf_putc(pTHX_ dbuf *d, char c) {
    if (d->len + 1 > d->cap) dbuf_grow(aTHX_ d, 1);
    d->buf[d->len++] = c;
}

static inline void dbuf_puts(pTHX_ dbuf *d, const char *s, STRLEN n) {
    if (d->len + n > d->cap) dbuf_grow(aTHX_ d, n);
    memcpy(d->buf + d->len, s, n);
    d->len += n;
}

static void dbuf_indent(pTHX_ dbuf *d, int level) {
    STRLEN need = (STRLEN)level * 2;
    if (d->len + need > d->cap) dbuf_grow(aTHX_ d, need);
    for (int i = 0; i < level; i++) {
        d->buf[d->len++] = ' ';
        d->buf[d->len++] = ' ';
    }
}

/* Bare-key check: ASCII identifier ([A-Za-z_][A-Za-z0-9_-]*). For full
 * Unicode XID coverage we'd need utf8proc; the realistic fixture is
 * 100% ASCII keys so the ASCII path covers it. Non-bare keys go through
 * the quoted-key path. */
static int is_bare_key_ascii(const char *s, STRLEN n) {
    if (n == 0) return 0;
    unsigned char c = (unsigned char)s[0];
    if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_'))
        return 0;
    for (STRLEN i = 1; i < n; i++) {
        c = (unsigned char)s[i];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
              (c >= '0' && c <= '9') || c == '_' || c == '-'))
            return 0;
    }
    return 1;
}

/* Emit a basic-quoted string ("...") with escapes. Fast path for clean
 * strings copies bytes verbatim. */
static void dbuf_basic_string(pTHX_ dbuf *d, const char *s, STRLEN n) {
    /* Fast path: scan for any byte needing escape. */
    int dirty = 0;
    for (STRLEN i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c == '\\' || c == '"' || c < 0x20) { dirty = 1; break; }
    }
    if (d->len + n + 2 > d->cap) dbuf_grow(aTHX_ d, n + 2);
    d->buf[d->len++] = '"';
    if (!dirty) {
        memcpy(d->buf + d->len, s, n);
        d->len += n;
        if (d->len + 1 > d->cap) dbuf_grow(aTHX_ d, 1);
        d->buf[d->len++] = '"';
        return;
    }
    for (STRLEN i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        if (d->len + 6 > d->cap) dbuf_grow(aTHX_ d, 6);
        switch (c) {
            case '\\': d->buf[d->len++] = '\\'; d->buf[d->len++] = '\\'; break;
            case '"':  d->buf[d->len++] = '\\'; d->buf[d->len++] = '"';  break;
            case '\n': d->buf[d->len++] = '\\'; d->buf[d->len++] = 'n';  break;
            case '\r': d->buf[d->len++] = '\\'; d->buf[d->len++] = 'r';  break;
            case '\t': d->buf[d->len++] = '\\'; d->buf[d->len++] = 't';  break;
            case '\b': d->buf[d->len++] = '\\'; d->buf[d->len++] = 'b';  break;
            case '\f': d->buf[d->len++] = '\\'; d->buf[d->len++] = 'f';  break;
            default:
                if (c < 0x20) {
                    int k = snprintf(d->buf + d->len, d->cap - d->len,
                                     "\\u%04X", c);
                    d->len += (STRLEN)k;
                } else {
                    d->buf[d->len++] = (char)c;
                }
        }
    }
    d->buf[d->len++] = '"';
}

/* Emit a key bare-or-quoted. */
static void dbuf_emit_key(pTHX_ dbuf *d, const char *s, STRLEN n) {
    if (is_bare_key_ascii(s, n)) {
        dbuf_puts(aTHX_ d, s, n);
    } else {
        dbuf_basic_string(aTHX_ d, s, n);
    }
}

/* Lite-mode tables carry their key order in a sidecar AV stored at
 * key "\0__dms_keys". Returns that AV if present, NULL otherwise.
 * Used by emit_perl_table to iterate in insertion order without
 * incurring Tie::IxHash overhead. */
static AV *get_lite_keys(pTHX_ HV *hv) {
    SV **slot = hv_fetch(hv, SIDECAR_KEY, SIDECAR_KEY_LEN, 0);
    if (!slot || !*slot || !SvROK(*slot)) return NULL;
    SV *rv = SvRV(*slot);
    if (SvTYPE(rv) != SVt_PVAV) return NULL;
    return (AV *)rv;
}

/* Detect Tie::IxHash on an HV. Returns the underlying tied AV
 * `[idx_rv, keys_rv, vals_rv, iter]` if found, NULL otherwise. */
static AV *get_ixhash_tied(pTHX_ HV *hv) {
    if (!SvRMAGICAL((SV *)hv)) return NULL;
    /* mg_find (not mg_findext) since sv_magic auto-installs a vtable
     * for PERL_MAGIC_tied; we don't want to match on a NULL vtable. */
    MAGIC *mg = mg_find((SV *)hv, PERL_MAGIC_tied);
    if (!mg || !mg->mg_obj) return NULL;
    SV *obj = mg->mg_obj;
    if (!SvROK(obj)) return NULL;
    SV *inner = SvRV(obj);
    if (!SvOBJECT(inner)) return NULL;
    HV *tied_stash = SvSTASH(inner);
    if (!tied_stash) return NULL;
    if (!stash_IxHash) stash_IxHash = gv_stashpv("Tie::IxHash", GV_ADD);
    if (tied_stash != stash_IxHash) return NULL;
    if (SvTYPE(inner) != SVt_PVAV) return NULL;
    return (AV *)inner;
}

/* Forward-declare: emit value (any kind) at given indent. */
static void emit_perl_value(pTHX_ dbuf *d, SV *v, int indent);
static void emit_perl_table(pTHX_ dbuf *d, HV *hv, int indent);
static void emit_perl_list(pTHX_ dbuf *d, AV *av, int indent);

/* Classify a blessed SV by its stash. */
typedef enum {
    BLE_OTHER = 0,
    BLE_BOOL, BLE_INTEGER, BLE_FLOAT,
    BLE_OFFSET_DT, BLE_LOCAL_DT, BLE_LOCAL_DATE, BLE_LOCAL_TIME,
    BLE_UNORDERED
} blessed_kind;

static HV *stash_UnorderedTable;

static blessed_kind classify_blessed(pTHX_ SV *rv) {
    if (!SvROK(rv)) return BLE_OTHER;
    SV *target = SvRV(rv);
    if (!SvOBJECT(target)) return BLE_OTHER;
    HV *st = SvSTASH(target);
    if (!st) return BLE_OTHER;
    /* Cache the stashes we care about and compare by pointer — much
     * faster than HvNAME comparisons. */
    if (!stash_Bool) stash_Bool = gv_stashpv("DMS::Parser::Bool", GV_ADD);
    if (st == stash_Bool) return BLE_BOOL;
    if (!stash_Integer) stash_Integer = gv_stashpv("DMS::Parser::Integer", GV_ADD);
    if (st == stash_Integer) return BLE_INTEGER;
    if (!stash_Float) stash_Float = gv_stashpv("DMS::Parser::Float", GV_ADD);
    if (st == stash_Float) return BLE_FLOAT;
    if (!stash_OffsetDateTime) stash_OffsetDateTime = gv_stashpv("DMS::Parser::OffsetDateTime", GV_ADD);
    if (st == stash_OffsetDateTime) return BLE_OFFSET_DT;
    if (!stash_LocalDateTime) stash_LocalDateTime = gv_stashpv("DMS::Parser::LocalDateTime", GV_ADD);
    if (st == stash_LocalDateTime) return BLE_LOCAL_DT;
    if (!stash_LocalDate) stash_LocalDate = gv_stashpv("DMS::Parser::LocalDate", GV_ADD);
    if (st == stash_LocalDate) return BLE_LOCAL_DATE;
    if (!stash_LocalTime) stash_LocalTime = gv_stashpv("DMS::Parser::LocalTime", GV_ADD);
    if (st == stash_LocalTime) return BLE_LOCAL_TIME;
    if (!stash_UnorderedTable) stash_UnorderedTable = gv_stashpv("DMS::Parser::UnorderedTable", GV_ADD);
    if (st == stash_UnorderedTable) return BLE_UNORDERED;
    return BLE_OTHER;
}

/* Emit a value inline (no indent prefix, no trailing newline).
 * Used for scalar values and flow-form sub-values. */
static void emit_perl_value_inline(pTHX_ dbuf *d, SV *v) {
    if (!v || !SvOK(v)) {
        /* Defensive: undef shouldn't reach here in lite mode (no nulls
         * in DMS), but emit "" to avoid crashing on broken input. */
        dbuf_puts(aTHX_ d, "\"\"", 2);
        return;
    }
    if (SvROK(v)) {
        blessed_kind k = classify_blessed(aTHX_ v);
        if (k == BLE_BOOL) {
            SV *inner = SvRV(v);
            if (SvTRUE(inner)) dbuf_puts(aTHX_ d, "true", 4);
            else dbuf_puts(aTHX_ d, "false", 5);
            return;
        }
        if (k == BLE_INTEGER) {
            SV *inner = SvRV(v);
            char tmp[24];
            int n = snprintf(tmp, sizeof(tmp), "%" IVdf, SvIV(inner));
            dbuf_puts(aTHX_ d, tmp, (STRLEN)n);
            return;
        }
        if (k == BLE_FLOAT) {
            SV *inner = SvRV(v);
            NV f = SvNV(inner);
            if (Perl_isnan(f)) { dbuf_puts(aTHX_ d, "nan", 3); return; }
            if (Perl_isinf(f)) {
                dbuf_puts(aTHX_ d, f > 0 ? "inf" : "-inf", f > 0 ? 3 : 4);
                return;
            }
            char tmp[64];
            int n = snprintf(tmp, sizeof(tmp), "%.17g", f);
            /* Trim to shortest round-trip would require ryu; the .17g
             * fallback is correct, just verbose. The lite-mode emit
             * doesn't promise minimal-form floats anyway. */
            dbuf_puts(aTHX_ d, tmp, (STRLEN)n);
            return;
        }
        if (k >= BLE_OFFSET_DT && k <= BLE_LOCAL_TIME) {
            SV *inner = SvRV(v);
            STRLEN slen;
            const char *s = SvPV(inner, slen);
            dbuf_puts(aTHX_ d, s, slen);
            return;
        }
        SV *rv = SvRV(v);
        if (SvTYPE(rv) == SVt_PVAV) {
            /* Plain array ref → flow list. */
            AV *av = (AV *)rv;
            SSize_t n = av_len(av) + 1;
            if (n == 0) { dbuf_puts(aTHX_ d, "[]", 2); return; }
            dbuf_putc(aTHX_ d, '[');
            for (SSize_t i = 0; i < n; i++) {
                if (i > 0) dbuf_puts(aTHX_ d, ", ", 2);
                SV **slot = av_fetch(av, i, 0);
                if (slot) emit_perl_value_inline(aTHX_ d, *slot);
            }
            dbuf_putc(aTHX_ d, ']');
            return;
        }
        if (SvTYPE(rv) == SVt_PVHV) {
            /* Tie::IxHash, lite-mode sidecar, or plain HV. Check
             * Tie::IxHash first — hv_fetch (used by get_lite_keys) on
             * a tied HV runs FETCH magic, which is slow. */
            HV *hv = (HV *)rv;
            AV *tied = get_ixhash_tied(aTHX_ hv);
            AV *lite_keys = tied ? NULL : get_lite_keys(aTHX_ hv);
            int empty;
            if (tied) {
                SV **slot = av_fetch(tied, 1, 0);
                AV *keys = slot ? (AV *)SvRV(*slot) : NULL;
                empty = !keys || av_len(keys) < 0;
            } else if (lite_keys) {
                empty = av_len(lite_keys) < 0;
            } else {
                empty = !HvUSEDKEYS(hv);
            }
            if (empty) { dbuf_puts(aTHX_ d, "{}", 2); return; }
            dbuf_putc(aTHX_ d, '{');
            int first = 1;
            if (lite_keys) {
                SSize_t n = av_len(lite_keys) + 1;
                for (SSize_t i = 0; i < n; i++) {
                    SV **kp = av_fetch(lite_keys, i, 0);
                    if (!kp) continue;
                    STRLEN klen;
                    const char *ks = SvPV(*kp, klen);
                    SV **vp = hv_fetch(hv, ks, (I32)klen, 0);
                    if (!vp) continue;
                    if (!first) dbuf_puts(aTHX_ d, ", ", 2);
                    first = 0;
                    dbuf_emit_key(aTHX_ d, ks, klen);
                    dbuf_puts(aTHX_ d, ": ", 2);
                    emit_perl_value_inline(aTHX_ d, *vp);
                }
            } else if (tied) {
                SV **k_slot = av_fetch(tied, 1, 0);
                SV **v_slot = av_fetch(tied, 2, 0);
                AV *keys = (AV *)SvRV(*k_slot);
                AV *vals = (AV *)SvRV(*v_slot);
                SSize_t n = av_len(keys) + 1;
                for (SSize_t i = 0; i < n; i++) {
                    SV **kp = av_fetch(keys, i, 0);
                    SV **vp = av_fetch(vals, i, 0);
                    if (!kp || !vp) continue;
                    if (!first) dbuf_puts(aTHX_ d, ", ", 2);
                    first = 0;
                    STRLEN klen;
                    const char *ks = SvPV(*kp, klen);
                    dbuf_emit_key(aTHX_ d, ks, klen);
                    dbuf_puts(aTHX_ d, ": ", 2);
                    emit_perl_value_inline(aTHX_ d, *vp);
                }
            } else {
                hv_iterinit(hv);
                HE *he;
                while ((he = hv_iternext(hv))) {
                    if (!first) dbuf_puts(aTHX_ d, ", ", 2);
                    first = 0;
                    STRLEN klen;
                    char *ks = HePV(he, klen);
                    dbuf_emit_key(aTHX_ d, ks, klen);
                    dbuf_puts(aTHX_ d, ": ", 2);
                    emit_perl_value_inline(aTHX_ d, HeVAL(he));
                }
            }
            dbuf_putc(aTHX_ d, '}');
            return;
        }
        /* Other refs: shouldn't happen in lite mode. Fall through. */
        dbuf_puts(aTHX_ d, "\"\"", 2);
        return;
    }
    /* Plain (non-ref) scalar. In Perl, parse_document_lite returns string
     * values as plain SV PVs. */
    STRLEN slen;
    const char *s = SvPV(v, slen);
    dbuf_basic_string(aTHX_ d, s, slen);
}

static void emit_perl_table(pTHX_ dbuf *d, HV *hv, int indent) {
    /* Order matters: check Tie::IxHash FIRST (full-mode common case)
     * because hv_fetch on a tied HV runs the FETCH magic, and looking
     * up the lite-mode sidecar key first would trigger that on every
     * full-mode table. mg_find is a cheap pointer-chain walk by
     * comparison. */
    AV *tied = get_ixhash_tied(aTHX_ hv);
    if (tied) {
        SV **k_slot = av_fetch(tied, 1, 0);
        SV **v_slot = av_fetch(tied, 2, 0);
        if (!k_slot || !v_slot) return;
        AV *keys = (AV *)SvRV(*k_slot);
        AV *vals = (AV *)SvRV(*v_slot);
        SSize_t n = av_len(keys) + 1;
        for (SSize_t i = 0; i < n; i++) {
            SV **kp = av_fetch(keys, i, 0);
            SV **vp = av_fetch(vals, i, 0);
            if (!kp || !vp) continue;
            STRLEN klen;
            const char *ks = SvPV(*kp, klen);
            SV *v = *vp;
            int can_block = 0;
            if (v && SvROK(v)) {
                SV *rv = SvRV(v);
                blessed_kind bk = classify_blessed(aTHX_ v);
                if (bk == BLE_OTHER || bk == BLE_UNORDERED) {
                    if (SvTYPE(rv) == SVt_PVHV) {
                        HV *sub = (HV *)rv;
                        AV *sub_tied = get_ixhash_tied(aTHX_ sub);
                        if (sub_tied) {
                            SV **sk = av_fetch(sub_tied, 1, 0);
                            if (sk && av_len((AV *)SvRV(*sk)) >= 0)
                                can_block = 1;
                        } else if (HvUSEDKEYS(sub)) {
                            can_block = 1;
                        }
                    } else if (SvTYPE(rv) == SVt_PVAV) {
                        if (av_len((AV *)rv) >= 0) can_block = 1;
                    }
                }
            }
            dbuf_indent(aTHX_ d, indent);
            dbuf_emit_key(aTHX_ d, ks, klen);
            dbuf_putc(aTHX_ d, ':');
            if (can_block) {
                dbuf_putc(aTHX_ d, '\n');
                SV *rv = SvRV(v);
                if (SvTYPE(rv) == SVt_PVHV) {
                    emit_perl_table(aTHX_ d, (HV *)rv, indent + 1);
                } else {
                    emit_perl_list(aTHX_ d, (AV *)rv, indent + 1);
                }
            } else {
                dbuf_putc(aTHX_ d, ' ');
                emit_perl_value_inline(aTHX_ d, v);
                dbuf_putc(aTHX_ d, '\n');
            }
        }
        return;
    }
    /* Plain HV: lite-mode shape with sidecar __dms_keys, OR a non-DMS
     * hash. The sidecar lookup is safe now (no tie magic to dispatch). */
    AV *lite_keys = get_lite_keys(aTHX_ hv);
    if (lite_keys) {
        SSize_t n = av_len(lite_keys) + 1;
        for (SSize_t i = 0; i < n; i++) {
            SV **kp = av_fetch(lite_keys, i, 0);
            if (!kp) continue;
            STRLEN klen;
            const char *ks = SvPV(*kp, klen);
            SV **vp = hv_fetch(hv, ks, (I32)klen, 0);
            if (!vp) continue;
            SV *v = *vp;
            int can_block = 0;
            if (v && SvROK(v)) {
                SV *rv = SvRV(v);
                blessed_kind bk = classify_blessed(aTHX_ v);
                if (bk == BLE_OTHER || bk == BLE_UNORDERED) {
                    if (SvTYPE(rv) == SVt_PVHV) {
                        HV *sub = (HV *)rv;
                        /* Sub-table check: lite_keys path again. mg_find on a
                         * non-tied sub HV is fast; sidecar check fast too. */
                        if (SvRMAGICAL((SV *)sub) && get_ixhash_tied(aTHX_ sub)) {
                            AV *sub_tied = get_ixhash_tied(aTHX_ sub);
                            SV **sk = av_fetch(sub_tied, 1, 0);
                            if (sk && av_len((AV *)SvRV(*sk)) >= 0)
                                can_block = 1;
                        } else {
                            AV *sub_keys = get_lite_keys(aTHX_ sub);
                            if (sub_keys) {
                                if (av_len(sub_keys) >= 0) can_block = 1;
                            } else if (HvUSEDKEYS(sub)) {
                                can_block = 1;
                            }
                        }
                    } else if (SvTYPE(rv) == SVt_PVAV) {
                        if (av_len((AV *)rv) >= 0) can_block = 1;
                    }
                }
            }
            dbuf_indent(aTHX_ d, indent);
            dbuf_emit_key(aTHX_ d, ks, klen);
            dbuf_putc(aTHX_ d, ':');
            if (can_block) {
                dbuf_putc(aTHX_ d, '\n');
                SV *rv = SvRV(v);
                if (SvTYPE(rv) == SVt_PVHV) emit_perl_table(aTHX_ d, (HV *)rv, indent + 1);
                else emit_perl_list(aTHX_ d, (AV *)rv, indent + 1);
            } else {
                dbuf_putc(aTHX_ d, ' ');
                emit_perl_value_inline(aTHX_ d, v);
                dbuf_putc(aTHX_ d, '\n');
            }
        }
        return;
    }
    /* Plain HV without sidecar. Iteration order arbitrary. */
    hv_iterinit(hv);
    HE *he;
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        char *ks = HePV(he, klen);
        SV *v = HeVAL(he);
        int can_block = 0;
        if (v && SvROK(v)) {
            SV *rv = SvRV(v);
            blessed_kind bk = classify_blessed(aTHX_ v);
            if (bk == BLE_OTHER || bk == BLE_UNORDERED) {
                if (SvTYPE(rv) == SVt_PVHV) {
                    if (HvUSEDKEYS((HV *)rv)) can_block = 1;
                } else if (SvTYPE(rv) == SVt_PVAV) {
                    if (av_len((AV *)rv) >= 0) can_block = 1;
                }
            }
        }
        dbuf_indent(aTHX_ d, indent);
        dbuf_emit_key(aTHX_ d, ks, klen);
        dbuf_putc(aTHX_ d, ':');
        if (can_block) {
            dbuf_putc(aTHX_ d, '\n');
            SV *rv = SvRV(v);
            if (SvTYPE(rv) == SVt_PVHV) emit_perl_table(aTHX_ d, (HV *)rv, indent + 1);
            else emit_perl_list(aTHX_ d, (AV *)rv, indent + 1);
        } else {
            dbuf_putc(aTHX_ d, ' ');
            emit_perl_value_inline(aTHX_ d, v);
            dbuf_putc(aTHX_ d, '\n');
        }
    }
}

static void emit_perl_list(pTHX_ dbuf *d, AV *av, int indent) {
    SSize_t n = av_len(av) + 1;
    for (SSize_t i = 0; i < n; i++) {
        SV **slot = av_fetch(av, i, 0);
        if (!slot) continue;
        SV *v = *slot;
        int can_block = 0;
        if (v && SvROK(v)) {
            SV *rv = SvRV(v);
            blessed_kind bk = classify_blessed(aTHX_ v);
            if (bk == BLE_OTHER || bk == BLE_UNORDERED) {
                if (SvTYPE(rv) == SVt_PVHV) {
                    HV *sub = (HV *)rv;
                    /* Tie::IxHash check first (cheap mg_find); fall
                     * through to lite-keys sidecar lookup only on
                     * non-tied HVs to avoid triggering FETCH magic. */
                    AV *sub_tied = get_ixhash_tied(aTHX_ sub);
                    if (sub_tied) {
                        SV **sk = av_fetch(sub_tied, 1, 0);
                        if (sk && av_len((AV *)SvRV(*sk)) >= 0)
                            can_block = 1;
                    } else {
                        AV *sub_lite_keys = get_lite_keys(aTHX_ sub);
                        if (sub_lite_keys) {
                            if (av_len(sub_lite_keys) >= 0) can_block = 1;
                        } else if (HvUSEDKEYS(sub)) {
                            can_block = 1;
                        }
                    }
                } else if (SvTYPE(rv) == SVt_PVAV) {
                    if (av_len((AV *)rv) >= 0) can_block = 1;
                }
            }
        }
        dbuf_indent(aTHX_ d, indent);
        dbuf_putc(aTHX_ d, '+');
        if (can_block) {
            dbuf_putc(aTHX_ d, '\n');
            SV *rv = SvRV(v);
            if (SvTYPE(rv) == SVt_PVHV) emit_perl_table(aTHX_ d, (HV *)rv, indent + 1);
            else emit_perl_list(aTHX_ d, (AV *)rv, indent + 1);
        } else {
            dbuf_putc(aTHX_ d, ' ');
            emit_perl_value_inline(aTHX_ d, v);
            dbuf_putc(aTHX_ d, '\n');
        }
    }
}

/* Top-level entry: emit a Document hashref { meta, body } as DMS source.
 * For lite-mode benches the input is what parse_document_lite returns. */
static SV *to_dms_lite_perl_xs(pTHX_ SV *doc_rv) {
    if (!SvROK(doc_rv) || SvTYPE(SvRV(doc_rv)) != SVt_PVHV) {
        croak("to_dms_lite_xs: expected Document hashref");
    }
    HV *doc = (HV *)SvRV(doc_rv);

    dbuf d;
    dbuf_init(aTHX_ &d, 64 * 1024);

    /* Meta (front matter) — emit `+++ ... +++` block when present. Skip
     * floating FM comments in lite mode. */
    SV **meta_slot = hv_fetch(doc, "meta", 4, 0);
    if (meta_slot && *meta_slot && SvOK(*meta_slot)) {
        SV *meta_sv = *meta_slot;
        if (SvROK(meta_sv) && SvTYPE(SvRV(meta_sv)) == SVt_PVHV) {
            HV *meta_hv = (HV *)SvRV(meta_sv);
            int has_keys = 0;
            /* Tie::IxHash check first to avoid FETCH-magic dispatch on
             * full-mode docs. Sidecar lookup only on non-tied HVs. */
            AV *meta_tied = get_ixhash_tied(aTHX_ meta_hv);
            if (meta_tied) {
                SV **kp = av_fetch(meta_tied, 1, 0);
                if (kp && av_len((AV *)SvRV(*kp)) >= 0) has_keys = 1;
            } else {
                AV *meta_lite_keys = get_lite_keys(aTHX_ meta_hv);
                if (meta_lite_keys) {
                    if (av_len(meta_lite_keys) >= 0) has_keys = 1;
                } else if (HvUSEDKEYS(meta_hv)) {
                    has_keys = 1;
                }
            }
            if (has_keys) {
                dbuf_puts(aTHX_ &d, "+++\n", 4);
                emit_perl_table(aTHX_ &d, meta_hv, 0);
                dbuf_puts(aTHX_ &d, "+++\n", 4);
            }
        }
    }

    SV **body_slot = hv_fetch(doc, "body", 4, 0);
    if (body_slot && *body_slot) {
        SV *body = *body_slot;
        if (SvROK(body)) {
            SV *body_rv = SvRV(body);
            if (SvTYPE(body_rv) == SVt_PVHV) {
                emit_perl_table(aTHX_ &d, (HV *)body_rv, 0);
            } else if (SvTYPE(body_rv) == SVt_PVAV) {
                emit_perl_list(aTHX_ &d, (AV *)body_rv, 0);
            } else {
                emit_perl_value_inline(aTHX_ &d, body);
                dbuf_putc(aTHX_ &d, '\n');
            }
        } else if (SvOK(body)) {
            emit_perl_value_inline(aTHX_ &d, body);
            dbuf_putc(aTHX_ &d, '\n');
        }
    }

    SV *out = newSVpvn(d.buf, d.len);
    SvUTF8_on(out);
    dbuf_free(aTHX_ &d);
    return out;
}


/* --- XS entry points --------------------------------------------------- */

MODULE = DMS::Parser::XS   PACKAGE = DMS::Parser::XS

PROTOTYPES: DISABLE

SV *
parse_document(src_sv)
    SV *src_sv
CODE:
    STRLEN src_len;
    const char *src = SvPV(src_sv, src_len);

    dms_error err;
    dms_document *doc = dms_parse_document(src, src_len, &err);

    if (!doc) {
        croak("%d:%d: %s\n", err.line, err.column, err.message);
    }

    /* Build { meta, body, comments } hashref. */
    HV *out = newHV();

    /* meta: undef when no front matter. */
    if (doc->meta) {
        dms_value mv;
        mv.type = DMS_TABLE;
        mv.u.t = *doc->meta;
        SV *mv_sv = value_to_sv(aTHX_ &mv);
        hv_store(out, "meta", 4, mv_sv, 0);
    } else {
        hv_store(out, "meta", 4, newSV(0), 0);
    }

    hv_store(out, "body", 4, value_to_sv(aTHX_ doc->body), 0);
    hv_store(out, "comments", 8,
             comments_to_sv(aTHX_ doc->comments, doc->num_comments), 0);
    /* original_forms: per-path source-lexeme records the Emitter consults
     * during full-mode `to_dms` to preserve integer base (0xFF stays
     * 0xFF, not 255), string quote style (basic vs literal vs heredoc),
     * heredoc label + modifier chain. Empty in lite mode. Without this
     * key the Emitter falls back to canonical form for every literal —
     * which matched lite-mode behaviour and is what `--mode full`
     * regressed to before this fix. */
    hv_store(out, "original_forms", 14,
             original_forms_to_sv(aTHX_ doc->original_forms,
                                       doc->num_original_forms), 0);

    dms_document_free(doc);

    RETVAL = newRV_noinc((SV *)out);
OUTPUT:
    RETVAL

SV *
parse_to_json_bytes(src_sv)
    SV *src_sv
CODE:
    /* Parse + serialize-to-canonical-JSON in C, end-to-end. Skips the
       SV/HV/AV/Tie::IxHash marshaling of parse_document entirely; for
       wide flat documents that's the dominant cost. Returns a Perl
       UTF-8 string suitable to print straight to stdout. */
    STRLEN src_len;
    const char *src = SvPV(src_sv, src_len);

    dms_error err;
    dms_document *doc = dms_parse_document_lite(src, src_len, &err);
    if (!doc) {
        croak("%d:%d: %s\n", err.line, err.column, err.message);
    }

    jbuf j; j.buf = NULL; j.len = 0; j.cap = 0;
    /* Pre-size: JSON is roughly 5-8x the source for tagged scalars on
       wide flat docs. Reserve to avoid early reallocs. */
    jbuf_grow(&j, src_len * 6 + 1024);
    emit_document(&j, doc);

    dms_document_free(doc);

    SV *out = newSVpvn(j.buf, j.len);
    SvUTF8_on(out);
    libc_free(j.buf);

    RETVAL = out;
OUTPUT:
    RETVAL

void
encode_stdin_to_stdout()
CODE:
    /* End-to-end fast path: read STDIN in C, parse, emit tagged JSON, write
       to STDOUT in C. Eliminates the two SV<->C buffer copies that the
       parse_to_json_bytes path still pays (input slurp into a Perl SV, then
       the result SV that the Perl caller `print`s). The conformance-encoder
       driver becomes a one-liner.

       On Windows we bypass PerlIO entirely and go straight to the OS via
       GetStdHandle + ReadFile/WriteFile. PerlIO_read has a small internal
       buffer (~4 KB) that costs measurable time on a 700 KB slurp;
       PerlIO_write fragments the 1.6 MB output across many buffered
       writes. The OS-level path matches what dms-encoder.exe does and
       closes the gap to the native baseline. Caller must `binmode STDIN`
       and `binmode STDOUT, ":raw"` first so that Perl doesn't introduce
       CRLF translation we'd be skipping past. */
    {
#if defined(WIN32) || defined(_WIN32)
        HANDLE hin  = GetStdHandle(STD_INPUT_HANDLE);
        HANDLE hout = GetStdHandle(STD_OUTPUT_HANDLE);
#endif

        /* Slurp stdin via a growable libc buffer. Sized to absorb typical
           conformance docs in one read; doubles on overflow. */
        size_t in_cap = 65536;
        size_t in_len = 0;
        char  *in_buf = (char *)libc_realloc(NULL, in_cap);
        if (!in_buf) croak("out of memory reading stdin");
        for (;;) {
            if (in_len == in_cap) {
                in_cap *= 2;
                in_buf = (char *)libc_realloc(in_buf, in_cap);
                if (!in_buf) croak("out of memory reading stdin");
            }
#if defined(WIN32) || defined(_WIN32)
            DWORD got = 0;
            BOOL ok = ReadFile(hin, in_buf + in_len, (DWORD)(in_cap - in_len),
                               &got, NULL);
            if (!ok || got == 0) break;
            in_len += (size_t)got;
#else
            ssize_t got = read(0, in_buf + in_len, in_cap - in_len);
            if (got <= 0) break;
            in_len += (size_t)got;
#endif
        }

        dms_error err;
        dms_document *doc = dms_parse_document_lite(in_buf, in_len, &err);
        if (!doc) {
            libc_free(in_buf);
            croak("%d:%d: %s\n", err.line, err.column, err.message);
        }

        jbuf j; j.buf = NULL; j.len = 0; j.cap = 0;
        jbuf_grow(&j, in_len * 6 + 1024);
        emit_document(&j, doc);

        dms_document_free(doc);
        libc_free(in_buf);

        /* Bulk write straight to the OS handle. */
        size_t wrote = 0;
        while (wrote < j.len) {
#if defined(WIN32) || defined(_WIN32)
            DWORD n = 0;
            BOOL ok = WriteFile(hout, j.buf + wrote, (DWORD)(j.len - wrote),
                                &n, NULL);
            if (!ok || n == 0) {
                libc_free(j.buf);
                croak("write to stdout failed");
            }
            wrote += n;
#else
            ssize_t n = write(1, j.buf + wrote, j.len - wrote);
            if (n <= 0) { libc_free(j.buf); croak("write to stdout failed"); }
            wrote += (size_t)n;
#endif
        }
        libc_free(j.buf);
    }

SV *
parse_document_lite(src_sv)
    SV *src_sv
CODE:
    /* Lite-mode parse: same data tree as parse_document, but with two
     * shape changes that drop tree-construction cost:
     *   - Tables are plain HVs with a sidecar `__dms_keys` AV at key
     *     "\0__dms_keys" instead of Tie::IxHash. Saves ~6 SVs/table.
     *   - Comment AST and original_forms are skipped (lite contract).
     * SPEC §Parsing modes — full and lite. */
    STRLEN src_len;
    const char *src = SvPV(src_sv, src_len);

    dms_error err;
    dms_document *doc = dms_parse_document_lite(src, src_len, &err);

    if (!doc) {
        croak("%d:%d: %s\n", err.line, err.column, err.message);
    }

    HV *out = newHV();
    if (doc->meta) {
        dms_value mv;
        mv.type = DMS_TABLE;
        mv.u.t = *doc->meta;
        hv_store(out, "meta", 4, value_to_sv_lite(aTHX_ &mv), 0);
    } else {
        hv_store(out, "meta", 4, newSV(0), 0);
    }
    hv_store(out, "body", 4, value_to_sv_lite(aTHX_ doc->body), 0);
    hv_store(out, "comments", 8, newRV_noinc((SV *)newAV()), 0);

    dms_document_free(doc);

    RETVAL = newRV_noinc((SV *)out);
OUTPUT:
    RETVAL


SV *
decode_t1_to_json(src_sv)
    SV *src_sv
CODE:
    /* Tier-1 parse via the C FFI: dms_decode_t1 + dms_t1_doc_to_json.
     * Returns the JSON string representation of the tier-1 document.
     * Use SvPVutf8 so Perl encodes any wide-char (Unicode) string to
     * UTF-8 bytes before handing it to the C parser. */
    STRLEN src_len;
    const char *src = SvPVutf8(src_sv, src_len);
    dms_t1_doc *doc = dms_decode_t1(src, src_len);
    if (!doc) {
        croak("%lu:%lu: %s",
              (unsigned long)dms_t1_last_error_line(),
              (unsigned long)dms_t1_last_error_col(),
              dms_t1_last_error_message());
    }
    char *json = dms_t1_doc_to_json(doc);
    dms_t1_doc_free(doc);
    if (!json) croak("dms_t1_doc_to_json: out of memory");
    SV *out = newSVpv(json, 0);
    SvUTF8_on(out);
    dms_t1_free_string(json);
    RETVAL = out;
OUTPUT:
    RETVAL

SV *
to_dms_lite_xs(doc_rv)
    SV *doc_rv
CODE:
    /* C-side to_dms_lite — walks the Perl Document tree (the shape
     * parse_document_lite returns) and emits canonical DMS source
     * directly into a Perl SV. Skips the per-kvpair Perl-VM trips of
     * the pure-Perl Emitter. Lite-mode only — no comment AST, no
     * original_forms preservation. SPEC §to_dms (canonical-form
     * subset). */
    RETVAL = to_dms_lite_perl_xs(aTHX_ doc_rv);
OUTPUT:
    RETVAL
