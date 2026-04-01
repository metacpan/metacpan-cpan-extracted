MODULE = Chandra    PACKAGE = Chandra::Event

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
CODE:
    HV *hv;
    if (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
        hv = (HV *)SvRV(ST(1));
        SvREFCNT_inc((SV *)hv);
    } else {
        hv = newHV();
    }
    RETVAL = sv_bless(newRV_noinc((SV *)hv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

SV *
type(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "type", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
target_id(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "targetId", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
target_name(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "targetName", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
value(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "value", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
checked(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "checked", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
key(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "key", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
key_code(self)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(hv, "keyCode", 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL

SV *
data(self, ...)
    SV *self
CODE:
    HV *hv = (HV *)SvRV(self);
    SV **data_svp = hv_fetchs(hv, "data", 0);
    if (items > 1) {
        /* data($key) — lookup within the data hash */
        if (data_svp && *data_svp && SvROK(*data_svp) && SvTYPE(SvRV(*data_svp)) == SVt_PVHV) {
            HV *data_hv = (HV *)SvRV(*data_svp);
            STRLEN klen;
            const char *key = SvPV(ST(1), klen);
            SV **val = hv_fetch(data_hv, key, (I32)klen, 0);
            RETVAL = (val && *val) ? SvREFCNT_inc(*val) : newSV(0);
        } else {
            RETVAL = newSV(0);
        }
    } else {
        /* data() — return raw data field */
        RETVAL = (data_svp && *data_svp) ? SvREFCNT_inc(*data_svp) : newSV(0);
    }
OUTPUT:
    RETVAL

SV *
get(self, key)
    SV *self
    SV *key
CODE:
    HV *hv = (HV *)SvRV(self);
    STRLEN klen;
    const char *kpv = SvPV(key, klen);
    SV **svp = hv_fetch(hv, kpv, (I32)klen, 0);
    RETVAL = (svp && *svp) ? SvREFCNT_inc(*svp) : newSV(0);
OUTPUT:
    RETVAL
