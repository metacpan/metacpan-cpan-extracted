MODULE = Chandra    PACKAGE = Chandra::Socket::Token

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    NV ttl      = 3600.0;   /* 1 hour default */
    NV rotation = 1800.0;   /* 30 minutes default */
    NV grace    = 60.0;     /* 60 seconds default */
    int length  = 32;       /* 32 bytes = 64 hex chars */
    NV now;
    SV *token;
    I32 i;

    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "ttl"))           ttl      = SvNV(val);
        else if (strEQ(key, "rotation")) rotation = SvNV(val);
        else if (strEQ(key, "grace"))    grace    = SvNV(val);
        else if (strEQ(key, "length"))   length   = SvIV(val);
    }

    now = _token_now();
    token = _token_generate(aTHX_ length);

    (void)hv_stores(self_hv, "_ttl",         newSVnv(ttl));
    (void)hv_stores(self_hv, "_rotation",    newSVnv(rotation));
    (void)hv_stores(self_hv, "_grace",       newSVnv(grace));
    (void)hv_stores(self_hv, "_length",      newSViv(length));
    (void)hv_stores(self_hv, "_current",     token);
    (void)hv_stores(self_hv, "_previous",    newSV(0));
    (void)hv_stores(self_hv, "_created_at",  newSVnv(now));
    (void)hv_stores(self_hv, "_expires_at",  newSVnv(now + ttl));
    (void)hv_stores(self_hv, "_rotation_at", newSVnv(now + rotation));
    (void)hv_stores(self_hv, "_grace_until", newSVnv(0));
    (void)hv_stores(self_hv, "_on_rotate",   newSV(0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
        gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

SV *
generate(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **len_svp = hv_fetchs(hv, "_length", 0);
    int len = (len_svp && SvOK(*len_svp)) ? SvIV(*len_svp) : 32;
    RETVAL = _token_generate(aTHX_ len);
}
OUTPUT:
    RETVAL

int
validate(self, token_sv)
    SV *self
    SV *token_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **cur_svp   = hv_fetchs(hv, "_current", 0);
    SV **prev_svp  = hv_fetchs(hv, "_previous", 0);
    SV **grace_svp = hv_fetchs(hv, "_grace_until", 0);
    SV **exp_svp   = hv_fetchs(hv, "_expires_at", 0);

    RETVAL = 0;

    if (!token_sv || !SvOK(token_sv) || !SvCUR(token_sv))
        goto done;

    /* Check if fully expired */
    if (exp_svp && SvOK(*exp_svp) && _token_expired(SvNV(*exp_svp)))
        goto done;

    /* Check current token */
    if (cur_svp && SvOK(*cur_svp) && sv_eq(token_sv, *cur_svp)) {
        RETVAL = 1;
        goto done;
    }

    /* Check previous token during grace period */
    if (prev_svp && SvOK(*prev_svp) && SvCUR(*prev_svp) &&
        grace_svp && SvOK(*grace_svp) &&
        _token_in_grace(SvNV(*grace_svp))) {
        if (sv_eq(token_sv, *prev_svp)) {
            RETVAL = 1;
            goto done;
        }
    }

    done:
    ;
}
OUTPUT:
    RETVAL

SV *
current(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_current", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
previous(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_previous", 0);
    RETVAL = (svp && SvOK(*svp) && SvCUR(*svp))
        ? SvREFCNT_inc(*svp) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
rotate(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **cur_svp  = hv_fetchs(hv, "_current", 0);
    SV **len_svp  = hv_fetchs(hv, "_length", 0);
    SV **ttl_svp  = hv_fetchs(hv, "_ttl", 0);
    SV **rot_svp  = hv_fetchs(hv, "_rotation", 0);
    SV **grace_svp = hv_fetchs(hv, "_grace", 0);
    SV **cb_svp   = hv_fetchs(hv, "_on_rotate", 0);
    int len  = (len_svp && SvOK(*len_svp)) ? SvIV(*len_svp) : 32;
    NV ttl   = (ttl_svp && SvOK(*ttl_svp)) ? SvNV(*ttl_svp) : 3600.0;
    NV rot   = (rot_svp && SvOK(*rot_svp)) ? SvNV(*rot_svp) : 1800.0;
    NV grace = (grace_svp && SvOK(*grace_svp)) ? SvNV(*grace_svp) : 60.0;
    NV now   = _token_now();
    SV *new_token;

    /* Move current → previous */
    if (cur_svp && SvOK(*cur_svp))
        (void)hv_stores(hv, "_previous", newSVsv(*cur_svp));
    else
        (void)hv_stores(hv, "_previous", newSV(0));

    /* Generate new current */
    new_token = _token_generate(aTHX_ len);
    (void)hv_stores(hv, "_current", new_token);

    /* Update timestamps */
    (void)hv_stores(hv, "_created_at",  newSVnv(now));
    (void)hv_stores(hv, "_expires_at",  newSVnv(now + ttl));
    (void)hv_stores(hv, "_rotation_at", newSVnv(now + rot));
    (void)hv_stores(hv, "_grace_until", newSVnv(now + grace));

    /* Fire on_rotate callback */
    if (cb_svp && SvOK(*cb_svp) && SvROK(*cb_svp)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(SvREFCNT_inc(new_token)));
        PUTBACK;
        call_sv(*cb_svp, G_DISCARD);
        FREETMPS; LEAVE;
    }
}

int
rotation_due(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_rotation_at", 0);
    RETVAL = (svp && SvOK(*svp))
        ? _token_rotation_due(SvNV(*svp)) : 0;
}
OUTPUT:
    RETVAL

int
expired(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_expires_at", 0);
    RETVAL = (svp && SvOK(*svp))
        ? _token_expired(SvNV(*svp)) : 0;
}
OUTPUT:
    RETVAL

int
in_grace(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_grace_until", 0);
    RETVAL = (svp && SvOK(*svp) && SvNV(*svp) > 0)
        ? _token_in_grace(SvNV(*svp)) : 0;
}
OUTPUT:
    RETVAL

SV *
info(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    HV *out = newHV();
    SV **svp;

    svp = hv_fetchs(hv, "_current", 0);
    (void)hv_stores(out, "current",
        (svp && SvOK(*svp)) ? newSVsv(*svp) : newSV(0));

    svp = hv_fetchs(hv, "_previous", 0);
    (void)hv_stores(out, "previous",
        (svp && SvOK(*svp) && SvCUR(*svp)) ? newSVsv(*svp) : newSV(0));

    svp = hv_fetchs(hv, "_created_at", 0);
    (void)hv_stores(out, "created_at",
        (svp && SvOK(*svp)) ? newSVnv(SvNV(*svp)) : newSVnv(0));

    svp = hv_fetchs(hv, "_expires_at", 0);
    (void)hv_stores(out, "expires_at",
        (svp && SvOK(*svp)) ? newSVnv(SvNV(*svp)) : newSVnv(0));

    svp = hv_fetchs(hv, "_rotation_at", 0);
    (void)hv_stores(out, "rotation_at",
        (svp && SvOK(*svp)) ? newSVnv(SvNV(*svp)) : newSVnv(0));

    svp = hv_fetchs(hv, "_grace_until", 0);
    (void)hv_stores(out, "grace_until",
        (svp && SvOK(*svp)) ? newSVnv(SvNV(*svp)) : newSVnv(0));

    RETVAL = newRV_noinc((SV *)out);
}
OUTPUT:
    RETVAL

SV *
on_rotate(self, callback)
    SV *self
    SV *callback
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_on_rotate", newSVsv(callback));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

NV
ttl(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_ttl", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvNV(*svp) : 0;
}
OUTPUT:
    RETVAL

NV
rotation_interval(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_rotation", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvNV(*svp) : 0;
}
OUTPUT:
    RETVAL

NV
grace_period(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "_grace", 0);
    RETVAL = (svp && SvOK(*svp)) ? SvNV(*svp) : 0;
}
OUTPUT:
    RETVAL
