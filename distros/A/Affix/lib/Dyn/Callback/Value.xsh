#// clang-format off

MODULE = Dyn::Callback   PACKAGE = Dyn::Callback::Value

SV *
new(const char * package)
CODE:
// clang-format on
{
    RETVAL = newSV(0);
    DCValue *dcv;
    Newxz(dcv, 1, DCValue);
    sv_setref_pv(RETVAL, package, (DCpointer)dcv);
}
// clang-format off
OUTPUT:
    RETVAL

SV *
_fetch(SV * me, SV * new_value = NULL)
ALIAS:
    B = DC_SIGCHAR_BOOL
    c = DC_SIGCHAR_CHAR
    C = DC_SIGCHAR_UCHAR
    s = DC_SIGCHAR_SHORT
    S = DC_SIGCHAR_USHORT
    i = DC_SIGCHAR_INT
    I = DC_SIGCHAR_UINT
    j = DC_SIGCHAR_LONG
    J = DC_SIGCHAR_ULONG
    l = DC_SIGCHAR_LONGLONG
    L = DC_SIGCHAR_ULONGLONG
    f = DC_SIGCHAR_FLOAT
    d = DC_SIGCHAR_DOUBLE
    p = DC_SIGCHAR_POINTER
    Z = DC_SIGCHAR_STRING
CODE:
    // clang-format on
    DCValue
    *
    value;
if (sv_derived_from(ST(0), "Dyn::Callback::Value")) {
    IV tmp = SvIV((SV *)SvRV(ST(0)));
    value = INT2PTR(DCValue *, tmp);
}
else
    croak("value is not of type Dyn::Callback::Value");
switch (ix) {
case DC_SIGCHAR_BOOL:
    if (new_value) value->B = (bool)SvTRUE(new_value);
    RETVAL = boolSV((bool)value->B);
    break;
case DC_SIGCHAR_CHAR: {
    if (new_value)
        if (SvPOK(new_value))
            value->c = (char)*SvPV_nolen(new_value);
        else
            value->c = (char)SvIV(new_value);
    /*dXSTARG;
    XSprePUSH;
    PUSHp((char *)&value->c, 1);
    XSRETURN(1);*/
    RETVAL = newSViv((char)value->c);
    break;
}
case DC_SIGCHAR_UCHAR: {
    if (new_value)
        if (SvPOK(new_value))
            value->C = (unsigned char)*SvPV_nolen(new_value);
        else
            value->C = (unsigned char)SvUV(new_value);
    /*dXSTARG;
    XSprePUSH;
    PUSHp((char *)(unsigned char *)&value->C, 1);
    XSRETURN(1);*/
    RETVAL = newSVuv((char)value->C);
    break;
}
case DC_SIGCHAR_SHORT:
    if (new_value) value->s = (short)SvIV(new_value);
    RETVAL = newSViv((short)value->s);
    break;
case DC_SIGCHAR_USHORT:
    if (new_value) value->S = (unsigned short)SvUV(new_value);
    RETVAL = newSVuv((unsigned short)value->S);
    break;
case DC_SIGCHAR_INT:
    if (new_value) value->i = (int)SvIV(new_value);
    RETVAL = newSViv((int)value->i);
    break;
case DC_SIGCHAR_UINT:
    if (new_value) value->I = (unsigned int)SvUV(new_value);
    RETVAL = newSVuv((unsigned int)value->I);
    break;
case DC_SIGCHAR_LONG:
    if (new_value) value->j = (long)SvIV(new_value);
    RETVAL = newSViv((long)value->j);
    break;
case DC_SIGCHAR_ULONG:
    if (new_value) value->J = (unsigned long)SvUV(new_value);
    RETVAL = newSVuv((unsigned long)value->J);
    break;
case DC_SIGCHAR_LONGLONG:
    if (new_value) value->l = (long long)SvIV(new_value);
    RETVAL = newSViv((long)value->l);
    break;
case DC_SIGCHAR_ULONGLONG:
    if (new_value) value->J = (unsigned long long)SvUV(new_value);
    RETVAL = newSVuv((unsigned long long)value->J);
    break;
case DC_SIGCHAR_FLOAT:
    if (new_value) value->f = (float)SvNV(new_value);
    RETVAL = newSVnv((float)value->f);
    break;
case DC_SIGCHAR_DOUBLE:
    if (new_value) value->d = (double)SvNV(new_value);
    RETVAL = newSVnv((double)value->d);
    break;
case DC_SIGCHAR_POINTER: {
    if (new_value) {
        if (SvROK(new_value) /*&& sv_derived_from(new_value, "Dyn::Call::Pointer")*/) {
            IV tmp = SvIV((SV *)SvRV(new_value));
            value->p = INT2PTR(DCpointer, new_value);
        }
        else
            croak("%s is not a blessed Dyn::Call::Pointer or subclass", SvPV_nolen(new_value));
    }
    RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV((DCpointer)value->p))),
                      gv_stashpv("Dyn::Call::Pointer", GV_ADD));
} break;
case DC_SIGCHAR_STRING: {
    dXSTARG;
    if (new_value) value->Z = (const char *)SvPV_nolen(new_value);
    sv_setpv(TARG, value->Z);
    XSprePUSH;
    PUSHTARG;
    XSRETURN(1);
} break;
default:
    croak("Dyn::Callback::Value has no field %c", ix);
    break;
}
// clang-format off
OUTPUT:
    RETVAL

void
DESTROY(SV * me)
CODE:
    // clang-format on
    DCValue *value;
if (sv_derived_from(me, "Dyn::Callback::Value")) {
    IV tmp = SvIV(MUTABLE_SV(SvRV(me)));
    value = INT2PTR(DCValue *, tmp);
}
else
    croak("value is not of type Dyn::Callback::Value");
if (value) { // No double free!
    value = NULL;
    safefree(value);
}
// clang-format off
