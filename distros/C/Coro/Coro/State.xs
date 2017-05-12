/* this works around a bug in mingw32 providing a non-working setjmp */
#define USE_NO_MINGW_SETJMP_TWO_ARGS

#define NDEBUG 1 /* perl usually disables NDEBUG later */

#include "libcoro/coro.c"

#define PERL_NO_GET_CONTEXT
#define PERL_EXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#include "schmorp.h"

#define ECB_NO_THREADS 1
#define ECB_NO_LIBM 1
#include "ecb.h"

#include <stddef.h>
#include <stdio.h>
#include <errno.h>
#include <assert.h>

#ifndef SvREFCNT_dec_NN
  #define SvREFCNT_dec_NN(sv) SvREFCNT_dec (sv)
#endif

#ifndef SvREFCNT_inc_NN
  #define SvREFCNT_inc_NN(sv) SvREFCNT_inc (sv)
#endif

#ifndef SVs_PADSTALE
# define SVs_PADSTALE 0
#endif

#ifdef PadARRAY
# define NEWPADAPI 1
# define newPADLIST(var)	(Newz (0, var, 1, PADLIST), Newx (PadlistARRAY (var), 2, PAD *))
#else
typedef AV PADNAMELIST;
# if !PERL_VERSION_ATLEAST(5,8,0)
typedef AV PADLIST;
typedef AV PAD;
# endif
# define PadlistARRAY(pl)	((PAD **)AvARRAY (pl))
# define PadlistMAX(pl)		AvFILLp (pl)
# define PadlistNAMES(pl)	(*PadlistARRAY (pl))
# define PadARRAY		AvARRAY
# define PadMAX			AvFILLp
# define newPADLIST(var)	((var) = newAV (), av_extend (var, 1))
#endif
#ifndef PadnamelistREFCNT
# define PadnamelistREFCNT(pnl) SvREFCNT (pnl)
#endif
#ifndef PadnamelistREFCNT_dec
# define PadnamelistREFCNT_dec(pnl) SvREFCNT_dec (pnl)
#endif

/* 5.19.something has replaced SVt_BIND by SVt_INVLIST */
/* we just alias it to SVt_IV, as that is sufficient for swap_sv for now */
#if PERL_VERSION_ATLEAST(5,19,0)
# define SVt_BIND SVt_IV
#endif

#if defined(_WIN32)
# undef HAS_GETTIMEOFDAY
# undef setjmp
# undef longjmp
# undef _exit
# define setjmp _setjmp /* deep magic */
#else
# include <inttypes.h> /* most portable stdint.h */
#endif

/* the maximum number of idle cctx that will be pooled */
static int cctx_max_idle = 4;

#if defined(DEBUGGING) && PERL_VERSION_ATLEAST(5,12,0)
# define HAS_SCOPESTACK_NAME 1
#endif

/* prefer perl internal functions over our own? */
#ifndef CORO_PREFER_PERL_FUNCTIONS
# define CORO_PREFER_PERL_FUNCTIONS 0
#endif

/* The next macros try to return the current stack pointer, in an as
 * portable way as possible. */
#if __GNUC__ >= 4
# define dSTACKLEVEL int stacklevel_dummy
# define STACKLEVEL __builtin_frame_address (0)
#else
# define dSTACKLEVEL volatile void *stacklevel
# define STACKLEVEL ((void *)&stacklevel)
#endif

#define IN_DESTRUCT PL_dirty

#include "CoroAPI.h"
#define GCoroAPI (&coroapi) /* very sneaky */

#ifdef USE_ITHREADS
# if CORO_PTHREAD
static void *coro_thx;
# endif
#endif

#ifdef __linux
# include <time.h> /* for timespec */
# include <syscall.h> /* for SYS_* */
# ifdef SYS_clock_gettime
#  define coro_clock_gettime(id, ts) syscall (SYS_clock_gettime, (id), (ts))
#  define CORO_CLOCK_MONOTONIC         1
#  define CORO_CLOCK_THREAD_CPUTIME_ID 3
# endif
#endif

/* perl usually suppressed asserts. for debugging, we sometimes force it to be on */
#if 0
# undef NDEBUG
# include <assert.h>
#endif

static double (*nvtime)(); /* so why doesn't it take void? */
static void   (*u2time)(pTHX_ UV ret[2]);

/* we hijack an hopefully unused CV flag for our purposes */
#define CVf_SLF 0x4000
static OP *pp_slf (pTHX);
static void slf_destroy (pTHX_ struct coro *coro);

static U32 cctx_gen;
static size_t cctx_stacksize = CORO_STACKSIZE;
static struct CoroAPI coroapi;
static AV *main_mainstack; /* used to differentiate between $main and others */
static JMPENV *main_top_env;
static HV *coro_state_stash, *coro_stash;
static volatile SV *coro_mortal; /* will be freed/thrown after next transfer */

static AV *av_destroy; /* destruction queue */
static SV *sv_manager; /* the manager coro */
static SV *sv_idle; /* $Coro::idle */

static GV *irsgv;    /* $/ */
static GV *stdoutgv; /* *STDOUT */
static SV *rv_diehook;
static SV *rv_warnhook;

/* async_pool helper stuff */
static SV *sv_pool_rss;
static SV *sv_pool_size;
static SV *sv_async_pool_idle; /* description string */
static AV *av_async_pool; /* idle pool */
static SV *sv_Coro; /* class string */
static CV *cv_pool_handler;

/* Coro::AnyEvent */
static SV *sv_activity;

/* enable processtime/realtime profiling */
static char enable_times;
typedef U32 coro_ts[2];
static coro_ts time_real, time_cpu;
static char times_valid;

static struct coro_cctx *cctx_first;
static int cctx_count, cctx_idle;

enum
{
  CC_MAPPED     = 0x01,
  CC_NOREUSE    = 0x02, /* throw this away after tracing */
  CC_TRACE      = 0x04,
  CC_TRACE_SUB  = 0x08, /* trace sub calls */
  CC_TRACE_LINE = 0x10, /* trace each statement */
  CC_TRACE_ALL  = CC_TRACE_SUB | CC_TRACE_LINE,
};

/* this is a structure representing a c-level coroutine */
typedef struct coro_cctx
{
  struct coro_cctx *next;

  /* the stack */
  struct coro_stack stack;

  /* cpu state */
  void *idle_sp;   /* sp of top-level transfer/schedule/cede call */
#ifndef NDEBUG
  JMPENV *idle_te; /* same as idle_sp, but for top_env */
#endif
  JMPENV *top_env;
  coro_context cctx;

  U32 gen;
#if CORO_USE_VALGRIND
  int valgrind_id;
#endif
  unsigned char flags;
} coro_cctx;

static coro_cctx *cctx_current; /* the currently running cctx */

/*****************************************************************************/

static MGVTBL coro_state_vtbl;

enum
{
  CF_RUNNING   = 0x0001, /* coroutine is running */
  CF_READY     = 0x0002, /* coroutine is ready */
  CF_NEW       = 0x0004, /* has never been switched to */
  CF_ZOMBIE    = 0x0008, /* coroutine data has been freed */
  CF_SUSPENDED = 0x0010, /* coroutine can't be scheduled */
  CF_NOCANCEL  = 0x0020, /* cannot cancel, set slf_frame.data to 1 (hackish) */
};

/* the structure where most of the perl state is stored, overlaid on the cxstack */
typedef struct
{
  #define VARx(name,expr,type) type name;
  #include "state.h"
} perl_slots;

/* how many context stack entries do we need for perl_slots */
#define SLOT_COUNT ((sizeof (perl_slots) + sizeof (PERL_CONTEXT) - 1) / sizeof (PERL_CONTEXT))

/* this is a structure representing a perl-level coroutine */
struct coro
{
  /* the C coroutine allocated to this perl coroutine, if any */
  coro_cctx *cctx;

  /* ready queue */
  struct coro *next_ready;

  /* state data */
  struct CoroSLF slf_frame; /* saved slf frame */
  AV *mainstack;
  perl_slots *slot; /* basically the saved sp */

  CV *startcv;  /* the CV to execute */
  AV *args;     /* data associated with this coroutine (initial args) */
  int flags;    /* CF_ flags */
  HV *hv;       /* the perl hash associated with this coro, if any */

  /* statistics */
  int usecount; /* number of transfers to this coro */

  /* coro process data */
  int prio;
  SV *except;   /* exception to be thrown */
  SV *rouse_cb; /* last rouse callback */
  AV *on_destroy; /* callbacks or coros to notify on destroy */
  AV *status;   /* the exit status list */

  /* async_pool */
  SV *saved_deffh;
  SV *invoke_cb;
  AV *invoke_av;

  /* on_enter/on_leave */
  AV *on_enter; AV *on_enter_xs;
  AV *on_leave; AV *on_leave_xs;

  /* swap_sv */
  AV *swap_sv;

  /* times */
  coro_ts t_cpu, t_real;

  /* linked list */
  struct coro *next, *prev;
};

typedef struct coro *Coro__State;
typedef struct coro *Coro__State_or_hashref;

/* the following variables are effectively part of the perl context */
/* and get copied between struct coro and these variables */
/* the main reason we don't support windows process emulation */
static struct CoroSLF slf_frame; /* the current slf frame */

/** Coro ********************************************************************/

#define CORO_PRIO_MAX     3
#define CORO_PRIO_HIGH    1
#define CORO_PRIO_NORMAL  0
#define CORO_PRIO_LOW    -1
#define CORO_PRIO_IDLE   -3
#define CORO_PRIO_MIN    -4

/* for Coro.pm */
static SV *coro_current;
static SV *coro_readyhook;
static struct coro *coro_ready [CORO_PRIO_MAX - CORO_PRIO_MIN + 1][2]; /* head|tail */
static CV *cv_coro_run;
static struct coro *coro_first;
#define coro_nready coroapi.nready

/** JIT *********************************************************************/

#if CORO_JIT
  /* APPLE doesn't have mmap though */
  #define CORO_JIT_UNIXY (__linux || __FreeBSD__ || __OpenBSD__ || __NetBSD__ || __solaris || __APPLE__)
  #ifndef CORO_JIT_TYPE
    #if ECB_AMD64 && CORO_JIT_UNIXY
      #define CORO_JIT_TYPE "amd64-unix"
    #elif __i386 && CORO_JIT_UNIXY
      #define CORO_JIT_TYPE "x86-unix"
    #endif
  #endif
#endif

#if !defined(CORO_JIT_TYPE) || _POSIX_MEMORY_PROTECTION <= 0
  #undef CORO_JIT
#endif

#if CORO_JIT
  typedef void (*load_save_perl_slots_type)(perl_slots *);
  static load_save_perl_slots_type load_perl_slots, save_perl_slots;
#endif

/** Coro::Select ************************************************************/

static OP *(*coro_old_pp_sselect) (pTHX);
static SV *coro_select_select;

/* horrible hack, but if it works... */
static OP *
coro_pp_sselect (pTHX)
{
  dSP;
  PUSHMARK (SP - 4); /* fake argument list */
  XPUSHs (coro_select_select);
  PUTBACK;

  /* entersub is an UNOP, select a LISTOP... keep your fingers crossed */
  PL_op->op_flags |= OPf_STACKED;
  PL_op->op_private = 0;
  return PL_ppaddr [OP_ENTERSUB](aTHX);
}

/** time stuff **************************************************************/

#ifdef HAS_GETTIMEOFDAY

ecb_inline void
coro_u2time (pTHX_ UV ret[2])
{
  struct timeval tv;
  gettimeofday (&tv, 0);

  ret [0] = tv.tv_sec;
  ret [1] = tv.tv_usec;
}

ecb_inline double
coro_nvtime (void)
{
  struct timeval tv;
  gettimeofday (&tv, 0);

  return tv.tv_sec + tv.tv_usec * 1e-6;
}

ecb_inline void
time_init (pTHX)
{
  nvtime = coro_nvtime;
  u2time = coro_u2time;
}

#else

ecb_inline void
time_init (pTHX)
{
  SV **svp;

  require_pv ("Time/HiRes.pm");

  svp = hv_fetch (PL_modglobal, "Time::NVtime", 12, 0);

  if (!svp)          croak ("Time::HiRes is required, but missing. Caught");
  if (!SvIOK (*svp)) croak ("Time::NVtime isn't a function pointer. Caught");

  nvtime = INT2PTR (double (*)(), SvIV (*svp));

  svp = hv_fetch (PL_modglobal, "Time::U2time", 12, 0);
  u2time = INT2PTR (void (*)(pTHX_ UV ret[2]), SvIV (*svp));
}

#endif

/** lowlevel stuff **********************************************************/

static SV * ecb_noinline
coro_get_sv (pTHX_ const char *name, int create)
{
#if PERL_VERSION_ATLEAST (5,10,0)
         /* silence stupid and wrong 5.10 warning that I am unable to switch off */
         get_sv (name, create);
#endif
  return get_sv (name, create);
}

static AV * ecb_noinline
coro_get_av (pTHX_ const char *name, int create)
{
#if PERL_VERSION_ATLEAST (5,10,0)
         /* silence stupid and wrong 5.10 warning that I am unable to switch off */
         get_av (name, create);
#endif
  return get_av (name, create);
}

static HV * ecb_noinline
coro_get_hv (pTHX_ const char *name, int create)
{
#if PERL_VERSION_ATLEAST (5,10,0)
         /* silence stupid and wrong 5.10 warning that I am unable to switch off */
         get_hv (name, create);
#endif
  return get_hv (name, create);
}

ecb_inline void
coro_times_update (void)
{
#ifdef coro_clock_gettime
  struct timespec ts;

  ts.tv_sec  = ts.tv_nsec = 0;
  coro_clock_gettime (CORO_CLOCK_THREAD_CPUTIME_ID, &ts);
  time_cpu  [0] = ts.tv_sec; time_cpu  [1] = ts.tv_nsec;

  ts.tv_sec  = ts.tv_nsec = 0;
  coro_clock_gettime (CORO_CLOCK_MONOTONIC, &ts);
  time_real [0] = ts.tv_sec; time_real [1] = ts.tv_nsec;
#else
  dTHX;
  UV tv[2];

  u2time (aTHX_ tv);
  time_real [0] = tv [0];
  time_real [1] = tv [1] * 1000;
#endif
}

ecb_inline void
coro_times_add (struct coro *c)
{
  c->t_real [1] += time_real [1];
  if (c->t_real [1] > 1000000000) { c->t_real [1] -= 1000000000; ++c->t_real [0]; }
  c->t_real [0] += time_real [0];

  c->t_cpu  [1] += time_cpu  [1];
  if (c->t_cpu  [1] > 1000000000) { c->t_cpu  [1] -= 1000000000; ++c->t_cpu  [0]; }
  c->t_cpu  [0] += time_cpu  [0];
}

ecb_inline void
coro_times_sub (struct coro *c)
{
  if (c->t_real [1] < time_real [1]) { c->t_real [1] += 1000000000; --c->t_real [0]; }
  c->t_real [1] -= time_real [1];
  c->t_real [0] -= time_real [0];

  if (c->t_cpu  [1] < time_cpu  [1]) { c->t_cpu  [1] += 1000000000; --c->t_cpu  [0]; }
  c->t_cpu  [1] -= time_cpu  [1];
  c->t_cpu  [0] -= time_cpu  [0];
}

/*****************************************************************************/
/* magic glue */

#define CORO_MAGIC_type_cv    26
#define CORO_MAGIC_type_state PERL_MAGIC_ext

#define CORO_MAGIC_NN(sv, type)				\
  (ecb_expect_true (SvMAGIC (sv)->mg_type == type)	\
    ? SvMAGIC (sv)					\
    : mg_find (sv, type))

#define CORO_MAGIC(sv, type)				\
  (ecb_expect_true (SvMAGIC (sv))			\
    ? CORO_MAGIC_NN (sv, type)				\
    : 0)

#define CORO_MAGIC_cv(cv)    CORO_MAGIC    (((SV *)(cv)), CORO_MAGIC_type_cv)
#define CORO_MAGIC_state(sv) CORO_MAGIC_NN (((SV *)(sv)), CORO_MAGIC_type_state)

ecb_inline MAGIC *
SvSTATEhv_p (pTHX_ SV *coro)
{
  MAGIC *mg;

  if (ecb_expect_true (
        SvTYPE (coro) == SVt_PVHV
        && (mg = CORO_MAGIC_state (coro))
        && mg->mg_virtual == &coro_state_vtbl
     ))
    return mg;

  return 0;
}

ecb_inline struct coro *
SvSTATE_ (pTHX_ SV *coro_sv)
{
  MAGIC *mg;

  if (SvROK (coro_sv))
    coro_sv = SvRV (coro_sv);

  mg = SvSTATEhv_p (aTHX_ coro_sv);
  if (!mg)
    croak ("Coro::State object required");

  return (struct coro *)mg->mg_ptr;
}

#define SvSTATE(sv) SvSTATE_ (aTHX_ (sv))

/* faster than SvSTATE, but expects a coroutine hv */
#define SvSTATE_hv(hv)  ((struct coro *)CORO_MAGIC_NN ((SV *)hv, CORO_MAGIC_type_state)->mg_ptr)
#define SvSTATE_current SvSTATE_hv (SvRV (coro_current))

/*****************************************************************************/
/* padlist management and caching */

ecb_inline PADLIST *
coro_derive_padlist (pTHX_ CV *cv)
{
  PADLIST *padlist = CvPADLIST (cv);
  PADLIST *newpadlist;
  PADNAMELIST *padnames;
  PAD *newpad;
  PADOFFSET off = PadlistMAX (padlist) + 1;

#if NEWPADAPI

  /* if we had the original CvDEPTH, we might be able to steal the CvDEPTH+1 entry instead */
  /* 20131102194744.GA6705@schmorp.de, 20131102195825.2013.qmail@lists-nntp.develooper.com */
  while (!PadlistARRAY (padlist)[off - 1])
    --off;

  Perl_pad_push (aTHX_ padlist, off);

  newpad = PadlistARRAY (padlist)[off];
  PadlistARRAY (padlist)[off] = 0;

#else

#if PERL_VERSION_ATLEAST (5,10,0)
  Perl_pad_push (aTHX_ padlist, off);
#else
  Perl_pad_push (aTHX_ padlist, off, 1);
#endif

  newpad = PadlistARRAY (padlist)[off];
  PadlistMAX (padlist) = off - 1;

#endif

  newPADLIST (newpadlist);
#if !PERL_VERSION_ATLEAST(5,15,3)
  /* Padlists are AvREAL as of 5.15.3. See perl bug #98092 and perl commit 7d953ba. */
  AvREAL_off (newpadlist);
#endif

  /* Already extended to 2 elements by newPADLIST. */
  PadlistMAX (newpadlist) = 1;

  padnames = PadlistNAMES (padlist);
  ++PadnamelistREFCNT (padnames);
  PadlistNAMES (newpadlist) = padnames;

  PadlistARRAY (newpadlist)[1] = newpad;

  return newpadlist;
}

ecb_inline void
free_padlist (pTHX_ PADLIST *padlist)
{
  /* may be during global destruction */
  if (!IN_DESTRUCT)
    {
      I32 i = PadlistMAX (padlist);

      while (i > 0) /* special-case index 0 */
        {
          /* we try to be extra-careful here */
          PAD *pad = PadlistARRAY (padlist)[i--];

          if (pad)
            {
              I32 j = PadMAX (pad);

              while (j >= 0)
                SvREFCNT_dec (PadARRAY (pad)[j--]);

              PadMAX (pad) = -1;
              SvREFCNT_dec (pad);
            }
        }

      PadnamelistREFCNT_dec (PadlistNAMES (padlist));

#if NEWPADAPI
      Safefree (PadlistARRAY (padlist));
      Safefree (padlist);
#else
      AvFILLp (padlist) = -1;
      AvREAL_off (padlist);
      SvREFCNT_dec ((SV*)padlist);
#endif
    }
}

static int
coro_cv_free (pTHX_ SV *sv, MAGIC *mg)
{
  PADLIST *padlist;
  PADLIST **padlists = (PADLIST **)(mg->mg_ptr + sizeof(size_t));
  size_t len = *(size_t *)mg->mg_ptr;

  /* perl manages to free our internal AV and _then_ call us */
  if (IN_DESTRUCT)
    return 0;

  while (len--)
    free_padlist (aTHX_ padlists[len]);

  return 0;
}

static MGVTBL coro_cv_vtbl = {
  0, 0, 0, 0,
  coro_cv_free
};

/* the next two functions merely cache the padlists */
ecb_inline void
get_padlist (pTHX_ CV *cv)
{
  MAGIC *mg = CORO_MAGIC_cv (cv);
  size_t *lenp;

  if (ecb_expect_true (mg && *(lenp = (size_t *)mg->mg_ptr)))
    CvPADLIST (cv) = ((PADLIST **)(mg->mg_ptr + sizeof(size_t)))[--*lenp];
  else
   {
#if CORO_PREFER_PERL_FUNCTIONS
     /* this is probably cleaner? but also slower! */
     /* in practise, it seems to be less stable */
     CV *cp = Perl_cv_clone (aTHX_ cv);
     CvPADLIST (cv) = CvPADLIST (cp);
     CvPADLIST (cp) = 0;
     SvREFCNT_dec (cp);
#else
     CvPADLIST (cv) = coro_derive_padlist (aTHX_ cv);
#endif
   }
}

ecb_inline void
put_padlist (pTHX_ CV *cv)
{
  MAGIC *mg = CORO_MAGIC_cv (cv);

  if (ecb_expect_false (!mg))
    {
      mg = sv_magicext ((SV *)cv, 0, CORO_MAGIC_type_cv, &coro_cv_vtbl, 0, 0);
      Newz (0, mg->mg_ptr ,sizeof (size_t) + sizeof (PADLIST *), char);
      mg->mg_len = 1; /* so mg_free frees mg_ptr */
    }
  else
    Renew (mg->mg_ptr,
           sizeof(size_t) + (*(size_t *)mg->mg_ptr + 1) * sizeof(PADLIST *),
           char);

  ((PADLIST **)(mg->mg_ptr + sizeof (size_t))) [(*(size_t *)mg->mg_ptr)++] = CvPADLIST (cv);
}

/** load & save, init *******************************************************/

ecb_inline void
swap_sv (SV *a, SV *b)
{
  const U32 keep = SVs_PADSTALE | SVs_PADTMP | SVs_PADMY; /* keep these flags */
  SV tmp;

  /* swap sv_any */
  SvANY (&tmp) = SvANY (a); SvANY (a) = SvANY (b); SvANY (b) = SvANY (&tmp);

  /* swap sv_flags */
  SvFLAGS (&tmp) = SvFLAGS (a);
  SvFLAGS (a)    = (SvFLAGS (a) & keep) | (SvFLAGS (b   ) & ~keep);
  SvFLAGS (b)    = (SvFLAGS (b) & keep) | (SvFLAGS (&tmp) & ~keep);

#if PERL_VERSION_ATLEAST (5,10,0)
  /* perl 5.10 and later complicates this _quite_ a bit, but it also
   * is much faster, so no quarrels here. alternatively, we could
   * sv_upgrade to avoid this.
   */
  {
    /* swap sv_u */
    tmp.sv_u = a->sv_u; a->sv_u = b->sv_u; b->sv_u = tmp.sv_u;

    /* if SvANY points to the head, we need to adjust the pointers,
     * as the pointer for a still points to b, and maybe vice versa.
     */
    U32 svany_in_head_set = (1 << SVt_NULL) | (1 << SVt_BIND) | (1 << SVt_IV) | (1 << SVt_RV);
    #if NVSIZE <= IVSIZE && PERL_VERSION_ATLEAST(5,22,0)
      svany_in_head_set |= 1 << SVt_NV;
    #endif

    #define svany_in_head(type) (svany_in_head_set & (1 << (type)))

    if (svany_in_head (SvTYPE (a)))
      SvANY (a) = (void *)((PTRV)SvANY (a) - (PTRV)b + (PTRV)a);

    if (svany_in_head (SvTYPE (b)))
      SvANY (b) = (void *)((PTRV)SvANY (b) - (PTRV)a + (PTRV)b);
  }
#endif
}

/* swap sv heads, at least logically */
static void
swap_svs_enter (pTHX_ Coro__State c)
{
  int i;

  for (i = 0; i <= AvFILLp (c->swap_sv); i += 2)
    swap_sv (AvARRAY (c->swap_sv)[i], AvARRAY (c->swap_sv)[i + 1]);
}

static void
swap_svs_leave (pTHX_ Coro__State c)
{
  int i;

  for (i = AvFILLp (c->swap_sv) - 1; i >= 0; i -= 2)
    swap_sv (AvARRAY (c->swap_sv)[i], AvARRAY (c->swap_sv)[i + 1]);
}

#define SWAP_SVS_ENTER(coro)			\
  if (ecb_expect_false ((coro)->swap_sv))	\
    swap_svs_enter (aTHX_ (coro))

#define SWAP_SVS_LEAVE(coro)			\
  if (ecb_expect_false ((coro)->swap_sv))	\
    swap_svs_leave (aTHX_ (coro))

static void
on_enterleave_call (pTHX_ SV *cb);

static void
load_perl (pTHX_ Coro__State c)
{
  perl_slots *slot = c->slot;
  c->slot = 0;

  PL_mainstack = c->mainstack;

#if CORO_JIT
  load_perl_slots (slot);
#else
  #define VARx(name,expr,type) expr = slot->name;
  #include "state.h"
#endif

  {
    dSP;

    CV *cv;

    /* now do the ugly restore mess */
    while (ecb_expect_true (cv = (CV *)POPs))
      {
        put_padlist (aTHX_ cv); /* mark this padlist as available */
        CvDEPTH (cv) = PTR2IV (POPs);
        CvPADLIST (cv) = (PADLIST *)POPs;
      }

    PUTBACK;
  }

  slf_frame  = c->slf_frame;
  CORO_THROW = c->except;

  if (ecb_expect_false (enable_times))
    {
      if (ecb_expect_false (!times_valid))
        coro_times_update ();

      coro_times_sub (c);
    }

  if (ecb_expect_false (c->on_enter))
    {
      int i;

      for (i = 0; i <= AvFILLp (c->on_enter); ++i)
        on_enterleave_call (aTHX_ AvARRAY (c->on_enter)[i]);
    }

  if (ecb_expect_false (c->on_enter_xs))
    {
      int i;

      for (i = 0; i <= AvFILLp (c->on_enter_xs); i += 2)
        ((coro_enterleave_hook)AvARRAY (c->on_enter_xs)[i]) (aTHX_ AvARRAY (c->on_enter_xs)[i + 1]);
    }

  SWAP_SVS_ENTER (c);
}

static void
save_perl (pTHX_ Coro__State c)
{
  SWAP_SVS_LEAVE (c);

  if (ecb_expect_false (c->on_leave_xs))
    {
      int i;

      for (i = AvFILLp (c->on_leave_xs) - 1; i >= 0; i -= 2)
        ((coro_enterleave_hook)AvARRAY (c->on_leave_xs)[i]) (aTHX_ AvARRAY (c->on_leave_xs)[i + 1]);
    }

  if (ecb_expect_false (c->on_leave))
    {
      int i;

      for (i = AvFILLp (c->on_leave); i >= 0; --i)
        on_enterleave_call (aTHX_ AvARRAY (c->on_leave)[i]);
    }

  times_valid = 0;

  if (ecb_expect_false (enable_times))
    {
      coro_times_update (); times_valid = 1;
      coro_times_add (c);
    }

  c->except    = CORO_THROW;
  c->slf_frame = slf_frame;

  {
    dSP;
    I32 cxix = cxstack_ix;
    PERL_CONTEXT *ccstk = cxstack;
    PERL_SI *top_si = PL_curstackinfo;

    /*
     * the worst thing you can imagine happens first - we have to save
     * (and reinitialize) all cv's in the whole callchain :(
     */

    XPUSHs (Nullsv);
    /* this loop was inspired by pp_caller */
    for (;;)
      {
        while (ecb_expect_true (cxix >= 0))
          {
            PERL_CONTEXT *cx = &ccstk[cxix--];

            if (ecb_expect_true (CxTYPE (cx) == CXt_SUB) || ecb_expect_false (CxTYPE (cx) == CXt_FORMAT))
              {
                CV *cv = cx->blk_sub.cv;

                if (ecb_expect_true (CvDEPTH (cv)))
                  {
                    EXTEND (SP, 3);
                    PUSHs ((SV *)CvPADLIST (cv));
                    PUSHs (INT2PTR (SV *, (IV)CvDEPTH (cv)));
                    PUSHs ((SV *)cv);

                    CvDEPTH (cv) = 0;
                    get_padlist (aTHX_ cv);
                  }
              }
          }

        if (ecb_expect_true (top_si->si_type == PERLSI_MAIN))
          break;

        top_si = top_si->si_prev;
        ccstk  = top_si->si_cxstack;
        cxix   = top_si->si_cxix;
      }

    PUTBACK;
  }

  /* allocate some space on the context stack for our purposes */
  if (ecb_expect_false (cxstack_ix + (int)SLOT_COUNT >= cxstack_max))
    {
      unsigned int i;

      for (i = 0; i < SLOT_COUNT; ++i)
        CXINC;

      cxstack_ix -= SLOT_COUNT; /* undo allocation */
    }

  c->mainstack = PL_mainstack;

  {
    perl_slots *slot = c->slot = (perl_slots *)(cxstack + cxstack_ix + 1);

#if CORO_JIT
    save_perl_slots (slot);
#else
    #define VARx(name,expr,type) slot->name = expr;
    #include "state.h"
#endif
  }
}

/*
 * allocate various perl stacks. This is almost an exact copy
 * of perl.c:init_stacks, except that it uses less memory
 * on the (sometimes correct) assumption that coroutines do
 * not usually need a lot of stackspace.
 */
#if CORO_PREFER_PERL_FUNCTIONS
# define coro_init_stacks(thx) init_stacks ()
#else
static void
coro_init_stacks (pTHX)
{
    PL_curstackinfo = new_stackinfo(32, 4 + SLOT_COUNT); /* 3 is minimum due to perl rounding down in scope.c:GROW() */
    PL_curstackinfo->si_type = PERLSI_MAIN;
    PL_curstack = PL_curstackinfo->si_stack;
    PL_mainstack = PL_curstack;		/* remember in case we switch stacks */

    PL_stack_base = AvARRAY(PL_curstack);
    PL_stack_sp = PL_stack_base;
    PL_stack_max = PL_stack_base + AvMAX(PL_curstack);

    New(50,PL_tmps_stack,32,SV*);
    PL_tmps_floor = -1;
    PL_tmps_ix = -1;
    PL_tmps_max = 32;

    New(54,PL_markstack,16,I32);
    PL_markstack_ptr = PL_markstack;
    PL_markstack_max = PL_markstack + 16;

#ifdef SET_MARK_OFFSET
    SET_MARK_OFFSET;
#endif

    New(54,PL_scopestack,8,I32);
    PL_scopestack_ix = 0;
    PL_scopestack_max = 8;
#if HAS_SCOPESTACK_NAME
    New(54,PL_scopestack_name,8,const char*);
#endif

    New(54,PL_savestack,24,ANY);
    PL_savestack_ix = 0;
    PL_savestack_max = 24;
#if PERL_VERSION_ATLEAST (5,24,0)
    /* perl 5.24 moves SS_MAXPUSH optimisation from */
    /* the header macros to PL_savestack_max */
    PL_savestack_max -= SS_MAXPUSH;
#endif

#if !PERL_VERSION_ATLEAST (5,10,0)
    New(54,PL_retstack,4,OP*);
    PL_retstack_ix = 0;
    PL_retstack_max = 4;
#endif
}
#endif

/*
 * destroy the stacks, the callchain etc...
 */
static void
coro_destruct_stacks (pTHX)
{
  while (PL_curstackinfo->si_next)
    PL_curstackinfo = PL_curstackinfo->si_next;

  while (PL_curstackinfo)
    {
      PERL_SI *p = PL_curstackinfo->si_prev;

      if (!IN_DESTRUCT)
        SvREFCNT_dec (PL_curstackinfo->si_stack);

      Safefree (PL_curstackinfo->si_cxstack);
      Safefree (PL_curstackinfo);
      PL_curstackinfo = p;
  }

  Safefree (PL_tmps_stack);
  Safefree (PL_markstack);
  Safefree (PL_scopestack);
#if HAS_SCOPESTACK_NAME
  Safefree (PL_scopestack_name);
#endif
  Safefree (PL_savestack);
#if !PERL_VERSION_ATLEAST (5,10,0)
  Safefree (PL_retstack);
#endif
}

#define CORO_RSS										\
  rss += sizeof (SYM (curstackinfo));								\
  rss += (SYM (curstackinfo->si_cxmax) + 1) * sizeof (PERL_CONTEXT);				\
  rss += sizeof (SV) + sizeof (struct xpvav) + (1 + AvMAX (SYM (curstack))) * sizeof (SV *);	\
  rss += SYM (tmps_max) * sizeof (SV *);							\
  rss += (SYM (markstack_max) - SYM (markstack_ptr)) * sizeof (I32);				\
  rss += SYM (scopestack_max) * sizeof (I32);							\
  rss += SYM (savestack_max) * sizeof (ANY);

static size_t
coro_rss (pTHX_ struct coro *coro)
{
  size_t rss = sizeof (*coro);

  if (coro->mainstack)
    {
      if (coro->flags & CF_RUNNING)
        {
          #define SYM(sym) PL_ ## sym
          CORO_RSS;
          #undef SYM
        }
      else
        {
          #define SYM(sym) coro->slot->sym
          CORO_RSS;
          #undef SYM
        }
    }

  return rss;
}

/** provide custom get/set/clear methods for %SIG elements ******************/

/* apparently < 5.8.8 */
#ifndef MgPV_nolen_const
#define MgPV_nolen_const(mg)    (((((int)(mg)->mg_len)) == HEf_SVKEY) ?   \
                                 SvPV_nolen((SV*)((mg)->mg_ptr)) :  \
                                 (const char*)(mg)->mg_ptr)
#endif

/* this will be a patched copy of PL_vtbl_sigelem */
static MGVTBL coro_sigelem_vtbl;

static int ecb_cold
coro_sig_copy (pTHX_ SV *sv, MAGIC *mg, SV *nsv, const char *name, I32 namlen)
{
  char *key = SvPV_nolen ((SV *)name);

  /* do what mg_copy normally does */
  sv_magic (nsv, mg->mg_obj, PERL_MAGIC_sigelem, name, namlen);
  assert (mg_find (nsv, PERL_MAGIC_sigelem)->mg_virtual == &PL_vtbl_sigelem);

  /* patch sigelem vtbl, but only for __WARN__ and __DIE__ */
  if (*key == '_'
      && (strEQ (key, "__DIE__")
          || strEQ (key, "__WARN__")))
    mg_find (nsv, PERL_MAGIC_sigelem)->mg_virtual = &coro_sigelem_vtbl;

  return 1;
}

/* perl does not have a %SIG vtbl, we provide one so we can override */
/* the magic vtbl for the __DIE__ and __WARN__ members */
static const MGVTBL coro_sig_vtbl = {
  0, 0, 0, 0, 0,
  coro_sig_copy
};

/*
 * This overrides the default magic get method of %SIG elements.
 * The original one doesn't provide for reading back of PL_diehook/PL_warnhook
 * and instead of trying to save and restore the hash elements (extremely slow),
 * we just provide our own readback here.
 */
static int ecb_cold
coro_sigelem_get (pTHX_ SV *sv, MAGIC *mg)
{
  const char *s = MgPV_nolen_const (mg);
  /* the key must be either __DIE__ or __WARN__ here */
  SV **svp = s[2] == 'D' ? &PL_diehook : &PL_warnhook;

  SV *ssv;

  if (!*svp)
    ssv = &PL_sv_undef;
  else if (SvTYPE (*svp) == SVt_PVCV) /* perlio directly stores a CV in warnhook. ugh. */
    ssv = sv_2mortal (newRV_inc (*svp));
  else
    ssv = *svp;

  sv_setsv (sv, ssv);
  return 0;
}

static int ecb_cold
coro_sigelem_clr (pTHX_ SV *sv, MAGIC *mg)
{
  const char *s = MgPV_nolen_const (mg);
  /* the key must be either __DIE__ or __WARN__ here */
  SV **svp = s[2] == 'D' ? &PL_diehook : &PL_warnhook;

  SV *old = *svp;
  *svp = 0;
  SvREFCNT_dec (old);
  return 0;
}

static int ecb_cold
coro_sigelem_set (pTHX_ SV *sv, MAGIC *mg)
{
  const char *s = MgPV_nolen_const (mg);
  /* the key must be either __DIE__ or __WARN__ here */
  SV **svp = s[2] == 'D' ? &PL_diehook : &PL_warnhook;

  SV *old = *svp;
  *svp = SvOK (sv) ? newSVsv (sv) : 0;
  SvREFCNT_dec (old);
  return 0;
}

static void
prepare_nop (pTHX_ struct coro_transfer_args *ta)
{
  /* kind of mega-hacky, but works */
  ta->next = ta->prev = (struct coro *)ta;
}

static int
slf_check_nop (pTHX_ struct CoroSLF *frame)
{
  return 0;
}

static int
slf_check_repeat (pTHX_ struct CoroSLF *frame)
{
  return 1;
}

/** coroutine stack handling ************************************************/

static UNOP init_perl_op;

ecb_noinline static void /* noinline to keep it out of the transfer fast path */
init_perl (pTHX_ struct coro *coro)
{
  /*
   * emulate part of the perl startup here.
   */
  coro_init_stacks (aTHX);

  PL_runops     = RUNOPS_DEFAULT;
  PL_curcop     = &PL_compiling;
  PL_in_eval    = EVAL_NULL;
  PL_comppad    = 0;
  PL_comppad_name       = 0;
  PL_comppad_name_fill  = 0;
  PL_comppad_name_floor = 0;
  PL_curpm      = 0;
  PL_curpad     = 0;
  PL_localizing = 0;
  PL_restartop  = 0;
#if PERL_VERSION_ATLEAST (5,10,0)
  PL_parser     = 0;
#endif
  PL_hints      = 0;

  /* recreate the die/warn hooks */
  PL_diehook  = SvREFCNT_inc (rv_diehook);
  PL_warnhook = SvREFCNT_inc (rv_warnhook);

  GvSV (PL_defgv)    = newSV (0);
  GvAV (PL_defgv)    = coro->args; coro->args = 0;
  GvSV (PL_errgv)    = newSV (0);
  GvSV (irsgv)       = newSVpvn ("\n", 1); sv_magic (GvSV (irsgv), (SV *)irsgv, PERL_MAGIC_sv, "/", 0);
  GvHV (PL_hintgv)   = newHV ();
#if PERL_VERSION_ATLEAST (5,10,0)
  hv_magic (GvHV (PL_hintgv), 0, PERL_MAGIC_hints);
#endif
  PL_rs              = newSVsv (GvSV (irsgv));
  PL_defoutgv        = (GV *)SvREFCNT_inc_NN (stdoutgv);

  {
    dSP;
    UNOP myop;

    Zero (&myop, 1, UNOP);
    myop.op_next  = Nullop;
    myop.op_type  = OP_ENTERSUB;
    myop.op_flags = OPf_WANT_VOID;

    PUSHMARK (SP);
    PUSHs ((SV *)coro->startcv);
    PUTBACK;
    PL_op = (OP *)&myop;
    PL_op = PL_ppaddr[OP_ENTERSUB](aTHX);
  }

  /* this newly created coroutine might be run on an existing cctx which most
   * likely was suspended in pp_slf, so we have to emulate entering pp_slf here.
   */
  slf_frame.prepare = prepare_nop;   /* provide a nop function for an eventual pp_slf */
  slf_frame.check   = slf_check_nop; /* signal pp_slf to not repeat */
  slf_frame.destroy = 0;

  /* and we have to provide the pp_slf op in any case, so pp_slf can skip it */
  init_perl_op.op_next   = PL_op;
  init_perl_op.op_type   = OP_ENTERSUB;
  init_perl_op.op_ppaddr = pp_slf;
  /* no flags etc. required, as an init function won't be called */

  PL_op = (OP *)&init_perl_op;

  /* copy throw, in case it was set before init_perl */
  CORO_THROW = coro->except;

  SWAP_SVS_ENTER (coro);

  if (ecb_expect_false (enable_times))
    {
      coro_times_update ();
      coro_times_sub (coro);
    }
}

static void
coro_unwind_stacks (pTHX)
{
  if (!IN_DESTRUCT)
    {
      /* restore all saved variables and stuff */
      LEAVE_SCOPE (0);
      assert (PL_tmps_floor == -1);

      /* free all temporaries */
      FREETMPS;
      assert (PL_tmps_ix == -1);

      /* unwind all extra stacks */
      POPSTACK_TO (PL_mainstack);

      /* unwind main stack */
      dounwind (-1);
    }
}

static void
destroy_perl (pTHX_ struct coro *coro)
{
  SV *svf [9];

  {
    SV *old_current = SvRV (coro_current);
    struct coro *current = SvSTATE (old_current);

    assert (("FATAL: tried to destroy currently running coroutine", coro->mainstack != PL_mainstack));

    save_perl (aTHX_ current);

    /* this will cause transfer_check to croak on block*/
    SvRV_set (coro_current, (SV *)coro->hv);

    load_perl (aTHX_ coro);

    /* restore swapped sv's */
    SWAP_SVS_LEAVE (coro);

    coro_unwind_stacks (aTHX);

    coro_destruct_stacks (aTHX);

    /* now save some sv's to be free'd later */
    svf    [0] =       GvSV (PL_defgv);
    svf    [1] = (SV *)GvAV (PL_defgv);
    svf    [2] =       GvSV (PL_errgv);
    svf    [3] = (SV *)PL_defoutgv;
    svf    [4] =       PL_rs;
    svf    [5] =       GvSV (irsgv);
    svf    [6] = (SV *)GvHV (PL_hintgv);
    svf    [7] =       PL_diehook;
    svf    [8] =       PL_warnhook;
    assert (9 == sizeof (svf) / sizeof (*svf));

    SvRV_set (coro_current, old_current);

    load_perl (aTHX_ current);
  }

  {
    unsigned int i;

    for (i = 0; i < sizeof (svf) / sizeof (*svf); ++i)
      SvREFCNT_dec (svf [i]);

    SvREFCNT_dec (coro->saved_deffh);
    SvREFCNT_dec (coro->rouse_cb);
    SvREFCNT_dec (coro->invoke_cb);
    SvREFCNT_dec (coro->invoke_av);
    SvREFCNT_dec (coro->on_enter_xs);
    SvREFCNT_dec (coro->on_leave_xs);
  }
}

ecb_inline void
free_coro_mortal (pTHX)
{
  if (ecb_expect_true (coro_mortal))
    {
      SvREFCNT_dec ((SV *)coro_mortal);
      coro_mortal = 0;
    }
}

static int
runops_trace (pTHX)
{
  COP *oldcop = 0;
  int oldcxix = -2;

  while ((PL_op = CALL_FPTR (PL_op->op_ppaddr) (aTHX)))
    {
      PERL_ASYNC_CHECK ();

      if (cctx_current->flags & CC_TRACE_ALL)
        {
          if (PL_op->op_type == OP_LEAVESUB && cctx_current->flags & CC_TRACE_SUB)
            {
              PERL_CONTEXT *cx = &cxstack[cxstack_ix];
              SV **bot, **top;
              AV *av = newAV (); /* return values */
              SV **cb;
              dSP;

              GV *gv = CvGV (cx->blk_sub.cv);
              SV *fullname = sv_2mortal (newSV (0));
              if (isGV (gv))
                gv_efullname3 (fullname, gv, 0);

              bot = PL_stack_base + cx->blk_oldsp + 1;
              top = cx->blk_gimme == G_ARRAY  ? SP + 1
                  : cx->blk_gimme == G_SCALAR ? bot + 1
                  :                             bot;

              av_extend (av, top - bot);
              while (bot < top)
                av_push (av, SvREFCNT_inc_NN (*bot++));

              PL_runops = RUNOPS_DEFAULT;
              ENTER;
              SAVETMPS;
              EXTEND (SP, 3);
              PUSHMARK (SP);
              PUSHs (&PL_sv_no);
              PUSHs (fullname);
              PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));
              PUTBACK;
              cb = hv_fetch ((HV *)SvRV (coro_current), "_trace_sub_cb", sizeof ("_trace_sub_cb") - 1, 0);
              if (cb) call_sv (*cb, G_KEEPERR | G_EVAL | G_VOID | G_DISCARD);
              SPAGAIN;
              FREETMPS;
              LEAVE;
              PL_runops = runops_trace;
            }

          if (oldcop != PL_curcop)
            {
              oldcop = PL_curcop;

              if (PL_curcop != &PL_compiling)
                {
                  SV **cb;

                  if (oldcxix != cxstack_ix && cctx_current->flags & CC_TRACE_SUB && cxstack_ix >= 0)
                    {
                      PERL_CONTEXT *cx = &cxstack[cxstack_ix];

                      if (CxTYPE (cx) == CXt_SUB && oldcxix < cxstack_ix)
                        {
                          dSP;
                          GV *gv = CvGV (cx->blk_sub.cv);
                          SV *fullname = sv_2mortal (newSV (0));

                          if (isGV (gv))
                            gv_efullname3 (fullname, gv, 0);

                          PL_runops = RUNOPS_DEFAULT;
                          ENTER;
                          SAVETMPS;
                          EXTEND (SP, 3);
                          PUSHMARK (SP);
                          PUSHs (&PL_sv_yes);
                          PUSHs (fullname);
                          PUSHs (CxHASARGS (cx) ? sv_2mortal (newRV_inc ((SV *)cx->blk_sub.argarray)) : &PL_sv_undef);
                          PUTBACK;
                          cb = hv_fetch ((HV *)SvRV (coro_current), "_trace_sub_cb", sizeof ("_trace_sub_cb") - 1, 0);
                          if (cb) call_sv (*cb, G_KEEPERR | G_EVAL | G_VOID | G_DISCARD);
                          SPAGAIN;
                          FREETMPS;
                          LEAVE;
                          PL_runops = runops_trace;
                        }

                      oldcxix = cxstack_ix;
                    }

                  if (cctx_current->flags & CC_TRACE_LINE)
                    {
                      dSP;

                      PL_runops = RUNOPS_DEFAULT;
                      ENTER;
                      SAVETMPS;
                      EXTEND (SP, 3);
                      PL_runops = RUNOPS_DEFAULT;
                      PUSHMARK (SP);
                      PUSHs (sv_2mortal (newSVpv (OutCopFILE (oldcop), 0)));
                      PUSHs (sv_2mortal (newSViv (CopLINE (oldcop))));
                      PUTBACK;
                      cb = hv_fetch ((HV *)SvRV (coro_current), "_trace_line_cb", sizeof ("_trace_line_cb") - 1, 0);
                      if (cb) call_sv (*cb, G_KEEPERR | G_EVAL | G_VOID | G_DISCARD);
                      SPAGAIN;
                      FREETMPS;
                      LEAVE;
                      PL_runops = runops_trace;
                    }
                }
            }
        }
    }

  TAINT_NOT;
  return 0;
}

static struct CoroSLF cctx_ssl_frame;

static void
slf_prepare_set_stacklevel (pTHX_ struct coro_transfer_args *ta)
{
  ta->prev = 0;
}

static int
slf_check_set_stacklevel (pTHX_ struct CoroSLF *frame)
{
  *frame = cctx_ssl_frame;

  return frame->check (aTHX_ frame); /* execute the restored frame - there must be one */
}

/* initialises PL_top_env and injects a pseudo-slf-call to set the stacklevel */
static void ecb_noinline
cctx_prepare (pTHX)
{
  PL_top_env = &PL_start_env;

  if (cctx_current->flags & CC_TRACE)
    PL_runops = runops_trace;

  /* we already must be executing an SLF op, there is no other valid way
   * that can lead to creation of a new cctx */
  assert (("FATAL: can't prepare slf-less cctx in Coro module (please report)",
           slf_frame.prepare && PL_op->op_ppaddr == pp_slf));

  /* we must emulate leaving pp_slf, which is done inside slf_check_set_stacklevel */
  cctx_ssl_frame = slf_frame;

  slf_frame.prepare = slf_prepare_set_stacklevel;
  slf_frame.check   = slf_check_set_stacklevel;
}

/* the tail of transfer: execute stuff we can only do after a transfer */
ecb_inline void
transfer_tail (pTHX)
{
  free_coro_mortal (aTHX);
}

/* try to exit the same way perl's main function would do */
/* we do not bother resetting the environment or other things *7
/* that are not, uhm, essential */
/* this obviously also doesn't work when perl is embedded */
static void ecb_noinline ecb_cold
perlish_exit (pTHX)
{
  int exitstatus = perl_destruct (PL_curinterp);
  perl_free (PL_curinterp);
  exit (exitstatus);
}

/*
 * this is a _very_ stripped down perl interpreter ;)
 */
static void
cctx_run (void *arg)
{
#ifdef USE_ITHREADS
# if CORO_PTHREAD
  PERL_SET_CONTEXT (coro_thx);
# endif
#endif
  {
    dTHX;

    /* normally we would need to skip the entersub here */
    /* not doing so will re-execute it, which is exactly what we want */
    /* PL_nop = PL_nop->op_next */

    /* inject a fake subroutine call to cctx_init */
    cctx_prepare (aTHX);

    /* cctx_run is the alternative tail of transfer() */
    transfer_tail (aTHX);

    /* somebody or something will hit me for both perl_run and PL_restartop */
    PL_restartop = PL_op;
    perl_run (PL_curinterp);
    /*
     * Unfortunately, there is no way to get at the return values of the
     * coro body here, as perl_run destroys these. Likewise, we cannot catch
     * runtime errors here, as this is just a random interpreter, not a thread.
     */

    /*
     * pp_entersub in 5.24 no longer ENTERs, but perl_destruct
     * requires PL_scopestack_ix, so do it here if required.
     */
    if (!PL_scopestack_ix)
      ENTER;

    /*
     * If perl-run returns we assume exit() was being called or the coro
     * fell off the end, which seems to be the only valid (non-bug)
     * reason for perl_run to return. We try to mimic whatever perl is normally
     * doing in that case. YMMV.
     */
    perlish_exit (aTHX);
  }
}

static coro_cctx *
cctx_new (void)
{
  coro_cctx *cctx;

  ++cctx_count;
  New (0, cctx, 1, coro_cctx);

  cctx->gen     = cctx_gen;
  cctx->flags   = 0;
  cctx->idle_sp = 0; /* can be accessed by transfer between cctx_run and set_stacklevel, on throw */

  return cctx;
}

/* create a new cctx only suitable as source */
static coro_cctx *
cctx_new_empty (void)
{
  coro_cctx *cctx = cctx_new ();

  cctx->stack.sptr = 0;
  coro_create (&cctx->cctx, 0, 0, 0, 0);

  return cctx;
}

/* create a new cctx suitable as destination/running a perl interpreter */
static coro_cctx *
cctx_new_run (void)
{
  coro_cctx *cctx = cctx_new ();

  if (!coro_stack_alloc (&cctx->stack, cctx_stacksize))
    {
      perror ("FATAL: unable to allocate stack for coroutine, exiting.");
      _exit (EXIT_FAILURE);
    }

  coro_create (&cctx->cctx, cctx_run, (void *)cctx, cctx->stack.sptr, cctx->stack.ssze);

  return cctx;
}

static void
cctx_destroy (coro_cctx *cctx)
{
  if (!cctx)
    return;

  assert (("FATAL: tried to destroy current cctx", cctx != cctx_current));

  --cctx_count;
  coro_destroy (&cctx->cctx);

  coro_stack_free (&cctx->stack);

  Safefree (cctx);
}

/* wether this cctx should be destructed */
#define CCTX_EXPIRED(cctx) ((cctx)->gen != cctx_gen || ((cctx)->flags & CC_NOREUSE))

static coro_cctx *
cctx_get (pTHX)
{
  while (ecb_expect_true (cctx_first))
    {
      coro_cctx *cctx = cctx_first;
      cctx_first = cctx->next;
      --cctx_idle;

      if (ecb_expect_true (!CCTX_EXPIRED (cctx)))
        return cctx;

      cctx_destroy (cctx);
    }

  return cctx_new_run ();
}

static void
cctx_put (coro_cctx *cctx)
{
  assert (("FATAL: cctx_put called on non-initialised cctx in Coro (please report)", cctx->stack.sptr));

  /* free another cctx if overlimit */
  if (ecb_expect_false (cctx_idle >= cctx_max_idle))
    {
      coro_cctx *first = cctx_first;
      cctx_first = first->next;
      --cctx_idle;

      cctx_destroy (first);
    }

  ++cctx_idle;
  cctx->next = cctx_first;
  cctx_first = cctx;
}

/** coroutine switching *****************************************************/

static void
transfer_check (pTHX_ struct coro *prev, struct coro *next)
{
  /* TODO: throwing up here is considered harmful */

  if (ecb_expect_true (prev != next))
    {
      if (ecb_expect_false (!(prev->flags & (CF_RUNNING | CF_NEW))))
        croak ("Coro::State::transfer called with a blocked prev Coro::State, but can only transfer from running or new states,");

      if (ecb_expect_false (next->flags & (CF_RUNNING | CF_ZOMBIE | CF_SUSPENDED)))
        croak ("Coro::State::transfer called with running, destroyed or suspended next Coro::State, but can only transfer to inactive states,");

#if !PERL_VERSION_ATLEAST (5,10,0)
      if (ecb_expect_false (PL_lex_state != LEX_NOTPARSING))
        croak ("Coro::State::transfer called while parsing, but this is not supported in your perl version,");
#endif
    }
}

/* always use the TRANSFER macro */
static void ecb_noinline /* noinline so we have a fixed stackframe */
transfer (pTHX_ struct coro *prev, struct coro *next, int force_cctx)
{
  dSTACKLEVEL;

  /* sometimes transfer is only called to set idle_sp */
  if (ecb_expect_false (!prev))
    {
      cctx_current->idle_sp = STACKLEVEL;
      assert (cctx_current->idle_te = PL_top_env); /* just for the side-effect when asserts are enabled */
    }
  else if (ecb_expect_true (prev != next))
    {
      coro_cctx *cctx_prev;

      if (ecb_expect_false (prev->flags & CF_NEW))
        {
          /* create a new empty/source context */
          prev->flags &= ~CF_NEW;
          prev->flags |=  CF_RUNNING;
        }

      prev->flags &= ~CF_RUNNING;
      next->flags |=  CF_RUNNING;

      /* first get rid of the old state */
      save_perl (aTHX_ prev);

      if (ecb_expect_false (next->flags & CF_NEW))
        {
          /* need to start coroutine */
          next->flags &= ~CF_NEW;
          /* setup coroutine call */
          init_perl (aTHX_ next);
        }
      else
        load_perl (aTHX_ next);

      /* possibly untie and reuse the cctx */
      if (ecb_expect_true (
            cctx_current->idle_sp == STACKLEVEL
            && !(cctx_current->flags & CC_TRACE)
            && !force_cctx
         ))
        {
          /* I assume that stacklevel is a stronger indicator than PL_top_env changes */
          assert (("FATAL: current top_env must equal previous top_env in Coro (please report)", PL_top_env == cctx_current->idle_te));

          /* if the cctx is about to be destroyed we need to make sure we won't see it in cctx_get. */
          /* without this the next cctx_get might destroy the running cctx while still in use */
          if (ecb_expect_false (CCTX_EXPIRED (cctx_current)))
            if (ecb_expect_true (!next->cctx))
              next->cctx = cctx_get (aTHX);

          cctx_put (cctx_current);
        }
      else
        prev->cctx = cctx_current;

      ++next->usecount;

      cctx_prev    = cctx_current;
      cctx_current = ecb_expect_false (next->cctx) ? next->cctx : cctx_get (aTHX);

      next->cctx = 0;

      if (ecb_expect_false (cctx_prev != cctx_current))
        {
          cctx_prev->top_env = PL_top_env;
          PL_top_env = cctx_current->top_env;
          coro_transfer (&cctx_prev->cctx, &cctx_current->cctx);
        }

      transfer_tail (aTHX);
    }
}

#define TRANSFER(ta, force_cctx) transfer (aTHX_ (ta).prev, (ta).next, (force_cctx))
#define TRANSFER_CHECK(ta) transfer_check (aTHX_ (ta).prev, (ta).next)

/** high level stuff ********************************************************/

/* this function is actually Coro, not Coro::State, but we call it from here */
/* because it is convenient - but it hasn't been declared yet for that reason */
static void
coro_call_on_destroy (pTHX_ struct coro *coro);

static void
coro_state_destroy (pTHX_ struct coro *coro)
{
  if (coro->flags & CF_ZOMBIE)
    return;

  slf_destroy (aTHX_ coro);

  coro->flags |= CF_ZOMBIE;

  if (coro->flags & CF_READY)
    {
      /* reduce nready, as destroying a ready coro effectively unreadies it */
      /* alternative: look through all ready queues and remove the coro */
      --coro_nready;
    }
  else
    coro->flags |= CF_READY; /* make sure it is NOT put into the readyqueue */

  if (coro->next) coro->next->prev = coro->prev;
  if (coro->prev) coro->prev->next = coro->next;
  if (coro == coro_first) coro_first = coro->next;

  if (coro->mainstack
      && coro->mainstack != main_mainstack
      && coro->slot
      && !PL_dirty)
    destroy_perl (aTHX_ coro);

  cctx_destroy (coro->cctx);
  SvREFCNT_dec (coro->startcv);
  SvREFCNT_dec (coro->args);
  SvREFCNT_dec (coro->swap_sv);
  SvREFCNT_dec (CORO_THROW);

  coro_call_on_destroy (aTHX_ coro);

  /* more destruction mayhem in coro_state_free */
}

static int
coro_state_free (pTHX_ SV *sv, MAGIC *mg)
{
  struct coro *coro = (struct coro *)mg->mg_ptr;
  mg->mg_ptr = 0;

  coro_state_destroy (aTHX_ coro);
  SvREFCNT_dec (coro->on_destroy);
  SvREFCNT_dec (coro->status);

  Safefree (coro);

  return 0;
}

static int ecb_cold
coro_state_dup (pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
  /* called when perl clones the current process the slow way (windows process emulation) */
  /* WE SIMply nuke the pointers in the copy, causing perl to croak */
  mg->mg_ptr     = 0;
  mg->mg_virtual = 0;

  return 0;
}

static MGVTBL coro_state_vtbl = {
  0, 0, 0, 0,
  coro_state_free,
  0,
#ifdef MGf_DUP
  coro_state_dup,
#else
# define MGf_DUP 0
#endif
};

static void
prepare_transfer (pTHX_ struct coro_transfer_args *ta, SV *prev_sv, SV *next_sv)
{
  ta->prev = SvSTATE (prev_sv);
  ta->next = SvSTATE (next_sv);
  TRANSFER_CHECK (*ta);
}

static void
api_transfer (pTHX_ SV *prev_sv, SV *next_sv)
{
  struct coro_transfer_args ta;

  prepare_transfer (aTHX_ &ta, prev_sv, next_sv);
  TRANSFER (ta, 1);
}

/** Coro ********************************************************************/

ecb_inline void
coro_enq (pTHX_ struct coro *coro)
{
  struct coro **ready = coro_ready [coro->prio - CORO_PRIO_MIN];

  SvREFCNT_inc_NN (coro->hv);

  coro->next_ready = 0;
  *(ready [0] ? &ready [1]->next_ready : &ready [0]) = coro;
  ready [1] = coro;
}

ecb_inline struct coro *
coro_deq (pTHX)
{
  int prio;

  for (prio = CORO_PRIO_MAX - CORO_PRIO_MIN + 1; --prio >= 0; )
    {
      struct coro **ready = coro_ready [prio];

      if (ready [0])
        {
          struct coro *coro = ready [0];
          ready [0] = coro->next_ready;
          return coro;
        }
    }

  return 0;
}

static void
invoke_sv_ready_hook_helper (void)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK (SP);
  PUTBACK;
  call_sv (coro_readyhook, G_VOID | G_DISCARD);

  FREETMPS;
  LEAVE;
}

static int
api_ready (pTHX_ SV *coro_sv)
{
  struct coro *coro = SvSTATE (coro_sv);

  if (coro->flags & CF_READY)
    return 0;

  coro->flags |= CF_READY;

  coro_enq (aTHX_ coro);

  if (!coro_nready++)
    if (coroapi.readyhook)
      coroapi.readyhook ();

  return 1;
}

static int
api_is_ready (pTHX_ SV *coro_sv)
{
  return !!(SvSTATE (coro_sv)->flags & CF_READY);
}

/* expects to own a reference to next->hv */
ecb_inline void
prepare_schedule_to (pTHX_ struct coro_transfer_args *ta, struct coro *next)
{
  SV *prev_sv = SvRV (coro_current);

  ta->prev = SvSTATE_hv (prev_sv);
  ta->next = next;

  TRANSFER_CHECK (*ta);

  SvRV_set (coro_current, (SV *)next->hv);

  free_coro_mortal (aTHX);
  coro_mortal = prev_sv;
}

static void
prepare_schedule (pTHX_ struct coro_transfer_args *ta)
{
  for (;;)
    {
      struct coro *next = coro_deq (aTHX);

      if (ecb_expect_true (next))
        {
          /* cannot transfer to destroyed coros, skip and look for next */
          if (ecb_expect_false (next->flags & (CF_ZOMBIE | CF_SUSPENDED)))
            SvREFCNT_dec (next->hv); /* coro_nready has already been taken care of by destroy */
          else
            {
              next->flags &= ~CF_READY;
              --coro_nready;

              prepare_schedule_to (aTHX_ ta, next);
              break;
            }
        }
      else
        {
          /* nothing to schedule: call the idle handler */
          if (SvROK (sv_idle)
              && SvOBJECT (SvRV (sv_idle)))
            {
              if (SvRV (sv_idle) == SvRV (coro_current))
                {
                  require_pv ("Carp");

                  {
                    dSP;

                    ENTER;
                    SAVETMPS;

                    PUSHMARK (SP);
                    XPUSHs (sv_2mortal (newSVpv ("FATAL: $Coro::idle blocked itself - did you try to block inside an event loop callback? Caught", 0)));
                    PUTBACK;
                    call_pv ("Carp::confess", G_VOID | G_DISCARD);

                    FREETMPS;
                    LEAVE;
                  }
                }

              ++coro_nready; /* hack so that api_ready doesn't invoke ready hook */
              api_ready (aTHX_ SvRV (sv_idle));
              --coro_nready;
            }
          else
            {
              /* TODO: deprecated, remove, cannot work reliably *//*D*/
              dSP;

              ENTER;
              SAVETMPS;

              PUSHMARK (SP);
              PUTBACK;
              call_sv (sv_idle, G_VOID | G_DISCARD);

              FREETMPS;
              LEAVE;
            }
        }
    }
}

ecb_inline void
prepare_cede (pTHX_ struct coro_transfer_args *ta)
{
  api_ready (aTHX_ coro_current);
  prepare_schedule (aTHX_ ta);
}

ecb_inline void
prepare_cede_notself (pTHX_ struct coro_transfer_args *ta)
{
  SV *prev = SvRV (coro_current);

  if (coro_nready)
    {
      prepare_schedule (aTHX_ ta);
      api_ready (aTHX_ prev);
    }
  else
    prepare_nop (aTHX_ ta);
}

static void
api_schedule (pTHX)
{
  struct coro_transfer_args ta;

  prepare_schedule (aTHX_ &ta);
  TRANSFER (ta, 1);
}

static void
api_schedule_to (pTHX_ SV *coro_sv)
{
  struct coro_transfer_args ta;
  struct coro *next = SvSTATE (coro_sv);

  SvREFCNT_inc_NN (coro_sv);
  prepare_schedule_to (aTHX_ &ta, next);
}

static int
api_cede (pTHX)
{
  struct coro_transfer_args ta;

  prepare_cede (aTHX_ &ta);

  if (ecb_expect_true (ta.prev != ta.next))
    {
      TRANSFER (ta, 1);
      return 1;
    }
  else
    return 0;
}

static int
api_cede_notself (pTHX)
{
  if (coro_nready)
    {
      struct coro_transfer_args ta;

      prepare_cede_notself (aTHX_ &ta);
      TRANSFER (ta, 1);
      return 1;
    }
  else
    return 0;
}

static void
api_trace (pTHX_ SV *coro_sv, int flags)
{
  struct coro *coro = SvSTATE (coro_sv);

  if (coro->flags & CF_RUNNING)
    croak ("cannot enable tracing on a running coroutine, caught");

  if (flags & CC_TRACE)
    {
      if (!coro->cctx)
        coro->cctx = cctx_new_run ();
      else if (!(coro->cctx->flags & CC_TRACE))
        croak ("cannot enable tracing on coroutine with custom stack, caught");

      coro->cctx->flags |= CC_NOREUSE | (flags & (CC_TRACE | CC_TRACE_ALL));
    }
  else if (coro->cctx && coro->cctx->flags & CC_TRACE)
    {
      coro->cctx->flags &= ~(CC_TRACE | CC_TRACE_ALL);

      if (coro->flags & CF_RUNNING)
        PL_runops = RUNOPS_DEFAULT;
      else
        coro->slot->runops = RUNOPS_DEFAULT;
    }
}

static void
coro_push_av (pTHX_ AV *av, I32 gimme_v)
{
  if (AvFILLp (av) >= 0 && gimme_v != G_VOID)
    {
      dSP;

      if (gimme_v == G_SCALAR)
        XPUSHs (AvARRAY (av)[AvFILLp (av)]);
      else
        {
          int i;
          EXTEND (SP, AvFILLp (av) + 1);

          for (i = 0; i <= AvFILLp (av); ++i)
            PUSHs (AvARRAY (av)[i]);
        }

      PUTBACK;
    }
}

static void
coro_push_on_destroy (pTHX_ struct coro *coro, SV *cb)
{
  if (!coro->on_destroy)
    coro->on_destroy = newAV ();

  av_push (coro->on_destroy, cb);
}

static void
slf_destroy_join (pTHX_ struct CoroSLF *frame)
{
  SvREFCNT_dec ((SV *)((struct coro *)frame->data)->hv);
}

static int
slf_check_join (pTHX_ struct CoroSLF *frame)
{
  struct coro *coro = (struct coro *)frame->data;

  if (!coro->status)
    return 1;

  frame->destroy = 0;

  coro_push_av (aTHX_ coro->status, GIMME_V);

  SvREFCNT_dec ((SV *)coro->hv);

  return 0;
}

static void
slf_init_join (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  struct coro *coro = SvSTATE (items > 0 ? arg [0] : &PL_sv_undef);

  if (items > 1)
    croak ("join called with too many arguments");

  if (coro->status)
    frame->prepare = prepare_nop;
  else
    {
      coro_push_on_destroy (aTHX_ coro, SvREFCNT_inc_NN (SvRV (coro_current)));
      frame->prepare = prepare_schedule;
    }

  frame->check   = slf_check_join;
  frame->destroy = slf_destroy_join;
  frame->data    = (void *)coro;
  SvREFCNT_inc (coro->hv);
}

static void
coro_call_on_destroy (pTHX_ struct coro *coro)
{
  AV *od = coro->on_destroy;

  if (!od)
    return;

  coro->on_destroy = 0;
  sv_2mortal ((SV *)od);

  while (AvFILLp (od) >= 0)
    {
      SV *cb = sv_2mortal (av_pop (od));

      /* coro hv's (and only hv's at the moment) are supported as well */
      if (SvSTATEhv_p (aTHX_ cb))
        api_ready (aTHX_ cb);
      else
        {
          dSP; /* don't disturb outer sp */
          PUSHMARK (SP);

          if (coro->status)
            {
              PUTBACK;
              coro_push_av (aTHX_ coro->status, G_ARRAY);
              SPAGAIN;
            }

          PUTBACK;
          call_sv (cb, G_VOID | G_DISCARD);
        }
    }
}

static void
coro_set_status (pTHX_ struct coro *coro, SV **arg, int items)
{
  AV *av;
 
  if (coro->status)
    {
      av = coro->status;
      av_clear (av);
    }
  else
    av = coro->status = newAV ();

  /* items are actually not so common, so optimise for this case */
  if (items)
    {
      int i;

      av_extend (av, items - 1);

      for (i = 0; i < items; ++i)
        av_push (av, SvREFCNT_inc_NN (arg [i]));
    }
}

static void
slf_init_terminate_cancel_common (pTHX_ struct CoroSLF *frame, HV *coro_hv)
{
  av_push (av_destroy, (SV *)newRV_inc ((SV *)coro_hv)); /* RVinc for perl */
  api_ready (aTHX_ sv_manager);

  frame->prepare = prepare_schedule;
  frame->check   = slf_check_repeat;

  /* as a minor optimisation, we could unwind all stacks here */
  /* but that puts extra pressure on pp_slf, and is not worth much */
  /*coro_unwind_stacks (aTHX);*/
}

static void
slf_init_terminate (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  HV *coro_hv = (HV *)SvRV (coro_current);

  coro_set_status (aTHX_ SvSTATE ((SV *)coro_hv), arg, items);
  slf_init_terminate_cancel_common (aTHX_ frame, coro_hv);
}

static void
slf_init_cancel (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  HV *coro_hv;
  struct coro *coro;

  if (items <= 0)
    croak ("Coro::cancel called without coro object,");

  coro = SvSTATE (arg [0]);
  coro_hv = coro->hv;

  coro_set_status (aTHX_ coro, arg + 1, items - 1);
 
  if (ecb_expect_false (coro->flags & CF_NOCANCEL))
    {
      /* coro currently busy cancelling something, so just notify it */
      coro->slf_frame.data = (void *)coro;

      frame->prepare = prepare_nop;
      frame->check   = slf_check_nop;
    }
  else if (coro_hv == (HV *)SvRV (coro_current))
    {
      /* cancelling the current coro is allowed, and equals terminate */
      slf_init_terminate_cancel_common (aTHX_ frame, coro_hv);
    }
  else
    {
      struct coro *self = SvSTATE_current;

      if (!self)
        croak ("Coro::cancel called outside of thread content,");

      /* otherwise we cancel directly, purely for speed reasons
       * unfortunately, this requires some magic trickery, as
       * somebody else could cancel us, so we have to fight the cancellation.
       * this is ugly, and hopefully fully worth the extra speed.
       * besides, I can't get the slow-but-safe version working...
       */
      slf_frame.data = 0;
      self->flags |= CF_NOCANCEL;
      coro_state_destroy (aTHX_ coro);
      self->flags &= ~CF_NOCANCEL;

      if (slf_frame.data)
        {
          /* while we were busy we have been cancelled, so terminate */
          slf_init_terminate_cancel_common (aTHX_ frame, self->hv);
        }
      else
        {
          frame->prepare = prepare_nop;
          frame->check   = slf_check_nop;
        }
    }
}

static int
slf_check_safe_cancel (pTHX_ struct CoroSLF *frame)
{
  frame->prepare = 0;
  coro_unwind_stacks (aTHX);

  slf_init_terminate_cancel_common (aTHX_ frame, (HV *)SvRV (coro_current));

  return 1;
}

static int
safe_cancel (pTHX_ struct coro *coro, SV **arg, int items)
{
  if (coro->cctx)
    croak ("coro inside C callback, unable to cancel at this time, caught");

  if (coro->flags & CF_NEW)
    {
      coro_set_status (aTHX_ coro, arg, items);
      coro_state_destroy (aTHX_ coro);
    }
  else
    {
      if (!coro->slf_frame.prepare)
        croak ("coro outside an SLF function, unable to cancel at this time, caught");

      slf_destroy (aTHX_ coro);

      coro_set_status (aTHX_ coro, arg, items);
      coro->slf_frame.prepare = prepare_nop;
      coro->slf_frame.check   = slf_check_safe_cancel;

      api_ready (aTHX_ (SV *)coro->hv);
    }

  return 1;
}

/*****************************************************************************/
/* async pool handler */

static int
slf_check_pool_handler (pTHX_ struct CoroSLF *frame)
{
  HV *hv = (HV *)SvRV (coro_current);
  struct coro *coro = (struct coro *)frame->data;

  if (!coro->invoke_cb)
    return 1; /* loop till we have invoke */
  else
    {
      hv_store (hv, "desc", sizeof ("desc") - 1,
                newSVpvn ("[async_pool]", sizeof ("[async_pool]") - 1), 0);

      coro->saved_deffh = SvREFCNT_inc_NN ((SV *)PL_defoutgv);

      {
        dSP;
        XPUSHs (sv_2mortal (coro->invoke_cb)); coro->invoke_cb = 0;
        PUTBACK;
      }

      SvREFCNT_dec (GvAV (PL_defgv));
      GvAV (PL_defgv) = coro->invoke_av;
      coro->invoke_av = 0;

      return 0;
    }
}

static void
slf_init_pool_handler (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  HV *hv = (HV *)SvRV (coro_current);
  struct coro *coro = SvSTATE_hv ((SV *)hv);

  if (ecb_expect_true (coro->saved_deffh))
    {
      /* subsequent iteration */
      SvREFCNT_dec ((SV *)PL_defoutgv); PL_defoutgv = (GV *)coro->saved_deffh;
      coro->saved_deffh = 0;

      if (coro_rss (aTHX_ coro) > SvUV (sv_pool_rss)
          || av_len (av_async_pool) + 1 >= SvIV (sv_pool_size))
        {
          slf_init_terminate_cancel_common (aTHX_ frame, hv);
          return;
        }
      else
        {
          av_clear (GvAV (PL_defgv));
          hv_store (hv, "desc", sizeof ("desc") - 1, SvREFCNT_inc_NN (sv_async_pool_idle), 0);

          if (ecb_expect_false (coro->swap_sv))
            {
              SWAP_SVS_LEAVE (coro);
              SvREFCNT_dec_NN (coro->swap_sv);
              coro->swap_sv = 0;
            }

          coro->prio = 0;

          if (ecb_expect_false (coro->cctx) && ecb_expect_false (coro->cctx->flags & CC_TRACE))
            api_trace (aTHX_ coro_current, 0);

          frame->prepare = prepare_schedule;
          av_push (av_async_pool, SvREFCNT_inc (hv));
        }
    }
  else
    {
      /* first iteration, simply fall through */
      frame->prepare = prepare_nop;
    }

  frame->check = slf_check_pool_handler;
  frame->data  = (void *)coro;
}

/*****************************************************************************/
/* rouse callback */

#define CORO_MAGIC_type_rouse PERL_MAGIC_ext

static void
coro_rouse_callback (pTHX_ CV *cv)
{
  dXSARGS;
  SV *data = (SV *)S_GENSUB_ARG;

  if (SvTYPE (SvRV (data)) != SVt_PVAV)
    {
      /* first call, set args */
      SV *coro = SvRV (data);
      AV *av = newAV ();

      SvRV_set (data, (SV *)av);

      /* better take a full copy of the arguments */
      while (items--)
        av_store (av, items, newSVsv (ST (items)));

      api_ready (aTHX_ coro);
      SvREFCNT_dec (coro);
    }

  XSRETURN_EMPTY;
}

static int
slf_check_rouse_wait (pTHX_ struct CoroSLF *frame)
{
  SV *data = (SV *)frame->data;
 
  if (CORO_THROW)
    return 0;

  if (SvTYPE (SvRV (data)) != SVt_PVAV)
    return 1;

  /* now push all results on the stack */
  {
    dSP;
    AV *av = (AV *)SvRV (data);
    int i;

    EXTEND (SP, AvFILLp (av) + 1);
    for (i = 0; i <= AvFILLp (av); ++i)
      PUSHs (sv_2mortal (AvARRAY (av)[i]));

    /* we have stolen the elements, so set length to zero and free */
    AvFILLp (av) = -1;
    av_undef (av);

    PUTBACK;
  }

  return 0;
}

static void
slf_init_rouse_wait (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  SV *cb;

  if (items)
    cb = arg [0];
  else
    {
      struct coro *coro = SvSTATE_current;

      if (!coro->rouse_cb)
        croak ("Coro::rouse_wait called without rouse callback, and no default rouse callback found either,");

      cb = sv_2mortal (coro->rouse_cb);
      coro->rouse_cb = 0;
    }

  if (!SvROK (cb)
      || SvTYPE (SvRV (cb)) != SVt_PVCV
      || CvXSUB ((CV *)SvRV (cb)) != coro_rouse_callback)
    croak ("Coro::rouse_wait called with illegal callback argument,");

  {
    CV *cv = (CV *)SvRV (cb); /* for S_GENSUB_ARG */
    SV *data = (SV *)S_GENSUB_ARG;

    frame->data    = (void *)data;
    frame->prepare = SvTYPE (SvRV (data)) == SVt_PVAV ? prepare_nop : prepare_schedule;
    frame->check   = slf_check_rouse_wait;
  }
}

static SV *
coro_new_rouse_cb (pTHX)
{
  HV *hv = (HV *)SvRV (coro_current);
  struct coro *coro = SvSTATE_hv (hv);
  SV *data = newRV_inc ((SV *)hv);
  SV *cb = s_gensub (aTHX_ coro_rouse_callback, (void *)data);

  sv_magicext (SvRV (cb), data, CORO_MAGIC_type_rouse, 0, 0, 0);
  SvREFCNT_dec (data); /* magicext increases the refcount */

  SvREFCNT_dec (coro->rouse_cb);
  coro->rouse_cb = SvREFCNT_inc_NN (cb);

  return cb;
}

/*****************************************************************************/
/* schedule-like-function opcode (SLF) */

static UNOP slf_restore; /* restore stack as entersub did, for first-re-run */
static const CV *slf_cv;
static SV **slf_argv;
static int slf_argc, slf_arga; /* count, allocated */
static I32 slf_ax; /* top of stack, for restore */

/* this restores the stack in the case we patched the entersub, to */
/* recreate the stack frame as perl will on following calls */
/* since entersub cleared the stack */
static OP *
pp_restore (pTHX)
{
  int i;
  SV **SP = PL_stack_base + slf_ax;

  PUSHMARK (SP);

  EXTEND (SP, slf_argc + 1);

  for (i = 0; i < slf_argc; ++i)
    PUSHs (sv_2mortal (slf_argv [i]));

  PUSHs ((SV *)CvGV (slf_cv));

  RETURNOP (slf_restore.op_first);
}

static void
slf_prepare_transfer (pTHX_ struct coro_transfer_args *ta)
{
  SV **arg = (SV **)slf_frame.data;

  prepare_transfer (aTHX_ ta, arg [0], arg [1]);
}

static void
slf_init_transfer (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  if (items != 2)
    croak ("Coro::State::transfer (prev, next) expects two arguments, not %d,", items);

  frame->prepare = slf_prepare_transfer;
  frame->check   = slf_check_nop;
  frame->data    = (void *)arg; /* let's hope it will stay valid */
}

static void
slf_init_schedule (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  frame->prepare = prepare_schedule;
  frame->check   = slf_check_nop;
}

static void
slf_prepare_schedule_to (pTHX_ struct coro_transfer_args *ta)
{
  struct coro *next = (struct coro *)slf_frame.data;

  SvREFCNT_inc_NN (next->hv);
  prepare_schedule_to (aTHX_ ta, next);
}

static void
slf_init_schedule_to (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  if (!items)
    croak ("Coro::schedule_to expects a coroutine argument, caught");

  frame->data    = (void *)SvSTATE (arg [0]);
  frame->prepare = slf_prepare_schedule_to;
  frame->check   = slf_check_nop;
}

static void
slf_init_cede_to (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  api_ready (aTHX_ SvRV (coro_current));

  slf_init_schedule_to (aTHX_ frame, cv, arg, items);
}

static void
slf_init_cede (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  frame->prepare = prepare_cede;
  frame->check   = slf_check_nop;
}

static void
slf_init_cede_notself (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  frame->prepare = prepare_cede_notself;
  frame->check   = slf_check_nop;
}

/* "undo"/cancel a running slf call - used when cancelling a coro, mainly */
static void
slf_destroy (pTHX_ struct coro *coro)
{
  struct CoroSLF frame = coro->slf_frame;

  /*
   * The on_destroy below most likely is from an SLF call.
   * Since by definition the SLF call will not finish when we destroy
   * the coro, we will have to force-finish it here, otherwise
   * cleanup functions cannot call SLF functions.
   */
  coro->slf_frame.prepare = 0;

  /* this callback is reserved for slf functions needing to do cleanup */
  if (frame.destroy && frame.prepare && !PL_dirty)
    frame.destroy (aTHX_ &frame);
}

/*
 * these not obviously related functions are all rolled into one
 * function to increase chances that they all will call transfer with the same
 * stack offset
 * SLF stands for "schedule-like-function".
 */
static OP *
pp_slf (pTHX)
{
  I32 checkmark; /* mark SP to see how many elements check has pushed */

  /* set up the slf frame, unless it has already been set-up */
  /* the latter happens when a new coro has been started */
  /* or when a new cctx was attached to an existing coroutine */
  if (ecb_expect_true (!slf_frame.prepare))
    {
      /* first iteration */
      dSP;
      SV **arg = PL_stack_base + TOPMARK + 1;
      int items = SP - arg; /* args without function object */
      SV *gv = *sp;

      /* do a quick consistency check on the "function" object, and if it isn't */
      /* for us, divert to the real entersub */
      if (SvTYPE (gv) != SVt_PVGV
          || !GvCV (gv)
          || !(CvFLAGS (GvCV (gv)) & CVf_SLF))
        return PL_ppaddr[OP_ENTERSUB](aTHX);

      if (!(PL_op->op_flags & OPf_STACKED))
        {
          /* ampersand-form of call, use @_ instead of stack */
          AV *av = GvAV (PL_defgv);
          arg = AvARRAY (av);
          items = AvFILLp (av) + 1;
        }

      /* now call the init function, which needs to set up slf_frame */
      ((coro_slf_cb)CvXSUBANY (GvCV (gv)).any_ptr)
        (aTHX_ &slf_frame, GvCV (gv), arg, items);

      /* pop args */
      SP = PL_stack_base + POPMARK;

      PUTBACK;
    }

  /* now that we have a slf_frame, interpret it! */
  /* we use a callback system not to make the code needlessly */
  /* complicated, but so we can run multiple perl coros from one cctx */

  do
    {
      struct coro_transfer_args ta;

      slf_frame.prepare (aTHX_ &ta);
      TRANSFER (ta, 0);

      checkmark = PL_stack_sp - PL_stack_base;
    }
  while (slf_frame.check (aTHX_ &slf_frame));

  slf_frame.prepare = 0; /* invalidate the frame, we are done processing it */

  /* exception handling */
  if (ecb_expect_false (CORO_THROW))
    {
      SV *exception = sv_2mortal (CORO_THROW);

      CORO_THROW = 0;
      sv_setsv (ERRSV, exception);
      croak (0);
    }

  /* return value handling - mostly like entersub */
  /* make sure we put something on the stack in scalar context */
  if (GIMME_V == G_SCALAR
      && ecb_expect_false (PL_stack_sp != PL_stack_base + checkmark + 1))
    {
      dSP;
      SV **bot = PL_stack_base + checkmark;

      if (sp == bot) /* too few, push undef */
        bot [1] = &PL_sv_undef;
      else /* too many, take last one */
        bot [1] = *sp;

      SP = bot + 1;

      PUTBACK;
    }

  return NORMAL;
}

static void
api_execute_slf (pTHX_ CV *cv, coro_slf_cb init_cb, I32 ax)
{
  int i;
  SV **arg = PL_stack_base + ax;
  int items = PL_stack_sp - arg + 1;

  assert (("FATAL: SLF call with illegal CV value", !CvANON (cv)));

  if (PL_op->op_ppaddr != PL_ppaddr [OP_ENTERSUB]
      && PL_op->op_ppaddr != pp_slf)
    croak ("FATAL: Coro SLF calls can only be made normally, not via goto or any other means, caught");

  CvFLAGS (cv) |= CVf_SLF;
  CvXSUBANY (cv).any_ptr = (void *)init_cb;
  slf_cv = cv;

  /* we patch the op, and then re-run the whole call */
  /* we have to put the same argument on the stack for this to work */
  /* and this will be done by pp_restore */
  slf_restore.op_next   = (OP *)&slf_restore;
  slf_restore.op_type   = OP_CUSTOM;
  slf_restore.op_ppaddr = pp_restore;
  slf_restore.op_first  = PL_op;

  slf_ax   = ax - 1; /* undo the ax++ inside dAXMARK */

  if (PL_op->op_flags & OPf_STACKED)
    {
      if (items > slf_arga)
        {
          slf_arga = items;
          Safefree (slf_argv);
          New (0, slf_argv, slf_arga, SV *);
        }

      slf_argc = items;

      for (i = 0; i < items; ++i)
        slf_argv [i] = SvREFCNT_inc (arg [i]);
    }
  else
    slf_argc = 0;

  PL_op->op_ppaddr  = pp_slf;
  /*PL_op->op_type    = OP_CUSTOM; /* we do behave like entersub still */

  PL_op = (OP *)&slf_restore;
}

/*****************************************************************************/
/* dynamic wind */

static void
on_enterleave_call (pTHX_ SV *cb)
{
  dSP;

  PUSHSTACK;

  PUSHMARK (SP);
  PUTBACK;
  call_sv (cb, G_VOID | G_DISCARD);
  SPAGAIN;

  POPSTACK;
}

static SV *
coro_avp_pop_and_free (pTHX_ AV **avp)
{
  AV *av = *avp;
  SV *res = av_pop (av);

  if (AvFILLp (av) < 0)
    {
      *avp = 0;
      SvREFCNT_dec (av);
    }

  return res;
}

static void
coro_pop_on_enter (pTHX_ void *coro)
{
  SV *cb = coro_avp_pop_and_free (aTHX_ &((struct coro *)coro)->on_enter);
  SvREFCNT_dec (cb);
}

static void
coro_pop_on_leave (pTHX_ void *coro)
{
  SV *cb = coro_avp_pop_and_free (aTHX_ &((struct coro *)coro)->on_leave);
  on_enterleave_call (aTHX_ sv_2mortal (cb));
}

static void
enterleave_hook_xs (pTHX_ struct coro *coro, AV **avp, coro_enterleave_hook hook, void *arg)
{
  if (!hook)
    return;

  if (!*avp)
    {
      *avp = newAV ();
      AvREAL_off (*avp);
    }

  av_push (*avp, (SV *)hook);
  av_push (*avp, (SV *)arg);
}

static void
enterleave_unhook_xs (pTHX_ struct coro *coro, AV **avp, coro_enterleave_hook hook, int execute)
{
  AV *av = *avp;
  int i;

  if (!av)
    return;

  for (i = AvFILLp (av) - 1; i >= 0; i -= 2)
    if (AvARRAY (av)[i] == (SV *)hook)
      {
        if (execute)
          hook (aTHX_ (void *)AvARRAY (av)[i + 1]);

        memmove (AvARRAY (av) + i, AvARRAY (av) + i + 2, AvFILLp (av) - i - 1);
        av_pop (av);
        av_pop (av);
        break;
      }

  if (AvFILLp (av) >= 0)
    {
      *avp = 0;
      SvREFCNT_dec_NN (av);
    }
}

static void
api_enterleave_hook (pTHX_ SV *coro_sv, coro_enterleave_hook enter, void *enter_arg, coro_enterleave_hook leave, void *leave_arg)
{
  struct coro *coro = SvSTATE (coro_sv);

  if (SvSTATE_current == coro)
    if (enter)
      enter (aTHX_ enter_arg);

  enterleave_hook_xs (aTHX_ coro, &coro->on_enter_xs, enter, enter_arg);
  enterleave_hook_xs (aTHX_ coro, &coro->on_leave_xs, leave, leave_arg);
}

static void
api_enterleave_unhook (pTHX_ SV *coro_sv, coro_enterleave_hook enter, coro_enterleave_hook leave)
{
  struct coro *coro = SvSTATE (coro_sv);

  enterleave_unhook_xs (aTHX_ coro, &coro->on_enter_xs, enter, 0);
  enterleave_unhook_xs (aTHX_ coro, &coro->on_leave_xs, leave, SvSTATE_current == coro);
}

static void
savedestructor_unhook_enter (pTHX_ coro_enterleave_hook enter)
{
  struct coro *coro = SvSTATE_current;

  enterleave_unhook_xs (aTHX_ coro, &coro->on_enter_xs, enter, 0);
}

static void
savedestructor_unhook_leave (pTHX_ coro_enterleave_hook leave)
{
  struct coro *coro = SvSTATE_current;

  enterleave_unhook_xs (aTHX_ coro, &coro->on_leave_xs, leave, 1);
}

static void
api_enterleave_scope_hook (pTHX_ coro_enterleave_hook enter, void *enter_arg, coro_enterleave_hook leave, void *leave_arg)
{
  api_enterleave_hook (aTHX_ coro_current, enter, enter_arg, leave, leave_arg);

  /* this ought to be much cheaper than malloc + a single destructor call */
  if (enter) SAVEDESTRUCTOR_X (savedestructor_unhook_enter, enter);
  if (leave) SAVEDESTRUCTOR_X (savedestructor_unhook_leave, leave);
}

/*****************************************************************************/
/* PerlIO::cede */

typedef struct
{
  PerlIOBuf base;
  NV next, every;
} PerlIOCede;

static IV ecb_cold
PerlIOCede_pushed (pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab)
{
  PerlIOCede *self = PerlIOSelf (f, PerlIOCede);

  self->every = SvCUR (arg) ? SvNV (arg) : 0.01;
  self->next  = nvtime () + self->every;

  return PerlIOBuf_pushed (aTHX_ f, mode, Nullsv, tab);
}

static SV * ecb_cold
PerlIOCede_getarg (pTHX_ PerlIO *f, CLONE_PARAMS *param, int flags)
{
  PerlIOCede *self = PerlIOSelf (f, PerlIOCede);

  return newSVnv (self->every);
}

static IV
PerlIOCede_flush (pTHX_ PerlIO *f)
{
  PerlIOCede *self = PerlIOSelf (f, PerlIOCede);
  double now = nvtime ();

  if (now >= self->next)
    {
      api_cede (aTHX);
      self->next = now + self->every;
    }

  return PerlIOBuf_flush (aTHX_ f);
}

static PerlIO_funcs PerlIO_cede =
{
  sizeof(PerlIO_funcs),
  "cede",
  sizeof(PerlIOCede),
  PERLIO_K_DESTRUCT | PERLIO_K_RAW,
  PerlIOCede_pushed,
  PerlIOBuf_popped,
  PerlIOBuf_open,
  PerlIOBase_binmode,
  PerlIOCede_getarg,
  PerlIOBase_fileno,
  PerlIOBuf_dup,
  PerlIOBuf_read,
  PerlIOBuf_unread,
  PerlIOBuf_write,
  PerlIOBuf_seek,
  PerlIOBuf_tell,
  PerlIOBuf_close,
  PerlIOCede_flush,
  PerlIOBuf_fill,
  PerlIOBase_eof,
  PerlIOBase_error,
  PerlIOBase_clearerr,
  PerlIOBase_setlinebuf,
  PerlIOBuf_get_base,
  PerlIOBuf_bufsiz,
  PerlIOBuf_get_ptr,
  PerlIOBuf_get_cnt,
  PerlIOBuf_set_ptrcnt,
};

/*****************************************************************************/
/* Coro::Semaphore & Coro::Signal */

static SV *
coro_waitarray_new (pTHX_ int count)
{
  /* a waitarray=semaphore contains a counter IV in $sem->[0] and any waiters after that */
  AV *av = newAV ();
  SV **ary;

  /* unfortunately, building manually saves memory */
  Newx (ary, 2, SV *);
  AvALLOC (av) = ary;
#if PERL_VERSION_ATLEAST (5,10,0)
  AvARRAY (av) = ary;
#else
  /* 5.8.8 needs this syntax instead of AvARRAY = ary, yet */
  /* -DDEBUGGING flags this as a bug, despite it perfectly working */
  SvPVX ((SV *)av) = (char *)ary;
#endif
  AvMAX   (av) = 1;
  AvFILLp (av) = 0;
  ary [0] = newSViv (count);

  return newRV_noinc ((SV *)av);
}

/* semaphore */

static void
coro_semaphore_adjust (pTHX_ AV *av, IV adjust)
{
  SV *count_sv = AvARRAY (av)[0];
  IV count = SvIVX (count_sv);

  count += adjust;
  SvIVX (count_sv) = count;

  /* now wake up as many waiters as are expected to lock */
  while (count > 0 && AvFILLp (av) > 0)
    {
      SV *cb;

      /* swap first two elements so we can shift a waiter */
      AvARRAY (av)[0] = AvARRAY (av)[1];
      AvARRAY (av)[1] = count_sv;
      cb = av_shift (av);

      if (SvOBJECT (cb))
        {
          api_ready (aTHX_ cb);
          --count;
        }
      else if (SvTYPE (cb) == SVt_PVCV)
        {
          dSP;
          PUSHMARK (SP);
          XPUSHs (sv_2mortal (newRV_inc ((SV *)av)));
          PUTBACK;
          call_sv (cb, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
        }

      SvREFCNT_dec_NN (cb);
    }
}

static void
coro_semaphore_destroy (pTHX_ struct CoroSLF *frame)
{
  /* call $sem->adjust (0) to possibly wake up some other waiters */
  coro_semaphore_adjust (aTHX_ (AV *)frame->data, 0);
}

static int
slf_check_semaphore_down_or_wait (pTHX_ struct CoroSLF *frame, int acquire)
{
  AV *av = (AV *)frame->data;
  SV *count_sv = AvARRAY (av)[0];
  SV *coro_hv = SvRV (coro_current);

  frame->destroy = 0;

  /* if we are about to throw, don't actually acquire the lock, just throw */
  if (ecb_expect_false (CORO_THROW))
    {
      /* we still might be responsible for the semaphore, so wake up others */
      coro_semaphore_adjust (aTHX_ av, 0);

      return 0;
    }
  else if (SvIVX (count_sv) > 0)
    {
      if (acquire)
        SvIVX (count_sv) = SvIVX (count_sv) - 1;
      else
        coro_semaphore_adjust (aTHX_ av, 0);

      return 0;
    }
  else
    {
      int i;
      /* if we were woken up but can't down, we look through the whole */
      /* waiters list and only add us if we aren't in there already */
      /* this avoids some degenerate memory usage cases */
      for (i = AvFILLp (av); i > 0; --i) /* i > 0 is not an off-by-one bug */
        if (AvARRAY (av)[i] == coro_hv)
          return 1;

      av_push (av, SvREFCNT_inc (coro_hv));
      return 1;
    }
}

static int
slf_check_semaphore_down (pTHX_ struct CoroSLF *frame)
{
  return slf_check_semaphore_down_or_wait (aTHX_ frame, 1);
}

static int
slf_check_semaphore_wait (pTHX_ struct CoroSLF *frame)
{
  return slf_check_semaphore_down_or_wait (aTHX_ frame, 0);
}

static void
slf_init_semaphore_down_or_wait (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  AV *av = (AV *)SvRV (arg [0]);

  if (SvIVX (AvARRAY (av)[0]) > 0)
    {
      frame->data    = (void *)av;
      frame->prepare = prepare_nop;
    }
  else
    {
      av_push (av, SvREFCNT_inc (SvRV (coro_current)));

      frame->data    = (void *)sv_2mortal (SvREFCNT_inc ((SV *)av));
      frame->prepare = prepare_schedule;
      /* to avoid race conditions when a woken-up coro gets terminated */
      /* we arrange for a temporary on_destroy that calls adjust (0) */
      frame->destroy = coro_semaphore_destroy;
    }
}

static void
slf_init_semaphore_down (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  slf_init_semaphore_down_or_wait (aTHX_ frame, cv, arg, items);
  frame->check = slf_check_semaphore_down;
}

static void
slf_init_semaphore_wait (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  if (items >= 2)
    {
      /* callback form */
      AV *av = (AV *)SvRV (arg [0]);
      SV *cb_cv = s_get_cv_croak (arg [1]);

      av_push (av, SvREFCNT_inc_NN (cb_cv));

      if (SvIVX (AvARRAY (av)[0]) > 0)
        coro_semaphore_adjust (aTHX_ av, 0);

      frame->prepare = prepare_nop;
      frame->check   = slf_check_nop;
    }
  else
    {
      slf_init_semaphore_down_or_wait (aTHX_ frame, cv, arg, items);
      frame->check = slf_check_semaphore_wait;
    }
}

/* signal */

static void
coro_signal_wake (pTHX_ AV *av, int count)
{
  SvIVX (AvARRAY (av)[0]) = 0;

  /* now signal count waiters */
  while (count > 0 && AvFILLp (av) > 0)
    {
      SV *cb;

      /* swap first two elements so we can shift a waiter */
      cb = AvARRAY (av)[0];
      AvARRAY (av)[0] = AvARRAY (av)[1];
      AvARRAY (av)[1] = cb;

      cb = av_shift (av);

      if (SvTYPE (cb) == SVt_PVCV)
        {
          dSP;
          PUSHMARK (SP);
          XPUSHs (sv_2mortal (newRV_inc ((SV *)av)));
          PUTBACK;
          call_sv (cb, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
        }
      else
        {
          api_ready (aTHX_ cb);
          sv_setiv (cb, 0); /* signal waiter */
        }

      SvREFCNT_dec_NN (cb);

      --count;
    }
}

static int
slf_check_signal_wait (pTHX_ struct CoroSLF *frame)
{
  /* if we are about to throw, also stop waiting */
  return SvROK ((SV *)frame->data) && !CORO_THROW;
}

static void
slf_init_signal_wait (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  AV *av = (AV *)SvRV (arg [0]);

  if (items >= 2)
    {
      SV *cb_cv = s_get_cv_croak (arg [1]);
      av_push (av, SvREFCNT_inc_NN (cb_cv));

      if (SvIVX (AvARRAY (av)[0]))
        coro_signal_wake (aTHX_ av, 1); /* must be the only waiter */

      frame->prepare = prepare_nop;
      frame->check   = slf_check_nop;
    }
  else if (SvIVX (AvARRAY (av)[0]))
    {
      SvIVX (AvARRAY (av)[0]) = 0;
      frame->prepare = prepare_nop;
      frame->check   = slf_check_nop;
    }
  else
    {
      SV *waiter = newSVsv (coro_current); /* owned by signal av */

      av_push (av, waiter);

      frame->data    = (void *)sv_2mortal (SvREFCNT_inc_NN (waiter)); /* owned by process */
      frame->prepare = prepare_schedule;
      frame->check   = slf_check_signal_wait;
    }
}

/*****************************************************************************/
/* Coro::AIO */

#define CORO_MAGIC_type_aio PERL_MAGIC_ext

/* helper storage struct */
struct io_state
{
  int errorno;
  I32 laststype; /* U16 in 5.10.0 */
  int laststatval;
  Stat_t statcache;
};

static void
coro_aio_callback (pTHX_ CV *cv)
{
  dXSARGS;
  AV *state = (AV *)S_GENSUB_ARG;
  SV *coro = av_pop (state);
  SV *data_sv = newSV (sizeof (struct io_state));

  av_extend (state, items - 1);

  sv_upgrade (data_sv, SVt_PV);
  SvCUR_set (data_sv, sizeof (struct io_state));
  SvPOK_only (data_sv);

  {
    struct io_state *data = (struct io_state *)SvPVX (data_sv);

    data->errorno     = errno;
    data->laststype   = PL_laststype;
    data->laststatval = PL_laststatval;
    data->statcache   = PL_statcache;
  }

  /* now build the result vector out of all the parameters and the data_sv */
  {
    int i;

    for (i = 0; i < items; ++i)
      av_push (state, SvREFCNT_inc_NN (ST (i)));
  }

  av_push (state, data_sv);

  api_ready (aTHX_ coro);
  SvREFCNT_dec_NN (coro);
  SvREFCNT_dec_NN ((AV *)state);
}

static int
slf_check_aio_req (pTHX_ struct CoroSLF *frame)
{
  AV *state = (AV *)frame->data;

  /* if we are about to throw, return early */
  /* this does not cancel the aio request, but at least */
  /* it quickly returns */
  if (CORO_THROW)
    return 0;

  /* one element that is an RV? repeat! */
  if (AvFILLp (state) == 0 && SvTYPE (AvARRAY (state)[0]) != SVt_PV)
    return 1;

  /* restore status */
  {
    SV *data_sv = av_pop (state);
    struct io_state *data = (struct io_state *)SvPVX (data_sv);

    errno          = data->errorno;
    PL_laststype   = data->laststype;
    PL_laststatval = data->laststatval;
    PL_statcache   = data->statcache;

    SvREFCNT_dec_NN (data_sv);
  }

  /* push result values */
  {
    dSP;
    int i;

    EXTEND (SP, AvFILLp (state) + 1);
    for (i = 0; i <= AvFILLp (state); ++i)
      PUSHs (sv_2mortal (SvREFCNT_inc_NN (AvARRAY (state)[i])));

    PUTBACK;
  }

  return 0;
}

static void
slf_init_aio_req (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  AV *state = (AV *)sv_2mortal ((SV *)newAV ());
  SV *coro_hv = SvRV (coro_current);
  struct coro *coro = SvSTATE_hv (coro_hv);

  /* put our coroutine id on the state arg */
  av_push (state, SvREFCNT_inc_NN (coro_hv));

  /* first see whether we have a non-zero priority and set it as AIO prio */
  if (coro->prio)
    {
      dSP;

      static SV *prio_cv;
      static SV *prio_sv;

      if (ecb_expect_false (!prio_cv))
        {
          prio_cv = (SV *)get_cv ("IO::AIO::aioreq_pri", 0);
          prio_sv = newSViv (0);
        }

      PUSHMARK (SP);
      sv_setiv (prio_sv, coro->prio);
      XPUSHs (prio_sv);

      PUTBACK;
      call_sv (prio_cv, G_VOID | G_DISCARD);
    }

  /* now call the original request */
  {
    dSP;
    CV *req = (CV *)CORO_MAGIC_NN ((SV *)cv, CORO_MAGIC_type_aio)->mg_obj;
    int i;

    PUSHMARK (SP);

    /* first push all args to the stack */
    EXTEND (SP, items + 1);

    for (i = 0; i < items; ++i)
      PUSHs (arg [i]);

    /* now push the callback closure */
    PUSHs (sv_2mortal (s_gensub (aTHX_ coro_aio_callback, (void *)SvREFCNT_inc_NN ((SV *)state))));

    /* now call the AIO function - we assume our request is uncancelable */
    PUTBACK;
    call_sv ((SV *)req, G_VOID | G_DISCARD);
  }

  /* now that the request is going, we loop till we have a result */
  frame->data    = (void *)state;
  frame->prepare = prepare_schedule;
  frame->check   = slf_check_aio_req;
}

static void
coro_aio_req_xs (pTHX_ CV *cv)
{
  dXSARGS;

  CORO_EXECUTE_SLF_XS (slf_init_aio_req);

  XSRETURN_EMPTY;
}

/*****************************************************************************/

#if CORO_CLONE
# include "clone.c"
#endif

/*****************************************************************************/

static SV *
coro_new (pTHX_ HV *stash, SV **argv, int argc, int is_coro)
{
  SV *coro_sv;
  struct coro *coro;
  MAGIC *mg;
  HV *hv;
  SV *cb;
  int i;

  if (argc > 0)
    {
      cb = s_get_cv_croak (argv [0]);

      if (!is_coro)
        {
          if (CvISXSUB (cb))
            croak ("Coro::State doesn't support XS functions as coroutine start, caught");

          if (!CvROOT (cb))
            croak ("Coro::State doesn't support autoloaded or undefined functions as coroutine start, caught");
        }
    }

  Newz (0, coro, 1, struct coro);
  coro->args  = newAV ();
  coro->flags = CF_NEW;

  if (coro_first) coro_first->prev = coro;
  coro->next = coro_first;
  coro_first = coro;

  coro->hv = hv = newHV ();
  mg = sv_magicext ((SV *)hv, 0, CORO_MAGIC_type_state, &coro_state_vtbl, (char *)coro, 0);
  mg->mg_flags |= MGf_DUP;
  coro_sv = sv_bless (newRV_noinc ((SV *)hv), stash);

  if (argc > 0)
    {
      av_extend (coro->args, argc + is_coro - 1);

      if (is_coro)
        {
          av_push (coro->args, SvREFCNT_inc_NN ((SV *)cb));
          cb = (SV *)cv_coro_run;
        }

      coro->startcv = (CV *)SvREFCNT_inc_NN ((SV *)cb);

      for (i = 1; i < argc; i++)
        av_push (coro->args, newSVsv (argv [i]));
    }

  return coro_sv;
}

#ifndef __cplusplus
ecb_cold XS(boot_Coro__State);
#endif

#if CORO_JIT

static void ecb_noinline ecb_cold
pushav_4uv (pTHX_ UV a, UV b, UV c, UV d)
{
  dSP;
  AV *av = newAV ();

  av_store (av, 3, newSVuv (d));
  av_store (av, 2, newSVuv (c));
  av_store (av, 1, newSVuv (b));
  av_store (av, 0, newSVuv (a));

  XPUSHs (sv_2mortal (newRV_noinc ((SV *)av)));

  PUTBACK;
}

static void ecb_noinline ecb_cold
jit_init (pTHX)
{
  dSP;
  SV *load, *save;
  char *map_base;
  char *load_ptr, *save_ptr;
  STRLEN load_len, save_len, map_len;
  int count;

  eval_pv ("require 'Coro/jit-" CORO_JIT_TYPE ".pl'", 1);

  PUSHMARK (SP);
  #define VARx(name,expr,type) pushav_4uv (aTHX_ (UV)&(expr), sizeof (expr), offsetof (perl_slots, name), sizeof (type));
  #include "state.h"
  count = call_pv ("Coro::State::_jit", G_ARRAY);
  SPAGAIN;

  save = POPs; save_ptr = SvPVbyte (save, save_len);
  load = POPs; load_ptr = SvPVbyte (load, load_len);

  map_len = load_len + save_len + 16;

  map_base = mmap (0, map_len, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

  assert (("Coro: unable to mmap jit code page, cannot continue.", map_base != (char *)MAP_FAILED));

  load_perl_slots = (load_save_perl_slots_type)map_base;
  memcpy (map_base, load_ptr, load_len);

  map_base += (load_len + 15) & ~15;

  save_perl_slots = (load_save_perl_slots_type)map_base;
  memcpy (map_base, save_ptr, save_len);

  /* we are good citizens and try to make the page read-only, so the evil evil */
  /* hackers might have it a bit more difficult */
  mprotect (map_base, map_len, PROT_READ | PROT_EXEC);

  PUTBACK;
  eval_pv ("undef &Coro::State::_jit", 1);
}

#endif

MODULE = Coro::State                PACKAGE = Coro::State	PREFIX = api_

PROTOTYPES: DISABLE

BOOT:
{
#define VARx(name,expr,type) if (sizeof (type) < sizeof (expr)) croak ("FATAL: Coro thread context slot '" # name "' too small for this version of perl.");
#include "state.h"
#ifdef USE_ITHREADS
# if CORO_PTHREAD
        coro_thx = PERL_GET_CONTEXT;
# endif
#endif
        /* perl defines these to check for existance first, but why it doesn't */
        /* just create them one at init time is not clear to me, except for */
        /* programs trying to delete them, but... */
        /* anyway, we declare this as invalid and make sure they are initialised here */
        DEFSV;
        ERRSV;

        cctx_current = cctx_new_empty ();

        irsgv    = gv_fetchpv ("/"     , GV_ADD|GV_NOTQUAL, SVt_PV);
        stdoutgv = gv_fetchpv ("STDOUT", GV_ADD|GV_NOTQUAL, SVt_PVIO);

	{
	  /*
	   * we provide a vtbvl for %SIG magic that replaces PL_vtbl_sig
	   * by coro_sig_vtbl in hash values.
	   */
	  MAGIC *mg = mg_find ((SV *)GvHV (gv_fetchpv ("SIG", GV_ADD | GV_NOTQUAL, SVt_PVHV)), PERL_MAGIC_sig);
	
	  /* this only works if perl doesn't have a vtbl for %SIG */
	  assert (!mg->mg_virtual);
	
	  /*
	   * The irony is that the perl API itself asserts that mg_virtual
	   * must be non-const, yet perl5porters insisted on marking their
	   * vtbls as read-only, just to thwart perl modules from patching
	   * them.
	   */
	  mg->mg_virtual = (MGVTBL *)&coro_sig_vtbl;
	  mg->mg_flags |= MGf_COPY;
	
	  coro_sigelem_vtbl = PL_vtbl_sigelem;
	  coro_sigelem_vtbl.svt_get   = coro_sigelem_get;
	  coro_sigelem_vtbl.svt_set   = coro_sigelem_set;
	  coro_sigelem_vtbl.svt_clear = coro_sigelem_clr;
	}

        rv_diehook  = newRV_inc ((SV *)gv_fetchpv ("Coro::State::diehook" , 0, SVt_PVCV));
        rv_warnhook = newRV_inc ((SV *)gv_fetchpv ("Coro::State::warnhook", 0, SVt_PVCV));

	coro_state_stash = gv_stashpv ("Coro::State", TRUE);

        newCONSTSUB (coro_state_stash, "CC_TRACE"     , newSViv (CC_TRACE));
        newCONSTSUB (coro_state_stash, "CC_TRACE_SUB" , newSViv (CC_TRACE_SUB));
        newCONSTSUB (coro_state_stash, "CC_TRACE_LINE", newSViv (CC_TRACE_LINE));
        newCONSTSUB (coro_state_stash, "CC_TRACE_ALL" , newSViv (CC_TRACE_ALL));

        main_mainstack = PL_mainstack;
        main_top_env   = PL_top_env;

        while (main_top_env->je_prev)
          main_top_env = main_top_env->je_prev;

        {
          SV *slf = sv_2mortal (newSViv (PTR2IV (pp_slf)));

          if (!PL_custom_op_names) PL_custom_op_names = newHV ();
          hv_store_ent (PL_custom_op_names, slf, newSVpv ("coro_slf", 0), 0);

          if (!PL_custom_op_descs) PL_custom_op_descs = newHV ();
          hv_store_ent (PL_custom_op_descs, slf, newSVpv ("coro schedule like function", 0), 0);
        }

        coroapi.ver         = CORO_API_VERSION;
        coroapi.rev         = CORO_API_REVISION;

        coroapi.transfer    = api_transfer;

        coroapi.sv_state             = SvSTATE_;
        coroapi.execute_slf          = api_execute_slf;
        coroapi.prepare_nop          = prepare_nop;
        coroapi.prepare_schedule     = prepare_schedule;
        coroapi.prepare_cede         = prepare_cede;
        coroapi.prepare_cede_notself = prepare_cede_notself;

        time_init (aTHX);

        assert (("PRIO_NORMAL must be 0", !CORO_PRIO_NORMAL));
#if CORO_JIT
	PUTBACK;
	jit_init (aTHX);
        SPAGAIN;
#endif
}

SV *
new (SV *klass, ...)
	ALIAS:
        Coro::new = 1
        CODE:
        RETVAL = coro_new (aTHX_ ix ? coro_stash : coro_state_stash, &ST (1), items - 1, ix);
	OUTPUT:
        RETVAL

void
transfer (...)
        PROTOTYPE: $$
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_transfer);

SV *
clone (Coro::State coro)
	CODE:
{
#if CORO_CLONE
        struct coro *ncoro = coro_clone (aTHX_ coro);
        MAGIC *mg;
        /* TODO: too much duplication */
        ncoro->hv = newHV ();
        mg = sv_magicext ((SV *)ncoro->hv, 0, CORO_MAGIC_type_state, &coro_state_vtbl, (char *)ncoro, 0);
        mg->mg_flags |= MGf_DUP;
        RETVAL = sv_bless (newRV_noinc ((SV *)ncoro->hv), SvSTASH (coro->hv));
#else
        croak ("Coro::State->clone has not been configured into this installation of Coro, realised");
#endif
}
	OUTPUT:
        RETVAL

int
cctx_stacksize (int new_stacksize = 0)
	PROTOTYPE: ;$
	CODE:
        RETVAL = cctx_stacksize;
        if (new_stacksize)
          {
            cctx_stacksize = new_stacksize;
            ++cctx_gen;
          }
	OUTPUT:
        RETVAL

int
cctx_max_idle (int max_idle = 0)
	PROTOTYPE: ;$
	CODE:
        RETVAL = cctx_max_idle;
        if (max_idle > 1)
          cctx_max_idle = max_idle;
	OUTPUT:
        RETVAL

int
cctx_count ()
	PROTOTYPE:
	CODE:
        RETVAL = cctx_count;
	OUTPUT:
        RETVAL

int
cctx_idle ()
	PROTOTYPE:
	CODE:
        RETVAL = cctx_idle;
	OUTPUT:
        RETVAL

void
list ()
	PROTOTYPE:
	PPCODE:
{
	struct coro *coro;
        for (coro = coro_first; coro; coro = coro->next)
          if (coro->hv)
            XPUSHs (sv_2mortal (newRV_inc ((SV *)coro->hv)));
}

void
call (Coro::State coro, SV *coderef)
	ALIAS:
        eval = 1
	CODE:
{
        if (coro->mainstack && ((coro->flags & CF_RUNNING) || coro->slot))
          {
            struct coro *current = SvSTATE_current;
            struct CoroSLF slf_save;

            if (current != coro)
              {
                PUTBACK;
                save_perl (aTHX_ current);
                load_perl (aTHX_ coro);
                /* the coro is most likely in an active SLF call.
                 * while not strictly required (the code we execute is
                 * not allowed to call any SLF functions), it's cleaner
                 * to reinitialise the slf_frame and restore it later.
                 * This might one day allow us to actually do SLF calls
                 * from code executed here.
                 */
                slf_save = slf_frame;
                slf_frame.prepare = 0;
                SPAGAIN;
              }

            PUSHSTACK;

            PUSHMARK (SP);
            PUTBACK;

            if (ix)
              eval_sv (coderef, 0);
            else
              call_sv (coderef, G_KEEPERR | G_EVAL | G_VOID | G_DISCARD);

            POPSTACK;
            SPAGAIN;

            if (current != coro)
              {
                PUTBACK;
                slf_frame = slf_save;
                save_perl (aTHX_ coro);
                load_perl (aTHX_ current);
                SPAGAIN;
              }
          }
}

SV *
is_ready (Coro::State coro)
        PROTOTYPE: $
        ALIAS:
        is_ready     = CF_READY
        is_running   = CF_RUNNING
        is_new       = CF_NEW
        is_destroyed = CF_ZOMBIE
        is_zombie    = CF_ZOMBIE
        is_suspended = CF_SUSPENDED
	CODE:
        RETVAL = boolSV (coro->flags & ix);
	OUTPUT:
        RETVAL

void
throw (SV *self, SV *exception = &PL_sv_undef)
	PROTOTYPE: $;$
        CODE:
{
	struct coro *coro    = SvSTATE (self);
	struct coro *current = SvSTATE_current;
	SV **exceptionp = coro == current ? &CORO_THROW : &coro->except;
        SvREFCNT_dec (*exceptionp);
        SvGETMAGIC (exception);
        *exceptionp = SvOK (exception) ? newSVsv (exception) : 0;

	api_ready (aTHX_ self);
}

void
api_trace (SV *coro, int flags = CC_TRACE | CC_TRACE_SUB)
	PROTOTYPE: $;$
	C_ARGS: aTHX_ coro, flags

SV *
has_cctx (Coro::State coro)
        PROTOTYPE: $
	CODE:
        /* maybe manage the running flag differently */
        RETVAL = boolSV (!!coro->cctx || (coro->flags & CF_RUNNING));
	OUTPUT:
        RETVAL

int
is_traced (Coro::State coro)
        PROTOTYPE: $
	CODE:
        RETVAL = (coro->cctx ? coro->cctx->flags : 0) & CC_TRACE_ALL;
	OUTPUT:
        RETVAL

UV
rss (Coro::State coro)
        PROTOTYPE: $
        ALIAS:
        usecount = 1
        CODE:
        switch (ix)
	  {
            case 0: RETVAL = coro_rss (aTHX_ coro); break;
            case 1: RETVAL = coro->usecount;        break;
          }
	OUTPUT:
        RETVAL

void
force_cctx ()
	PROTOTYPE:
	CODE:
        cctx_current->idle_sp = 0;

void
swap_defsv (Coro::State self)
	PROTOTYPE: $
        ALIAS:
        swap_defav = 1
        CODE:
	if (!self->slot)
          croak ("cannot swap state with coroutine that has no saved state,");
        else
          {
            SV **src = ix ? (SV **)&GvAV (PL_defgv) : &GvSV (PL_defgv);
            SV **dst = ix ? (SV **)&self->slot->defav : (SV **)&self->slot->defsv;

            SV *tmp = *src; *src = *dst; *dst = tmp;
          }

void
cancel (Coro::State self)
	CODE:
	coro_state_destroy (aTHX_ self);

SV *
enable_times (int enabled = enable_times)
	CODE:
{
        RETVAL = boolSV (enable_times);

        if (enabled != enable_times)
          {
            enable_times = enabled;

            coro_times_update ();
            (enabled ? coro_times_sub : coro_times_add)(SvSTATE (coro_current));
          }
}
        OUTPUT:
        RETVAL

void
times (Coro::State self)
	PPCODE:
{
	struct coro *current = SvSTATE (coro_current);

        if (ecb_expect_false (current == self))
          {
            coro_times_update ();
            coro_times_add (SvSTATE (coro_current));
          }

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVnv (self->t_real [0] + self->t_real [1] * 1e-9)));
        PUSHs (sv_2mortal (newSVnv (self->t_cpu  [0] + self->t_cpu  [1] * 1e-9)));

        if (ecb_expect_false (current == self))
          coro_times_sub (SvSTATE (coro_current));
}

void
swap_sv (Coro::State coro, SV *sva, SV *svb)
	CODE:
{
        struct coro *current = SvSTATE_current;
        AV *swap_sv;
        int i;

        sva = SvRV (sva);
        svb = SvRV (svb);

        if (current == coro)
          SWAP_SVS_LEAVE (current);

        if (!coro->swap_sv)
          coro->swap_sv = newAV ();

        swap_sv = coro->swap_sv;

        for (i = AvFILLp (swap_sv) - 1; i >= 0; i -= 2)
          {
            SV *a = AvARRAY (swap_sv)[i    ];
            SV *b = AvARRAY (swap_sv)[i + 1];

            if (a == sva && b == svb)
              {
                SvREFCNT_dec_NN (a);
                SvREFCNT_dec_NN (b);

                for (; i <= AvFILLp (swap_sv) - 2; i++)
                  AvARRAY (swap_sv)[i] = AvARRAY (swap_sv)[i + 2];

                AvFILLp (swap_sv) -= 2;

                goto removed;
              }
          }

        av_push (swap_sv, SvREFCNT_inc_NN (sva));
        av_push (swap_sv, SvREFCNT_inc_NN (svb));

	removed:

        if (current == coro)
          SWAP_SVS_ENTER (current);
}


MODULE = Coro::State                PACKAGE = Coro

BOOT:
{
	if (SVt_LAST > 32)
          croak ("Coro internal error: SVt_LAST > 32, swap_sv might need adjustment");

        sv_pool_rss        = coro_get_sv (aTHX_ "Coro::POOL_RSS"  , TRUE);
        sv_pool_size       = coro_get_sv (aTHX_ "Coro::POOL_SIZE" , TRUE);
        cv_coro_run        =      get_cv (      "Coro::_coro_run" , GV_ADD);
        coro_current       = coro_get_sv (aTHX_ "Coro::current"   , FALSE); SvREADONLY_on (coro_current);
        av_async_pool      = coro_get_av (aTHX_ "Coro::async_pool", TRUE);
        av_destroy         = coro_get_av (aTHX_ "Coro::destroy"   , TRUE);
        sv_manager         = coro_get_sv (aTHX_ "Coro::manager"   , TRUE);
        sv_idle            = coro_get_sv (aTHX_ "Coro::idle"      , TRUE);

        sv_async_pool_idle = newSVpv ("[async pool idle]", 0); SvREADONLY_on (sv_async_pool_idle);
        sv_Coro            = newSVpv ("Coro", 0); SvREADONLY_on (sv_Coro);
        cv_pool_handler    = get_cv ("Coro::pool_handler", GV_ADD); SvREADONLY_on (cv_pool_handler);
        CvNODEBUG_on (get_cv ("Coro::_pool_handler", 0)); /* work around a debugger bug */

	coro_stash = gv_stashpv ("Coro", TRUE);

        newCONSTSUB (coro_stash, "PRIO_MAX",    newSViv (CORO_PRIO_MAX));
        newCONSTSUB (coro_stash, "PRIO_HIGH",   newSViv (CORO_PRIO_HIGH));
        newCONSTSUB (coro_stash, "PRIO_NORMAL", newSViv (CORO_PRIO_NORMAL));
        newCONSTSUB (coro_stash, "PRIO_LOW",    newSViv (CORO_PRIO_LOW));
        newCONSTSUB (coro_stash, "PRIO_IDLE",   newSViv (CORO_PRIO_IDLE));
        newCONSTSUB (coro_stash, "PRIO_MIN",    newSViv (CORO_PRIO_MIN));

        {
          SV *sv = coro_get_sv (aTHX_ "Coro::API", TRUE);

          coroapi.schedule     = api_schedule;
          coroapi.schedule_to  = api_schedule_to;
          coroapi.cede         = api_cede;
          coroapi.cede_notself = api_cede_notself;
          coroapi.ready        = api_ready;
          coroapi.is_ready     = api_is_ready;
          coroapi.nready       = coro_nready;
          coroapi.current      = coro_current;

          coroapi.enterleave_hook       = api_enterleave_hook;
          coroapi.enterleave_unhook     = api_enterleave_unhook;
          coroapi.enterleave_scope_hook = api_enterleave_scope_hook;

          /*GCoroAPI = &coroapi;*/
          sv_setiv (sv, (IV)&coroapi);
          SvREADONLY_on (sv);
        }
}

SV *
async (...)
	PROTOTYPE: &@
        CODE:
        RETVAL = coro_new (aTHX_ coro_stash, &ST (0), items, 1);
        api_ready (aTHX_ RETVAL);
	OUTPUT:
        RETVAL

void
_destroy (Coro::State coro)
	CODE:
	/* used by the manager thread */
	coro_state_destroy (aTHX_ coro);

void
on_destroy (Coro::State coro, SV *cb)
	CODE:
        coro_push_on_destroy (aTHX_ coro, newSVsv (cb));

void
join (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_join);

void
terminate (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_terminate);

void
cancel (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_cancel);

int
safe_cancel (Coro::State self, ...)
	C_ARGS: aTHX_ self, &ST (1), items - 1

void
schedule (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_schedule);

void
schedule_to (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_schedule_to);

void
cede_to (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_cede_to);

void
cede (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_cede);

void
cede_notself (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_cede_notself);

void
_set_current (SV *current)
        PROTOTYPE: $
	CODE:
        SvREFCNT_dec_NN (SvRV (coro_current));
        SvRV_set (coro_current, SvREFCNT_inc_NN (SvRV (current)));

void
_set_readyhook (SV *hook)
	PROTOTYPE: $
        CODE:
        SvREFCNT_dec (coro_readyhook);
        SvGETMAGIC (hook);
        if (SvOK (hook))
	  {
            coro_readyhook = newSVsv (hook);
            CORO_READYHOOK = invoke_sv_ready_hook_helper;
          }
	else
          {
            coro_readyhook = 0;
            CORO_READYHOOK = 0;
          }

int
prio (Coro::State coro, int newprio = 0)
	PROTOTYPE: $;$
        ALIAS:
        nice = 1
        CODE:
{
        RETVAL = coro->prio;

        if (items > 1)
          {
            if (ix)
              newprio = coro->prio - newprio;

            if (newprio < CORO_PRIO_MIN) newprio = CORO_PRIO_MIN;
            if (newprio > CORO_PRIO_MAX) newprio = CORO_PRIO_MAX;

            coro->prio = newprio;
          }
}
	OUTPUT:
        RETVAL

SV *
ready (SV *self)
        PROTOTYPE: $
	CODE:
        RETVAL = boolSV (api_ready (aTHX_ self));
	OUTPUT:
        RETVAL

int
nready (...)
	PROTOTYPE:
        CODE:
        RETVAL = coro_nready;
	OUTPUT:
        RETVAL

void
suspend (Coro::State self)
	PROTOTYPE: $
	CODE:
        self->flags |= CF_SUSPENDED;

void
resume (Coro::State self)
	PROTOTYPE: $
	CODE:
        self->flags &= ~CF_SUSPENDED;

void
_pool_handler (...)
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_pool_handler);

void
async_pool (SV *cv, ...)
	PROTOTYPE: &@
        PPCODE:
{
	HV *hv = (HV *)av_pop (av_async_pool);
        AV *av = newAV ();
        SV *cb = ST (0);
        int i;

        av_extend (av, items - 2);
        for (i = 1; i < items; ++i)
          av_push (av, SvREFCNT_inc_NN (ST (i)));

        if ((SV *)hv == &PL_sv_undef)
          {
            SV *sv = coro_new (aTHX_ coro_stash, (SV **)&cv_pool_handler, 1, 1);
            hv = (HV *)SvREFCNT_inc_NN (SvRV (sv));
            SvREFCNT_dec_NN (sv);
          }

        {
          struct coro *coro = SvSTATE_hv (hv);

          assert (!coro->invoke_cb);
          assert (!coro->invoke_av);
          coro->invoke_cb = SvREFCNT_inc (cb);
          coro->invoke_av = av;
        }

        api_ready (aTHX_ (SV *)hv);

        if (GIMME_V != G_VOID)
          XPUSHs (sv_2mortal (newRV_noinc ((SV *)hv)));
        else
          SvREFCNT_dec_NN (hv);
}

SV *
rouse_cb ()
        PROTOTYPE:
	CODE:
        RETVAL = coro_new_rouse_cb (aTHX);
	OUTPUT:
        RETVAL

void
rouse_wait (...)
        PROTOTYPE: ;$
	PPCODE:
        CORO_EXECUTE_SLF_XS (slf_init_rouse_wait);

void
on_enter (SV *block)
	ALIAS:
        on_leave = 1
	PROTOTYPE: &
	CODE:
{
	struct coro *coro = SvSTATE_current;
	AV **avp = ix ? &coro->on_leave : &coro->on_enter;

        block = s_get_cv_croak (block);

        if (!*avp)
          *avp = newAV ();

        av_push (*avp, SvREFCNT_inc (block));

        if (!ix)
          on_enterleave_call (aTHX_ block);

        LEAVE; /* pp_entersub unfortunately forces an ENTER/LEAVE around XS calls */
        SAVEDESTRUCTOR_X (ix ? coro_pop_on_leave : coro_pop_on_enter, (void *)coro);
        ENTER; /* pp_entersub unfortunately forces an ENTER/LEAVE around XS calls */
}


MODULE = Coro::State                PACKAGE = PerlIO::cede

BOOT:
	PerlIO_define_layer (aTHX_ &PerlIO_cede);


MODULE = Coro::State                PACKAGE = Coro::Semaphore

SV *
new (SV *klass, SV *count = 0)
	CODE:
{
	int semcnt = 1;

        if (count)
          {
            SvGETMAGIC (count);

            if (SvOK (count))
              semcnt = SvIV (count);
          }

        RETVAL = sv_bless (
                   coro_waitarray_new (aTHX_ semcnt),
                   GvSTASH (CvGV (cv))
                 );
}
	OUTPUT:
        RETVAL

# helper for Coro::Channel and others
SV *
_alloc (int count)
	CODE:
        RETVAL = coro_waitarray_new (aTHX_ count);
	OUTPUT:
        RETVAL

SV *
count (SV *self)
	CODE:
        RETVAL = newSVsv (AvARRAY ((AV *)SvRV (self))[0]);
	OUTPUT:
        RETVAL

void
up (SV *self)
        CODE:
        coro_semaphore_adjust (aTHX_ (AV *)SvRV (self), 1);

void
adjust (SV *self, int adjust)
        CODE:
        coro_semaphore_adjust (aTHX_ (AV *)SvRV (self), adjust);

void
down (...)
        CODE:
        CORO_EXECUTE_SLF_XS (slf_init_semaphore_down);

void
wait (...)
        CODE:
        CORO_EXECUTE_SLF_XS (slf_init_semaphore_wait);

void
try (SV *self)
        PPCODE:
{
        AV *av = (AV *)SvRV (self);
        SV *count_sv = AvARRAY (av)[0];
        IV count = SvIVX (count_sv);

        if (count > 0)
          {
            --count;
            SvIVX (count_sv) = count;
            XSRETURN_YES;
          }
        else
          XSRETURN_NO;
}

void
waiters (SV *self)
	PPCODE:
{
        AV *av = (AV *)SvRV (self);
        int wcount = AvFILLp (av) + 1 - 1;

        if (GIMME_V == G_SCALAR)
          XPUSHs (sv_2mortal (newSViv (wcount)));
        else
          {
            int i;
            EXTEND (SP, wcount);
            for (i = 1; i <= wcount; ++i)
              PUSHs (sv_2mortal (newRV_inc (AvARRAY (av)[i])));
          }
}

MODULE = Coro::State                PACKAGE = Coro::SemaphoreSet

void
_may_delete (SV *sem, int count, unsigned int extra_refs)
	PPCODE:
{
	AV *av = (AV *)SvRV (sem);

        if (SvREFCNT ((SV *)av) == 1 + extra_refs
            && AvFILLp (av) == 0 /* no waiters, just count */
            && SvIV (AvARRAY (av)[0]) == count)
          XSRETURN_YES;

        XSRETURN_NO;
}

MODULE = Coro::State                PACKAGE = Coro::Signal

SV *
new (SV *klass)
	CODE:
        RETVAL = sv_bless (
                   coro_waitarray_new (aTHX_ 0),
                   GvSTASH (CvGV (cv))
                 );
        OUTPUT:
        RETVAL

void
wait (...)
        CODE:
        CORO_EXECUTE_SLF_XS (slf_init_signal_wait);

void
broadcast (SV *self)
        CODE:
{
	AV *av = (AV *)SvRV (self);
        coro_signal_wake (aTHX_ av, AvFILLp (av));
}

void
send (SV *self)
        CODE:
{
	AV *av = (AV *)SvRV (self);

        if (AvFILLp (av))
          coro_signal_wake (aTHX_ av, 1);
        else
          SvIVX (AvARRAY (av)[0]) = 1; /* remember the signal */
}

IV
awaited (SV *self)
	CODE:
        RETVAL = AvFILLp ((AV *)SvRV (self)) + 1 - 1;
	OUTPUT:
        RETVAL


MODULE = Coro::State                PACKAGE = Coro::AnyEvent

BOOT:
        sv_activity = coro_get_sv (aTHX_ "Coro::AnyEvent::ACTIVITY", TRUE);

void
_schedule (...)
	CODE:
{
	static int incede;

        api_cede_notself (aTHX);

        ++incede;
        while (coro_nready >= incede && api_cede (aTHX))
          ;

        sv_setsv (sv_activity, &PL_sv_undef);
        if (coro_nready >= incede)
          {
            PUSHMARK (SP);
            PUTBACK;
            call_pv ("Coro::AnyEvent::_activity", G_KEEPERR | G_EVAL | G_VOID | G_DISCARD);
          }

        --incede;
}


MODULE = Coro::State                PACKAGE = Coro::AIO

void
_register (char *target, char *proto, SV *req)
	CODE:
{
        SV *req_cv = s_get_cv_croak (req);
        /* newXSproto doesn't return the CV on 5.8 */
        CV *slf_cv = newXS (target, coro_aio_req_xs, __FILE__);
        sv_setpv ((SV *)slf_cv, proto);
        sv_magicext ((SV *)slf_cv, (SV *)req_cv, CORO_MAGIC_type_aio, 0, 0, 0);
}

MODULE = Coro::State                PACKAGE = Coro::Select

void
patch_pp_sselect ()
	CODE:
        if (!coro_old_pp_sselect)
          {
            coro_select_select = (SV *)get_cv ("Coro::Select::select", 0);
            coro_old_pp_sselect = PL_ppaddr [OP_SSELECT];
            PL_ppaddr [OP_SSELECT] = coro_pp_sselect;
          }

void
unpatch_pp_sselect ()
	CODE:
        if (coro_old_pp_sselect)
          {
            PL_ppaddr [OP_SSELECT] = coro_old_pp_sselect;
            coro_old_pp_sselect = 0;
          }

MODULE = Coro::State                PACKAGE = Coro::Util

void
_exit (int code)
	CODE:
	_exit (code);

NV
time ()
	CODE:
        RETVAL = nvtime (aTHX);
	OUTPUT:
        RETVAL

NV
gettimeofday ()
	PPCODE:
{
        UV tv [2];
        u2time (aTHX_ tv);
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVuv (tv [0])));
        PUSHs (sv_2mortal (newSVuv (tv [1])));
}

