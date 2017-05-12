#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* CPAN #28912: MSWin32 and AIX as only platforms do not export PERL_CORE functions,
   such as Perl_debop
   so disable this feature. cygwin gcc-3 --export-all-symbols was non-strict, gcc-4 is.
   POSIX with export PERL_DL_NONLAZY=1 also fails. This is checked in Makefile.PL
   but cannot be solved for clients adding it.
*/
#if !defined (DISABLE_PERL_CORE_EXPORTED) &&                            \
  (defined(WIN32) ||                                                    \
   defined(_MSC_VER) || defined(__MINGW32_VERSION) ||			\
   (defined(__CYGWIN__) && (__GNUC__ > 3)) || defined(AIX))
# define DISABLE_PERL_CORE_EXPORTED
#endif
#if PERL_VERSION < 7
# define DEBUG_v(x) DEBUG_t(x)
#endif

STATIC U32 opcount[MAXO];

/* From B::C */
STATIC int
my_runops(pTHX)
{
  int ignore = 0;
#if 0
  /* ignore all ops from our subs */
  HV* ign_stash = get_hv( "B::Stats::", 0 );
  if (!CopSTASH_eq(PL_curcop, PL_debstash)) {
    OP *o = PL_op;
    HV *stash = NULL;
    /* from Perl_debop */
    switch (o->op_type) {
    case OP_CONST:
	/* With ITHREADS, consts are stored in the pad, and the right pad
	 * may not be active here, so check.
	 * Looks like only during compiling the pads are illegal.
	 */
#ifdef USE_ITHREADS
	if ((((SVOP*)o)->op_sv) || !IN_PERL_COMPILETIME)
#endif
	  stash = GvSTASH(cSVOPo_sv);
	break;
    case OP_GVSV:
    case OP_GV:
	if (cGVOPo_gv) {
	    stash = GvSTASH(cGVOPo_gv);
	}
	break;
    default:
	break;
    }
    ignore = stash == ign_stash;
  }
#endif

  DEBUG_v(Perl_deb(aTHX_ "Entering new RUNOPS level (B::Stats)\n"));
  do {
#if (PERL_VERSION < 13) || ((PERL_VERSION == 13) && (PERL_SUBVERSION < 2))
    PERL_ASYNC_CHECK();
#endif
    if (PL_debug) {
      if (PL_watchaddr && (*PL_watchaddr != PL_watchok))
	PerlIO_printf(Perl_debug_log,
		      "WARNING: %"UVxf" changed from %"UVxf" to %"UVxf"\n",
		      PTR2UV(PL_watchaddr), PTR2UV(PL_watchok),
		      PTR2UV(*PL_watchaddr));
#if !defined(DISABLE_PERL_CORE_EXPORTED) && defined(DEBUGGING)
# if (PERL_VERSION > 7)
      if (DEBUG_s_TEST_) debstack();
      if (DEBUG_t_TEST_) debop(PL_op);
# else
      DEBUG_s(debstack());
      DEBUG_t(debop(PL_op));
# endif
#endif
    }
    if (!ignore) {
      opcount[PL_op->op_type]++;
#if defined(DEBUGGING) && PERL_VERSION > 7
      if (DEBUG_v_TEST_) {
# ifndef DISABLE_PERL_CORE_EXPORTED
        debop(PL_op);
# endif
        PerlIO_printf(Perl_debug_log, "Counted %d for %s\n",
		      opcount[PL_op->op_type]+1, PL_op_name[PL_op->op_type]);
      }
#endif
    }
  } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));
  DEBUG_v(Perl_deb(aTHX_ "leaving RUNOPS level (B::Stats)\n"));

  TAINT_NOT;
  return 0;
}

void
reset_rcount() {
#if 1
  memset(opcount, 0, sizeof(opcount));
#else
  register int i;
  for (i=0; i < MAXO; i++) {
    opcount[i] = 0;
  }
#endif
}
/* returns an SV ref to AV with caller now owning the SV ref */
SV *
rcount_all(pTHX) {
  AV * av;
  int i;
  av = newAV();
  for (i=0; i < MAXO; i++) {
    av_store(av, i, newSViv(opcount[i]));
  }
  return newRV_noinc((SV*)av);
}

MODULE = B::Stats  PACKAGE = B::Stats

PROTOTYPES: DISABLE

U32
rcount(opcode)
	IV opcode
  CODE:
	RETVAL = opcount[opcode];
  OUTPUT:
	RETVAL

SV *
rcount_all()
  C_ARGS:
    aTHX

void
reset_rcount()

void
_xs_collect_env()
  CODE:
	/* walk stashes in C and store in %B_env before B is loaded,
	   to be able to detect if our testfunc loads B and its 14 deps itself.
	 */

void
END(...)
  PREINIT:
    SV * sv;
  PPCODE:
    PUSHMARK(SP);
    PUSHs(sv_2mortal(rcount_all(aTHX)));
    PUTBACK;
    call_pv("B::Stats::_end", G_VOID);
    return; /* skip implicity PUTBACK */

void
INIT(...)
  PPCODE:
    PUTBACK;
    reset_rcount();
    return; /* skip implicity PUTBACK */

BOOT:
{
  reset_rcount();
  PL_runops = my_runops;
}
