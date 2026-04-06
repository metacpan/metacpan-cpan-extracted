MODULE = Chandra    PACKAGE = Chandra::Assets

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    SV *root_sv = NULL;
    SV *prefix_sv = NULL;
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "root")) {
            root_sv = val;
        } else if (strEQ(key, "prefix")) {
            prefix_sv = val;
        } else if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        }
    }

    if (!root_sv || !SvOK(root_sv)) {
        croak("Chandra::Assets->new() requires 'root' directory");
    }

    /* Normalize root: ensure trailing slash */
    {
        STRLEN rlen;
        const char *rstr = SvPV(root_sv, rlen);
        if (rlen > 0 && rstr[rlen - 1] != '/') {
            SV *norm = newSVpvn(rstr, rlen);
            sv_catpvs(norm, "/");
            (void)hv_stores(self_hv, "root", norm);
        } else {
            (void)hv_stores(self_hv, "root", newSVsv(root_sv));
        }
    }

    if (prefix_sv && SvOK(prefix_sv)) {
        /* Clean prefix: strip :// suffix */
        STRLEN plen;
        const char *pstr = SvPV(prefix_sv, plen);
        if (plen > 3 && pstr[plen - 3] == ':' && pstr[plen - 2] == '/' && pstr[plen - 1] == '/') {
            (void)hv_stores(self_hv, "prefix", newSVpvn(pstr, plen - 3));
        } else if (plen > 1 && pstr[plen - 1] == ':') {
            (void)hv_stores(self_hv, "prefix", newSVpvn(pstr, plen - 1));
        } else {
            (void)hv_stores(self_hv, "prefix", newSVsv(prefix_sv));
        }
    } else {
        (void)hv_stores(self_hv, "prefix", newSVpvs("asset"));
    }

    (void)hv_stores(self_hv, "_mounted", newSViv(0));

    /* Ensure File::Raw is loaded for all I/O operations */
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("File::Raw"), NULL);

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
root(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "root", 0);
    RETVAL = (svp && SvOK(*svp)) ? newSVsv(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
prefix(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "prefix", 0);
    RETVAL = (svp && SvOK(*svp)) ? newSVsv(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
mime_type(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    STRLEN plen;
    const char *path = SvPV(path_sv, plen);
    const char *dot = NULL;
    STRLEN i;
    PERL_UNUSED_VAR(self);

    /* Find last dot */
    for (i = plen; i > 0; i--) {
        if (path[i - 1] == '.') { dot = &path[i]; break; }
        if (path[i - 1] == '/') break;
    }

    if (dot) {
        STRLEN ext_len = (path + plen) - dot;
        /* Lowercase the extension into a small buffer */
        char ext_buf[32];
        STRLEN j;
        if (ext_len < sizeof(ext_buf)) {
            for (j = 0; j < ext_len; j++)
                ext_buf[j] = (dot[j] >= 'A' && dot[j] <= 'Z')
                    ? (char)(dot[j] + 32) : dot[j];
            ext_buf[ext_len] = '\0';
            RETVAL = newSVpv(chandra_assets_mime(ext_buf, ext_len), 0);
        } else {
            RETVAL = newSVpvs("application/octet-stream");
        }
    } else {
        RETVAL = newSVpvs("application/octet-stream");
    }
}
OUTPUT:
    RETVAL

SV *
_resolve_path(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **root_svp = hv_fetchs(hv, "root", 0);
    STRLEN rlen, plen;
    const char *root, *path;

    if (!root_svp || !SvOK(*root_svp))
        croak("Assets object has no root");

    root = SvPV(*root_svp, rlen);
    path = SvPV(rel_sv, plen);

    /* Security: reject traversal */
    if (!chandra_assets_path_safe(path, plen)) {
        croak("Invalid asset path: path traversal detected");
    }

    /* Build full path: root + rel */
    {
        SV *full = newSVpvn(root, rlen);
        /* Skip leading slash in relative path if present */
        if (plen > 0 && path[0] == '/') {
            path++;
            plen--;
        }
        sv_catpvn(full, path, plen);
        RETVAL = full;
    }
}
OUTPUT:
    RETVAL

SV *
read(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    /* Resolve path, then call File::Raw::slurp */
    SV *full_path;
    int count;
    dSP;

    /* Resolve */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("_resolve_path", G_SCALAR);
    SPAGAIN;
    full_path = (count > 0) ? newSVsv(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;

    if (!full_path) {
        RETVAL = &PL_sv_undef;
    } else {
        /* Call File::Raw::slurp($path) */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(full_path));
        PUTBACK;
        count = call_pv("File::Raw::slurp", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? newSVsv(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
    }
}
OUTPUT:
    RETVAL

SV *
exists(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    SV *full_path;
    int count;
    dSP;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("_resolve_path", G_SCALAR | G_EVAL);
    SPAGAIN;
    full_path = (count > 0 && !SvTRUE(ERRSV)) ? newSVsv(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;

    if (!full_path) {
        RETVAL = &PL_sv_no;
    } else {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(full_path));
        PUTBACK;
        count = call_pv("File::Raw::exists", G_SCALAR);
        SPAGAIN;
        {
            SV *result = (count > 0) ? POPs : NULL;
            RETVAL = (result && SvTRUE(result)) ? &PL_sv_yes : &PL_sv_no;
        }
        PUTBACK; FREETMPS; LEAVE;
    }
}
OUTPUT:
    RETVAL

void
list(self, ...)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **root_svp = hv_fetchs(hv, "root", 0);
    SV *pattern_sv = (items > 1 && SvOK(ST(1))) ? ST(1) : NULL;
    AV *result_av = NULL;

    if (!root_svp || !SvOK(*root_svp)) XSRETURN(0);

    /* Call File::Raw::readdir($root) — capture result before returning to our stack */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*root_svp);
        PUTBACK;
        count = call_pv("File::Raw::readdir", G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            SV *entries_sv = POPs;
            if (SvROK(entries_sv) && SvTYPE(SvRV(entries_sv)) == SVt_PVAV) {
                /* Copy the array so it survives FREETMPS */
                AV *src = (AV *)SvRV(entries_sv);
                SSize_t len = av_len(src) + 1;
                SSize_t i;
                result_av = newAV();
                av_extend(result_av, len - 1);
                for (i = 0; i < len; i++) {
                    SV **svp = av_fetch(src, i, 0);
                    if (svp && SvOK(*svp))
                        av_push(result_av, newSVsv(*svp));
                }
            }
        }
        PUTBACK; FREETMPS; LEAVE;
    }

    if (result_av) {
        SSize_t len = av_len(result_av) + 1;
        SSize_t i;
        for (i = 0; i < len; i++) {
            SV **entry_svp = av_fetch(result_av, i, 0);
            if (entry_svp && SvOK(*entry_svp)) {
                int push_it = 1;
                if (pattern_sv) {
                    STRLEN plen, elen;
                    const char *pat = SvPV(pattern_sv, plen);
                    const char *ent = SvPV(*entry_svp, elen);
                    push_it = 0;
                    if (plen >= 2 && pat[0] == '*' && pat[1] == '.') {
                        const char *ext = pat + 1;
                        STRLEN ext_len = plen - 1;
                        if (elen >= ext_len &&
                            memcmp(ent + elen - ext_len, ext, ext_len) == 0) {
                            push_it = 1;
                        }
                    } else if (elen >= plen && memcmp(ent, pat, plen) == 0) {
                        push_it = 1;
                    }
                }
                if (push_it) {
                    XPUSHs(sv_2mortal(newSVsv(*entry_svp)));
                }
            }
        }
        SvREFCNT_dec((SV *)result_av);
    }
}

SV *
inline_css(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    SV *content;
    int count;
    dSP;

    /* Read file content */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("read", G_SCALAR);
    SPAGAIN;
    content = (count > 0) ? newSVsv(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;

    if (!content || !SvOK(content)) {
        croak("Cannot read asset: %s", SvPV_nolen(rel_sv));
    }

    {
        STRLEN clen;
        const char *cstr = SvPV(content, clen);
        SV *result = newSVpvs("<style>");
        sv_catpvn(result, cstr, clen);
        sv_catpvs(result, "</style>");
        SvREFCNT_dec(content);
        RETVAL = result;
    }
}
OUTPUT:
    RETVAL

SV *
inline_js(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    SV *content;
    int count;
    dSP;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("read", G_SCALAR);
    SPAGAIN;
    content = (count > 0) ? newSVsv(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;

    if (!content || !SvOK(content)) {
        croak("Cannot read asset: %s", SvPV_nolen(rel_sv));
    }

    {
        STRLEN clen;
        const char *cstr = SvPV(content, clen);
        SV *result = newSVpvs("<script>");
        sv_catpvn(result, cstr, clen);
        sv_catpvs(result, "</script>");
        SvREFCNT_dec(content);
        RETVAL = result;
    }
}
OUTPUT:
    RETVAL

SV *
inline_image(self, rel_sv)
    SV *self
    SV *rel_sv
CODE:
{
    SV *content, *mime_sv, *b64_sv;
    int count;
    dSP;

    /* Get MIME type */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("mime_type", G_SCALAR);
    SPAGAIN;
    mime_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("application/octet-stream");
    PUTBACK; FREETMPS; LEAVE;

    /* Read raw file content */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(rel_sv);
    PUTBACK;
    count = call_method("read", G_SCALAR);
    SPAGAIN;
    content = (count > 0) ? newSVsv(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;

    if (!content || !SvOK(content)) {
        SvREFCNT_dec(mime_sv);
        croak("Cannot read asset: %s", SvPV_nolen(rel_sv));
    }

    /* Base64 encode: call MIME::Base64::encode_base64($content, "") */
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("MIME::Base64"), NULL);
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(content));
    XPUSHs(sv_2mortal(newSVpvs("")));
    PUTBACK;
    count = call_pv("MIME::Base64::encode_base64", G_SCALAR);
    SPAGAIN;
    b64_sv = (count > 0) ? newSVsv(POPs) : newSVpvs("");
    PUTBACK; FREETMPS; LEAVE;

    /* Build: <img src="data:mime;base64,DATA"> */
    {
        STRLEN mlen, blen;
        const char *mstr = SvPV(mime_sv, mlen);
        const char *bstr = SvPV(b64_sv, blen);
        SV *result = newSVpvs("<img src=\"data:");
        sv_catpvn(result, mstr, mlen);
        sv_catpvs(result, ";base64,");
        sv_catpvn(result, bstr, blen);
        sv_catpvs(result, "\">");
        SvREFCNT_dec(mime_sv);
        SvREFCNT_dec(b64_sv);
        RETVAL = result;
    }
}
OUTPUT:
    RETVAL

SV *
bundle(self, ...)
    SV *self
CODE:
{
    HV *result_hv = newHV();
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *type = SvPV_nolen(ST(i));
        SV *files_sv = ST(i + 1);

        if (!SvROK(files_sv) || SvTYPE(SvRV(files_sv)) != SVt_PVAV) {
            croak("bundle() expects arrayref for '%s'", type);
        }

        {
            AV *files = (AV *)SvRV(files_sv);
            SSize_t len = av_len(files) + 1;
            SSize_t j;
            SV *combined = newSVpvs("");

            if (strEQ(type, "css")) {
                sv_catpvs(combined, "<style>");
                for (j = 0; j < len; j++) {
                    SV **file_svp = av_fetch(files, j, 0);
                    if (file_svp && SvOK(*file_svp)) {
                        SV *content;
                        int count;
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(self);
                        XPUSHs(*file_svp);
                        PUTBACK;
                        count = call_method("read", G_SCALAR);
                        SPAGAIN;
                        content = (count > 0) ? POPs : NULL;
                        if (content && SvOK(content)) {
                            STRLEN clen;
                            const char *cstr = SvPV(content, clen);
                            if (j > 0) sv_catpvs(combined, "\n");
                            sv_catpvn(combined, cstr, clen);
                        }
                        PUTBACK; FREETMPS; LEAVE;
                    }
                }
                sv_catpvs(combined, "</style>");
            }
            else if (strEQ(type, "js")) {
                sv_catpvs(combined, "<script>");
                for (j = 0; j < len; j++) {
                    SV **file_svp = av_fetch(files, j, 0);
                    if (file_svp && SvOK(*file_svp)) {
                        SV *content;
                        int count;
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(self);
                        XPUSHs(*file_svp);
                        PUTBACK;
                        count = call_method("read", G_SCALAR);
                        SPAGAIN;
                        content = (count > 0) ? POPs : NULL;
                        if (content && SvOK(content)) {
                            STRLEN clen;
                            const char *cstr = SvPV(content, clen);
                            if (j > 0) sv_catpvs(combined, ";\n");
                            sv_catpvn(combined, cstr, clen);
                        }
                        PUTBACK; FREETMPS; LEAVE;
                    }
                }
                sv_catpvs(combined, "</script>");
            }
            else {
                croak("bundle(): unknown type '%s' (expected 'css' or 'js')", type);
            }

            (void)hv_store(result_hv, type, strlen(type), combined, 0);
        }
    }

    RETVAL = newRV_noinc((SV *)result_hv);
}
OUTPUT:
    RETVAL

SV *
mount(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **mounted_svp = hv_fetchs(hv, "_mounted", 0);
    SV **prefix_svp = hv_fetchs(hv, "prefix", 0);
    SV **app_svp;
    SV *app_sv = NULL;

    /* Already mounted? */
    if (mounted_svp && SvTRUE(*mounted_svp)) {
        RETVAL = SvREFCNT_inc(self);
    } else {
        /* Get app: from args or stored */
        if (items > 1 && SvOK(ST(1))) {
            app_sv = ST(1);
            (void)hv_stores(hv, "app", newSVsv(app_sv));
        } else {
            app_svp = hv_fetchs(hv, "app", 0);
            if (app_svp && SvOK(*app_svp)) app_sv = *app_svp;
        }

        if (!app_sv) {
            croak("mount() requires an app object");
        }

        /* Register protocol: $app->protocol->register($prefix, sub { ... }) */
        {
            SV *protocol_sv;
            int count;
            dSP;

            /* Get protocol object */
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(app_sv);
            PUTBACK;
            count = call_method("protocol", G_SCALAR);
            SPAGAIN;
            protocol_sv = (count > 0) ? newSVsv(POPs) : NULL;
            PUTBACK; FREETMPS; LEAVE;

            if (protocol_sv && SvOK(protocol_sv)) {
                /* Build a closure that captures $self for serving files */
                /* We create an anonymous sub that calls $self->_serve($path) */
                SV *handler_sv;
                CV *handler_cv;

                /* Store self reference for the handler */
                (void)hv_stores(hv, "_self_ref", newSVsv(self));

                /* Create handler: sub { my ($path, $params) = @_; $self->_serve($path) } */
                {
                    SV *code_sv;
                    /* Build eval string that creates a closure over $self */
                    /* We use a different approach: store self in a global and reference it */
                    SV *self_copy = newSVsv(self);

                    handler_cv = newXS(NULL, XS_Chandra__Assets__serve_handler, __FILE__);
                    CvXSUBANY(handler_cv).any_ptr = (void *)self_copy;
                    handler_sv = newRV_noinc((SV *)handler_cv);
                }

                /* $protocol->register($prefix, $handler) */
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(protocol_sv));
                XPUSHs(*prefix_svp);
                XPUSHs(sv_2mortal(handler_sv));
                PUTBACK;
                call_method("register", G_DISCARD);
                FREETMPS; LEAVE;

                (void)hv_stores(hv, "_mounted", newSViv(1));
            }
        }

        RETVAL = SvREFCNT_inc(self);
    }
}
OUTPUT:
    RETVAL

SV *
_serve(self, path_sv)
    SV *self
    SV *path_sv
CODE:
{
    /* Serve an asset file: resolve path, read content, return with MIME info */
    SV *full_path = NULL;
    SV *content = NULL;
    int count;
    dSP;

    /* Resolve path (with security check) */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(path_sv);
    PUTBACK;
    count = call_method("_resolve_path", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count > 0 && !SvTRUE(ERRSV)) {
        full_path = newSVsv(POPs);
    }
    PUTBACK; FREETMPS; LEAVE;

    if (!full_path) {
        RETVAL = &PL_sv_undef;
    } else {
        /* Read file */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(full_path));
        PUTBACK;
        count = call_pv("File::Raw::slurp", G_SCALAR);
        SPAGAIN;
        content = (count > 0) ? newSVsv(POPs) : NULL;
        PUTBACK; FREETMPS; LEAVE;

        RETVAL = content ? content : &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL
