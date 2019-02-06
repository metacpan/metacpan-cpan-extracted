#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

MODULE = CPP::geos                PACKAGE = CPP::geos
PROTOTYPES: DISABLE

BOOT {
    1;
}
