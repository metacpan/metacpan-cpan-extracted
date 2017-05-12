#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <dlfcn.h>
#include "cryptoki/cryptoki.h"
#include "const-c.inc"


MODULE = Crypt::Cryptoki::Constant							PACKAGE = Crypt::Cryptoki::Constant		

INCLUDE: const-xs.inc
