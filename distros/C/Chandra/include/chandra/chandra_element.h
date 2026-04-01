/*
 * chandra_element.h — Element module static helpers
 * Included from Chandra.xs before the INCLUDE: xs/element.xs
 */

#ifndef CHANDRA_ELEMENT_H
#define CHANDRA_ELEMENT_H

/* Global handler registry and counters */
static HV *_elem_handlers = NULL;
static int _elem_handler_id = 0;
static int _elem_element_id = 0;

/* ========================================================================
 * Lookup tables
 * ======================================================================== */

static int
_elem_is_event_attr(const char *key)
{
    return (
        strEQ(key, "onclick")     || strEQ(key, "onchange")   ||
        strEQ(key, "onsubmit")    || strEQ(key, "onkeyup")    ||
        strEQ(key, "onkeydown")   || strEQ(key, "oninput")    ||
        strEQ(key, "onfocus")     || strEQ(key, "onblur")     ||
        strEQ(key, "onmouseover") || strEQ(key, "onmouseout") ||
        strEQ(key, "ondblclick")  || strEQ(key, "onkeypress") ||
        strEQ(key, "onmousedown") || strEQ(key, "onmouseup")  ||
        strEQ(key, "onscroll")    || strEQ(key, "onresize")   ||
        strEQ(key, "onload")      || strEQ(key, "onunload")
    );
}

static int
_elem_is_void(const char *tag)
{
    return (
        strEQ(tag, "area")   || strEQ(tag, "base")   ||
        strEQ(tag, "br")     || strEQ(tag, "col")    ||
        strEQ(tag, "embed")  || strEQ(tag, "hr")     ||
        strEQ(tag, "img")    || strEQ(tag, "input")  ||
        strEQ(tag, "link")   || strEQ(tag, "meta")   ||
        strEQ(tag, "param")  || strEQ(tag, "source") ||
        strEQ(tag, "track")  || strEQ(tag, "wbr")
    );
}

static int
_elem_is_known_key(const char *key)
{
    return (
        strEQ(key, "tag")      || strEQ(key, "id")    ||
        strEQ(key, "class")    || strEQ(key, "style") ||
        strEQ(key, "data")     || strEQ(key, "raw")   ||
        strEQ(key, "children")
    );
}

/* ========================================================================
 * HTML Escaping Functions
 * ======================================================================== */

/* Escape HTML content: & < > */
static SV *
_elem_escape_html(pTHX_ const char *src, STRLEN len)
{
    STRLEN out_len = 0;
    STRLEN i;
    SV *out;
    char *dst;
    STRLEN d = 0;

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '&': out_len += 5; break;
            case '<': out_len += 4; break;
            case '>': out_len += 4; break;
            default:  out_len += 1; break;
        }
    }

    out = newSV(out_len + 1);
    dst = SvPVX(out);

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '&': memcpy(dst + d, "&amp;", 5); d += 5; break;
            case '<': memcpy(dst + d, "&lt;", 4);  d += 4; break;
            case '>': memcpy(dst + d, "&gt;", 4);  d += 4; break;
            default:  dst[d++] = src[i]; break;
        }
    }

    dst[d] = '\0';
    SvCUR_set(out, d);
    SvPOK_on(out);
    return out;
}

/* Escape HTML attribute value: & " < > */
static SV *
_elem_escape_attr(pTHX_ const char *src, STRLEN len)
{
    STRLEN out_len = 0;
    STRLEN i;
    SV *out;
    char *dst;
    STRLEN d = 0;

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '&': out_len += 5; break;
            case '"': out_len += 6; break;
            case '<': out_len += 4; break;
            case '>': out_len += 4; break;
            default:  out_len += 1; break;
        }
    }

    out = newSV(out_len + 1);
    dst = SvPVX(out);

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '&': memcpy(dst + d, "&amp;", 5);  d += 5; break;
            case '"': memcpy(dst + d, "&quot;", 6); d += 6; break;
            case '<': memcpy(dst + d, "&lt;", 4);   d += 4; break;
            case '>': memcpy(dst + d, "&gt;", 4);   d += 4; break;
            default:  dst[d++] = src[i]; break;
        }
    }

    dst[d] = '\0';
    SvCUR_set(out, d);
    SvPOK_on(out);
    return out;
}

/* Escape JS string content: \ ' */
static SV *
_elem_escape_js(pTHX_ const char *src, STRLEN len)
{
    STRLEN out_len = 0;
    STRLEN i;
    SV *out;
    char *dst;
    STRLEN d = 0;

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '\\': out_len += 2; break;
            case '\'': out_len += 2; break;
            default:   out_len += 1; break;
        }
    }

    out = newSV(out_len + 1);
    dst = SvPVX(out);

    for (i = 0; i < len; i++) {
        switch (src[i]) {
            case '\\': dst[d++] = '\\'; dst[d++] = '\\'; break;
            case '\'': dst[d++] = '\\'; dst[d++] = '\''; break;
            default:   dst[d++] = src[i]; break;
        }
    }

    dst[d] = '\0';
    SvCUR_set(out, d);
    SvPOK_on(out);
    return out;
}

/* ========================================================================
 * Global Handler Registry
 * ======================================================================== */

static HV *
_elem_get_handlers(pTHX)
{
    if (!_elem_handlers)
        _elem_handlers = newHV();
    return _elem_handlers;
}

/* Register an event handler. Returns 1 on success, 0 on failure. */
static int
_elem_register_handler(pTHX_ HV *self_hv, const char *event_attr,
                       STRLEN event_len, SV *sub_sv)
{
    HV *handlers;
    char hid_buf[32];
    int hid_len;
    SV **hvp;

    if (!SvROK(sub_sv) || SvTYPE(SvRV(sub_sv)) != SVt_PVCV)
        return 0;

    handlers = _elem_get_handlers(aTHX);
    hid_len = snprintf(hid_buf, sizeof(hid_buf), "_h_%d", ++_elem_handler_id);

    /* Store coderef in global registry */
    (void)hv_store(handlers, hid_buf, hid_len, SvREFCNT_inc(sub_sv), 0);

    /* Store handler ID in element's _handlers hash */
    hvp = hv_fetchs(self_hv, "_handlers", 0);
    if (hvp && *hvp && SvROK(*hvp) && SvTYPE(SvRV(*hvp)) == SVt_PVHV) {
        HV *eh = (HV *)SvRV(*hvp);
        (void)hv_store(eh, event_attr, (I32)event_len,
                       newSVpvn(hid_buf, hid_len), 0);
    }

    /* Also register in Chandra::Bind */
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Bind")));
        XPUSHs(sv_2mortal(newSVpvn(hid_buf, hid_len)));
        XPUSHs(sub_sv);
        PUTBACK;
        call_method("register_handler", G_DISCARD);
        FREETMPS;
        LEAVE;
    }

    return 1;
}

/* ========================================================================
 * Tree Search Helpers
 * ======================================================================== */

static SV *
_elem_find_by_id(pTHX_ SV *self_sv, const char *target_id)
{
    HV *hv;
    SV **id_svp, **ch_svp;

    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVHV)
        return NULL;

    hv = (HV *)SvRV(self_sv);

    id_svp = hv_fetchs(hv, "id", 0);
    if (id_svp && *id_svp && SvOK(*id_svp) &&
        strEQ(SvPV_nolen(*id_svp), target_id))
        return self_sv;

    ch_svp = hv_fetchs(hv, "children", 0);
    if (ch_svp && *ch_svp && SvROK(*ch_svp) &&
        SvTYPE(SvRV(*ch_svp)) == SVt_PVAV) {
        AV *children = (AV *)SvRV(*ch_svp);
        SSize_t i, len = av_len(children) + 1;
        for (i = 0; i < len; i++) {
            SV **csvp = av_fetch(children, i, 0);
            if (csvp && *csvp && SvROK(*csvp) &&
                sv_derived_from(*csvp, "Chandra::Element")) {
                SV *found = _elem_find_by_id(aTHX_ *csvp, target_id);
                if (found) return found;
            }
        }
    }

    return NULL;
}

static SV *
_elem_find_by_tag(pTHX_ SV *self_sv, const char *target_tag)
{
    HV *hv;
    SV **tag_svp, **ch_svp;

    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVHV)
        return NULL;

    hv = (HV *)SvRV(self_sv);

    tag_svp = hv_fetchs(hv, "tag", 0);
    if (tag_svp && *tag_svp && strEQ(SvPV_nolen(*tag_svp), target_tag))
        return self_sv;

    ch_svp = hv_fetchs(hv, "children", 0);
    if (ch_svp && *ch_svp && SvROK(*ch_svp) &&
        SvTYPE(SvRV(*ch_svp)) == SVt_PVAV) {
        AV *children = (AV *)SvRV(*ch_svp);
        SSize_t i, len = av_len(children) + 1;
        for (i = 0; i < len; i++) {
            SV **csvp = av_fetch(children, i, 0);
            if (csvp && *csvp && SvROK(*csvp) &&
                sv_derived_from(*csvp, "Chandra::Element")) {
                SV *found = _elem_find_by_tag(aTHX_ *csvp, target_tag);
                if (found) return found;
            }
        }
    }

    return NULL;
}

static void
_elem_collect_by_class(pTHX_ SV *self_sv, const char *target_class,
                       STRLEN tlen, AV *results)
{
    HV *hv;
    SV **class_svp, **ch_svp;

    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVHV)
        return;

    hv = (HV *)SvRV(self_sv);

    class_svp = hv_fetchs(hv, "class", 0);
    if (class_svp && *class_svp && SvOK(*class_svp)) {
        STRLEN clen;
        const char *cstr = SvPV(*class_svp, clen);
        const char *p = cstr;
        const char *end = cstr + clen;

        while (p < end) {
            const char *start;
            STRLEN wlen;

            while (p < end && (*p == ' ' || *p == '\t'))
                p++;
            start = p;
            while (p < end && *p != ' ' && *p != '\t')
                p++;
            wlen = p - start;
            if (wlen == tlen && memEQ(start, target_class, tlen)) {
                av_push(results, SvREFCNT_inc(self_sv));
                break;
            }
        }
    }

    ch_svp = hv_fetchs(hv, "children", 0);
    if (ch_svp && *ch_svp && SvROK(*ch_svp) &&
        SvTYPE(SvRV(*ch_svp)) == SVt_PVAV) {
        AV *children = (AV *)SvRV(*ch_svp);
        SSize_t i, len = av_len(children) + 1;
        for (i = 0; i < len; i++) {
            SV **csvp = av_fetch(children, i, 0);
            if (csvp && *csvp && SvROK(*csvp) &&
                sv_derived_from(*csvp, "Chandra::Element")) {
                _elem_collect_by_class(aTHX_ *csvp, target_class,
                                       tlen, results);
            }
        }
    }
}

/* ========================================================================
 * Render Helper
 * ======================================================================== */

/* Collect HV keys into a sorted AV */
static AV *
_elem_sorted_hv_keys(pTHX_ HV *hv)
{
    AV *keys = newAV();
    HE *entry;

    hv_iterinit(hv);
    while ((entry = hv_iternext(hv))) {
        av_push(keys, newSVsv(hv_iterkeysv(entry)));
    }
    if (av_len(keys) >= 0)
        sortsv(AvARRAY(keys), av_len(keys) + 1, Perl_sv_cmp);

    return keys;
}

/* Render element to HTML string — recursive */
static SV *
_elem_render(pTHX_ SV *self_sv)
{
    HV *hv;
    SV *out;
    SV **tag_svp, **id_svp, **class_svp, **style_svp;
    SV **attrs_svp, **hdl_svp, **raw_svp, **data_svp, **children_svp;
    const char *tag;

    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVHV)
        return newSVpvs("");

    hv = (HV *)SvRV(self_sv);
    out = newSVpvs("");

    /* Tag */
    tag_svp = hv_fetchs(hv, "tag", 0);
    tag = (tag_svp && *tag_svp && SvOK(*tag_svp))
        ? SvPV_nolen(*tag_svp) : "div";
    sv_catpvf(out, "<%s", tag);

    /* id */
    id_svp = hv_fetchs(hv, "id", 0);
    if (id_svp && *id_svp && SvOK(*id_svp)) {
        STRLEN id_len;
        const char *id_str = SvPV(*id_svp, id_len);
        SV *esc = _elem_escape_attr(aTHX_ id_str, id_len);
        sv_catpvs(out, " id=\"");
        sv_catsv(out, esc);
        sv_catpvs(out, "\"");
        SvREFCNT_dec(esc);
    }

    /* class */
    class_svp = hv_fetchs(hv, "class", 0);
    if (class_svp && *class_svp && SvOK(*class_svp)) {
        STRLEN cls_len;
        const char *cls_str = SvPV(*class_svp, cls_len);
        SV *esc = _elem_escape_attr(aTHX_ cls_str, cls_len);
        sv_catpvs(out, " class=\"");
        sv_catsv(out, esc);
        sv_catpvs(out, "\"");
        SvREFCNT_dec(esc);
    }

    /* style */
    style_svp = hv_fetchs(hv, "style", 0);
    if (style_svp && *style_svp && SvOK(*style_svp)) {
        SV *style_str = NULL;

        if (SvROK(*style_svp) &&
            SvTYPE(SvRV(*style_svp)) == SVt_PVHV) {
            HV *style_hv = (HV *)SvRV(*style_svp);
            AV *skeys = _elem_sorted_hv_keys(aTHX_ style_hv);
            SSize_t slen = av_len(skeys) + 1;

            if (slen > 0) {
                SSize_t si;
                style_str = newSVpvs("");
                for (si = 0; si < slen; si++) {
                    SV **ksvp = av_fetch(skeys, si, 0);
                    if (ksvp && *ksvp) {
                        STRLEN kl;
                        const char *kstr = SvPV(*ksvp, kl);
                        SV **vsvp = hv_fetch(style_hv, kstr, kl, 0);
                        if (vsvp && *vsvp) {
                            if (SvCUR(style_str) > 0)
                                sv_catpvs(style_str, "; ");
                            sv_catpvf(style_str, "%s: %s",
                                      kstr, SvPV_nolen(*vsvp));
                        }
                    }
                }
            }
            SvREFCNT_dec((SV *)skeys);
        } else {
            STRLEN slen;
            const char *sstr = SvPV(*style_svp, slen);
            if (slen > 0)
                style_str = newSVpvn(sstr, slen);
        }

        if (style_str && SvCUR(style_str) > 0) {
            STRLEN ssl;
            const char *ssstr = SvPV(style_str, ssl);
            SV *esc = _elem_escape_attr(aTHX_ ssstr, ssl);
            sv_catpvs(out, " style=\"");
            sv_catsv(out, esc);
            sv_catpvs(out, "\"");
            SvREFCNT_dec(esc);
        }
        if (style_str)
            SvREFCNT_dec(style_str);
    }

    /* Attributes (sorted) */
    attrs_svp = hv_fetchs(hv, "attributes", 0);
    if (attrs_svp && *attrs_svp && SvROK(*attrs_svp) &&
        SvTYPE(SvRV(*attrs_svp)) == SVt_PVHV) {
        HV *attrs = (HV *)SvRV(*attrs_svp);
        AV *akeys = _elem_sorted_hv_keys(aTHX_ attrs);
        SSize_t alen = av_len(akeys) + 1;
        SSize_t ai;

        for (ai = 0; ai < alen; ai++) {
            SV **ksvp = av_fetch(akeys, ai, 0);
            if (ksvp && *ksvp) {
                STRLEN kl;
                const char *kstr = SvPV(*ksvp, kl);
                SV **vsvp = hv_fetch(attrs, kstr, kl, 0);

                if (vsvp && *vsvp && SvOK(*vsvp)) {
                    STRLEN vl;
                    const char *vstr = SvPV(*vsvp, vl);
                    SV *esc = _elem_escape_attr(aTHX_ vstr, vl);
                    sv_catpvf(out, " %s=\"", kstr);
                    sv_catsv(out, esc);
                    sv_catpvs(out, "\"");
                    SvREFCNT_dec(esc);
                } else {
                    /* Boolean attribute (undef value) */
                    sv_catpvf(out, " %s", kstr);
                }
            }
        }
        SvREFCNT_dec((SV *)akeys);
    }

    /* Event handlers (sorted) */
    hdl_svp = hv_fetchs(hv, "_handlers", 0);
    if (hdl_svp && *hdl_svp && SvROK(*hdl_svp) &&
        SvTYPE(SvRV(*hdl_svp)) == SVt_PVHV) {
        HV *hdl = (HV *)SvRV(*hdl_svp);
        AV *hkeys = _elem_sorted_hv_keys(aTHX_ hdl);
        SSize_t hlen = av_len(hkeys) + 1;
        SSize_t hi;

        for (hi = 0; hi < hlen; hi++) {
            SV **ksvp = av_fetch(hkeys, hi, 0);
            if (ksvp && *ksvp) {
                STRLEN kal;
                const char *kastr = SvPV(*ksvp, kal);
                SV **hidsvp = hv_fetch(hdl, kastr, kal, 0);

                if (hidsvp && *hidsvp) {
                    const char *hid = SvPV_nolen(*hidsvp);
                    const char *eid = "";
                    SV *esc_eid, *js, *esc_js;
                    STRLEN eid_len, jslen;
                    const char *jsstr;

                    /* Get element id for targetId */
                    SV **eid_svp = hv_fetchs(hv, "id", 0);
                    if (!eid_svp || !*eid_svp || !SvOK(*eid_svp))
                        eid_svp = hv_fetchs(hv, "_eid", 0);
                    if (eid_svp && *eid_svp && SvOK(*eid_svp))
                        eid = SvPV_nolen(*eid_svp);

                    eid_len = strlen(eid);
                    esc_eid = _elem_escape_js(aTHX_ eid, eid_len);

                    js = newSVpvf(
                        "window.chandra._event('%s',window.chandra"
                        "._eventData(event,{targetId:'%s'}))",
                        hid, SvPV_nolen(esc_eid));
                    SvREFCNT_dec(esc_eid);

                    jsstr = SvPV(js, jslen);
                    esc_js = _elem_escape_attr(aTHX_ jsstr, jslen);
                    sv_catpvf(out, " %s=\"", kastr);
                    sv_catsv(out, esc_js);
                    sv_catpvs(out, "\"");
                    SvREFCNT_dec(esc_js);
                    SvREFCNT_dec(js);
                }
            }
        }
        SvREFCNT_dec((SV *)hkeys);
    }

    /* Void element check */
    if (_elem_is_void(tag)) {
        sv_catpvs(out, " />");
        return out;
    }

    sv_catpvs(out, ">");

    /* Raw content (not escaped) */
    raw_svp = hv_fetchs(hv, "raw", 0);
    if (raw_svp && *raw_svp && SvOK(*raw_svp)) {
        sv_catsv(out, *raw_svp);
    }

    /* Text data (escaped) */
    data_svp = hv_fetchs(hv, "data", 0);
    if (data_svp && *data_svp && SvOK(*data_svp)) {
        STRLEN dlen;
        const char *dstr = SvPV(*data_svp, dlen);
        SV *esc = _elem_escape_html(aTHX_ dstr, dlen);
        sv_catsv(out, esc);
        SvREFCNT_dec(esc);
    }

    /* Children (recursive) */
    children_svp = hv_fetchs(hv, "children", 0);
    if (children_svp && *children_svp && SvROK(*children_svp) &&
        SvTYPE(SvRV(*children_svp)) == SVt_PVAV) {
        AV *children = (AV *)SvRV(*children_svp);
        SSize_t i, clen = av_len(children) + 1;
        for (i = 0; i < clen; i++) {
            SV **csvp = av_fetch(children, i, 0);
            if (csvp && *csvp) {
                if (SvROK(*csvp) &&
                    sv_derived_from(*csvp, "Chandra::Element")) {
                    SV *child_html = _elem_render(aTHX_ *csvp);
                    sv_catsv(out, child_html);
                    SvREFCNT_dec(child_html);
                } else {
                    STRLEN csl;
                    const char *csstr = SvPV(*csvp, csl);
                    SV *esc = _elem_escape_html(aTHX_ csstr, csl);
                    sv_catsv(out, esc);
                    SvREFCNT_dec(esc);
                }
            }
        }
    }

    /* Closing tag */
    sv_catpvf(out, "</%s>", tag);
    return out;
}

#endif /* CHANDRA_ELEMENT_H */
