#ifndef CHANDRA_ASSETS_H
#define CHANDRA_ASSETS_H

/*
 * chandra_assets.h — MIME type lookup and path security for Chandra::Assets
 *
 * Inline C helpers called from xs/assets.xs.
 * Keeps hot-path MIME detection out of Perl.
 */

/* ---- MIME type table ---- */

typedef struct {
    const char *ext;    /* lowercase, no dot */
    const char *mime;
} chandra_mime_entry;

static const chandra_mime_entry chandra_mime_table[] = {
    { "css",   "text/css" },
    { "js",    "application/javascript" },
    { "mjs",   "application/javascript" },
    { "html",  "text/html" },
    { "htm",   "text/html" },
    { "json",  "application/json" },
    { "xml",   "application/xml" },
    { "txt",   "text/plain" },
    { "csv",   "text/csv" },
    { "md",    "text/markdown" },
    /* images */
    { "png",   "image/png" },
    { "jpg",   "image/jpeg" },
    { "jpeg",  "image/jpeg" },
    { "gif",   "image/gif" },
    { "svg",   "image/svg+xml" },
    { "ico",   "image/x-icon" },
    { "webp",  "image/webp" },
    { "bmp",   "image/bmp" },
    /* fonts */
    { "woff",  "font/woff" },
    { "woff2", "font/woff2" },
    { "ttf",   "font/ttf" },
    { "otf",   "font/otf" },
    { "eot",   "application/vnd.ms-fontobject" },
    /* audio/video */
    { "mp3",   "audio/mpeg" },
    { "ogg",   "audio/ogg" },
    { "wav",   "audio/wav" },
    { "mp4",   "video/mp4" },
    { "webm",  "video/webm" },
    /* data */
    { "wasm",  "application/wasm" },
    { "pdf",   "application/pdf" },
    { "zip",   "application/zip" },
    { NULL, NULL }
};

/*
 * chandra_assets_mime(ext, ext_len)
 *   Returns the MIME type string for a given lowercase extension (no dot).
 *   Returns "application/octet-stream" for unknown extensions.
 */
static const char *
chandra_assets_mime(const char *ext, STRLEN ext_len)
{
    const chandra_mime_entry *e;
    for (e = chandra_mime_table; e->ext; e++) {
        if (strlen(e->ext) == ext_len && memcmp(e->ext, ext, ext_len) == 0)
            return e->mime;
    }
    return "application/octet-stream";
}

/*
 * chandra_assets_is_text_mime(mime)
 *   Returns 1 if the MIME type is text-based (safe to inline without base64).
 */
static int
chandra_assets_is_text_mime(const char *mime)
{
    return (strncmp(mime, "text/", 5) == 0 ||
            strncmp(mime, "application/javascript", 22) == 0 ||
            strncmp(mime, "application/json", 16) == 0 ||
            strncmp(mime, "application/xml", 15) == 0 ||
            strncmp(mime, "image/svg+xml", 13) == 0);
}

/*
 * chandra_assets_path_safe(path, path_len)
 *   Returns 1 if the path is safe (no traversal attacks).
 *   Rejects:  "..", absolute paths, backslashes, null bytes.
 */
static int
chandra_assets_path_safe(const char *path, STRLEN path_len)
{
    STRLEN i;
    /* reject null bytes */
    for (i = 0; i < path_len; i++) {
        if (path[i] == '\0') return 0;
    }
    /* reject absolute paths */
    if (path_len > 0 && (path[0] == '/' || path[0] == '\\')) return 0;
    /* reject backslashes (Windows path sep) */
    for (i = 0; i < path_len; i++) {
        if (path[i] == '\\') return 0;
    }
    /* reject ".." components */
    for (i = 0; i + 1 < path_len; i++) {
        if (path[i] == '.' && path[i + 1] == '.') {
            /* It's ".." if at start, end, or surrounded by slashes */
            if ((i == 0 || path[i - 1] == '/') &&
                (i + 2 >= path_len || path[i + 2] == '/'))
                return 0;
        }
    }
    return 1;
}

#endif /* CHANDRA_ASSETS_H */

/*
 * XS callback for protocol handler — serves asset files.
 * CvXSUBANY stores a reference to the Chandra::Assets object.
 * Called by the protocol system with ($path, $params).
 */
static XS(XS_Chandra__Assets__serve_handler)
{
    dXSARGS;
    SV *assets_self = (SV *)CvXSUBANY(cv).any_ptr;
    SV *path_sv = (items > 0) ? ST(0) : &PL_sv_undef;
    SV *result = &PL_sv_undef;
    PERL_UNUSED_VAR(items);

    if (assets_self && SvOK(assets_self)) {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(assets_self);
        XPUSHs(path_sv);
        PUTBACK;
        count = call_method("_serve", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) {
            result = newSVsv(POPs);
        }
        PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
    }

    if (result == &PL_sv_undef) {
        ST(0) = &PL_sv_undef;
    } else {
        ST(0) = sv_2mortal(result);
    }
    XSRETURN(1);
}
