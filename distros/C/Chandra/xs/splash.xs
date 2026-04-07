MODULE = Chandra    PACKAGE = Chandra::Splash

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
PREINIT:
    HV   *self;
    const char *title     = "Loading";
    int   width           = 400;
    int   height          = 200;
    int   frameless       = 0;
    int   progress        = 0;
    int   timeout         = 0;       /* ms; 0 = no auto-close */
    SV   *content_sv      = NULL;
    SV   *image_sv        = NULL;
    int   i;
CODE:
{
    if ((items - 1) % 2 != 0)
        croak("Chandra::Splash->new requires key => value pairs");

    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV         *val = ST(i + 1);
        if      (strEQ(key, "title"))     title     = SvPV_nolen(val);
        else if (strEQ(key, "width"))     width     = SvIV(val);
        else if (strEQ(key, "height"))    height    = SvIV(val);
        else if (strEQ(key, "frameless")) frameless = SvIV(val);
        else if (strEQ(key, "progress"))  progress  = SvIV(val);
        else if (strEQ(key, "timeout"))   timeout   = SvIV(val);
        else if (strEQ(key, "content"))   content_sv = val;
        else if (strEQ(key, "image"))     image_sv  = val;
    }

    self = newHV();
    (void)hv_stores(self, "title",     newSVpv(title, 0));
    (void)hv_stores(self, "width",     newSViv(width));
    (void)hv_stores(self, "height",    newSViv(height));
    (void)hv_stores(self, "frameless", newSViv(frameless));
    (void)hv_stores(self, "progress",  newSViv(progress));
    (void)hv_stores(self, "timeout",   newSViv(timeout));
    (void)hv_stores(self, "_wid",      newSViv(-1));
    (void)hv_stores(self, "_shown",    newSViv(0));

    if (content_sv && SvOK(content_sv))
        (void)hv_stores(self, "content", newSVsv(content_sv));
    if (image_sv && SvOK(image_sv))
        (void)hv_stores(self, "image", newSVsv(image_sv));

    RETVAL = sv_bless(newRV_noinc((SV *)self),
                      gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

# ---- show ----------------------------------------------------------------

SV *
show(self)
    SV *self
PREINIT:
    HV         *hv;
    SV        **svp;
    int         wid;
    const char *title;
    int         width, height, frameless, progress, timeout;
    char       *html = NULL;
CODE:
{
    hv        = (HV *)SvRV(self);
    svp       = hv_fetchs(hv, "_shown", 0);
    if (svp && SvIV(*svp)) {
        RETVAL = SvREFCNT_inc(self);
        goto show_done;
    }

    title     = SvPV_nolen(*hv_fetchs(hv, "title",     0));
    width     = SvIV(*hv_fetchs(hv, "width",     0));
    height    = SvIV(*hv_fetchs(hv, "height",    0));
    frameless = SvIV(*hv_fetchs(hv, "frameless", 0));
    progress  = SvIV(*hv_fetchs(hv, "progress",  0));
    timeout   = SvIV(*hv_fetchs(hv, "timeout",   0));

    wid = csplash_create(title, width, height, frameless);
    if (wid < 0) {
        warn("Chandra::Splash: multi-window not supported on this platform");
        RETVAL = SvREFCNT_inc(self);
        goto show_done;
    }
    (void)hv_stores(hv, "_wid",   newSViv(wid));
    (void)hv_stores(hv, "_shown", newSViv(1));

    /* Determine HTML to display */
    {
        SV **content_svp = hv_fetchs(hv, "content", 0);
        SV **image_svp   = hv_fetchs(hv, "image",   0);

        if (image_svp && SvOK(*image_svp)) {
            /* Image mode: base64-encode the file */
            const char *path = SvPV_nolen(*image_svp);
            FILE *fh = fopen(path, "rb");
            if (!fh) {
                warn("Chandra::Splash: cannot open image '%s'", path);
            } else {
                /* Read file into buffer */
                fseek(fh, 0, SEEK_END);
                long fsize = ftell(fh);
                rewind(fh);
                unsigned char *fbuf = (unsigned char *)malloc(fsize);
                if (fbuf) {
                    size_t nread = fread(fbuf, 1, fsize, fh);
                    if ((long)nread != fsize) {
                        warn("Chandra::Splash: short read on '%s'", path);
                        free(fbuf);
                        fbuf = NULL;
                    }
                }
                if (fbuf) {
                    STRLEN b64len;
                    SV *b64sv = sv_2mortal(newSV(0));
                    sv_setpvn(b64sv, (char *)fbuf, fsize);
                    {
                        /* Use MIME::Base64 via Perl call */
                        dSP;
                        int count;
                        load_module(PERL_LOADMOD_NOIMPORT,
                                    newSVpvs("MIME::Base64"), NULL);
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(b64sv);
                        PUTBACK;
                        count = call_pv("MIME::Base64::encode_base64",
                                        G_SCALAR);
                        SPAGAIN;
                        if (count > 0) {
                            SV *b64result = POPs;
                            /* Strip newlines from base64 output */
                            STRLEN b64l;
                            const char *b64s = SvPV(b64result, b64l);
                            SV *clean = sv_2mortal(newSVpv("", 0));
                            STRLEN ci;
                            for (ci = 0; ci < b64l; ci++) {
                                if (b64s[ci] != '\n' && b64s[ci] != '\r')
                                    sv_catpvn(clean, b64s + ci, 1);
                            }
                            /* Detect mime type from extension */
                            const char *mime = "image/png";
                            const char *dot = strrchr(path, '.');
                            if (dot) {
                                if (strcasecmp(dot, ".jpg") == 0 ||
                                    strcasecmp(dot, ".jpeg") == 0)
                                    mime = "image/jpeg";
                                else if (strcasecmp(dot, ".gif") == 0)
                                    mime = "image/gif";
                                else if (strcasecmp(dot, ".webp") == 0)
                                    mime = "image/webp";
                            }
                            STRLEN cl;
                            const char *cs = SvPV(clean, cl);
                            size_t hlen = strlen(CHANDRA_SPLASH_IMAGE_TMPL)
                                        + strlen(mime) + cl + 1;
                            html = (char *)malloc(hlen);
                            if (html)
                                snprintf(html, hlen, CHANDRA_SPLASH_IMAGE_TMPL,
                                         mime, cs);
                        }
                        PUTBACK;
                        FREETMPS; LEAVE;
                    }
                    free(fbuf);
                }
                fclose(fh);
            }
        } else if (content_svp && SvOK(*content_svp)) {
            html = strdup(SvPV_nolen(*content_svp));
        } else if (progress) {
            html = csplash_build_html(title);
        } else {
            /* Bare title-only splash */
            html = csplash_build_html(title);
        }
    }

    if (html) {
        csplash_show_html(wid, html);
        free(html);
    } else {
        csplash_show_html(wid, "<html><body></body></html>");
    }

    /* If timeout > 0, store it so close_if_expired() can check */
    if (timeout > 0) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        IV deadline_ms = (IV)tv.tv_sec * 1000 + (IV)tv.tv_usec / 1000
                       + (IV)timeout;
        (void)hv_stores(hv, "_deadline", newSViv(deadline_ms));
    }

    RETVAL = SvREFCNT_inc(self);
    show_done: ;
}
OUTPUT:
    RETVAL

# ---- update_status -------------------------------------------------------

SV *
update_status(self, text)
    SV         *self
    const char *text
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    if (svp && SvOK(*svp)) {
        int wid = (int)SvIV(*svp);
        if (wid > 0) csplash_update_status(wid, text);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

# ---- update_progress -----------------------------------------------------

SV *
update_progress(self, percent)
    SV *self
    int percent
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    if (svp && SvOK(*svp)) {
        int wid = (int)SvIV(*svp);
        if (wid > 0) csplash_update_progress(wid, percent);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

# ---- close ---------------------------------------------------------------

void
close(self)
    SV *self
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    if (svp && SvOK(*svp)) {
        int wid = (int)SvIV(*svp);
        if (wid > 0) {
            csplash_close(wid);
            (void)hv_stores(hv, "_wid",   newSViv(-1));
            (void)hv_stores(hv, "_shown", newSViv(0));
        }
    }
}

# ---- is_open -------------------------------------------------------------

int
is_open(self)
    SV *self
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    RETVAL = (svp && SvOK(*svp)) ? csplash_is_open((int)SvIV(*svp)) : 0;
}
OUTPUT:
    RETVAL

# ---- wid -----------------------------------------------------------------

int
wid(self)
    SV *self
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    RETVAL = (svp && SvOK(*svp)) ? (int)SvIV(*svp) : -1;
}
OUTPUT:
    RETVAL

# ---- eval_js (escape hatch) ----------------------------------------------

void
eval_js(self, js)
    SV         *self
    const char *js
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    if (svp && SvOK(*svp)) {
        int wid = (int)SvIV(*svp);
        if (wid > 0) cwin_eval_js(wid, js);
    }
}

# ---- DESTROY — prevent native window leak --------------------------------

void
DESTROY(self)
    SV *self
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_wid", 0);
    if (svp && SvOK(*svp)) {
        int wid = (int)SvIV(*svp);
        if (wid > 0) {
            csplash_close(wid);
        }
    }
}

# ---- close_if_expired — check timeout deadline, close if past ------------

int
close_if_expired(self)
    SV *self
CODE:
{
    HV  *hv  = (HV *)SvRV(self);
    SV **dl  = hv_fetchs(hv, "_deadline", 0);
    RETVAL = 0;
    if (dl && SvOK(*dl) && SvIV(*dl) > 0) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        IV now_ms = (IV)tv.tv_sec * 1000 + (IV)tv.tv_usec / 1000;
        if (now_ms >= SvIV(*dl)) {
            /* Deadline passed — close the window */
            SV **wid_svp = hv_fetchs(hv, "_wid", 0);
            if (wid_svp && SvOK(*wid_svp)) {
                int wid = (int)SvIV(*wid_svp);
                if (wid > 0) {
                    csplash_close(wid);
                    (void)hv_stores(hv, "_wid",   newSViv(-1));
                    (void)hv_stores(hv, "_shown", newSViv(0));
                }
            }
            (void)hv_stores(hv, "_deadline", newSViv(0));
            RETVAL = 1;
        }
    }
}
OUTPUT:
    RETVAL
