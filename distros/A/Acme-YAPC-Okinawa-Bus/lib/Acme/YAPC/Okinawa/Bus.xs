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

MODULE = Acme::YAPC::Okinawa::Bus    PACKAGE = Acme::YAPC::Okinawa::Bus

PROTOTYPES: DISABLE

void
time()
CODE:
{
    ST(0) = newSVpvs_flags("朝7時45分", SVs_TEMP);
}

void
place()
CODE:
{
    ST(0) = newSVpvs_flags("県庁前", SVs_TEMP);
}
