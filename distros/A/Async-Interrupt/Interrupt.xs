#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define ECB_NO_LIBM 1
#define ECB_NO_THREADS 1
#include "ecb.h"
#include "schmorp.h"

typedef volatile sig_atomic_t atomic_t;

static int *sig_pending, *psig_pend; /* make local copies because of missing THX */
static Sighandler_t old_sighandler;
static atomic_t async_pending;

#define PERL_VERSION_ATLEAST(a,b,c)                             \
  (PERL_REVISION > (a)                                          \
   || (PERL_REVISION == (a)                                     \
       && (PERL_VERSION > (b)                                   \
           || (PERL_VERSION == (b) && PERL_SUBVERSION >= (c)))))

#if defined(HAS_SIGACTION) && defined(SA_SIGINFO)
# define HAS_SA_SIGINFO 1
#endif

#if !PERL_VERSION_ATLEAST(5,10,0)
# undef HAS_SA_SIGINFO
#endif

/*****************************************************************************/

typedef struct {
  SV *cb;
  void (*c_cb)(pTHX_ void *c_arg, int value);
  void *c_arg;
  SV *fh_r, *fh_w;
  SV *value;
  int signum;
  int autodrain;
  ANY *scope_savestack;
  volatile int blocked;

  s_epipe ep;
  int fd_wlen;
  atomic_t fd_enable;
  atomic_t pending;
  volatile IV *valuep;
  atomic_t hysteresis;
} async_t;

static AV *asyncs;
static async_t *sig_async [SIG_SIZE];

#define SvASYNC_nrv(sv) INT2PTR (async_t *, SvIVX (sv))
#define SvASYNC(rv)     SvASYNC_nrv (SvRV (rv))

static void async_signal (void *signal_arg, int value);

static void
setsig (int signum, void (*handler)(int))
{
#if _WIN32
  signal (signum, handler);
#else
  struct sigaction sa;
  sa.sa_handler = handler;
  sigfillset (&sa.sa_mask);
  sa.sa_flags = 0; /* if we interrupt a syscall, we might drain the pipe before it became ready */
  sigaction (signum, &sa, 0);
#endif
}

static void
async_sigsend (int signum)
{
  async_signal (sig_async [signum], 0);
}

/* the main workhorse to signal */
static void
async_signal (void *signal_arg, int value)
{
  static char pipedata [8];

  async_t *async = (async_t *)signal_arg;
  int pending = async->pending;

  if (async->hysteresis)
    setsig (async->signum, SIG_IGN);

  *async->valuep = value ? value : 1;
  ECB_MEMORY_FENCE_RELEASE;
  async->pending = 1;
  ECB_MEMORY_FENCE_RELEASE;
  async_pending  = 1;
  ECB_MEMORY_FENCE_RELEASE;

  if (!async->blocked)
    {
      psig_pend [9]  = 1;
      ECB_MEMORY_FENCE_RELEASE;
      *sig_pending   = 1;
      ECB_MEMORY_FENCE_RELEASE;
    }

  if (!pending && async->fd_enable && async->ep.len)
    s_epipe_signal (&async->ep);
}

static void
handle_async (async_t *async)
{
  int old_errno = errno;
  int value = *async->valuep;

  *async->valuep = 0;
  async->pending = 0;

  /* restore signal */
  if (async->hysteresis)
    setsig (async->signum, async_sigsend);

  /* drain pipe */
  if (async->fd_enable && async->ep.len && async->autodrain)
    s_epipe_drain (&async->ep);

  if (async->c_cb)
    {
      dTHX;
      async->c_cb (aTHX_ async->c_arg, value);
    }

  if (async->cb)
    {
      dSP;

      SV *saveerr = SvOK (ERRSV) ? sv_mortalcopy (ERRSV) : 0;
      SV *savedie = PL_diehook;

      PL_diehook = 0;

      PUSHSTACKi (PERLSI_SIGNAL);

      PUSHMARK (SP);
      XPUSHs (sv_2mortal (newSViv (value)));
      PUTBACK;
      call_sv (async->cb, G_VOID | G_DISCARD | G_EVAL);

      if (SvTRUE (ERRSV))
        {
          SPAGAIN;

          PUSHMARK (SP);
          PUTBACK;
          call_sv (get_sv ("Async::Interrupt::DIED", 1), G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);

          sv_setpvn (ERRSV, "", 0);
        }

      if (saveerr)
        sv_setsv (ERRSV, saveerr);

      {
        SV *oldhook = PL_diehook;
        PL_diehook = savedie;
        SvREFCNT_dec (oldhook);
      }

      POPSTACK;
    }

  errno = old_errno;
}

static void
handle_asyncs (void)
{
  int i;

  ECB_MEMORY_FENCE_ACQUIRE;

  async_pending = 0;

  for (i = AvFILLp (asyncs); i >= 0; --i)
    {
      SV *async_sv = AvARRAY (asyncs)[i];
      async_t *async = SvASYNC_nrv (async_sv);

      if (async->pending && !async->blocked)
        {
          /* temporarily keep a refcount */
          SvREFCNT_inc (async_sv);
          handle_async (async);
          SvREFCNT_dec (async_sv);

          /* the handler could have deleted any number of asyncs */
          if (i > AvFILLp (asyncs))
            i = AvFILLp (asyncs);
        }
    }
}

#if HAS_SA_SIGINFO && !PERL_VERSION_ATLEAST(5, 31, 6)
static Signal_t async_sighandler (int signum, siginfo_t *si, void *sarg)
{
  if (signum == 9)
    handle_asyncs ();
  else
    old_sighandler (signum, si, sarg);
}
#else
static Signal_t async_sighandler (int signum)
{
  if (signum == 9)
    handle_asyncs ();
  else
    old_sighandler (signum);
}
#endif

#define block(async) ++(async)->blocked

static void
unblock (async_t *async)
{
  --async->blocked;
  if (async->pending && !async->blocked)
    handle_async (async);
}

static void
scope_block_cb (pTHX_ void *async_sv)
{
  async_t *async = SvASYNC_nrv ((SV *)async_sv);

  async->scope_savestack = 0;
  unblock (async);
  SvREFCNT_dec (async_sv);
}

static void
scope_block (SV *async_sv)
{
  async_t *async = SvASYNC_nrv (async_sv);

  /* as a heuristic, we skip the scope block if we already are blocked */
  /* and the existing scope block used the same savestack */

  if (!async->scope_savestack || async->scope_savestack != PL_savestack)
    {
      async->scope_savestack = PL_savestack;
      block (async);

      LEAVE; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */
      SAVEDESTRUCTOR_X (scope_block_cb, (void *)SvREFCNT_inc (async_sv));
      ENTER; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */
    }
}

MODULE = Async::Interrupt		PACKAGE = Async::Interrupt

BOOT:
	old_sighandler = PL_sighandlerp;
        PL_sighandlerp = async_sighandler;
        sig_pending = &PL_sig_pending;
        psig_pend   = PL_psig_pend;
        asyncs      = newAV ();
        CvNODEBUG_on (get_cv ("Async::Interrupt::scope_block", 0)); /* otherwise calling scope can be the debugger */

PROTOTYPES: DISABLE

void
_alloc (SV *cb, void *c_cb, void *c_arg, SV *fh_r, SV *fh_w, SV *signl, SV *pvalue)
	PPCODE:
{
        SV *cv   = SvOK (cb) ? SvREFCNT_inc (s_get_cv_croak (cb)) : 0;
	async_t *async;

        Newz (0, async, 1, async_t);

        XPUSHs (sv_2mortal (newSViv (PTR2IV (async))));
        /* TODO: need to bless right now to ensure deallocation */
        av_push (asyncs, TOPs);

        SvGETMAGIC (fh_r); SvGETMAGIC (fh_w);
        if (SvOK (fh_r) || SvOK (fh_w))
          {
            int fd_r = s_fileno_croak (fh_r, 0);
            int fd_w = s_fileno_croak (fh_w, 1);

            async->fh_r      = newSVsv (fh_r);
            async->fh_w      = newSVsv (fh_w);
            async->ep.fd [0] = fd_r;
            async->ep.fd [1] = fd_w;
            async->ep.len    = 1;
            async->fd_enable = 1;
          }

        async->value     = SvROK (pvalue)
                           ? SvREFCNT_inc_NN (SvRV (pvalue))
                           : NEWSV (0, 0);

        sv_setiv (async->value, 0);
        SvIOK_only (async->value); /* just to be sure */
        SvREADONLY_on (async->value);

        async->valuep    = &(SvIVX (async->value));

        async->autodrain = 1;
        async->cb        = cv;
        async->c_cb      = c_cb;
        async->c_arg     = c_arg;
        async->signum    = SvOK (signl) ? s_signum_croak (signl) : 0;

        if (async->signum)
          {
            if (async->signum < 0)
              croak ("Async::Interrupt::new got passed illegal signal name or number: %s", SvPV_nolen (signl));

            sig_async [async->signum] = async;
            setsig (async->signum, async_sigsend);
          }
}

void
signal_hysteresis (async_t *async, int enable)
	CODE:
        async->hysteresis = enable;

void
signal_func (async_t *async)
	PPCODE:
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSViv (PTR2IV (async_signal))));
        PUSHs (sv_2mortal (newSViv (PTR2IV (async))));

void
scope_block_func (SV *self)
	PPCODE:
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSViv (PTR2IV (scope_block))));
        PUSHs (sv_2mortal (newSViv (PTR2IV (SvRV (self)))));

IV
c_var (async_t *async)
	CODE:
        RETVAL = PTR2IV (async->valuep);
	OUTPUT:
        RETVAL

void
handle (async_t *async)
	CODE:
        handle_async (async);

void
signal (async_t *async, int value = 1)
	CODE:
        async_signal (async, value);

void
block (async_t *async)
	CODE:
        block (async);

void
unblock (async_t *async)
	CODE:
        unblock (async);

void
scope_block (SV *self)
	CODE:
        scope_block (SvRV (self));

void
pipe_enable (async_t *async)
	ALIAS:
        pipe_enable  = 1
        pipe_disable = 0
	CODE:
        async->fd_enable = ix;

int
pipe_fileno (async_t *async)
	CODE:
        if (!async->ep.len)
          {
            int res;

            /*block (async);*//*TODO*/
            res = s_epipe_new (&async->ep);
            async->fd_enable = 1;
            /*unblock (async);*//*TODO*/

            if (res < 0)
              croak ("Async::Interrupt: unable to initialize event pipe");
          }

	RETVAL = async->ep.fd [0];
	OUTPUT:
        RETVAL

int
pipe_autodrain (async_t *async, int enable = -1)
	CODE:
	RETVAL = async->autodrain;
        if (enable >= 0)
          async->autodrain = enable;
	OUTPUT:
        RETVAL

void
pipe_drain (async_t *async)
	CODE:
        if (async->ep.len)
          s_epipe_drain (&async->ep);

void
post_fork (async_t *async)
	CODE:
        if (async->ep.len)
          {
	    int res;

            /*block (async);*//*TODO*/
            res = s_epipe_renew (&async->ep);
            /*unblock (async);*//*TODO*/

            if (res < 0)
              croak ("Async::Interrupt: unable to initialize event pipe after fork");
          }

void
DESTROY (SV *self)
	CODE:
{
	int i;
	SV *async_sv = SvRV (self);
	async_t *async = SvASYNC_nrv (async_sv);

        for (i = AvFILLp (asyncs); i >= 0; --i)
          if (AvARRAY (asyncs)[i] == async_sv)
            {
              AvARRAY (asyncs)[i] = AvARRAY (asyncs)[AvFILLp (asyncs)];
              av_pop (asyncs);
              goto found;
            }

        if (!PL_dirty)
          warn ("Async::Interrupt::DESTROY could not find async object in list of asyncs, please report");

	found:

        if (async->signum)
          setsig (async->signum, SIG_DFL);

        if (!async->fh_r && async->ep.len)
          s_epipe_destroy (&async->ep);

        SvREFCNT_dec (async->fh_r);
        SvREFCNT_dec (async->fh_w);
        SvREFCNT_dec (async->cb);
        SvREFCNT_dec (async->value);

        Safefree (async);
}

SV *
sig2num (SV *signame_or_number)
	ALIAS:
        sig2num  = 0
        sig2name = 1
        PROTOTYPE: $
	CODE:
{
  	int signum = s_signum (signame_or_number);

        if (signum < 0)
          RETVAL = &PL_sv_undef;
        else if (ix)
          RETVAL = newSVpv (PL_sig_name [signum], 0);
        else
          RETVAL = newSViv (signum);
}
        OUTPUT:
        RETVAL

MODULE = Async::Interrupt		PACKAGE = Async::Interrupt::EventPipe		PREFIX = s_epipe_

void
new (const char *klass)
	PPCODE:
{
	s_epipe *epp;

        Newz (0, epp, 1, s_epipe);
        XPUSHs (sv_setref_iv (sv_newmortal (), klass, PTR2IV (epp)));

        if (s_epipe_new (epp) < 0)
          croak ("Async::Interrupt::EventPipe: unable to create new event pipe");
}

void
filenos (s_epipe *epp)
	PPCODE:
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSViv (epp->fd [0])));
        PUSHs (sv_2mortal (newSViv (epp->fd [1])));

int
fileno (s_epipe *epp)
	ALIAS:
        fileno   = 0
        fileno_r = 0
        fileno_w = 1
	CODE:
        RETVAL = epp->fd [ix];
	OUTPUT:
        RETVAL

int
type (s_epipe *epp)
	CODE:
        RETVAL = epp->len;
	OUTPUT:
        RETVAL

void
s_epipe_signal (s_epipe *epp)

void
s_epipe_drain (s_epipe *epp)

void
signal_func (s_epipe *epp)
	ALIAS:
        drain_func = 1
	PPCODE:
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSViv (PTR2IV (ix ? s_epipe_drain : s_epipe_signal))));
        PUSHs (sv_2mortal (newSViv (PTR2IV (epp))));

void
s_epipe_wait (s_epipe *epp)

void
s_epipe_renew (s_epipe *epp)

void
DESTROY (s_epipe *epp)
	CODE:
        s_epipe_destroy (epp);

