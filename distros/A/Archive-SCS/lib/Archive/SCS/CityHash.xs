#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <city.cc>

MODULE = Archive::SCS::CityHash  PACKAGE = Archive::SCS::CityHash

SV *
cityhash64_(sv)
    SV * sv
  PROTOTYPE: $
  CODE:
    STRLEN len;
    const char *buf = SvPVbyte(sv, len);
    uint64 cityhash_int = CityHash64(buf, len);
    RETVAL = newSVuv((UV) cityhash_int);
  OUTPUT:
    RETVAL
