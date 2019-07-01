#define PERL_NO_GET_CONTEXT

#ifndef CBOR_FREE_BOOLEAN
#define CBOR_FREE_BOOLEAN

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define LOAD_BOOLEAN_CLASS   "Types::Serialiser"
#define BOOLEAN_CLASS   "Types::Serialiser::Boolean"

#include "cbor_free_common.h"

HV *cbf_get_boolean_stash();

SV *cbf_get_false();

SV *cbf_get_true();

#endif
