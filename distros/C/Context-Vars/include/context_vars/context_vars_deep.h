#ifndef CONTEXT_VARS_DEEP_H
#define CONTEXT_VARS_DEEP_H

/* Deep context data: arrays, hashes, and whatever plain hashes and arrays a
 * variable holds at any depth.
 *
 * In a context, a plain hash is held as a HAMT map and a plain array as a
 * HAMT vector, at every level, as objects of two classes of this dist's own
 * so that a HAMT object a program stores is never mistaken for context data.
 * Blessed objects and code are never converted: they are kept as references
 * and shared, as their own classes expect.
 *
 * A change at any depth copies the nodes on the path from the variable down
 * to what changed - a few small nodes for each level - and stores the new top
 * under the variable's name through the variable's own rules, so that the
 * change belongs to the current context and every other context keeps what
 * it had. That is what makes "an assignment holds until the sub it is
 * written in returns" true of $seen{a}{b} as of $scalar.
 *
 * What a program reads is a PROXY: an array or hash tied to a path - the
 * variable's name and then each key or index - which it resolves against the
 * current context at each access.
 *
 * Names in the context: a scalar under its bare name, an array under "@name",
 * a hash under "%name". */

static void context_vars_var_put(pTHX_ const char *name, STRLEN len, SV *value);

#define CONTEXT_VARS_DEEP_MAX 4096     /* levels before a structure is called circular */

/* ---- nodes ------------------------------------------------------------------- */

static int context_vars_is_map(pTHX_ SV *v) {
    dMY_CXT;
    return v && SvROK(v) && SvOBJECT(SvRV(v)) && SvSTASH(SvRV(v)) == MY_CXT.map_stash;
}

static int context_vars_is_vec(pTHX_ SV *v) {
    dMY_CXT;
    return v && SvROK(v) && SvOBJECT(SvRV(v)) && SvSTASH(SvRV(v)) == MY_CXT.vec_stash;
}

/* Objects owning the struct, with one reference the caller owns. */
static SV *context_vars_map_sv(pTHX_ hamt_map *m) {
    if (!m) croak("Context::Vars: out of memory");
    return (CONTEXT_VARS_HAMT->map_to_sv)(aTHX_ m, "Context::Vars::Data::Map");
}

static SV *context_vars_vec_sv(pTHX_ hamt_vec *v) {
    if (!v) croak("Context::Vars: out of memory");
    return (CONTEXT_VARS_HAMT->vec_to_sv)(aTHX_ v, "Context::Vars::Data::Vector");
}

static void context_vars_ok(int status) {
    if (status != HAMT_ABI_OK) croak("Context::Vars: out of memory");
}

/* ---- proxies -------------------------------------------------------------------- */

/* A proxy's tie object is a blessed array: [ path, iteration state ], where the
 * path is an array of the variable's context name and each key or index. */
static AV *context_vars_proxy_path(pTHX_ SV *tieobj) {
    SV **p;
    if (!tieobj || !SvROK(tieobj) || SvTYPE(SvRV(tieobj)) != SVt_PVAV) return NULL;
    p = av_fetch((AV *)SvRV(tieobj), 0, 0);
    return (p && SvROK(*p) && SvTYPE(SvRV(*p)) == SVt_PVAV) ? (AV *)SvRV(*p) : NULL;
}

/* The tie object of a container tied to one of our proxies, or NULL. */
static SV *context_vars_proxy_of_container(pTHX_ SV *container) {
    dMY_CXT;
    MAGIC *mg;
    if (!container || !SvRMAGICAL(container)) return NULL;
    mg = mg_find(container, PERL_MAGIC_tied);
    if (!mg || !mg->mg_obj || !SvROK(mg->mg_obj) || !SvOBJECT(SvRV(mg->mg_obj))) return NULL;
    if (SvSTASH(SvRV(mg->mg_obj)) != MY_CXT.hash_stash
        && SvSTASH(SvRV(mg->mg_obj)) != MY_CXT.array_stash) return NULL;
    return mg->mg_obj;
}

/* The path behind a reference to one of our proxies, or NULL. */
static AV *context_vars_proxy_ref_path(pTHX_ SV *v) {
    SV *obj;
    if (!v || !SvROK(v) || SvOBJECT(SvRV(v))) return NULL;
    if (SvTYPE(SvRV(v)) != SVt_PVHV && SvTYPE(SvRV(v)) != SVt_PVAV) return NULL;
    obj = context_vars_proxy_of_container(aTHX_ SvRV(v));
    return obj ? context_vars_proxy_path(aTHX_ obj) : NULL;
}

/* Ties `container` to a proxy for `path`, which it takes over. */
static void context_vars_tie(pTHX_ SV *container, AV *path) {
    dMY_CXT;
    AV *state = newAV();
    SV *obj;
    av_push(state, newRV_noinc((SV *)path));
    obj = newRV_noinc((SV *)state);
    sv_bless(obj, SvTYPE(container) == SVt_PVHV ? MY_CXT.hash_stash : MY_CXT.array_stash);
    sv_magic(container, obj, PERL_MAGIC_tied, NULL, 0);
    SvREFCNT_dec(obj);
}

/* A new path: `base` followed by `key`. */
static AV *context_vars_path_plus(pTHX_ AV *base, SV *key) {
    AV *p = newAV();
    I32 i, n = av_len(base) + 1;
    av_extend(p, n);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(base, i, 0);
        av_push(p, newSVsv(e ? *e : &PL_sv_undef));
    }
    if (key) av_push(p, newSVsv(key));
    return p;
}

/* ---- reading a path ---------------------------------------------------------- */

static SV *context_vars_node_get(pTHX_ SV *node, SV *key) {
    if (context_vars_is_map(aTHX_ node)) {
        STRLEN klen;
        const char *k = SvPV(key, klen);
        return (CONTEXT_VARS_HAMT->map_fetch)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ node),
                                              k, klen, SvUTF8(key) ? 1 : 0);
    }
    if (context_vars_is_vec(aTHX_ node)) {
        IV i = SvIV(key);
        if (i < 0) return NULL;
        return (CONTEXT_VARS_HAMT->vec_fetch)(aTHX_ (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ node), (size_t)i);
    }
    return NULL;
}

/* What is at a path in the current context, borrowed, or NULL. */
static SV *context_vars_path_get(pTHX_ AV *path) {
    I32 i, n = av_len(path) + 1;
    SV **name = av_fetch(path, 0, 0);
    STRLEN len;
    const char *p;
    SV *node;
    if (!name) return NULL;
    p = SvPV(*name, len);
    node = context_vars_fetch(aTHX_ p, len);
    for (i = 1; i < n && node; i++) {
        SV **key = av_fetch(path, i, 0);
        node = key ? context_vars_node_get(aTHX_ node, *key) : NULL;
    }
    return node;
}

/* ---- conversion -------------------------------------------------------------- */

static SV *context_vars_in_depth(pTHX_ SV *v, int depth);

/* A plain hash or array, at any depth, as nodes; a proxy as the node it shows;
 * anything else is NULL, meaning "store it as it is". The result has one
 * reference the caller owns. */
static SV *context_vars_in(pTHX_ SV *v) {
    return context_vars_in_depth(aTHX_ v, 0);
}

static SV *context_vars_in_depth(pTHX_ SV *v, int depth) {
    SV *ref;
    AV *ppath;
    if (!v || !SvROK(v)) return NULL;
    ref = SvRV(v);
    if (SvOBJECT(ref)) return NULL;
    if (depth > CONTEXT_VARS_DEEP_MAX)
        croak("Context::Vars: a structure nested more than %d deep, or one that contains itself",
              CONTEXT_VARS_DEEP_MAX);

    if ((ppath = context_vars_proxy_ref_path(aTHX_ v))) {
        SV *node = context_vars_path_get(aTHX_ ppath);
        return node ? newSVsv(node) : NULL;
    }
    if (SvTYPE(ref) == SVt_PVHV) {
        HV *hv = (HV *)ref;
        hamt_map *m = (CONTEXT_VARS_HAMT->map_new)(aTHX);
        HE *he;
        if (!m) croak("Context::Vars: out of memory");
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            STRLEN klen;
            const char *k = HePV(he, klen);
            SV *val = hv_iterval(hv, he);
            SV *child = context_vars_in_depth(aTHX_ val, depth + 1);
            context_vars_ok((CONTEXT_VARS_HAMT->map_store)(aTHX_ m, k, klen, HeUTF8(he) ? 1 : 0,
                                                           child ? child : val));
            if (child) SvREFCNT_dec(child);
        }
        return context_vars_map_sv(aTHX_ m);
    }
    if (SvTYPE(ref) == SVt_PVAV) {
        AV *av = (AV *)ref;
        I32 i, n = av_len(av) + 1;
        hamt_vec *vv = (CONTEXT_VARS_HAMT->vec_new)(aTHX);
        if (!vv) croak("Context::Vars: out of memory");
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            SV *val = e ? *e : &PL_sv_undef;
            SV *child = context_vars_in_depth(aTHX_ val, depth + 1);
            context_vars_ok((CONTEXT_VARS_HAMT->vec_push)(aTHX_ vv, child ? child : val));
            if (child) SvREFCNT_dec(child);
        }
        return context_vars_vec_sv(aTHX_ vv);
    }
    return NULL;
}

/* What a program reads at `path`: a node as a proxy for that path (taking the
 * path over), anything else as it is. Mortal, or the borrowed value itself. */
static SV *context_vars_out(pTHX_ SV *val, AV *path) {
    if (context_vars_is_map(aTHX_ val)) {
        HV *hv = newHV();
        context_vars_tie(aTHX_ (SV *)hv, path);
        return sv_2mortal(newRV_noinc((SV *)hv));
    }
    if (context_vars_is_vec(aTHX_ val)) {
        AV *av = newAV();
        context_vars_tie(aTHX_ (SV *)av, path);
        return sv_2mortal(newRV_noinc((SV *)av));
    }
    SvREFCNT_dec((SV *)path);
    return val ? val : &PL_sv_undef;
}

static int context_vars_plain_cb(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value);
static SV *context_vars_plain(pTHX_ SV *val);

/* A node as a plain, unshared copy - for what is taken out of a structure,
 * popped, shifted, spliced or deleted, which no longer has a path to proxy. */
static SV *context_vars_plain(pTHX_ SV *val) {
    if (context_vars_is_map(aTHX_ val)) {
        HV *hv = newHV();
        (CONTEXT_VARS_HAMT->map_walk)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ val),
                                      context_vars_plain_cb, hv);
        return newRV_noinc((SV *)hv);
    }
    if (context_vars_is_vec(aTHX_ val)) {
        const hamt_vec *v = (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ val);
        size_t i, n = (CONTEXT_VARS_HAMT->vec_count)(aTHX_ v);
        AV *av = newAV();
        av_extend(av, (I32)n);
        for (i = 0; i < n; i++)
            av_push(av, context_vars_plain(aTHX_ (CONTEXT_VARS_HAMT->vec_fetch)(aTHX_ v, i)));
        return newRV_noinc((SV *)av);
    }
    return val ? newSVsv(val) : newSV(0);
}

static int context_vars_plain_cb(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    (void)hv_store((HV *)ud, key, utf8 ? -(I32)klen : (I32)klen, context_vars_plain(aTHX_ value), 0);
    return 0;
}

/* ---- small helpers for the proxies ----------------------------------------------- */

static int context_vars_keys_cb(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    SV *k = newSVpvn(key, klen);
    PERL_UNUSED_ARG(value);
    if (utf8) SvUTF8_on(k);
    av_push((AV *)ud, k);
    return 0;
}

static size_t context_vars_vec_len(pTHX_ SV *node) {
    return context_vars_is_vec(aTHX_ node)
         ? (CONTEXT_VARS_HAMT->vec_count)(aTHX_ (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ node)) : 0;
}

/* A struct of the caller's own onto the vector at `node`, or an empty one. */
static hamt_vec *context_vars_vec_dup(pTHX_ SV *node) {
    hamt_vec *v = context_vars_is_vec(aTHX_ node)
        ? (CONTEXT_VARS_HAMT->vec_copy)(aTHX_ (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ node))
        : (CONTEXT_VARS_HAMT->vec_new)(aTHX);
    if (!v) croak("Context::Vars: out of memory");
    return v;
}

/* A new vector of the `n` values at `args`, converted as stored values are. */
static hamt_vec *context_vars_vec_of_args(pTHX_ SV **args, I32 n) {
    hamt_vec *v = (CONTEXT_VARS_HAMT->vec_new)(aTHX);
    I32 i;
    if (!v) croak("Context::Vars: out of memory");
    for (i = 0; i < n; i++) {
        SV *conv = context_vars_in(aTHX_ args[i]);
        context_vars_ok((CONTEXT_VARS_HAMT->vec_push)(aTHX_ v, conv ? conv : args[i]));
        if (conv) SvREFCNT_dec(conv);
    }
    return v;
}

static void context_vars_path_put(pTHX_ AV *path, SV *node);

/* An array proxy below the top whose array is not there - cleared away, or
 * replaced by something else - gets an empty one first, so that a store into
 * it does not make a hash. */
static void context_vars_vec_ensure(pTHX_ AV *path) {
    if (av_len(path) > 0 && !context_vars_is_vec(aTHX_ context_vars_path_get(aTHX_ path)))
        context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ (CONTEXT_VARS_HAMT->vec_new)(aTHX)));
}

/* ---- writing a path ---------------------------------------------------------- */

/* Puts `node` - owned by the caller, or NULL to remove what is there - at
 * `path` in the current context, copying every level above it. A level that
 * is not there is made: the root by its sigil, anything deeper as a hash, or
 * as an array when its key is the index of an array proxy (`kinds`). */
static void context_vars_path_put(pTHX_ AV *path, SV *node) {
    I32 n = av_len(path) + 1, depth;
    SV **name = av_fetch(path, 0, 0);
    SV **parents;
    STRLEN len;
    const char *p;
    SV *child = node;

    if (!name) croak("Context::Vars: internal error: an empty path");
    p = SvPV(*name, len);

    Newx(parents, n, SV *);
    SAVEFREEPV(parents);
    parents[0] = context_vars_fetch(aTHX_ p, len);
    for (depth = 1; depth < n - 1; depth++) {
        SV **key = av_fetch(path, depth, 0);
        parents[depth] = parents[depth - 1] && key
                       ? context_vars_node_get(aTHX_ parents[depth - 1], *key) : NULL;
    }

    for (depth = n - 2; depth >= 0; depth--) {
        SV *parent = parents[depth];
        SV **keyp = av_fetch(path, depth + 1, 0);
        SV *key = keyp ? *keyp : &PL_sv_undef;
        SV *made;
        int as_vec = context_vars_is_vec(aTHX_ parent)
                  || (!context_vars_is_map(aTHX_ parent) && depth == 0 && p[0] == '@');

        if (as_vec) {
            hamt_vec *v = context_vars_is_vec(aTHX_ parent)
                ? (CONTEXT_VARS_HAMT->vec_copy)(aTHX_ (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ parent))
                : (CONTEXT_VARS_HAMT->vec_new)(aTHX);
            IV i = SvIV(key);
            if (!v) croak("Context::Vars: out of memory");
            if (i < 0) croak("Context::Vars: a negative index below the start of an array");
            while ((IV)(CONTEXT_VARS_HAMT->vec_count)(aTHX_ v) <= i)
                context_vars_ok((CONTEXT_VARS_HAMT->vec_push)(aTHX_ v, &PL_sv_undef));
            context_vars_ok((CONTEXT_VARS_HAMT->vec_store)(aTHX_ v, (size_t)i,
                                                          child ? child : &PL_sv_undef));
            made = context_vars_vec_sv(aTHX_ v);
        }
        else {
            STRLEN klen;
            const char *k = SvPV(key, klen);
            hamt_map *m = context_vars_is_map(aTHX_ parent)
                ? (CONTEXT_VARS_HAMT->map_copy)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ parent))
                : (CONTEXT_VARS_HAMT->map_new)(aTHX);
            if (!m) croak("Context::Vars: out of memory");
            if (child)
                context_vars_ok((CONTEXT_VARS_HAMT->map_store)(aTHX_ m, k, klen, SvUTF8(key) ? 1 : 0, child));
            else
                context_vars_ok((CONTEXT_VARS_HAMT->map_remove)(aTHX_ m, k, klen, SvUTF8(key) ? 1 : 0));
            made = context_vars_map_sv(aTHX_ m);
        }
        if (child) SvREFCNT_dec(child);
        child = made;
    }

    context_vars_var_put(aTHX_ p, len, child);
    if (child) SvREFCNT_dec(child);
}

/* ---- autovivification on old perls ------------------------------------------ */

/* perl 5.14 and older vivify through a tied hash or array by making a plain
 * container, storing it, and then writing into THAT container. So a fresh,
 * empty, plain container stored at `path` - one nothing else holds - is tied
 * in place to a proxy for the path, and the write that follows goes through
 * it. A container something else holds is left alone. */
static int context_vars_is_fresh(pTHX_ SV *v) {
    SV *c;
    if (!v || !SvROK(v)) return 0;
    c = SvRV(v);
    if (SvOBJECT(c) || SvREFCNT(c) != 1 || SvRMAGICAL(c)) return 0;
    if (SvTYPE(c) == SVt_PVHV) return HvUSEDKEYS((HV *)c) == 0;
    if (SvTYPE(c) == SVt_PVAV) return av_len((AV *)c) < 0;
    return 0;
}

static void context_vars_tie_fresh(pTHX_ SV *v, AV *path) {
    if (context_vars_is_fresh(aTHX_ v))
        context_vars_tie(aTHX_ SvRV(v), context_vars_path_plus(aTHX_ path, NULL));
}

/* ---- local on a whole container --------------------------------------------- */

/* `local %name` and `local @name` make a new container for the glob, and
 * perl does NOT carry a tie over to it: left alone, the local container would
 * be a plain one, seen only through this package's glob and never by another
 * package, a capture or a callback. So this ext magic's local hook ties the
 * new container to the same path, copies the mark, and keeps the context's
 * value of the variable to put back when the local ends. */
typedef struct { SV *name; SV *value; } context_vars_local_rec;

static void context_vars_local_restore(pTHX_ void *p) {
    context_vars_local_rec *r = (context_vars_local_rec *)p;
    STRLEN len;
    const char *n = SvPV(r->name, len);
    context_vars_var_put(aTHX_ n, len, r->value);
    SvREFCNT_dec(r->name);
    if (r->value) SvREFCNT_dec(r->value);
    Safefree(r);
}

static int context_vars_container_local(pTHX_ SV *nsv, MAGIC *mg);
static MGVTBL context_vars_container_vtbl = { 0, 0, 0, 0, 0, 0, 0, context_vars_container_local };

static void context_vars_mark_container(pTHX_ SV *container, const char *name, STRLEN len) {
    MAGIC *mg = sv_magicext(container, NULL, PERL_MAGIC_ext, &context_vars_container_vtbl, name, (I32)len);
    mg->mg_flags |= MGf_LOCAL;
}

static int context_vars_container_local(pTHX_ SV *nsv, MAGIC *mg) {
    context_vars_local_rec *r;
    SV *held = context_vars_fetch(aTHX_ mg->mg_ptr, (STRLEN)mg->mg_len);
    Newx(r, 1, context_vars_local_rec);
    r->name  = newSVpvn(mg->mg_ptr, mg->mg_len);
    r->value = held ? newSVsv(held) : NULL;
    SAVEDESTRUCTOR_X(context_vars_local_restore, r);
    {
        AV *path = newAV();
        av_push(path, newSVpvn(mg->mg_ptr, mg->mg_len));
        context_vars_tie(aTHX_ nsv, path);
    }
    context_vars_mark_container(aTHX_ nsv, mg->mg_ptr, (STRLEN)mg->mg_len);
    return 0;
}

#endif
