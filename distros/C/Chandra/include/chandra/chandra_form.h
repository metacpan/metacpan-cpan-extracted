/*
 * chandra_form.h — Form module static helpers
 * Included from Chandra.xs before INCLUDE: xs/form.xs
 */

#ifndef CHANDRA_FORM_H
#define CHANDRA_FORM_H

/* ========================================================================
 * Field ID counter
 * ======================================================================== */

static int _form_field_id = 0;

/* ========================================================================
 * Form registry — maps form id (string) => Perl SV* form objects
 * Supports multiple forms attached simultaneously; dispatch routes by id.
 * ======================================================================== */

static HV *_form_registry = NULL;
static int _form_events_bound = 0;

static void _form_ensure_registry(pTHX) {
    if (!_form_registry)
        _form_registry = newHV();
}

static void _form_register(pTHX_ const char *id, STRLEN id_len, SV *form) {
    _form_ensure_registry(aTHX);
    (void)hv_store(_form_registry, id, (I32)id_len, SvREFCNT_inc(form), 0);
}

static SV *_form_lookup(pTHX_ const char *id, STRLEN id_len) {
    SV **svp;
    _form_ensure_registry(aTHX);
    svp = hv_fetch(_form_registry, id, (I32)id_len, 0);
    return svp ? *svp : NULL;
}

/* ========================================================================
 * Helper: append HTML-attribute-escaped field ID to SV
 * ======================================================================== */

static void
_form_cat_escaped_id(pTHX_ SV *html, const char *id, STRLEN id_len)
{
    SV *esc = _elem_escape_attr(aTHX_ id, id_len);
    sv_catsv(html, esc);
    SvREFCNT_dec(esc);
}

/* ========================================================================
 * HTML escape helpers (delegate to element helpers)
 * ======================================================================== */

/* Forward-declared: _elem_escape_attr, _elem_escape_html from chandra_element.h */

/* ========================================================================
 * Field rendering helpers
 * ======================================================================== */

/* Append common HTML attributes for a field */
static void
_form_append_attrs(pTHX_ SV *html, HV *opts)
{
    SV **svp;

    svp = hv_fetchs(opts, "required", 0);
    if (svp && SvTRUE(*svp))
        sv_catpvs(html, " required");

    svp = hv_fetchs(opts, "disabled", 0);
    if (svp && SvTRUE(*svp))
        sv_catpvs(html, " disabled");

    svp = hv_fetchs(opts, "readonly", 0);
    if (svp && SvTRUE(*svp))
        sv_catpvs(html, " readonly");

    svp = hv_fetchs(opts, "placeholder", 0);
    if (svp && SvOK(*svp)) {
        STRLEN len;
        const char *val = SvPV(*svp, len);
        SV *esc = _elem_escape_attr(aTHX_ val, len);
        sv_catpvs(html, " placeholder=\"");
        sv_catsv(html, esc);
        sv_catpvs(html, "\"");
        SvREFCNT_dec(esc);
    }

    svp = hv_fetchs(opts, "maxlength", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " maxlength=\"%ld\"", (long)SvIV(*svp));

    svp = hv_fetchs(opts, "minlength", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " minlength=\"%ld\"", (long)SvIV(*svp));

    svp = hv_fetchs(opts, "min", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " min=\"%s\"", SvPV_nolen(*svp));

    svp = hv_fetchs(opts, "max", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " max=\"%s\"", SvPV_nolen(*svp));

    svp = hv_fetchs(opts, "step", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " step=\"%s\"", SvPV_nolen(*svp));

    svp = hv_fetchs(opts, "pattern", 0);
    if (svp && SvOK(*svp)) {
        STRLEN len;
        const char *val = SvPV(*svp, len);
        SV *esc = _elem_escape_attr(aTHX_ val, len);
        sv_catpvs(html, " pattern=\"");
        sv_catsv(html, esc);
        sv_catpvs(html, "\"");
        SvREFCNT_dec(esc);
    }

    svp = hv_fetchs(opts, "class", 0);
    if (svp && SvOK(*svp)) {
        STRLEN len;
        const char *val = SvPV(*svp, len);
        SV *esc = _elem_escape_attr(aTHX_ val, len);
        sv_catpvs(html, " class=\"");
        sv_catsv(html, esc);
        sv_catpvs(html, "\"");
        SvREFCNT_dec(esc);
    }

    svp = hv_fetchs(opts, "autofocus", 0);
    if (svp && SvTRUE(*svp))
        sv_catpvs(html, " autofocus");
}

/* Render a <label> tag */
static void
_form_render_label(pTHX_ SV *html, const char *label, STRLEN label_len,
                   const char *field_id, STRLEN fid_len)
{
    SV *esc;
    sv_catpvs(html, "<label class=\"chandra-label\" for=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "\">");
    esc = _elem_escape_html(aTHX_ label, label_len);
    sv_catsv(html, esc);
    SvREFCNT_dec(esc);
    sv_catpvs(html, "</label>");
}

/* Render a simple <input> field (text, password, email, number, range, hidden) */
static SV *
_form_render_input(pTHX_ const char *type, const char *name, STRLEN name_len,
                   HV *opts, const char *field_id, STRLEN fid_len)
{
    SV *html = newSVpvs("");
    SV **svp;
    int is_hidden = strEQ(type, "hidden");

    if (!is_hidden)
        sv_catpvs(html, "<div class=\"chandra-field\">");

    /* Label */
    if (!is_hidden) {
        svp = hv_fetchs(opts, "label", 0);
        if (svp && SvOK(*svp)) {
            STRLEN llen;
            const char *lbl = SvPV(*svp, llen);
            _form_render_label(aTHX_ html, lbl, llen, field_id, fid_len);
        }
    }

    /* Input element */
    sv_catpvf(html, "<input type=\"%s\" id=\"", type);
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "\" name=\"");
    {
        SV *esc_name = _elem_escape_attr(aTHX_ name, name_len);
        sv_catsv(html, esc_name);
        SvREFCNT_dec(esc_name);
    }
    sv_catpvs(html, "\"");

    /* Value */
    svp = hv_fetchs(opts, "value", 0);
    if (svp && SvOK(*svp)) {
        STRLEN vlen;
        const char *val = SvPV(*svp, vlen);
        SV *esc = _elem_escape_attr(aTHX_ val, vlen);
        sv_catpvs(html, " value=\"");
        sv_catsv(html, esc);
        sv_catpvs(html, "\"");
        SvREFCNT_dec(esc);
    }

    _form_append_attrs(aTHX_ html, opts);
    sv_catpvs(html, ">");

    /* Error placeholder */
    if (!is_hidden) {
        sv_catpvs(html, "<span class=\"chandra-error\" id=\"");
        _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
        sv_catpvs(html, "-error\"></span></div>");
    }

    return html;
}

/* Render a <select> field */
static SV *
_form_render_select(pTHX_ const char *name, STRLEN name_len,
                    HV *opts, const char *field_id, STRLEN fid_len)
{
    SV *html = newSVpvs("<div class=\"chandra-field\">");
    SV **svp;
    SV **sel_val_svp;
    const char *sel_val = NULL;
    STRLEN sel_val_len = 0;

    /* Label */
    svp = hv_fetchs(opts, "label", 0);
    if (svp && SvOK(*svp)) {
        STRLEN llen;
        const char *lbl = SvPV(*svp, llen);
        _form_render_label(aTHX_ html, lbl, llen, field_id, fid_len);
    }

    sv_catpvf(html, "<select id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "\" name=\"");
    {
        SV *esc_name = _elem_escape_attr(aTHX_ name, name_len);
        sv_catsv(html, esc_name);
        SvREFCNT_dec(esc_name);
    }
    sv_catpvs(html, "\"");
    _form_append_attrs(aTHX_ html, opts);
    sv_catpvs(html, ">");

    /* Current value for selected detection */
    sel_val_svp = hv_fetchs(opts, "value", 0);
    if (sel_val_svp && SvOK(*sel_val_svp))
        sel_val = SvPV(*sel_val_svp, sel_val_len);

    /* Options */
    svp = hv_fetchs(opts, "options", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
        AV *options = (AV *)SvRV(*svp);
        I32 i, len = av_len(options);
        for (i = 0; i <= len; i++) {
            SV **oref = av_fetch(options, i, 0);
            if (oref && SvROK(*oref) && SvTYPE(SvRV(*oref)) == SVt_PVHV) {
                HV *opt_hv = (HV *)SvRV(*oref);
                SV **v_svp = hv_fetchs(opt_hv, "value", 0);
                SV **l_svp = hv_fetchs(opt_hv, "label", 0);
                if (v_svp && SvOK(*v_svp)) {
                    STRLEN vlen, llen;
                    const char *v = SvPV(*v_svp, vlen);
                    SV *esc_v = _elem_escape_attr(aTHX_ v, vlen);
                    sv_catpvs(html, "<option value=\"");
                    sv_catsv(html, esc_v);
                    sv_catpvs(html, "\"");
                    SvREFCNT_dec(esc_v);
                    if (sel_val && vlen == sel_val_len &&
                        memEQ(v, sel_val, vlen))
                        sv_catpvs(html, " selected");
                    svp = hv_fetchs(opt_hv, "disabled", 0);
                    if (svp && SvTRUE(*svp))
                        sv_catpvs(html, " disabled");
                    sv_catpvs(html, ">");
                    if (l_svp && SvOK(*l_svp)) {
                        const char *l = SvPV(*l_svp, llen);
                        SV *esc_l = _elem_escape_html(aTHX_ l, llen);
                        sv_catsv(html, esc_l);
                        SvREFCNT_dec(esc_l);
                    }
                    sv_catpvs(html, "</option>");
                }
            }
        }
    }

    sv_catpvf(html, "</select><span class=\"chandra-error\" id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "-error\"></span></div>");
    return html;
}

/* Render a <textarea> field */
static SV *
_form_render_textarea(pTHX_ const char *name, STRLEN name_len,
                      HV *opts, const char *field_id, STRLEN fid_len)
{
    SV *html = newSVpvs("<div class=\"chandra-field\">");
    SV **svp;

    /* Label */
    svp = hv_fetchs(opts, "label", 0);
    if (svp && SvOK(*svp)) {
        STRLEN llen;
        const char *lbl = SvPV(*svp, llen);
        _form_render_label(aTHX_ html, lbl, llen, field_id, fid_len);
    }

    sv_catpvf(html, "<textarea id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "\" name=\"");
    {
        SV *esc_name = _elem_escape_attr(aTHX_ name, name_len);
        sv_catsv(html, esc_name);
        SvREFCNT_dec(esc_name);
    }
    sv_catpvs(html, "\"");

    svp = hv_fetchs(opts, "rows", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " rows=\"%ld\"", (long)SvIV(*svp));

    svp = hv_fetchs(opts, "cols", 0);
    if (svp && SvOK(*svp))
        sv_catpvf(html, " cols=\"%ld\"", (long)SvIV(*svp));

    _form_append_attrs(aTHX_ html, opts);
    sv_catpvs(html, ">");

    /* Content */
    svp = hv_fetchs(opts, "value", 0);
    if (svp && SvOK(*svp)) {
        STRLEN vlen;
        const char *val = SvPV(*svp, vlen);
        SV *esc = _elem_escape_html(aTHX_ val, vlen);
        sv_catsv(html, esc);
        SvREFCNT_dec(esc);
    }

    sv_catpvf(html, "</textarea><span class=\"chandra-error\" id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "-error\"></span></div>");
    return html;
}

/* Render a checkbox field */
static SV *
_form_render_checkbox(pTHX_ const char *name, STRLEN name_len,
                      HV *opts, const char *field_id, STRLEN fid_len)
{
    SV *html = newSVpvs("<div class=\"chandra-field chandra-field-checkbox\">");
    SV **svp;

    sv_catpvf(html, "<input type=\"checkbox\" id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "\" name=\"");
    {
        SV *esc_name = _elem_escape_attr(aTHX_ name, name_len);
        sv_catsv(html, esc_name);
        SvREFCNT_dec(esc_name);
    }
    sv_catpvs(html, "\"");

    svp = hv_fetchs(opts, "value", 0);
    if (svp && SvOK(*svp)) {
        STRLEN vlen;
        const char *val = SvPV(*svp, vlen);
        SV *esc = _elem_escape_attr(aTHX_ val, vlen);
        sv_catpvs(html, " value=\"");
        sv_catsv(html, esc);
        sv_catpvs(html, "\"");
        SvREFCNT_dec(esc);
    } else {
        sv_catpvs(html, " value=\"1\"");
    }

    svp = hv_fetchs(opts, "checked", 0);
    if (svp && SvTRUE(*svp))
        sv_catpvs(html, " checked");

    _form_append_attrs(aTHX_ html, opts);
    sv_catpvs(html, ">");

    /* Label after checkbox */
    svp = hv_fetchs(opts, "label", 0);
    if (svp && SvOK(*svp)) {
        STRLEN llen;
        const char *lbl = SvPV(*svp, llen);
        _form_render_label(aTHX_ html, lbl, llen, field_id, fid_len);
    }

    sv_catpvf(html, "<span class=\"chandra-error\" id=\"");
    _form_cat_escaped_id(aTHX_ html, field_id, fid_len);
    sv_catpvs(html, "-error\"></span></div>");
    return html;
}

/* Render radio button group */
static SV *
_form_render_radio(pTHX_ const char *name, STRLEN name_len,
                   HV *opts, const char *base_id, STRLEN base_id_len)
{
    SV *html = newSVpvs("<div class=\"chandra-field chandra-field-radio\">");
    SV **svp;
    const char *sel_val = NULL;
    STRLEN sel_val_len = 0;

    /* Group label */
    svp = hv_fetchs(opts, "label", 0);
    if (svp && SvOK(*svp)) {
        STRLEN llen;
        const char *lbl = SvPV(*svp, llen);
        SV *esc = _elem_escape_html(aTHX_ lbl, llen);
        sv_catpvs(html, "<span class=\"chandra-label\">");
        sv_catsv(html, esc);
        sv_catpvs(html, "</span>");
        SvREFCNT_dec(esc);
    }

    svp = hv_fetchs(opts, "value", 0);
    if (svp && SvOK(*svp))
        sel_val = SvPV(*svp, sel_val_len);

    svp = hv_fetchs(opts, "options", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
        AV *options = (AV *)SvRV(*svp);
        I32 i, len = av_len(options);
        for (i = 0; i <= len; i++) {
            SV **oref = av_fetch(options, i, 0);
            if (oref && SvROK(*oref) && SvTYPE(SvRV(*oref)) == SVt_PVHV) {
                HV *opt_hv = (HV *)SvRV(*oref);
                SV **v_svp = hv_fetchs(opt_hv, "value", 0);
                SV **l_svp = hv_fetchs(opt_hv, "label", 0);
                if (v_svp && SvOK(*v_svp)) {
                    STRLEN vlen;
                    const char *v = SvPV(*v_svp, vlen);
                    char rid[64];
                    int rid_len;
                    SV *esc_v, *esc_n;

                    rid_len = my_snprintf(rid, sizeof(rid), "%.*s-%d",
                                          (int)base_id_len, base_id, (int)i);

                    sv_catpvs(html, "<div class=\"chandra-radio-option\">");
                    sv_catpvs(html, "<input type=\"radio\" id=\"");
                    _form_cat_escaped_id(aTHX_ html, rid, rid_len);
                    sv_catpvs(html, "\" name=\"");
                    esc_n = _elem_escape_attr(aTHX_ name, name_len);
                    sv_catsv(html, esc_n);
                    SvREFCNT_dec(esc_n);
                    sv_catpvs(html, "\" value=\"");
                    esc_v = _elem_escape_attr(aTHX_ v, vlen);
                    sv_catsv(html, esc_v);
                    SvREFCNT_dec(esc_v);
                    sv_catpvs(html, "\"");

                    if (sel_val && vlen == sel_val_len &&
                        memEQ(v, sel_val, vlen))
                        sv_catpvs(html, " checked");

                    sv_catpvs(html, ">");

                    if (l_svp && SvOK(*l_svp)) {
                        STRLEN llen;
                        const char *lbl = SvPV(*l_svp, llen);
                        _form_render_label(aTHX_ html, lbl, llen, rid, rid_len);
                    }
                    sv_catpvs(html, "</div>");
                }
            }
        }
    }

    sv_catpvf(html, "<span class=\"chandra-error\" id=\"");
    _form_cat_escaped_id(aTHX_ html, base_id, base_id_len);
    sv_catpvs(html, "-error\"></span></div>");
    return html;
}

/* ========================================================================
 * JavaScript for form submit interception and two-way binding
 * ======================================================================== */

static const char _form_js_template[] =
    "(function(){"
    "var f=document.getElementById('%s');"
    "if(!f)return;"
    "function gd(){"
    "var d={},els=f.elements,i,el;"
    "for(i=0;i<els.length;i++){"
    "el=els[i];if(!el.name)continue;"
    "if(el.type==='checkbox')d[el.name]=el.checked?1:0;"
    "else if(el.type==='radio'){if(el.checked)d[el.name]=el.value;}"
    "else d[el.name]=el.value;"
    "}"
    "return d;"
    "}"
    "f.addEventListener('submit',function(e){"
    "e.preventDefault();"
    "window.chandra.invoke('_form_submit',[JSON.stringify({id:'%s',data:gd()})]);"
    "});"
    "f.addEventListener('change',function(e){"
    "var el=e.target;if(!el.name)return;"
    "var v=el.type==='checkbox'?el.checked?1:0:el.value;"
    "window.chandra.invoke('_form_change',[JSON.stringify({id:'%s',field:el.name,value:v})]);"
    "});"
    "f.addEventListener('input',function(e){"
    "var el=e.target;if(!el.name||el.type==='checkbox'||el.type==='radio')return;"
    "window.chandra.invoke('_form_input',[JSON.stringify({id:'%s',field:el.name,value:el.value})]);"
    "});"
    "})();";

/* Set values JS template: expects JSON object */
static const char _form_set_values_js[] =
    "(function(){"
    "var f=document.getElementById('%s');"
    "if(!f)return;"
    "var d=%s,el,i;"
    "for(var k in d){"
    "var els=f.querySelectorAll('[name=\"'+k+'\"]');"
    "for(i=0;i<els.length;i++){"
    "el=els[i];"
    "if(el.type==='checkbox')el.checked=!!d[k];"
    "else if(el.type==='radio')el.checked=(el.value===String(d[k]));"
    "else el.value=d[k];"
    "}"
    "}"
    "})();";

/* Get values JS: collects and sends via bridge */
static const char _form_get_values_js[] =
    "(function(){"
    "var f=document.getElementById('%s');"
    "if(!f)return;"
    "var d={},els=f.elements,i,el;"
    "for(i=0;i<els.length;i++){"
    "el=els[i];if(!el.name)continue;"
    "if(el.type==='checkbox')d[el.name]=el.checked?1:0;"
    "else if(el.type==='radio'){if(el.checked)d[el.name]=el.value;}"
    "else d[el.name]=el.value;"
    "}"
    "window.chandra.invoke('_form_values',[JSON.stringify({id:'%s',data:d})]);"
    "})();";

/* Validation JS: show/clear error messages */
static const char _form_show_errors_js[] =
    "(function(){"
    "var errs=%s;"
    "for(var k in errs){"
    "var el=document.getElementById(k+'-error');"
    "if(el){el.textContent=errs[k];el.style.display='block';}"
    "}"
    "})();";

static const char _form_clear_errors_js[] =
    "(function(){"
    "var els=document.querySelectorAll('#%s .chandra-error');"
    "for(var i=0;i<els.length;i++){els[i].textContent='';els[i].style.display='none';}"
    "})();";

#endif /* CHANDRA_FORM_H */
