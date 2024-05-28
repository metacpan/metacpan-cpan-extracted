#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <city.cc>

#if BYTEORDER == 0x12345678
#  define to_network_byteorder(x) ((U64)( \
     (((U64)(x) & UINT64_C(0x00000000000000ff)) << 56) | \
     (((U64)(x) & UINT64_C(0x000000000000ff00)) << 40) | \
     (((U64)(x) & UINT64_C(0x0000000000ff0000)) << 24) | \
     (((U64)(x) & UINT64_C(0x00000000ff000000)) <<  8) | \
     (((U64)(x) & UINT64_C(0x000000ff00000000)) >>  8) | \
     (((U64)(x) & UINT64_C(0x0000ff0000000000)) >> 24) | \
     (((U64)(x) & UINT64_C(0x00ff000000000000)) >> 40) | \
     (((U64)(x) & UINT64_C(0xff00000000000000)) >> 56) ))
#else
#  define to_network_byteorder(x) ((U64)(x))
#endif

MODULE = Archive::SCS::CityHash  PACKAGE = Archive::SCS::CityHash

SV *
cityhash64_(sv)
    SV * sv
  PROTOTYPE: $
  CODE:
    STRLEN len;
    const char *buf = SvPVbyte(sv, len);
    uint64 cityhash_int = CityHash64(buf, len);
    U64 cityhash = to_network_byteorder(cityhash_int);
    RETVAL = newSVpvn((const char * const) &cityhash, U64SIZE);
  OUTPUT:
    RETVAL
