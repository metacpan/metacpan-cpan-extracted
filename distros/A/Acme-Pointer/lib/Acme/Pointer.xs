#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#define CODE   "CODE"
#define HASH   "HASH"
#define ARRAY  "ARRAY"
#define SCALAR "SCALAR"

#define IsCodeRef(l, str)   (l > 4 && strnNE(str, CODE,   4) == 0 && str[4] == '(' && str[l - 1] == ')')
#define IsHashRef(l, str)   (l > 4 && strnNE(str, HASH,   4) == 0 && str[4] == '(' && str[l - 1] == ')')
#define IsArrayRef(l, str)  (l > 5 && strnNE(str, ARRAY,  5) == 0 && str[5] == '(' && str[l - 1] == ')')
#define IsScalarRef(l, str) (l > 6 && strnNE(str, SCALAR, 6) == 0 && str[6] == '(' && str[l - 1] == ')')

static SV *
_pointer(pTHX_ const char *addr)
{
    SV *p = (SV *)strtoul(addr, NULL, 0);
    if (SvTYPE(p) > 0) {
        return newRV_inc(p);
    }
    return &PL_sv_undef;
}

static SV *
get_address(pTHX_ int idx, int len, const char *ref)
{
    int i = idx;
    while (ref[i++] != ')');
    const char *addr;
    int l = i - (idx + 2);
    Newxz(addr, l, char);  /* same as calloc */
    Move(ref + idx + 1, addr, l, char); /* same as memmove */
    return _pointer(aTHX_ addr);
}

MODULE = Acme::Pointer    PACKAGE = Acme::Pointer

PROTOTYPES: ENABLE

SV *
deref(ref_str)
    SV *ref_str
CODE:
{
    STRLEN len;
    const char *ref = SvPV(ref_str, len);
    if (IsCodeRef(len, ref) || IsHashRef(len, ref)) {
        RETVAL = get_address(aTHX_ 4, len, ref);
    } else if (IsArrayRef(len, ref)) {
        RETVAL = get_address(aTHX_ 5, len, ref);
    } else if (IsScalarRef(len, ref)) {
        RETVAL = get_address(aTHX_ 6, len, ref);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV *
pointer(addr_str)
    SV *addr_str
CODE:
{
    STRLEN len;
    const char *addr = SvPV(addr_str, len);
    if (len > 1 && addr[0] == '0' && addr[1] == 'x') {
        RETVAL = _pointer(aTHX_ addr);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL
