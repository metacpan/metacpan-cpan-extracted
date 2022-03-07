#ifndef EASYXS_INIT
#define EASYXS_INIT 1

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"

/* Implement perl5 415da10787d8fa51 for older perls (part 1): */
#define STMT_START  do
#define STMT_END    while (0)

#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Implement perl5 415da10787d8fa51 for older perls (part 2): */
#undef STMT_START
#undef STMT_END
#define STMT_START  do
#define STMT_END    while (0)

#endif
