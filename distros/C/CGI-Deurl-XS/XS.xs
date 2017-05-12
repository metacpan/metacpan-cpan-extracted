#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <parser/parser.h>

#include "const-c.inc"

MODULE = CGI::Deurl::XS		PACKAGE = CGI::Deurl::XS

INCLUDE: const-xs.inc

SV*
parse_query_string(query)
    char* query
CODE:
    if (!query) {
        XSRETURN_UNDEF;
    }
    SV* sv = _split_to_parms(query);
    if (sv) {
        RETVAL = sv;
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
