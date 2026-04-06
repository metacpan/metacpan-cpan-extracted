MODULE = Chandra    PACKAGE = Chandra::ContextMenu

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    AV *items_av = newAV();
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        } else if (strEQ(key, "items")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                SvREFCNT_dec(items_av);
                items_av = (AV *)SvRV(val);
                SvREFCNT_inc((SV *)items_av);
            }
        } else if (strEQ(key, "mode")) {
            (void)hv_stores(self_hv, "mode", newSVsv(val));
        }
    }

    (void)hv_stores(self_hv, "_items", newRV_noinc((SV *)items_av));
    (void)hv_stores(self_hv, "_attachments", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_actions", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_next_id", newSViv(1));
    (void)hv_stores(self_hv, "_enabled", newSViv(1));
    (void)hv_stores(self_hv, "_injected", newSViv(0));
    (void)hv_stores(self_hv, "_dispatch_bound", newSViv(0));
    (void)hv_stores(self_hv, "_global", newSViv(0));

    /* Set default mode */
    {
        SV **mode_svp = hv_fetchs(self_hv, "mode", 0);
        if (!mode_svp || !SvOK(*mode_svp))
            (void)hv_stores(self_hv, "mode", newSVpvs("html"));
    }

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- attach(selector, [dynamic_cb]) ----

SV *
attach(self, selector, ...)
    SV *self
    SV *selector
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **att_svp = hv_fetchs(hv, "_attachments", 0);
    HV *att_hv = (HV *)SvRV(*att_svp);
    const char *sel;
    STRLEN sel_len;

    if (!SvOK(selector))
        croak("attach() requires a CSS selector string");

    sel = SvPV(selector, sel_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) {
        /* Dynamic callback: store coderef */
        (void)hv_store(att_hv, sel, sel_len, newSVsv(ST(2)), 0);
    } else {
        /* Static: store 1 as marker */
        (void)hv_store(att_hv, sel, sel_len, newSViv(1), 0);
    }

    /* Register actions from items */
    {
        SV **items_svp = hv_fetchs(hv, "_items", 0);
        SV **actions_svp = hv_fetchs(hv, "_actions", 0);
        if (items_svp && SvROK(*items_svp) && actions_svp && SvROK(*actions_svp)) {
            _cm_register_actions(aTHX_ hv, (AV *)SvRV(*items_svp),
                (HV *)SvRV(*actions_svp));
        }
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- detach(selector) ----

SV *
detach(self, selector)
    SV *self
    SV *selector
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **att_svp = hv_fetchs(hv, "_attachments", 0);
    HV *att_hv = (HV *)SvRV(*att_svp);
    STRLEN sel_len;
    const char *sel = SvPV(selector, sel_len);
    (void)hv_delete(att_hv, sel, sel_len, G_DISCARD);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- attach_global() ----

SV *
attach_global(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_global", newSViv(1));

    if (items > 1 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
        (void)hv_stores(hv, "_global_dynamic", newSVsv(ST(1)));
    }

    /* Register actions */
    {
        SV **items_svp = hv_fetchs(hv, "_items", 0);
        SV **actions_svp = hv_fetchs(hv, "_actions", 0);
        if (items_svp && SvROK(*items_svp) && actions_svp && SvROK(*actions_svp)) {
            _cm_register_actions(aTHX_ hv, (AV *)SvRV(*items_svp),
                (HV *)SvRV(*actions_svp));
        }
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- detach_global() ----

SV *
detach_global(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_global", newSViv(0));
    (void)hv_delete(hv, "_global_dynamic", 16, G_DISCARD);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- show_at(x, y) ----

SV *
show_at(self, x, y)
    SV *self
    NV x
    NV y
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_show_x", newSVnv(x));
    (void)hv_stores(hv, "_show_y", newSVnv(y));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- set_item(label, key => value, ...) ----

SV *
set_item(self, label_sv, ...)
    SV *self
    SV *label_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *items_av;
    const char *label;
    STRLEN label_len;
    I32 j, len;

    if (!SvOK(label_sv))
        croak("set_item() requires a label");

    label = SvPV(label_sv, label_len);
    items_av = (AV *)SvRV(*items_svp);
    len = av_len(items_av);

    for (j = 0; j <= len; j++) {
        SV **elem = av_fetch(items_av, j, 0);
        HV *item_hv;
        SV **l_svp;
        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
            continue;
        item_hv = (HV *)SvRV(*elem);
        l_svp = hv_fetchs(item_hv, "label", 0);
        if (!l_svp || !SvOK(*l_svp)) continue;
        if (!strEQ(SvPV_nolen(*l_svp), label)) continue;

        /* Found it — apply key => value pairs */
        {
            I32 k;
            for (k = 2; k + 1 < items; k += 2) {
                const char *key = SvPV_nolen(ST(k));
                SV *val = ST(k + 1);
                (void)hv_store(item_hv, key, strlen(key), newSVsv(val), 0);
            }
        }
        break;
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- add_item({ ... }) ----

SV *
add_item(self, item)
    SV *self
    SV *item
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *items_av = (AV *)SvRV(*items_svp);

    if (!SvROK(item) || SvTYPE(SvRV(item)) != SVt_PVHV)
        croak("add_item() requires a hashref");

    av_push(items_av, newSVsv(item));

    /* Register action if present */
    {
        SV **actions_svp = hv_fetchs(hv, "_actions", 0);
        HV *actions = (HV *)SvRV(*actions_svp);
        HV *item_hv = (HV *)SvRV(item);
        SV **act_svp = hv_fetchs(item_hv, "action", 0);
        if (act_svp && SvROK(*act_svp) && SvTYPE(SvRV(*act_svp)) == SVt_PVCV) {
            IV id = _cm_next_id(aTHX_ hv);
            char id_str[32];
            int id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)id);
            (void)hv_stores(item_hv, "_id", newSViv(id));
            (void)hv_store(actions, id_str, id_len, newSVsv(*act_svp), 0);
        }
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- remove_item(label) ----

SV *
remove_item(self, label_sv)
    SV *self
    SV *label_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    AV *items_av = (AV *)SvRV(*items_svp);
    const char *label = SvPV_nolen(label_sv);
    I32 len = av_len(items_av);
    I32 j;

    for (j = 0; j <= len; j++) {
        SV **elem = av_fetch(items_av, j, 0);
        HV *item_hv;
        SV **l_svp;
        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
            continue;
        item_hv = (HV *)SvRV(*elem);
        l_svp = hv_fetchs(item_hv, "label", 0);
        if (!l_svp || !SvOK(*l_svp)) continue;
        if (!strEQ(SvPV_nolen(*l_svp), label)) continue;

        /* Remove action from registry */
        {
            SV **id_svp = hv_fetchs(item_hv, "_id", 0);
            if (id_svp && SvOK(*id_svp)) {
                SV **actions_svp = hv_fetchs(hv, "_actions", 0);
                char id_str[32];
                int id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)SvIV(*id_svp));
                (void)hv_delete((HV *)SvRV(*actions_svp), id_str, id_len, G_DISCARD);
            }
        }

        /* Shift items down */
        {
            I32 k;
            for (k = j; k < len; k++) {
                SV **next = av_fetch(items_av, k + 1, 0);
                if (next) av_store(items_av, k, SvREFCNT_inc(*next));
            }
            av_pop(items_av);
        }
        break;
    }
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- items() — return items arrayref ----

SV *
get_items(self)
    SV *self
ALIAS:
    items = 1
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    PERL_UNUSED_VAR(ix);
    RETVAL = SvREFCNT_inc(*items_svp);
}
OUTPUT:
    RETVAL

 # ---- attachments() — return list of attached selectors ----

void
attachments(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **att_svp = hv_fetchs(hv, "_attachments", 0);
    HV *att_hv = (HV *)SvRV(*att_svp);
    HE *entry;

    hv_iterinit(att_hv);
    while ((entry = hv_iternext(att_hv)) != NULL) {
        I32 klen;
        const char *key = hv_iterkey(entry, &klen);
        XPUSHs(sv_2mortal(newSVpvn(key, klen)));
    }
}

 # ---- enable / disable / is_enabled ----

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

int
is_enabled(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **en_svp = hv_fetchs(hv, "_enabled", 0);
    RETVAL = (en_svp && SvTRUE(*en_svp)) ? 1 : 0;
}
OUTPUT:
    RETVAL

 # ---- js_code() — generate the JS injection code ----

SV *
js_code(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **att_svp = hv_fetchs(hv, "_attachments", 0);
    SV **items_svp = hv_fetchs(hv, "_items", 0);
    SV **global_svp = hv_fetchs(hv, "_global", 0);
    HV *att_hv = (HV *)SvRV(*att_svp);
    AV *items_av = (AV *)SvRV(*items_svp);
    int is_global = (global_svp && SvTRUE(*global_svp));
    SV *js;

    js = newSVpvs(
        "(function(){\n"
        "if(window.__chandraCtxMenu)return;\n"
        "window.__chandraCtxMenu=1;\n"
        "var sels=["
    );

    /* Emit selectors */
    {
        HE *entry;
        int first = 1;
        hv_iterinit(att_hv);
        while ((entry = hv_iternext(att_hv)) != NULL) {
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

    /* Items JSON */
    sv_catpvs(js, "var items=");
    _cm_items_to_js(aTHX_ js, items_av);
    sv_catpvs(js, ";\n");

    /* Global flag */
    sv_catpvf(js, "var isGlobal=%d;\n", is_global);

    /* CSS for menu */
    sv_catpvs(js,
        "var style=document.createElement('style');\n"
        "style.textContent='"
        ".chandra-ctx-menu{"
            "position:fixed;z-index:999999;min-width:160px;"
            "background:#fff;border:1px solid #ccc;border-radius:6px;"
            "box-shadow:0 4px 16px rgba(0,0,0,.18);padding:4px 0;"
            "font:13px/1.4 -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;"
            "color:#222;user-select:none;opacity:0;transform:scale(.96);"
            "transition:opacity .12s,transform .12s;"
        "}"
        ".chandra-ctx-menu.show{opacity:1;transform:scale(1);}"
        ".chandra-ctx-item{"
            "padding:6px 32px 6px 28px;cursor:pointer;white-space:nowrap;"
            "display:flex;align-items:center;position:relative;"
        "}"
        ".chandra-ctx-item:hover{background:#e8f0fe;}"
        ".chandra-ctx-item.disabled{color:#999;pointer-events:none;}"
        ".chandra-ctx-sep{height:1px;background:#e0e0e0;margin:4px 8px;}"
        ".chandra-ctx-icon{width:20px;margin-right:6px;text-align:center;}"
        ".chandra-ctx-sc{margin-left:auto;padding-left:24px;color:#888;font-size:12px;}"
        ".chandra-ctx-check{position:absolute;left:8px;}"
        ".chandra-ctx-sub-arrow{margin-left:auto;padding-left:16px;color:#888;}"
        ".chandra-ctx-sub{position:fixed;}"
        "@media(prefers-color-scheme:dark){"
            ".chandra-ctx-menu{background:#2d2d2d;border-color:#555;color:#e0e0e0;}"
            ".chandra-ctx-item:hover{background:#404040;}"
            ".chandra-ctx-sep{background:#555;}"
            ".chandra-ctx-sc,.chandra-ctx-sub-arrow{color:#888;}"
            ".chandra-ctx-item.disabled{color:#666;}"
        "}"
        "';\n"
        "document.head.appendChild(style);\n"
    );

    /* Menu rendering and event handling JS */
    sv_catpvs(js,
        "var openMenus=[];\n"

        "function closeAll(){"
            "openMenus.forEach(function(m){m.remove()});"
            "openMenus=[];"
        "}\n"

        "function buildMenu(items,x,y,depth){"
            "var m=document.createElement('div');"
            "m.className='chandra-ctx-menu';"

            "items.forEach(function(it){"
                "if(it.sep){"
                    "var s=document.createElement('div');"
                    "s.className='chandra-ctx-sep';"
                    "m.appendChild(s);return;"
                "}"
                "var row=document.createElement('div');"
                "row.className='chandra-ctx-item'+(it.dis?' disabled':'');"

                /* Check mark */
                "if(it.chk){"
                    "var ck=document.createElement('span');"
                    "ck.className='chandra-ctx-check';"
                    "ck.textContent=it.ckd?'\\u2713':'';"
                    "row.appendChild(ck);"
                "}"

                /* Icon */
                "if(it.ico){"
                    "var ic=document.createElement('span');"
                    "ic.className='chandra-ctx-icon';"
                    "ic.textContent=it.ico;"
                    "row.appendChild(ic);"
                "}"

                /* Label */
                "var lb=document.createElement('span');"
                "lb.textContent=it.l||'';"
                "row.appendChild(lb);"

                /* Shortcut hint */
                "if(it.sc){"
                    "var sh=document.createElement('span');"
                    "sh.className='chandra-ctx-sc';"
                    "sh.textContent=it.sc;"
                    "row.appendChild(sh);"
                "}"

                /* Submenu arrow + hover */
                "if(it.sub){"
                    "var ar=document.createElement('span');"
                    "ar.className='chandra-ctx-sub-arrow';"
                    "ar.textContent='\\u25b6';"
                    "row.appendChild(ar);"
                    "var subTimer=null,subMenu=null;"
                    "row.addEventListener('mouseenter',function(){"
                        "clearTimeout(subTimer);"
                        "if(!subMenu){"
                            "subTimer=setTimeout(function(){"
                                "var r=row.getBoundingClientRect();"
                                "subMenu=buildMenu(it.sub,r.right,r.top,(depth||0)+1);"
                                "subMenu.addEventListener('mouseleave',function(ev){"
                                    "if(ev.relatedTarget&&row.contains(ev.relatedTarget))return;"
                                    "subMenu.remove();"
                                    "var idx=openMenus.indexOf(subMenu);"
                                    "if(idx>=0)openMenus.splice(idx,1);"
                                    "subMenu=null;"
                                "});"
                            "},150);"
                        "}"
                    "});"
                    "row.addEventListener('mouseleave',function(ev){"
                        "if(ev.relatedTarget&&subMenu&&subMenu.contains(ev.relatedTarget))return;"
                        "clearTimeout(subTimer);"
                        "if(subMenu){subMenu.remove();"
                        "var idx=openMenus.indexOf(subMenu);"
                        "if(idx>=0)openMenus.splice(idx,1);"
                        "subMenu=null;}"
                    "});"
                "}"

                /* Click handler */
                "if(it.id!=null&&!it.dis){"
                    "row.addEventListener('click',function(e){"
                        "e.stopPropagation();"
                        "var payload=JSON.stringify({type:'action',id:it.id"
                            ",chk:it.chk?!it.ckd:undefined});"
                        "if(it.chk){it.ckd=!it.ckd;"
                            "var cm=row.querySelector('.chandra-ctx-check');"
                            "if(cm)cm.textContent=it.ckd?'\\u2713':'';}"
                        "closeAll();"
                        "window.chandra.invoke('__chandraContextMenuBridge',[payload]);"
                    "});"
                "}"

                "m.appendChild(row);"
            "});\n"

            "m.style.left=x+'px';m.style.top=y+'px';"
            "document.body.appendChild(m);"
            "openMenus.push(m);"

            /* Reposition if off-screen */
            "var br=m.getBoundingClientRect();"
            "if(br.right>window.innerWidth)m.style.left=(x-br.width)+'px';"
            "if(br.bottom>window.innerHeight)m.style.top=(y-br.height)+'px';"

            "requestAnimationFrame(function(){m.classList.add('show');});"
            "return m;"
        "}\n"

        /* Dismiss on click outside or Escape */
        "document.addEventListener('click',function(){closeAll();});\n"
        "document.addEventListener('keydown',function(e){"
            "if(e.key==='Escape')closeAll();"
        "});\n"

        /* Context menu handler */
        "document.addEventListener('contextmenu',function(e){"
            "var t=e.target;"

            /* Check selectors */
            "var matched=false;"
            "for(var i=0;i<sels.length;i++){"
                "if(t.matches(sels[i])||t.closest(sels[i])){"
                    "matched=true;break;"
                "}"
            "}"
            "if(!matched&&!isGlobal)return;\n"

            "e.preventDefault();"
            "closeAll();"

            /* Send dynamic request or show static menu */
            "var tdata={id:t.id||'',class:t.className||'',tag:t.tagName||''"
                ",sel:matched?sels[i]:''};\n"

            /* Check if we need dynamic items */
            "var payload=JSON.stringify({type:'contextmenu'"
                ",x:e.clientX,y:e.clientY,target:tdata});\n"
            "window.chandra.invoke('__chandraContextMenuBridge',[payload]);\n"
        "});\n"

        /* Expose show function for dynamic response */
        "window.__chandraCtxShow=function(x,y,dynItems){"
            "closeAll();"
            "buildMenu(dynItems||items,x,y,0);"
        "};\n"

    "})();\n"
    );

    RETVAL = js;
}
OUTPUT:
    RETVAL

 # ---- _dispatch(json_sv) — handle messages from JS bridge ----

void
_dispatch(self, json_sv)
    SV *self
    SV *json_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **en_svp = hv_fetchs(hv, "_enabled", 0);
    SV *event_sv;
    HV *event_hv;
    SV **type_svp;
    const char *type;

    if (!en_svp || !SvTRUE(*en_svp)) return;

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
            return;
        }
        event_sv = newSVsv(POPs);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    if (!SvROK(event_sv) || SvTYPE(SvRV(event_sv)) != SVt_PVHV) {
        SvREFCNT_dec(event_sv);
        return;
    }

    event_hv = (HV *)SvRV(event_sv);
    type_svp = hv_fetchs(event_hv, "type", 0);
    if (!type_svp || !SvOK(*type_svp)) {
        SvREFCNT_dec(event_sv);
        return;
    }
    type = SvPV_nolen(*type_svp);

    /* Action click */
    if (strEQ(type, "action")) {
        SV **id_svp = hv_fetchs(event_hv, "id", 0);
        SV **chk_svp = hv_fetchs(event_hv, "chk", 0);

        if (id_svp && SvOK(*id_svp)) {
            SV **actions_svp = hv_fetchs(hv, "_actions", 0);
            HV *actions = (HV *)SvRV(*actions_svp);
            char id_str[32];
            int id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)SvIV(*id_svp));
            SV **cb_svp = hv_fetch(actions, id_str, id_len, 0);

            if (cb_svp && SvROK(*cb_svp) && SvTYPE(SvRV(*cb_svp)) == SVt_PVCV) {
                /* Update checked state in items if checkable */
                if (chk_svp && SvOK(*chk_svp)) {
                    /* Find item by _id and update checked */
                    SV **items_svp = hv_fetchs(hv, "_items", 0);
                    AV *items_av = (AV *)SvRV(*items_svp);
                    I32 len = av_len(items_av);
                    I32 j;
                    for (j = 0; j <= len; j++) {
                        SV **elem = av_fetch(items_av, j, 0);
                        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
                            continue;
                        HV *it = (HV *)SvRV(*elem);
                        SV **iid = hv_fetchs(it, "_id", 0);
                        if (iid && SvOK(*iid) && SvIV(*iid) == SvIV(*id_svp)) {
                            (void)hv_stores(it, "checked",
                                newSViv(SvTRUE(*chk_svp) ? 1 : 0));
                            break;
                        }
                    }
                }

                {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    if (chk_svp && SvOK(*chk_svp))
                        XPUSHs(*chk_svp);
                    PUTBACK;
                    call_sv(*cb_svp, G_DISCARD | G_EVAL);
                    if (SvTRUE(ERRSV))
                        warn("ContextMenu action error: %s", SvPV_nolen(ERRSV));
                    FREETMPS; LEAVE;
                }
            }
        }
    }
    /* Context menu request — dynamic items or show static */
    else if (strEQ(type, "contextmenu")) {
        SV **x_svp = hv_fetchs(event_hv, "x", 0);
        SV **y_svp = hv_fetchs(event_hv, "y", 0);
        SV **target_svp = hv_fetchs(event_hv, "target", 0);
        NV x = (x_svp && SvOK(*x_svp)) ? SvNV(*x_svp) : 0;
        NV y = (y_svp && SvOK(*y_svp)) ? SvNV(*y_svp) : 0;

        /* Check for dynamic callback: per-selector or global */
        SV *dynamic_cb = NULL;
        if (target_svp && SvROK(*target_svp)) {
            HV *tgt = (HV *)SvRV(*target_svp);
            SV **sel_svp = hv_fetchs(tgt, "sel", 0);
            if (sel_svp && SvOK(*sel_svp) && SvCUR(*sel_svp) > 0) {
                SV **att_svp2 = hv_fetchs(hv, "_attachments", 0);
                HV *att = (HV *)SvRV(*att_svp2);
                STRLEN slen;
                const char *s = SvPV(*sel_svp, slen);
                SV **dcb = hv_fetch(att, s, slen, 0);
                if (dcb && SvROK(*dcb) && SvTYPE(SvRV(*dcb)) == SVt_PVCV)
                    dynamic_cb = *dcb;
            }
        }
        if (!dynamic_cb) {
            SV **gd_svp = hv_fetchs(hv, "_global_dynamic", 0);
            if (gd_svp && SvROK(*gd_svp) && SvTYPE(SvRV(*gd_svp)) == SVt_PVCV)
                dynamic_cb = *gd_svp;
        }

        if (dynamic_cb) {
            /* Call dynamic callback with target info, get items arrayref back */
            SV *dyn_items;
            AV *dyn_av;
            {
                dSP;
                int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                if (target_svp && SvOK(*target_svp))
                    XPUSHs(*target_svp);
                PUTBACK;
                count = call_sv(dynamic_cb, G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    warn("ContextMenu dynamic callback error: %s", SvPV_nolen(ERRSV));
                    FREETMPS; LEAVE;
                    SvREFCNT_dec(event_sv);
                    return;
                }
                dyn_items = (count > 0) ? newSVsv(POPs) : NULL;
                PUTBACK;
                FREETMPS; LEAVE;
            }

            if (dyn_items && SvROK(dyn_items) && SvTYPE(SvRV(dyn_items)) == SVt_PVAV) {
                dyn_av = (AV *)SvRV(dyn_items);

                /* Register actions for dynamic items */
                {
                    SV **actions_svp = hv_fetchs(hv, "_actions", 0);
                    _cm_register_actions(aTHX_ hv, dyn_av, (HV *)SvRV(*actions_svp));
                }

                /* Build JS items and eval show */
                {
                    SV *show_js = newSVpvs("window.__chandraCtxShow(");
                    sv_catpvf(show_js, "%g,%g,", x, y);
                    _cm_items_to_js(aTHX_ show_js, dyn_av);
                    sv_catpvs(show_js, ");");

                    /* Call app->eval(js) */
                    {
                        SV **app_svp = hv_fetchs(hv, "app", 0);
                        if (app_svp && SvOK(*app_svp)) {
                            dSP;
                            ENTER; SAVETMPS;
                            PUSHMARK(SP);
                            XPUSHs(*app_svp);
                            XPUSHs(show_js);
                            PUTBACK;
                            call_method("eval", G_DISCARD);
                            FREETMPS; LEAVE;
                        }
                    }
                    SvREFCNT_dec(show_js);
                }
                SvREFCNT_dec(dyn_items);
            }
        } else {
            /* Static menu — show via JS */
            SV *show_js = newSVpvf("window.__chandraCtxShow(%g,%g);", x, y);
            SV **app_svp = hv_fetchs(hv, "app", 0);
            if (app_svp && SvOK(*app_svp)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*app_svp);
                XPUSHs(show_js);
                PUTBACK;
                call_method("eval", G_DISCARD);
                FREETMPS; LEAVE;
            }
            SvREFCNT_dec(show_js);
        }
    }

    SvREFCNT_dec(event_sv);
}

 # ---- inject() — bind dispatch + inject JS ----

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

        /* Bind __chandraContextMenuBridge dispatch if not already done */
        {
            SV **db_svp = hv_fetchs(hv, "_dispatch_bound", 0);
            if (!db_svp || !SvTRUE(*db_svp)) {
                SV **app_svp = hv_fetchs(hv, "app", 0);
                if (app_svp && SvOK(*app_svp)) {
                    SV *cm_self_ref = newSVsv(self);
                    CV *wrapper_cv;

                    sv_rvweaken(cm_self_ref);
                    wrapper_cv = newXS(NULL, XS_Chandra__ContextMenu__dispatch_trampoline, __FILE__);
                    CvXSUBANY(wrapper_cv).any_ptr = (void *)cm_self_ref;
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(*app_svp);
                        XPUSHs(sv_2mortal(newSVpvs("__chandraContextMenuBridge")));
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
