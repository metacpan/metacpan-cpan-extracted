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

#include "ppport.h"
#include "xop_compat.h"

#include <sys/stat.h>
#include <errno.h>
#ifndef _WIN32
#  include <unistd.h>
#else
#  include <io.h>
#  include <direct.h>
#  include <windows.h>   /* MoveFileEx; perl.h has it already, this is a guard */
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
   /*
    * Stat_t is struct w32_stat, the layout perl's own stat() fills in - but
    * that stat() is the macro undef'd just above, so what is left is the CRT
    * one, which writes a differently shaped struct.  Pair the call and the
    * type instead: _stat64 keeps st_size 64 bit, which the CRT's struct stat
    * does not on Win64.
    */
#  define apophis_stat_t struct _stat64
#  define apophis_stat(p, b) _stat64((p), (b))
#else
#  define apophis_mkdir(p, m) mkdir(p, m)
#  define apophis_stat_t struct stat
#  define apophis_stat(p, b) stat((p), (b))
#endif

/*
 * The CRT rename() refuses a destination that already exists, so the second
 * store of the same content with metadata could not replace its sidecar.
 * MoveFileEx replaces, and stays atomic.
 */
static int
apophis_rename(const char *from, const char *to)
{
#ifdef WIN32
    if (MoveFileExA(from, to, MOVEFILE_REPLACE_EXISTING))
        return 0;
    errno = EACCES;
    return -1;
#else
    return rename(from, to);
#endif
}

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

/* The same for the XSUBs, which have nowhere to report a truncated path: a
 * path that does not fit, with room left for the .tmp.<pid> and .meta
 * suffixes written beside it, is a different file, so it croaks. */
#define APOPHIS_PATH_ROOM 24

static int
apophis_path(char *out, size_t out_size,
             const char *store_dir, STRLEN store_len,
             const char *id, STRLEN id_len)
{
    int len = apophis_build_path(out, out_size, store_dir, store_len, id, id_len);
    if (len < 0 || (size_t)len + APOPHIS_PATH_ROOM >= out_size) /* # uncoverable condition left count:1 */
        croak("Apophis: path too long");
    return len;
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

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (written != (SSize_t)content_len) {
        unlink(tmp_path); /* # uncoverable statement */
        croak("Apophis: short write to '%s'", tmp_path); /* # uncoverable statement */
    }

    if (apophis_rename(tmp_path, path) != 0) {
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

    if (apophis_rename(tmp_path, meta_path) != 0) {
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

    if (apophis_stat(meta_path, &st) != 0) return NULL;

    fh = PerlIO_open(meta_path, "r");
    if (!fh) return NULL;

    buf = (char *)malloc((size_t)st.st_size + 1);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!buf) { PerlIO_close(fh); return NULL; }

    nread = PerlIO_read(fh, buf, (Size_t)st.st_size);
    if (PerlIO_error(fh)) nread = -1;
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
/* The six fused bodies                                                */
/*                                                                     */
/* identify, store, exists, fetch, verify and remove each have one     */
/* body here. The XSUB of that name runs it, and so does the custom op */
/* a call to it compiles to under `use Apophis`. `who` is the name a   */
/* croak reports. `args` and `items` are the XSUB's stack, for the     */
/* key/value options after the positional arguments; the op passes     */
/* NULL and 2, since it only stands for a call with none.              */
/* ================================================================== */

static HV *
apophis_self_hv(pTHX_ const char *who, SV *self)
{
    if (!sv_isobject(self))
        croak("%s: not an object", who);
    return (HV *)SvRV(self);
}

/* The trailing key/value pairs as a mortal HV, or NULL when there are
 * none. When `meta` is given, a `meta` hashref goes there instead. */
static HV *
apophis_opts(pTHX_ const char *who, SV **args, I32 items, HV **meta)
{
    HV *opts;
    I32 i;

    if (items <= 2)
        return NULL;
    if ((items - 2) % 2 != 0)
        croak("%s: odd number of optional arguments", who);
    opts = (HV *)sv_2mortal((SV *)newHV());
    for (i = 2; i < items; i += 2) {
        STRLEN klen;
        const char *k = SvPV(args[i], klen);
        SV *v = args[i + 1];
        if (meta && strEQ(k, "meta") && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV)
            *meta = (HV *)SvRV(v);
        else
            (void)hv_store(opts, k, klen, SvREFCNT_inc(v), 0);
    }
    return opts;
}

static const char *
apophis_content_of(pTHX_ const char *who, SV *content_ref, STRLEN *len)
{
    if (!SvROK(content_ref))
        croak("%s: argument must be a scalar reference", who);
    return SvPV(SvRV(content_ref), *len);
}

static void
apophis_do_identify(pTHX_ const char *who, SV *self, SV *content_ref, unsigned char *uuid)
{
    HV *hv = apophis_self_hv(aTHX_ who, self);
    const unsigned char *ns = apophis_get_ns(aTHX_ hv);
    STRLEN content_len;
    const char *content = apophis_content_of(aTHX_ who, content_ref, &content_len);

    apophis_identify_content(uuid, ns, content, content_len);
}

/* Writes the id, HORUS_FMT_STR_LEN bytes and a NUL, into id_str. */
static void
apophis_do_store(pTHX_ const char *who, SV *self, SV *content_ref, SV **args, I32 items, char *id_str)
{
    HV *hv = apophis_self_hv(aTHX_ who, self);
    const unsigned char *ns = apophis_get_ns(aTHX_ hv);
    STRLEN content_len, store_dir_len;
    const char *content = apophis_content_of(aTHX_ who, content_ref, &content_len);
    HV *meta = NULL;
    HV *opts = apophis_opts(aTHX_ who, args, items, &meta);
    const char *store_dir;
    unsigned char uuid[16];
    char path[APOPHIS_PATH_MAX];
    int path_len;
    apophis_stat_t st;

    apophis_identify_content(uuid, ns, content, content_len);
    horus_format_uuid(id_str, uuid, HORUS_FMT_STR);

    store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);
    path_len = apophis_path(path, sizeof(path), store_dir, store_dir_len, id_str, HORUS_FMT_STR_LEN);

    if (apophis_stat(path, &st) != 0) {
        apophis_ensure_parent_dir(path);
        apophis_atomic_write(aTHX_ path, content, content_len);
    }

    if (meta) {
        char meta_path[APOPHIS_PATH_MAX];
        apophis_build_meta_path(meta_path, sizeof(meta_path), path, path_len);
        apophis_meta_write(aTHX_ meta_path, meta);
    }
}

/* The sharded path of an id under the store, for the four methods that
 * take an id and options. Gives the id's bytes back for verify. */
static int
apophis_id_path(pTHX_ const char *who, HV *hv, SV *id, SV **args, I32 items,
                char *path, size_t path_size, const char **id_str, STRLEN *id_len)
{
    HV *opts = apophis_opts(aTHX_ who, args, items, NULL);
    STRLEN store_dir_len;
    const char *store_dir = apophis_get_store_dir(aTHX_ hv, opts, &store_dir_len);

    *id_str = SvPV(id, *id_len);
    return apophis_path(path, path_size, store_dir, store_dir_len, *id_str, *id_len);
}

static bool
apophis_do_exists(pTHX_ const char *who, SV *self, SV *id, SV **args, I32 items)
{
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    apophis_stat_t st;

    apophis_id_path(aTHX_ who, apophis_self_hv(aTHX_ who, self), id, args, items, path, sizeof(path), &id_str, &id_len);
    return apophis_stat(path, &st) == 0;
}

/* A new reference to the content, or &PL_sv_undef when there is none. */
static SV *
apophis_do_fetch(pTHX_ const char *who, SV *self, SV *id, SV **args, I32 items)
{
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    apophis_stat_t st;
    PerlIO *fh;
    SV *content;
    SSize_t nread;

    apophis_id_path(aTHX_ who, apophis_self_hv(aTHX_ who, self), id, args, items, path, sizeof(path), &id_str, &id_len);
    if (apophis_stat(path, &st) != 0)
        return &PL_sv_undef;

    fh = PerlIO_open(path, "rb");
    if (!fh)
        croak("%s: cannot open '%s': %s", who, path, strerror(errno));

    content = newSV((STRLEN)st.st_size + 1);
    SvPOK_on(content);
    nread = PerlIO_read(fh, SvPVX(content), (Size_t)st.st_size);
    if (PerlIO_error(fh))
        nread = -1;
    PerlIO_close(fh);

    if (nread < 0) {
        SvREFCNT_dec(content);
        croak("%s: read error on '%s'", who, path);
    }
    SvCUR_set(content, (STRLEN)nread);
    *SvEND(content) = '\0';
    return newRV_noinc(content);
}

static bool
apophis_do_verify(pTHX_ const char *who, SV *self, SV *id, SV **args, I32 items)
{
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    PerlIO *fh;
    unsigned char uuid[16];
    char recomputed[HORUS_FMT_STR_LEN + 1];
    HV *hv = apophis_self_hv(aTHX_ who, self);
    const unsigned char *ns = apophis_get_ns(aTHX_ hv);

    apophis_id_path(aTHX_ who, hv, id, args, items, path, sizeof(path), &id_str, &id_len);
    fh = PerlIO_open(path, "rb");
    if (!fh)
        return FALSE;

    apophis_identify_stream(aTHX_ uuid, ns, fh);
    PerlIO_close(fh);
    horus_format_uuid(recomputed, uuid, HORUS_FMT_STR);
    return id_len == HORUS_FMT_STR_LEN && memcmp(id_str, recomputed, HORUS_FMT_STR_LEN) == 0;
}

static bool
apophis_do_remove(pTHX_ const char *who, SV *self, SV *id, SV **args, I32 items)
{
    const char *id_str;
    STRLEN id_len;
    char path[APOPHIS_PATH_MAX];
    char meta_path[APOPHIS_PATH_MAX];
    int path_len, removed;

    path_len = apophis_id_path(aTHX_ who, apophis_self_hv(aTHX_ who, self), id, args, items, path, sizeof(path), &id_str, &id_len);
    removed = unlink(path) == 0;

    /* The sidecar goes too. It need not be there. */
    apophis_build_meta_path(meta_path, sizeof(meta_path), path, path_len);
    unlink(meta_path);
    return removed ? TRUE : FALSE;
}


/* ================================================================== */
/* Custom ops                                                          */
/*                                                                     */
/* Under `use Apophis`, a call to one of the six methods above with    */
/* exactly its arguments compiles to a custom op in place of the       */
/* entersub. The op keeps entersub's kids, so the method is still      */
/* looked up at run time and the invocant decides. When it resolves    */
/* to this module's own XSUB, the op runs the body straight off the    */
/* stack: no sub call, no @_, and a result written into the pad slot   */
/* the call site owns. Anything else, a method a subclass overrode, a  */
/* wrapped sub, a call that turns out to carry options, runs           */
/* pp_entersub itself, so it behaves exactly as it would have.         */
/* ================================================================== */

#define AP_HINT_KEY "Apophis/ops"

enum { AP_IDENTIFY, AP_STORE, AP_EXISTS, AP_FETCH, AP_VERIFY, AP_REMOVE, AP_NOPS };

static OP *pp_apophis_identify(pTHX);
static OP *pp_apophis_store(pTHX);
static OP *pp_apophis_exists(pTHX);
static OP *pp_apophis_fetch(pTHX);
static OP *pp_apophis_verify(pTHX);
static OP *pp_apophis_remove(pTHX);

typedef struct {
    const char *name;
    STRLEN      len;
    int         which;
} ap_name_t;

/* The method names a call site may use, and the op each stands for. The
 * op_ names are the aliases below, kept from when they were the only way
 * to the fused bodies. */
static const ap_name_t ap_names[] = {
    { "identify",    8,  AP_IDENTIFY }, { "op_identify", 11, AP_IDENTIFY },
    { "store",       5,  AP_STORE    }, { "op_store",    8,  AP_STORE    },
    { "exists",      6,  AP_EXISTS   }, { "op_exists",   9,  AP_EXISTS   },
    { "fetch",       5,  AP_FETCH    }, { "op_fetch",    8,  AP_FETCH    },
    { "verify",      6,  AP_VERIFY   }, { "op_verify",   9,  AP_VERIFY   },
    { "remove",      6,  AP_REMOVE   }, { "op_remove",   9,  AP_REMOVE   },
};

static const char *const ap_method[AP_NOPS] = {
    "identify", "store", "exists", "fetch", "verify", "remove",
};

/* The name a croak reports, by op and by whether the call used the op_
 * alias, which is the XSUB's ix. */
static const char *const ap_who[AP_NOPS][2] = {
    { "Apophis::identify", "Apophis::op_identify" },
    { "Apophis::store",    "Apophis::op_store"    },
    { "Apophis::exists",   "Apophis::op_exists"   },
    { "Apophis::fetch",    "Apophis::op_fetch"    },
    { "Apophis::verify",   "Apophis::op_verify"   },
    { "Apophis::remove",   "Apophis::op_remove"   },
};

static OP *(*const ap_pp[AP_NOPS])(pTHX) = {
    pp_apophis_identify, pp_apophis_store, pp_apophis_exists,
    pp_apophis_fetch, pp_apophis_verify, pp_apophis_remove,
};

static const char *const ap_xop_name[AP_NOPS] = {
    "apophis_identify", "apophis_store", "apophis_exists",
    "apophis_fetch", "apophis_verify", "apophis_remove",
};

static const char *const ap_xop_desc[AP_NOPS] = {
    "Apophis fused identify (SHA-1, UUID v5)",
    "Apophis fused store (identify, mkdir, atomic write)",
    "Apophis fused exists (path, stat)",
    "Apophis fused fetch (path, stat, read)",
    "Apophis fused verify (read, re-hash, compare)",
    "Apophis fused remove (path, unlink, sidecar)",
};

/* The C function behind each method's XSUB, taken at boot. A CV on the
 * stack is ours when it runs one of these, which holds in every thread
 * and survives nothing but a redefinition. */
static XSUBADDR_t ap_xsub[AP_NOPS];
static XOP        ap_xop[AP_NOPS];

static bool
ap_ops_in_scope(pTHX)
{
    SV **ent = hv_fetchs(GvHV(PL_hintgv), AP_HINT_KEY, 0);
    return ent && SvTRUE(*ent);
}

/* entersub's own check has run. A method call to one of the names, with
 * no more kids than the invocant and the one argument, becomes the op. */
static Perl_check_t ap_next_ck_entersub;

static OP *
ap_ck_entersub(pTHX_ OP *o)
{
    OP *kid, *last = NULL;
    SV *meth;
    const char *name;
    STRLEN len;
    int nkids = 0;
    size_t i;

    o = ap_next_ck_entersub(aTHX_ o);
    if (o->op_type != OP_ENTERSUB
        || (o->op_private & (OPpENTERSUB_AMPER | OPpENTERSUB_DB))
        || !ap_ops_in_scope(aTHX))
        return o;

    /* The kids, or the nulled list that holds them, as ck_subr reads them. */
    kid = cUNOPo->op_first;
    if (!OpHAS_SIBLING(kid))
        kid = cUNOPx(kid)->op_first;
    for (; kid; kid = OpSIBLING(kid)) {
        last = kid;
        nkids++;
    }
    /* pushmark, the invocant, the argument, the method */
    if (last->op_type != OP_METHOD_NAMED || nkids > 4)
        return o;

#if PERL_VERSION_GE(5,22,0)
    meth = cMETHOPx_meth(last);
#else
    meth = cSVOPx_sv(last);
#endif
    name = SvPV(meth, len);
    for (i = 0; i < sizeof(ap_names) / sizeof(*ap_names); i++) {
        if (len == ap_names[i].len && memEQ(name, ap_names[i].name, len)) {
            o->op_type   = OP_CUSTOM;
            o->op_ppaddr = ap_pp[ap_names[i].which];
#if PERL_VERSION_GE(5,16,0)
            /* A perl that gives entersub a pad slot of its own, as 5.40
             * and 5.42 do, never reaches the allocation.
             # uncoverable branch true
             # uncoverable condition left count:1 */
            if (!o->op_targ)
                o->op_targ = pad_alloc(OP_ENTERSUB, SVs_PADTMP); /* # uncoverable statement */
#endif
            break;
        }
    }
    return o;
}

/* Above the mark sit the invocant, the argument and the CV the method
 * resolved to. The op takes the call when that CV is the XSUB it stands
 * for, and then only. */
static bool
ap_op_mine(pTHX_ SV **mark, SV **sp, int which)
{
    SV *cv = *sp;
    return sp - mark == 3
        && SvTYPE(cv) == SVt_PVCV
        && CvISXSUB((CV *)cv)
        && CvXSUB((CV *)cv) == ap_xsub[which];
}

static const char *
ap_op_who(SV *cv, int which)
{
    return ap_who[which][CvXSUBANY((CV *)cv).any_i32 ? 1 : 0];
}

/* The call site's pad slot, which the check above saw to. */
static SV *
ap_op_targ(pTHX)
{
    return PAD_SV(PL_op->op_targ);
}

/* The call is over. Its three values go, and the result takes their
 * place unless nothing wanted one. */
static OP *
ap_op_leave(pTHX_ I32 markix, SV *result)
{
    dSP;
    const I32 gimme = GIMME_V;

    SP = PL_stack_base + markix;
    if (gimme != G_VOID)
        *++SP = result;
    PUTBACK;
    return NORMAL;
}

/* The mark is kept as an index: a body may read a tied or overloaded
 * argument, and that can move the stack. */
#define AP_OP_PROLOGUE(which)                                   \
    dSP;                                                        \
    const I32 markix = TOPMARK;                                 \
    SV **mark = PL_stack_base + markix;                         \
    const char *who;                                            \
    if (!ap_op_mine(aTHX_ mark, SP, (which)))                   \
        return PL_ppaddr[OP_ENTERSUB](aTHX);                    \
    who = ap_op_who(*SP, (which));                              \
    (void)POPMARK

static OP *
pp_apophis_identify(pTHX)
{
    unsigned char uuid[16];
    char buf[HORUS_FMT_STR_LEN + 1];
    SV *result;
    AP_OP_PROLOGUE(AP_IDENTIFY);

    apophis_do_identify(aTHX_ who, mark[1], mark[2], uuid);
    horus_format_uuid(buf, uuid, HORUS_FMT_STR);
    result = ap_op_targ(aTHX);
    sv_setpvn(result, buf, HORUS_FMT_STR_LEN);
    return ap_op_leave(aTHX_ markix, result);
}

static OP *
pp_apophis_store(pTHX)
{
    char id_str[HORUS_FMT_STR_LEN + 1];
    SV *result;
    AP_OP_PROLOGUE(AP_STORE);

    apophis_do_store(aTHX_ who, mark[1], mark[2], NULL, 2, id_str);
    result = ap_op_targ(aTHX);
    sv_setpvn(result, id_str, HORUS_FMT_STR_LEN);
    return ap_op_leave(aTHX_ markix, result);
}

static OP *
pp_apophis_exists(pTHX)
{
    AP_OP_PROLOGUE(AP_EXISTS);
    return ap_op_leave(aTHX_ markix,
        apophis_do_exists(aTHX_ who, mark[1], mark[2], NULL, 2) ? &PL_sv_yes : &PL_sv_no);
}

static OP *
pp_apophis_fetch(pTHX)
{
    AP_OP_PROLOGUE(AP_FETCH);
    return ap_op_leave(aTHX_ markix,
        sv_2mortal(apophis_do_fetch(aTHX_ who, mark[1], mark[2], NULL, 2)));
}

static OP *
pp_apophis_verify(pTHX)
{
    AP_OP_PROLOGUE(AP_VERIFY);
    return ap_op_leave(aTHX_ markix,
        apophis_do_verify(aTHX_ who, mark[1], mark[2], NULL, 2) ? &PL_sv_yes : &PL_sv_no);
}

static OP *
pp_apophis_remove(pTHX)
{
    AP_OP_PROLOGUE(AP_REMOVE);
    return ap_op_leave(aTHX_ markix,
        apophis_do_remove(aTHX_ who, mark[1], mark[2], NULL, 2) ? &PL_sv_yes : &PL_sv_no);
}

/* Once for the process: the XSUBs behind the names, the ops' names for
 * B and the debugger, and the hook on entersub's check. */
static void
ap_boot_ops(pTHX)
{
    int i;

    for (i = 0; i < AP_NOPS; i++) {
        CV *cv = get_cv(form("Apophis::%s", ap_method[i]), 0);
        ap_xsub[i] = CvXSUB(cv);
        XopENTRY_set(&ap_xop[i], xop_name, ap_xop_name[i]);
        XopENTRY_set(&ap_xop[i], xop_desc, ap_xop_desc[i]);
        XopENTRY_set(&ap_xop[i], xop_class, OA_UNOP);
        Perl_custom_op_register(aTHX_ ap_pp[i], &ap_xop[i]);
    }
#if PERL_VERSION_GE(5,16,0)
    wrap_op_checker(OP_ENTERSUB, ap_ck_entersub, &ap_next_ck_entersub);
#else
    if (!ap_next_ck_entersub) {
        ap_next_ck_entersub = PL_check[OP_ENTERSUB];
        PL_check[OP_ENTERSUB] = ap_ck_entersub;
    }
#endif
}


/* ================================================================== */
/* The public C ABI                                                    */
/* ================================================================== */

/* Wraps the static core above into the table consumers reach through
 * Apophis::_abi_ptr. Included here, after everything it wraps. */
#include "ap_abi_impl.h"


/* ================================================================== */
/* XSUBs                                                               */
/* ================================================================== */

MODULE = Apophis  PACKAGE = Apophis

BOOT:
    ap_boot_ops(aTHX);

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
    ALIAS:
        op_identify = 1
    PREINIT:
        unsigned char uuid[16];
    CODE:
        apophis_do_identify(aTHX_ ap_who[AP_IDENTIFY][ix], self, content_ref, uuid);
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

        path_len = apophis_path(path, sizeof(path),
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
    ALIAS:
        op_store = 1
    PREINIT:
        char id_str[HORUS_FMT_STR_LEN + 1];
    CODE:
        apophis_do_store(aTHX_ ap_who[AP_STORE][ix], self, content_ref, &ST(0), items, id_str);
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
    ALIAS:
        op_fetch = 1
    CODE:
        RETVAL = apophis_do_fetch(aTHX_ ap_who[AP_FETCH][ix], self, id, &ST(0), items);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# exists($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
exists(self, id, ...)
        SV *self
        SV *id
    ALIAS:
        op_exists = 1
    CODE:
        RETVAL = apophis_do_exists(aTHX_ ap_who[AP_EXISTS][ix], self, id, &ST(0), items);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# remove($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
remove(self, id, ...)
        SV *self
        SV *id
    ALIAS:
        op_remove = 1
    CODE:
        RETVAL = apophis_do_remove(aTHX_ ap_who[AP_REMOVE][ix], self, id, &ST(0), items);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# verify($id, %opts) -> bool                                          #
# ------------------------------------------------------------------ #

bool
verify(self, id, ...)
        SV *self
        SV *id
    ALIAS:
        op_verify = 1
    CODE:
        RETVAL = apophis_do_verify(aTHX_ ap_who[AP_VERIFY][ix], self, id, &ST(0), items);
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

            apophis_path(path, sizeof(path),
                               store_dir, store_dir_len,
                               id_str, HORUS_FMT_STR_LEN);

            if (apophis_stat(path, &st) != 0) {
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
            apophis_path(path, sizeof(path),
                               store_dir, store_dir_len, id_str, id_len);

            if (apophis_stat(path, &st) != 0) {
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
        path_len = apophis_path(path, sizeof(path),
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
# The public C ABI (ap_abi.h)                                          #
# ------------------------------------------------------------------ #

# _abi_ptr() -> the address of the process-wide table, as a UV.
#
# Private. UV and PTR2UV rather than IV and PTR2IV because an address is
# unsigned: PTR2IV hands back a NEGATIVE integer wherever the .so maps with
# the top bit set - Solaris/illumos amd64 loads libraries high, and so does
# any 32-bit build in the upper 2GB - which makes a consumer's `$ptr > 0`
# sanity check fail on a perfectly usable pointer.

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&AP_ABI);
    OUTPUT:
        RETVAL

# _abi_selftest($store, \$content, $name, $fh)
#   -> ($id, $path, $ns_of_name, $id_of_fh, $short_id_rc, $probe_rc, $probe_dirlen)
#
# Drives the table through its own function pointers, so the suite exercises
# the ABI the way a consumer does rather than the way the XSUBs do. Writes the
# blob, exactly as store() would. The test compares both answers against the
# Perl API - two implementations of one algorithm agreeing is the assertion,
# not an assumption. The rest of the table rides along: the namespace derived
# from $name, the id of what $fh reads, build_path's refusal of a short id, and
# store_of asked for part of the store, as a consumer probing with NULLs does.

void
_abi_selftest(self, content_ref, name, fh_sv)
        SV *self
        SV *content_ref
        SV *name
        SV *fh_sv
    PREINIT:
        const ap_abi *A = &AP_ABI;
        const unsigned char *ns = NULL;
        const unsigned char *ns_only = NULL;
        const char *dir = NULL;
        const char *dir_only = NULL;
        STRLEN dirlen = 0;
        STRLEN only_len = 0;
        const char *content;
        STRLEN content_len;
        const char *name_str;
        STRLEN name_len;
        unsigned char id[16];
        unsigned char ns_bytes[16];
        unsigned char fh_id[16];
        char id_str[HORUS_FMT_STR_LEN + 1];
        char ns_str[HORUS_FMT_STR_LEN + 1];
        char fh_str[HORUS_FMT_STR_LEN + 1];
        char path[APOPHIS_PATH_MAX];
        int path_len;
        int short_rc;
        int probe_rc;
        int null_rc;
    PPCODE:
        if (!A->store_of(aTHX_ self, &ns, &dir, &dirlen))
            croak("Apophis::_abi_selftest: not a store");
        if (!SvROK(content_ref))
            croak("Apophis::_abi_selftest: content must be a scalar reference");
        content = SvPV(SvRV(content_ref), content_len);
        name_str = SvPV(name, name_len);

        probe_rc = A->store_of(aTHX_ self, &ns_only, NULL, NULL)
                 + A->store_of(aTHX_ self, NULL, &dir_only, NULL)
                 + A->store_of(aTHX_ self, NULL, NULL, &only_len);
        null_rc  = A->store_of(aTHX_ NULL, &ns_only, &dir_only, &only_len);

        A->derive_ns(ns_bytes, name_str, name_len);
        A->format_id(ns_str, ns_bytes);

        A->identify(id, ns, content, content_len);
        A->format_id(id_str, id);

        short_rc = A->build_path(path, sizeof(path), dir, dirlen, id_str, 3);
        path_len = A->build_path(path, sizeof(path), dir, dirlen,
                                 id_str, HORUS_FMT_STR_LEN);
        if (path_len < 0 || (size_t)path_len >= sizeof(path)) /* # uncoverable condition left count:1 */
            croak("Apophis::_abi_selftest: path too long");

        A->write_atomic(aTHX_ path, content, content_len);

        A->identify_fh(aTHX_ fh_id, ns, IoIFP(sv_2io(fh_sv)));
        A->format_id(fh_str, fh_id);

        EXTEND(SP, 8);
        PUSHs(sv_2mortal(newSVpvn(id_str, HORUS_FMT_STR_LEN)));
        PUSHs(sv_2mortal(newSVpvn(path, path_len)));
        PUSHs(sv_2mortal(newSVpvn(ns_str, HORUS_FMT_STR_LEN)));
        PUSHs(sv_2mortal(newSVpvn(fh_str, HORUS_FMT_STR_LEN)));
        PUSHs(sv_2mortal(newSViv(short_rc)));
        PUSHs(sv_2mortal(newSViv(probe_rc)));
        PUSHs(sv_2mortal(newSVuv(only_len)));
        PUSHs(sv_2mortal(newSViv(null_rc)));

# _abi_write($path, \$content)
#
# The table's write_atomic on a path of the caller's choosing, as a consumer
# that built its own path would call it.

void
_abi_write(path, content_ref)
        const char *path
        SV *content_ref
    PREINIT:
        const char *content;
        STRLEN content_len;
    PPCODE:
        if (!SvROK(content_ref))
            croak("Apophis::_abi_write: content must be a scalar reference");
        content = SvPV(SvRV(content_ref), content_len);
        AP_ABI.write_atomic(aTHX_ path, content, content_len);
        XSRETURN_EMPTY;
