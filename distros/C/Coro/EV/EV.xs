#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>
#include <assert.h>
#include <string.h>

#include "EVAPI.h"
#include "../Coro/CoroAPI.h"

static struct ev_prepare scheduler;
static struct ev_idle idler;
static int inhibit;

static void
idle_cb (EV_P_ ev_idle *w, int revents)
{
  ev_idle_stop (EV_A, w);
}

static void
prepare_cb (EV_P_ ev_prepare *w, int revents)
{
  static int incede;

  if (inhibit)
    return;

  ++incede;

  CORO_CEDE_NOTSELF;

  while (CORO_NREADY >= incede && CORO_CEDE)
    ;

  /* if still ready, then we have lower-priority coroutines.
   * poll anyways, but do not block.
   */
  if (CORO_NREADY >= incede)
    {
      if (!ev_is_active (&idler))
        ev_idle_start (EV_A, &idler);
    }
  else
    {
      if (ev_is_active (&idler))
        ev_idle_stop (EV_A, &idler);
    }

  --incede;
}

static void
readyhook (void)
{
  if (!ev_is_active (&idler))
    ev_idle_start (EV_DEFAULT_UC, &idler);
}

/*****************************************************************************/

static void
once_cb (int revents, void *arg)
{
  SV *data = (SV *)arg;

  CORO_READY (data);
  sv_setiv (data, revents);
  SvREFCNT_dec (data);
}

static int
slf_check_once (pTHX_ struct CoroSLF *frame)
{
  SV *data = (SV *)frame->data;

  /* return early when an exception is pending */
  if (CORO_THROW)
    return 0;

  if (SvROK (data))
    return 1; /* repeat until we have been signalled */
  else
    {
      dSP;

      XPUSHs (data);

      PUTBACK;
      return 0;
    }
}

static void
slf_init_timed_io (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  SV *data;

  if (items < 2 || items > 3)
    croak ("Coro::EV::timed_io_once requires exactly two or three parameters, not %d.\n", items);

  SvGETMAGIC (arg [0]);
  SvGETMAGIC (arg [1]);

  if (items >= 3)
    SvGETMAGIC (arg [2]);

  data = sv_2mortal (newRV_inc (CORO_CURRENT));
  frame->data    = (void *)data;
  frame->prepare = GCoroAPI->prepare_schedule;
  frame->check   = slf_check_once;

  ev_once (
    EV_DEFAULT_UC,
    sv_fileno (arg [0]),
    SvIV (arg [1]),
    items >= 3 && SvOK (arg [2]) ? SvNV (arg [2]) : -1.,
    once_cb,
    SvREFCNT_inc (data)
  );
}

static void
slf_init_timer (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  SV *data;
  NV after;

  if (items > 1)
    croak ("Coro::EV::timer_once requires at most one parameter, not %d.\n", items);

  data = sv_2mortal (newRV_inc (CORO_CURRENT));
  frame->data    = (void *)data;
  frame->prepare = GCoroAPI->prepare_schedule;
  frame->check   = slf_check_once;

  after = items ? SvNV (arg [0]) : 0;

  ev_once (
    EV_DEFAULT_UC,
    -1,
    0,
    after >= 0. ? after : 0.,
    once_cb,
    SvREFCNT_inc (data)
  );
}

/*****************************************************************************/

typedef struct
{
  ev_io io;
  ev_timer tw;
  SV *data;
} coro_dir;

typedef struct
{
  coro_dir r, w;
} coro_handle;

static int
handle_free (pTHX_ SV *sv, MAGIC *mg)
{
  coro_handle *data = (coro_handle *)mg->mg_ptr;
  mg->mg_ptr = 0;

  ev_io_stop    (EV_DEFAULT_UC, &data->r.io); ev_io_stop    (EV_DEFAULT_UC, &data->w.io);
  ev_timer_stop (EV_DEFAULT_UC, &data->r.tw); ev_timer_stop (EV_DEFAULT_UC, &data->w.tw);

  return 0;
}

static MGVTBL handle_vtbl = { 0,  0,  0,  0, handle_free };

static void
handle_cb (coro_dir *dir, int success)
{
  ev_io_stop    (EV_DEFAULT_UC, &dir->io);
  ev_timer_stop (EV_DEFAULT_UC, &dir->tw);

  CORO_READY (dir->data);
  sv_setiv (dir->data, success);
}

static void
handle_io_cb (EV_P_ ev_io *w, int revents)
{
  handle_cb ((coro_dir *)(((char *)w) - offsetof (coro_dir, io)), 1);
}

static void
handle_timer_cb (EV_P_ ev_timer *w, int revents)
{
  handle_cb ((coro_dir *)(((char *)w) - offsetof (coro_dir, tw)), 0);
}

static int
slf_check_rw (pTHX_ struct CoroSLF *frame)
{
  coro_dir *dir = (coro_dir *)frame->data;

  /* return early when an exception is pending */
  if (CORO_THROW)
    {
      ev_io_stop (EV_DEFAULT_UC, &dir->io);
      ev_timer_stop (EV_DEFAULT_UC, &dir->tw);

      return 0;
    }

  if (SvROK (dir->data))
    return 1;
  else
    {
      dSP;

      XPUSHs (dir->data);

      PUTBACK;
      return 0;
    }
}

static void
slf_init_rw (pTHX_ struct CoroSLF *frame, SV *arg, int wr)
{
  AV *handle = (AV *)SvRV (arg);
  SV *data_sv = AvARRAY (handle)[5];
  coro_handle *data;
  coro_dir *dir;
  assert (AvFILLp (handle) >= 7);

  if (!SvOK (data_sv))
    {
      int fno = sv_fileno (AvARRAY (handle)[0]);
      SvREFCNT_dec (data_sv);
      data_sv = AvARRAY (handle)[5] = NEWSV (0, sizeof (coro_handle));
      SvPOK_only (data_sv);
      SvREADONLY_on (data_sv);
      data = (coro_handle *)SvPVX (data_sv);
      memset (data, 0, sizeof (coro_handle));

      ev_io_init (&data->r.io, handle_io_cb, fno, EV_READ);
      ev_io_init (&data->w.io, handle_io_cb, fno, EV_WRITE);
      ev_init    (&data->r.tw, handle_timer_cb);
      ev_init    (&data->w.tw, handle_timer_cb);

      sv_magicext (data_sv, 0, PERL_MAGIC_ext, &handle_vtbl, (char *)data, 0);
    }
  else
    data = (coro_handle *)SvPVX (data_sv);

  dir = wr ? &data->w : &data->r;

  if (ev_is_active (&dir->io) || ev_is_active (&dir->tw))
    croak ("recursive invocation of readable_ev or writable_ev (concurrent Coro::Handle calls on same handle?), detected");

  dir->data = sv_2mortal (newRV_inc (CORO_CURRENT));

  {
    SV *to = AvARRAY (handle)[2];

    if (SvOK (to))
      {
        ev_timer_set (&dir->tw, 0., SvNV (to));
        ev_timer_again (EV_DEFAULT_UC, &dir->tw);
      }
  }

  ev_io_start (EV_DEFAULT_UC, &dir->io);

  frame->data    = (void *)dir;
  frame->prepare = GCoroAPI->prepare_schedule;
  frame->check   = slf_check_rw;
}

static void
slf_init_readable (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  slf_init_rw (aTHX_ frame, arg [0], 0);
}

static void
slf_init_writable (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items)
{
  slf_init_rw (aTHX_ frame, arg [0], 1);
}

/*****************************************************************************/

MODULE = Coro::EV                PACKAGE = Coro::EV

PROTOTYPES: ENABLE

BOOT:
{
        I_EV_API   ("Coro::EV");
	I_CORO_API ("Coro::EV");

        EV_DEFAULT; /* make sure it is initialised */

        ev_prepare_init (&scheduler, prepare_cb);
        ev_set_priority (&scheduler, EV_MINPRI);
        ev_prepare_start (EV_DEFAULT_UC, &scheduler);
        ev_unref (EV_DEFAULT_UC);

        ev_idle_init (&idler, idle_cb);
        ev_set_priority (&idler, EV_MINPRI);

        if (!CORO_READYHOOK) /* do not override if Coro::AnyEvent already did */
          {
            CORO_READYHOOK = readyhook;
            CORO_READYHOOK (); /* make sure we don't miss previous ready's */
          }
}

void
_set_readyhook ()
	CODE:
        CORO_READYHOOK = readyhook;
        CORO_READYHOOK ();

void
_loop_oneshot ()
	CODE:
{
        /* inhibit the prepare watcher, as we know we are the only
         * ready coroutine and we don't want it to start an idle watcher
         * just because of the fallback idle coro being of lower priority.
         */
        ++inhibit;

        /* same reasoning as above, make sure it is stopped */
        if (ev_is_active (&idler))
          ev_idle_stop (EV_DEFAULT_UC, &idler);
        ev_run (EV_DEFAULT_UC, EVRUN_ONCE);
        --inhibit;
}

void
timed_io_once (...)
	PROTOTYPE: $$;$
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_timed_io);

void
timer_once (...)
	PROTOTYPE: $
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_timer);

void
_poll (...)
	PROTOTYPE:
	CODE:
        CORO_EXECUTE_SLF_XS (slf_init_timer);

PROTOTYPES: DISABLE

void
_readable_ev (...)
	CODE:
        items = 1; /* ignore the remaining args for speed inside Coro::Handle */
        CORO_EXECUTE_SLF_XS (slf_init_readable);

void
_writable_ev (...)
	CODE:
        items = 1; /* ignore the remaining args for speed inside Coro::Handle */
        CORO_EXECUTE_SLF_XS (slf_init_writable);

