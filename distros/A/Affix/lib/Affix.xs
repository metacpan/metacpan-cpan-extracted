#include "../lib/clutter.h"
typedef struct {
    SV *type;
    void *ptr;
} var_ptr;

int get_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    SV *val = ptr2sv(aTHX_ ptr->ptr, ptr->type);
    sv_setsv(sv, val);
    return 0;
}

int set_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    DCpointer val = SvOK(sv) ? sv2ptr(aTHX_ ptr->type, sv, ptr->ptr, 0, 0) : NULL;
    return 0;
}

int free_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    sv_2mortal(ptr->type);
    safefree(ptr);
    return 0;
}

static MGVTBL pin_vtbl = {
    get_pin,  // get
    set_pin,  // set
    NULL,     // len
    NULL,     // clear
    free_pin, // free
    NULL,     // copy
    NULL,     // dup
    NULL      // local
};

typedef struct CoW {
    DCCallback *cb;
    struct CoW *next;
} CoW;

static CoW *cow;

typedef struct {
    char *sig;
    size_t sig_len;
    char ret;
    void *fptr;
    char *perl_sig;
    DLLib *lib;
    AV *args;
    SV *retval;
    bool reset;
} Call;

typedef struct {
    char *sig;
    size_t sig_len;
    char ret;
    char *perl_sig;
    SV *cv;
    AV *args;
    SV *retval;
    dTHXfield(perl)
} Callback;

char cbHandler(DCCallback *cb, DCArgs *args, DCValue *result, DCpointer userdata) {
    Callback *cbx = (Callback *)userdata;
    /*warn("Triggering callback: %c (%s [%d] return: %c) at %s line %d", cbx->ret,
       cbx->sig, cbx->sig_len, cbx->ret, __FILE__, __LINE__);*/
    dTHXa(cbx->perl);

    dSP;
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    EXTEND(SP, cbx->sig_len);
    char type;
    for (int i = 0; i < cbx->sig_len; ++i) {
        type = cbx->sig[i];
        // warn("type : %c", type);
        switch (type) {
        case DC_SIGCHAR_VOID:
            // TODO: push undef?
            break;
        case DC_SIGCHAR_BOOL:
            mPUSHs(boolSV(dcbArgBool(args)));
            break;
        case DC_SIGCHAR_CHAR:
            mPUSHi((IV)dcbArgChar(args));
            break;
        case DC_SIGCHAR_UCHAR:
            mPUSHu((UV)dcbArgChar(args));
            break;
        case DC_SIGCHAR_SHORT:
            mPUSHi((IV)dcbArgShort(args));
            break;
        case DC_SIGCHAR_USHORT:
            mPUSHu((UV)dcbArgShort(args));
            break;
        case DC_SIGCHAR_INT:
            mPUSHi((IV)dcbArgInt(args));
            break;
        case DC_SIGCHAR_UINT:
            mPUSHu((UV)dcbArgInt(args));
            break;
        case DC_SIGCHAR_LONG:
            mPUSHi((IV)dcbArgLong(args));
            break;
        case DC_SIGCHAR_ULONG:
            mPUSHu((UV)dcbArgLong(args));
            break;
        case DC_SIGCHAR_LONGLONG:
            mPUSHi((IV)dcbArgLongLong(args));
            break;
        case DC_SIGCHAR_ULONGLONG:
            mPUSHu((UV)dcbArgLongLong(args));
            break;
        case DC_SIGCHAR_FLOAT:
            mPUSHn((NV)dcbArgFloat(args));
            break;
        case DC_SIGCHAR_DOUBLE:
            mPUSHn((NV)dcbArgDouble(args));
            break;
        case DC_SIGCHAR_POINTER: {
            mPUSHs(sv_setref_pv(newSV(1), "Affix::Pointer", dcbArgPointer(args)));
            // mPUSHs(newSVpv((char *)ptr, 0));
        } break;
        case DC_SIGCHAR_STRING: {
            DCpointer ptr = dcbArgPointer(args);
            PUSHs(newSVpv((char *)ptr, 0));
        } break;
        case DC_SIGCHAR_BLESSED: {
            DCpointer ptr = dcbArgPointer(args);
            HV *blessed = MUTABLE_HV(SvRV(*av_fetch(cbx->args, i, 0)));
            SV **package = hv_fetchs(blessed, "package", 0);
            PUSHs(sv_setref_pv(newSV(1), SvPV_nolen(*package), ptr));
        } break;
        case DC_SIGCHAR_ENUM:
        case DC_SIGCHAR_ENUM_UINT: {
            PUSHs(enum2sv(*av_fetch(cbx->args, i, 0), dcbArgInt(args)));
        } break;
        case DC_SIGCHAR_ENUM_CHAR: {
            PUSHs(enum2sv(*av_fetch(cbx->args, i, 0), dcbArgChar(args)));
        } break;
        case DC_SIGCHAR_ANY: {
            DCpointer ptr = dcbArgPointer(args);
            SV *sv = newSV(0);
            if (ptr != NULL && SvOK(MUTABLE_SV(ptr))) {
                // DumpHex(ptr, sizeof(SV));
                // warn("SvOK");
                sv = MUTABLE_SV(ptr);
                // sv_dump(sv);
            }
            PUSHs(sv);
        } break;
        default:
            croak("Unhandled callback arg. Type: %c [%s]", cbx->sig[i], cbx->sig);
            break;
        }
    }
    PUTBACK;
    if (cbx->ret == DC_SIGCHAR_VOID) { call_sv(cbx->cv, G_VOID); }
    else {
        count = call_sv(cbx->cv, G_SCALAR);
        if (count != 1) croak("Big trouble: %d returned items", count);
        SPAGAIN;
        switch (cbx->ret) {
        case DC_SIGCHAR_VOID:
            break;
        case DC_SIGCHAR_BOOL:
            result->B = SvTRUEx(POPs);
            break;
        case DC_SIGCHAR_CHAR:
            result->c = POPu;
            break;
        case DC_SIGCHAR_UCHAR:
            result->C = POPu;
            break;
        case DC_SIGCHAR_SHORT:
            result->s = POPu;
            break;
        case DC_SIGCHAR_USHORT:
            result->S = POPi;
            break;
        case DC_SIGCHAR_INT:
            result->i = POPi;
            break;
        case DC_SIGCHAR_UINT:
            result->I = POPu;
            break;
        case DC_SIGCHAR_LONG:
            result->j = POPl;
            break;
        case DC_SIGCHAR_ULONG:
            result->J = POPul;
            break;
        case DC_SIGCHAR_LONGLONG:
            result->l = POPi;
            break;
        case DC_SIGCHAR_ULONGLONG:
            result->L = POPu;
            break;
        case DC_SIGCHAR_FLOAT:
            result->f = POPn;
            break;
        case DC_SIGCHAR_DOUBLE:
            result->d = POPn;
            break;
        case DC_SIGCHAR_POINTER: {
            SV *sv_ptr = POPs;
            if (SvOK(sv_ptr)) {
                if (sv_derived_from(sv_ptr, "Affix::Pointer")) {
                    IV tmp = SvIV((SV *)SvRV(sv_ptr));
                    result->p = INT2PTR(DCpointer, tmp);
                }
                else
                    croak("Returned value is not a Affix::Pointer or subclass");
            }
            else
                result->p = NULL; // ha.
        } break;
        case DC_SIGCHAR_STRING:
            result->Z = POPp;
            break;
        default:
            croak("Unhandled return from callback: %c", cbx->ret);
        }
        PUTBACK;
    }

    FREETMPS;
    LEAVE;

    return cbx->ret;
}

XS_INTERNAL(Types_wrapper) {
    dVAR;
    dXSARGS;
    dXSI32;
    char *package = (char *)XSANY.any_ptr;
    package = form("%s", package);
    SV *RETVAL;
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(newSVpv(package, 0));
        for (int i = 0; i < items; i++)
            mXPUSHs(newSVsv(ST(i)));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count != 1) croak("Big trouble\n");
        RETVAL = newSVsv(POPs);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    RETVAL = sv_2mortal(RETVAL);
    ST(0) = RETVAL;
    XSRETURN(1);
}

XS_INTERNAL(Types) {
    dVAR;
    dXSARGS;
    dXSI32;
    dMY_CXT;

    char *package = (char *)SvPV_nolen(ST(0));

    // warn("ix == %i %c", ix, ix);
    // PERL_UNUSED_VAR(ax); /* -Wall */
    // warn("Creating a new %s [ix == %c]", package, ix);

    HV *RETVAL_HV = newHV();
    //
    //  warn("ix == %c", ix);
    switch (ix) {
    case DC_SIGCHAR_ENUM:
    case DC_SIGCHAR_ENUM_UINT:
    case DC_SIGCHAR_ENUM_CHAR: {
        AV *vals = MUTABLE_AV(SvRV(ST(1)));
        AV *values = newAV_mortal();
        SV *current_value = newSViv(0);
        for (int i = 0; i < av_count(vals); ++i) {
            SV *name = newSV(0);
            SV **item = av_fetch(vals, i, 0);
            if (SvROK(*item)) {
                if (SvTYPE(SvRV(*item)) == SVt_PVAV) {
                    AV *cast = MUTABLE_AV(SvRV(*item));
                    if (av_count(cast) == 2) {
                        name = *av_fetch(cast, 0, 0);
                        current_value = *av_fetch(cast, 1, 0);
                        if (!SvIOK(current_value)) { // C-like enum math like: enum { a,
                                                     // b, c = a+b}
                            char *eval = NULL;
                            size_t pos = 0;
                            size_t size = 1024;
                            Newxz(eval, size, char);
                            for (int i = 0; i < av_count(values); i++) {
                                SV *e = *av_fetch(values, i, 0);
                                char *str = SvPV_nolen(e);
                                char *line;
                                if (SvIOK(e)) {
                                    int num = SvIV(e);
                                    line = form("sub %s(){%d}", str, num);
                                }
                                else {
                                    char *chr = SvPV_nolen(e);
                                    line = form("sub %s(){'%s'}", str, chr);
                                }
                                // size_t size = pos + strlen(line);
                                size = (strlen(eval) > (size + strlen(line))) ? size + strlen(line)
                                                                              : size;
                                Renewc(eval, size, char, char);
                                Copy(line, (DCpointer)(PTR2IV(eval) + pos), strlen(line) + 1, char);
                                pos += strlen(line);
                            }
                            current_value = eval_pv(form("package Affix::Enum::eval{no warnings "
                                                         "qw'redefine reserved';%s%s}",
                                                         eval, SvPV_nolen(current_value)),
                                                    1);
                            safefree(eval);
                        }
                    }
                }
                else { croak("Enum element must be a [key => value] pair"); }
            }
            else
                sv_setsv(name, *item);
            {
                SV *TARGET = newSV(1);
                { // Let's make enum values dualvars just 'cause; snagged from
                  // Scalar::Util
                    SV *num = newSVsv(current_value);
                    (void)SvUPGRADE(TARGET, SVt_PVNV);
                    sv_copypv(TARGET, name);
                    if (SvNOK(num) || SvPOK(num) || SvMAGICAL(num)) {
                        SvNV_set(TARGET, SvNV(num));
                        SvNOK_on(TARGET);
                    }
#ifdef SVf_IVisUV
                    else if (SvUOK(num)) {
                        SvUV_set(TARGET, SvUV(num));
                        SvIOK_on(TARGET);
                        SvIsUV_on(TARGET);
                    }
#endif
                    else {
                        SvIV_set(TARGET, SvIV(num));
                        SvIOK_on(TARGET);
                    }
                    if (PL_tainting && (SvTAINTED(num) || SvTAINTED(name))) SvTAINTED_on(TARGET);
                }
                av_push(values, newSVsv(TARGET));
            }
            sv_inc(current_value);
        }
        hv_stores(RETVAL_HV, "values", newRV_inc(MUTABLE_SV(values)));
    }; break;
    case DC_SIGCHAR_ARRAY: { // ArrayRef[Int, 5]
        AV *type_size = MUTABLE_AV(SvRV(ST(1)));
        SV *type;
        size_t array_length, array_sizeof = 0;
        bool packed = false;
        switch (av_count(type_size)) {
        case 2: {
            array_length = SvUV(*av_fetch(type_size, 1, 0));
            if (array_length < 1) croak("Given size %zd is not a positive integer", array_length);
            type = *av_fetch(type_size, 0, 0);
            if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                croak("Given type for '%s' is not a subclass of Affix::Type::Base",
                      SvPV_nolen(type));
            size_t offset = 0;
            size_t type_sizeof = _sizeof(aTHX_ type);
            for (int i = 0; i < array_length; ++i) {
                array_sizeof += type_sizeof;
                array_sizeof += packed ? 0
                                       : padding_needed_for(array_sizeof, ALIGNBYTES > type_sizeof
                                                                              ? type_sizeof
                                                                              : ALIGNBYTES);
                offset = array_sizeof;
            }
        } break;
        default:
            croak("Expected a single type and array length: "
                  "ArrayRef[Int, 5]");
        }

        hv_stores(RETVAL_HV, "sizeof", newSVuv(array_sizeof));
        hv_stores(RETVAL_HV, "size", newSVuv(array_length));
        hv_stores(RETVAL_HV, "name", newSV(0));
        hv_stores(RETVAL_HV, "packed", sv_2mortal(boolSV(packed)));
        hv_stores(RETVAL_HV, "type", newSVsv(type));
    } break;
    case DC_SIGCHAR_CODE: {
        AV *fields = newAV_mortal();
        SV *retval = sv_newmortal();

        size_t field_count;
        {
            if (items != 2) croak("CodeRef[ [args] => return]");

            AV *args = MUTABLE_AV(SvRV(ST(1)));
            if (av_count(args) != 2) croak("Expected a list of arguments and a return value");
            fields = MUTABLE_AV(SvRV(*av_fetch(args, 0, 0)));
            field_count = av_count(fields);

            for (int i = i; i < field_count; ++i) {
                SV **type_ref = av_fetch(fields, i, 0);
                if (!(sv_isobject(*type_ref) && sv_derived_from(*type_ref, "Affix::Type::Base")))
                    croak("Given type for CodeRef %d is not a subclass of "
                          "Affix::Type::Base",
                          i);
                av_push(fields, SvREFCNT_inc(((*type_ref))));
            }

            sv_setsv(retval, *av_fetch(args, 1, 0));
            if (!(sv_isobject(retval) && sv_derived_from(retval, "Affix::Type::Base")))
                croak("Given type for return value is not a subclass of "
                      "Affix::Type::Base");

            char signature[field_count];
            for (int i = 0; i < field_count; i++) {
                SV **type_ref = av_fetch(fields, i, 0);
                char *str = SvPVbytex_nolen(*type_ref);
                // av_push(cb->args, SvREFCNT_inc(*type_ref));
                switch (str[0]) {
                case DC_SIGCHAR_CODE:
                case DC_SIGCHAR_ARRAY:
                    signature[i] = DC_SIGCHAR_POINTER;
                    break;
                case DC_SIGCHAR_AGGREGATE:
                case DC_SIGCHAR_STRUCT:
                    signature[i] = DC_SIGCHAR_AGGREGATE;
                    break;
                default:
                    signature[i] = str[0];
                    break;
                }
            }
            hv_stores(RETVAL_HV, "args", SvREFCNT_inc(*av_fetch(args, 0, 0)));
            hv_stores(RETVAL_HV, "return", SvREFCNT_inc(retval));
            hv_stores(RETVAL_HV, "sig_len", newSViv(field_count));
            hv_stores(RETVAL_HV, "signature", newSVpv(signature, field_count));
        }
    } break;
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        if (items == 2) {
            bool packed = false; // TODO: handle packed structs correctly
            hv_stores(RETVAL_HV, "packed", boolSV(packed));
            AV *fields = newAV();
            AV *fields_in = MUTABLE_AV(SvRV(ST(1)));
            size_t field_count = av_count(fields_in);
            size_t size = 0;
            if (field_count && field_count % 2) croak("Expected an even sized list");
            for (int i = 0; i < field_count; i += 2) {
                // warn("here at %s line %d", __FILE__, __LINE__);
                AV *field = newAV();
                SV *key = newSVsv(*av_fetch(fields_in, i, 0));
                if (!SvPOK(key)) croak("Given name of '%s' is not a string", SvPV_nolen(key));
                SV *type = *av_fetch(fields_in, i + 1, 0);
                if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                    croak("Given type for '%s' is not a subclass of Affix::Type::Base",
                          SvPV_nolen(key));
                size_t __sizeof = _sizeof(aTHX_ type);
                if (ix == DC_SIGCHAR_STRUCT) {
                    size += packed ? 0
                                   : padding_needed_for(size, ALIGNBYTES > __sizeof ? __sizeof
                                                                                    : ALIGNBYTES);
                    size += __sizeof;
                    (void)hv_stores(MUTABLE_HV(SvRV(type)), "offset", newSVuv(size - __sizeof));
                }
                else {
                    if (size < __sizeof) size = __sizeof;
                    if (!packed && field_count > 1 && __sizeof > ALIGNBYTES)
                        size += padding_needed_for(__sizeof, ALIGNBYTES);
                    (void)hv_stores(MUTABLE_HV(SvRV(type)), "offset", newSVuv(0));
                }
                (void)hv_stores(MUTABLE_HV(SvRV(type)), "sizeof", newSVuv(__sizeof));
                av_push(field, SvREFCNT_inc(key));
                SV **value_ptr = av_fetch(fields_in, i + 1, 0);
                SV *value = *value_ptr;
                av_push(field, SvREFCNT_inc(value));
                SV *sv_field = (MUTABLE_SV(field));
                av_push(fields, newRV(sv_field));
            }

            if (ix == DC_SIGCHAR_STRUCT) {

                if (!packed && size > ALIGNBYTES * 2) size += padding_needed_for(size, ALIGNBYTES);
            }
            hv_stores(RETVAL_HV, "sizeof", newSVuv(size));
            hv_stores(RETVAL_HV, "fields", newRV(MUTABLE_SV(fields)));
        }
        else
            croak("%s[...] expected an even a list of elements",
                  ix == DC_SIGCHAR_STRUCT ? "Struct" : "Union");
    } break;
    case DC_SIGCHAR_POINTER: {
        AV *fields = MUTABLE_AV(SvRV(ST(1)));
        if (av_count(fields) == 1) {
            SV *inside;
            SV **type_ref = av_fetch(fields, 0, 0);
            SV *type = *type_ref;
            if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                croak("Pointer[...] expects a subclass of Affix::Type::Base");
            hv_stores(RETVAL_HV, "type", SvREFCNT_inc(type));
        }
        else
            croak("Pointer[...] expects a single type. e.g. Pointer[Int]");
    } break;
    case DC_SIGCHAR_BLESSED: {
        AV *packages_in = MUTABLE_AV(SvRV(ST(1)));
        if (av_count(packages_in) != 1) croak("InstanceOf[...] expects a single package name");
        SV **package_ptr = av_fetch(packages_in, 0, 0);
        if (is_valid_class_name(*package_ptr))
            hv_stores(RETVAL_HV, "package", newSVsv(*package_ptr));
        else
            croak("%s is not a known type", SvPVbytex_nolen(*package_ptr));
    } break;
    case DC_SIGCHAR_ANY: {
        break;
    } break;
    default:
        if (items > 1)
            croak("Too many arguments for subroutine '%s' (got %d; expected 0)", package, items);
        // warn("Unhandled...");
        break;
    }

    SV *self = newRV_inc(MUTABLE_SV(RETVAL_HV));
    ST(0) = sv_bless(self, gv_stashpv(package, GV_ADD));
    // SvREADONLY_on(self);

    XSRETURN(1);
    // PUTBACK;
    // return;
}

XS_INTERNAL(Types_sig) {
    dXSARGS;
    dXSI32;
    dXSTARG;
    if (PL_phase == PERL_PHASE_DESTRUCT) XSRETURN_IV(0);
    // warn("Types_sig %c/%d", ix, ix);
    XSRETURN_PV((char *)&ix);
}

XS_INTERNAL(Types_return_typedef) {
    dXSARGS;
    dXSI32;
    dXSTARG;
    ST(0) = sv_2mortal(newSVsv(XSANY.any_sv));
    XSRETURN(1);
}

XS_INTERNAL(Types_type) {
    dXSARGS;
    dXSI32;
    dXSTARG;

    // XSprePUSH;
    if (items != 1) croak("Expected 1 parameter; found %d", items);
    AV *args = MUTABLE_AV(SvRV(newSVsv(ST(0))));
    if (av_count(args) > 1) croak("Expected 1 parameter; found %zu", av_count(args));
    SV *type = av_shift(args);
    if (SvPOK(type)) {
        HV *type_registry = get_hv("Affix::Type::_reg", GV_ADD);
        const char *type_str = SvPV_nolen(type);
        if (!hv_exists_ent(type_registry, type, 0)) croak("Type named '%s' is undefined", type_str);
        type = MUTABLE_SV(SvRV(*hv_fetch(type_registry, type_str, strlen(type_str), 0)));
    }
    ST(0) = newSVsv(type);
    XSRETURN(1);
}

XS_INTERNAL(Affix_call) {
    dVAR;
    dXSARGS;
    dXSI32;
    dMY_CXT;

    Call *call = (Call *)XSANY.any_ptr;
    if (call->reset) dcReset(MY_CXT.cvm);
    bool pointers = false;

    /*warn("Calling at %s line %d", __FILE__, __LINE__);
    warn("%d items at %s line %d", items, __FILE__, __LINE__);
    warn("sig_len: %d at %s line %d", call->sig_len, __FILE__, __LINE__);
    warn("sig: %s at %s line %d", call->sig, __FILE__, __LINE__);*/

    if (call->sig_len != items) {
        if (call->sig_len < items && !call->reset) croak("Too many arguments");
        if (call->sig_len > items) croak("Not enough arguments");
    }
    // warn("ping at %s line %d", __FILE__, __LINE__);
    DCaggr *agg;
    switch (call->ret) {
    case DC_SIGCHAR_AGGREGATE:
    case DC_SIGCHAR_UNION:
    case DC_SIGCHAR_ARRAY:
    case DC_SIGCHAR_STRUCT: {
        // warn("here at %s line %d", __FILE__, __LINE__);
        agg = _aggregate(aTHX_ call->retval);
        dcBeginCallAggr(MY_CXT.cvm, agg);
    } break;
    default:
        break;
    }
    // dcArgPointer(pc, &o); // this ptr
    // dcCallAggr(pc, vtbl[VTBI_BASE+1], s, &returned);
    SV *value;
    SV *type;
    char _type;
    DCpointer pointer[call->sig_len];
    bool l_pointer[call->sig_len];
    for (size_t pos_arg = 0, pos_csig = 0, pos_psig = 0; pos_arg < items;
         ++pos_arg, ++pos_csig, ++pos_psig) {
        /*warn("Working on element %d of %d (type: %c, pos_arg: %d, pos_csig: %d,
           pos_psig: %d) at "
             "%s line %d",
             pos_arg + 1, call->sig_len,
             call->sig[pos_csig], pos_arg, pos_csig, pos_psig,
             __FILE__, __LINE__);*/
        value = ST(pos_arg);
        type = *av_fetch(call->args, pos_arg, 0); // Make broad assexumptions
        /*{
            char *tmp = SvPV_nolen(type);
            _type = tmp[0];
        }*/
        _type = call->sig[pos_csig];
        switch (_type) {
        case DC_SIGCHAR_VOID:
            break;
        case DC_SIGCHAR_BOOL:
            dcArgBool(MY_CXT.cvm, SvTRUE(value)); // Anything can be a bool
            break;
        case DC_SIGCHAR_CHAR:
            dcArgChar(MY_CXT.cvm, (char)(SvIOK(value) ? SvIV(value) : *SvPV_nolen(value)));
            break;
        case DC_SIGCHAR_UCHAR:
            dcArgChar(MY_CXT.cvm, (unsigned char)(SvIOK(value) ? SvUV(value) : *SvPV_nolen(value)));
            break;
        case DC_SIGCHAR_SHORT:
            dcArgShort(MY_CXT.cvm, (short)(SvIV(value)));
            break;
        case DC_SIGCHAR_USHORT:
            dcArgShort(MY_CXT.cvm, (unsigned short)(SvUV(value)));
            break;
        case DC_SIGCHAR_INT:
            dcArgInt(MY_CXT.cvm, (int)(SvIV(value)));
            break;
        case DC_SIGCHAR_UINT:
            dcArgInt(MY_CXT.cvm, (unsigned int)(SvUV(value)));
            break;
        case DC_SIGCHAR_LONG:
            dcArgLong(MY_CXT.cvm, (long)(SvIV(value)));
            break;
        case DC_SIGCHAR_ULONG:
            dcArgLong(MY_CXT.cvm, (unsigned long)(SvUV(value)));
            break;
        case DC_SIGCHAR_LONGLONG:
            dcArgLongLong(MY_CXT.cvm, (long long)(SvIV(value)));
            break;
        case DC_SIGCHAR_ULONGLONG:
            dcArgLongLong(MY_CXT.cvm, (unsigned long long)(SvUV(value)));
            break;
        case DC_SIGCHAR_FLOAT:
            dcArgFloat(MY_CXT.cvm, (float)SvNV(value));
            break;
        case DC_SIGCHAR_DOUBLE:
            dcArgDouble(MY_CXT.cvm, (double)SvNV(value));
            break;
        case DC_SIGCHAR_POINTER: {
            SV **subtype_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
            if (SvOK(value)) {
                if (sv_derived_from(value, "Dyn::Call::Pointer")) {
                    IV tmp = SvIV((SV *)SvRV(value));
                    pointer[pos_arg] = INT2PTR(DCpointer, tmp);
                    l_pointer[pos_arg] = false;
                    pointers = true;
                }
                else {
                    if (sv_isobject(SvRV(value))) croak("Unexpected pointer to blessed object");
                    SV *type = *subtype_ptr;
                    size_t size = _sizeof(aTHX_ type);
                    Newxz(pointer[pos_arg], size, char);
                    (void)sv2ptr(aTHX_ type, value, pointer[pos_arg], false, 0);
                    l_pointer[pos_arg] = true;
                    pointers = true;
                }
            }
            else if (SvREADONLY(value)) { // explicit undef
                pointer[pos_arg] = NULL;
                l_pointer[pos_arg] = false;
            }
            else { // treat as if it's an lvalue
                SV **subtype_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
                SV *type = *subtype_ptr;
                size_t size = _sizeof(aTHX_ type);
                Newxz(pointer[pos_arg], size, char);
                l_pointer[pos_arg] = true;
                pointers = true;
            }

            dcArgPointer(MY_CXT.cvm, pointer[pos_arg]);
        } break;
        case DC_SIGCHAR_BLESSED: { // Essentially the same as DC_SIGCHAR_POINTER
            SV **package_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "package", 0);
            DCpointer ptr;
            if (SvROK(value) &&
                sv_derived_from((value), (const char *)SvPVbytex_nolen(*package_ptr))) {
                IV tmp = SvIV((SV *)SvRV(value));
                ptr = INT2PTR(DCpointer, tmp);
            }
            else if (!SvOK(value)) // Passed us an undef
                ptr = NULL;
            else
                croak("Type of arg %d must be an instance or subclass of %s", pos_arg + 1,
                      SvPVbytex_nolen(*package_ptr));
            // DCpointer ptr = sv2ptr(aTHX_ field, MUTABLE_SV(value), false);
            dcArgPointer(MY_CXT.cvm, ptr);
            // pointers = true;
        } break;
        case DC_SIGCHAR_ANY: {
            if (!SvOK(value)) sv_set_undef(value);
            // sv_dump(value);
            //   croak("here");
            dcArgPointer(MY_CXT.cvm, SvREFCNT_inc(value));
        } break;
        case DC_SIGCHAR_STRING: {
            dcArgPointer(MY_CXT.cvm, !SvOK(value) ? NULL : SvPV_nolen(value));
        } break;
        case DC_SIGCHAR_CODE: {
            if (SvOK(value)) {
                DCCallback *cb = NULL;
                {
                    CoW *p = cow;
                    while (p != NULL) {
                        if (p->cb) {
                            Callback *_cb = (Callback *)dcbGetUserData(p->cb);
                            if (SvRV(_cb->cv) == SvRV(value)) {
                                cb = p->cb;
                                break;
                            }
                        }
                        p = p->next;
                    }
                }

                if (!cb) {
                    HV *field = MUTABLE_HV(SvRV(type)); // Make broad assumptions
                    SV **sig = hv_fetchs(field, "signature", 0);
                    SV **sig_len = hv_fetchs(field, "sig_len", 0);
                    SV **ret = hv_fetchs(field, "return", 0);
                    SV **args = hv_fetchs(field, "args", 0);

                    Callback *callback;
                    Newxz(callback, 1, Callback);

                    callback->args = MUTABLE_AV(SvRV(*args));
                    callback->sig = SvPV_nolen(*sig);
                    callback->sig_len = strlen(callback->sig);
                    callback->ret = (char)*SvPV_nolen(*ret);

                    /*CV *coderef;
                    STMT_START {
                        HV *st;
                        GV *gvp;
                        SV *const xsub_tmp_sv = ST(i);
                        SvGETMAGIC(xsub_tmp_sv);
                        coderef = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
                        if (!coderef) croak("Type of arg %d must be code ref", i + 1);
                    }
                    STMT_END;
                    if (callback->cv) SvREFCNT_dec(callback->cv);
                    callback->cv = SvREFCNT_inc(MUTABLE_SV(coderef));*/

                    callback->cv = SvREFCNT_inc(value);
                    storeTHX(callback->perl);

                    cb = dcbNewCallback(callback->sig, cbHandler, callback);
                    {
                        CoW *hold;
                        Newxz(hold, 1, CoW);
                        hold->cb = cb;
                        hold->next = cow;
                        cow = hold;
                    }
                }
                dcArgPointer(MY_CXT.cvm, cb);
            }
            else
                dcArgPointer(MY_CXT.cvm, NULL);
        } break;
        case DC_SIGCHAR_ARRAY: {
            if (!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVAV)
                croak("Type of arg %d must be an array ref", pos_arg + 1);
            AV *elements = MUTABLE_AV(SvRV(value));
            HV *hv_ptr = MUTABLE_HV(SvRV(type));
            SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
            SV **size_ptr = hv_fetchs(hv_ptr, "size", 0);
            SV **ptr_ptr = hv_fetchs(hv_ptr, "pointer", 0);
            size_t av_len;
            if (SvOK(*size_ptr)) {
                av_len = SvIV(*size_ptr);
                if (av_count(elements) != av_len)
                    croak("Expected an array of %lu elements; found %zd", av_len,
                          av_count(elements));
            }
            else
                av_len = av_count(elements);
            size_t size = _sizeof(aTHX_ * type_ptr);
            // warn("av_len * size = %d * %d = %d", av_len, size, av_len * size);
            DCpointer ptr = NULL;
            if (0) {
                if (ptr_ptr) {
                    // warn("Reuse!");
                    IV tmp = SvIV((SV *)SvRV(*ptr_ptr));
                    ptr = saferealloc(INT2PTR(DCpointer, tmp), av_len * size);
                }
            }
            if (ptr == NULL) {
                // warn("Pointer was NULL!");
                ptr = safemalloc(av_len * size);
            }
            if (0) {
                SV *RETVALSV = newSV(0); // sv_newmortal();
                sv_setref_pv(RETVALSV, "Affix::Pointer", ptr);
                hv_stores(hv_ptr, "pointer", RETVALSV);
            }
            DCaggr *ag = sv2ptr(aTHX_ type, value, ptr, false, 0);
            // DumpHex(ptr, size * av_len);
            dcArgAggr(MY_CXT.cvm, ag, ptr);
        } break;
        case DC_SIGCHAR_STRUCT: {
            if (!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVHV)
                croak("Type of arg %d must be a hash ref", pos_arg + 1);
            // DCaggr *agg = _aggregate(aTHX_ field);
            DCpointer ptr = safemalloc(_sizeof(aTHX_ type));
            DCaggr *agg = sv2ptr(aTHX_ type, value, ptr, false, 0);
            // DumpHex(ptr, _sizeof(aTHX_ field));
            dcArgAggr(MY_CXT.cvm, agg, ptr);
        } break;
        case DC_SIGCHAR_ENUM:
            dcArgInt(MY_CXT.cvm, (int)(SvIV(value)));
            break;
        case DC_SIGCHAR_ENUM_UINT:
            dcArgInt(MY_CXT.cvm, (unsigned int)SvUV(value));
            break;
        case DC_SIGCHAR_ENUM_CHAR:
            dcArgChar(MY_CXT.cvm, (char)(SvIOK(value) ? SvIV(value) : *SvPV_nolen(value)));
            break;
        case DC_SIGCHAR_CC_PREFIX: {
            --pos_arg;
            DCsigchar _mode = call->sig[++pos_csig];
            DCint mode = dcGetModeFromCCSigChar(_mode);
            dcMode(MY_CXT.cvm, mode);
            /*warn("csig: %s type: %c _mode: %c mode: %d at %s line %d", call->sig,
               _type, _mode, mode, __FILE__, __LINE__);*/
            switch (_mode) {
            case DC_SIGCHAR_CC_ELLIPSIS:
            case DC_SIGCHAR_CC_ELLIPSIS_VARARGS:
                break; // TODO: Should I allow for this to reset anyway?
            default:
                dcReset(MY_CXT.cvm);
                break;
            }
            break;
        }
        default:
            croak("--> Unfinished: [%c/%d]%s", call->sig[pos_csig], pos_arg, call->sig);
        }
    }
    // warn("Return type: %c at %s line %d", call->ret, __FILE__, __LINE__);
    SV *RETVAL;
    {
        switch (call->ret) {
        case DC_SIGCHAR_VOID:
            RETVAL = newSV(0);
            dcCallVoid(MY_CXT.cvm, call->fptr);
            break;
        case DC_SIGCHAR_BOOL:
            RETVAL = newSV(0);
            sv_setbool_mg(RETVAL, (bool)dcCallBool(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_CHAR:
            RETVAL = newSViv((char)dcCallChar(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_UCHAR:
            RETVAL = newSVuv((unsigned char)dcCallChar(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_SHORT:
            RETVAL = newSViv((short)dcCallShort(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_USHORT:
            RETVAL = newSVuv((unsigned short)dcCallShort(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_INT:
            RETVAL = newSViv((int)dcCallInt(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_UINT:
            RETVAL = newSVuv((unsigned int)dcCallInt(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_LONG:
            RETVAL = newSViv((long)dcCallLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_ULONG:
            RETVAL = newSVuv((unsigned long)dcCallLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_LONGLONG:
            RETVAL = newSViv((long long)dcCallLongLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_ULONGLONG:
            RETVAL = newSVuv((unsigned long long)dcCallLongLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_FLOAT:
            RETVAL = newSVnv((float)dcCallFloat(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_DOUBLE:
            RETVAL = newSVnv((double)dcCallDouble(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_POINTER: {
            if (1) {
                SV *RETVALSV;
                RETVALSV = newSV(1);
                sv_setref_pv(RETVALSV, "Affix::Pointer", dcCallPointer(MY_CXT.cvm, call->fptr));
                RETVAL = RETVALSV;
            }
            else {
                size_t si = _sizeof(aTHX_ call->retval);
                DCpointer ret_ptr = safemalloc(si);
                DCpointer out = dcCallAggr(MY_CXT.cvm, call->fptr, agg, ret_ptr);
                RETVAL = agg2sv(aTHX_ agg, SvRV(call->retval), out, si);
            }
        } break;
        case DC_SIGCHAR_STRING:
            RETVAL = newSVpv((char *)dcCallPointer(MY_CXT.cvm, call->fptr), 0);
            break;
        case DC_SIGCHAR_BLESSED: {
            // warn("here at %s line %d", __FILE__, __LINE__);

            DCpointer ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            // warn("here at %s line %d", __FILE__, __LINE__);

            SV **package = hv_fetchs(MUTABLE_HV(SvRV(call->retval)), "package", 0);
            // warn("here at %s line %d", __FILE__, __LINE__);

            RETVAL = newSV(1);
            // warn("here at %s line %d", __FILE__, __LINE__);

            sv_setref_pv(RETVAL, SvPVbytex_nolen(*package), ptr);
            // warn("here at %s line %d", __FILE__, __LINE__);

        } break;
        case DC_SIGCHAR_ANY: {
            DCpointer ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            if (ptr && SvOK((SV *)ptr))
                RETVAL = (SV *)ptr;
            else
                sv_set_undef(RETVAL);
        } break;
        case DC_SIGCHAR_AGGREGATE:
        case DC_SIGCHAR_STRUCT:
        case DC_SIGCHAR_UNION: {
            size_t si = _sizeof(aTHX_ call->retval);
            DCpointer ret_ptr = safemalloc(si);
            // warn("agg.size == %d at %s line %d", agg->size, __FILE__, __LINE__);
            // warn("agg.n_fields == %d at %s line %d", agg->n_fields, __FILE__,
            // __LINE__); DumpHex(agg, 16);
            DCpointer out = dcCallAggr(MY_CXT.cvm, call->fptr, agg, ret_ptr);
            RETVAL = agg2sv(aTHX_ agg, SvRV(call->retval), out, si);
        } break;
        case DC_SIGCHAR_ENUM:
        case DC_SIGCHAR_ENUM_UINT: {
            RETVAL = enum2sv(call->retval, (int)dcCallInt(MY_CXT.cvm, call->fptr));
        } break;
        case DC_SIGCHAR_ENUM_CHAR: {
            RETVAL = enum2sv(call->retval, (char)dcCallChar(MY_CXT.cvm, call->fptr));
        } break;
        default:
            croak("Unhandled return type: %c", call->ret);
        }

        if (pointers) {
            // warn("pointers! at %s line %d", __FILE__, __LINE__);
            for (int i = 0; i < call->sig_len; ++i) {
                switch (call->sig[i]) {
                case DC_SIGCHAR_POINTER: {
                    SV *package = *av_fetch(call->args, i, 0); // Make broad assumptions
                    if (SvOK(ST(i)) && sv_derived_from(ST(i), "Affix::Pointer")) {
                        IV tmp = SvIV((SV *)SvRV(ST(i)));
                        pointer[i] = INT2PTR(DCpointer, tmp);
                    }
                    else if (!SvREADONLY(value)) { // not explicit undef
                        HV *type_hv = MUTABLE_HV(SvRV(package));
                        // DumpHex(ptr, 16);
                        SV **type_ptr = hv_fetchs(type_hv, "type", 0);
                        SV *type = *type_ptr;
                        char *_type = SvPV_nolen(type);
                        switch (_type[0]) {
                        case DC_SIGCHAR_VOID:
                            // let it pass through as a Dyn::Call::Pointer
                            break;
                        case DC_SIGCHAR_AGGREGATE:
                        case DC_SIGCHAR_STRUCT:
                        case DC_SIGCHAR_ARRAY: {

                            // warn("aggregate! at %s line %d", __FILE__, __LINE__);
                            // sv_dump((type));
                            DCaggr *agg = _aggregate(aTHX_ type);
                            size_t si = _sizeof(aTHX_ type);
                            SvSetMagicSV(ST(i), agg2sv(aTHX_ agg, SvRV(type), pointer[i], si));
                        } break;
                        default: {
                            // warn("pointers! at %s line %d", __FILE__, __LINE__);
                            // sv_dump(SvRV(*type_ptr));

                            // DumpHex(pointer[i], 56);
                            SV *sv = ptr2sv(aTHX_ pointer[i], type);
                            // sv_dump(sv);
                            //  if (SvOK(ST(i))) {
                            if (!SvREADONLY(ST(i))) SvSetMagicSV(ST(i), sv);
                            // else ... guess they passed undef rather than an undef
                            // scalar
                        }
                        }
                    }
                } break;

                default:
                    break;
                }
                if (l_pointer[i] && pointer[i] != NULL) {
                    // safefree(pointer[i]);
                    pointer[i] = NULL;
                }
            }
        }

        if (call->ret == DC_SIGCHAR_VOID) XSRETURN_EMPTY;
        RETVAL = sv_2mortal(RETVAL);
        ST(0) = RETVAL;
        XSRETURN(1);
    }
}

XS_INTERNAL(Affix_DESTROY) {
    dVAR;
    dXSARGS;
    Call *call;
    CV *THIS;
    STMT_START {
        HV *st;
        GV *gvp;
        SV *const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        THIS = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        {
            CV *cv = THIS;
            call = (Call *)XSANY.any_ptr;
        }
    }
    STMT_END;
    if (call == NULL) XSRETURN_EMPTY;
    if (call->lib != NULL) dlFreeLibrary(call->lib);
    if (call->fptr != NULL) call->fptr = NULL;
    SvREFCNT_dec(call->args);
    SvREFCNT_dec(call->retval);
    if (call->sig != NULL) safefree(call->sig);
    if (call->perl_sig != NULL) safefree(call->perl_sig);
    safefree(call);
    call = NULL;
    if (XSANY.any_ptr != NULL) safefree(XSANY.any_ptr);
    XSANY.any_ptr = NULL;
    XSRETURN_EMPTY;
}

#define TYPE(NAME, SIGCHAR, SIGCHAR_C)                                                             \
    {                                                                                              \
        const char *package = form("Affix::Type::%s", #NAME);                                      \
        set_isa(package, "Affix::Type::Base");                                                     \
        cv = newXSproto_portable(form("Affix::%s", #NAME), Types_wrapper, file, ";$");             \
        Newx(XSANY.any_ptr, strlen(package) + 1, char);                                            \
        Copy(package, XSANY.any_ptr, strlen(package) + 1, char);                                   \
        cv = get_cv(form("%s::new", package), 0); /* Allow type constructors to be overridden */   \
        if (cv == NULL) {                                                                          \
            cv = newXSproto_portable(form("%s::new", package), Types /*_#NAME*/, file, "$");       \
            safefree(XSANY.any_ptr);                                                               \
            XSANY.any_i32 = (int)SIGCHAR;                                                          \
        }                                                                                          \
        export_function("Affix", #NAME, "types");                                                  \
        /*warn("Exporting %s to Affix q[:types]", NAME);*/                                         \
        /* Int->sig == 'i'; Struct[Int, Float]->sig == '{if}' */                                   \
        cv = newXSproto_portable(form("%s::sig", package), Types_sig, file, "$");                  \
        XSANY.any_i32 = (int)SIGCHAR;                                                              \
        /* embed an extra character inside a method call to get the 'real' C type*/                \
        cv = newXSproto_portable(form("%s::csig", package), Types_sig, file, "$");                 \
        XSANY.any_i32 = (int)SIGCHAR_C;                                                            \
        /* types objects can stringify to sigchars */                                              \
        cv = newXSproto_portable(form("%s::(\"\"", package), Types_sig, file, ";$");               \
        XSANY.any_i32 = (int)SIGCHAR;                                                              \
        /* The magic for overload gets a GV* via gv_fetchmeth as */                                \
        /* mentioned above, and looks in the SV* slot of it for */                                 \
        /* the "fallback" status. */                                                               \
        sv_setsv(get_sv(form("%s::()", package), TRUE), &PL_sv_yes);                               \
        /* Making a sub named "Affix::Call::Aggregate::()" allows the package */                   \
        /* to be findable via fetchmethod(), and causes */                                         \
        /* overload::Overloaded("Affix::Call::Aggregate") to return true. */                       \
        (void)newXSproto_portable(form("%s::()", package), Types_sig, file, ";$");                 \
    }
// clang-format off

MODULE = Affix PACKAGE = Affix

# Override default typemap

TYPEMAP: <<HERE
DCpointer   T_DCPOINTER

INPUT
T_DCPOINTER
    if (sv_derived_from($arg, \"Affix::Pointer\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type Affix::Pointer\");

OUTPUT
T_DCPOINTER
    sv_setref_pv($arg,\"Affix::Pointer\", $var);

HERE


BOOT:
  // clang-format on
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif
{
    MY_CXT_INIT;
    MY_CXT.cvm = dcNewCallVM(4096);
}
{
    (void)newXSproto_portable("Affix::Type", Types_type, file, "$");
    (void)newXSproto_portable("Affix::DESTROY", Affix_DESTROY, file, "$");

    CV *cv;
    TYPE(Void, DC_SIGCHAR_VOID, DC_SIGCHAR_VOID);
    TYPE(Bool, DC_SIGCHAR_BOOL, DC_SIGCHAR_BOOL);
    TYPE(Char, DC_SIGCHAR_CHAR, DC_SIGCHAR_CHAR);
    TYPE(UChar, DC_SIGCHAR_UCHAR, DC_SIGCHAR_UCHAR);
    TYPE(Short, DC_SIGCHAR_SHORT, DC_SIGCHAR_SHORT);
    TYPE(UShort, DC_SIGCHAR_USHORT, DC_SIGCHAR_USHORT);
    TYPE(Int, DC_SIGCHAR_INT, DC_SIGCHAR_INT);
    TYPE(UInt, DC_SIGCHAR_UINT, DC_SIGCHAR_UINT);
    TYPE(Long, DC_SIGCHAR_LONG, DC_SIGCHAR_LONG);
    TYPE(ULong, DC_SIGCHAR_ULONG, DC_SIGCHAR_ULONG);
    TYPE(LongLong, DC_SIGCHAR_LONGLONG, DC_SIGCHAR_LONGLONG);
    TYPE(ULongLong, DC_SIGCHAR_ULONGLONG, DC_SIGCHAR_ULONGLONG);
    TYPE(Float, DC_SIGCHAR_FLOAT, DC_SIGCHAR_FLOAT);
    TYPE(Double, DC_SIGCHAR_DOUBLE, DC_SIGCHAR_DOUBLE);
    TYPE(Pointer, DC_SIGCHAR_POINTER, DC_SIGCHAR_POINTER);
    TYPE(Str, DC_SIGCHAR_STRING, DC_SIGCHAR_STRING);
    TYPE(Aggregate, DC_SIGCHAR_AGGREGATE, DC_SIGCHAR_AGGREGATE);
    TYPE(Struct, DC_SIGCHAR_STRUCT, DC_SIGCHAR_AGGREGATE);
    TYPE(ArrayRef, DC_SIGCHAR_ARRAY, DC_SIGCHAR_AGGREGATE);
    TYPE(Union, DC_SIGCHAR_UNION, DC_SIGCHAR_AGGREGATE);
    TYPE(CodeRef, DC_SIGCHAR_CODE, DC_SIGCHAR_AGGREGATE);
    TYPE(InstanceOf, DC_SIGCHAR_BLESSED, DC_SIGCHAR_POINTER);
    TYPE(Any, DC_SIGCHAR_ANY, DC_SIGCHAR_POINTER);
    TYPE(SSize_t, DC_SIGCHAR_SSIZE_T, DC_SIGCHAR_SSIZE_T);
    TYPE(Size_t, DC_SIGCHAR_SIZE_T, DC_SIGCHAR_SIZE_T);

    TYPE(Enum, DC_SIGCHAR_ENUM, DC_SIGCHAR_INT);

    TYPE(IntEnum, DC_SIGCHAR_ENUM, DC_SIGCHAR_INT);
    set_isa("Affix::Type::IntEnum", "Affix::Type::Enum");

    TYPE(UIntEnum, DC_SIGCHAR_ENUM_UINT, DC_SIGCHAR_UINT);
    set_isa("Affix::Type::UIntEnum", "Affix::Type::Enum");

    TYPE(CharEnum, DC_SIGCHAR_ENUM_CHAR, DC_SIGCHAR_CHAR);
    set_isa("Affix::Type::CharEnum", "Affix::Type::Enum");

    TYPE(CC_DEFAULT, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_DEFAULT);
    TYPE(CC_THISCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL);
    TYPE(CC_ELLIPSIS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ELLIPSIS);
    TYPE(CC_ELLIPSIS_VARARGS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ELLIPSIS_VARARGS);
    TYPE(CC_CDECL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_CDECL);
    TYPE(CC_STDCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_STDCALL);
    TYPE(CC_FASTCALL_MS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_FASTCALL_MS);
    TYPE(CC_FASTCALL_GNU, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_FASTCALL_GNU);
    TYPE(CC_THISCALL_MS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL_MS);
    TYPE(CC_THISCALL_GNU, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL_GNU);
    TYPE(CC_ARM_ARM, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ARM_ARM);
    TYPE(CC_ARM_THUMB, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ARM_THUMB);
    TYPE(CC_SYSCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_SYSCALL);

    // Enum[]?
    export_function("Affix", "typedef", "types");
    export_function("Affix", "wrap", "default");
    export_function("Affix", "affix", "default");
    export_function("Affix", "MODIFY_CODE_ATTRIBUTES", "default");
    export_function("Affix", "AUTOLOAD", "default");
}
// clang-format off

DLLib *
load_lib(const char * lib_name)
CODE:
{
    // clang-format on
    // Use perl to get the actual path to the library
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(ST(0));
        PUTBACK;
        count = call_pv("Affix::locate_lib", G_SCALAR);
        SPAGAIN;
        if (count == 1) lib_name = SvPVx_nolen(POPs);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    RETVAL =
#if defined(_WIN32) || defined(_WIN64)
        dlLoadLibrary(lib_name);
#else
        (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
    if (RETVAL == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
        unsigned int err = GetLastError();
        croak("Failed to load %s: %d", lib_name, err);
#else
        char *reason = dlerror();
        croak("Failed to load %s: %s", lib_name, reason);
#endif
        XSRETURN_EMPTY;
    }
}
// clang-format off
OUTPUT:
    RETVAL

void
pin(SV *sv, lib, symbol, SV *type);
    const char * symbol
PREINIT:
	struct ufuncs uf;
PPCODE:
// clang-format on
{
    PERL_UNUSED_VAR(sv);
    DLLib *lib;
    if (!SvOK(ST(1)))
        lib = NULL;
    else if (SvROK(ST(1)) && sv_derived_from(ST(1), "Dyn::Load::Lib")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else {
        char *lib_name = (char *)SvPV_nolen(ST(1));
        // Use perl to get the actual path to the library
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(ST(1));
            PUTBACK;
            count = call_pv("Affix::locate_lib", G_SCALAR);
            SPAGAIN;
            if (count == 1) lib_name = SvPVx_nolen(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        lib =
#if defined(_WIN32) || defined(_WIN64)
            dlLoadLibrary(lib_name);
#else
            (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
        if (lib == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
            unsigned int err = GetLastError();
            croak("Failed to load %s: %d", lib_name, err);
#else
            char *reason = dlerror();
            croak("Failed to load %s: %s", lib_name, reason);
#endif
            XSRETURN_EMPTY;
        }
    }
    DCpointer ptr = dlFindSymbol(lib, symbol);
    if (ptr == NULL) { // TODO: throw a warning
        char *sOut;
        dlGetLibraryPath(lib, sOut, 1024);
        croak("Failed to locate symbol %s in %s", symbol, sOut);
        XSRETURN_EMPTY;
    }
    MAGIC *mg;
    mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &pin_vtbl, NULL, 0);
    {
        var_ptr *_ptr;
        Newx(_ptr, 1, var_ptr);
        _ptr->ptr = ptr;
        _ptr->type = newSVsv(type);
        mg->mg_ptr = (char *)_ptr;
    }
    // magic_dump(mg);
    XSRETURN_YES;
}
// clang-format off

SV *
affix(lib, symbol, args, ret, func_name = (ix == 1) ? NULL : symbol)
    char * symbol
    AV * args
    SV * ret
    const char * func_name
ALIAS:
    affix = 0
    wrap  = 1
PREINIT:
    dMY_CXT;
CODE:
// clang-format on
{
    Call *call;
    DLLib *lib;

    if (!SvOK(ST(0)))
        lib = NULL;
    else if (SvROK(ST(0)) && sv_derived_from(ST(0), "Dyn::Load::Lib")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else {
        char *lib_name = (char *)SvPV_nolen(ST(0));
        // Use perl to get the actual path to the library
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(ST(0));
            PUTBACK;
            count = call_pv("Affix::locate_lib", G_SCALAR);
            SPAGAIN;
            if (count == 1) lib_name = SvPVx_nolen(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        lib =
#if defined(_WIN32) || defined(_WIN64)
            dlLoadLibrary(lib_name);
#else
            (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
        if (lib == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
            unsigned int err = GetLastError();
            croak("Failed to load %s: %d", lib_name, err);
#else
            char *reason = dlerror();
            croak("Failed to load %s: %s", lib_name, reason);
#endif
            XSRETURN_EMPTY;
        }
    }
    Newx(call, 1, Call);

    call->fptr = dlFindSymbol(lib, symbol);
    size_t args_len = av_count(args);

    if (call->fptr == NULL) { // TODO: throw a warning
        safefree(call);
        char *sOut;
        dlGetLibraryPath(lib, sOut, 1024);
        croak("Failed to locate symbol %s in %s", symbol, sOut);
        XSRETURN_EMPTY;
    }

    call->lib = lib;
    call->reset = true;
    call->retval = SvREFCNT_inc(ret);
    Newxz(call->sig, args_len * 2, char);
    Newxz(call->perl_sig, args_len, char);

    char c_sig[args_len];
    call->args = newAV();
    size_t perl_sig_pos = 0;
    size_t c_sig_pos = 0;
    call->sig_len = 0;
    for (int i = 0; i < args_len; ++i) {
        SV **type_ref = av_fetch(args, i, 0);
        if (!(sv_isobject(*type_ref) && sv_derived_from(*type_ref, "Affix::Type::Base")))
            croak("Given type for arg %d is not a subclass of Affix::Type::Base", i);
        av_push(call->args, SvREFCNT_inc(*type_ref));
        char *str = SvPVbytex_nolen(*type_ref);
        call->sig[c_sig_pos++] = str[0];
        switch (str[0]) {
        case DC_SIGCHAR_CODE:
            call->perl_sig[perl_sig_pos] = '&';
            break;
        case DC_SIGCHAR_ARRAY:
            call->perl_sig[perl_sig_pos++] = '\\';
            call->perl_sig[perl_sig_pos] = '@';
            break;
        case DC_SIGCHAR_STRUCT:
            call->perl_sig[perl_sig_pos++] = '\\';
            call->perl_sig[perl_sig_pos] = '%'; // TODO: Get actual type
            break;
        case DC_SIGCHAR_CC_PREFIX: { // Don't add to perl sig or inc arg count
            char cc[1];
            {
                dSP;
                int count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 1);
                PUSHs(*type_ref);
                PUTBACK;
                count = call_method("csig", G_SCALAR);
                SPAGAIN;
                if (count == 1) Copy(POPp, cc, 1, char);
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            call->sig[c_sig_pos++] = cc[0];
            if (i == 0 &&
                !(cc[0] != DC_SIGCHAR_CC_ELLIPSIS || cc[0] != DC_SIGCHAR_CC_ELLIPSIS_VARARGS)) {
                call->reset = false;
            }
        }
            continue;
        default:
            call->perl_sig[perl_sig_pos] = '$';
            break;
        }
        ++call->sig_len;
        ++perl_sig_pos;
    }
    {
        char *str = SvPVbytex_nolen(ret);
        call->ret = str[0];
    }
    // if (call == NULL) croak("Failed to affix %s", symbol);
    /* Create a new XSUB instance at runtime and set it's XSANY.any_ptr to contain
     *the necessary user data. name can be NULL => fully anonymous sub!
     **/

    CV *cv;
    STMT_START {
        cv = newXSproto_portable(func_name, Affix_call, (char *)__FILE__, call->perl_sig);
        if (cv == NULL) croak("ARG! Something went really wrong while installing a new XSUB!");
        XSANY.any_ptr = (DCpointer)call;
    }
    STMT_END;
    RETVAL = sv_bless((func_name == NULL ? newRV_noinc(MUTABLE_SV(cv)) : newRV_inc(MUTABLE_SV(cv))),
                      gv_stashpv("Affix", GV_ADD));
}
// clang-format off
OUTPUT:
    RETVAL

void
typedef(char * name, SV * type)
CODE:
// clang-format on
{
    {
        CV *cv = newXSproto_portable(name, Types_return_typedef, __FILE__, "");
        XSANY.any_sv = SvREFCNT_inc(newSVsv(type));
    }

    if (sv_isobject(type)) {
        if (sv_derived_from(type, "Affix::Type::Enum")) {
            HV *href = MUTABLE_HV(SvRV(type));
            SV **values_ref = hv_fetch(href, "values", 6, 0);
            AV *values = MUTABLE_AV(SvRV(*values_ref));
            HV *_stash = gv_stashpv(name, TRUE);
            for (int i = 0; i < av_count(values); i++) {
                SV **value = av_fetch(MUTABLE_AV(values), i, 0);
                register_constant(name, SvPV_nolen(*value), *value);
            }
        }
    }
    else
        croak("Expected a subclass of Affix::Type::Base");
}
// clang-format off

void
CLONE(...)
CODE :
    MY_CXT_CLONE;

void
sv_dump(SV * sv)
CODE :
    sv_dump(sv);

DCpointer
sv2ptr( SV * data, SV * type)
CODE:
    size_t size = _sizeof(aTHX_ type);
    Newxz(RETVAL, size, char);
    sv2ptr(aTHX_ type, data, RETVAL, false, 0);
OUTPUT:
    RETVAL

SV *
ptr2sv(DCpointer ptr, SV * type)
CODE:
    RETVAL = ptr2sv(aTHX_ ptr, type);
OUTPUT:
    RETVAL

void
DumpHex(DCpointer ptr, size_t size)
CODE:
    DumpHex(ptr, size);

BOOT :
// clang-format on
{
    export_function("Affix", "sv2ptr", "utility");
    export_function("Affix", "ptr2sv", "utility");
    export_function("Affix", "DumpHex", "utility");
    export_function("Affix", "pin", "default");
    export_function("Affix", "cast", "default");
}
// clang-format off

MODULE = Affix PACKAGE = Affix::ArrayRef

void
DESTROY(HV * me)
CODE:
// clang-format on
{
    SV **ptr_ptr = hv_fetchs(me, "pointer", 0);
    if (!ptr_ptr) return;
    DCpointer ptr;
    IV tmp = SvIV((SV *)SvRV(*ptr_ptr));
    ptr = INT2PTR(DCpointer, tmp);
    if (ptr) safefree(ptr);
    ptr = NULL;
}
// clang-format off

MODULE = Affix PACKAGE = Affix

size_t
sizeof(SV * type)
CODE:
    RETVAL = _sizeof(aTHX_ type);
OUTPUT:
    RETVAL

size_t
offsetof(SV * type, char * field)
CODE:
  // clang-format on
  {
    if (sv_isobject(type) && (sv_derived_from(type, "Affix::Type::Struct"))) {
        HV *href = MUTABLE_HV(SvRV(type));
        SV **fields_ref = hv_fetch(href, "fields", 6, 0);
        AV *fields = MUTABLE_AV(SvRV(*fields_ref));
        size_t field_count = av_count(fields);
        for (size_t i = 0; i < field_count; ++i) {
            AV *av_field = MUTABLE_AV(SvRV(*av_fetch(fields, i, 0)));
            SV *sv_field = *av_fetch(av_field, 0, 0);
            char *this_field = SvPV_nolen(sv_field);
            if (!strcmp(this_field, field)) {
                RETVAL = _offsetof(aTHX_ * av_fetch(av_field, 1, 0));
                break;
            }
            if (i == field_count) croak("Given structure does not contain field named '%s'", field);
        }
    }
    else
        croak("Given type is not a structure");
}
    // clang-format off
OUTPUT:
    RETVAL

# c+p from Affix::Pointer

DCpointer
malloc(size_t size)
CODE:
// clang-format on
{
    RETVAL = safemalloc(size);
    if (RETVAL == NULL) XSRETURN_EMPTY;
}
// clang-format off
OUTPUT:
RETVAL

DCpointer
calloc(size_t num, size_t size)
CODE:
// clang-format off
    {RETVAL = safecalloc(num, size);
    if (RETVAL == NULL) XSRETURN_EMPTY;}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
realloc(IN_OUT DCpointer ptr, size_t size)
CODE:
    ptr = saferealloc(ptr, size);
OUTPUT:
    RETVAL

void
free(DCpointer ptr)
PPCODE:
// clang-format on
{
    if (ptr) {
        safefree(ptr);
        ptr = NULL;
    }
    sv_set_undef(ST(0));
} // Let Affix::Pointer::DESTROY take care of the rest
  // clang-format off

DCpointer
memchr(DCpointer ptr, char ch, size_t count)

int
memcmp(lhs, rhs, size_t count)
INIT:
    DCpointer lhs, rhs;
CODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else
        croak("ptr is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { rhs = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    RETVAL = memcmp(lhs, rhs, count);
}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
memset(DCpointer dest, char ch, size_t count)

void
memcpy(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    CopyD(src, dest, nitems, char);
}
// clang-format off

void
memmove(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    Move(src, dest, nitems, char);
}
// clang-format off

BOOT :
// clang-format on
{
    export_function("Affix", "offsetof", "default");
    export_function("Affix", "sizeof", "default");
    export_function("Affix", "malloc", "memory");
    export_function("Affix", "calloc", "memory");
    export_function("Affix", "realloc", "memory");
    export_function("Affix", "free", "memory");
    export_function("Affix", "memchr", "memory");
    export_function("Affix", "memcmp", "memory");
    export_function("Affix", "memset", "memory");
    export_function("Affix", "memcpy", "memory");
    export_function("Affix", "memmove", "memory");
    set_isa("Affix::Pointer", "Dyn::Call::Pointer");
}
// clang-format off

MODULE = Affix PACKAGE = Affix::Pointer

FALLBACK : TRUE

IV
plus(DCpointer ptr, IV other, IV swap)
OVERLOAD: +
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) + other;
// clang-format off
OUTPUT:
    RETVAL

IV
minus(DCpointer ptr, IV other, IV swap)
OVERLOAD: -
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) - other;
// clang-format off
OUTPUT:
    RETVAL

char *
as_string(DCpointer ptr, ...)
OVERLOAD: \"\"
CODE:
    // clang-format on
    RETVAL = (char *)ptr;
// clang-format off
OUTPUT:
    RETVAL

SV *
raw(ptr, size_t size, bool utf8 = false)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    RETVAL = newSVpvn_utf8((const char *)ptr, size, utf8 ? 1 : 0);
}
// clang-format off
OUTPUT:
    RETVAL

void
dump(ptr, size_t size)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
}
//clang-format off

BOOT:
// clang-format on
{
    HV *stash = gv_stashpv("Affix", 0);
    // Supported Calling Convention Modes
    newCONSTSUB(stash, "DC_CALL_C_DEFAULT", newSViv(DC_CALL_C_DEFAULT));
    newCONSTSUB(stash, "DC_CALL_C_ELLIPSIS", newSViv(DC_CALL_C_ELLIPSIS));
    newCONSTSUB(stash, "DC_CALL_C_ELLIPSIS_VARARGS", newSViv(DC_CALL_C_ELLIPSIS_VARARGS));
    newCONSTSUB(stash, "DC_CALL_C_X86_CDECL", newSViv(DC_CALL_C_X86_CDECL));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_STD", newSViv(DC_CALL_C_X86_WIN32_STD));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_FAST_MS", newSViv(DC_CALL_C_X86_WIN32_FAST_MS));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_FAST_GNU", newSViv(DC_CALL_C_X86_WIN32_FAST_GNU));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_THIS_MS", newSViv(DC_CALL_C_X86_WIN32_THIS_MS));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_THIS_GNU", newSViv(DC_CALL_C_X86_WIN32_THIS_GNU));
    newCONSTSUB(stash, "DC_CALL_C_X64_WIN64", newSViv(DC_CALL_C_X64_WIN64));
    newCONSTSUB(stash, "DC_CALL_C_X64_SYSV", newSViv(DC_CALL_C_X64_SYSV));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_DARWIN", newSViv(DC_CALL_C_PPC32_DARWIN));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_OSX", newSViv(DC_CALL_C_PPC32_OSX));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARM_EABI", newSViv(DC_CALL_C_ARM_ARM_EABI));
    newCONSTSUB(stash, "DC_CALL_C_ARM_THUMB_EABI", newSViv(DC_CALL_C_ARM_THUMB_EABI));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARMHF", newSViv(DC_CALL_C_ARM_ARMHF));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_EABI", newSViv(DC_CALL_C_MIPS32_EABI));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_PSPSDK", newSViv(DC_CALL_C_MIPS32_PSPSDK));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_SYSV", newSViv(DC_CALL_C_PPC32_SYSV));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_LINUX", newSViv(DC_CALL_C_PPC32_LINUX));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARM", newSViv(DC_CALL_C_ARM_ARM));
    newCONSTSUB(stash, "DC_CALL_C_ARM_THUMB", newSViv(DC_CALL_C_ARM_THUMB));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_O32", newSViv(DC_CALL_C_MIPS32_O32));
    newCONSTSUB(stash, "DC_CALL_C_MIPS64_N32", newSViv(DC_CALL_C_MIPS64_N32));
    newCONSTSUB(stash, "DC_CALL_C_MIPS64_N64", newSViv(DC_CALL_C_MIPS64_N64));
    newCONSTSUB(stash, "DC_CALL_C_X86_PLAN9", newSViv(DC_CALL_C_X86_PLAN9));
    newCONSTSUB(stash, "DC_CALL_C_SPARC32", newSViv(DC_CALL_C_SPARC32));
    newCONSTSUB(stash, "DC_CALL_C_SPARC64", newSViv(DC_CALL_C_SPARC64));
    newCONSTSUB(stash, "DC_CALL_C_ARM64", newSViv(DC_CALL_C_ARM64));
    newCONSTSUB(stash, "DC_CALL_C_PPC64", newSViv(DC_CALL_C_PPC64));
    newCONSTSUB(stash, "DC_CALL_C_PPC64_LINUX", newSViv(DC_CALL_C_PPC64_LINUX));
    newCONSTSUB(stash, "DC_CALL_SYS_DEFAULT", newSViv(DC_CALL_SYS_DEFAULT));
    newCONSTSUB(stash, "DC_CALL_SYS_X86_INT80H_LINUX", newSViv(DC_CALL_SYS_X86_INT80H_LINUX));
    newCONSTSUB(stash, "DC_CALL_SYS_X86_INT80H_BSD", newSViv(DC_CALL_SYS_X86_INT80H_BSD));
    newCONSTSUB(stash, "DC_CALL_SYS_PPC32", newSViv(DC_CALL_SYS_PPC32));
    newCONSTSUB(stash, "DC_CALL_SYS_PPC64", newSViv(DC_CALL_SYS_PPC64));

    // Signature characters
    newCONSTSUB(stash, "DC_SIGCHAR_VOID", newSVpv(form("%c", DC_SIGCHAR_VOID), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_BOOL", newSVpv(form("%c", DC_SIGCHAR_BOOL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CHAR", newSVpv(form("%c", DC_SIGCHAR_CHAR), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_UCHAR", newSVpv(form("%c", DC_SIGCHAR_UCHAR), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_SHORT", newSVpv(form("%c", DC_SIGCHAR_SHORT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_USHORT", newSVpv(form("%c", DC_SIGCHAR_USHORT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_INT", newSVpv(form("%c", DC_SIGCHAR_INT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_UINT", newSVpv(form("%c", DC_SIGCHAR_UINT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_LONG", newSVpv(form("%c", DC_SIGCHAR_LONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ULONG", newSVpv(form("%c", DC_SIGCHAR_ULONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_LONGLONG", newSVpv(form("%c", DC_SIGCHAR_LONGLONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ULONGLONG", newSVpv(form("%c", DC_SIGCHAR_ULONGLONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_FLOAT", newSVpv(form("%c", DC_SIGCHAR_FLOAT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_DOUBLE", newSVpv(form("%c", DC_SIGCHAR_DOUBLE), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_POINTER", newSVpv(form("%c", DC_SIGCHAR_POINTER), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_STRING",
                newSVpv(form("%c", DC_SIGCHAR_STRING),
                        1)); /* in theory same as 'p', but convenient to disambiguate */
    newCONSTSUB(stash, "DC_SIGCHAR_AGGREGATE", newSVpv(form("%c", DC_SIGCHAR_AGGREGATE), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ENDARG",
                newSVpv(form("%c", DC_SIGCHAR_ENDARG), 1)); /* also works for end struct */

    /* calling convention / mode signatures */
    newCONSTSUB(stash, "DC_SIGCHAR_CC_PREFIX", newSVpv(form("%c", DC_SIGCHAR_CC_PREFIX), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_DEFAULT", newSVpv(form("%c", DC_SIGCHAR_CC_DEFAULT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL", newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ELLIPSIS", newSVpv(form("%c", DC_SIGCHAR_CC_ELLIPSIS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ELLIPSIS_VARARGS",
                newSVpv(form("%c", DC_SIGCHAR_CC_ELLIPSIS_VARARGS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_CDECL", newSVpv(form("%c", DC_SIGCHAR_CC_CDECL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_STDCALL", newSVpv(form("%c", DC_SIGCHAR_CC_STDCALL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_FASTCALL_MS",
                newSVpv(form("%c", DC_SIGCHAR_CC_FASTCALL_MS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_FASTCALL_GNU",
                newSVpv(form("%c", DC_SIGCHAR_CC_FASTCALL_GNU), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL_MS",
                newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL_MS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL_GNU",
                newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL_GNU), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ARM_ARM", newSVpv(form("%c", DC_SIGCHAR_CC_ARM_ARM), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ARM_THUMB", newSVpv(form("%c", DC_SIGCHAR_CC_ARM_THUMB), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_SYSCALL", newSVpv(form("%c", DC_SIGCHAR_CC_SYSCALL), 1));

    // Error codes
    newCONSTSUB(stash, "DC_ERROR_NONE", newSViv(DC_ERROR_NONE));
    newCONSTSUB(stash, "DC_ERROR_UNSUPPORTED_MODE", newSViv(DC_ERROR_UNSUPPORTED_MODE));

    export_function("Affix", "DC_CALL_C_DEFAULT", "vars");
    export_function("Affix", "DC_CALL_C_ELLIPSIS", "vars");
    export_function("Affix", "DC_CALL_C_ELLIPSIS_VARARGS", "vars");
    export_function("Affix", "DC_CALL_C_X86_CDECL", "vars");
    export_function("Affix", "DC_CALL_C_X86_WIN32_STD", "vars");
    export_function("Affix", "DC_CALL_C_X86_WIN32_FAST_MS", "vars");
    export_function("Affix", "DC_CALL_C_X86_WIN32_FAST_GNU", "vars");
    export_function("Affix", "DC_CALL_C_X86_WIN32_THIS_MS", "vars");
    export_function("Affix", "DC_CALL_C_X86_WIN32_THIS_GNU", "vars");
    export_function("Affix", "DC_CALL_C_X64_WIN64", "vars");
    export_function("Affix", "DC_CALL_C_X64_SYSV", "vars");
    export_function("Affix", "DC_CALL_C_PPC32_DARWIN", "vars");
    export_function("Affix", "DC_CALL_C_PPC32_OSX", "vars");
    export_function("Affix", "DC_CALL_C_ARM_ARM_EABI", "vars");
    export_function("Affix", "DC_CALL_C_ARM_THUMB_EABI", "vars");
    export_function("Affix", "DC_CALL_C_ARM_ARMHF", "vars");
    export_function("Affix", "DC_CALL_C_MIPS32_EABI", "vars");
    export_function("Affix", "DC_CALL_C_MIPS32_PSPSDK", "vars");
    export_function("Affix", "DC_CALL_C_PPC32_SYSV", "vars");
    export_function("Affix", "DC_CALL_C_PPC32_LINUX", "vars");
    export_function("Affix", "DC_CALL_C_ARM_ARM", "vars");
    export_function("Affix", "DC_CALL_C_ARM_THUMB", "vars");
    export_function("Affix", "DC_CALL_C_MIPS32_O32", "vars");
    export_function("Affix", "DC_CALL_C_MIPS64_N32", "vars");
    export_function("Affix", "DC_CALL_C_MIPS64_N64", "vars");
    export_function("Affix", "DC_CALL_C_X86_PLAN9", "vars");
    export_function("Affix", "DC_CALL_C_SPARC32", "vars");
    export_function("Affix", "DC_CALL_C_SPARC64", "vars");
    export_function("Affix", "DC_CALL_C_ARM64", "vars");
    export_function("Affix", "DC_CALL_C_PPC64", "vars");
    export_function("Affix", "DC_CALL_C_PPC64_LINUX", "vars");
    export_function("Affix", "DC_CALL_SYS_DEFAULT", "vars");
    export_function("Affix", "DC_CALL_SYS_X86_INT80H_LINUX", "vars");
    export_function("Affix", "DC_CALL_SYS_X86_INT80H_BSD", "vars");
    export_function("Affix", "DC_CALL_SYS_PPC32", "vars");
    export_function("Affix", "DC_CALL_SYS_PPC64", "vars");

    export_function("Affix", "DC_ERROR_NONE", "vars");
    export_function("Affix", "DC_ERROR_UNSUPPORTED_MODE", "vars");

    export_function("Affix", "DC_SIGCHAR_VOID", "sigchar");
    export_function("Affix", "DC_SIGCHAR_BOOL", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CHAR", "sigchar");
    export_function("Affix", "DC_SIGCHAR_UCHAR", "sigchar");
    export_function("Affix", "DC_SIGCHAR_SHORT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_USHORT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_INT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_UINT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_LONG", "sigchar");
    export_function("Affix", "DC_SIGCHAR_ULONG", "sigchar");
    export_function("Affix", "DC_SIGCHAR_LONGLONG", "sigchar");
    export_function("Affix", "DC_SIGCHAR_ULONGLONG", "sigchar");
    export_function("Affix", "DC_SIGCHAR_FLOAT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_DOUBLE", "sigchar");
    export_function("Affix", "DC_SIGCHAR_POINTER", "sigchar");
    export_function("Affix", "DC_SIGCHAR_STRING", "sigchar");
    export_function("Affix", "DC_SIGCHAR_STRUCT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_ENDARG", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_PREFIX", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_DEFAULT", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_ELLIPSIS", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_ELLIPSIS_VARARGS", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_CDECL", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_STDCALL", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_THISCALL", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_FASTCALL_MS", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_FASTCALL_GNU", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_THISCALL_MS", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_THISCALL_GNU", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_ARM_ARM", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_ARM_THUMB", "sigchar");
    export_function("Affix", "DC_SIGCHAR_CC_SYSCALL", "sigchar");
    export_function("Affix", "DEFAULT_ALIGNMENT", "vars");

    newCONSTSUB(stash, "ALIGNBYTES", newSViv(ALIGNBYTES));
}
