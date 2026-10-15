# The proxies a program sees for a context array or hash, and for every
# plain hash or array inside a context variable. Each is tied to a path,
# resolved against the current context at each access; every change copies
# the levels above it and stores the new top through the variable's rules.

MODULE = Context::Vars    PACKAGE = Context::Vars::Hash

void
FETCH(self, key)
        SV *self
        SV *key
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = path ? context_vars_path_get(aTHX_ path) : NULL;
        SV *val  = node ? context_vars_node_get(aTHX_ node, key) : NULL;
        XPUSHs(val ? context_vars_out(aTHX_ val, context_vars_path_plus(aTHX_ path, key)) : &PL_sv_undef);
    }

void
STORE(self, key, value)
        SV *self
        SV *key
        SV *value
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        AV *at   = context_vars_path_plus(aTHX_ path, key);
        SV *conv;
        SAVEFREESV((SV *)at);
        conv = context_vars_in(aTHX_ value);
        context_vars_path_put(aTHX_ at, conv ? conv : newSVsv(value));
        context_vars_tie_fresh(aTHX_ value, at);
    }

void
DELETE(self, key)
        SV *self
        SV *key
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        SV *old  = node ? context_vars_node_get(aTHX_ node, key) : NULL;
        SV *ret  = old ? sv_2mortal(context_vars_plain(aTHX_ old)) : &PL_sv_undef;
        if (old) {
            AV *at = context_vars_path_plus(aTHX_ path, key);
            SAVEFREESV((SV *)at);
            context_vars_path_put(aTHX_ at, NULL);
        }
        XPUSHs(ret);
    }

void
CLEAR(self)
        SV *self
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        context_vars_path_put(aTHX_ path, context_vars_map_sv(aTHX_ (CONTEXT_VARS_HAMT->map_new)(aTHX)));
    }

int
EXISTS(self, key)
        SV *self
        SV *key
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        STRLEN klen;
        const char *k = SvPV(key, klen);
        RETVAL = context_vars_is_map(aTHX_ node)
               ? (CONTEXT_VARS_HAMT->map_has)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ node),
                                              k, klen, SvUTF8(key) ? 1 : 0)
               : 0;
    }
    OUTPUT:
        RETVAL

# Iteration walks the keys as they were when it began.
void
FIRSTKEY(self)
        SV *self
    PPCODE:
    {
        AV *state = (AV *)SvRV(self);
        AV *path  = context_vars_proxy_path(aTHX_ self);
        SV *node  = context_vars_path_get(aTHX_ path);
        AV *keys  = newAV();
        SV *first;
        if (context_vars_is_map(aTHX_ node))
            (CONTEXT_VARS_HAMT->map_walk)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ node),
                                          context_vars_keys_cb, keys);
        av_store(state, 1, newRV_noinc((SV *)keys));
        first = av_shift(keys);
        XPUSHs(first == &PL_sv_undef ? first : sv_2mortal(first));
    }

void
NEXTKEY(self, last)
        SV *self
        SV *last
    PPCODE:
    {
        SV **kp = av_fetch((AV *)SvRV(self), 1, 0);
        SV *next = (kp && SvROK(*kp)) ? av_shift((AV *)SvRV(*kp)) : &PL_sv_undef;
        PERL_UNUSED_VAR(last);
        XPUSHs(next == &PL_sv_undef ? next : sv_2mortal(next));
    }

IV
SCALAR(self)
        SV *self
    CODE:
    {
        SV *node = context_vars_path_get(aTHX_ context_vars_proxy_path(aTHX_ self));
        RETVAL = context_vars_is_map(aTHX_ node)
               ? (IV)(CONTEXT_VARS_HAMT->map_count)(aTHX_ (CONTEXT_VARS_HAMT->map_from_sv)(aTHX_ node))
               : 0;
    }
    OUTPUT:
        RETVAL

MODULE = Context::Vars    PACKAGE = Context::Vars::Array

IV
FETCHSIZE(self)
        SV *self
    CODE:
        RETVAL = (IV)context_vars_vec_len(aTHX_ context_vars_path_get(aTHX_ context_vars_proxy_path(aTHX_ self)));
    OUTPUT:
        RETVAL

void
FETCH(self, index)
        SV *self
        SV *index
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        SV *val  = context_vars_is_vec(aTHX_ node) ? context_vars_node_get(aTHX_ node, index) : NULL;
        XPUSHs(val ? context_vars_out(aTHX_ val, context_vars_path_plus(aTHX_ path, index)) : &PL_sv_undef);
    }

void
STORE(self, index, value)
        SV *self
        SV *index
        SV *value
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        AV *at   = context_vars_path_plus(aTHX_ path, index);
        SV *conv;
        SAVEFREESV((SV *)at);
        conv = context_vars_in(aTHX_ value);
        context_vars_vec_ensure(aTHX_ path);
        context_vars_path_put(aTHX_ at, conv ? conv : newSVsv(value));
        context_vars_tie_fresh(aTHX_ value, at);
    }

int
EXISTS(self, index)
        SV *self
        SV *index
    CODE:
    {
        IV i = SvIV(index);
        RETVAL = i >= 0 && (size_t)i < context_vars_vec_len(aTHX_
                     context_vars_path_get(aTHX_ context_vars_proxy_path(aTHX_ self)));
    }
    OUTPUT:
        RETVAL

void
DELETE(self, index)
        SV *self
        SV *index
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        SV *old  = context_vars_is_vec(aTHX_ node) ? context_vars_node_get(aTHX_ node, index) : NULL;
        SV *ret  = old ? sv_2mortal(context_vars_plain(aTHX_ old)) : &PL_sv_undef;
        if (old) {
            AV *at = context_vars_path_plus(aTHX_ path, index);
            SAVEFREESV((SV *)at);
            context_vars_path_put(aTHX_ at, newSV(0));
        }
        XPUSHs(ret);
    }

void
CLEAR(self)
        SV *self
    CODE:
        context_vars_path_put(aTHX_ context_vars_proxy_path(aTHX_ self),
                              context_vars_vec_sv(aTHX_ (CONTEXT_VARS_HAMT->vec_new)(aTHX)));

void
EXTEND(self, n)
        SV *self
        SV *n
    CODE:
        PERL_UNUSED_VAR(self);
        PERL_UNUSED_VAR(n);

void
STORESIZE(self, n)
        SV *self
        IV n
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        hamt_vec *v = context_vars_vec_dup(aTHX_ node);
        size_t want = n < 0 ? 0 : (size_t)n;
        size_t have = (CONTEXT_VARS_HAMT->vec_count)(aTHX_ v);
        if (want < have) {
            int st = HAMT_ABI_OK;
            hamt_vec *cut = (CONTEXT_VARS_HAMT->vec_slice)(aTHX_ v, 0, want, &st);
            (CONTEXT_VARS_HAMT->vec_release)(aTHX_ v);
            if (!cut) croak("Context::Vars: out of memory");
            v = cut;
        }
        while ((CONTEXT_VARS_HAMT->vec_count)(aTHX_ v) < want)
            context_vars_ok((CONTEXT_VARS_HAMT->vec_push)(aTHX_ v, &PL_sv_undef));
        context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ v));
    }

IV
PUSH(self, ...)
        SV *self
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        hamt_vec *v = context_vars_vec_dup(aTHX_ context_vars_path_get(aTHX_ path));
        I32 i;
        for (i = 1; i < items; i++) {
            SV *conv = context_vars_in(aTHX_ ST(i));
            context_vars_ok((CONTEXT_VARS_HAMT->vec_push)(aTHX_ v, conv ? conv : ST(i)));
            if (conv) SvREFCNT_dec(conv);
        }
        RETVAL = (IV)(CONTEXT_VARS_HAMT->vec_count)(aTHX_ v);
        context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ v));
    }
    OUTPUT:
        RETVAL

void
POP(self)
        SV *self
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        size_t n = context_vars_vec_len(aTHX_ node);
        SV *ret = &PL_sv_undef;
        if (n) {
            hamt_vec *v;
            ret = sv_2mortal(context_vars_plain(aTHX_ context_vars_node_get(aTHX_ node, sv_2mortal(newSVuv(n - 1)))));
            v = context_vars_vec_dup(aTHX_ node);
            context_vars_ok((CONTEXT_VARS_HAMT->vec_pop)(aTHX_ v));
            context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ v));
        }
        XPUSHs(ret);
    }

void
SHIFT(self)
        SV *self
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        SV *ret = &PL_sv_undef;
        if (context_vars_vec_len(aTHX_ node)) {
            int st = HAMT_ABI_OK;
            hamt_vec *rest;
            ret = sv_2mortal(context_vars_plain(aTHX_ context_vars_node_get(aTHX_ node, sv_2mortal(newSViv(0)))));
            rest = (CONTEXT_VARS_HAMT->vec_remove)(aTHX_ (CONTEXT_VARS_HAMT->vec_from_sv)(aTHX_ node), 0, 1, &st);
            if (!rest) croak("Context::Vars: out of memory");
            context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ rest));
        }
        XPUSHs(ret);
    }

IV
UNSHIFT(self, ...)
        SV *self
    CODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        hamt_vec *mid = context_vars_vec_of_args(aTHX_ &ST(1), items - 1);
        hamt_vec *cur = context_vars_vec_dup(aTHX_ node);
        int st = HAMT_ABI_OK;
        hamt_vec *joined = (CONTEXT_VARS_HAMT->vec_insert)(aTHX_ cur, 0, mid, &st);
        (CONTEXT_VARS_HAMT->vec_release)(aTHX_ cur);
        (CONTEXT_VARS_HAMT->vec_release)(aTHX_ mid);
        if (!joined) croak("Context::Vars: out of memory");
        RETVAL = (IV)(CONTEXT_VARS_HAMT->vec_count)(aTHX_ joined);
        context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ joined));
    }
    OUTPUT:
        RETVAL

void
SPLICE(self, ...)
        SV *self
    PPCODE:
    {
        AV *path = context_vars_proxy_path(aTHX_ self);
        SV *node = context_vars_path_get(aTHX_ path);
        IV size = (IV)context_vars_vec_len(aTHX_ node);
        IV off  = items > 1 && SvOK(ST(1)) ? SvIV(ST(1)) : 0;
        IV len;
        I32 i, nnew = items > 3 ? items - 3 : 0;
        hamt_vec *cur, *cut, *mid, *joined;
        AV *gone = (AV *)sv_2mortal((SV *)newAV());
        int st = HAMT_ABI_OK;
        I32 gimme = GIMME_V;

        if (off < 0) off += size;
        if (off < 0) croak("Modification of non-creatable array value attempted, subscript %" IVdf, off - size);
        if (off > size) off = size;
        len = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : size - off;
        if (len < 0) len = size - off + len;
        if (len < 0) len = 0;
        if (off + len > size) len = size - off;

        for (i = 0; i < len; i++)
            av_push(gone, context_vars_plain(aTHX_ context_vars_node_get(aTHX_ node, sv_2mortal(newSViv(off + i)))));

        mid = context_vars_vec_of_args(aTHX_ &ST(3), nnew);
        cur = context_vars_vec_dup(aTHX_ node);
        cut = (CONTEXT_VARS_HAMT->vec_remove)(aTHX_ cur, (size_t)off, (size_t)len, &st);
        (CONTEXT_VARS_HAMT->vec_release)(aTHX_ cur);
        if (!cut) croak("Context::Vars: out of memory");
        joined = nnew ? (CONTEXT_VARS_HAMT->vec_insert)(aTHX_ cut, (size_t)off, mid, &st) : NULL;
        if (nnew) {
            (CONTEXT_VARS_HAMT->vec_release)(aTHX_ cut);
            if (!joined) croak("Context::Vars: out of memory");
        }
        else joined = cut;
        (CONTEXT_VARS_HAMT->vec_release)(aTHX_ mid);
        context_vars_path_put(aTHX_ path, context_vars_vec_sv(aTHX_ joined));

        if (gimme == G_ARRAY) {
            EXTEND(SP, len);
            for (i = 0; i < len; i++) PUSHs(*av_fetch(gone, i, 0));
        }
        else {
            XPUSHs(len ? *av_fetch(gone, len - 1, 0) : &PL_sv_undef);
        }
    }
