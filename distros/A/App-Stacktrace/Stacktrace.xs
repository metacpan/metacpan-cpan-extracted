#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

#include "thread.h"

#include "ppport.h"

#define V(h,k,v) hv_store(h, k, strlen(k), newSViv(v), 0);

#include "threads.h"

SV*
_perl_offsets() {
    HV *hv = newHV();;

    V(hv, "$CXTYPEMASK", (IV)CXTYPEMASK);
    V(hv, "$CXt_SUB", (IV)CXt_SUB);
    V(hv, "$CXt_EVAL", (IV)CXt_EVAL);
    V(hv, "$CXt_FORMAT", (IV)CXt_FORMAT);

#ifdef USE_ITHREADS
#  if PERL_VERSION >= 10
    V(hv, "$POOLP_main_thread", (IV)&((my_pool_t*)0)->main_thread);
    V(hv, "$THREAD_next", (IV)&((ithread*)0)->next);
    V(hv, "$THREAD_interpreter", (IV)&((ithread*)0)->interp);
    V(hv, "$THREAD_tid", (IV)&((ithread*)0)->tid);
    V(hv, "$THREAD_state", (IV)&((ithread*)0)->state);
    V(hv, "$INTERPRETER_modglobal", (IV)&((PerlInterpreter*)0)->Imodglobal);
    V(hv, "$INTERPRETER_curstackinfo", (IV)&((PerlInterpreter*)0)->Icurstackinfo);
    V(hv, "$COP_file", (IV)&((COP*)0)->cop_file);
#  elif PERL_VERSION == 8 && PERL_SUBVERSION >= 9
    V(hv, "$POOLP_main_thread", (IV)&((my_pool_t*)0)->main_thread);
    V(hv, "$THREAD_next", (IV)&((ithread*)0)->next);
    V(hv, "$THREAD_interpreter", (IV)&((ithread*)0)->interp);
    V(hv, "$THREAD_tid", (IV)&((ithread*)0)->tid);
    V(hv, "$THREAD_state", (IV)&((ithread*)0)->state);
    V(hv, "$INTERPRETER_modglobal", (IV)&((PerlInterpreter*)0)->Imodglobal);
    V(hv, "$INTERPRETER_curstackinfo", (IV)&((PerlInterpreter*)0)->Tcurstackinfo);
    V(hv, "$COP_file", (IV)&((COP*)0)->cop_file);
#  else
    V(hv, "$THREAD_next", (IV)&((ithread*)0)->next);
    V(hv, "$THREAD_interp", (IV)&((ithread*)0)->interp);
    V(hv, "$THREAD_tid", (IV)&((ithread*)0)->tid);
    V(hv, "$THREAD_state", (IV)&((ithread*)0)->state);
    V(hv, "$INTERPRETER_curstackinfo", (IV)&((PerlInterpreter*)0)->Tcurstackinfo);
    V(hv, "$COP_file", (IV)&((COP*)0)->cop_file);
#  endif
#else
    V(hv, "$COP_gv", (IV)&((COP*)0)->cop_filegv);
#endif

    V(hv, "$SV_any", (IV)&((SV*)0)->sv_any);
    V(hv, "$STACKINFO_cxstack", (IV)&((PERL_SI*)0)->si_cxstack);
    V(hv, "$STACKINFO_cxix", (IV)&((PERL_SI*)0)->si_cxix);
    V(hv, "$STACKINFO_prev", (IV)&((PERL_SI*)0)->si_prev);
    V(hv, "$CONTEXT_sizeof",  sizeof(PERL_CONTEXT));
    V(hv, "$CONTEXT_cop", (IV)&((PERL_CONTEXT*)0)->cx_u.cx_blk.blku_oldcop);
    V(hv, "$COP_line", (IV)&((COP*)0)->cop_line);
    V(hv, "$GP_sv", (IV)&((GP*)0)->gp_sv);

#if PERL_VERSION >= 10
    V(hv, "$CONTEXT_type", (IV)&((PERL_CONTEXT*)0)->cx_u.cx_subst.sbu_type);
    V(hv, "$GV_gp", (IV)&((GV*)0)->sv_u.svu_gp);
    V(hv, "$SV_pv", (IV)&((SV*)0)->sv_u.svu_pv);
#else
    V(hv, "$CONTEXT_type", (IV)&((PERL_CONTEXT*)0)->cx_type);
    V(hv, "$GV_gp", (IV)&((XPVGV*)0)->xgv_gp);
    V(hv, "$XPV_pv", (IV)&((XPV*)0)->xpv_pv);
#endif

#if PERL_VERSION >= 12
    V(hv, "$SV_iv", (IV)&((struct xpvuv*)0)->xuv_u.xivu_uv);
#elif PERL_VERSION >= 10
    V(hv, "$SV_uv", (IV)&((struct xpvuv*)0)->xuv_u.xuvu_uv);
#else
    V(hv, "$SV_uv", (IV)&((struct xpvuv*)0)->xuv_uv);
#endif
    return newRV_noinc((SV*) hv);
}

MODULE = App::Stacktrace PACKAGE = App::Stacktrace

SV*
_perl_offsets()
