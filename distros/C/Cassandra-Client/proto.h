#include <stdint.h>
#define PERL_NO_GET_CONTEXT
#include "perl.h"

int32_t unpack_int(pTHX_ char *input, STRLEN len, STRLEN *pos);
int unpack_short_nocroak(pTHX_ char *input, STRLEN len, STRLEN *pos, uint16_t *out);
uint16_t unpack_short(pTHX_ char *input, STRLEN len, STRLEN *pos);
int unpack_bytes(pTHX_ char *input, STRLEN len, STRLEN *pos, char **output, STRLEN *outlen);
SV *unpack_bytes_sv(pTHX_ char *input, STRLEN len, STRLEN *pos);
int unpack_string_nocroak(pTHX_ char *input, STRLEN len, STRLEN *pos, char **output, STRLEN *outlen);
void unpack_string(pTHX_ char *input, STRLEN len, STRLEN *pos, char **output, STRLEN *outlen);
SV *unpack_string_sv(pTHX_ char *input, STRLEN len, STRLEN *pos);
SV *unpack_string_sv_hash(pTHX_ char *input, STRLEN len, STRLEN *pos, U32 *hashout);
