MODULE = Chandra    PACKAGE = Chandra::Notify

PROTOTYPES: DISABLE

 # ---- _xs_is_supported() - check if notifications are available ----

int
_xs_is_supported()
CODE:
{
    RETVAL = chandra_notify_is_supported();
}
OUTPUT:
    RETVAL

 # ---- _xs_send(\%args) - send a notification ----

int
# uncoverable subroutine class:ignore_covered_err
# uncoverable statement class:ignore_covered_err
_xs_send(args_hv)
    HV *args_hv
CODE:
{
    ChandraNotification notif;
    SV **svp;

    # uncoverable statement class:ignore_covered_err
    memset(&notif, 0, sizeof(notif));

    # uncoverable statement class:ignore_covered_err
    svp = hv_fetchs(args_hv, "title", 0);
    # uncoverable statement class:ignore_covered_err
    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    # uncoverable condition right count:1
    # uncoverable condition right count:2
    if (svp && SvOK(*svp)) notif.title = SvPV_nolen(*svp);

    # uncoverable statement class:ignore_covered_err
    svp = hv_fetchs(args_hv, "body", 0);
    # uncoverable statement class:ignore_covered_err
    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    # uncoverable condition right count:1
    # uncoverable condition right count:2
    if (svp && SvOK(*svp)) notif.body = SvPV_nolen(*svp);

    # uncoverable statement class:ignore_covered_err
    svp = hv_fetchs(args_hv, "icon", 0);
    # uncoverable statement class:ignore_covered_err
    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    # uncoverable condition right count:1
    # uncoverable condition right count:2
    if (svp && SvOK(*svp)) notif.icon = SvPV_nolen(*svp);

    # uncoverable statement class:ignore_covered_err
    svp = hv_fetchs(args_hv, "sound", 0);
    # uncoverable statement class:ignore_covered_err
    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    # uncoverable condition right count:1
    # uncoverable condition right count:2
    if (svp && SvOK(*svp)) notif.sound = SvIV(*svp);

    # uncoverable statement class:ignore_covered_err
    svp = hv_fetchs(args_hv, "timeout", 0);
    # uncoverable statement class:ignore_covered_err
    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    # uncoverable condition right count:1
    # uncoverable condition right count:2
    if (svp && SvOK(*svp)) notif.timeout_ms = SvIV(*svp);

    # uncoverable statement class:ignore_covered_err
    RETVAL = chandra_notify_send(aTHX_ &notif);
}
OUTPUT:
    RETVAL
