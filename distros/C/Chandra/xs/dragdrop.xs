MODULE = Chandra    PACKAGE = Chandra::DragDrop

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        }
    }

    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_drop_zones", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_draggables", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_enabled", newSViv(1));
    (void)hv_stores(self_hv, "_injected", newSViv(0));
    (void)hv_stores(self_hv, "_dispatch_bound", newSViv(0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- on_file_drop($coderef) ----

SV *
on_file_drop(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **h_svp = hv_fetchs(hv, "_handlers", 0);
    HV *handlers = (HV *)SvRV(*h_svp);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("on_file_drop() requires a coderef");
    (void)hv_stores(handlers, "file_drop", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_text_drop($coderef) ----

SV *
on_text_drop(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **h_svp = hv_fetchs(hv, "_handlers", 0);
    HV *handlers = (HV *)SvRV(*h_svp);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("on_text_drop() requires a coderef");
    (void)hv_stores(handlers, "text_drop", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_drag_enter($coderef) ----

SV *
on_drag_enter(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **h_svp = hv_fetchs(hv, "_handlers", 0);
    HV *handlers = (HV *)SvRV(*h_svp);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("on_drag_enter() requires a coderef");
    (void)hv_stores(handlers, "drag_enter", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_drag_leave($coderef) ----

SV *
on_drag_leave(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **h_svp = hv_fetchs(hv, "_handlers", 0);
    HV *handlers = (HV *)SvRV(*h_svp);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("on_drag_leave() requires a coderef");
    (void)hv_stores(handlers, "drag_leave", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- on_internal_drop($coderef) ----

SV *
on_internal_drop(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **h_svp = hv_fetchs(hv, "_handlers", 0);
    HV *handlers = (HV *)SvRV(*h_svp);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("on_internal_drop() requires a coderef");
    (void)hv_stores(handlers, "internal_drop", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- add_drop_zone($selector, $coderef) ----

SV *
add_drop_zone(self, selector, callback)
    SV *self
    SV *selector
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dz_svp = hv_fetchs(hv, "_drop_zones", 0);
    HV *zones = (HV *)SvRV(*dz_svp);
    STRLEN slen;
    const char *sel = SvPV(selector, slen);
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("add_drop_zone() requires a coderef");
    (void)hv_store(zones, sel, (I32)slen, newSVsv(callback), 0);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- remove_drop_zone($selector) ----

SV *
remove_drop_zone(self, selector)
    SV *self
    SV *selector
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dz_svp = hv_fetchs(hv, "_drop_zones", 0);
    HV *zones = (HV *)SvRV(*dz_svp);
    STRLEN slen;
    const char *sel = SvPV(selector, slen);
    (void)hv_delete(zones, sel, (I32)slen, G_DISCARD);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- drop_zones() — list registered selectors ----

void
drop_zones(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dz_svp = hv_fetchs(hv, "_drop_zones", 0);
    HV *zones = (HV *)SvRV(*dz_svp);
    HE *entry;
    hv_iterinit(zones);
    while ((entry = hv_iternext(zones)) != NULL) {
        I32 klen;
        const char *key = hv_iterkey(entry, &klen);
        XPUSHs(sv_2mortal(newSVpvn(key, klen)));
    }
}

 # ---- make_draggable($selector, %opts) ----

SV *
make_draggable(self, selector, ...)
    SV *self
    SV *selector
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dr_svp = hv_fetchs(hv, "_draggables", 0);
    HV *drags = (HV *)SvRV(*dr_svp);
    STRLEN slen;
    const char *sel = SvPV(selector, slen);
    HV *opts = newHV();
    I32 i;

    for (i = 2; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "data")) {
            (void)hv_stores(opts, "data", newSVsv(val));
        } else if (strEQ(key, "data_from")) {
            (void)hv_stores(opts, "data_from", newSVsv(val));
        }
    }

    (void)hv_store(drags, sel, (I32)slen, newRV_noinc((SV *)opts), 0);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- remove_draggable($selector) ----

SV *
remove_draggable(self, selector)
    SV *self
    SV *selector
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dr_svp = hv_fetchs(hv, "_draggables", 0);
    HV *drags = (HV *)SvRV(*dr_svp);
    STRLEN slen;
    const char *sel = SvPV(selector, slen);
    (void)hv_delete(drags, sel, (I32)slen, G_DISCARD);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- enable / disable ----

SV *
enable(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_enabled", newSViv(1));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
disable(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_enabled", newSViv(0));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

SV *
is_enabled(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **en_svp = hv_fetchs(hv, "_enabled", 0);
    RETVAL = newSViv(en_svp && SvTRUE(*en_svp) ? 1 : 0);
}
OUTPUT:
    RETVAL

 # ---- _dispatch(json_sv) — called from JS via __chandra_dragdrop bind ----

void
_dispatch(self, json_sv)
    SV *self
    SV *json_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **en_svp = hv_fetchs(hv, "_enabled", 0);
    SV **h_svp, **dz_svp;
    HV *handlers, *zones;
    SV *event_hv_sv;
    HV *event_hv;
    SV **type_svp;
    const char *type;

    /* Check enabled */
    if (!en_svp || !SvTRUE(*en_svp)) goto done_dispatch;

    h_svp = hv_fetchs(hv, "_handlers", 0);
    handlers = (HV *)SvRV(*h_svp);
    dz_svp = hv_fetchs(hv, "_drop_zones", 0);
    zones = (HV *)SvRV(*dz_svp);

    /* Decode JSON */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(json_sv);
        PUTBACK;
        count = call_pv("Cpanel::JSON::XS::decode_json", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV) || count < 1) {
            FREETMPS; LEAVE;
            goto done_dispatch;
        }
        event_hv_sv = newSVsv(POPs);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    if (!SvROK(event_hv_sv) || SvTYPE(SvRV(event_hv_sv)) != SVt_PVHV) {
        SvREFCNT_dec(event_hv_sv);
        goto done_dispatch;
    }

    event_hv = (HV *)SvRV(event_hv_sv);
    type_svp = hv_fetchs(event_hv, "type", 0);
    if (!type_svp || !SvOK(*type_svp)) {
        SvREFCNT_dec(event_hv_sv);
        goto done_dispatch;
    }
    type = SvPV_nolen(*type_svp);

    /* File drop */
    if (strEQ(type, "file_drop")) {
        SV **files_svp = hv_fetchs(event_hv, "files", 0);
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        SV **zone_svp = hv_fetchs(event_hv, "zone", 0);
        AV *files_av;

        if (!files_svp || !SvROK(*files_svp)) {
            SvREFCNT_dec(event_hv_sv);
            goto done_dispatch;
        }
        files_av = (AV *)SvRV(*files_svp);

        /* Skip if no files */
        if (av_len(files_av) < 0) {
            SvREFCNT_dec(event_hv_sv);
            goto done_dispatch;
        }

        /* Check zone-specific handler first */
        if (zone_svp && SvOK(*zone_svp)) {
            STRLEN zlen;
            const char *zstr = SvPV(*zone_svp, zlen);
            SV **cb_svp = hv_fetch(zones, zstr, (I32)zlen, 0);
            if (cb_svp && SvROK(*cb_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_inc((SV *)files_av)));
                if (target_svp && SvOK(*target_svp))
                    XPUSHs(*target_svp);
                PUTBACK;
                call_sv(*cb_svp, G_DISCARD | G_EVAL);
                if (SvTRUE(ERRSV))
                    warn("DragDrop zone handler error: %s", SvPV_nolen(ERRSV));
                FREETMPS; LEAVE;
            }
        }

        /* Global file_drop handler */
        {
            SV **cb_svp = hv_fetchs(handlers, "file_drop", 0);
            if (cb_svp && SvROK(*cb_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_inc((SV *)files_av)));
                if (target_svp && SvOK(*target_svp))
                    XPUSHs(*target_svp);
                PUTBACK;
                call_sv(*cb_svp, G_DISCARD | G_EVAL);
                if (SvTRUE(ERRSV))
                    warn("DragDrop file_drop handler error: %s", SvPV_nolen(ERRSV));
                FREETMPS; LEAVE;
            }
        }
    }

    /* Text drop */
    else if (strEQ(type, "text_drop")) {
        SV **text_svp = hv_fetchs(event_hv, "text", 0);
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        SV **cb_svp = hv_fetchs(handlers, "text_drop", 0);
        if (cb_svp && SvROK(*cb_svp) && text_svp && SvOK(*text_svp)) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(*text_svp);
            if (target_svp && SvOK(*target_svp))
                XPUSHs(*target_svp);
            PUTBACK;
            call_sv(*cb_svp, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("DragDrop text_drop handler error: %s", SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
        }
    }

    /* Drag enter */
    else if (strEQ(type, "drag_enter")) {
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        SV **cb_svp = hv_fetchs(handlers, "drag_enter", 0);
        if (cb_svp && SvROK(*cb_svp)) {
            SV *result;
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            if (target_svp && SvOK(*target_svp))
                XPUSHs(*target_svp);
            PUTBACK;
            count = call_sv(*cb_svp, G_SCALAR | G_EVAL);
            SPAGAIN;
            if (SvTRUE(ERRSV)) {
                warn("DragDrop drag_enter handler error: %s", SvPV_nolen(ERRSV));
            } else if (count > 0) {
                result = POPs;
                /* Return CSS class to JS for visual feedback */
                if (SvOK(result)) {
                    SV **app_svp = hv_fetchs(hv, "app", 0);
                    if (app_svp && SvOK(*app_svp)) {
                        SV *tgt_id = NULL;
                        if (target_svp && SvROK(*target_svp)
                            && SvTYPE(SvRV(*target_svp)) == SVt_PVHV) {
                            SV **id_svp = hv_fetchs((HV *)SvRV(*target_svp), "id", 0);
                            if (id_svp && SvOK(*id_svp)) tgt_id = *id_svp;
                        }
                        if (tgt_id) {
                            SV *js = newSVpvf(
                                "var _el=document.getElementById('%s');"
                                "if(_el)_el.classList.add('%s');",
                                SvPV_nolen(tgt_id),
                                SvPV_nolen(result)
                            );
                            PUSHMARK(SP);
                            XPUSHs(*app_svp);
                            XPUSHs(sv_2mortal(js));
                            PUTBACK;
                            call_method("eval", G_DISCARD);
                        }
                    }
                }
            }
            PUTBACK;
            FREETMPS; LEAVE;
        }
    }

    /* Drag leave */
    else if (strEQ(type, "drag_leave")) {
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        SV **cb_svp = hv_fetchs(handlers, "drag_leave", 0);
        if (cb_svp && SvROK(*cb_svp)) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            if (target_svp && SvOK(*target_svp))
                XPUSHs(*target_svp);
            PUTBACK;
            call_sv(*cb_svp, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("DragDrop drag_leave handler error: %s", SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
        }
    }

    /* Internal drop (intra-app drag) */
    else if (strEQ(type, "internal_drop")) {
        SV **data_svp = hv_fetchs(event_hv, "data", 0);
        SV **source_svp = hv_fetchs(event_hv, "source", 0);
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        SV **cb_svp = hv_fetchs(handlers, "internal_drop", 0);
        if (cb_svp && SvROK(*cb_svp)) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            if (data_svp && SvOK(*data_svp))
                XPUSHs(*data_svp);
            else
                XPUSHs(&PL_sv_undef);
            if (source_svp && SvOK(*source_svp))
                XPUSHs(*source_svp);
            else
                XPUSHs(&PL_sv_undef);
            if (target_svp && SvOK(*target_svp))
                XPUSHs(*target_svp);
            else
                XPUSHs(&PL_sv_undef);
            PUTBACK;
            call_sv(*cb_svp, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("DragDrop internal_drop handler error: %s", SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
        }
    }

    SvREFCNT_dec(event_hv_sv);

    done_dispatch:
    ;
}

 # ---- js_code() — returns JavaScript for drag & drop handling ----

SV *
js_code(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **dz_svp = hv_fetchs(hv, "_drop_zones", 0);
    SV **dr_svp = hv_fetchs(hv, "_draggables", 0);
    HV *zones = (HV *)SvRV(*dz_svp);
    HV *drags = (HV *)SvRV(*dr_svp);
    SV *js;

    js = newSVpvs(
        "(function(){\n"
        "if(window.__chandraDragDrop)return;\n"
        "var zones=["
    );

    /* Emit zone selectors */
    {
        HE *entry;
        int first = 1;
        hv_iterinit(zones);
        while ((entry = hv_iternext(zones)) != NULL) {
            I32 klen;
            const char *key = hv_iterkey(entry, &klen);
            if (!first) sv_catpvs(js, ",");
            sv_catpvs(js, "'");
            sv_catpvn(js, key, klen);
            sv_catpvs(js, "'");
            first = 0;
        }
    }

    sv_catpvs(js, "];\n");

    /* Emit draggable config */
    sv_catpvs(js, "var draggables=[");
    {
        HE *entry;
        int first = 1;
        hv_iterinit(drags);
        while ((entry = hv_iternext(drags)) != NULL) {
            I32 klen;
            const char *key = hv_iterkey(entry, &klen);
            SV *val = HeVAL(entry);
            const char *data_from = NULL;

            if (!first) sv_catpvs(js, ",");
            sv_catpvs(js, "{sel:'");
            sv_catpvn(js, key, klen);
            sv_catpvs(js, "'");

            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *opts = (HV *)SvRV(val);
                SV **df_svp = hv_fetchs(opts, "data_from", 0);
                SV **d_svp = hv_fetchs(opts, "data", 0);
                if (df_svp && SvOK(*df_svp)) {
                    sv_catpvs(js, ",dataFrom:'");
                    sv_catpv(js, SvPV_nolen(*df_svp));
                    sv_catpvs(js, "'");
                } else if (d_svp && SvOK(*d_svp)) {
                    /* Encode data to JSON */
                    dSP;
                    int count;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*d_svp);
                    PUTBACK;
                    count = call_pv("Cpanel::JSON::XS::encode_json", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV) && count > 0) {
                        SV *json = POPs;
                        sv_catpvs(js, ",data:");
                        sv_catsv(js, json);
                    }
                    PUTBACK;
                    FREETMPS; LEAVE;
                }
            }

            sv_catpvs(js, "}");
            first = 0;
        }
    }

    sv_catpvs(js, "];\n");

    /* Core drag-drop JS */
    sv_catpvs(js,
        "var _dragData=null;\n"

        "function elemInfo(el){\n"
        "return {id:el.id||'',class:el.className||'',tag:el.tagName||''};\n"
        "}\n"

        "function matchZone(el){\n"
        "for(var i=0;i<zones.length;i++){\n"
        "var z=el.closest(zones[i]);\n"
        "if(z)return zones[i];\n"
        "}\n"
        "return null;\n"
        "}\n"

        /* Prevent default on dragover to allow drop */
        "document.addEventListener('dragover',function(e){\n"
        "e.preventDefault();\n"
        "},true);\n"

        /* dragenter */
        "document.addEventListener('dragenter',function(e){\n"
        "e.preventDefault();\n"
        "window.chandra.invoke('__chandra_dragdrop',[JSON.stringify({\n"
        "type:'drag_enter',target:elemInfo(e.target)\n"
        "})]);\n"
        "},true);\n"

        /* dragleave */
        "document.addEventListener('dragleave',function(e){\n"
        "window.chandra.invoke('__chandra_dragdrop',[JSON.stringify({\n"
        "type:'drag_leave',target:elemInfo(e.target)\n"
        "})]);\n"
        "},true);\n"

        /* drop */
        "document.addEventListener('drop',function(e){\n"
        "e.preventDefault();\n"
        "var tgt=elemInfo(e.target);\n"
        "var zone=matchZone(e.target);\n"

        /* Internal drop (intra-app drag) */
        "if(_dragData){\n"
        "var _srcEl=_dragData.sourceEl;\n"
        "var _tgtEl=e.target;\n"
        /* Walk up past any draggable elements to find the container */
        "while(_tgtEl&&_tgtEl.getAttribute&&_tgtEl.getAttribute('draggable')==='true'&&_tgtEl.parentElement){\n"
        "_tgtEl=_tgtEl.parentElement;\n"
        "}\n"
        "if(_tgtEl&&_tgtEl.closest){\n"
        "var _zs=matchZone(_tgtEl);\n"
        "if(_zs)_tgtEl=_tgtEl.closest(_zs);\n"
        "}\n"
        "if(_srcEl&&_tgtEl&&_srcEl!==_tgtEl&&!_srcEl.contains(_tgtEl))_tgtEl.appendChild(_srcEl);\n"
        "window.chandra.invoke('__chandra_dragdrop',[JSON.stringify({\n"
        "type:'internal_drop',data:_dragData.data,source:_dragData.source,\n"
        "target:elemInfo(_tgtEl)\n"
        "})]);\n"
        "_dragData=null;\n"
        "return;\n"
        "}\n"

        /* File drop */
        "var files=[];\n"
        "if(e.dataTransfer&&e.dataTransfer.files){\n"
        "for(var i=0;i<e.dataTransfer.files.length;i++){\n"
        "var f=e.dataTransfer.files[i];\n"
        "files.push(f.path||f.name);\n"
        "}\n"
        "}\n"
        "if(files.length>0){\n"
        "window.chandra.invoke('__chandra_dragdrop',[JSON.stringify({\n"
        "type:'file_drop',files:files,target:tgt,zone:zone\n"
        "})]);\n"
        "return;\n"
        "}\n"

        /* Text drop */
        "var text=e.dataTransfer?e.dataTransfer.getData('text/plain'):'';\n"
        "if(text){\n"
        "window.chandra.invoke('__chandra_dragdrop',[JSON.stringify({\n"
        "type:'text_drop',text:text,target:tgt\n"
        "})]);\n"
        "}\n"
        "},true);\n"

        /* Setup draggable elements */
        "draggables.forEach(function(cfg){\n"
        "var els=document.querySelectorAll(cfg.sel);\n"
        "els.forEach(function(el){\n"
        "el.setAttribute('draggable','true');\n"
        "el.addEventListener('dragstart',function(e){\n"
        "var data=cfg.data||null;\n"
        "if(cfg.dataFrom){\n"
        "var attr=el.getAttribute(cfg.dataFrom);\n"
        "try{data=JSON.parse(attr);}catch(_){data=attr;}\n"
        "}\n"
        "_dragData={data:data,source:elemInfo(el),sourceEl:el};\n"
        "e.dataTransfer.effectAllowed='move';\n"
        "});\n"
        "});\n"
        "});\n"

        "window.__chandraDragDrop={zones:zones,draggables:draggables};\n"
        "})();\n"
    );

    RETVAL = js;
}
OUTPUT:
    RETVAL

 # ---- inject() — inject JS via app->eval ----

SV *
inject(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **injected_svp;

    injected_svp = hv_fetchs(hv, "_injected", 0);
    if (injected_svp && SvTRUE(*injected_svp)) {
        RETVAL = SvREFCNT_inc(self);
    } else {
        SV *js;

        (void)hv_stores(hv, "_injected", newSViv(1));

        /* Bind __chandra_dragdrop dispatch if not already done */
        {
            SV **db_svp = hv_fetchs(hv, "_dispatch_bound", 0);
            if (!db_svp || !SvTRUE(*db_svp)) {
                SV **app_svp = hv_fetchs(hv, "app", 0);
                if (app_svp && SvOK(*app_svp)) {
                    SV *dd_self_ref = newSVsv(self);
                    CV *wrapper_cv;

                    sv_rvweaken(dd_self_ref);
                    wrapper_cv = newXS(NULL, XS_Chandra__DragDrop__dispatch_trampoline, __FILE__);
                    CvXSUBANY(wrapper_cv).any_ptr = (void *)dd_self_ref;
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(*app_svp);
                        XPUSHs(sv_2mortal(newSVpvs("__chandra_dragdrop")));
                        XPUSHs(sv_2mortal(newRV_noinc((SV *)wrapper_cv)));
                        PUTBACK;
                        call_method("bind", G_DISCARD);
                        FREETMPS; LEAVE;
                    }
                    (void)hv_stores(hv, "_dispatch_bound", newSViv(1));
                }
            }
        }

        /* Get JS code */
        {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            PUTBACK;
            count = call_method("js_code", G_SCALAR);
            SPAGAIN;
            js = (count > 0) ? newSVsv(POPs) : newSVpvs("");
            PUTBACK;
            FREETMPS; LEAVE;
        }

        /* Call $self->{app}->eval($js) */
        {
            SV **app_svp = hv_fetchs(hv, "app", 0);
            if (app_svp && SvOK(*app_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*app_svp);
                XPUSHs(sv_2mortal(js));
                PUTBACK;
                call_method("eval", G_DISCARD);
                FREETMPS; LEAVE;
            } else {
                SvREFCNT_dec(js);
            }
        }

        RETVAL = SvREFCNT_inc(self);
    }
}
OUTPUT:
    RETVAL
