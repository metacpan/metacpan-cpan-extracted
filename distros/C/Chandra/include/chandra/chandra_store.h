/*
 * chandra_store.h — Persistent key-value storage for Chandra apps
 *
 * Storage: JSON file, default ~/.chandra/<name>/store.json
 * Features: dot-notation keys, atomic writes, flock concurrency safety
 *
 * Include with CHANDRA_XS_IMPLEMENTATION defined to get implementations.
 */
#ifndef CHANDRA_STORE_H
#define CHANDRA_STORE_H

#include "chandra.h"
#include <sys/stat.h>
#include <sys/file.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <pwd.h>

#ifdef CHANDRA_XS_IMPLEMENTATION

/* ============================================================================
 * JSON singleton
 * ============================================================================ */

static SV *_store_json_obj = NULL;

static SV *
chandra_store_get_json(pTHX)
{
    if (!_store_json_obj || !SvOK(_store_json_obj)) {
        _store_json_obj = eval_pv(
            "require Cpanel::JSON::XS;"
            "Cpanel::JSON::XS->new->utf8->pretty(1)->canonical(1)->allow_nonref",
            TRUE
        );
        SvREFCNT_inc_simple_void(_store_json_obj);
    }
    return _store_json_obj;
}

static SV *
chandra_store_encode(pTHX_ SV *val)
{
    dSP;
    SV *json = chandra_store_get_json(aTHX);
    int count;
    SV *result;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json);
    XPUSHs(val);
    PUTBACK;
    count = call_method("encode", G_SCALAR | G_EVAL);
    SPAGAIN;
    result = (count > 0 && !SvTRUE(ERRSV))
        ? newSVsv(POPs) : newSVpvs("{}");
    if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
    PUTBACK; FREETMPS; LEAVE;
    return result;
}

/* Returns new HV* on success, NULL on corrupt (emits warn) */
static HV *
chandra_store_decode(pTHX_ SV *json_sv, const char *path)
{
    dSP;
    SV *json = chandra_store_get_json(aTHX);
    int count;
    HV *result = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json);
    XPUSHs(json_sv);
    PUTBACK;
    count = call_method("decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count > 0 && !SvTRUE(ERRSV)) {
        SV *decoded = POPs;
        if (SvOK(decoded) && SvROK(decoded)
                && SvTYPE(SvRV(decoded)) == SVt_PVHV) {
            result = (HV *)SvRV(decoded);
            SvREFCNT_inc_simple_void((SV *)result);
        }
    }
    if (SvTRUE(ERRSV)) sv_setpvs(ERRSV, "");
    PUTBACK; FREETMPS; LEAVE;
    if (!result)
        warn("Chandra::Store: corrupt store '%s', starting fresh\n",
             path ? path : "unknown");
    return result;
}

/* ============================================================================
 * mkdir -p in C
 * ============================================================================ */

static int
chandra_store_mkdirp(const char *path, mode_t mode)
{
    char tmp[4096];
    char *p;
    struct stat st;
    size_t len;

    if (stat(path, &st) == 0) return 0;

    strncpy(tmp, path, sizeof(tmp) - 1);
    tmp[sizeof(tmp) - 1] = '\0';
    len = strlen(tmp);
    if (len > 0 && tmp[len - 1] == '/') tmp[len - 1] = '\0';

    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            if (stat(tmp, &st) != 0)
                if (mkdir(tmp, mode) != 0 && errno != EEXIST) return -1;
            *p = '/';
        }
    }
    if (mkdir(tmp, mode) != 0 && errno != EEXIST) return -1;
    return 0;
}

/* ============================================================================
 * Dot-notation traversal
 *
 * Splits key on '.', walks HV chain, returns (parent HV, leaf key as mortal SV).
 * create=1: missing intermediate HVs are created.
 * Returns NULL on failure (non-hash intermediate, or absent + !create).
 * On "intermediate is not a hash" sets *not_hash = 1.
 * ============================================================================ */

static HV *
chandra_store_traverse(pTHX_ HV *data, const char *key, STRLEN klen,
                       int create, SV **leaf_sv, int *not_hash)
{
    char *buf;
    char *p, *seg;
    HV *node = data;

    *leaf_sv = NULL;
    if (not_hash) *not_hash = 0;

    Newx(buf, klen + 1, char);
    memcpy(buf, key, klen);
    buf[klen] = '\0';

    p   = buf;
    seg = buf;

    while (*p) {
        if (*p == '.') {
            STRLEN seg_len;
            SV **svp;
            *p = '\0';
            seg_len = (STRLEN)(p - seg);

            svp = hv_fetch(node, seg, (I32)seg_len, 0);
            if (!svp || !SvOK(*svp)) {
                if (!create) { Safefree(buf); return NULL; }
                HV *new_hv = newHV();
                (void)hv_store(node, seg, (I32)seg_len,
                               newRV_noinc((SV *)new_hv), 0);
                node = new_hv;
            } else if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
                node = (HV *)SvRV(*svp);
            } else {
                /* Non-hash in the middle of the path */
                if (not_hash) *not_hash = 1;
                Safefree(buf);
                return NULL;
            }
            p++;
            seg = p;
        } else {
            p++;
        }
    }

    *leaf_sv = sv_2mortal(newSVpvn(seg, (STRLEN)(p - seg)));
    Safefree(buf);
    return node;
}

/* ============================================================================
 * File I/O — save & reload
 * ============================================================================ */

static void
chandra_store_save_c(pTHX_ HV *self_hv)
{
    SV **path_svp  = hv_fetchs(self_hv, "_path", 0);
    SV **data_svp  = hv_fetchs(self_hv, "_data", 0);
    const char *path;
    char tmp_path[4096];
    char dir_buf[4096];
    char *last_slash;
    SV *json_sv;
    STRLEN json_len;
    const char *json_str;
    FILE *fh;
    int fd;

    if (!path_svp || !SvOK(*path_svp)) return;
    if (!data_svp || !SvROK(*data_svp)) return;

    path = SvPV_nolen(*path_svp);

    /* Ensure parent directory */
    strncpy(dir_buf, path, sizeof(dir_buf) - 1);
    dir_buf[sizeof(dir_buf) - 1] = '\0';
    last_slash = strrchr(dir_buf, '/');
    if (last_slash) {
        *last_slash = '\0';
        chandra_store_mkdirp(dir_buf, 0700);
    }

    /* Build .tmp.PID path */
    snprintf(tmp_path, sizeof(tmp_path), "%s.tmp.%d", path, (int)getpid());

    /* JSON-encode the data */
    json_sv = chandra_store_encode(aTHX_ *data_svp);
    json_str = SvPV(json_sv, json_len);

    fh = fopen(tmp_path, "w");
    if (!fh) {
        SvREFCNT_dec(json_sv);
        croak("Chandra::Store: cannot open '%s' for write: %s\n",
              tmp_path, strerror(errno));
    }

    fd = fileno(fh);
    flock(fd, LOCK_EX);
    fwrite(json_str, 1, json_len, fh);
    flock(fd, LOCK_UN);
    fclose(fh);

    SvREFCNT_dec(json_sv);

    if (rename(tmp_path, path) != 0)
        croak("Chandra::Store: cannot rename '%s' to '%s': %s\n",
              tmp_path, path, strerror(errno));
}

static void
chandra_store_reload_c(pTHX_ HV *self_hv)
{
    SV **path_svp = hv_fetchs(self_hv, "_path", 0);
    const char *path;
    FILE *fh;
    int fd;
    long size;
    char *buf;
    SV *json_sv;
    HV *new_data;

    if (!path_svp || !SvOK(*path_svp)) return;
    path = SvPV_nolen(*path_svp);

    fh = fopen(path, "r");
    if (!fh) return;  /* File doesn't exist yet — start fresh */

    fd = fileno(fh);
    flock(fd, LOCK_SH);

    fseek(fh, 0, SEEK_END);
    size = ftell(fh);
    fseek(fh, 0, SEEK_SET);

    if (size <= 0) {
        flock(fd, LOCK_UN);
        fclose(fh);
        return;
    }

    Newx(buf, size + 1, char);
    fread(buf, 1, (size_t)size, fh);
    buf[size] = '\0';

    flock(fd, LOCK_UN);
    fclose(fh);

    json_sv = sv_2mortal(newSVpvn(buf, (STRLEN)size));
    Safefree(buf);

    new_data = chandra_store_decode(aTHX_ json_sv, path);
    if (new_data) {
        SV **old_svp = hv_fetchs(self_hv, "_data", 0);
        if (old_svp && SvROK(*old_svp)) {
            /* Replace _data with freshly decoded HV */
            (void)hv_stores(self_hv, "_data", newRV_noinc((SV *)new_data));
        } else {
            (void)hv_stores(self_hv, "_data", newRV_noinc((SV *)new_data));
        }
    }
    /* If new_data is NULL, we leave _data as-is (start fresh, already set in new) */
}

/* ============================================================================
 * Constructor helper — build default path from name
 * ============================================================================ */

static SV *
chandra_store_default_path(pTHX_ const char *name)
{
    const char *home = getenv("HOME");
    SV *path_sv;

    if (!home || !*home) {
        /* Fall back to getpwuid */
        struct passwd *pw = getpwuid(getuid());
        home = pw ? pw->pw_dir : "/tmp";
    }

    path_sv = newSVpvf("%s/.chandra/%s/store.json", home, name);
    return path_sv;
}

#endif /* CHANDRA_XS_IMPLEMENTATION */
#endif /* CHANDRA_STORE_H */
