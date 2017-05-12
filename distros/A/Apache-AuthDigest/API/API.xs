#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mod_perl.h"

MODULE = Apache::AuthDigest::API         PACKAGE = Apache::AuthDigest::API

PROTOTYPES: ENABLE

void
note_digest_auth_failure(r)
  Apache r

  CODE:
    ap_note_digest_auth_failure(r);
