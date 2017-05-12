#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

#include <mysql.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if HAVE_EV
# include "EVAPI.h"
# include "CoroAPI.h"
#endif

#define IN_DESTRUCT PL_dirty

typedef U16 uint16;

/* cached function gv's */
static CV *readable, *writable;
static int use_ev;

#include "violite.h"

#define CoMy_MAGIC 0x436f4d79

typedef struct {
#if DESC_IS_PTR
  char desc[30];
  const char *old_desc;
#endif
  int magic;
  SV *corohandle_sv, *corohandle;
  int bufofs, bufcnt;
#if HAVE_EV
  ev_io rw, ww;
#endif
  char buf[VIO_READ_BUFFER_SIZE];
  size_t  (*old_read)(Vio*, uchar *, size_t);
  size_t  (*old_write)(Vio*, const uchar *, size_t);
  int     (*old_vioclose)(Vio*);
} ourdata;

#if DESC_IS_PTR
# define OURDATAPTR (*(ourdata **)&((vio)->desc))
#else
# define DESC_OFFSET 22
# define OURDATAPTR (*((ourdata **)((vio)->desc + DESC_OFFSET)))
#endif

static xlen
our_read (Vio *vio, xgptr p, xlen len)
{
  ourdata *our = OURDATAPTR;

  if (!our->bufcnt)
    {
      int rd;
      my_bool dummy;

      vio->vioblocking (vio, 0, &dummy);

      for (;;)
        {
          rd = recv (vio->sd, our->buf, sizeof (our->buf), 0);

          if (rd >= 0 || errno != EAGAIN)
            break;

#if HAVE_EV
          if (use_ev)
            {
              our->rw.data = (void *)sv_2mortal (SvREFCNT_inc (CORO_CURRENT));
              ev_io_start (EV_DEFAULT_UC, &(our->rw));
              CORO_SCHEDULE;
              ev_io_stop (EV_DEFAULT_UC, &(our->rw)); /* avoids races */
            }
          else
#endif
            {
              dSP;
              PUSHMARK (SP);
              XPUSHs (our->corohandle);
              PUTBACK;
              call_sv ((SV *)readable, G_VOID | G_DISCARD);
            }
        }

      if (rd <= 0)
        return rd;

      our->bufcnt = rd;
      our->bufofs = 0;
    }

  if (our->bufcnt < len)
    len = our->bufcnt;

  memcpy (p, our->buf + our->bufofs, len);
  our->bufofs += len;
  our->bufcnt -= len;

  return len;
}

static xlen
our_write (Vio *vio, cxgptr p, xlen len)
{
  char *ptr = (char *)p;
  my_bool dummy;

  vio->vioblocking (vio, 0, &dummy);

  while (len > 0)
    {
      int wr = send (vio->sd, ptr, len, 0);

      if (wr > 0)
        {
          ptr += wr;
          len -= wr;
        }
      else if (errno == EAGAIN)
        {
          ourdata *our = OURDATAPTR;

#if HAVE_EV
          if (use_ev)
            {
              our->ww.data = (void *)sv_2mortal (SvREFCNT_inc (CORO_CURRENT));
              ev_io_start (EV_DEFAULT_UC, &(our->ww));
              CORO_SCHEDULE;
              ev_io_stop (EV_DEFAULT_UC, &(our->ww)); /* avoids races */
            }
          else
#endif
            {
              dSP;
              PUSHMARK (SP);
              XPUSHs (our->corohandle);
              PUTBACK;
              call_sv ((SV *)writable, G_VOID | G_DISCARD);
            }
        }
      else if (ptr == (char *)p)
        return -1;
      else
        break;
    }

  return ptr - (char *)p;
}

static int
our_close (Vio *vio)
{
  ourdata *our = OURDATAPTR;

  if (vio->read != our_read)
    croak ("vio.read has unexpected content during unpatch - wtf?");

  if (vio->write != our_write)
    croak ("vio.write has unexpected content during unpatch - wtf?");

  if (vio->vioclose != our_close)
    croak ("vio.vioclose has unexpected content during unpatch - wtf?");

#if HAVE_EV
  if (use_ev)
    {
      ev_io_stop (EV_DEFAULT_UC, &(our->rw));
      ev_io_stop (EV_DEFAULT_UC, &(our->ww));
    }
#endif

  SvREFCNT_dec (our->corohandle);
  SvREFCNT_dec (our->corohandle_sv);

#if DESC_IS_PTR
  vio->desc = our->old_desc;
#endif

  vio->vioclose = our->old_vioclose;
  vio->write    = our->old_write;
  vio->read     = our->old_read;

  Safefree (our);

  vio->vioclose (vio);
}

#if HAVE_EV
static void
iocb (EV_P_ ev_io *w, int revents)
{
  ev_io_stop (EV_A, w);
  CORO_READY ((SV *)w->data);
}
#endif

MODULE = Coro::Mysql		PACKAGE = Coro::Mysql

BOOT:
{
  readable = get_cv ("Coro::Mysql::readable", 0);
  writable = get_cv ("Coro::Mysql::writable", 0);
}

PROTOTYPES: ENABLE

void
_use_ev ()
	PPCODE:
{
	static int onceonly;

	if (!onceonly)
          {
	    onceonly = 1;
#if HAVE_EV
	    I_EV_API ("Coro::Mysql");
	    I_CORO_API ("Coro::Mysql");
	    use_ev = 1;
#endif
          }

        XPUSHs (use_ev ? &PL_sv_yes : &PL_sv_no);
}

void
_patch (IV sock, int fd, unsigned long client_version, SV *corohandle_sv, SV *corohandle)
	CODE:
{
	MYSQL *my = (MYSQL *)sock;
        Vio *vio = my->net.vio;
        ourdata *our;

        /* matching versions are required but not sufficient */
        if (client_version != mysql_get_client_version ())
          croak ("DBD::mysql linked against different libmysqlclient library than Coro::Mysql (%lu vs. %lu).",
                 client_version, mysql_get_client_version ());

        if (fd != my->net.fd)
          croak ("DBD::mysql fd and libmysql disagree - library mismatch, unsupported transport or API changes?");

        if (fd != vio->sd)
          croak ("DBD::mysql fd and vio-sd disagree - library mismatch, unsupported transport or API changes?");
#if MYSQL_VERSION_ID < 100010 && !defined(MARIADB_BASE_VERSION)
        if (vio->vioclose != vio_close)
          croak ("vio.vioclose has unexpected content - library mismatch, unsupported transport or API changes?");

        if (vio->write != vio_write)
          croak ("vio.write has unexpected content - library mismatch, unsupported transport or API changes?");

        if (vio->read != vio_read
            && vio->read != vio_read_buff)
          croak ("vio.read has unexpected content - library mismatch, unsupported transport or API changes?");
#endif

        Newz (0, our, 1, ourdata);
        our->magic = CoMy_MAGIC;
        our->corohandle_sv = newSVsv (corohandle_sv);
        our->corohandle    = newSVsv (corohandle);
#if HAVE_EV
        if (use_ev)
          {
            ev_io_init (&(our->rw), iocb, vio->sd, EV_READ);
            ev_io_init (&(our->ww), iocb, vio->sd, EV_WRITE);
          }
#endif
#if DESC_IS_PTR
        our->old_desc = vio->desc;
        strncpy (our->desc, vio->desc, sizeof (our->desc));
        our->desc [sizeof (our->desc) - 1] = 0;
#else
        vio->desc [DESC_OFFSET - 1] = 0;
#endif
        OURDATAPTR = our;

        our->old_vioclose = vio->vioclose;
        our->old_write    = vio->write;
        our->old_read     = vio->read;

        vio->vioclose = our_close;
        vio->write    = our_write;
        vio->read     = our_read;
}

