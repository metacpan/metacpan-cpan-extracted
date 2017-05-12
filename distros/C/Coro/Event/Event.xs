#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <string.h>

#include "EventAPI.h"
#include "../Coro/CoroAPI.h"

#define CD_WAIT	0 /* wait queue */
#define CD_TYPE	1
#define CD_OK	2
#define CD_HITS	3 /* hardcoded in Coro::Event */
#define CD_GOT	4 /* hardcoded in Coro::Event, Coro::Handle */
#define CD_MAX	4

static HV *coro_event_event_stash;

#define PERL_MAGIC_coro_event 0x18 /* to avoid clashes with e.g. event */

static void
coro_std_cb (pe_event *pe)
{
  AV *priv = (AV *)pe->ext_data;
  IV type = SvIV (AvARRAY (priv)[CD_TYPE]);
  AV *cd_wait;
  SV *coro;

  SvIV_set (AvARRAY (priv)[CD_HITS], pe->hits);
  SvIV_set (AvARRAY (priv)[CD_GOT], type ? ((pe_ioevent *)pe)->got : 0);

  AvARRAY (priv)[CD_OK] = &PL_sv_yes;

  cd_wait = (AV *)AvARRAY(priv)[CD_WAIT];

  coro = av_shift (cd_wait);
  if (coro != &PL_sv_undef)
    {
      CORO_READY (coro);
      SvREFCNT_dec (coro);
    }

  if (av_len (cd_wait) < 0)
    GEventAPI->stop (pe->up, 0);
}

static void
asynccheck_hook (void *data)
{
  /* this loops as long as we have _other_ coros with the same or higher priority */
  while (CORO_NREADY && CORO_CEDE)
    ;
}

static NV
prepare_hook (void *data)
{
  /* this yields once to another coro with any priority */
  if (CORO_NREADY)
    {
      CORO_CEDE_NOTSELF;
      /*
       * timers might have changed, and Event fails to notice this
       * so we have to assume the worst. If Event didn't have that bug,
       * we would only need to do this if CORO_NREADY is != 0 now.
       */
      return 0.;
    }
  else
    return 85197.73; /* this is as good as any value, but it factors badly with common values */
}

MODULE = Coro::Event                PACKAGE = Coro::Event

PROTOTYPES: ENABLE

BOOT:
{
	coro_event_event_stash = gv_stashpv ("Coro::Event::Event", TRUE);

        I_EVENT_API ("Coro::Event");
	I_CORO_API  ("Coro::Event");

        GEventAPI->add_hook ("asynccheck", (void *)asynccheck_hook, 0);
        GEventAPI->add_hook ("prepare",    (void *)prepare_hook,    0);
}

void
_install_std_cb (SV *self, int type)
        CODE:
{
        pe_watcher *w = (pe_watcher *)GEventAPI->sv_2watcher (self);

        if (w->callback)
          croak ("Coro::Event watchers must not have a callback (see Coro::Event), caught");

        {
          AV *priv = newAV ();

          av_fill (priv, CD_MAX);
          AvARRAY (priv)[CD_WAIT] = (SV *)newAV (); /* AV in AV _should_ not be exposed to perl */
          AvARRAY (priv)[CD_TYPE] = newSViv (type);
          AvARRAY (priv)[CD_OK  ] = &PL_sv_no;
          AvARRAY (priv)[CD_HITS] = newSViv (0);
          AvARRAY (priv)[CD_GOT ] = newSViv (0);
          SvREADONLY_on (priv);

          w->callback = (void *)coro_std_cb;
          w->ext_data = priv;

          {
            SV *mob = newRV_noinc ((SV *)priv);
            sv_magicext (SvRV (self), mob, PERL_MAGIC_coro_event, 0, (char *)w, 0);
            SvREFCNT_dec (mob); /* sv_magicext increments the refcount */
          }
        }
}

void
_next (SV *self)
        CODE:
{
        pe_watcher *w = (pe_watcher *)GEventAPI->sv_2watcher (self);
        AV *priv = (AV *)w->ext_data;

        if (AvARRAY (priv)[CD_OK] == &PL_sv_yes)
          {
            AvARRAY (priv)[CD_OK] = &PL_sv_no;
            XSRETURN_NO; /* got an event */
          }

        av_push ((AV *)AvARRAY (priv)[CD_WAIT], SvREFCNT_inc (CORO_CURRENT));

        if (!w->running)
          GEventAPI->start (w, 1);

        XSRETURN_YES; /* schedule */
}

SV *
_event (SV *self)
	CODE:
{
        if (GIMME_V == G_VOID)
          XSRETURN_EMPTY;

        {
          pe_watcher *w = (pe_watcher *)GEventAPI->sv_2watcher (self);
          AV *priv = (AV *)w->ext_data;

          RETVAL = newRV_inc ((SV *)priv);

          /* may need to bless it now */
          if (!SvOBJECT (priv))
            {
              SvREADONLY_off ((SV *)priv);
              sv_bless (RETVAL, coro_event_event_stash);
              SvREADONLY_on ((SV *)priv);
            }
        }
}
	OUTPUT:
        RETVAL

