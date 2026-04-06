#ifndef CHANDRA_CONTEXTMENU_H
#define CHANDRA_CONTEXTMENU_H

/* Static C helper functions for Chandra::ContextMenu */

static IV
_cm_next_id(pTHX_ HV *hv)
{
    SV **id_svp = hv_fetchs(hv, "_next_id", 0);
    IV id = SvIV(*id_svp);
    sv_setiv(*id_svp, id + 1);
    return id;
}

static void _cm_items_to_js(pTHX_ SV *js, AV *items_av);

static void
_cm_register_actions(pTHX_ HV *self_hv, AV *items_av, HV *actions_hv)
{
    I32 len = av_len(items_av);
    I32 i;

    for (i = 0; i <= len; i++) {
        SV **elem = av_fetch(items_av, i, 0);
        HV *item_hv;
        SV **action_svp, **sub_svp;

        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
            continue;
        item_hv = (HV *)SvRV(*elem);

        action_svp = hv_fetchs(item_hv, "action", 0);
        if (action_svp && SvROK(*action_svp) && SvTYPE(SvRV(*action_svp)) == SVt_PVCV) {
            IV id = _cm_next_id(aTHX_ self_hv);
            char id_str[32];
            int id_len = my_snprintf(id_str, sizeof(id_str), "%ld", (long)id);
            (void)hv_stores(item_hv, "_id", newSViv(id));
            (void)hv_store(actions_hv, id_str, id_len, newSVsv(*action_svp), 0);
        }

        sub_svp = hv_fetchs(item_hv, "submenu", 0);
        if (sub_svp && SvROK(*sub_svp) && SvTYPE(SvRV(*sub_svp)) == SVt_PVAV) {
            _cm_register_actions(aTHX_ self_hv, (AV *)SvRV(*sub_svp), actions_hv);
        }
    }
}

static void
_cm_items_to_js(pTHX_ SV *js, AV *items_av)
{
    I32 len = av_len(items_av);
    I32 i;

    sv_catpvs(js, "[");
    for (i = 0; i <= len; i++) {
        SV **elem = av_fetch(items_av, i, 0);
        HV *item_hv;
        SV **sep_svp, **label_svp, **sub_svp;
        SV **disabled_svp, **checkable_svp, **checked_svp;
        SV **icon_svp, **shortcut_svp, **id_svp;

        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
            continue;
        item_hv = (HV *)SvRV(*elem);

        if (i > 0) sv_catpvs(js, ",");
        sv_catpvs(js, "{");

        sep_svp = hv_fetchs(item_hv, "separator", 0);
        if (sep_svp && SvTRUE(*sep_svp)) {
            sv_catpvs(js, "sep:1}");
            continue;
        }

        label_svp = hv_fetchs(item_hv, "label", 0);
        if (label_svp && SvOK(*label_svp)) {
            STRLEN llen;
            const char *lbl = SvPV(*label_svp, llen);
            sv_catpvs(js, "l:'");
            sv_catpvn(js, lbl, llen);
            sv_catpvs(js, "'");
        }

        id_svp = hv_fetchs(item_hv, "_id", 0);
        if (id_svp && SvOK(*id_svp)) {
            sv_catpvf(js, ",id:%ld", (long)SvIV(*id_svp));
        }

        disabled_svp = hv_fetchs(item_hv, "disabled", 0);
        if (disabled_svp && SvTRUE(*disabled_svp)) {
            sv_catpvs(js, ",dis:1");
        }

        checkable_svp = hv_fetchs(item_hv, "checkable", 0);
        if (checkable_svp && SvTRUE(*checkable_svp)) {
            sv_catpvs(js, ",chk:1");
            checked_svp = hv_fetchs(item_hv, "checked", 0);
            if (checked_svp && SvTRUE(*checked_svp))
                sv_catpvs(js, ",ckd:1");
        }

        icon_svp = hv_fetchs(item_hv, "icon", 0);
        if (icon_svp && SvOK(*icon_svp)) {
            sv_catpvs(js, ",ico:'");
            sv_catpvn(js, SvPV_nolen(*icon_svp), SvCUR(*icon_svp));
            sv_catpvs(js, "'");
        }

        shortcut_svp = hv_fetchs(item_hv, "shortcut", 0);
        if (shortcut_svp && SvOK(*shortcut_svp)) {
            sv_catpvs(js, ",sc:'");
            sv_catpvn(js, SvPV_nolen(*shortcut_svp), SvCUR(*shortcut_svp));
            sv_catpvs(js, "'");
        }

        sub_svp = hv_fetchs(item_hv, "submenu", 0);
        if (sub_svp && SvROK(*sub_svp) && SvTYPE(SvRV(*sub_svp)) == SVt_PVAV) {
            sv_catpvs(js, ",sub:");
            _cm_items_to_js(aTHX_ js, (AV *)SvRV(*sub_svp));
        }

        sv_catpvs(js, "}");
    }
    sv_catpvs(js, "]");
}

#endif /* CHANDRA_CONTEXTMENU_H */
