MODULE = Chandra    PACKAGE = Chandra::Form

PROTOTYPES: DISABLE

 # ---- new(class, key => value, ...) ----

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    AV *fields_av = newAV();
    I32 i;
    char id_buf[64];
    int id_len;

    id_len = my_snprintf(id_buf, sizeof(id_buf), "chandra-form-%d",
                         ++_form_field_id);

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "id")) {
            (void)hv_stores(self_hv, "id", newSVsv(val));
        } else if (strEQ(key, "action")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV)
                (void)hv_stores(self_hv, "_action", newSVsv(val));
            else
                croak("Chandra::Form->new: 'action' must be a coderef");
        } else if (strEQ(key, "method")) {
            (void)hv_stores(self_hv, "method", newSVsv(val));
        } else if (strEQ(key, "class")) {
            (void)hv_stores(self_hv, "class", newSVsv(val));
        } else if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        }
    }

    /* Default id if not supplied */
    {
        SV **id_svp = hv_fetchs(self_hv, "id", 0);
        if (!id_svp || !SvOK(*id_svp))
            (void)hv_stores(self_hv, "id", newSVpvn(id_buf, id_len));
    }

    (void)hv_stores(self_hv, "_fields", newRV_noinc((SV *)fields_av));
    (void)hv_stores(self_hv, "_submit_label", newSVpvs("Submit"));
    (void)hv_stores(self_hv, "_on_change", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_on_change_global", &PL_sv_undef);
    (void)hv_stores(self_hv, "_groups", newRV_noinc((SV *)newAV()));
    (void)hv_stores(self_hv, "_current_group", &PL_sv_undef);
    (void)hv_stores(self_hv, "_bound", newSViv(0));
    (void)hv_stores(self_hv, "_validators", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_get_values_cb", &PL_sv_undef);
    (void)hv_stores(self_hv, "_validate_cb", &PL_sv_undef);

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- text(name, { opts }) ----

SV *
text(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("text"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));

    av_push(fields, newRV_noinc((SV *)field_hv));

    /* Track current group */
    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- password(name, { opts }) ----

SV *
password(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("password"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- email(name, { opts }) ----

SV *
email(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("email"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- textarea(name, { opts }) ----

SV *
textarea(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("textarea"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- select(name, { opts }) ----

SV *
_select(self, name, ...)
    SV *self
    SV *name
ALIAS:
    select = 1
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);
    PERL_UNUSED_VAR(ix);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("select"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- checkbox(name, { opts }) ----

SV *
checkbox(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("checkbox"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- radio(name, { opts }) ----

SV *
radio(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("radio"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- number(name, { opts }) ----

SV *
number(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("number"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- range(name, { opts }) ----

SV *
range(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("range"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    {
        SV **grp = hv_fetchs(hv, "_current_group", 0);
        if (grp && SvOK(*grp))
            (void)hv_stores(field_hv, "group", newSVsv(*grp));
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- hidden(name, { opts }) ----

SV *
hidden(self, name, ...)
    SV *self
    SV *name
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    HV *field_hv = newHV();
    HV *opts_hv = NULL;
    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);

    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
        opts_hv = (HV *)SvRV(ST(2));

    (void)hv_stores(field_hv, "type", newSVpvs("hidden"));
    (void)hv_stores(field_hv, "name", newSVpvn(name_str, name_len));
    if (opts_hv)
        (void)hv_stores(field_hv, "opts", newRV_inc((SV *)opts_hv));
    else
        (void)hv_stores(field_hv, "opts", newRV_noinc((SV *)newHV()));
    av_push(fields, newRV_noinc((SV *)field_hv));

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- submit(label) ----

SV *
submit(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    if (items > 1 && SvOK(ST(1)))
        (void)hv_stores(hv, "_submit_label", newSVsv(ST(1)));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- group(label, coderef) ----

SV *
group(self, label, code)
    SV *self
    SV *label
    SV *code
CODE:
{
    HV *hv = (HV *)SvRV(self);

    if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        croak("Chandra::Form->group: second argument must be a coderef");

    /* Set current group */
    (void)hv_stores(hv, "_current_group", newSVsv(label));

    /* Push group label onto _groups list */
    {
        SV **groups_svp = hv_fetchs(hv, "_groups", 0);
        AV *groups = (AV *)SvRV(*groups_svp);
        av_push(groups, newSVsv(label));
    }

    /* Call the coderef */
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD);
        FREETMPS;
        LEAVE;
    }

    /* Clear current group */
    (void)hv_stores(hv, "_current_group", &PL_sv_undef);

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- render() ----

SV *
render(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    SV **submit_svp = hv_fetchs(hv, "_submit_label", 0);
    SV **cls_svp = hv_fetchs(hv, "class", 0);
    AV *fields;
    I32 i, len;
    SV *html;
    const char *form_id;
    STRLEN form_id_len;
    char *cur_group = NULL;
    int in_fieldset = 0;

    form_id = SvPV(*id_svp, form_id_len);
    fields = (AV *)SvRV(*fields_svp);
    len = av_len(fields);

    html = newSVpvs("<form class=\"chandra-form");
    if (cls_svp && SvOK(*cls_svp)) {
        sv_catpvs(html, " ");
        sv_catsv(html, *cls_svp);
    }
    sv_catpvs(html, "\" id=\"");
    {
        SV *esc_id = _elem_escape_attr(aTHX_ form_id, form_id_len);
        sv_catsv(html, esc_id);
        SvREFCNT_dec(esc_id);
    }
    sv_catpvs(html, "\">");

    for (i = 0; i <= len; i++) {
        SV **fref = av_fetch(fields, i, 0);
        HV *fhv;
        SV **type_svp, **name_svp, **opts_svp, **grp_svp;
        const char *type, *name;
        STRLEN type_len, name_len;
        HV *opts;
        char fid[128];
        int fid_len;
        SV *field_html = NULL;

        if (!fref || !SvROK(*fref)) continue;
        fhv = (HV *)SvRV(*fref);

        type_svp = hv_fetchs(fhv, "type", 0);
        name_svp = hv_fetchs(fhv, "name", 0);
        opts_svp = hv_fetchs(fhv, "opts", 0);
        if (!type_svp || !name_svp) continue;

        type = SvPV(*type_svp, type_len);
        name = SvPV(*name_svp, name_len);
        opts = (opts_svp && SvROK(*opts_svp)) ? (HV *)SvRV(*opts_svp) : newHV();

        /* Generate field id */
        fid_len = my_snprintf(fid, sizeof(fid), "%.*s-%.*s",
                              (int)form_id_len, form_id,
                              (int)name_len, name);

        /* Handle group transitions */
        grp_svp = hv_fetchs(fhv, "group", 0);
        if (grp_svp && SvOK(*grp_svp)) {
            const char *grp = SvPV_nolen(*grp_svp);
            if (!cur_group || !strEQ(cur_group, grp)) {
                if (in_fieldset)
                    sv_catpvs(html, "</fieldset>");
                sv_catpvs(html, "<fieldset class=\"chandra-group\"><legend>");
                {
                    STRLEN glen;
                    const char *g = SvPV(*grp_svp, glen);
                    SV *esc = _elem_escape_html(aTHX_ g, glen);
                    sv_catsv(html, esc);
                    SvREFCNT_dec(esc);
                }
                sv_catpvs(html, "</legend>");
                cur_group = SvPV_nolen(*grp_svp);
                in_fieldset = 1;
            }
        } else {
            if (in_fieldset) {
                sv_catpvs(html, "</fieldset>");
                in_fieldset = 0;
                cur_group = NULL;
            }
        }

        /* Render field by type */
        if (strEQ(type, "text") || strEQ(type, "password") ||
            strEQ(type, "email") || strEQ(type, "number") ||
            strEQ(type, "range") || strEQ(type, "hidden")) {
            field_html = _form_render_input(aTHX_ type, name, name_len,
                                            opts, fid, fid_len);
        } else if (strEQ(type, "select")) {
            field_html = _form_render_select(aTHX_ name, name_len,
                                             opts, fid, fid_len);
        } else if (strEQ(type, "textarea")) {
            field_html = _form_render_textarea(aTHX_ name, name_len,
                                               opts, fid, fid_len);
        } else if (strEQ(type, "checkbox")) {
            field_html = _form_render_checkbox(aTHX_ name, name_len,
                                               opts, fid, fid_len);
        } else if (strEQ(type, "radio")) {
            field_html = _form_render_radio(aTHX_ name, name_len,
                                            opts, fid, fid_len);
        }

        if (field_html) {
            sv_catsv(html, field_html);
            SvREFCNT_dec(field_html);
        }
    }

    if (in_fieldset)
        sv_catpvs(html, "</fieldset>");

    /* Submit button */
    if (submit_svp && SvOK(*submit_svp)) {
        STRLEN slen;
        const char *slbl = SvPV(*submit_svp, slen);
        SV *esc = _elem_escape_html(aTHX_ slbl, slen);
        sv_catpvs(html, "<div class=\"chandra-field chandra-field-submit\">"
                        "<button type=\"submit\" class=\"chandra-submit\">");
        sv_catsv(html, esc);
        sv_catpvs(html, "</button></div>");
        SvREFCNT_dec(esc);
    }

    sv_catpvs(html, "</form>");

    RETVAL = html;
}
OUTPUT:
    RETVAL

 # ---- bind_js() — returns the JavaScript needed for two-way binding ----

SV *
bind_js(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    const char *form_id;
    STRLEN form_id_len;
    char *js;
    int js_len;

    form_id = SvPV(*id_svp, form_id_len);

    /* 4 substitutions of form_id into template */
    Newx(js, sizeof(_form_js_template) + form_id_len * 4 + 1, char);
    js_len = my_snprintf(js, sizeof(_form_js_template) + form_id_len * 4,
                         _form_js_template, form_id, form_id, form_id, form_id);
    RETVAL = newSVpvn(js, js_len);
    Safefree(js);
}
OUTPUT:
    RETVAL

 # ---- set_values_js(hashref) — returns JS to set field values ----

SV *
set_values_js(self, data)
    SV *self
    SV *data
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    const char *form_id;
    STRLEN form_id_len;
    SV *json_sv;
    const char *json;
    STRLEN json_len;
    char *js;
    int js_len;

    if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
        croak("set_values_js() requires a hashref");

    form_id = SvPV(*id_svp, form_id_len);

    /* Convert data to JSON via Cpanel::JSON::XS */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(data);
        PUTBACK;
        count = call_pv("Cpanel::JSON::XS::encode_json", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count == 1)
            json_sv = newSVsv(POPs);
        else
            json_sv = newSVpvs("{}");
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    json = SvPV(json_sv, json_len);
    Newx(js, sizeof(_form_set_values_js) + form_id_len + json_len + 1, char);
    js_len = my_snprintf(js, sizeof(_form_set_values_js) + form_id_len + json_len,
                         _form_set_values_js, form_id, json);
    RETVAL = newSVpvn(js, js_len);
    Safefree(js);
    SvREFCNT_dec(json_sv);
}
OUTPUT:
    RETVAL

 # ---- get_values_js() — returns JS that sends current form values via bridge ----

SV *
get_values_js(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    const char *form_id;
    STRLEN form_id_len;
    char *js;
    int js_len;

    form_id = SvPV(*id_svp, form_id_len);
    Newx(js, sizeof(_form_get_values_js) + form_id_len * 2 + 1, char);
    js_len = my_snprintf(js, sizeof(_form_get_values_js) + form_id_len * 2,
                         _form_get_values_js, form_id, form_id);
    RETVAL = newSVpvn(js, js_len);
    Safefree(js);
}
OUTPUT:
    RETVAL

 # ---- show_errors_js(hashref) ----

SV *
show_errors_js(self, errors)
    SV *self
    SV *errors
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV *json_sv;
    const char *json;
    STRLEN json_len;
    char *js;
    int js_len;

    if (!SvROK(errors) || SvTYPE(SvRV(errors)) != SVt_PVHV)
        croak("show_errors_js() requires a hashref");

    /* Build JSON mapping field_id => error message */
    {
        HV *err_hv = (HV *)SvRV(errors);
        SV **id_svp = hv_fetchs(hv, "id", 0);
        const char *form_id = SvPV_nolen(*id_svp);
        HV *mapped = newHV();
        HE *entry;
        char key_buf[256];

        hv_iterinit(err_hv);
        while ((entry = hv_iternext(err_hv))) {
            I32 klen;
            const char *k = hv_iterkey(entry, &klen);
            SV *v = hv_iterval(err_hv, entry);
            int kb_len = my_snprintf(key_buf, sizeof(key_buf), "%s-%.*s",
                                     form_id, (int)klen, k);
            (void)hv_store(mapped, key_buf, kb_len, newSVsv(v), 0);
        }

        /* Encode to JSON */
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)mapped)));
            PUTBACK;
            count = call_pv("Cpanel::JSON::XS::encode_json", G_SCALAR | G_EVAL);
            SPAGAIN;
            json_sv = (!SvTRUE(ERRSV) && count == 1) ? newSVsv(POPs) : newSVpvs("{}");
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
    }

    json = SvPV(json_sv, json_len);
    Newx(js, sizeof(_form_show_errors_js) + json_len + 1, char);
    js_len = my_snprintf(js, sizeof(_form_show_errors_js) + json_len,
                         _form_show_errors_js, json);
    RETVAL = newSVpvn(js, js_len);
    Safefree(js);
    SvREFCNT_dec(json_sv);
}
OUTPUT:
    RETVAL

 # ---- clear_errors_js() ----

SV *
clear_errors_js(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    const char *form_id;
    STRLEN form_id_len;
    char *js;
    int js_len;

    form_id = SvPV(*id_svp, form_id_len);
    Newx(js, sizeof(_form_clear_errors_js) + form_id_len + 1, char);
    js_len = my_snprintf(js, sizeof(_form_clear_errors_js) + form_id_len,
                         _form_clear_errors_js, form_id);
    RETVAL = newSVpvn(js, js_len);
    Safefree(js);
}
OUTPUT:
    RETVAL

 # ---- on_change(field_or_cb, [cb]) — register change handlers ----

SV *
on_change(self, field_or_cb, ...)
    SV *self
    SV *field_or_cb
CODE:
{
    HV *hv = (HV *)SvRV(self);

    if (SvROK(field_or_cb) && SvTYPE(SvRV(field_or_cb)) == SVt_PVCV) {
        /* Global on_change handler */
        (void)hv_stores(hv, "_on_change_global", newSVsv(field_or_cb));
    } else if (SvOK(field_or_cb) && items > 2 &&
               SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) {
        /* Field-specific change handler */
        SV **oc_svp = hv_fetchs(hv, "_on_change", 0);
        HV *oc_hv = (HV *)SvRV(*oc_svp);
        STRLEN flen;
        const char *fname = SvPV(field_or_cb, flen);
        (void)hv_store(oc_hv, fname, flen, newSVsv(ST(2)), 0);
    } else {
        croak("on_change() requires a coderef or (field_name, coderef)");
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- field_count() ----

IV
field_count(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    RETVAL = av_len((AV *)SvRV(*fields_svp)) + 1;
}
OUTPUT:
    RETVAL

 # ---- id() ----

SV *
id(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    RETVAL = newSVsv(*id_svp);
}
OUTPUT:
    RETVAL

 # ---- fields() — returns arrayref of field names ----

SV *
fields(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **fields_svp = hv_fetchs(hv, "_fields", 0);
    AV *fields = (AV *)SvRV(*fields_svp);
    AV *names = newAV();
    I32 i, len = av_len(fields);

    for (i = 0; i <= len; i++) {
        SV **fref = av_fetch(fields, i, 0);
        if (fref && SvROK(*fref)) {
            HV *fhv = (HV *)SvRV(*fref);
            SV **n = hv_fetchs(fhv, "name", 0);
            if (n && SvOK(*n))
                av_push(names, newSVsv(*n));
        }
    }

    RETVAL = newRV_noinc((SV *)names);
}
OUTPUT:
    RETVAL

 # ---- action(coderef) — get/set action handler ----

SV *
action(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);

    if (items > 1) {
        if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV)
            croak("action() requires a coderef");
        (void)hv_stores(hv, "_action", newSVsv(ST(1)));
        RETVAL = SvREFCNT_inc(self);
    } else {
        SV **act = hv_fetchs(hv, "_action", 0);
        RETVAL = (act && SvOK(*act)) ? newSVsv(*act) : &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

 # ---- dispatch(event_type, json_string) — internal: called from bridge ----

void
dispatch(self, event_type, json_str)
    SV *self
    SV *event_type
    SV *json_str
CODE:
{
    HV *hv = (HV *)SvRV(self);
    const char *evt = SvPV_nolen(event_type);
    SV *decoded;

    /* Decode JSON */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(json_str);
        PUTBACK;
        count = call_pv("Cpanel::JSON::XS::decode_json", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV) || count < 1) {
            PUTBACK;
            FREETMPS;
            LEAVE;
            return;
        }
        decoded = (count == 1) ? SvREFCNT_inc(POPs) : NULL;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    if (!decoded || !SvROK(decoded) || SvTYPE(SvRV(decoded)) != SVt_PVHV) {
        if (decoded) SvREFCNT_dec(decoded);
        return;
    }

    if (strEQ(evt, "_form_submit")) {
        SV **act = hv_fetchs(hv, "_action", 0);
        if (act && SvROK(*act) && SvTYPE(SvRV(*act)) == SVt_PVCV) {
            HV *dhv = (HV *)SvRV(decoded);
            SV **data_svp = hv_fetchs(dhv, "data", 0);
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(data_svp ? *data_svp : &PL_sv_undef);
            PUTBACK;
            call_sv(*act, G_DISCARD);
            FREETMPS;
            LEAVE;
        }
    } else if (strEQ(evt, "_form_change") || strEQ(evt, "_form_input")) {
        HV *dhv = (HV *)SvRV(decoded);
        SV **field_svp = hv_fetchs(dhv, "field", 0);
        SV **value_svp = hv_fetchs(dhv, "value", 0);

        if (field_svp && SvOK(*field_svp)) {
            STRLEN flen;
            const char *fname = SvPV(*field_svp, flen);

            /* Field-specific handler */
            {
                SV **oc_svp = hv_fetchs(hv, "_on_change", 0);
                if (oc_svp && SvROK(*oc_svp)) {
                    HV *oc_hv = (HV *)SvRV(*oc_svp);
                    SV **cb = hv_fetch(oc_hv, fname, flen, 0);
                    if (cb && SvROK(*cb) && SvTYPE(SvRV(*cb)) == SVt_PVCV) {
                        dSP;
                        ENTER;
                        SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(value_svp ? *value_svp : &PL_sv_undef);
                        PUTBACK;
                        call_sv(*cb, G_DISCARD);
                        FREETMPS;
                        LEAVE;
                    }
                }
            }

            /* Global on_change handler */
            {
                SV **gcb = hv_fetchs(hv, "_on_change_global", 0);
                if (gcb && SvROK(*gcb) && SvTYPE(SvRV(*gcb)) == SVt_PVCV) {
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*field_svp);
                    XPUSHs(value_svp ? *value_svp : &PL_sv_undef);
                    PUTBACK;
                    call_sv(*gcb, G_DISCARD);
                    FREETMPS;
                    LEAVE;
                }
            }
        }
    } else if (strEQ(evt, "_form_values")) {
        SV **cb = hv_fetchs(hv, "_get_values_cb", 0);
        if (cb && SvROK(*cb) && SvTYPE(SvRV(*cb)) == SVt_PVCV) {
            HV *dhv = (HV *)SvRV(decoded);
            SV **data_svp = hv_fetchs(dhv, "data", 0);
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(data_svp ? *data_svp : &PL_sv_undef);
            PUTBACK;
            call_sv(*cb, G_DISCARD);
            FREETMPS;
            LEAVE;
            (void)hv_stores(hv, "_get_values_cb", &PL_sv_undef);
        }
    }

    SvREFCNT_dec(decoded);
}

 # ---- _route_event(event_type, json_str) — class method: routes to correct form ----

void
_route_event(class, event_type, json_str)
    const char *class
    SV *event_type
    SV *json_str
CODE:
{
    SV *decoded;
    PERL_UNUSED_VAR(class);

    /* Decode JSON to extract the form id */
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(json_str);
        PUTBACK;
        count = call_pv("Cpanel::JSON::XS::decode_json", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV) || count < 1) {
            PUTBACK;
            FREETMPS;
            LEAVE;
            return;
        }
        decoded = (count == 1) ? SvREFCNT_inc(POPs) : NULL;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    if (!decoded || !SvROK(decoded) || SvTYPE(SvRV(decoded)) != SVt_PVHV) {
        if (decoded) SvREFCNT_dec(decoded);
        return;
    }

    /* Extract id from the decoded hash */
    {
        HV *dhv = (HV *)SvRV(decoded);
        SV **id_svp = hv_fetchs(dhv, "id", 0);
        if (id_svp && SvOK(*id_svp)) {
            STRLEN id_len;
            const char *id = SvPV(*id_svp, id_len);
            SV *form = _form_lookup(aTHX_ id, id_len);
            if (form) {
                /* Call $form->dispatch($event_type, $json_str) */
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(form);
                XPUSHs(event_type);
                XPUSHs(json_str);
                PUTBACK;
                call_method("dispatch", G_DISCARD);
                FREETMPS;
                LEAVE;
            }
        }
    }

    SvREFCNT_dec(decoded);
}

 # ---- attach(app) — register form and bind events on the app ----

SV *
attach(self, app)
    SV *self
    SV *app
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);
    STRLEN id_len;
    const char *id;

    if (!id_svp || !SvOK(*id_svp))
        croak("attach(): form has no id");
    id = SvPV(*id_svp, id_len);

    /* Register this form in the global registry */
    _form_register(aTHX_ id, id_len, self);

    /* Bind the four form events on the app (once globally) */
    if (!_form_events_bound) {
        static const char *events[] = {
            "_form_submit", "_form_change", "_form_input", "_form_values"
        };
        int i;
        for (i = 0; i < 4; i++) {
            dSP;
            SV *evt_name = sv_2mortal(newSVpv(events[i], 0));
            SV *evt_copy = newSVpv(events[i], 0);

            /* Build a closure: sub { Chandra::Form->_route_event('evt', $_[0]); 1 } */
            SV *cb;
            {
                SV *code_str = sv_2mortal(newSVpvf(
                    "sub { Chandra::Form->_route_event('%s', $_[0]); 1 }",
                    events[i]));
                cb = eval_pv(SvPV_nolen(code_str), TRUE);
                SvREFCNT_inc(cb);
            }

            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(app);
            XPUSHs(evt_name);
            XPUSHs(sv_2mortal(newRV_noinc(cb)));
            PUTBACK;
            call_method("bind", G_DISCARD);
            FREETMPS;
            LEAVE;

            SvREFCNT_dec(evt_copy);
        }
        _form_events_bound = 1;
    }

    /* Inject the bind_js for this form */
    {
        dSP;
        SV *js;
        int count;

        /* Get bind_js */
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        count = call_method("bind_js", G_SCALAR);
        SPAGAIN;
        js = (count > 0) ? POPs : &PL_sv_undef;

        if (SvOK(js)) {
            /* Call $app->dispatch_eval($js) */
            PUSHMARK(SP);
            XPUSHs(app);
            XPUSHs(js);
            PUTBACK;
            call_method("dispatch_eval", G_DISCARD);
        }
        SPAGAIN;
        FREETMPS;
        LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- detach() — remove form from the global registry ----

SV *
detach(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **id_svp = hv_fetchs(hv, "id", 0);

    if (id_svp && SvOK(*id_svp)) {
        STRLEN id_len;
        const char *id = SvPV(*id_svp, id_len);
        _form_ensure_registry(aTHX);
        (void)hv_delete(_form_registry, id, (I32)id_len, G_DISCARD);
    }

    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- validate(\%data) — validate form data, returns hashref or undef ----

SV *
validate(self, data_rv)
    SV *self
    SV *data_rv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    HV *data;
    HV *errors;
    SV **fields_svp;
    AV *fields;
    SSize_t i, flen;
    int has_errors = 0;

    if (!SvROK(data_rv) || SvTYPE(SvRV(data_rv)) != SVt_PVHV)
        croak("validate() requires a hashref");
    data = (HV *)SvRV(data_rv);

    fields_svp = hv_fetchs(hv, "_fields", 0);
    if (!fields_svp || !SvROK(*fields_svp))
        XSRETURN_UNDEF;
    fields = (AV *)SvRV(*fields_svp);

    errors = newHV();
    flen = av_len(fields) + 1;

    for (i = 0; i < flen; i++) {
        SV **fsvp = av_fetch(fields, i, 0);
        HV *field_hv, *opts_hv;
        SV **type_svp, **name_svp, **opts_svp, **val_svp;
        const char *fname, *ftype;
        STRLEN fname_len;
        const char *value = "";
        STRLEN value_len = 0;

        if (!fsvp || !SvROK(*fsvp)) continue;
        field_hv = (HV *)SvRV(*fsvp);

        type_svp = hv_fetchs(field_hv, "type", 0);
        name_svp = hv_fetchs(field_hv, "name", 0);
        opts_svp = hv_fetchs(field_hv, "opts", 0);
        if (!name_svp || !SvOK(*name_svp)) continue;
        fname = SvPV(*name_svp, fname_len);

        ftype = (type_svp && SvOK(*type_svp)) ? SvPV_nolen(*type_svp) : "text";
        if (strEQ(ftype, "hidden") || strEQ(ftype, "submit") || strEQ(ftype, "group"))
            continue;

        opts_hv = (opts_svp && SvROK(*opts_svp) && SvTYPE(SvRV(*opts_svp)) == SVt_PVHV)
            ? (HV *)SvRV(*opts_svp) : NULL;
        if (!opts_hv) continue;

        /* Get value from data */
        val_svp = hv_fetch(data, fname, (I32)fname_len, 0);
        if (val_svp && SvOK(*val_svp))
            value = SvPV(*val_svp, value_len);

        /* Required */
        {
            SV **req = hv_fetchs(opts_hv, "required", 0);
            if (req && SvTRUE(*req) && value_len == 0) {
                SV **msg = hv_fetchs(opts_hv, "required_msg", 0);
                SV **label = hv_fetchs(opts_hv, "label", 0);
                SV *err;
                if (msg && SvOK(*msg)) {
                    err = newSVsv(*msg);
                } else if (label && SvOK(*label)) {
                    err = newSVpvf("%s is required", SvPV_nolen(*label));
                } else {
                    err = newSVpvf("%s is required", fname);
                }
                hv_store(errors, fname, (I32)fname_len, err, 0);
                has_errors = 1;
                continue;
            }
        }

        if (value_len == 0) continue; /* Not required and empty */

        /* Minlength */
        {
            SV **ml = hv_fetchs(opts_hv, "minlength", 0);
            if (ml && SvOK(*ml)) {
                IV min = SvIV(*ml);
                if ((IV)value_len < min) {
                    SV **msg = hv_fetchs(opts_hv, "minlength_msg", 0);
                    SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                        : newSVpvf("Must be at least %" IVdf " characters", min);
                    hv_store(errors, fname, (I32)fname_len, err, 0);
                    has_errors = 1;
                    continue;
                }
            }
        }

        /* Maxlength */
        {
            SV **ml = hv_fetchs(opts_hv, "maxlength", 0);
            if (ml && SvOK(*ml)) {
                IV max = SvIV(*ml);
                if ((IV)value_len > max) {
                    SV **msg = hv_fetchs(opts_hv, "maxlength_msg", 0);
                    SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                        : newSVpvf("Must be at most %" IVdf " characters", max);
                    hv_store(errors, fname, (I32)fname_len, err, 0);
                    has_errors = 1;
                    continue;
                }
            }
        }

        /* Pattern — compile regex and match */
        {
            SV **pat = hv_fetchs(opts_hv, "pattern", 0);
            if (pat && SvOK(*pat)) {
                SV *val_sv = sv_2mortal(newSVpvn(value, value_len));
                SV *re_sv;
                int matched;

                /* If pattern is already a qr//, use it; else compile as string */
                if (SvROK(*pat) && SvTYPE(SvRV(*pat)) == SVt_REGEXP) {
                    re_sv = *pat;
                } else {
                    /* Compile string pattern to regex via eval */
                    SV *code = sv_2mortal(newSVpvf("qr/%s/", SvPV_nolen(*pat)));
                    re_sv = eval_pv(SvPV_nolen(code), 0);
                    if (SvTRUE(ERRSV)) {
                        sv_setsv(ERRSV, &PL_sv_undef);
                        re_sv = NULL;
                    }
                }

                matched = 0;
                if (re_sv) {
                    REGEXP *rx = SvRX(re_sv);
                    if (rx) {
                        matched = pregexec(rx, SvPV_nolen(val_sv),
                                          SvPV_nolen(val_sv) + value_len,
                                          SvPV_nolen(val_sv), 0, val_sv, 1);
                    }
                }

                if (!matched) {
                    SV **msg = hv_fetchs(opts_hv, "pattern_msg", 0);
                    SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                        : newSVpvs("Invalid format");
                    hv_store(errors, fname, (I32)fname_len, err, 0);
                    has_errors = 1;
                    continue;
                }
            }
        }

        /* Min (numeric) */
        {
            SV **mn = hv_fetchs(opts_hv, "min", 0);
            if (mn && SvOK(*mn)) {
                NV min_val = SvNV(*mn);
                NV val_num = SvNV(newSVpvn(value, value_len));
                if (val_num < min_val) {
                    SV **msg = hv_fetchs(opts_hv, "min_msg", 0);
                    SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                        : newSVpvf("Must be at least %g", (double)min_val);
                    hv_store(errors, fname, (I32)fname_len, err, 0);
                    has_errors = 1;
                    continue;
                }
            }
        }

        /* Max (numeric) */
        {
            SV **mx = hv_fetchs(opts_hv, "max", 0);
            if (mx && SvOK(*mx)) {
                NV max_val = SvNV(*mx);
                NV val_num = SvNV(newSVpvn(value, value_len));
                if (val_num > max_val) {
                    SV **msg = hv_fetchs(opts_hv, "max_msg", 0);
                    SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                        : newSVpvf("Must be at most %g", (double)max_val);
                    hv_store(errors, fname, (I32)fname_len, err, 0);
                    has_errors = 1;
                    continue;
                }
            }
        }

        /* Email */
        if (strEQ(ftype, "email")) {
            /* Basic check: has @ and . after @ */
            const char *at = memchr(value, '@', value_len);
            if (!at || at == value || !memchr(at + 1, '.', value_len - (at - value) - 1)) {
                SV **msg = hv_fetchs(opts_hv, "email_msg", 0);
                SV *err = (msg && SvOK(*msg)) ? newSVsv(*msg)
                    : newSVpvs("Invalid email address");
                hv_store(errors, fname, (I32)fname_len, err, 0);
                has_errors = 1;
                continue;
            }
        }

        /* Custom validator callback */
        {
            SV **vcb = hv_fetchs(opts_hv, "validate", 0);
            if (vcb && SvOK(*vcb) && SvROK(*vcb) && SvTYPE(SvRV(*vcb)) == SVt_PVCV) {
                int count;
                SV *result;
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpvn(value, value_len)));
                XPUSHs(data_rv);
                PUTBACK;
                count = call_sv(*vcb, G_SCALAR | G_EVAL);
                SPAGAIN;
                result = (count > 0) ? POPs : &PL_sv_undef;
                if (SvOK(result) && SvTRUE(result)) {
                    hv_store(errors, fname, (I32)fname_len, newSVsv(result), 0);
                    has_errors = 1;
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
        }
    }

    if (has_errors) {
        RETVAL = newRV_noinc((SV *)errors);
    } else {
        SvREFCNT_dec((SV *)errors);
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL
