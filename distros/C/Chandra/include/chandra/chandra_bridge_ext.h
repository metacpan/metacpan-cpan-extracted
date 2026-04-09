/*
 * chandra_bridge_ext.h — Bridge extension registry
 *
 * Manages named JavaScript extensions that are injected into the
 * bridge code under window.chandra.<name>.  Extensions may declare
 * dependencies on other extensions; injection order is resolved via
 * topological sort.
 *
 * Header-only: guarded by CHANDRA_XS_IMPLEMENTATION.
 */

#ifndef CHANDRA_BRIDGE_EXT_H
#define CHANDRA_BRIDGE_EXT_H

#ifdef CHANDRA_XS_IMPLEMENTATION

#include "EXTERN.h"
#include "perl.h"

/* ---- data structures ------------------------------------------------- */

typedef struct chandra_ext {
    char   *name;
    char   *source;
    char  **depends;
    int     dep_count;
    int     order;           /* insertion order for stable sort */
} chandra_ext_t;

/* simple dynamic array */
static chandra_ext_t *_ext_list  = NULL;
static int            _ext_count = 0;
static int            _ext_cap   = 0;
static int            _ext_order = 0;

/* reserved bridge property names */
static const char *_reserved_names[] = {
    "invoke", "call", "_resolve", "_event", "_eventData",
    "_callbacks", "_id", NULL
};

/* ---- helpers --------------------------------------------------------- */

static int
chandra_ext_is_reserved(const char *name)
{
    int i;
    for (i = 0; _reserved_names[i]; i++) {
        if (strcmp(name, _reserved_names[i]) == 0)
            return 1;
    }
    return 0;
}

static int
chandra_ext_find(const char *name)
{
    int i;
    for (i = 0; i < _ext_count; i++) {
        if (strcmp(_ext_list[i].name, name) == 0)
            return i;
    }
    return -1;
}

static void
chandra_ext_free_entry(chandra_ext_t *e)
{
    int i;
    Safefree(e->name);
    Safefree(e->source);
    for (i = 0; i < e->dep_count; i++)
        Safefree(e->depends[i]);
    Safefree(e->depends);
    e->name = NULL;
    e->source = NULL;
    e->depends = NULL;
    e->dep_count = 0;
}

/* ---- public API ------------------------------------------------------ */

static int
chandra_ext_register(pTHX_ const char *name, const char *source,
                     char **deps, int dep_count)
{
    int idx, i;
    chandra_ext_t *e;

    if (chandra_ext_is_reserved(name))
        croak("Chandra::Bridge::Extension: '%s' is a reserved bridge name", name);

    /* validate name: alphanumeric + underscore */
    {
        const char *p;
        for (p = name; *p; p++) {
            if (!isALNUM(*p))
                croak("Chandra::Bridge::Extension: invalid character in name '%s'", name);
        }
        if (p == name)
            croak("Chandra::Bridge::Extension: name must not be empty");
    }

    /* check deps exist (or will be registered later — we check at generation time) */

    idx = chandra_ext_find(name);
    if (idx >= 0) {
        /* overwrite existing */
        chandra_ext_free_entry(&_ext_list[idx]);
        e = &_ext_list[idx];
    } else {
        /* grow array if needed */
        if (_ext_count >= _ext_cap) {
            _ext_cap = _ext_cap ? _ext_cap * 2 : 8;
            Renew(_ext_list, _ext_cap, chandra_ext_t);
        }
        e = &_ext_list[_ext_count++];
    }

    e->name = savepv(name);
    e->source = savepv(source);
    e->order = _ext_order++;
    e->dep_count = dep_count;
    if (dep_count > 0) {
        Newx(e->depends, dep_count, char *);
        for (i = 0; i < dep_count; i++)
            e->depends[i] = savepv(deps[i]);
    } else {
        e->depends = NULL;
    }

    return 1;
}

static int
chandra_ext_unregister(const char *name)
{
    int idx = chandra_ext_find(name);
    if (idx < 0)
        return 0;

    chandra_ext_free_entry(&_ext_list[idx]);

    /* shift remaining entries down */
    if (idx < _ext_count - 1) {
        Move(&_ext_list[idx + 1], &_ext_list[idx],
             _ext_count - idx - 1, chandra_ext_t);
    }
    _ext_count--;
    return 1;
}

static void
chandra_ext_clear(void)
{
    int i;
    for (i = 0; i < _ext_count; i++)
        chandra_ext_free_entry(&_ext_list[i]);
    _ext_count = 0;
    _ext_order = 0;
}

static int
chandra_ext_is_registered(const char *name)
{
    return chandra_ext_find(name) >= 0;
}

static const char *
chandra_ext_source(const char *name)
{
    int idx = chandra_ext_find(name);
    if (idx < 0)
        return NULL;
    return _ext_list[idx].source;
}

/* ---- topological sort ------------------------------------------------ */

/*
 * Returns a Newx'd array of indices into _ext_list in dependency order.
 * Caller must Safefree.  Sets *out_count.  Returns NULL on error
 * (circular or missing dep), with *err_msg set (caller does NOT free err_msg —
 * it points to a static or already-allocated buffer).
 */
static int *
chandra_ext_topo_sort(pTHX_ int *out_count, const char **err_msg)
{
    int *result;
    int *in_degree;
    int *queue;
    int  front = 0, back = 0, count = 0;
    int  i, j;
    static char _err_buf[256];

    *out_count = 0;

    if (_ext_count == 0) {
        *out_count = 0;
        return NULL;
    }

    Newxz(in_degree, _ext_count, int);
    Newx(queue, _ext_count, int);
    Newx(result, _ext_count, int);

    /* compute in-degrees */
    for (i = 0; i < _ext_count; i++) {
        for (j = 0; j < _ext_list[i].dep_count; j++) {
            int dep_idx = chandra_ext_find(_ext_list[i].depends[j]);
            if (dep_idx < 0) {
                snprintf(_err_buf, sizeof(_err_buf),
                    "Chandra::Bridge::Extension: '%s' depends on unknown extension '%s'",
                    _ext_list[i].name, _ext_list[i].depends[j]);
                *err_msg = _err_buf;
                Safefree(in_degree);
                Safefree(queue);
                Safefree(result);
                return NULL;
            }
            in_degree[i]++;
        }
    }

    /* seed queue with zero-degree nodes (stable by insertion order) */
    for (i = 0; i < _ext_count; i++) {
        if (in_degree[i] == 0)
            queue[back++] = i;
    }

    /* BFS */
    while (front < back) {
        /* pick the queue entry with lowest insertion order for stability */
        int best = front;
        for (i = front + 1; i < back; i++) {
            if (_ext_list[queue[i]].order < _ext_list[queue[best]].order)
                best = i;
        }
        /* swap best to front */
        if (best != front) {
            int tmp = queue[front];
            queue[front] = queue[best];
            queue[best] = tmp;
        }

        int cur = queue[front++];
        result[count++] = cur;

        /* for each ext that depends on cur, decrement in-degree */
        for (i = 0; i < _ext_count; i++) {
            for (j = 0; j < _ext_list[i].dep_count; j++) {
                if (chandra_ext_find(_ext_list[i].depends[j]) == cur) {
                    in_degree[i]--;
                    if (in_degree[i] == 0)
                        queue[back++] = i;
                }
            }
        }
    }

    Safefree(in_degree);
    Safefree(queue);

    if (count != _ext_count) {
        *err_msg = "Chandra::Bridge::Extension: circular dependency detected";
        Safefree(result);
        return NULL;
    }

    *out_count = count;
    return result;
}

/* ---- JS generation --------------------------------------------------- */

/*
 * Build the extensions JS block.  Returns a new SV containing all
 * extension IIFEs in dependency order, or an empty string if none
 * registered.  Croaks on dependency errors.
 */
static SV *
chandra_ext_generate_js(pTHX)
{
    SV *out;
    int *order;
    int  count, i;
    const char *err = NULL;

    if (_ext_count == 0)
        return newSVpvn("", 0);

    order = chandra_ext_topo_sort(aTHX_ &count, &err);
    if (!order)
        croak("%s", err);

    out = newSVpvn("", 0);
    for (i = 0; i < count; i++) {
        chandra_ext_t *e = &_ext_list[order[i]];
        sv_catpvf(out,
            "\n(function() { window.chandra.%s = (function() {\n%s\n})(); })();",
            e->name, e->source);
    }

    Safefree(order);
    return out;
}

/*
 * Escape an SV's string content for safe eval_js injection.
 * Returns a new SV.
 */
static SV *
chandra_ext_escape_sv(pTHX_ SV *src_sv)
{
    STRLEN src_len;
    const char *src = SvPV(src_sv, src_len);
    SV *out = newSV(src_len * 2);
    char *dst = SvPVX(out);
    STRLEN dlen = 0;
    STRLEN i;

    for (i = 0; i < src_len; i++) {
        switch (src[i]) {
            case '\\': dst[dlen++] = '\\'; dst[dlen++] = '\\'; break;
            case '\'': dst[dlen++] = '\\'; dst[dlen++] = '\''; break;
            case '\n': dst[dlen++] = '\\'; dst[dlen++] = 'n';  break;
            case '\r': dst[dlen++] = '\\'; dst[dlen++] = 'r';  break;
            default:   dst[dlen++] = src[i]; break;
        }
    }
    dst[dlen] = '\0';
    SvCUR_set(out, dlen);
    SvPOK_on(out);
    return out;
}

#endif /* CHANDRA_XS_IMPLEMENTATION */
#endif /* CHANDRA_BRIDGE_EXT_H */
