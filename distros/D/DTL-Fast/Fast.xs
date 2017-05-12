#define PERL_NO_GET_CONTEXT 

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "src/perl_mnemonic.h"
#include "src/spaceless.h"
#include "src/html_protect.h"
#include "src/count_lines.h"

MODULE = DTL::Fast  PACKAGE = DTL::Fast

SV*
spaceless( SV* scalar_string )
    CODE:
        RETVAL = _spaceless( aTHX_ scalar_string );
    OUTPUT:
        RETVAL

SV*
html_protect( SV* scalar_string )
    CODE:
        RETVAL = _html_protect(aTHX_ scalar_string );
    OUTPUT:
        RETVAL
        
int
eval_sequence()
    CODE:
        RETVAL = PL_evalseq;
    OUTPUT:
        RETVAL

SV*
count_lines(SV* scalar_string)
    CODE:
        RETVAL = _count_lines(aTHX_ scalar_string );
    OUTPUT:
        RETVAL
