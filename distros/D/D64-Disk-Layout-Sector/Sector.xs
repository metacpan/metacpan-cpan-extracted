#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = D64::Disk::Layout::Sector  PACKAGE = D64::Disk::Layout::Sector
PROTOTYPES: ENABLE

# my $is_int = _is_int($var);

SV*
_is_int(var)
        SV *var
    CODE:
        if (SvIOKp(var))
            RETVAL = newSViv(1);
        else
            RETVAL = newSViv(0);
    OUTPUT:
        RETVAL

# my $is_str = _is_str($var);

SV*
_is_str(var)
        SV *var
    CODE:
        if (SvPOKp(var))
            RETVAL = newSViv(1);
        else
            RETVAL = newSViv(0);
    OUTPUT:
        RETVAL
