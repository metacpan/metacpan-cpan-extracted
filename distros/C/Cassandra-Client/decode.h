#define PERL_NO_GET_CONTEXT
#include "perl.h"
#include "define.h"

void decode_cell(pTHX_ char *input, STRLEN len, STRLEN *pos, struct cc_type *type, SV *output);
