#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#define MP_SOURCE 1
#include "msgpuck.h"

const char *
_msgunpuck(const char *p, const char *pe, SV **res, int utf)
{
    switch(mp_typeof(*p)) {
        case MP_NIL:
            mp_decode_nil(&p);
            *res = newSV(0);
            break;

        case MP_BOOL: {
            HV *stash;
            if (mp_decode_bool(&p)) {
                stash = gv_stashpvn(
                    "DR::Msgpuck::True",
                    sizeof("DR::Msgpuck::True"),
                    GV_ADD|GV_NOINIT
                );
                *res = newRV_noinc(newSViv(1));
                sv_bless(*res, stash);
            } else {
                stash = gv_stashpvn(
                    "DR::Msgpuck::False",
                    sizeof("DR::Msgpuck::False"),
                    GV_ADD|GV_NOINIT
                );
                *res = newRV_noinc(newSViv(0));
                sv_bless(*res, stash);
            }
            break;
        }

        case MP_UINT:
            *res = newSViv( mp_decode_uint(&p) );
            break;

        case MP_INT:
            *res = newSViv( mp_decode_int(&p) );
            break;

        case MP_FLOAT:
            *res = newSVnv( mp_decode_float(&p) );
            break;

        case MP_DOUBLE:
            *res = newSVnv( mp_decode_double(&p) );
            break;

        case MP_STR: {
            const char *s;
            uint32_t len;
            s = mp_decode_str(&p, &len);
            if (p > pe)
                goto UNEXPECTED_EOF;
            *res = newSVpvn_flags(s, len, utf ? SVf_UTF8 : 0);
            break;
        }

        case MP_ARRAY: {
            uint32_t l, i;
            l = mp_decode_array(&p);
            AV *a = newAV();
            sv_2mortal((SV *)a);
            for (i = 0; i < l; i++) {
                SV *item = 0;
                if (p >= pe)
                    goto UNEXPECTED_EOF;
                p = _msgunpuck(p, pe, &item, utf);
                av_push(a, item);
            }
            *res = newRV((SV *)a);
            break;
        }
        case MP_MAP: {
            uint32_t l, i;
            l = mp_decode_map(&p);
            HV * h = newHV();
            sv_2mortal((SV *)h);
            for (i = 0; i < l; i++) {
                SV *k = 0;
                SV *v = 0;
                if (p >= pe)
                    goto UNEXPECTED_EOF;
                p = _msgunpuck(p, pe, &k, utf);
                sv_2mortal(k);
                if (p >= pe)
                    goto UNEXPECTED_EOF;
                p = _msgunpuck(p, pe, &v, utf);
                hv_store_ent(h, k, v, 0);
            }
            *res = newRV((SV *)h);
            break;
        }

        case MP_EXT:
            croak("Msgpack extencions don't provided yet");
        default:
            croak("Unexpected symbol 0x%02x", 0xFF & (int)(*p));
    }
    return p;
    UNEXPECTED_EOF:
            croak("Unexpected EOF msgunpack str");
}

void
_msgpuck(SV *o, SV *out)
{
    STRLEN len = sv_len(out);
    STRLEN size, olen;
    char *p;


    // null
    if (!SvOK(o)) {
        size = mp_sizeof_nil();
        p = SvGROW(out, len + size);
        SvCUR_set(out, len + size);
        mp_encode_nil(p + len);
        return;
    }

    if (SvROK(o)) {
        o = SvRV(o);
        if (SvOBJECT(o)) {
            SvGETMAGIC(o);
            HV *stash = SvSTASH(o);
            GV *mtd = gv_fetchmethod_autoload(stash, "TO_MSGPACK", 0);
            if (!mtd)
                croak("Object has no method 'msgpack'");
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs (sv_bless (sv_2mortal (newRV_inc(o)), stash));
            PUTBACK;
            call_sv((SV *)GvCV(mtd), G_SCALAR);
            SPAGAIN;

            SV *pkt = POPs;

            if (!SvOK(pkt))
                croak("O->msgp[ua]ck returned undef");

            const char *s = SvPV(pkt, size);

            p = SvGROW(out, len + size);
            SvCUR_set(out, len + size);
            memcpy(p + len, s, size);

            PUTBACK;
            FREETMPS;
            LEAVE;

            return;
        }

        switch(SvTYPE(o)) {
            case SVt_PVAV: {
                AV *a = (AV *)o;
                size_t asize = av_len(a) + 1;
                size = mp_sizeof_array(asize);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_array(p + len, asize);

		int i;
                for (i = 0; i < asize; i++) {
                    SV **item = av_fetch(a, i, 0);
                    _msgpuck(*item, out);
                }
                break;
            }
            case SVt_PVHV: {
                HV *h = (HV *)o;
                size_t hsize = hv_iterinit(h);
                size = mp_sizeof_map(hsize);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_map(p + len, hsize);

                for (;;) {
                    HE * iter = hv_iternext(h);
                    if (!iter)
                        break;

                    SV *k = hv_iterkeysv(iter);
                    SV *v = HeVAL(iter);
                    _msgpuck(k, out);
                    _msgpuck(v, out);
                }

                break;
            }

            default:
                croak("Can't serialize refs");
        }
        return;
    }


    switch(SvTYPE(o)) {
        case SVt_PV:
        case SVt_PVIV:
        case SVt_PVNV:
        case SVt_PVMG:
        case SVt_REGEXP:
            if (!looks_like_number(o)) {
                SvPV(o, olen);
                size = mp_sizeof_str(olen);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_str(p + len, sv_pv(o), olen);
                return;
            }
        case SVt_NV: {
            NV v = SvNV(o);
            IV iv = (IV)v;
            if (v != iv) {
                size = mp_sizeof_double(v);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_double(p + len, v);
                return;
            }
        }
        case SVt_IV: {
            IV v = SvIV(o);
            if (v >= 0) {
                size = mp_sizeof_uint(v);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_uint(p + len, v);
            } else {
                size = mp_sizeof_int(v);
                p = SvGROW(out, len + size);
                SvCUR_set(out, len + size);
                mp_encode_int(p + len, v);
            }
            return;
        }
        default:
            croak("Internal msgpack error %d", SvTYPE(o));
    }
}


MODULE = DR::Msgpuck		PACKAGE = DR::Msgpuck


SV *
msgpack(o)
    SV *o

    INIT:
        RETVAL = newSVpv("", 0);
    CODE:
        _msgpuck(o, RETVAL);
    OUTPUT:
        RETVAL

SV *
msgunpack(str)
    SV *str

    INIT:
        size_t size;
        const char *ptr;

    CODE:
        if (!SvOK(str)) {
            croak("Cant unpack undefined value");
        }
        ptr = SvPV(str, size);
        _msgunpuck(ptr, ptr + size, &RETVAL, 0);
    OUTPUT:
        RETVAL

SV *
msgunpack_utf8(str)
    SV *str

    INIT:
        size_t size;
        const char *ptr;

    CODE:
        if (!SvOK(str)) {
            croak("Cant unpack undefined value");
        }
        ptr = SvPV(str, size);
        _msgunpuck(ptr, ptr + size, &RETVAL, 1);
    OUTPUT:
        RETVAL

size_t msgunpack_check(str)
        SV *str
        PROTOTYPE: $
        CODE:
            int res;
            size_t len;
            if (SvOK(str)) {
                const char *p = SvPV(str, len);
                if (len > 0) {
                    const char *pe = p + len;
                    const char *begin = p;
                    if (mp_check(&p, pe) == 0) {
                        RETVAL = p - begin;
                    } else {
                        RETVAL = 0;
                    }
                } else {
                    RETVAL = 0;
                }
            } else {
                RETVAL = 0;
            }
        OUTPUT:
            RETVAL

