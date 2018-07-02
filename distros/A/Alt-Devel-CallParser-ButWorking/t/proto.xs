#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "proto_callparser1.h"
#include "XSUB.h"

MODULE = t::proto PACKAGE = t::proto

PROTOTYPES: DISABLE

void
cv_set_call_parser_proto(CV *cv, SV *proto)
PROTOTYPE: $$
CODE:
	if(SvROK(proto)) proto = SvRV(proto);
	cv_set_call_parser(cv, Perl_parse_args_proto, proto);

void
cv_set_call_parser_proto_or_list(CV *cv, SV *proto)
PROTOTYPE: $$
CODE:
	if(SvROK(proto)) proto = SvRV(proto);
	cv_set_call_parser(cv, Perl_parse_args_proto_or_list, proto);
