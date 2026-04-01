MODULE = Chandra    PACKAGE = Chandra::Element

PROTOTYPES: DISABLE

BOOT:
{
    _elem_handlers = newHV();
}

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *args = NULL;
    HV *self_hv;
    HV *attrs;
    AV *children;
    HV *hdl;
    SV **tag_svp, **id_svp, **style_svp, **class_svp;
    SV **data_svp, **raw_svp;
    char eid_buf[32];
    int eid_len;
    SV *self_rv;

    if (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) &&
        SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
        args = (HV *)SvRV(ST(1));
    }

    self_hv = newHV();

    /* tag */
    tag_svp = args ? hv_fetchs(args, "tag", 0) : NULL;
    (void)hv_stores(self_hv, "tag",
        (tag_svp && *tag_svp && SvOK(*tag_svp))
            ? newSVsv(*tag_svp) : newSVpvs("div"));

    /* style */
    style_svp = args ? hv_fetchs(args, "style", 0) : NULL;
    if (style_svp && *style_svp && SvOK(*style_svp))
        (void)hv_stores(self_hv, "style", newSVsv(*style_svp));

    /* class */
    class_svp = args ? hv_fetchs(args, "class", 0) : NULL;
    if (class_svp && *class_svp && SvOK(*class_svp))
        (void)hv_stores(self_hv, "class", newSVsv(*class_svp));

    /* data */
    data_svp = args ? hv_fetchs(args, "data", 0) : NULL;
    if (data_svp && *data_svp && SvOK(*data_svp))
        (void)hv_stores(self_hv, "data", newSVsv(*data_svp));

    /* raw */
    raw_svp = args ? hv_fetchs(args, "raw", 0) : NULL;
    if (raw_svp && *raw_svp && SvOK(*raw_svp))
        (void)hv_stores(self_hv, "raw", newSVsv(*raw_svp));

    /* attributes, children, _handlers */
    attrs = newHV();
    (void)hv_stores(self_hv, "attributes", newRV_noinc((SV *)attrs));
    children = newAV();
    (void)hv_stores(self_hv, "children", newRV_noinc((SV *)children));
    hdl = newHV();
    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)hdl));

    /* _eid */
    eid_len = snprintf(eid_buf, sizeof(eid_buf), "_e_%d",
                       ++_elem_element_id);
    (void)hv_stores(self_hv, "_eid", newSVpvn(eid_buf, eid_len));

    /* id — use provided or auto-assign from _eid */
    id_svp = args ? hv_fetchs(args, "id", 0) : NULL;
    if (id_svp && *id_svp && SvOK(*id_svp)) {
        (void)hv_stores(self_hv, "id", newSVsv(*id_svp));
    } else {
        (void)hv_stores(self_hv, "id", newSVpvn(eid_buf, eid_len));
    }

    /* Bless */
    self_rv = sv_bless(newRV_noinc((SV *)self_hv),
                       gv_stashpv(class, GV_ADD));

    /* Process extra keys from args: attributes and event handlers */
    if (args) {
        HE *entry;
        hv_iterinit(args);
        while ((entry = hv_iternext(args))) {
            STRLEN klen;
            const char *key = HePV(entry, klen);
            SV *val;

            if (_elem_is_known_key(key))
                continue;

            val = HeVAL(entry);
            if (_elem_is_event_attr(key)) {
                _elem_register_handler(aTHX_ self_hv, key, klen, val);
            } else {
                (void)hv_store(attrs, key, (I32)klen,
                               newSVsv(val), 0);
            }
        }

        /* Process children */
        {
            SV **ch_svp = hv_fetchs(args, "children", 0);
            if (ch_svp && *ch_svp && SvROK(*ch_svp) &&
                SvTYPE(SvRV(*ch_svp)) == SVt_PVAV) {
                AV *ch_av = (AV *)SvRV(*ch_svp);
                SSize_t i, chlen = av_len(ch_av) + 1;
                for (i = 0; i < chlen; i++) {
                    SV **csvp = av_fetch(ch_av, i, 0);
                    if (csvp && *csvp) {
                        SV *child;
                        if (SvROK(*csvp) &&
                            SvTYPE(SvRV(*csvp)) == SVt_PVHV) {
                            /* Hashref → create new Element */
                            int count;
                            dSP;
                            ENTER;
                            SAVETMPS;
                            PUSHMARK(SP);
                            XPUSHs(sv_2mortal(
                                newSVpvs("Chandra::Element")));
                            XPUSHs(*csvp);
                            PUTBACK;
                            count = call_method("new", G_SCALAR);
                            SPAGAIN;
                            child = (count > 0)
                                ? SvREFCNT_inc(POPs)
                                : &PL_sv_undef;
                            PUTBACK;
                            FREETMPS;
                            LEAVE;
                        } else {
                            child = newSVsv(*csvp);
                        }
                        av_push(children, child);
                    }
                }
            }
        }
    }

    RETVAL = self_rv;
}
OUTPUT:
    RETVAL

SV *
add_child(self, child)
    SV *self
    SV *child
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **ch_svp = hv_fetchs(hv, "children", 0);
    AV *children = (AV *)SvRV(*ch_svp);

    if (SvROK(child) && SvTYPE(SvRV(child)) == SVt_PVHV &&
        !sv_isobject(child)) {
        /* Hashref → create new Element */
        int count;
        SV *new_child;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Chandra::Element")));
        XPUSHs(child);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        new_child = (count > 0) ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS;
        LEAVE;
        av_push(children, new_child);
        RETVAL = SvREFCNT_inc(new_child);
    } else {
        av_push(children, SvREFCNT_inc(child));
        RETVAL = SvREFCNT_inc(child);
    }
}
OUTPUT:
    RETVAL

void
children(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **ch_svp = hv_fetchs(hv, "children", 0);
    if (ch_svp && *ch_svp && SvROK(*ch_svp) &&
        SvTYPE(SvRV(*ch_svp)) == SVt_PVAV) {
        AV *children = (AV *)SvRV(*ch_svp);
        SSize_t i, len = av_len(children) + 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(len)));
        } else {
            EXTEND(SP, len);
            for (i = 0; i < len; i++) {
                SV **csvp = av_fetch(children, i, 0);
                if (csvp && *csvp)
                    PUSHs(*csvp);
            }
        }
    } else if (GIMME_V == G_SCALAR) {
        XPUSHs(sv_2mortal(newSViv(0)));
    }
}

SV *
tag(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "tag", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSVpvs("div");
}
OUTPUT:
    RETVAL

SV *
id(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;
    if (items > 1 && SvOK(ST(1))) {
        (void)hv_stores(hv, "id", newSVsv(ST(1)));
    }
    svp = hv_fetchs(hv, "id", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
class(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;
    if (items > 1 && SvOK(ST(1))) {
        (void)hv_stores(hv, "class", newSVsv(ST(1)));
    }
    svp = hv_fetchs(hv, "class", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
data(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;
    if (items > 1 && SvOK(ST(1))) {
        SV *val = ST(1);
        if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
            /* Unwrap single-element array (Moonshine compat) */
            AV *av = (AV *)SvRV(val);
            SV **elem = av_fetch(av, 0, 0);
            (void)hv_stores(hv, "data",
                (elem && *elem) ? newSVsv(*elem) : newSV(0));
        } else {
            (void)hv_stores(hv, "data", newSVsv(val));
        }
    }
    svp = hv_fetchs(hv, "data", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
raw(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;
    if (items > 1 && SvOK(ST(1))) {
        (void)hv_stores(hv, "raw", newSVsv(ST(1)));
    }
    svp = hv_fetchs(hv, "raw", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
style(self, ...)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp;
    if (items > 1 && SvOK(ST(1))) {
        (void)hv_stores(hv, "style", newSVsv(ST(1)));
    }
    svp = hv_fetchs(hv, "style", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
attribute(self, key, ...)
    SV *self
    SV *key
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **attrs_svp = hv_fetchs(hv, "attributes", 0);
    HV *attrs = (HV *)SvRV(*attrs_svp);
    STRLEN klen;
    const char *kstr = SvPV(key, klen);
    SV **vsvp;

    if (items > 2 && SvOK(ST(2))) {
        (void)hv_store(attrs, kstr, (I32)klen, newSVsv(ST(2)), 0);
    }

    vsvp = hv_fetch(attrs, kstr, (I32)klen, 0);
    RETVAL = (vsvp && *vsvp) ? SvREFCNT_inc(*vsvp) : newSV(0);
}
OUTPUT:
    RETVAL

SV *
get_element_by_id(self, target_id)
    SV *self
    const char *target_id
CODE:
{
    SV *found = _elem_find_by_id(aTHX_ self, target_id);
    RETVAL = found ? SvREFCNT_inc(found) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
get_element_by_tag(self, target_tag)
    SV *self
    const char *target_tag
CODE:
{
    SV *found = _elem_find_by_tag(aTHX_ self, target_tag);
    RETVAL = found ? SvREFCNT_inc(found) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
get_elements_by_class(self, target_class)
    SV *self
    const char *target_class
PPCODE:
{
    AV *results = newAV();
    STRLEN tlen = strlen(target_class);
    SSize_t i, len;

    _elem_collect_by_class(aTHX_ self, target_class, tlen, results);

    len = av_len(results) + 1;
    EXTEND(SP, len);
    for (i = 0; i < len; i++) {
        SV **svp = av_fetch(results, i, 0);
        if (svp && *svp)
            PUSHs(*svp);
    }
    SvREFCNT_dec((SV *)results);
}

SV *
render(self)
    SV *self
CODE:
    RETVAL = _elem_render(aTHX_ self);
OUTPUT:
    RETVAL

SV *
handlers(...)
CODE:
{
    HV *h;
    PERL_UNUSED_VAR(items);
    h = _elem_get_handlers(aTHX);
    RETVAL = newRV_inc((SV *)h);
}
OUTPUT:
    RETVAL

SV *
get_handler(self_or_class, hid)
    SV *self_or_class
    SV *hid
CODE:
{
    HV *h;
    STRLEN hlen;
    const char *hstr;
    SV **svp;

    PERL_UNUSED_VAR(self_or_class);
    h = _elem_get_handlers(aTHX);
    hstr = SvPV(hid, hlen);
    svp = hv_fetch(h, hstr, (I32)hlen, 0);
    if (svp && *svp) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

void
clear_handlers(...)
CODE:
{
    HV *h;
    PERL_UNUSED_VAR(items);
    h = _elem_get_handlers(aTHX);
    hv_clear(h);
    _elem_handler_id = 0;
}

void
reset_ids(...)
CODE:
{
    HV *h;
    PERL_UNUSED_VAR(items);
    _elem_element_id = 0;
    _elem_handler_id = 0;
    h = _elem_get_handlers(aTHX);
    hv_clear(h);
}
