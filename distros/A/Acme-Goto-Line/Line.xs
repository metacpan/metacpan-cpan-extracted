#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

int acme_goto_line_walkop (OP* op, IV line) {
  if(!op)
    return 0;
  if(op->op_type == OP_NEXTSTATE) {
      COP* cop = (COP*) op;
      //      printf("Matching line %d == %d \n", cop->cop_line, line);
      if(cop->cop_line == line) {
	//	printf("Matched line %d\n", line);
	PL_op = op;
	return 1;
      }    
  }
  if(op && op->op_flags & OPf_KIDS) {
    UNOP* uop = (UNOP*) op;
    OP* kid;
    for(kid = uop->op_first; kid; kid = kid->op_sibling) {
      IV ret = acme_goto_line_walkop(kid, line);
      if(ret)
	return 1;
    }
  }
    return 0;
}

CV* acme_goto_line_find_cv() {
  I32		 ix;
  PERL_SI	 *si;
  PERL_CONTEXT *cx;
  for (si = PL_curstackinfo; si; si = si->si_prev) {
    for (ix = si->si_cxix; ix >= 0; ix--) {
      cx = &(si->si_cxstack[ix]);
      if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
	CV *cv = cx->blk_sub.cv;
	return cv;
      }
      else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx))
	return PL_compcv;
    }
  }
  return 0;
}

void acme_goto_line_goto (IV line) {
  CV* caller = acme_goto_line_find_cv();
  OP* op = 0;
  if(caller) {
    while(CvOUTSIDE(caller)) {
      caller = CvOUTSIDE(caller);
    }
  }
  if(caller == 0 || caller == PL_main_cv) {
    op = PL_main_root;
  } else if(PL_eval_root) {
    op = PL_eval_root;
  } else {
    op = CvROOT(caller);
  }
  acme_goto_line_walkop(op, line);
}

OP* acme_goto_line_newgoto(aTHX_) {
  dSP;
  IV line;

  if(PL_op->op_flags & OPf_STACKED) {
    SV* top = POPs;
    line = SvIV(top);
    PUSHs(top);
  } else {
    char* label = cPVOP->op_pv;
    SV* temp = newSVpv(label,0);
    line = SvIV(temp);
    SvREFCNT_dec(temp);
  }


  if(line) {
    acme_goto_line_goto(line);
  } else {
    return Perl_pp_goto();
  }
  RETURN;
}

MODULE = Acme::Goto::Line		PACKAGE = Acme::Goto::Line		

void
import(class)
     SV * class
     CODE: 
{
  PL_ppaddr[OP_GOTO] = MEMBER_TO_FPTR(acme_goto_line_newgoto);
}


void goto(line)
     IV line
     CODE:
     acme_goto_line_goto(line);
