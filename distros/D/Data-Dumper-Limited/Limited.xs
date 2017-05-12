#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ddl_enc.h"


MODULE = Data::Dumper::Limited        PACKAGE = Data::Dumper::Limited
PROTOTYPES: DISABLE

void
DumpLimited(src, opt = newHV())
    SV *src;
    HV *opt;
  PREINIT:
    ddl_encoder_t *enc;
  PPCODE:
    enc = build_encoder_struct(aTHX_ opt);
    ddl_dump_sv(aTHX_ enc, src);
    /* FIXME optimization: avoid copy by stealing string buffer if
     *                     it is not too large. */
    ST(0) = sv_2mortal(newSVpvn_utf8(enc->buf_start, (STRLEN)(enc->pos - enc->buf_start), 1));
    XSRETURN(1);


