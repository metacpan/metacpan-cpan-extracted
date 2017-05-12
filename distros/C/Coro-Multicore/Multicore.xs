#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define X_STACKSIZE 1024 * sizeof (void *)

#include "CoroAPI.h"
#include "perlmulticore.h"
#include "schmorp.h"
#include "xthread.h"

#ifdef _WIN32
  typedef char sigset_t;
  #define pthread_sigmask(mode,new,old)
#endif

#ifndef SvREFCNT_dec_NN
  #define SvREFCNT_dec_NN(sv) SvREFCNT_dec (sv)
#endif

#ifndef SvREFCNT_inc_NN
  #define SvREFCNT_inc_NN(sv) SvREFCNT_inc (sv)
#endif

static pthread_key_t current_key;

static s_epipe ep;
static void *perl_thx;
static sigset_t cursigset, fullsigset;

static int global_enable = 0;
static int thread_enable; /* 0 undefined, 1 disabled, 2 enabled */

/* assigned to a thread for each release/acquire */
struct tctx
{
  void *coro;
  int wait_f;
  xcond_t wait_c;
};

static struct tctx *tctx_free;

static int idle;
static int min_idle = 1;

static xmutex_t perl_m = X_MUTEX_INIT;
static xcond_t perl_c = X_COND_INIT;
static struct tctx *perl_f;

static xmutex_t wait_m = X_MUTEX_INIT;

static int wakeup_f;
static struct tctx **waiters;
static int waiters_count, waiters_max;

static struct tctx *
tctx_get (void)
{
  struct tctx *ctx;

  if (!tctx_free)
    {
      ctx = malloc (sizeof (*tctx_free));
      X_COND_CREATE (ctx->wait_c);
    }
  else
    {
      ctx = tctx_free;
      tctx_free = tctx_free->coro;
    }

  return ctx;
}

static void
tctx_put (struct tctx *ctx)
{
  ctx->coro = tctx_free;
  tctx_free = ctx;
}

X_THREAD_PROC(thread_proc)
{
  PERL_SET_CONTEXT (perl_thx);

  {
    dTHX; /* inefficient, we already have perl_thx, but I see no better way */
    struct tctx *ctx;

    X_LOCK (perl_m);

    for (;;)
      {
        while (!perl_f)
          if (idle <= min_idle || 1)
            X_COND_WAIT (perl_c, perl_m);
          else
            {
              struct timespec ts = { time (0) + idle - min_idle, 0 };

              if (X_COND_TIMEDWAIT (perl_c, perl_m, ts) == ETIMEDOUT)
                if (idle > min_idle && !perl_f)
                  break;
            }

        ctx = perl_f;
        perl_f = 0;
        --idle;
        X_UNLOCK (perl_m);

        if (!ctx) /* timed out? */
          break;

        pthread_sigmask (SIG_SETMASK, &cursigset, 0);

        while (ctx->coro)
          CORO_SCHEDULE;

        pthread_sigmask (SIG_SETMASK, &fullsigset, &cursigset);

        X_LOCK (wait_m);
        ctx->wait_f = 1;
        X_COND_SIGNAL (ctx->wait_c);
        X_UNLOCK (wait_m);

        X_LOCK (perl_m);
        ++idle;
      }
  }
}

static void
start_thread (void)
{
  xthread_t tid;

  ++idle;
  xthread_create (&tid, thread_proc, 0);
}

static void
pmapi_release (void)
{
  if (!(thread_enable ? thread_enable & 1 : global_enable))
    {
      pthread_setspecific (current_key, 0);
      return;
    }

  struct tctx *ctx = tctx_get ();
  ctx->coro = SvREFCNT_inc_NN (CORO_CURRENT);
  ctx->wait_f = 0;

  pthread_setspecific (current_key, ctx);
  pthread_sigmask (SIG_SETMASK, &fullsigset, &cursigset);

  X_LOCK (perl_m);

  if (idle <= min_idle)
    start_thread ();

  perl_f = ctx;
  X_COND_SIGNAL (perl_c);

  X_UNLOCK (perl_m);
}

static void
pmapi_acquire (void)
{
  struct tctx *ctx = pthread_getspecific (current_key);

  if (!ctx)
    return;

  X_LOCK (wait_m);

  if (waiters_count >= waiters_max)
    {
      waiters_max = waiters_max ? waiters_max * 2 : 16;
      waiters = realloc (waiters, waiters_max * sizeof (*waiters));
    }

  waiters [waiters_count++] = ctx;

  s_epipe_signal (&ep);
  while (!ctx->wait_f)
    X_COND_WAIT (ctx->wait_c, wait_m);
  X_UNLOCK (wait_m);

  tctx_put (ctx);
  pthread_sigmask (SIG_SETMASK, &cursigset, 0);
}

static void
set_thread_enable (pTHX_ void *arg)
{
  thread_enable = PTR2IV (arg);
}

MODULE = Coro::Multicore		PACKAGE = Coro::Multicore

PROTOTYPES: DISABLE

BOOT:
{
	#ifndef _WIN32
	sigfillset (&fullsigset);
	#endif

        pthread_key_create (&current_key, 0);

        if (s_epipe_new (&ep))
          croak ("Coro::Multicore: unable to initialise event pipe.\n");

        perl_thx = PERL_GET_CONTEXT;

	I_CORO_API ("Coro::Multicore");

        X_LOCK (perl_m);
        while (idle < min_idle)
          start_thread ();
        start_thread ();//D
        X_UNLOCK (perl_m);

        /* not perfectly efficient to do it this way, but it's simple */
	perl_multicore_init ();
        perl_multicore_api->pmapi_release = pmapi_release;
        perl_multicore_api->pmapi_acquire = pmapi_acquire;
}

bool
enable (bool enable = NO_INIT)
	CODE:
        RETVAL = global_enable;
        if (items)
          global_enable = enable;
        OUTPUT:
        RETVAL

void
scoped_enable ()
	CODE:
        LEAVE; /* see Guard.xs */
        CORO_ENTERLEAVE_SCOPE_HOOK (set_thread_enable, (void *)1, set_thread_enable, (void *)0);
        ENTER; /* see Guard.xs */

void
scoped_disable ()
	CODE:
        LEAVE; /* see Guard.xs */
        CORO_ENTERLEAVE_SCOPE_HOOK (set_thread_enable, (void *)2, set_thread_enable, (void *)0);
        ENTER; /* see Guard.xs */

U32
min_idle_threads (U32 min = NO_INIT)
	CODE:
        X_LOCK (wait_m);
        RETVAL = min_idle;
        if (items)
	  min_idle = min;
        X_UNLOCK (wait_m);
        OUTPUT:
        RETVAL
	

int
fd ()
	CODE:
        RETVAL = s_epipe_fd (&ep);
	OUTPUT:
        RETVAL

void
poll (...)
	CODE:
        s_epipe_drain (&ep);
	X_LOCK (wait_m);
        while (waiters_count)
          {
            struct tctx *ctx = waiters [--waiters_count];
            CORO_READY ((SV *)ctx->coro);
            SvREFCNT_dec_NN ((SV *)ctx->coro);
            ctx->coro = 0;
          }
	X_UNLOCK (wait_m);

void
sleep (NV seconds)
	CODE:
        perlinterp_release ();
        usleep (seconds * 1e6);
        perlinterp_acquire ();

