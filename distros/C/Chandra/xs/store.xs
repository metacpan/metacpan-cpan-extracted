MODULE = Chandra    PACKAGE = Chandra::Store

PROTOTYPES: DISABLE

 # ---- new(class, name => ...|path => ..., [auto_save => 1]) ----

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv  = newHV();
    SV *path_sv  = NULL;
    int auto_save = 1;
    int i;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "path")) {
            path_sv = newSVsv(ST(i + 1));
        } else if (strEQ(key, "name")) {
            path_sv = chandra_store_default_path(aTHX_ SvPV_nolen(ST(i + 1)));
        } else if (strEQ(key, "auto_save")) {
            auto_save = SvTRUE(ST(i + 1)) ? 1 : 0;
        }
    }

    if (!path_sv)
        croak("Chandra::Store->new: 'name' or 'path' is required");

    (void)hv_stores(self_hv, "_path",      path_sv);
    (void)hv_stores(self_hv, "_data",      newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_auto_save", newSViv(auto_save));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
                      gv_stashpv(class, GV_ADD));

    chandra_store_reload_c(aTHX_ self_hv);
}
OUTPUT:
    RETVAL

 # ---- get(self, key [, default]) ----

SV *
get(self, key, ...)
    SV *self
    SV *key
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    SV  *def      = (items > 2) ? ST(2) : &PL_sv_undef;
    HV  *data_hv;
    const char *key_str;
    STRLEN key_len;
    SV  *leaf_sv  = NULL;
    int  not_hash = 0;
    HV  *parent;

    if (!data_svp || !SvROK(*data_svp)) {
        RETVAL = SvREFCNT_inc(def);
        goto done_get;
    }
    data_hv = (HV *)SvRV(*data_svp);

    key_str = SvPV(key, key_len);
    parent  = chandra_store_traverse(aTHX_ data_hv, key_str, key_len,
                                     0, &leaf_sv, &not_hash);
    if (!parent || !leaf_sv) {
        RETVAL = SvREFCNT_inc(def);
        goto done_get;
    }

    {
        STRLEN llen;
        const char *lstr = SvPV(leaf_sv, llen);
        SV **val_svp = hv_fetch(parent, lstr, (I32)llen, 0);
        RETVAL = val_svp ? SvREFCNT_inc(*val_svp) : SvREFCNT_inc(def);
    }
    done_get: ;
}
OUTPUT:
    RETVAL

 # ---- set(self, key, value) — returns self ----

SV *
set(self, key, value)
    SV *self
    SV *key
    SV *value
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    SV **as_svp   = hv_fetchs(self_hv, "_auto_save", 0);
    HV  *data_hv;
    const char *key_str;
    STRLEN key_len;
    SV  *leaf_sv  = NULL;
    int  not_hash = 0;
    HV  *parent;

    if (!data_svp || !SvROK(*data_svp))
        croak("Chandra::Store: internal error: _data missing");
    data_hv = (HV *)SvRV(*data_svp);

    key_str = SvPV(key, key_len);
    parent  = chandra_store_traverse(aTHX_ data_hv, key_str, key_len,
                                     1, &leaf_sv, &not_hash);
    if (!parent) {
        if (not_hash)
            croak("Chandra::Store: intermediate key is not a hash");
        croak("Chandra::Store: cannot traverse path '%s'", key_str);
    }

    {
        STRLEN llen;
        const char *lstr = SvPV(leaf_sv, llen);
        (void)hv_store(parent, lstr, (I32)llen, SvREFCNT_inc(value), 0);
    }

    if (as_svp && SvTRUE(*as_svp))
        chandra_store_save_c(aTHX_ self_hv);

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- has(self, key) — returns 0 or 1 ----

int
has(self, key)
    SV *self
    SV *key
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    HV  *data_hv;
    const char *key_str;
    STRLEN key_len;
    SV  *leaf_sv  = NULL;
    int  not_hash = 0;
    HV  *parent;

    RETVAL = 0;
    if (!data_svp || !SvROK(*data_svp)) goto done_has;
    data_hv = (HV *)SvRV(*data_svp);

    key_str = SvPV(key, key_len);
    parent  = chandra_store_traverse(aTHX_ data_hv, key_str, key_len,
                                     0, &leaf_sv, &not_hash);
    if (!parent || !leaf_sv) goto done_has;

    {
        STRLEN llen;
        const char *lstr = SvPV(leaf_sv, llen);
        RETVAL = hv_fetch(parent, lstr, (I32)llen, 0) ? 1 : 0;
    }
    done_has: ;
}
OUTPUT:
    RETVAL

 # ---- delete(self, key) — returns self ----

SV *
delete(self, key)
    SV *self
    SV *key
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    SV **as_svp   = hv_fetchs(self_hv, "_auto_save", 0);
    HV  *data_hv;
    const char *key_str;
    STRLEN key_len;
    SV  *leaf_sv  = NULL;
    int  not_hash = 0;
    HV  *parent;
    int  did_delete = 0;

    if (!data_svp || !SvROK(*data_svp)) goto done_del;
    data_hv = (HV *)SvRV(*data_svp);

    key_str = SvPV(key, key_len);
    parent  = chandra_store_traverse(aTHX_ data_hv, key_str, key_len,
                                     0, &leaf_sv, &not_hash);
    if (parent && leaf_sv) {
        STRLEN llen;
        const char *lstr = SvPV(leaf_sv, llen);
        SV *removed = hv_delete(parent, lstr, (I32)llen, 0);
        if (removed) did_delete = 1;
    }

    if (did_delete && as_svp && SvTRUE(*as_svp))
        chandra_store_save_c(aTHX_ self_hv);

    done_del: ;
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- set_many(self, \%pairs) — returns self ----

SV *
set_many(self, pairs_sv)
    SV *self
    SV *pairs_sv
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    SV **as_svp   = hv_fetchs(self_hv, "_auto_save", 0);
    HV  *data_hv;
    HV  *pairs_hv;
    HE  *he;

    if (!SvROK(pairs_sv) || SvTYPE(SvRV(pairs_sv)) != SVt_PVHV)
        croak("Chandra::Store::set_many: argument must be a hashref");
    if (!data_svp || !SvROK(*data_svp))
        croak("Chandra::Store: internal error: _data missing");

    data_hv  = (HV *)SvRV(*data_svp);
    pairs_hv = (HV *)SvRV(pairs_sv);

    hv_iterinit(pairs_hv);
    while ((he = hv_iternext(pairs_hv))) {
        STRLEN klen;
        const char *kstr = HePV(he, klen);
        SV  *val      = HeVAL(he);
        SV  *leaf_sv  = NULL;
        int  not_hash = 0;
        HV  *parent   = chandra_store_traverse(aTHX_ data_hv, kstr, klen,
                                                1, &leaf_sv, &not_hash);
        if (!parent) {
            if (not_hash)
                croak("Chandra::Store::set_many: intermediate key '%s' is not a hash",
                      kstr);
            croak("Chandra::Store::set_many: cannot traverse path '%s'", kstr);
        }
        {
            STRLEN llen;
            const char *lstr = SvPV(leaf_sv, llen);
            (void)hv_store(parent, lstr, (I32)llen, SvREFCNT_inc(val), 0);
        }
    }

    if (as_svp && SvTRUE(*as_svp))
        chandra_store_save_c(aTHX_ self_hv);

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- all(self) — returns \%data ----

SV *
all(self)
    SV *self
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(self_hv, "_data", 0);
    if (data_svp && SvROK(*data_svp)) {
        RETVAL = SvREFCNT_inc(*data_svp);
    } else {
        RETVAL = newRV_noinc((SV *)newHV());
    }
}
OUTPUT:
    RETVAL

 # ---- clear(self) — returns self ----

SV *
clear(self)
    SV *self
CODE:
{
    HV  *self_hv = (HV *)SvRV(self);
    SV **as_svp  = hv_fetchs(self_hv, "_auto_save", 0);
    (void)hv_stores(self_hv, "_data", newRV_noinc((SV *)newHV()));
    if (as_svp && SvTRUE(*as_svp))
        chandra_store_save_c(aTHX_ self_hv);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- save(self) — explicit write to disk ----

SV *
save(self)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    chandra_store_save_c(aTHX_ self_hv);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- reload(self) — re-read from disk ----

SV *
reload(self)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    chandra_store_reload_c(aTHX_ self_hv);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- path(self) — returns path string ----

SV *
path(self)
    SV *self
CODE:
{
    HV  *self_hv  = (HV *)SvRV(self);
    SV **path_svp = hv_fetchs(self_hv, "_path", 0);
    RETVAL = (path_svp && SvOK(*path_svp))
        ? SvREFCNT_inc(*path_svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

 # ---- auto_save(self [, val]) — getter/setter ----

SV *
auto_save(self, ...)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    if (items > 1) {
        int val = SvTRUE(ST(1)) ? 1 : 0;
        (void)hv_stores(self_hv, "_auto_save", newSViv(val));
        RETVAL = SvREFCNT_inc(self);
    } else {
        SV **as_svp = hv_fetchs(self_hv, "_auto_save", 0);
        RETVAL = (as_svp && SvOK(*as_svp))
            ? SvREFCNT_inc(*as_svp) : newSViv(1);
    }
}
OUTPUT:
    RETVAL
