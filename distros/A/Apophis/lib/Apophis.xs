/*
 * Apophis.xs - Content-addressable storage with deterministic UUID v5
 *
 * Named after Apophis, the Egyptian serpent of chaos — here tamed
 * to bring order to content through deterministic hashing.
 *
 * 100% XS: all logic in C, Perl layer is just XSLoader.
 * Uses Horus library for RFC 9562 UUID v5 (SHA-1 namespace) generation.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../ppport.h"

#include <sys/stat.h>
#include <errno.h>
#ifndef _WIN32
#  include <unistd.h>
#else
#  include <io.h>
#  include <direct.h>
#endif

/*
 * Windows compatibility:
 * perl.h on threaded Windows redefines mkdir, stat, unlink etc. as macros
 * requiring the interpreter context (my_perl).  Our static C helper functions
 * don't have pTHX, so we undo those overrides and use the real libc calls.
 */
#ifdef WIN32
#  undef mkdir
#  undef stat
#  undef unlink
#  undef rename
#  undef open
#  undef close
#  undef read
#  undef write
   /* Windows mkdir takes only one arg */
#  define apophis_mkdir(p, m) _mkdir(p)
#else
#  define apophis_mkdir(p, m) mkdir(p, m)
#endif

/* Portable stat type — Stat_t handles struct w32_stat on Windows */
#define apophis_stat_t Stat_t

/* Horus UUID library - pure C, no Perl deps */
#define HORUS_FATAL(msg) croak("%s", (msg))
#include "horus_core.h"

/* ------------------------------------------------------------------ */
/* Constants                                                           */
/* ------------------------------------------------------------------ */

#define APOPHIS_STREAM_BUF  65536   /* 64KB read chunks for streaming */
#define APOPHIS_PATH_MAX    4096

/* ------------------------------------------------------------------ */
/* Internal: namespace UUID generation                                 */
/* ------------------------------------------------------------------ */

/* Derive a namespace UUID from a human-readable string via v5(DNS, name) */
static void
apophis_derive_namespace(unsigned char *ns_out,
                         const char *name, STRLEN name_len)
{
    horus_uuid_v5(ns_out, HORUS_NS_DNS,
                  (const unsigned char *)name, (size_t)name_len);
}

/* Format 16-byte UUID binary to 36-char string SV */
static SV *
apophis_uuid_to_sv(pTHX_ const unsigned char *uuid)
{
    char buf[HORUS_FMT_STR_LEN + 1];
    horus_format_uuid(buf, uuid, HORUS_FMT_STR);
    return newSVpvn(buf, HORUS_FMT_STR_LEN);
}

/* ------------------------------------------------------------------ */
/* Internal: content identification                                    */
/* ------------------------------------------------------------------ */

/* Identify in-memory content: v5(namespace, content) */
static void
apophis_identify_content(unsigned char *uuid_out,
                         const unsigned char *ns_bytes,
                         const char *content, STRLEN content_len)
{
    horus_uuid_v5(uuid_out, ns_bytes,
                  (const unsigned char *)content, (size_t)content_len);
}

/* Identify via streaming SHA-1 — O(1) memory */
static void
apophis_identify_stream(pTHX_ unsigned char *uuid_out,
                        const unsigned char *ns_bytes,
                        PerlIO *fh)
{
    horus_sha1_ctx ctx;
    unsigned char buf[APOPHIS_STREAM_BUF];
    unsigned char digest[20];
    SSize_t nread;

    horus_sha1_init(&ctx);
    horus_sha1_update(&ctx, ns_bytes, 16);  /* namespace first per RFC */

    while ((nread = PerlIO_read(fh, buf, sizeof(buf))) > 0) {
        horus_sha1_update(&ctx, (const unsigned char *)buf, (size_t)nread);
    }

    horus_sha1_final(digest, &ctx);
    memcpy(uuid_out, digest, 16);
    horus_stamp_version_variant(uuid_out, 5);
}

/* ------------------------------------------------------------------ */
/* Internal: path computation                                          */
/* ------------------------------------------------------------------ */

/* Build 2-level sharded path: store_dir/a3/bb/a3bb189e-...-1e3a
 * Returns length written (excluding NUL). */
static int
apophis_build_path(char *out, size_t out_size,
                   const char *store_dir, STRLEN store_len,
                   const char *id, STRLEN id_len)
{
    /* UUID is 36 chars: a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a
     * Shard on first 2 and chars 3-4 (skipping no hyphens needed,
     * first 4 hex chars are positions 0-3 of the UUID string) */
    if (id_len < 5)
        croak("Apophis: invalid UUID id");

    return snprintf(out, out_size, "%.*s/%c%c/%c%c/%.*s",
                    (int)store_len, store_dir,
                    id[0], id[1],    /* first shard level */
                    id[2], id[3],    /* second shard level */
                    (int)id_len, id);
}

/* Build path for .meta sidecar */
static int
apophis_build_meta_path(char *out, size_t out_size,
                        const char *content_path, int content_path_len)
{
    return snprintf(out, out_size, "%.*s.meta",
                    content_path_len, content_path);
}

/* ------------------------------------------------------------------ */
/* Internal: recursive mkdir                                           */
/* ------------------------------------------------------------------ */

static void
apophis_mkdir_p(const char *path)
{
    char buf[APOPHIS_PATH_MAX];
    char *p;
    size_t len;

    len = strlen(path);
    if (len >= sizeof(buf))
        croak("Apophis: path too long");

    memcpy(buf, path, len + 1);

    for (p = buf + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            if (apophis_mkdir(buf, 0777) != 0 && errno != EEXIST) {
                croak("Apophis: cannot create directory '%s': %s",
                      buf, strerror(errno));
            }
            *p = '/';
        }
    }
    /* Final component */
    if (apophis_mkdir(buf, 0777) != 0 && errno != EEXIST) {
        croak("Apophis: cannot create directory '%s': %s",
              buf, strerror(errno));
    }
}

/* Ensure parent directory of a file path exists */
static void
apophis_ensure_parent_dir(const char *file_path)
{
    char buf[APOPHIS_PATH_MAX];
    char *last_slash;
    size_t len;

    len = strlen(file_path);
    if (len >= sizeof(buf))
        croak("Apophis: path too long");

    memcpy(buf, file_path, len + 1);
    last_slash = strrchr(buf, '/');
    if (last_slash) {
        *last_slash = '\0';
        apophis_mkdir_p(buf);
    }
}

/* ------------------------------------------------------------------ */
/* Internal: atomic file write (temp + rename)                         */
/* ------------------------------------------------------------------ */

static void
apophis_atomic_write(pTHX_ const char *path,
                     const char *content, STRLEN content_len)
{
    char tmp_path[APOPHIS_PATH_MAX];
    PerlIO *fh;
    SSize_t written;

    snprintf(tmp_path, sizeof(tmp_path), "%s.tmp.%d",
             path, (int)getpid());

    fh = PerlIO_open(tmp_path, "wb");
    if (!fh)
        croak("Apophis: cannot write '%s': %s", tmp_path, strerror(errno));

    written = PerlIO_write(fh, content, content_len);
    PerlIO_close(fh);

    if (written != (SSize_t)content_len) {
        unlink(tmp_path);
        croak("Apophis: short write to '%s'", tmp_path);
    }

    if (rename(tmp_path, path) != 0) {
        unlink(tmp_path);
        croak("Apophis: cannot rename '%s' -> '%s': %s",
              tmp_path, path, strerror(errno));
    }
}

/* ------------------------------------------------------------------ */
/* Internal: metadata sidecar (key=value\n format)                     */
/* ------------------------------------------------------------------ */

static void
apophis_meta_write(pTHX_ const char *meta_path, HV *meta)
{
    PerlIO *fh;
    HE *entry;
    char tmp_path[APOPHIS_PATH_MAX];

    snprintf(tmp_path, sizeof(tmp_path), "%s.tmp.%d",
             meta_path, (int)getpid());

    fh = PerlIO_open(tmp_path, "w");
    if (!fh)
        croak("Apophis: cannot write metadata '%s': %s",
              tmp_path, strerror(errno));

    hv_iterinit(meta);
    while ((entry = hv_iternext(meta))) {
        SV *val = hv_iterval(meta, entry);
        I32 klen;
        const char *key = hv_iterkey(entry, &klen);
        STRLEN vlen;
        const char *vstr = SvPV(val, vlen);
        PerlIO_write(fh, key, (SSize_t)klen);
        PerlIO_write(fh, "=", 1);
        PerlIO_write(fh, vstr, (SSize_t)vlen);
        PerlIO_write(fh, "\n", 1);
    }

    PerlIO_close(fh);

    if (rename(tmp_path, meta_path) != 0) {
        unlink(tmp_path);
        croak("Apophis: cannot rename metadata '%s': %s",
              tmp_path, strerror(errno));
    }
}

static HV *
apophis_meta_read(pTHX_ const char *meta_path)
{
    PerlIO *fh;
    HV *meta;
    apophis_stat_t st;
    char *buf, *p, *end;
    SSize_t nread;

    if (stat(meta_path, &st) != 0) return NULL;

    fh = PerlIO_open(meta_path, "r");
    if (!fh) return NULL;

    buf = (char *)malloc((size_t)st.st_size + 1);
    if (!buf) { PerlIO_close(fh); return NULL; }

    nread = PerlIO_read(fh, buf, (Size_t)st.st_size);
    PerlIO_close(fh);

    if (nread < 0) { free(buf); return NULL; }
    buf[nread] = '\0';

    meta = newHV();
    p = buf;
    end = buf + nread;

    while (p < end) {
        char *line_end = strchr(p, '\n');
        char *eq;
        if (!line_end) line_end = end;

        eq = (char *)memchr(p, '=', (size_t)(line_end - p));
        if (eq) {
            hv_store(meta, p, (I32)(eq - p),
                     newSVpvn(eq + 1, (STRLEN)(line_end - eq - 1)), 0);
        }

        p = line_end + 1;
    }

    free(buf);
    return meta;
}

/* ------------------------------------------------------------------ */
/* Internal: object field accessors                                    */
/* ------------------------------------------------------------------ */

/* Get the 16-byte namespace bytes from the object */
static const unsigned char *
apophis_get_ns(pTHX_ HV *self)
{
    SV **svp = hv_fetchs(self, "_ns_bytes", 0);
    if (!svp || !SvOK(*svp))
        croak("Apophis: object has no namespace (not properly constructed)");
    return (const unsigned char *)SvPV_nolen(*svp);
}

/* Get store_dir from object, or from opts, or croak */
static const char *
apophis_get_store_dir(pTHX_ HV *self, HV *opts, STRLEN *len_out)
{
    SV **svp;

    /* Check opts first */
    if (opts) {
        svp = hv_fetchs(opts, "store_dir", 0);
        if (svp && SvOK(*svp))
            return SvPV(*svp, *len_out);
    }

    /* Fall back to object */
    svp = hv_fetchs(self, "store_dir", 0);
    if (svp && SvOK(*svp))
        return SvPV(*svp, *len_out);

    croak("Apophis: no store_dir specified");
    return NULL; /* not reached */
}


/* ================================================================== */
/* Custom Ops - bypass method dispatch for hot-path operations         */
/* ================================================================== */

/* Forward declarations */
static OP *pp_apophis_identify(pTHX);
static OP *pp_apophis_store(pTHX);
static OP *pp_apophis_exists(pTHX);
static OP *pp_apophis_fetch(pTHX);
static OP *pp_apophis_verify(pTHX);
static OP *pp_apophis_remove(pTHX);

/* XOP structs for debug names (5.14+ only) */
#if PERL_VERSION >= 14
static XOP apophis_xop_identify;
static XOP apophis_xop_store;
static XOP apophis_xop_exists;
static XOP apophis_xop_fetch;
static XOP apophis_xop_verify;
static XOP apophis_xop_remove;
#endif

/*
 * pp_apophis_identify - Custom op: content → UUID v5 string
 *
 * Stack input:  self_sv, content_ref_sv
 * Stack output: uuid_string_sv
 *
 * Fuses: namespace extraction + SHA-1 + v5 stamp + format
 * Zero intermediate SVs, no method dispatch overhead.
 */
static OP *
pp_apophis_identify(pTHX) {
    dSP;
    SV *content_ref_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const unsigned char *ns;
    SV *content_sv;
    const char *content;
    STRLEN content_len;
    unsigned char uuid[16];

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_identify: not an object");
    hv = (HV *)SvRV(self_sv);
    ns = apophis_get_ns(aTHX_ hv);

    if (!SvROK(content_ref_sv))
        croak("Apophis: pp_identify: argument must be a scalar reference");
    content_sv = SvRV(content_ref_sv);
    content = SvPV(content_sv, content_len);

    apophis_identify_content(uuid, ns, content, content_len);

    EXTEND(SP, 1);
    PUSHs(sv_2mortal(apophis_uuid_to_sv(aTHX_ uuid)));
    PUTBACK;
    return NORMAL;
}

/*
 * pp_apophis_store - Custom op: fused identify + mkdir + atomic write
 *
 * Stack input:  self_sv, content_ref_sv
 * Stack output: uuid_string_sv
 *
 * Fuses the entire store pipeline into a single op:
 *   1. Extract namespace bytes from object
 *   2. SHA-1 hash content → UUID v5
 *   3. Compute 2-level sharded path
 *   4. stat() for CAS dedup check
 *   5. mkdir -p parent directories
 *   6. Atomic write (temp + rename)
 *   7. Format and return UUID string
 */
static OP *
pp_apophis_store(pTHX) {
    dSP;
    SV *content_ref_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const unsigned char *ns;
    SV *content_sv;
    const char *content;
    STRLEN content_len;
    unsigned char uuid[16];
    char id_str[HORUS_FMT_STR_LEN + 1];
    const char *store_dir;
    STRLEN store_dir_len;
    char path[APOPHIS_PATH_MAX];
    apophis_stat_t st;

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_store: not an object");
    hv = (HV *)SvRV(self_sv);
    ns = apophis_get_ns(aTHX_ hv);

    if (!SvROK(content_ref_sv))
        croak("Apophis: pp_store: argument must be a scalar reference");
    content_sv = SvRV(content_ref_sv);
    content = SvPV(content_sv, content_len);

    /* Identify */
    apophis_identify_content(uuid, ns, content, content_len);
    horus_format_uuid(id_str, uuid, HORUS_FMT_STR);

    /* Get store_dir from object */
    store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);

    /* Build sharded path */
    apophis_build_path(path, sizeof(path),
                       store_dir, store_dir_len,
                       id_str, HORUS_FMT_STR_LEN);

    /* CAS dedup: only write if not already stored */
    if (stat(path, &st) != 0) {
        apophis_ensure_parent_dir(path);
        apophis_atomic_write(aTHX_ path, content, content_len);
    }

    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn(id_str, HORUS_FMT_STR_LEN)));
    PUTBACK;
    return NORMAL;
}

/*
 * pp_apophis_exists - Custom op: UUID → boolean existence check
 *
 * Stack input:  self_sv, id_sv
 * Stack output: bool_sv
 *
 * Fuses: path computation + stat() into a single op.
 */
static OP *
pp_apophis_exists(pTHX) {
    dSP;
    SV *id_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const char *store_dir;
    STRLEN store_dir_len;
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    apophis_stat_t st;

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_exists: not an object");
    hv = (HV *)SvRV(self_sv);

    store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
    id_str = SvPV(id_sv, id_len);

    apophis_build_path(path, sizeof(path),
                       store_dir, store_dir_len, id_str, id_len);

    EXTEND(SP, 1);
    PUSHs(stat(path, &st) == 0 ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/*
 * pp_apophis_fetch - Custom op: UUID → content scalar ref or undef
 *
 * Stack input:  self_sv, id_sv
 * Stack output: \$content or undef
 *
 * Fuses: path computation + stat + open + read into a single op.
 */
static OP *
pp_apophis_fetch(pTHX) {
    dSP;
    SV *id_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const char *store_dir;
    STRLEN store_dir_len;
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    apophis_stat_t st;

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_fetch: not an object");
    hv = (HV *)SvRV(self_sv);

    store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
    id_str = SvPV(id_sv, id_len);

    apophis_build_path(path, sizeof(path),
                       store_dir, store_dir_len, id_str, id_len);

    EXTEND(SP, 1);
    if (stat(path, &st) != 0) {
        PUSHs(&PL_sv_undef);
    } else {
        PerlIO *fh = PerlIO_open(path, "rb");
        if (!fh)
            croak("Apophis: pp_fetch: cannot open '%s': %s",
                  path, strerror(errno));

        SV *content = newSV((STRLEN)st.st_size + 1);
        SvPOK_on(content);
        SSize_t nread = PerlIO_read(fh, SvPVX(content), (Size_t)st.st_size);
        PerlIO_close(fh);

        if (nread < 0) {
            SvREFCNT_dec(content);
            croak("Apophis: pp_fetch: read error on '%s'", path);
        }
        SvCUR_set(content, (STRLEN)nread);
        *SvEND(content) = '\0';

        PUSHs(sv_2mortal(newRV_noinc(content)));
    }
    PUTBACK;
    return NORMAL;
}

/*
 * pp_apophis_verify - Custom op: fused re-read + re-hash + compare
 *
 * Stack input:  self_sv, id_sv
 * Stack output: bool_sv
 *
 * Fuses: path computation + open + streaming SHA-1 + format + memcmp.
 */
static OP *
pp_apophis_verify(pTHX) {
    dSP;
    SV *id_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const unsigned char *ns;
    const char *store_dir;
    STRLEN store_dir_len;
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    PerlIO *fh;
    unsigned char uuid[16];
    char recomputed[HORUS_FMT_STR_LEN + 1];

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_verify: not an object");
    hv = (HV *)SvRV(self_sv);
    ns = apophis_get_ns(aTHX_ hv);

    store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
    id_str = SvPV(id_sv, id_len);

    apophis_build_path(path, sizeof(path),
                       store_dir, store_dir_len, id_str, id_len);

    EXTEND(SP, 1);
    fh = PerlIO_open(path, "rb");
    if (!fh) {
        PUSHs(&PL_sv_no);
    } else {
        apophis_identify_stream(aTHX_ uuid, ns, fh);
        PerlIO_close(fh);

        horus_format_uuid(recomputed, uuid, HORUS_FMT_STR);
        PUSHs((id_len == HORUS_FMT_STR_LEN &&
               memcmp(id_str, recomputed, HORUS_FMT_STR_LEN) == 0)
              ? &PL_sv_yes : &PL_sv_no);
    }
    PUTBACK;
    return NORMAL;
}

/*
 * pp_apophis_remove - Custom op: fused path + unlink + meta cleanup
 *
 * Stack input:  self_sv, id_sv
 * Stack output: bool_sv
 *
 * Fuses: path computation + unlink + meta sidecar cleanup.
 */
static OP *
pp_apophis_remove(pTHX) {
    dSP;
    SV *id_sv = POPs;
    SV *self_sv = POPs;
    HV *hv;
    const char *store_dir;
    STRLEN store_dir_len;
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    int path_len;
    char meta_path[APOPHIS_PATH_MAX];
    int removed;

    if (!sv_isobject(self_sv))
        croak("Apophis: pp_remove: not an object");
    hv = (HV *)SvRV(self_sv);

    store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
    id_str = SvPV(id_sv, id_len);

    path_len = apophis_build_path(path, sizeof(path),
                                   store_dir, store_dir_len,
                                   id_str, id_len);

    removed = (unlink(path) == 0);

    apophis_build_meta_path(meta_path, sizeof(meta_path),
                            path, path_len);
    unlink(meta_path);  /* ignore error — may not exist */

    EXTEND(SP, 1);
    PUSHs(removed ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/*
 * apophis_make_custom_op - Create a custom OP node
 *
 * Used by the optimize/import system to inject custom ops into optrees.
 */
static OP *
apophis_make_custom_op(pTHX_ OP *(*pp_func)(pTHX))
{
    OP *op;
    NewOp(1101, op, 1, OP);
    op->op_type = OP_CUSTOM;
    op->op_ppaddr = pp_func;
    op->op_next = op;  /* will be linked by caller */
    op->op_flags = OPf_WANT_SCALAR;
    return op;
}


/* ================================================================== */
/* XSUBs                                                               */
/* ================================================================== */

MODULE = Apophis  PACKAGE = Apophis

BOOT:
#if PERL_VERSION >= 14
    /* Register custom ops with debug names */
    XopENTRY_set(&apophis_xop_identify, xop_name, "apophis_identify");
    XopENTRY_set(&apophis_xop_identify, xop_desc, "Apophis content identification (SHA-1 → UUID v5)");
    XopENTRY_set(&apophis_xop_identify, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_identify, &apophis_xop_identify);

    XopENTRY_set(&apophis_xop_store, xop_name, "apophis_store");
    XopENTRY_set(&apophis_xop_store, xop_desc, "Apophis fused store (identify + mkdir + atomic write)");
    XopENTRY_set(&apophis_xop_store, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_store, &apophis_xop_store);

    XopENTRY_set(&apophis_xop_exists, xop_name, "apophis_exists");
    XopENTRY_set(&apophis_xop_exists, xop_desc, "Apophis fused existence check (path + stat)");
    XopENTRY_set(&apophis_xop_exists, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_exists, &apophis_xop_exists);

    XopENTRY_set(&apophis_xop_fetch, xop_name, "apophis_fetch");
    XopENTRY_set(&apophis_xop_fetch, xop_desc, "Apophis fused fetch (path + stat + read)");
    XopENTRY_set(&apophis_xop_fetch, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_fetch, &apophis_xop_fetch);

    XopENTRY_set(&apophis_xop_verify, xop_name, "apophis_verify");
    XopENTRY_set(&apophis_xop_verify, xop_desc, "Apophis fused verify (read + re-hash + compare)");
    XopENTRY_set(&apophis_xop_verify, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_verify, &apophis_xop_verify);

    XopENTRY_set(&apophis_xop_remove, xop_name, "apophis_remove");
    XopENTRY_set(&apophis_xop_remove, xop_desc, "Apophis fused remove (path + unlink + meta cleanup)");
    XopENTRY_set(&apophis_xop_remove, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_apophis_remove, &apophis_xop_remove);
#endif

# ------------------------------------------------------------------ #
# new(class, %args) -> blessed object                                  #
# ------------------------------------------------------------------ #

SV *
new(class, ...)
        const char *class
    PREINIT:
        HV *self;
        SV *self_ref;
        int i;
        const char *namespace_str = NULL;
        STRLEN namespace_len = 0;
        const char *store_dir = NULL;
        STRLEN store_dir_len = 0;
        unsigned char ns_bytes[16];
    CODE:
        if ((items - 1) % 2 != 0)
            croak("Apophis->new: odd number of arguments");

        /* Parse args */
        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "namespace")) {
                namespace_str = SvPV(ST(i+1), namespace_len);
            } else if (strEQ(key, "store_dir")) {
                store_dir = SvPV(ST(i+1), store_dir_len);
            }
        }

        if (!namespace_str)
            croak("Apophis->new: 'namespace' is required");

        /* Derive namespace UUID */
        apophis_derive_namespace(ns_bytes, namespace_str, namespace_len);

        /* Build object */
        self = newHV();
        hv_stores(self, "_ns_bytes", newSVpvn((const char *)ns_bytes, 16));
        hv_stores(self, "_ns_str", apophis_uuid_to_sv(aTHX_ ns_bytes));

        if (store_dir)
            hv_stores(self, "store_dir", newSVpvn(store_dir, store_dir_len));

        self_ref = newRV_noinc((SV *)self);
        sv_bless(self_ref, gv_stashpv(class, GV_ADD));
        RETVAL = self_ref;
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# namespace() -> UUID string                                           #
# ------------------------------------------------------------------ #

SV *
namespace(self)
        SV *self
    PREINIT:
        HV *hv;
        SV **svp;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::namespace: not an object");
        hv = (HV *)SvRV(self);
        svp = hv_fetchs(hv, "_ns_str", 0);
        if (!svp || !SvOK(*svp))
            croak("Apophis: object has no namespace");
        RETVAL = newSVsv(*svp);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# identify(\$content) -> UUID string                                   #
# ------------------------------------------------------------------ #

SV *
identify(self, content_ref)
        SV *self
        SV *content_ref
    PREINIT:
        HV *hv;
        const unsigned char *ns;
        SV *content_sv;
        const char *content;
        STRLEN content_len;
        unsigned char uuid[16];
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::identify: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (!SvROK(content_ref))
            croak("Apophis::identify: argument must be a scalar reference");
        content_sv = SvRV(content_ref);
        content = SvPV(content_sv, content_len);

        apophis_identify_content(uuid, ns, content, content_len);
        RETVAL = apophis_uuid_to_sv(aTHX_ uuid);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# identify_file($path) -> UUID string                                  #
# ------------------------------------------------------------------ #

SV *
identify_file(self, path)
        SV *self
        const char *path
    PREINIT:
        HV *hv;
        const unsigned char *ns;
        unsigned char uuid[16];
        PerlIO *fh;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::identify_file: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        fh = PerlIO_open(path, "rb");
        if (!fh)
            croak("Apophis::identify_file: cannot open '%s': %s",
                  path, strerror(errno));

        apophis_identify_stream(aTHX_ uuid, ns, fh);
        PerlIO_close(fh);

        RETVAL = apophis_uuid_to_sv(aTHX_ uuid);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# path_for($id, %opts) -> path string                                 #
# ------------------------------------------------------------------ #

SV *
path_for(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        int path_len;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::path_for: not an object");
        hv = (HV *)SvRV(self);

        /* Parse optional key-value pairs into opts HV */
        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::path_for: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);

        path_len = apophis_build_path(path, sizeof(path),
                                       store_dir, store_dir_len,
                                       id_str, id_len);
        RETVAL = newSVpvn(path, path_len);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# store(\$content, %opts) -> UUID string                               #
# ------------------------------------------------------------------ #

SV *
store(self, content_ref, ...)
        SV *self
        SV *content_ref
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        HV *meta = NULL;
        const unsigned char *ns;
        SV *content_sv;
        const char *content;
        STRLEN content_len;
        unsigned char uuid[16];
        char id_str[HORUS_FMT_STR_LEN + 1];
        const char *store_dir;
        STRLEN store_dir_len;
        char path[APOPHIS_PATH_MAX];
        int path_len;
        apophis_stat_t st;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::store: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (!SvROK(content_ref))
            croak("Apophis::store: argument must be a scalar reference");
        content_sv = SvRV(content_ref);
        content = SvPV(content_sv, content_len);

        /* Parse opts */
        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::store: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                SV *v = ST(i+1);
                if (strEQ(k, "meta") && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
                    meta = (HV *)SvRV(v);
                } else {
                    hv_store(opts, k, klen, SvREFCNT_inc(v), 0);
                }
            }
        }

        /* Identify content */
        apophis_identify_content(uuid, ns, content, content_len);
        horus_format_uuid(id_str, uuid, HORUS_FMT_STR);

        /* Build path */
        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        path_len = apophis_build_path(path, sizeof(path),
                                       store_dir, store_dir_len,
                                       id_str, HORUS_FMT_STR_LEN);

        /* CAS dedup: skip if already exists */
        if (stat(path, &st) != 0) {
            apophis_ensure_parent_dir(path);
            apophis_atomic_write(aTHX_ path, content, content_len);
        }

        /* Write metadata sidecar if provided */
        if (meta) {
            char meta_path[APOPHIS_PATH_MAX];
            apophis_build_meta_path(meta_path, sizeof(meta_path),
                                    path, path_len);
            apophis_meta_write(aTHX_ meta_path, meta);
        }

        RETVAL = newSVpvn(id_str, HORUS_FMT_STR_LEN);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# fetch($id, %opts) -> \$content or undef                             #
# ------------------------------------------------------------------ #

SV *
fetch(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        PerlIO *fh;
        apophis_stat_t st;
        SV *content;
        SSize_t nread;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::fetch: not an object");
        hv = (HV *)SvRV(self);

        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::fetch: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        /* Check existence */
        if (stat(path, &st) != 0) {
            RETVAL = &PL_sv_undef;
        } else {
            /* Read entire file */
            fh = PerlIO_open(path, "rb");
            if (!fh)
                croak("Apophis::fetch: cannot open '%s': %s",
                      path, strerror(errno));

            content = newSV((STRLEN)st.st_size + 1);
            SvPOK_on(content);
            nread = PerlIO_read(fh, SvPVX(content), (Size_t)st.st_size);
            PerlIO_close(fh);

            if (nread < 0) {
                SvREFCNT_dec(content);
                croak("Apophis::fetch: read error on '%s'", path);
            }
            SvCUR_set(content, (STRLEN)nread);
            *SvEND(content) = '\0';

            RETVAL = newRV_noinc(content);
        }
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# exists($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
exists(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        apophis_stat_t st;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::exists: not an object");
        hv = (HV *)SvRV(self);

        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::exists: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        RETVAL = (stat(path, &st) == 0) ? TRUE : FALSE;
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# remove($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
remove(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        int path_len;
        char meta_path[APOPHIS_PATH_MAX];
        int removed;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::remove: not an object");
        hv = (HV *)SvRV(self);

        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::remove: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);
        path_len = apophis_build_path(path, sizeof(path),
                                       store_dir, store_dir_len,
                                       id_str, id_len);

        removed = (unlink(path) == 0);

        /* Also remove metadata sidecar if it exists */
        apophis_build_meta_path(meta_path, sizeof(meta_path),
                                path, path_len);
        unlink(meta_path);  /* ignore error — may not exist */

        RETVAL = removed ? TRUE : FALSE;
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# verify($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
verify(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const unsigned char *ns;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        PerlIO *fh;
        unsigned char uuid[16];
        char recomputed[HORUS_FMT_STR_LEN + 1];
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::verify: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::verify: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        fh = PerlIO_open(path, "rb");
        if (!fh) {
            RETVAL = FALSE;
        } else {
            apophis_identify_stream(aTHX_ uuid, ns, fh);
            PerlIO_close(fh);

            horus_format_uuid(recomputed, uuid, HORUS_FMT_STR);
            RETVAL = (id_len == HORUS_FMT_STR_LEN &&
                      memcmp(id_str, recomputed, HORUS_FMT_STR_LEN) == 0)
                     ? TRUE : FALSE;
        }
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# store_many(\@refs, %opts) -> @ids                                    #
# ------------------------------------------------------------------ #

void
store_many(self, refs, ...)
        SV *self
        SV *refs
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const unsigned char *ns;
        const char *store_dir;
        STRLEN store_dir_len;
        AV *av;
        I32 len, i;
    PPCODE:
        if (!sv_isobject(self))
            croak("Apophis::store_many: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (!SvROK(refs) || SvTYPE(SvRV(refs)) != SVt_PVAV)
            croak("Apophis::store_many: first argument must be an array ref");
        av = (AV *)SvRV(refs);
        len = av_len(av) + 1;

        if (items > 2) {
            int j;
            if ((items - 2) % 2 != 0)
                croak("Apophis::store_many: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (j = 2; j < items; j += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(j), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(j+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);

        EXTEND(SP, len);
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(av, i, 0);
            SV *content_sv;
            const char *content;
            STRLEN content_len;
            unsigned char uuid[16];
            char id_str[HORUS_FMT_STR_LEN + 1];
            char path[APOPHIS_PATH_MAX];
            apophis_stat_t st;

            if (!svp || !SvROK(*svp))
                croak("Apophis::store_many: element %d must be a scalar ref",
                      (int)i);

            content_sv = SvRV(*svp);
            content = SvPV(content_sv, content_len);

            apophis_identify_content(uuid, ns, content, content_len);
            horus_format_uuid(id_str, uuid, HORUS_FMT_STR);

            apophis_build_path(path, sizeof(path),
                               store_dir, store_dir_len,
                               id_str, HORUS_FMT_STR_LEN);

            if (stat(path, &st) != 0) {
                apophis_ensure_parent_dir(path);
                apophis_atomic_write(aTHX_ path, content, content_len);
            }

            PUSHs(sv_2mortal(newSVpvn(id_str, HORUS_FMT_STR_LEN)));
        }

# ------------------------------------------------------------------ #
# find_missing(\@ids, %opts) -> @missing_ids                           #
# ------------------------------------------------------------------ #

void
find_missing(self, ids, ...)
        SV *self
        SV *ids
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        AV *av;
        I32 len, i;
    PPCODE:
        if (!sv_isobject(self))
            croak("Apophis::find_missing: not an object");
        hv = (HV *)SvRV(self);

        if (!SvROK(ids) || SvTYPE(SvRV(ids)) != SVt_PVAV)
            croak("Apophis::find_missing: first argument must be an array ref");
        av = (AV *)SvRV(ids);
        len = av_len(av) + 1;

        if (items > 2) {
            int j;
            if ((items - 2) % 2 != 0)
                croak("Apophis::find_missing: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (j = 2; j < items; j += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(j), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(j+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);

        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(av, i, 0);
            const char *id_str;
            STRLEN id_len;
            char path[APOPHIS_PATH_MAX];
            apophis_stat_t st;

            if (!svp || !SvOK(*svp)) continue;

            id_str = SvPV(*svp, id_len);
            apophis_build_path(path, sizeof(path),
                               store_dir, store_dir_len, id_str, id_len);

            if (stat(path, &st) != 0) {
                XPUSHs(sv_2mortal(newSVpvn(id_str, id_len)));
            }
        }

# ------------------------------------------------------------------ #
# meta($id, %opts) -> \%meta or undef                                 #
# ------------------------------------------------------------------ #

SV *
meta(self, id, ...)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        HV *opts = NULL;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        int path_len;
        char meta_path[APOPHIS_PATH_MAX];
        HV *meta;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::meta: not an object");
        hv = (HV *)SvRV(self);

        if (items > 2) {
            int i;
            if ((items - 2) % 2 != 0)
                croak("Apophis::meta: odd number of optional arguments");
            opts = newHV();
            sv_2mortal((SV *)opts);
            for (i = 2; i < items; i += 2) {
                STRLEN klen;
                const char *k = SvPV(ST(i), klen);
                hv_store(opts, k, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        }

        store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
        id_str = SvPV(id, id_len);
        path_len = apophis_build_path(path, sizeof(path),
                                       store_dir, store_dir_len,
                                       id_str, id_len);
        apophis_build_meta_path(meta_path, sizeof(meta_path),
                                path, path_len);

        meta = apophis_meta_read(aTHX_ meta_path);
        if (meta) {
            RETVAL = newRV_noinc((SV *)meta);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# Custom op direct invocation XSUBs                                    #
#                                                                      #
# These call the pp_ functions directly, giving the same speedup      #
# as injected custom ops but accessible as regular function calls.     #
# ------------------------------------------------------------------ #

# op_identify($self, \$content) -> UUID string
# Calls pp_apophis_identify directly — no method dispatch.

SV *
op_identify(self, content_ref)
        SV *self
        SV *content_ref
    PREINIT:
        HV *hv;
        const unsigned char *ns;
        SV *content_sv;
        const char *content;
        STRLEN content_len;
        unsigned char uuid[16];
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_identify: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (!SvROK(content_ref))
            croak("Apophis::op_identify: argument must be a scalar reference");
        content_sv = SvRV(content_ref);
        content = SvPV(content_sv, content_len);

        apophis_identify_content(uuid, ns, content, content_len);
        RETVAL = apophis_uuid_to_sv(aTHX_ uuid);
    OUTPUT:
        RETVAL

# op_store($self, \$content) -> UUID string
# Fused identify + mkdir + atomic write — single call, no intermediates.

SV *
op_store(self, content_ref)
        SV *self
        SV *content_ref
    PREINIT:
        HV *hv;
        const unsigned char *ns;
        SV *content_sv;
        const char *content;
        STRLEN content_len;
        unsigned char uuid[16];
        char id_str[HORUS_FMT_STR_LEN + 1];
        const char *store_dir;
        STRLEN store_dir_len;
        char path[APOPHIS_PATH_MAX];
        apophis_stat_t st;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_store: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        if (!SvROK(content_ref))
            croak("Apophis::op_store: argument must be a scalar reference");
        content_sv = SvRV(content_ref);
        content = SvPV(content_sv, content_len);

        apophis_identify_content(uuid, ns, content, content_len);
        horus_format_uuid(id_str, uuid, HORUS_FMT_STR);

        store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len,
                           id_str, HORUS_FMT_STR_LEN);

        if (stat(path, &st) != 0) {
            apophis_ensure_parent_dir(path);
            apophis_atomic_write(aTHX_ path, content, content_len);
        }

        RETVAL = newSVpvn(id_str, HORUS_FMT_STR_LEN);
    OUTPUT:
        RETVAL

# op_exists($self, $id) -> bool
# Fused path computation + stat — single call.

bool
op_exists(self, id)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        apophis_stat_t st;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_exists: not an object");
        hv = (HV *)SvRV(self);

        store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        RETVAL = (stat(path, &st) == 0) ? TRUE : FALSE;
    OUTPUT:
        RETVAL

# op_fetch($self, $id) -> \$content or undef
# Fused path computation + stat + read — single call.

SV *
op_fetch(self, id)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        PerlIO *fh;
        apophis_stat_t st;
        SV *content;
        SSize_t nread;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_fetch: not an object");
        hv = (HV *)SvRV(self);

        store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        if (stat(path, &st) != 0) {
            RETVAL = &PL_sv_undef;
        } else {
            fh = PerlIO_open(path, "rb");
            if (!fh)
                croak("Apophis::op_fetch: cannot open '%s': %s",
                      path, strerror(errno));

            content = newSV((STRLEN)st.st_size + 1);
            SvPOK_on(content);
            nread = PerlIO_read(fh, SvPVX(content), (Size_t)st.st_size);
            PerlIO_close(fh);

            if (nread < 0) {
                SvREFCNT_dec(content);
                croak("Apophis::op_fetch: read error on '%s'", path);
            }
            SvCUR_set(content, (STRLEN)nread);
            *SvEND(content) = '\0';

            RETVAL = newRV_noinc(content);
        }
    OUTPUT:
        RETVAL

# op_verify($self, $id) -> bool
# Fused read + streaming SHA-1 + compare — single call.

bool
op_verify(self, id)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        const unsigned char *ns;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        PerlIO *fh;
        unsigned char uuid[16];
        char recomputed[HORUS_FMT_STR_LEN + 1];
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_verify: not an object");
        hv = (HV *)SvRV(self);
        ns = apophis_get_ns(aTHX_ hv);

        store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
        id_str = SvPV(id, id_len);
        apophis_build_path(path, sizeof(path),
                           store_dir, store_dir_len, id_str, id_len);

        fh = PerlIO_open(path, "rb");
        if (!fh) {
            RETVAL = FALSE;
        } else {
            apophis_identify_stream(aTHX_ uuid, ns, fh);
            PerlIO_close(fh);

            horus_format_uuid(recomputed, uuid, HORUS_FMT_STR);
            RETVAL = (id_len == HORUS_FMT_STR_LEN &&
                      memcmp(id_str, recomputed, HORUS_FMT_STR_LEN) == 0)
                     ? TRUE : FALSE;
        }
    OUTPUT:
        RETVAL

# op_remove($self, $id) -> bool
# Fused path + unlink + meta cleanup — single call.

bool
op_remove(self, id)
        SV *self
        SV *id
    PREINIT:
        HV *hv;
        const char *store_dir;
        STRLEN store_dir_len;
        const char *id_str;
        STRLEN id_len;
        char path[APOPHIS_PATH_MAX];
        int path_len;
        char meta_path[APOPHIS_PATH_MAX];
        int removed;
    CODE:
        if (!sv_isobject(self))
            croak("Apophis::op_remove: not an object");
        hv = (HV *)SvRV(self);

        store_dir = apophis_get_store_dir(aTHX_ hv, NULL, &store_dir_len);
        id_str = SvPV(id, id_len);
        path_len = apophis_build_path(path, sizeof(path),
                                       store_dir, store_dir_len,
                                       id_str, id_len);

        removed = (unlink(path) == 0);

        apophis_build_meta_path(meta_path, sizeof(meta_path),
                                path, path_len);
        unlink(meta_path);  /* ignore error — may not exist */

        RETVAL = removed ? TRUE : FALSE;
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# Custom op introspection and testing                                  #
# ------------------------------------------------------------------ #

# _make_op($type) -> confirmation string
# Creates a custom OP node and returns its pp_addr name for testing.

SV *
_make_op(type)
        const char *type
    CODE:
        if (strEQ(type, "identify")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_identify);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_identify[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else if (strEQ(type, "store")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_store);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_store[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else if (strEQ(type, "exists")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_exists);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_exists[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else if (strEQ(type, "fetch")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_fetch);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_fetch[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else if (strEQ(type, "verify")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_verify);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_verify[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else if (strEQ(type, "remove")) {
            OP *op = apophis_make_custom_op(aTHX_ pp_apophis_remove);
            RETVAL = newSVpvf("CUSTOM_OP@apophis_remove[%p]", (void *)op->op_ppaddr);
            FreeOp(op);
        } else {
            croak("Apophis::_make_op: unknown type '%s'", type);
        }
    OUTPUT:
        RETVAL
