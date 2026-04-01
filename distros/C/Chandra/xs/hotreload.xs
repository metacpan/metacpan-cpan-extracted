MODULE = Chandra    PACKAGE = Chandra::HotReload

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;
    double interval = 1.0;

    /* Parse %args from stack */
    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "interval")) {
            interval = SvNV(val);
        }
    }

    (void)hv_stores(self_hv, "watches", newRV_noinc((SV *)newAV()));
    (void)hv_stores(self_hv, "interval", newSVnv(interval));
    (void)hv_stores(self_hv, "_last_check", newSVnv(0.0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
watch(self, path_sv, callback)
    SV *self
    SV *path_sv
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    const char *path;
    AV *watches_av;
    SV **watches_svp;
    HV *entry_hv;
    HV *files_hv;

    /* Validate path */
    if (!SvOK(path_sv)) {
        croak("watch() requires a path");
    }
    path = SvPV_nolen(path_sv);

    /* Validate callback */
    if (!SvOK(callback) || SvROK(callback) == 0 || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("watch() requires a callback");
    }

    /* Check path exists */
    {
        Stat_t st;
        if (PerlLIO_stat(path, &st) != 0) {
            croak("watch() path does not exist: %s", path);
        }
    }

    /* Scan files via Perl helper */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(path_sv);
        PUTBACK;
        count = call_method("_scan_files", G_SCALAR);
        SPAGAIN;
        files_hv = (HV *)SvRV(POPs);
        SvREFCNT_inc_simple_void((SV *)files_hv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    /* Build watch entry hash */
    entry_hv = newHV();
    (void)hv_stores(entry_hv, "path", newSVsv(path_sv));
    (void)hv_stores(entry_hv, "callback", SvREFCNT_inc(callback));
    (void)hv_stores(entry_hv, "files", newRV_noinc((SV *)files_hv));

    /* Push onto watches array */
    watches_svp = hv_fetchs(hv, "watches", 0);
    watches_av = (AV *)SvRV(*watches_svp);
    av_push(watches_av, newRV_noinc((SV *)entry_hv));

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

int
poll(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **interval_svp, **last_check_svp, **watches_svp;
    AV *watches_av;
    double now, interval, last_check;
    I32 wi, wlen;
    int total_changed = 0;

    now = (double)time(NULL);

    interval_svp = hv_fetchs(hv, "interval", 0);
    interval = SvNV(*interval_svp);

    last_check_svp = hv_fetchs(hv, "_last_check", 0);
    last_check = SvNV(*last_check_svp);

    if ((now - last_check) < interval) {
        RETVAL = 0;
        goto done;
    }

    sv_setnv(*last_check_svp, now);

    watches_svp = hv_fetchs(hv, "watches", 0);
    watches_av = (AV *)SvRV(*watches_svp);
    wlen = av_len(watches_av) + 1;

    for (wi = 0; wi < wlen; wi++) {
        SV **entry_svp = av_fetch(watches_av, wi, 0);
        HV *entry_hv = (HV *)SvRV(*entry_svp);
        SV **path_svp = hv_fetchs(entry_hv, "path", 0);
        SV **cb_svp = hv_fetchs(entry_hv, "callback", 0);
        SV **old_files_svp = hv_fetchs(entry_hv, "files", 0);
        HV *old_files = (HV *)SvRV(*old_files_svp);
        HV *current;
        AV *changed_av;
        HE *he;
        int changed_count;

        /* Scan current files */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(*path_svp);
            PUTBACK;
            count = call_method("_scan_files", G_SCALAR);
            SPAGAIN;
            current = (HV *)SvRV(POPs);
            SvREFCNT_inc_simple_void((SV *)current);
            PUTBACK;
            FREETMPS; LEAVE;
        }

        changed_av = newAV();

        /* Check for modified or new files */
        hv_iterinit(current);
        while ((he = hv_iternext(current))) {
            SV *key_sv = hv_iterkeysv(he);
            SV *cur_mtime = hv_iterval(current, he);
            STRLEN klen;
            const char *kpv = SvPV(key_sv, klen);
            SV **old_svp = hv_fetch(old_files, kpv, (I32)klen, 0);

            if (!old_svp || SvNV(*old_svp) != SvNV(cur_mtime)) {
                av_push(changed_av, newSVpvn(kpv, klen));
            }
        }

        /* Check for deleted files */
        hv_iterinit(old_files);
        while ((he = hv_iternext(old_files))) {
            SV *key_sv = hv_iterkeysv(he);
            STRLEN klen;
            const char *kpv = SvPV(key_sv, klen);
            if (!hv_exists(current, kpv, (I32)klen)) {
                av_push(changed_av, newSVpvn(kpv, klen));
            }
        }

        changed_count = av_len(changed_av) + 1;

        if (changed_count > 0) {
            /* Update stored files */
            (void)hv_stores(entry_hv, "files", newRV_noinc((SV *)current));

            /* Call callback with arrayref of changed files */
            {
                dSP;
                SV *changed_ref = sv_2mortal(newRV_noinc((SV *)changed_av));
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(changed_ref);
                PUTBACK;
                call_sv(*cb_svp, G_DISCARD | G_EVAL);
                FREETMPS; LEAVE;

                if (SvTRUE(ERRSV)) {
                    warn("Chandra::HotReload: callback error: %" SVf, SVfARG(ERRSV));
                    sv_setpvs(ERRSV, "");
                }
            }

            total_changed += changed_count;
        } else {
            SvREFCNT_dec((SV *)current);
            SvREFCNT_dec((SV *)changed_av);
        }
    }

    RETVAL = total_changed;
    done:
    ;
}
OUTPUT:
    RETVAL

SV *
clear(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "watches", newRV_noinc((SV *)newAV()));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

void
watched_paths(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **watches_svp = hv_fetchs(hv, "watches", 0);
    AV *watches_av = (AV *)SvRV(*watches_svp);
    I32 i, len = av_len(watches_av) + 1;

    if (GIMME_V == G_SCALAR) {
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(len)));
    } else {
        EXTEND(SP, len);
        for (i = 0; i < len; i++) {
            SV **entry_svp = av_fetch(watches_av, i, 0);
            HV *entry_hv = (HV *)SvRV(*entry_svp);
            SV **path_svp = hv_fetchs(entry_hv, "path", 0);
            PUSHs(sv_2mortal(newSVsv(*path_svp)));
        }
    }
}

SV *
interval(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;

    if (items > 1) {
        (void)hv_stores(hv, "interval", newSVnv(SvNV(ST(1))));
    }

    svp = hv_fetchs(hv, "interval", 0);
    RETVAL = newSVnv(SvNV(*svp));
}
OUTPUT:
    RETVAL

SV *
_scan_files(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    const char *path = SvPV_nolen(path_sv);
    HV *files_hv = newHV();
    Stat_t st;

    PERL_UNUSED_VAR(self);

    if (PerlLIO_stat(path, &st) == 0) {
        if (S_ISREG(st.st_mode)) {
            /* Single file */
            STRLEN plen = SvCUR(path_sv);
            (void)hv_store(files_hv, path, (I32)plen, newSVnv((NV)st.st_mtime), 0);
        } else if (S_ISDIR(st.st_mode)) {
            /* Recursive C directory walk — no File::Find / eval_pv */
            _hotreload_scan_recursive(aTHX_ path, files_hv);
        }
    }

    RETVAL = newRV_noinc((SV *)files_hv);
}
OUTPUT:
    RETVAL
