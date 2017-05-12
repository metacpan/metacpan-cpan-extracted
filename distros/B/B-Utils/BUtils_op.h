#ifndef _BUTILS_OP_H_
#define _BUTILS__OP_H_

extern PERL_CONTEXT *BUtils_op_upcontext
(pTHX_ I32 count, COP **cop_p, PERL_CONTEXT **ccstack_p,
 I32 *cxix_from_p, I32 *cxix_to_p);

#endif
