/*
 * chandra_internal.h — C helper functions for internal Chandra operations
 *
 * This header eliminates Perl method dispatch overhead for internal operations.
 * We only use Perl's call_* API for:
 *   - User callbacks (call_sv on user-provided coderefs)
 *   - Cpanel::JSON::XS encode/decode (external module)
 *   - IO operations (sysread, syswrite on handles)
 *   - File::Spec operations (external module)
 *
 * All internal Chandra::* class operations use direct C functions.
 */

#ifndef CHANDRA_INTERNAL_H
#define CHANDRA_INTERNAL_H

/* ============================================================================
 * Bridge JS Code — static constant (replaces Chandra::Bridge->js_code)
 * ============================================================================ */

static const char CHANDRA_BRIDGE_JS[] =
    "(function() {\n"
    "    if (window.chandra) return;\n"
    "\n"
    "    window.chandra = {\n"
    "        _callbacks: {},\n"
    "        _id: 0,\n"
    "\n"
    "        invoke: function(method, args) {\n"
    "            var self = this;\n"
    "            return new Promise(function(resolve, reject) {\n"
    "                var id = ++self._id;\n"
    "                self._callbacks[id] = { resolve: resolve, reject: reject };\n"
    "                window.external.invoke(JSON.stringify({\n"
    "                    type: 'call',\n"
    "                    id: id,\n"
    "                    method: method,\n"
    "                    args: args || []\n"
    "                }));\n"
    "            });\n"
    "        },\n"
    "\n"
    "        call: function(method) {\n"
    "            var args = Array.prototype.slice.call(arguments, 1);\n"
    "            return this.invoke(method, args);\n"
    "        },\n"
    "\n"
    "        _resolve: function(id, result, error) {\n"
    "            var cb = this._callbacks[id];\n"
    "            if (!cb) return;\n"
    "            delete this._callbacks[id];\n"
    "            if (error) {\n"
    "                cb.reject(new Error(error));\n"
    "            } else {\n"
    "                cb.resolve(result);\n"
    "            }\n"
    "        },\n"
    "\n"
    "        _event: function(handlerId, eventData) {\n"
    "            window.external.invoke(JSON.stringify({\n"
    "                type: 'event',\n"
    "                handler: handlerId,\n"
    "                event: eventData || {}\n"
    "            }));\n"
    "        },\n"
    "\n"
    "        _eventData: function(e, extra) {\n"
    "            var data = {\n"
    "                type: e.type,\n"
    "                targetId: e.target ? e.target.id : null,\n"
    "                targetName: e.target ? e.target.name : null,\n"
    "                value: e.target ? e.target.value : null,\n"
    "                checked: e.target ? e.target.checked : null,\n"
    "                key: e.key || null,\n"
    "                keyCode: e.keyCode || null\n"
    "            };\n"
    "            if (extra) {\n"
    "                for (var k in extra) {\n"
    "                    data[k] = extra[k];\n"
    "                }\n"
    "            }\n"
    "            return data;\n"
    "        }\n"
    "    };\n"
    "})();\n";

/* ============================================================================
 * Router JS Code — static constant (replaces Chandra::App->_router_js)
 * ============================================================================ */

static const char CHANDRA_ROUTER_JS[] =
    "(function() {\n"
    "    if (window.__chandraRouter) return;\n"
    "    window.__chandraRouter = {\n"
    "        navigate: function(path) {\n"
    "            if (window.chandra) {\n"
    "                window.chandra.invoke('__chandra_navigate', [path]);\n"
    "            }\n"
    "        }\n"
    "    };\n"
    "})();\n";

/* ============================================================================
 * Bind Initialization (replaces Chandra::_xs_init_bind)
 * ============================================================================
 *
 * Note: Uses perl_callback, my_perl_interp, and external_invoke_cb from chandra.h
 */

/* Forward declaration */
static void chandra_bind_register(pTHX_ const char *name, STRLEN nlen, SV *callback);

/* Initialize bind system for a PerlChandra */
static void
chandra_init_bind(pTHX_ SV *self_sv)
{
    SV *bind = get_sv("Chandra::_xs_bind", 0);
    int need_new = 1;

    if (bind && SvOK(bind) && SvROK(bind)) {
        HV *bind_hv = (HV *)SvRV(bind);
        SV **app_svp = hv_fetchs(bind_hv, "app", 0);
        if (app_svp && SvOK(*app_svp)
            && SvRV(*app_svp) == SvRV(self_sv)) {
            /* Same app object — reuse existing bind */
            (void)hv_stores(bind_hv, "app", newSVsv(self_sv));
            need_new = 0;
        }
    }

    if (need_new) {
        /* Create Chandra::Bind hash directly in C */
        HV *bind_hv = newHV();
        (void)hv_stores(bind_hv, "app", newSVsv(self_sv));
        SV *new_bind = sv_bless(newRV_noinc((SV *)bind_hv),
                                gv_stashpvs("Chandra::Bind", GV_ADD));
        sv_setsv(get_sv("Chandra::_xs_bind", GV_ADD), new_bind);
        SvREFCNT_dec(new_bind);
    }

    /* Set callback directly on PerlChandra struct */
    {
        PerlChandra *pc = INT2PTR(PerlChandra *, SvIV(SvRV(self_sv)));
        CV *dispatch_cv = get_cv("Chandra::_xs_dispatch", 0);
        SV *callback = newRV_inc((SV *)dispatch_cv);

        if (pc->callback) {
            SvREFCNT_dec(pc->callback);
            perl_callback = NULL;
        }
        perl_callback = SvREFCNT_inc(callback);
        pc->callback = perl_callback;
        pc->wv.external_invoke_cb = external_invoke_cb;
        my_perl_interp = PERL_GET_THX;
        SvREFCNT_dec(callback);
    }
}

/* Register a binding for an app */
static void
chandra_app_bind(pTHX_ SV *app_sv, const char *name, STRLEN nlen, SV *callback)
{
    SV *bind = get_sv("Chandra::_xs_bind", 0);

    /* Ensure bind exists */
    if (!bind || !SvOK(bind)) {
        chandra_init_bind(aTHX_ app_sv);
    }

    /* Register directly in the bind registry */
    chandra_bind_register(aTHX_ name, nlen, callback);
}

/* ============================================================================
 * Bind Registry Operations (replaces Chandra::Bind method calls)
 * ============================================================================
 *
 * Uses _bind_registry from chandra_bind.h
 */

/* Register a handler in the bind registry (direct C call) */
static void
chandra_bind_register(pTHX_ const char *name, STRLEN nlen, SV *callback)
{
    HV *reg = _bind_get_registry(aTHX);
    (void)hv_store(reg, name, (I32)nlen,
        SvREFCNT_inc(SvROK(callback) ? SvRV(callback) : callback), 0);
}

/* Lookup a handler in the bind registry */
static SV *
chandra_bind_lookup(pTHX_ const char *name, STRLEN nlen)
{
    HV *reg = _bind_get_registry(aTHX);
    SV **svp = hv_fetch(reg, name, (I32)nlen, 0);
    return (svp && *svp) ? *svp : NULL;
}

/* Build JS resolve string (replaces Chandra::Bind->js_resolve) */
static SV *
chandra_bind_js_resolve(pTHX_ int id, SV *result, SV *error)
{
    if (SvOK(error)) {
        SV *encoded = _bind_json_encode(aTHX_ error);
        SV *js = newSVpvf("window.chandra._resolve(%d, null, %s)",
                          id, SvPV_nolen(encoded));
        SvREFCNT_dec(encoded);
        return js;
    } else {
        SV *encoded = _bind_json_encode(aTHX_ result);
        SV *js = newSVpvf("window.chandra._resolve(%d, %s, null)",
                          id, SvPV_nolen(encoded));
        SvREFCNT_dec(encoded);
        return js;
    }
}

/* ============================================================================
 * Event Object Creation (replaces Chandra::Event->new)
 * ============================================================================ */

static SV *
chandra_event_new(pTHX_ SV *data)
{
    HV *event_hv = newHV();
    SV *event_sv;

    if (data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
        HV *data_hv = (HV *)SvRV(data);
        HE *entry;

        hv_iterinit(data_hv);
        while ((entry = hv_iternext(data_hv)) != NULL) {
            STRLEN klen;
            const char *key = HePV(entry, klen);
            SV *val = HeVAL(entry);
            (void)hv_store(event_hv, key, (I32)klen, newSVsv(val), 0);
        }
    }

    event_sv = newRV_noinc((SV *)event_hv);
    sv_bless(event_sv, gv_stashpvs("Chandra::Event", GV_ADD));
    return event_sv;
}

/* ============================================================================
 * JS String Escaping
 * ============================================================================
 * Note: chandra_escape_js(pTHX_ SV *str_sv) is already defined in chandra.h
 * Use that function for escaping JS strings.
 */

/* ============================================================================
 * Webview Operations (direct calls, replaces method dispatch)
 * ============================================================================ */

/* Wrapper for webview_eval via PerlChandra */
static int
chandra_eval_js(pTHX_ PerlChandra *pc, const char *js)
{
    if (!pc || !pc->initialized) return -1;
    return webview_eval(&pc->wv, js);
}

/* Wrapper for webview_dispatch via PerlChandra */
static void
chandra_dispatch_eval_js(pTHX_ PerlChandra *pc, const char *js)
{
    if (!pc || !pc->initialized) return;
    webview_dispatch(&pc->wv, deferred_eval_cb, strdup(js));
}

/* Wrapper for webview_dialog via PerlChandra */
static SV *
chandra_dialog(pTHX_ PerlChandra *pc, int dlgtype, int flags,
               const char *title, const char *arg)
{
    char result[4096];
    if (!pc || !pc->initialized) return &PL_sv_undef;

    memset(result, 0, sizeof(result));
    webview_dialog(&pc->wv, dlgtype, flags, title, arg, result, sizeof(result));

    if (strlen(result) > 0) {
        return newSVpv(result, 0);
    }
    return &PL_sv_undef;
}

/* ============================================================================
 * App Internal State Operations
 * ============================================================================ */

/* Get PerlChandra from app's _webview (if available) */
static PerlChandra *
chandra_app_get_pc(pTHX_ SV *app_sv)
{
    return CHANDRA_PC_FROM_APP(app_sv);
}

/* Eval JS directly from an app object */
static int
chandra_app_eval(pTHX_ SV *app_sv, const char *js)
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(app_sv);
    return chandra_eval_js(aTHX_ pc, js);
}

/* Dispatch eval JS directly from an app object */
static void
chandra_app_dispatch_eval(pTHX_ SV *app_sv, const char *js)
{
    PerlChandra *pc = CHANDRA_PC_FROM_APP(app_sv);
    chandra_dispatch_eval_js(aTHX_ pc, js);
}

/* ============================================================================
 * DevTools Internal Operations
 * ============================================================================ */

/* Check if devtools is enabled (direct hash access) */
static int
chandra_devtools_is_enabled(pTHX_ SV *dt_sv)
{
    HV *hv;
    SV **svp;

    if (!SvROK(dt_sv) || SvTYPE(SvRV(dt_sv)) != SVt_PVHV)
        return 0;

    hv = (HV *)SvRV(dt_sv);
    svp = hv_fetchs(hv, "enabled", 0);
    return (svp && *svp && SvTRUE(*svp)) ? 1 : 0;
}

/* Get devtools JS code constant */
static const char *
chandra_devtools_js_code(void)
{
    return Chandra__DevTools__js_code_str;
}

/* ============================================================================
 * Tray Internal Operations (replaces _sync, _menu_json)
 * ============================================================================ */

/* Forward declaration for tray menu JSON builder */
static SV *chandra_tray_build_menu_json(pTHX_ SV *tray_sv);

/* Build menu JSON from tray _items array */
static SV *
chandra_tray_build_menu_json(pTHX_ SV *tray_sv)
{
    HV *hv;
    SV **items_svp;
    AV *items;
    SSize_t len, i;
    SV *result;

    if (!SvROK(tray_sv) || SvTYPE(SvRV(tray_sv)) != SVt_PVHV)
        return newSVpvs("[]");

    hv = (HV *)SvRV(tray_sv);
    items_svp = hv_fetchs(hv, "_items", 0);

    if (!items_svp || !*items_svp || !SvROK(*items_svp) ||
        SvTYPE(SvRV(*items_svp)) != SVt_PVAV)
        return newSVpvs("[]");

    items = (AV *)SvRV(*items_svp);
    len = av_len(items) + 1;

    if (len == 0) return newSVpvs("[]");

    result = newSVpvs("[");
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(items, i, 0);
        if (elem && *elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
            HV *item_hv = (HV *)SvRV(*elem);
            SV **id_svp = hv_fetchs(item_hv, "id", 0);
            SV **label_svp = hv_fetchs(item_hv, "label", 0);
            SV **sep_svp = hv_fetchs(item_hv, "separator", 0);

            if (i > 0) sv_catpvs(result, ",");

            if (sep_svp && *sep_svp && SvTRUE(*sep_svp)) {
                sv_catpvs(result, "{\"separator\":true}");
            } else {
                IV id = (id_svp && *id_svp) ? SvIV(*id_svp) : 0;
                const char *label = (label_svp && *label_svp)
                    ? SvPV_nolen(*label_svp) : "";
                sv_catpvf(result, "{\"id\":%ld,\"label\":\"%s\"}", (long)id, label);
            }
        }
    }
    sv_catpvs(result, "]");

    return result;
}

/* ============================================================================
 * HotReload Internal Operations
 * ============================================================================ */

/* Scan files in a directory - returns AV of {path, mtime} */
static AV *
chandra_hotreload_scan_files(pTHX_ const char *dir_path)
{
    AV *result = newAV();
    /* Note: This would need platform-specific directory scanning.
     * For now, this is a stub that should be filled in. */
    return result;
}

/* ============================================================================
 * Socket Operations (C implementations)
 * ============================================================================ */

/* Generate a random token (replaces _xs_generate_token) */
static SV *
chandra_socket_generate_token(pTHX_ int length)
{
    static const char charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    SV *token;
    char *buf;
    int i;

    token = newSV(length + 1);
    buf = SvPVX(token);

    for (i = 0; i < length; i++) {
        buf[i] = charset[rand() % (sizeof(charset) - 1)];
    }
    buf[length] = '\0';

    SvCUR_set(token, length);
    SvPOK_on(token);
    return token;
}

#endif /* CHANDRA_INTERNAL_H */
