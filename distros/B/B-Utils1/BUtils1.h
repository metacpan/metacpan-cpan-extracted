#ifndef _BUTILS1_H_
#define _BUTILS1_H_

#include "ppport.h"

typedef OP	*B__OP;
typedef UNOP	*B__UNOP;
typedef BINOP	*B__BINOP;
typedef LOGOP	*B__LOGOP;
typedef LISTOP	*B__LISTOP;
typedef PMOP	*B__PMOP;
typedef SVOP	*B__SVOP;
typedef PADOP	*B__PADOP;
typedef PVOP	*B__PVOP;
typedef LOOP	*B__LOOP;
typedef COP	*B__COP;

typedef SV	*B__SV;
typedef SV	*B__IV;
typedef SV	*B__PV;
typedef SV	*B__NV;
typedef SV	*B__PVMG;
typedef SV	*B__PVLV;
typedef SV	*B__BM;
typedef SV	*B__RV;
typedef SV	*B__FM;
typedef AV	*B__AV;
typedef HV	*B__HV;
typedef CV	*B__CV;
typedef GV	*B__GV;
typedef IO	*B__IO;

extern char *BUtils1_cc_opclassname(pTHX_ const OP *o);
extern SV *BUtils1_make_sv_object(pTHX_ SV *arg, SV *sv);

extern I32 BUtils1_op_name_to_num(SV * name);

extern PERL_CONTEXT *BUtils1_op_upcontext
(pTHX_ I32 count, COP **cop_p, PERL_CONTEXT **ccstack_p,
 I32 *cxix_from_p, I32 *cxix_to_p);

#endif
