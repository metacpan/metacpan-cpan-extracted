
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

/* fixme, this is a hack: */
#include "HipRecord.cc"

MODULE = Astro::Hipparcos		PACKAGE = Astro::Hipparcos		

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp HipRecord.xsp

