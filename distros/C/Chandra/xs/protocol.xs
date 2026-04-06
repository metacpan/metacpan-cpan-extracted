MODULE = Chandra    PACKAGE = Chandra::Protocol

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;

    /* Parse %args from stack */
    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        }
    }

    (void)hv_stores(self_hv, "protocols", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_injected", newSViv(0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
register(self, scheme_sv, handler)
    SV *self
    SV *scheme_sv
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **protocols_svp;
    HV *protocols_hv;
    char *scheme;
    STRLEN scheme_len;
    char clean_scheme[256];
    STRLEN clean_len;

    /* Validate scheme */
    if (!SvOK(scheme_sv)) {
        croak("register() requires a scheme name");
    }

    /* Validate handler */
    if (!SvOK(handler) || !SvROK(handler) || SvTYPE(SvRV(handler)) != SVt_PVCV) {
        croak("register() requires a handler coderef");
    }

    /* Get and clean scheme: strip :// and : suffixes */
    scheme = SvPV(scheme_sv, scheme_len);
    clean_len = scheme_len;
    if (clean_len > 3 && scheme[clean_len - 3] == ':' && scheme[clean_len - 2] == '/' && scheme[clean_len - 1] == '/') {
        clean_len -= 3;
    } else if (clean_len > 1 && scheme[clean_len - 1] == ':') {
        clean_len -= 1;
    }
    if (clean_len >= sizeof(clean_scheme)) {
        clean_len = sizeof(clean_scheme) - 1;
    }
    Copy(scheme, clean_scheme, clean_len, char);
    clean_scheme[clean_len] = '\0';

    /* Store handler in protocols hash */
    protocols_svp = hv_fetchs(hv, "protocols", 0);
    if (protocols_svp && SvROK(*protocols_svp)) {
        protocols_hv = (HV *)SvRV(*protocols_svp);
        (void)hv_store(protocols_hv, clean_scheme, clean_len, newSVsv(handler), 0);
    }

    /* Create XS callback with CvXSUBANY for handler + JSON encoder */
    {
        SV **app_svp = hv_fetchs(hv, "app", 0);
        if (app_svp && SvOK(*app_svp)) {
            ProtocolBindCtx *ctx;
            CV *wrapper_cv;
            SV *json_enc;
            SV *bind_name = sv_2mortal(newSVpvf("__protocol_%s", clean_scheme));

            json_enc = get_sv("Chandra::Protocol::_xs_json", 0);

            Newxz(ctx, 1, ProtocolBindCtx);
            ctx->handler = SvREFCNT_inc(handler);
            ctx->json_encoder = SvREFCNT_inc(json_enc);

            wrapper_cv = newXS(NULL, xs_protocol_bound_callback, __FILE__);
            CvXSUBANY(wrapper_cv).any_ptr = (void *)ctx;

            {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*app_svp);
                XPUSHs(bind_name);
                XPUSHs(sv_2mortal(newRV_noinc((SV *)wrapper_cv)));
                PUTBACK;
                call_method("bind", G_DISCARD);
                FREETMPS; LEAVE;
            }
        }
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

void
schemes(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **protocols_svp;

    protocols_svp = hv_fetchs(hv, "protocols", 0);
    if (protocols_svp && SvROK(*protocols_svp)) {
        HV *protocols_hv = (HV *)SvRV(*protocols_svp);
        I32 num_keys = hv_iterinit(protocols_hv);

        if (GIMME_V == G_SCALAR) {
            mXPUSHi(num_keys);
            XSRETURN(1);
        } else {
            HE *entry;
            while ((entry = hv_iternext(protocols_hv)) != NULL) {
                XPUSHs(sv_2mortal(newSVhek(HeKEY_hek(entry))));
            }
        }
    } else {
        if (GIMME_V == G_SCALAR) {
            mXPUSHi(0);
            XSRETURN(1);
        }
    }
}

SV *
is_registered(self, scheme_sv)
    SV *self
    SV *scheme_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **protocols_svp;
    char *scheme;
    STRLEN scheme_len;
    char clean_scheme[256];
    STRLEN clean_len;

    scheme = SvPV(scheme_sv, scheme_len);
    clean_len = scheme_len;
    if (clean_len > 3 && scheme[clean_len - 3] == ':' && scheme[clean_len - 2] == '/' && scheme[clean_len - 1] == '/') {
        clean_len -= 3;
    } else if (clean_len > 1 && scheme[clean_len - 1] == ':') {
        clean_len -= 1;
    }
    if (clean_len >= sizeof(clean_scheme)) {
        clean_len = sizeof(clean_scheme) - 1;
    }
    Copy(scheme, clean_scheme, clean_len, char);
    clean_scheme[clean_len] = '\0';

    protocols_svp = hv_fetchs(hv, "protocols", 0);
    if (protocols_svp && SvROK(*protocols_svp)) {
        HV *protocols_hv = (HV *)SvRV(*protocols_svp);
        RETVAL = hv_exists(protocols_hv, clean_scheme, clean_len) ? &PL_sv_yes : &PL_sv_no;
    } else {
        RETVAL = &PL_sv_no;
    }
}
OUTPUT:
    RETVAL

SV *
inject(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **injected_svp;
    SV **protocols_svp;

    /* Check _injected flag */
    injected_svp = hv_fetchs(hv, "_injected", 0);
    if (injected_svp && SvTRUE(*injected_svp)) {
        RETVAL = SvREFCNT_inc(self);
    } else {
        /* Check protocols not empty */
        protocols_svp = hv_fetchs(hv, "protocols", 0);
        if (!protocols_svp || !SvROK(*protocols_svp) || HvUSEDKEYS((HV *)SvRV(*protocols_svp)) == 0) {
            /* No protocols registered - return without setting flag */
            RETVAL = SvREFCNT_inc(self);
        } else {
            HV *protocols_hv = (HV *)SvRV(*protocols_svp);
            SV *js_sv;
            HE *entry;
            int first = 1;

            /* Set _injected flag */
            (void)hv_stores(hv, "_injected", newSViv(1));

            /* Build JS string */
            js_sv = newSVpvs("(function() {\n"
                "    if (window.__chandraProtocol) return;\n"
                "    var schemes = [");

            /* Append scheme list */
            hv_iterinit(protocols_hv);
            while ((entry = hv_iternext(protocols_hv)) != NULL) {
                I32 klen;
                const char *key = hv_iterkey(entry, &klen);
                if (!first) sv_catpvs(js_sv, ",");
                sv_catpvs(js_sv, "'");
                sv_catpvn(js_sv, key, klen);
                sv_catpvs(js_sv, "'");
                first = 0;
            }

            sv_catpvs(js_sv, "];\n"
                "    function matchScheme(url) {\n"
                "        for (var i = 0; i < schemes.length; i++) {\n"
                "            var prefix = schemes[i] + '://';\n"
                "            if (url.indexOf(prefix) === 0) return { scheme: schemes[i], rest: url.substring(prefix.length) };\n"
                "        }\n"
                "        return null;\n"
                "    }\n"
                "    function parsePath(rest) {\n"
                "        var qIdx = rest.indexOf('?');\n"
                "        var path = qIdx >= 0 ? rest.substring(0, qIdx) : rest;\n"
                "        var params = {};\n"
                "        if (qIdx >= 0) {\n"
                "            rest.substring(qIdx + 1).split('&').forEach(function(pair) {\n"
                "                var kv = pair.split('=');\n"
                "                if (kv[0]) params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1] || '');\n"
                "            });\n"
                "        }\n"
                "        return { path: path, params: params };\n"
                "    }\n"
                "    function invokeHandler(url) {\n"
                "        var m = matchScheme(url);\n"
                "        if (!m) return Promise.reject(new Error('Unknown protocol: ' + url));\n"
                "        var p = parsePath(m.rest);\n"
                "        return window.chandra.invoke('__protocol_' + m.scheme, [p.path, JSON.stringify(p.params)]);\n"
                "    }\n"
                "    function mimeFromPath(path) {\n"
                "        var ext = path.split('.').pop().toLowerCase();\n"
                "        var map = {css:'text/css',js:'application/javascript',json:'application/json',\n"
                "            html:'text/html',htm:'text/html',xml:'application/xml',svg:'image/svg+xml',\n"
                "            png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',gif:'image/gif',\n"
                "            webp:'image/webp',ico:'image/x-icon',woff:'font/woff',woff2:'font/woff2',\n"
                "            ttf:'font/ttf',otf:'font/otf',txt:'text/plain'};\n"
                "        return map[ext] || 'application/octet-stream';\n"
                "    }\n"
                "    window.__chandraProtocol = {\n"
                "        schemes: schemes,\n"
                "        navigate: invokeHandler\n"
                "    };\n"
                "\n"
                "    /* Override fetch() for custom schemes */\n"
                "    var _origFetch = window.fetch;\n"
                "    window.fetch = function(input, init) {\n"
                "        var url = (typeof input === 'string') ? input : (input && input.url) || '';\n"
                "        if (matchScheme(url)) {\n"
                "            return invokeHandler(url).then(function(content) {\n"
                "                var m = matchScheme(url);\n"
                "                var p = parsePath(m.rest);\n"
                "                var mime = mimeFromPath(p.path);\n"
                "                return new Response(content || '', {\n"
                "                    status: content ? 200 : 404,\n"
                "                    headers: {'Content-Type': mime}\n"
                "                });\n"
                "            });\n"
                "        }\n"
                "        return _origFetch.apply(this, arguments);\n"
                "    };\n"
                "\n"
                "    /* Process elements with custom scheme URLs */\n"
                "    /* Supports data-href/data-src (no native fetch error) or real href/src */\n"
                "    function processElement(el) {\n"
                "        var tag = el.tagName;\n"
                "        if (tag === 'LINK' && el.rel === 'stylesheet') {\n"
                "            var href = el.getAttribute('data-href') || el.href;\n"
                "            if (!href || !matchScheme(href)) return;\n"
                "            el.removeAttribute('href'); el.removeAttribute('data-href');\n"
                "            invokeHandler(href).then(function(css) {\n"
                "                if (!css) return;\n"
                "                var style = document.createElement('style');\n"
                "                style.textContent = css;\n"
                "                if (el.parentNode) el.parentNode.replaceChild(style, el);\n"
                "            });\n"
                "        } else if (tag === 'SCRIPT') {\n"
                "            var src = el.getAttribute('data-src') || el.src;\n"
                "            if (!src || !matchScheme(src)) return;\n"
                "            el.removeAttribute('src'); el.removeAttribute('data-src');\n"
                "            invokeHandler(src).then(function(js) {\n"
                "                if (!js) return;\n"
                "                var script = document.createElement('script');\n"
                "                script.textContent = js;\n"
                "                if (el.parentNode) el.parentNode.replaceChild(script, el);\n"
                "            });\n"
                "        } else if (tag === 'IMG') {\n"
                "            var imgSrc = el.getAttribute('data-src') || el.src;\n"
                "            if (!imgSrc || !matchScheme(imgSrc)) return;\n"
                "            el.removeAttribute('src'); el.removeAttribute('data-src');\n"
                "            invokeHandler(imgSrc).then(function(data) {\n"
                "                if (!data) return;\n"
                "                var m = matchScheme(imgSrc);\n"
                "                var p = parsePath(m.rest);\n"
                "                var mime = mimeFromPath(p.path);\n"
                "                el.src = 'data:' + mime + ';base64,' + btoa(data);\n"
                "            });\n"
                "        }\n"
                "    }\n"
                "    var _sel = 'link[rel=stylesheet][data-href],link[rel=stylesheet][href],' +\n"
                "              'script[data-src],script[src],img[data-src],img[src]';\n"
                "\n"
                "    /* Scan existing elements */\n"
                "    document.querySelectorAll(_sel).forEach(processElement);\n"
                "\n"
                "    /* Watch for future elements */\n"
                "    new MutationObserver(function(mutations) {\n"
                "        mutations.forEach(function(mut) {\n"
                "            mut.addedNodes.forEach(function(node) {\n"
                "                if (node.nodeType !== 1) return;\n"
                "                processElement(node);\n"
                "                node.querySelectorAll && node.querySelectorAll(_sel).forEach(processElement);\n"
                "            });\n"
                "        });\n"
                "    }).observe(document.documentElement, { childList: true, subtree: true });\n"
                "\n"
                "    /* Intercept <a> clicks */\n"
                "    document.addEventListener('click', function(e) {\n"
                "        var target = e.target;\n"
                "        while (target && target.tagName !== 'A') target = target.parentElement;\n"
                "        if (!target || !target.href) return;\n"
                "        if (matchScheme(target.href)) {\n"
                "            e.preventDefault();\n"
                "            invokeHandler(target.href);\n"
                "        }\n"
                "    }, true);\n"
                "})();\n");

            /* Call $self->{app}->eval($js) */
            {
                SV **app_svp = hv_fetchs(hv, "app", 0);
                if (app_svp && SvOK(*app_svp)) {
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*app_svp);
                    XPUSHs(sv_2mortal(js_sv));
                    PUTBACK;
                    call_method("eval", G_DISCARD);
                    FREETMPS;
                    LEAVE;
                } else {
                    SvREFCNT_dec(js_sv);
                }
            }

            RETVAL = SvREFCNT_inc(self);
        }
    }
}
OUTPUT:
    RETVAL

SV *
js_code(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **protocols_svp;

    protocols_svp = hv_fetchs(hv, "protocols", 0);
    if (!protocols_svp || !SvROK(*protocols_svp) || HvUSEDKEYS((HV *)SvRV(*protocols_svp)) == 0) {
        RETVAL = newSVpvs("");
    } else {
        HV *protocols_hv = (HV *)SvRV(*protocols_svp);
        HE *entry;
        int first = 1;

        RETVAL = newSVpvs("(function() {\n"
            "    if (window.__chandraProtocol) return;\n"
            "    var schemes = [");

        /* Append scheme list */
        hv_iterinit(protocols_hv);
        while ((entry = hv_iternext(protocols_hv)) != NULL) {
            I32 klen;
            const char *key = hv_iterkey(entry, &klen);
            if (!first) sv_catpvs(RETVAL, ",");
            sv_catpvs(RETVAL, "'");
            sv_catpvn(RETVAL, key, klen);
            sv_catpvs(RETVAL, "'");
            first = 0;
        }

        sv_catpvs(RETVAL, "];\n"
            "    function matchScheme(url) {\n"
            "        for (var i = 0; i < schemes.length; i++) {\n"
            "            var prefix = schemes[i] + '://';\n"
            "            if (url.indexOf(prefix) === 0) return { scheme: schemes[i], rest: url.substring(prefix.length) };\n"
            "        }\n"
            "        return null;\n"
            "    }\n"
            "    function parsePath(rest) {\n"
            "        var qIdx = rest.indexOf('?');\n"
            "        var path = qIdx >= 0 ? rest.substring(0, qIdx) : rest;\n"
            "        var params = {};\n"
            "        if (qIdx >= 0) {\n"
            "            rest.substring(qIdx + 1).split('&').forEach(function(pair) {\n"
            "                var kv = pair.split('=');\n"
            "                if (kv[0]) params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1] || '');\n"
            "            });\n"
            "        }\n"
            "        return { path: path, params: params };\n"
            "    }\n"
            "    function invokeHandler(url) {\n"
            "        var m = matchScheme(url);\n"
            "        if (!m) return Promise.reject(new Error('Unknown protocol: ' + url));\n"
            "        var p = parsePath(m.rest);\n"
            "        return window.chandra.invoke('__protocol_' + m.scheme, [p.path, JSON.stringify(p.params)]);\n"
            "    }\n"
            "    function mimeFromPath(path) {\n"
            "        var ext = path.split('.').pop().toLowerCase();\n"
            "        var map = {css:'text/css',js:'application/javascript',json:'application/json',\n"
            "            html:'text/html',htm:'text/html',xml:'application/xml',svg:'image/svg+xml',\n"
            "            png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',gif:'image/gif',\n"
            "            webp:'image/webp',ico:'image/x-icon',woff:'font/woff',woff2:'font/woff2',\n"
            "            ttf:'font/ttf',otf:'font/otf',txt:'text/plain'};\n"
            "        return map[ext] || 'application/octet-stream';\n"
            "    }\n"
            "    window.__chandraProtocol = {\n"
            "        schemes: schemes,\n"
            "        navigate: invokeHandler\n"
            "    };\n"
            "\n"
            "    /* Override fetch() for custom schemes */\n"
            "    var _origFetch = window.fetch;\n"
            "    window.fetch = function(input, init) {\n"
            "        var url = (typeof input === 'string') ? input : (input && input.url) || '';\n"
            "        if (matchScheme(url)) {\n"
            "            return invokeHandler(url).then(function(content) {\n"
            "                var m = matchScheme(url);\n"
            "                var p = parsePath(m.rest);\n"
            "                var mime = mimeFromPath(p.path);\n"
            "                return new Response(content || '', {\n"
            "                    status: content ? 200 : 404,\n"
            "                    headers: {'Content-Type': mime}\n"
            "                });\n"
            "            });\n"
            "        }\n"
            "        return _origFetch.apply(this, arguments);\n"
            "    };\n"
            "\n"
            "    /* Process elements with custom scheme URLs */\n"
            "    /* Supports data-href/data-src (no native fetch error) or real href/src */\n"
            "    function processElement(el) {\n"
            "        var tag = el.tagName;\n"
            "        if (tag === 'LINK' && el.rel === 'stylesheet') {\n"
            "            var href = el.getAttribute('data-href') || el.href;\n"
            "            if (!href || !matchScheme(href)) return;\n"
            "            el.removeAttribute('href'); el.removeAttribute('data-href');\n"
            "            invokeHandler(href).then(function(css) {\n"
            "                if (!css) return;\n"
            "                var style = document.createElement('style');\n"
            "                style.textContent = css;\n"
            "                if (el.parentNode) el.parentNode.replaceChild(style, el);\n"
            "            });\n"
            "        } else if (tag === 'SCRIPT') {\n"
            "            var src = el.getAttribute('data-src') || el.src;\n"
            "            if (!src || !matchScheme(src)) return;\n"
            "            el.removeAttribute('src'); el.removeAttribute('data-src');\n"
            "            invokeHandler(src).then(function(js) {\n"
            "                if (!js) return;\n"
            "                var script = document.createElement('script');\n"
            "                script.textContent = js;\n"
            "                if (el.parentNode) el.parentNode.replaceChild(script, el);\n"
            "            });\n"
            "        } else if (tag === 'IMG') {\n"
            "            var imgSrc = el.getAttribute('data-src') || el.src;\n"
            "            if (!imgSrc || !matchScheme(imgSrc)) return;\n"
            "            el.removeAttribute('src'); el.removeAttribute('data-src');\n"
            "            invokeHandler(imgSrc).then(function(data) {\n"
            "                if (!data) return;\n"
            "                var m = matchScheme(imgSrc);\n"
            "                var p = parsePath(m.rest);\n"
            "                var mime = mimeFromPath(p.path);\n"
            "                el.src = 'data:' + mime + ';base64,' + btoa(data);\n"
            "            });\n"
            "        }\n"
            "    }\n"
            "    var _sel = 'link[rel=stylesheet][data-href],link[rel=stylesheet][href],' +\n"
            "              'script[data-src],script[src],img[data-src],img[src]';\n"
            "\n"
            "    /* Scan existing elements */\n"
            "    document.querySelectorAll(_sel).forEach(processElement);\n"
            "\n"
            "    /* Watch for future elements */\n"
            "    new MutationObserver(function(mutations) {\n"
            "        mutations.forEach(function(mut) {\n"
            "            mut.addedNodes.forEach(function(node) {\n"
            "                if (node.nodeType !== 1) return;\n"
            "                processElement(node);\n"
            "                node.querySelectorAll && node.querySelectorAll(_sel).forEach(processElement);\n"
            "            });\n"
            "        });\n"
            "    }).observe(document.documentElement, { childList: true, subtree: true });\n"
            "\n"
            "    /* Intercept <a> clicks */\n"
            "    document.addEventListener('click', function(e) {\n"
            "        var target = e.target;\n"
            "        while (target && target.tagName !== 'A') target = target.parentElement;\n"
            "        if (!target || !target.href) return;\n"
            "        if (matchScheme(target.href)) {\n"
            "            e.preventDefault();\n"
            "            invokeHandler(target.href);\n"
            "        }\n"
            "    }, true);\n"
            "})();\n");
    }
}
OUTPUT:
    RETVAL
