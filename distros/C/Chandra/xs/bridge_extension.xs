MODULE = Chandra    PACKAGE = Chandra::Bridge::Extension

PROTOTYPES: DISABLE

void
register(klass, name, source, ...)
    SV *klass
    const char *name
    const char *source
PPCODE:
{
    char **deps = NULL;
    int    dep_count = 0;
    int    i;
    STRLEN len;

    PERL_UNUSED_VAR(klass);

    /* parse optional depends => [...] */
    if (items > 3 && (items - 3) % 2 == 0) {
        for (i = 3; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strcmp(key, "depends") == 0) {
                SV *val = ST(i + 1);
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV *)SvRV(val);
                    SSize_t alen = av_len(av) + 1;
                    int j;
                    dep_count = (int)alen;
                    if (dep_count > 0) {
                        Newx(deps, dep_count, char *);
                        for (j = 0; j < dep_count; j++) {
                            SV **svp = av_fetch(av, j, 0);
                            deps[j] = savepv(svp ? SvPV_nolen(*svp) : "");
                        }
                    }
                }
            }
        }
    }

    chandra_ext_register(aTHX_ name, source, deps, dep_count);

    /* free the temporary deps array (strings were copied by register) */
    if (deps) {
        for (i = 0; i < dep_count; i++)
            Safefree(deps[i]);
        Safefree(deps);
    }

    XSRETURN(1);
}

void
register_file(klass, name, path, ...)
    SV *klass
    const char *name
    const char *path
PPCODE:
{
    SV *contents;
    STRLEN len;
    const char *src;
    PerlIO *fh;

    PERL_UNUSED_VAR(klass);

    fh = PerlIO_open(path, "r");
    if (!fh)
        croak("Chandra::Bridge::Extension: cannot open '%s': %s", path, Strerror(errno));

    contents = newSVpvn("", 0);
    {
        char buf[4096];
        SSize_t nread;
        while ((nread = PerlIO_read(fh, buf, sizeof(buf))) > 0) {
            sv_catpvn(contents, buf, nread);
        }
    }
    PerlIO_close(fh);

    src = SvPV(contents, len);

    /* forward remaining args (depends => [...]) */
    {
        char **deps = NULL;
        int dep_count = 0;
        int i;

        if (items > 3 && (items - 3) % 2 == 0) {
            for (i = 3; i < items; i += 2) {
                const char *key = SvPV_nolen(ST(i));
                if (strcmp(key, "depends") == 0) {
                    SV *val = ST(i + 1);
                    if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                        AV *av = (AV *)SvRV(val);
                        SSize_t alen = av_len(av) + 1;
                        int j;
                        dep_count = (int)alen;
                        if (dep_count > 0) {
                            Newx(deps, dep_count, char *);
                            for (j = 0; j < dep_count; j++) {
                                SV **svp = av_fetch(av, j, 0);
                                deps[j] = savepv(svp ? SvPV_nolen(*svp) : "");
                            }
                        }
                    }
                }
            }
        }

        chandra_ext_register(aTHX_ name, src, deps, dep_count);

        if (deps) {
            for (i = 0; i < dep_count; i++)
                Safefree(deps[i]);
            Safefree(deps);
        }
    }

    SvREFCNT_dec(contents);
    XSRETURN(1);
}

void
unregister(klass, name)
    SV *klass
    const char *name
PPCODE:
{
    PERL_UNUSED_VAR(klass);
    if (chandra_ext_unregister(name))
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

void
is_registered(klass, name)
    SV *klass
    const char *name
PPCODE:
{
    PERL_UNUSED_VAR(klass);
    if (chandra_ext_is_registered(name))
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

SV *
source(klass, name)
    SV *klass
    const char *name
CODE:
{
    const char *src;
    PERL_UNUSED_VAR(klass);
    src = chandra_ext_source(name);
    if (src)
        RETVAL = newSVpv(src, 0);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
list(klass)
    SV *klass
PPCODE:
{
    int *order;
    int  count, i;
    const char *err = NULL;

    PERL_UNUSED_VAR(klass);

    if (_ext_count == 0)
        XSRETURN_EMPTY;

    order = chandra_ext_topo_sort(aTHX_ &count, &err);
    if (!order)
        croak("%s", err);

    EXTEND(SP, count);
    for (i = 0; i < count; i++) {
        PUSHs(sv_2mortal(newSVpv(_ext_list[order[i]].name, 0)));
    }
    Safefree(order);
}

void
clear(klass)
    SV *klass
PPCODE:
{
    PERL_UNUSED_VAR(klass);
    chandra_ext_clear();
    XSRETURN(1);
}

SV *
generate_js(klass)
    SV *klass
CODE:
{
    PERL_UNUSED_VAR(klass);
    RETVAL = chandra_ext_generate_js(aTHX);
}
OUTPUT:
    RETVAL

SV *
generate_js_escaped(klass)
    SV *klass
CODE:
{
    SV *raw;
    PERL_UNUSED_VAR(klass);
    raw = chandra_ext_generate_js(aTHX);
    RETVAL = chandra_ext_escape_sv(aTHX_ raw);
    SvREFCNT_dec(raw);
}
OUTPUT:
    RETVAL
