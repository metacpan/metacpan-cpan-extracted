#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = D64::Disk::Layout::Dir  PACKAGE = D64::Disk::Layout::Dir
PROTOTYPES: ENABLE

# my $var_iok = _set_iok($var);

SV*
_set_iok(var)
        SV *var
    CODE:
        if (SvIOKp(var) || SvNOKp(var)) {
            SvIOK_on(var);
            if (SvNOK(var))
                sv_setiv(var, (IV) SvNV(var));
            RETVAL = newSViv(SvIV(var));
        }
        else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

# my $int = _magic_to_int($magic);

SV*
_magic_to_int(magic)
        SV *magic
    CODE:
        if (SvIOKp(magic))
            RETVAL = newSViv(SvIV(magic));
        else
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

# my $is_numeric = _is_numeric($var);

SV*
_is_numeric(var)
        SV *var
    CODE:
        if (SvIOKp(var) || SvNOKp(var))
            RETVAL = newSViv(1);
        else
            RETVAL = newSViv(0);
    OUTPUT:
        RETVAL
