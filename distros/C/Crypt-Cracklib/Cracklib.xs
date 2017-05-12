#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <crack.h>

MODULE = Crypt::Cracklib PACKAGE = Crypt::Cracklib

const char*
_FascistCheck(password, path)
  char *password
  char *path
  PROTOTYPE: $$
  CODE:

  RETVAL = FascistCheck((const char*)password, (const char*)path);

  OUTPUT:
  RETVAL
