#ifndef CONFOLD_COMPAT_H
#define CONFOLD_COMPAT_H

#include "xop_compat.h"

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

#define CF_bufptr   (PL_parser->bufptr)
#define CF_bufend   (PL_parser->bufend)
#define CF_linestr  (PL_parser->linestr)
#define CF_expect   (PL_parser->expect)

#ifndef OpSIBLING
#  ifdef OpHAS_SIBLING
#    define OpSIBLING(o) (OpHAS_SIBLING(o) ? (o)->op_sibling : NULL)
#  else
#    define OpSIBLING(o) ((o)->op_sibling)
#  endif
#endif

#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

#define CF_MAKE_CUSTOM(o, pp) STMT_START {  \
        (o)->op_type   = OP_CUSTOM;         \
        (o)->op_ppaddr = (pp);              \
    } STMT_END

#endif
