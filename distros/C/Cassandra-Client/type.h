#define PERL_NO_GET_CONTEXT
#include "perl.h"

void cc_type_destroy(pTHX_ struct cc_type *type);
int unpack_type_nocroak(pTHX_ char *input, STRLEN len, STRLEN *pos, struct cc_type *output);
void unpack_type(pTHX_ char *input, STRLEN len, STRLEN *pos, struct cc_type *output);
