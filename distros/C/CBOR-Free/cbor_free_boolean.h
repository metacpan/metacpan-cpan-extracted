#ifndef CBOR_FREE_BOOLEAN
#define CBOR_FREE_BOOLEAN

#include "easyxs/init.h"

#define LOAD_BOOLEAN_CLASS   "Types::Serialiser"
#define BOOLEAN_CLASS   "Types::Serialiser::Boolean"

#include "cbor_free_common.h"

HV *cbf_get_boolean_stash();

SV *cbf_get_false();

SV *cbf_get_true();

#endif
