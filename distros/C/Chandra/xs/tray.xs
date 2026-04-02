MODULE = Chandra    PACKAGE = Chandra

int
_tray_create(self, icon_path, tooltip, menu_json, callback)
    PerlChandra *self
    const char *icon_path
    const char *tooltip
    const char *menu_json
    SV *callback
PREINIT:
    int result;
CODE:
    memset(&self->tray, 0, sizeof(self->tray));
    self->tray.w = &self->wv;
    self->tray.icon_path = savepv(icon_path);
    self->tray.tooltip = savepv(tooltip);
    self->tray.item_count = 0;

    chandra_tray_parse_menu_json(menu_json, &self->tray);

    /* Set up callback */
    if (callback && SvOK(callback) && SvROK(callback)) {
        if (self->tray_callback) {
            SvREFCNT_dec(self->tray_callback);
        }
        self->tray_callback = SvREFCNT_inc(callback);
        self->tray.menu_cb = tray_menu_cb;
    } else {
        self->tray.menu_cb = NULL;
    }

    result = webview_tray_create(&self->tray);
    self->tray_active = (result == 0) ? 1 : 0;
    RETVAL = result;
OUTPUT:
    RETVAL

void
_tray_update(self, icon_path, tooltip, menu_json)
    PerlChandra *self
    const char *icon_path
    const char *tooltip
    const char *menu_json
CODE:
    if (!self->tray_active) return;

    if (self->tray.icon_path) Safefree((char *)self->tray.icon_path);
    if (self->tray.tooltip) Safefree((char *)self->tray.tooltip);
    self->tray.icon_path = savepv(icon_path);
    self->tray.tooltip = savepv(tooltip);

    chandra_tray_free_item_labels(&self->tray);
    self->tray.item_count = 0;
    chandra_tray_parse_menu_json(menu_json, &self->tray);

    webview_tray_update(&self->tray);

void
_tray_destroy(self)
    PerlChandra *self
CODE:
    if (self->tray_active) {
        webview_tray_destroy(&self->tray);
        self->tray_active = 0;
        if (self->tray.icon_path) {
            Safefree((char *)self->tray.icon_path);
            self->tray.icon_path = NULL;
        }
        if (self->tray.tooltip) {
            Safefree((char *)self->tray.tooltip);
            self->tray.tooltip = NULL;
        }
        if (self->tray_callback) {
            SvREFCNT_dec(self->tray_callback);
            self->tray_callback = NULL;
        }
    }

int
_tray_active(self)
    PerlChandra *self
CODE:
    RETVAL = self->tray_active;
OUTPUT:
    RETVAL

 # ============================================================
 # Chandra::Tray — high-level tray API (all in XS)
 # ============================================================

MODULE = Chandra    PACKAGE = Chandra::Tray

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;
    SV *app_sv = &PL_sv_undef;
    SV *icon_sv = newSVpvs("");
    SV *tooltip_sv = newSVpvs("");

    /* Parse key => value pairs */
    for (i = 1; i + 1 < items; i += 2) {
        const char *key;
        STRLEN key_len;
        key = SvPV(ST(i), key_len);
        if (key_len == 3 && strEQ(key, "app")) {
            app_sv = newSVsv(ST(i + 1));
        } else if (key_len == 4 && strEQ(key, "icon")) {
            SvREFCNT_dec(icon_sv);
            icon_sv = newSVsv(ST(i + 1));
        } else if (key_len == 7 && strEQ(key, "tooltip")) {
            SvREFCNT_dec(tooltip_sv);
            tooltip_sv = newSVsv(ST(i + 1));
        }
    }

    (void)hv_stores(self_hv, "app", SvOK(app_sv) ? app_sv : newSV(0));
    (void)hv_stores(self_hv, "icon", icon_sv);
    (void)hv_stores(self_hv, "tooltip", tooltip_sv);
    (void)hv_stores(self_hv, "_items", newRV_noinc((SV *)newAV()));
    (void)hv_stores(self_hv, "_next_id", newSViv(1));
    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_on_click", newSV(0));
    (void)hv_stores(self_hv, "_active", newSViv(0));
    (void)hv_stores(self_hv, "_pending", newSViv(0));

    if (!SvOK(app_sv))
        SvREFCNT_dec(app_sv);

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- add_item(label, handler?) ----

SV *
add_item(self, label_sv, ...)
    SV *self
    SV *label_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    SV **next_id_svp = hv_fetchs(hv, "_next_id", 0);
    SV **handlers_svp = hv_fetchs(hv, "_handlers", 0);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    AV *items_av;
    HV *handlers_hv;
    IV id;
    HV *entry;
    char id_str[32];
    int id_len;

    items_av = (AV *)SvRV(*items_svp);
    handlers_hv = (HV *)SvRV(*handlers_svp);
    id = SvIV(*next_id_svp);
    sv_setiv(*next_id_svp, id + 1);

    entry = newHV();
    (void)hv_stores(entry, "id", newSViv(id));
    (void)hv_stores(entry, "label", newSVsv(label_sv));
    av_push(items_av, newRV_noinc((SV *)entry));

    /* Store handler if provided */
    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) {
        id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)id);
        (void)hv_store(handlers_hv, id_str, id_len, newSVsv(ST(2)), 0);
    }

    /* _sync if active */
    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- add_separator() ----

SV *
add_separator(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    AV *items_av = (AV *)SvRV(*items_svp);
    HV *entry;

    entry = newHV();
    (void)hv_stores(entry, "id", newSViv(0));
    (void)hv_stores(entry, "separator", newSViv(1));
    av_push(items_av, newRV_noinc((SV *)entry));

    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- add_submenu(label, items_aref) ----

SV *
add_submenu(self, label_sv, sub_items_sv)
    SV *self
    SV *label_sv
    SV *sub_items_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp, **next_id_svp, **handlers_svp, **active_svp;
    AV *items_av, *sub_av, *out_sub;
    HV *handlers_hv, *entry;
    I32 si, sub_len;

    /* sub_items must be an array ref */
    if (!SvROK(sub_items_sv) || SvTYPE(SvRV(sub_items_sv)) != SVt_PVAV) {
        RETVAL = SvREFCNT_inc(self);
        goto done_add_submenu;
    }

    items_svp = hv_fetchs(hv, "_items", 0);
    next_id_svp = hv_fetchs(hv, "_next_id", 0);
    handlers_svp = hv_fetchs(hv, "_handlers", 0);
    active_svp = hv_fetchs(hv, "_active", 0);

    items_av = (AV *)SvRV(*items_svp);
    handlers_hv = (HV *)SvRV(*handlers_svp);
    sub_av = (AV *)SvRV(sub_items_sv);
    sub_len = av_len(sub_av) + 1;

    out_sub = newAV();

    for (si = 0; si < sub_len; si++) {
        SV **elem_svp = av_fetch(sub_av, si, 0);
        HV *elem_hv, *sub_entry;
        SV **lbl_svp, **hdl_svp;
        IV sub_id;
        char id_str[32];
        int id_len;

        if (!elem_svp || !SvROK(*elem_svp)) continue;
        elem_hv = (HV *)SvRV(*elem_svp);

        sub_id = SvIV(*next_id_svp);
        sv_setiv(*next_id_svp, sub_id + 1);

        sub_entry = newHV();
        (void)hv_stores(sub_entry, "id", newSViv(sub_id));

        lbl_svp = hv_fetchs(elem_hv, "label", 0);
        (void)hv_stores(sub_entry, "label",
            (lbl_svp && SvOK(*lbl_svp)) ? newSVsv(*lbl_svp) : newSVpvs(""));

        hdl_svp = hv_fetchs(elem_hv, "handler", 0);
        if (hdl_svp && SvROK(*hdl_svp) && SvTYPE(SvRV(*hdl_svp)) == SVt_PVCV) {
            id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)sub_id);
            (void)hv_store(handlers_hv, id_str, id_len, newSVsv(*hdl_svp), 0);
        }

        av_push(out_sub, newRV_noinc((SV *)sub_entry));
    }

    entry = newHV();
    (void)hv_stores(entry, "id", newSViv(0));
    (void)hv_stores(entry, "label", newSVsv(label_sv));
    (void)hv_stores(entry, "submenu", newRV_noinc((SV *)out_sub));
    av_push(items_av, newRV_noinc((SV *)entry));

    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
    done_add_submenu:
    ;
}
OUTPUT:
    RETVAL

 # ---- set_icon(icon) ----

SV *
set_icon(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    SV *icon_val;

    if (items > 1 && SvOK(ST(1))) {
        icon_val = newSVsv(ST(1));
    } else {
        icon_val = newSVpvs("");
    }
    (void)hv_stores(hv, "icon", icon_val);

    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- set_tooltip(tooltip) ----

SV *
set_tooltip(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    SV *tip_val;

    if (items > 1 && SvOK(ST(1))) {
        tip_val = newSVsv(ST(1));
    } else {
        tip_val = newSVpvs("");
    }
    (void)hv_stores(hv, "tooltip", tip_val);

    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- update_item(id_or_label, key => value, ...) ----

SV *
update_item(self, id_or_label_sv, ...)
    SV *self
    SV *id_or_label_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    SV **handlers_svp = hv_fetchs(hv, "_handlers", 0);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    AV *items_av = (AV *)SvRV(*items_svp);
    HV *handlers_hv = (HV *)SvRV(*handlers_svp);
    const char *search;
    STRLEN search_len;
    int is_numeric;
    IV search_id = 0;
    I32 ai, alen;

    search = SvPV(id_or_label_sv, search_len);
    /* Check if numeric: /^\d+$/ */
    is_numeric = 1;
    {
        STRLEN si;
        if (search_len == 0) is_numeric = 0;
        for (si = 0; si < search_len; si++) {
            if (search[si] < '0' || search[si] > '9') { is_numeric = 0; break; }
        }
    }
    if (is_numeric) search_id = SvIV(id_or_label_sv);

    alen = av_len(items_av) + 1;
    for (ai = 0; ai < alen; ai++) {
        SV **elem_svp = av_fetch(items_av, ai, 0);
        HV *elem_hv;
        SV **id_svp, **label_svp;
        int match = 0;

        if (!elem_svp || !SvROK(*elem_svp)) continue;
        elem_hv = (HV *)SvRV(*elem_svp);

        if (is_numeric) {
            id_svp = hv_fetchs(elem_hv, "id", 0);
            if (id_svp && SvOK(*id_svp) && SvIV(*id_svp) == search_id)
                match = 1;
        } else {
            label_svp = hv_fetchs(elem_hv, "label", 0);
            if (label_svp && SvOK(*label_svp)) {
                const char *lbl;
                STRLEN lbl_len;
                lbl = SvPV(*label_svp, lbl_len);
                if (lbl_len == search_len && memEQ(lbl, search, search_len))
                    match = 1;
            }
        }

        if (match) {
            /* Apply key => value pairs from args */
            I32 ki;
            for (ki = 2; ki + 1 < items; ki += 2) {
                const char *key;
                STRLEN key_len;
                key = SvPV(ST(ki), key_len);
                if (key_len == 5 && strEQ(key, "label")) {
                    (void)hv_stores(elem_hv, "label", newSVsv(ST(ki + 1)));
                } else if (key_len == 8 && strEQ(key, "disabled")) {
                    (void)hv_stores(elem_hv, "disabled",
                        newSViv(SvTRUE(ST(ki + 1)) ? 1 : 0));
                } else if (key_len == 7 && strEQ(key, "checked")) {
                    (void)hv_stores(elem_hv, "checked",
                        newSViv(SvTRUE(ST(ki + 1)) ? 1 : 0));
                } else if (key_len == 7 && strEQ(key, "handler")) {
                    if (SvROK(ST(ki + 1)) && SvTYPE(SvRV(ST(ki + 1))) == SVt_PVCV) {
                        SV **eid = hv_fetchs(elem_hv, "id", 0);
                        if (eid && SvOK(*eid)) {
                            char id_str[32];
                            int id_len = my_snprintf(id_str, sizeof(id_str),
                                "%ld", (long)SvIV(*eid));
                            (void)hv_store(handlers_hv, id_str, id_len,
                                newSVsv(ST(ki + 1)), 0);
                        }
                    }
                }
            }
            break;
        }
    }

    if (active_svp && SvIV(*active_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method("_sync", G_DISCARD);
        FREETMPS; LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_click(handler) ----

SV *
on_click(self, handler)
    SV *self
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_click", newSVsv(handler));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- items() — returns arrayref copy ----

SV *
items(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *src = (AV *)SvRV(*items_svp);
    AV *copy = newAV();
    I32 i, len = av_len(src) + 1;
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(src, i, 0);
        if (elem) av_push(copy, newSVsv(*elem));
    }
    RETVAL = newRV_noinc((SV *)copy);
}
OUTPUT:
    RETVAL

 # ---- item_count() ----

int
item_count(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *items_av = (AV *)SvRV(*items_svp);
    RETVAL = (int)(av_len(items_av) + 1);
}
OUTPUT:
    RETVAL

 # ---- is_active() ----

int
is_active(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    RETVAL = (active_svp && SvIV(*active_svp)) ? 1 : 0;
}
OUTPUT:
    RETVAL

 # ---- show() ----

SV *
show(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    SV **app_svp = hv_fetchs(hv, "app", 0);

    /* Already active — no-op */
    if (active_svp && SvIV(*active_svp)) {
        RETVAL = SvREFCNT_inc(self);
        goto done_show;
    }

    /* No app — return self */
    if (!app_svp || !SvOK(*app_svp)) {
        RETVAL = SvREFCNT_inc(self);
        goto done_show;
    }

    /* Check if app has _started */
    {
        SV *app = *app_svp;
        HV *app_hv;
        SV **started_svp;

        if (!SvROK(app)) {
            RETVAL = SvREFCNT_inc(self);
            goto done_show;
        }
        app_hv = (HV *)SvRV(app);
        started_svp = hv_fetchs(app_hv, "_started", 0);

        if (!started_svp || !SvTRUE(*started_svp)) {
            /* Defer — set pending flag */
            (void)hv_stores(hv, "_pending", newSViv(1));
            RETVAL = SvREFCNT_inc(self);
            goto done_show;
        }
    }

    /* Access PerlChandra* directly from app->{_webview} */
    {
        PerlChandra *pc = CHANDRA_PC_FROM_APP(*app_svp);
        SV *menu_json_sv;
        SV *dispatch_cb;
        SV **icon_svp = hv_fetchs(hv, "icon", 0);
        SV **tooltip_svp = hv_fetchs(hv, "tooltip", 0);
        const char *icon_str;
        const char *tooltip_str;
        int result;

        if (!pc) {
            (void)hv_stores(hv, "_pending", newSViv(0));
            RETVAL = SvREFCNT_inc(self);
            goto done_show;
        }

        icon_str = (icon_svp && SvOK(*icon_svp)) ? SvPV_nolen(*icon_svp) : "";
        tooltip_str = (tooltip_svp && SvOK(*tooltip_svp)) ? SvPV_nolen(*tooltip_svp) : "";

        /* Build menu JSON directly */
        menu_json_sv = chandra_tray_build_menu_json(aTHX_ self);

        /* Build dispatch callback */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            PUTBACK;
            count = call_method("_make_dispatch_callback", G_SCALAR);
            SPAGAIN;
            dispatch_cb = (count > 0) ? newSVsv(POPs) : newSV(0);
            PUTBACK;
            FREETMPS; LEAVE;
        }

        /* Directly set up the tray on the PerlChandra struct */
        memset(&pc->tray, 0, sizeof(pc->tray));
        pc->tray.w = &pc->wv;
        pc->tray.icon_path = savepv(icon_str);
        pc->tray.tooltip = savepv(tooltip_str);
        pc->tray.item_count = 0;

        chandra_tray_parse_menu_json(SvPV_nolen(menu_json_sv), &pc->tray);
        SvREFCNT_dec(menu_json_sv);

        /* Set up callback */
        if (dispatch_cb && SvOK(dispatch_cb) && SvROK(dispatch_cb)) {
            if (pc->tray_callback) SvREFCNT_dec(pc->tray_callback);
            pc->tray_callback = SvREFCNT_inc(dispatch_cb);
            pc->tray.menu_cb = tray_menu_cb;
        } else {
            pc->tray.menu_cb = NULL;
        }
        SvREFCNT_dec(dispatch_cb);

        result = webview_tray_create(&pc->tray);
        pc->tray_active = (result == 0) ? 1 : 0;

        if (result == 0)
            (void)hv_stores(hv, "_active", newSViv(1));
        (void)hv_stores(hv, "_pending", newSViv(0));
    }

    RETVAL = SvREFCNT_inc(self);
    done_show:
    ;
}
OUTPUT:
    RETVAL

 # ---- remove() ----

SV *
remove(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);

    if (active_svp && SvIV(*active_svp)) {
        SV **app_svp = hv_fetchs(hv, "app", 0);
        if (app_svp && SvOK(*app_svp)) {
            PerlChandra *pc = CHANDRA_PC_FROM_APP(*app_svp);
            if (pc && pc->tray_active) {
                webview_tray_destroy(&pc->tray);
                pc->tray_active = 0;
                if (pc->tray.icon_path) {
                    Safefree((char *)pc->tray.icon_path);
                    pc->tray.icon_path = NULL;
                }
                if (pc->tray.tooltip) {
                    Safefree((char *)pc->tray.tooltip);
                    pc->tray.tooltip = NULL;
                }
                if (pc->tray_callback) {
                    SvREFCNT_dec(pc->tray_callback);
                    pc->tray_callback = NULL;
                }
            }
        }
        (void)hv_stores(hv, "_active", newSViv(0));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- _sync() — update the native tray if active ----

void
_sync(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **active_svp = hv_fetchs(hv, "_active", 0);
    SV **app_svp = hv_fetchs(hv, "app", 0);
    PerlChandra *pc;

    if (!active_svp || !SvIV(*active_svp)) return;
    if (!app_svp || !SvOK(*app_svp)) return;

    pc = CHANDRA_PC_FROM_APP(*app_svp);
    if (!pc || !pc->tray_active) return;

    {
        SV *menu_json_sv;
        SV **icon_svp = hv_fetchs(hv, "icon", 0);
        SV **tooltip_svp = hv_fetchs(hv, "tooltip", 0);
        const char *icon_str, *tooltip_str;

        icon_str = (icon_svp && SvOK(*icon_svp)) ? SvPV_nolen(*icon_svp) : "";
        tooltip_str = (tooltip_svp && SvOK(*tooltip_svp)) ? SvPV_nolen(*tooltip_svp) : "";

        /* Build menu JSON directly */
        menu_json_sv = chandra_tray_build_menu_json(aTHX_ self);

        /* Update tray struct directly */
        if (pc->tray.icon_path) Safefree((char *)pc->tray.icon_path);
        if (pc->tray.tooltip) Safefree((char *)pc->tray.tooltip);
        pc->tray.icon_path = savepv(icon_str);
        pc->tray.tooltip = savepv(tooltip_str);

        chandra_tray_free_item_labels(&pc->tray);
        pc->tray.item_count = 0;
        chandra_tray_parse_menu_json(SvPV_nolen(menu_json_sv), &pc->tray);
        SvREFCNT_dec(menu_json_sv);

        webview_tray_update(&pc->tray);
    }
}

 # ---- _menu_json() — build JSON array from items ----

SV *
_menu_json(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *items_av = (AV *)SvRV(*items_svp);
    I32 i, len = av_len(items_av) + 1;
    dSP;
    int count;

    /* Use Cpanel::JSON::XS to encode — build a Perl array, then encode it */
    {
        AV *out = newAV();

        for (i = 0; i < len; i++) {
            SV **elem_svp = av_fetch(items_av, i, 0);
            HV *elem_hv, *out_entry;
            SV **sep_svp, **sub_svp, **id_svp, **lbl_svp, **dis_svp, **chk_svp;

            if (!elem_svp || !SvROK(*elem_svp)) continue;
            elem_hv = (HV *)SvRV(*elem_svp);

            sep_svp = hv_fetchs(elem_hv, "separator", 0);
            if (sep_svp && SvTRUE(*sep_svp)) {
                out_entry = newHV();
                (void)hv_stores(out_entry, "separator", newSViv(1));
                av_push(out, newRV_noinc((SV *)out_entry));
                continue;
            }

            sub_svp = hv_fetchs(elem_hv, "submenu", 0);
            if (sub_svp && SvROK(*sub_svp)) {
                /* Flatten: emit parent label, then indented children */
                AV *sub_av = (AV *)SvRV(*sub_svp);
                I32 si, slen = av_len(sub_av) + 1;

                id_svp = hv_fetchs(elem_hv, "id", 0);
                lbl_svp = hv_fetchs(elem_hv, "label", 0);

                out_entry = newHV();
                (void)hv_stores(out_entry, "id",
                    newSViv((id_svp && SvOK(*id_svp)) ? SvIV(*id_svp) : 0));
                (void)hv_stores(out_entry, "label",
                    (lbl_svp && SvOK(*lbl_svp)) ? newSVsv(*lbl_svp) : newSVpvs(""));
                av_push(out, newRV_noinc((SV *)out_entry));

                for (si = 0; si < slen; si++) {
                    SV **sub_elem = av_fetch(sub_av, si, 0);
                    HV *sub_hv, *sub_out;
                    SV **sid_svp, **slbl_svp;

                    if (!sub_elem || !SvROK(*sub_elem)) continue;
                    sub_hv = (HV *)SvRV(*sub_elem);

                    sid_svp = hv_fetchs(sub_hv, "id", 0);
                    slbl_svp = hv_fetchs(sub_hv, "label", 0);

                    sub_out = newHV();
                    (void)hv_stores(sub_out, "id",
                        newSViv((sid_svp && SvOK(*sid_svp)) ? SvIV(*sid_svp) : 0));
                    {
                        SV *prefixed = newSVpvs("  ");
                        if (slbl_svp && SvOK(*slbl_svp))
                            sv_catsv(prefixed, *slbl_svp);
                        (void)hv_stores(sub_out, "label", prefixed);
                    }
                    av_push(out, newRV_noinc((SV *)sub_out));
                }
                continue;
            }

            /* Regular item */
            id_svp = hv_fetchs(elem_hv, "id", 0);
            lbl_svp = hv_fetchs(elem_hv, "label", 0);
            dis_svp = hv_fetchs(elem_hv, "disabled", 0);
            chk_svp = hv_fetchs(elem_hv, "checked", 0);

            out_entry = newHV();
            (void)hv_stores(out_entry, "id",
                newSViv((id_svp && SvOK(*id_svp)) ? SvIV(*id_svp) : 0));
            (void)hv_stores(out_entry, "label",
                (lbl_svp && SvOK(*lbl_svp)) ? newSVsv(*lbl_svp) : newSVpvs(""));
            if (dis_svp && SvTRUE(*dis_svp))
                (void)hv_stores(out_entry, "disabled", newSViv(1));
            if (chk_svp && SvTRUE(*chk_svp))
                (void)hv_stores(out_entry, "checked", newSViv(1));
            av_push(out, newRV_noinc((SV *)out_entry));
        }

        /* Encode via Cpanel::JSON::XS->new->utf8->allow_nonref->encode(\@out) */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Cpanel::JSON::XS")));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            SV *json_obj = POPs;

            PUSHMARK(SP);
            XPUSHs(json_obj);
            PUTBACK;
            call_method("utf8", G_SCALAR);
            SPAGAIN;
            json_obj = POPs;

            PUSHMARK(SP);
            XPUSHs(json_obj);
            PUTBACK;
            call_method("allow_nonref", G_SCALAR);
            SPAGAIN;
            json_obj = POPs;

            PUSHMARK(SP);
            XPUSHs(json_obj);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)out)));
            PUTBACK;
            count = call_method("encode", G_SCALAR);
            SPAGAIN;
            RETVAL = (count > 0) ? newSVsv(POPs) : newSVpvs("[]");
        } else {
            SvREFCNT_dec((SV *)out);
            RETVAL = newSVpvs("[]");
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }
}
OUTPUT:
    RETVAL

 # ---- _make_dispatch_callback() ----

SV *
_make_dispatch_callback(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **handlers_svp = hv_fetchs(hv, "_handlers", 0);
    SV **on_click_svp = hv_fetchs(hv, "_on_click", 0);
    SV *handlers_ref = newSVsv(*handlers_svp);
    SV *on_click_ref = (on_click_svp && SvOK(*on_click_svp))
        ? newSVsv(*on_click_svp) : newSV(0);
    CV *cv;

    /* Build a closure that captures handlers and on_click.
       We use a small Perl wrapper via eval_pv at compile time,
       but actually we build the callback in C using a pad. */

    /* Simpler approach: call back into Perl to build the closure */
    {
        dSP;
        int count;
        SV *code_sv;

        ENTER; SAVETMPS;

        /* Create closure via: sub { my ($id) = @_; ... } */
        code_sv = newSVpvs(
            "sub {"
            "  my ($handlers, $on_click) = @{$_[0]};"
            "  return sub {"
            "    my ($item_id) = @_;"
            "    if ($item_id == -1 && $on_click) {"
            "      $on_click->(); return;"
            "    }"
            "    if ($handlers->{$item_id}) {"
            "      $handlers->{$item_id}->();"
            "    }"
            "  };"
            "}"
        );

        /* eval the factory */
        PUSHMARK(SP);
        PUTBACK;
        {
            SV *factory = eval_pv(SvPV_nolen(code_sv), 1);
            SvREFCNT_dec(code_sv);

            /* Call factory->([handlers, on_click]) */
            {
                AV *args = newAV();
                av_push(args, handlers_ref);
                av_push(args, on_click_ref);

                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_noinc((SV *)args)));
                PUTBACK;
                count = call_sv(factory, G_SCALAR);
                SPAGAIN;
                RETVAL = (count > 0) ? newSVsv(POPs) : newSV(0);
            }
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }
}
OUTPUT:
    RETVAL
