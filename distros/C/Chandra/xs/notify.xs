MODULE = Chandra    PACKAGE = Chandra::Notify

PROTOTYPES: DISABLE

 # ---- _xs_is_supported() — check if notifications are available ----

int
_xs_is_supported()
CODE:
{
    RETVAL = chandra_notify_is_supported();
}
OUTPUT:
    RETVAL

 # ---- _xs_send(\%args) — send a notification ----

int
_xs_send(args_hv)
    HV *args_hv
CODE:
{
    ChandraNotification notif;
    SV **svp;

    memset(&notif, 0, sizeof(notif));

    svp = hv_fetchs(args_hv, "title", 0);
    if (svp && SvOK(*svp)) notif.title = SvPV_nolen(*svp);

    svp = hv_fetchs(args_hv, "body", 0);
    if (svp && SvOK(*svp)) notif.body = SvPV_nolen(*svp);

    svp = hv_fetchs(args_hv, "icon", 0);
    if (svp && SvOK(*svp)) notif.icon = SvPV_nolen(*svp);

    svp = hv_fetchs(args_hv, "sound", 0);
    if (svp && SvOK(*svp)) notif.sound = SvIV(*svp);

    svp = hv_fetchs(args_hv, "timeout", 0);
    if (svp && SvOK(*svp)) notif.timeout_ms = SvIV(*svp);

    RETVAL = chandra_notify_send(aTHX_ &notif);
}
OUTPUT:
    RETVAL
