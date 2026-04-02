MODULE = Chandra    PACKAGE = Chandra::Dialog

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash = gv_stashpv("Chandra::Dialog", GV_ADD);
    newCONSTSUB(stash, "TYPE_OPEN",      newSViv(0));
    newCONSTSUB(stash, "TYPE_SAVE",      newSViv(1));
    newCONSTSUB(stash, "TYPE_ALERT",     newSViv(2));
    newCONSTSUB(stash, "FLAG_FILE",      newSViv(0));
    newCONSTSUB(stash, "FLAG_DIRECTORY",  newSViv(1));
    newCONSTSUB(stash, "FLAG_INFO",      newSViv(1 << 1));
    newCONSTSUB(stash, "FLAG_WARNING",   newSViv(2 << 1));
    newCONSTSUB(stash, "FLAG_ERROR",     newSViv(3 << 1));
}

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    int i;
    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", SvREFCNT_inc(ST(i + 1)));
        }
    }
    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
open_file(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Open File";
    const char *filter = "";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title"))  title  = SvPV_nolen(ST(i + 1));
        if (strEQ(key, "filter")) filter = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_OPEN, WEBVIEW_DIALOG_FLAG_FILE, title, filter, result, sizeof(result));
        if (strlen(result) > 0) {
            RETVAL = newSVpv(result, 0);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(0)));  /* TYPE_OPEN */
        XPUSHs(sv_2mortal(newSViv(0)));  /* FLAG_FILE */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpv(filter, 0)));
        PUTBACK;
        count = call_method("dialog", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
}
OUTPUT:
    RETVAL

SV *
open_directory(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Open Directory";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title")) title = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_OPEN, WEBVIEW_DIALOG_FLAG_DIRECTORY, title, "", result, sizeof(result));
        if (strlen(result) > 0) {
            RETVAL = newSVpv(result, 0);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(0)));  /* TYPE_OPEN */
        XPUSHs(sv_2mortal(newSViv(1)));  /* FLAG_DIRECTORY */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpvs("")));
        PUTBACK;
        count = call_method("dialog", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
}
OUTPUT:
    RETVAL

SV *
save_file(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Save File";
    const char *def = "";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title"))   title = SvPV_nolen(ST(i + 1));
        if (strEQ(key, "default")) def   = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_SAVE, WEBVIEW_DIALOG_FLAG_FILE, title, def, result, sizeof(result));
        if (strlen(result) > 0) {
            RETVAL = newSVpv(result, 0);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(1)));  /* TYPE_SAVE */
        XPUSHs(sv_2mortal(newSViv(0)));  /* FLAG_FILE */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpv(def, 0)));
        PUTBACK;
        count = call_method("dialog", G_SCALAR);
        SPAGAIN;
        RETVAL = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
}
OUTPUT:
    RETVAL

SV *
info(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Information";
    const char *message = "";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title"))   title   = SvPV_nolen(ST(i + 1));
        if (strEQ(key, "message")) message = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_ALERT, WEBVIEW_DIALOG_FLAG_INFO, title, message, result, sizeof(result));
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(2)));        /* TYPE_ALERT */
        XPUSHs(sv_2mortal(newSViv(1 << 1)));   /* FLAG_INFO */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpv(message, 0)));
        PUTBACK;
        call_method("dialog", G_DISCARD);
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
warning(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Warning";
    const char *message = "";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title"))   title   = SvPV_nolen(ST(i + 1));
        if (strEQ(key, "message")) message = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_ALERT, WEBVIEW_DIALOG_FLAG_WARNING, title, message, result, sizeof(result));
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(2)));        /* TYPE_ALERT */
        XPUSHs(sv_2mortal(newSViv(2 << 1)));   /* FLAG_WARNING */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpv(message, 0)));
        PUTBACK;
        call_method("dialog", G_DISCARD);
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
error(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    const char *title = "Error";
    const char *message = "";
    int i;
    PerlChandra *pc;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "title"))   title   = SvPV_nolen(ST(i + 1));
        if (strEQ(key, "message")) message = SvPV_nolen(ST(i + 1));
    }

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (pc) {
        /* Direct C call */
        char result[4096];
        memset(result, 0, sizeof(result));
        webview_dialog(&pc->wv, WEBVIEW_DIALOG_TYPE_ALERT, WEBVIEW_DIALOG_FLAG_ERROR, title, message, result, sizeof(result));
    } else {
        /* Fallback to Perl call for mocks */
        SV *wv;
        int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(*app_svp);
        PUTBACK;
        count = call_method("webview", G_SCALAR);
        SPAGAIN;
        wv = (count > 0) ? POPs : &PL_sv_undef;
        SvREFCNT_inc_simple_void(wv);
        PUTBACK;
        FREETMPS; LEAVE;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(wv);
        XPUSHs(sv_2mortal(newSViv(2)));        /* TYPE_ALERT */
        XPUSHs(sv_2mortal(newSViv(3 << 1)));   /* FLAG_ERROR */
        XPUSHs(sv_2mortal(newSVpv(title, 0)));
        XPUSHs(sv_2mortal(newSVpv(message, 0)));
        PUTBACK;
        call_method("dialog", G_DISCARD);
        FREETMPS; LEAVE;
        SvREFCNT_dec(wv);
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL
