#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

/* mariadb/mysql uses all these reserved macro names, and probably more :( */
#undef read
#undef write
#undef close

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

#if MARIADB_VERSION_ID >= 100300

  typedef unsigned char uchar; /* bug? */
  #include <ma_pvio.h>

  #define PVIO 1
  #define VIOPTR MARIADB_PVIO *
  #define VIOM(vio) (vio)->methods
  #define vioblocking blocking
  #define vioclose close
  #define VIODATA(vio) (vio)->data
  /* ma_pvio_get_socket would be it, but it's only declared, not defined */
  #define VIOSD(vio) mysql_get_socket ((vio)->mysql)
  #define VIO_READ_BUFFER_SIZE PVIO_READ_AHEAD_CACHE_SIZE
  #define my_to_vio(sock) (sock)->net.pvio

  #define OURDATAPTR ((ourdata *)vio->methods)

  typedef       uchar *xgptr;
  typedef const uchar *cxgptr;
  typedef size_t  xsize_t;
  typedef ssize_t xssize_t;
  typedef my_bool xmy_bool;

#else

  #include "violite.h"

  #define PVIO 0
  #define VIOPTR Vio *
  #define VIOM(vio) vio
  #define VIODATA(vio) (vio)->desc
  #define VIOSD(vio) (vio)->sd
  #define my_to_vio(sock) (sock)->net.vio

  typedef int xmy_bool;

#endif

#define CoMy_MAGIC 0x436f4d79

typedef struct {
#if PVIO
  /* must be first member */
  struct st_ma_pvio_methods methods;
#else
#if DESC_IS_PTR
  char desc[30];
  const char *old_desc;
#endif
#endif
  int magic;
  SV *corohandle_sv, *corohandle;
  int bufofs, bufcnt;
#if HAVE_EV
  ev_io rw, ww;
#endif
  char buf[VIO_READ_BUFFER_SIZE];
#if PVIO
  struct st_ma_pvio_methods *oldmethods;
#else
  xssize_t  (*old_read)(VIOPTR, uchar *, size_t);
  xssize_t  (*old_write)(VIOPTR, const uchar *, size_t);
  xmy_bool (*old_close)(VIOPTR);
#endif
} ourdata;

#ifndef OURDATAPTR
#if DESC_IS_PTR
# define OURDATAPTR (*(ourdata **)&((vio)->desc))
#else
# define DESC_OFFSET 22
# define OURDATAPTR (*((ourdata **)((vio)->desc + DESC_OFFSET)))
#endif
#endif

static xssize_t
our_read (VIOPTR vio, xgptr p, xsize_t len)
{
  ourdata *our = OURDATAPTR;

  if (!our->bufcnt)
    {
      int rd;
      my_bool dummy;

      VIOM (vio)->vioblocking (vio, 0, &dummy);

      for (;;)
        {
          rd = recv (VIOSD (vio), our->buf, sizeof (our->buf), 0);

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

static xssize_t
our_write (VIOPTR vio, cxgptr p, xsize_t len)
{
  char *ptr = (char *)p;
  my_bool dummy;

  VIOM (vio)->vioblocking (vio, 0, &dummy);

  while (len > 0)
    {
      int wr = send (VIOSD (vio), ptr, len, 0);

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

static xmy_bool
our_close (VIOPTR vio)
{
  ourdata *our = OURDATAPTR;

  if (VIOM (vio)->read != our_read)
    croak ("vio.read has unexpected content during unpatch - wtf?");

  if (VIOM (vio)->write != our_write)
    croak ("vio.write has unexpected content during unpatch - wtf?");

  if (VIOM (vio)->vioclose != our_close)
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

#if PVIO
  vio->methods = our->oldmethods;
#else
  VIOM (vio)->vioclose = our->old_close;
  VIOM (vio)->write    = our->old_write;
  VIOM (vio)->read     = our->old_read;
#endif

  Safefree (our);

  VIOM (vio)->vioclose (vio);
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
        VIOPTR vio = my_to_vio (my);
        ourdata *our;

        /* matching versions are required but not sufficient */
        if (client_version != mysql_get_client_version ())
          croak ("DBD::mysql linked against different libmysqlclient library than Coro::Mysql (%lu vs. %lu).",
                 client_version, mysql_get_client_version ());

        if (fd != my->net.fd)
          croak ("DBD::mysql fd and libmysql disagree - library mismatch, unsupported transport or API changes?");

        if (fd != VIOSD (vio))
          croak ("DBD::mysql fd and vio-sd disagree - library mismatch, unsupported transport or API changes?");
#if MYSQL_VERSION_ID < 100010 && !defined(MARIADB_BASE_VERSION)
        if (VIOM (vio)->vioclose != vio_close)
          croak ("vio.vioclose has unexpected content - library mismatch, unsupported transport or API changes?");

        if (VIOM (vio)->write != vio_write)
          croak ("vio.write has unexpected content - library mismatch, unsupported transport or API changes?");

        if (VIOM (vio)->read != vio_read
            && VIOM (vio)->read != vio_read_buff)
          croak ("vio.read has unexpected content - library mismatch, unsupported transport or API changes?");
#endif
#if PVIO
        if (vio->type != PVIO_TYPE_UNIXSOCKET && vio->type != PVIO_TYPE_SOCKET)
          croak ("connection type mismatch: Coro::Mysql only supports 'unixsocket' and 'socket' types at this time");
#endif

        Newz (0, our, 1, ourdata);
        our->magic = CoMy_MAGIC;
        our->corohandle_sv = newSVsv (corohandle_sv);
        our->corohandle    = newSVsv (corohandle);
#if HAVE_EV
        if (use_ev)
          {
            ev_io_init (&(our->rw), iocb, VIOSD (vio), EV_READ);
            ev_io_init (&(our->ww), iocb, VIOSD (vio), EV_WRITE);
          }
#endif
#if PVIO
        /* with pvio, we replace methods by our own struct,
         * both becauase the original might be read-only,
         * and because we have no private data member, so the
         * methods pointer includes our data as well
         */
        our->methods = *vio->methods;
        our->oldmethods = vio->methods;
        vio->methods = &our->methods;
#else
        OURDATAPTR = our;
#if DESC_IS_PTR
        our->old_desc = vio->desc;
        strncpy (our->desc, vio->desc, sizeof (our->desc));
        our->desc [sizeof (our->desc) - 1] = 0;
#else
        vio->desc [DESC_OFFSET - 1] = 0;
#endif
        our->old_close = VIOM (vio)->vioclose;
        our->old_write = VIOM (vio)->write;
        our->old_read  = VIOM (vio)->read;
#endif

        /* with pvio, this patches our own struct */
        VIOM (vio)->vioclose = our_close;
        VIOM (vio)->write    = our_write;
        VIOM (vio)->read     = our_read;
}

int
_is_patched (IV sock)
	CODE:
{
	MYSQL *my = (MYSQL *)sock;
        VIOPTR vio = my_to_vio (my);
        RETVAL = VIOM (vio)->write == our_write;
}
        OUTPUT: RETVAL

int
have_ev ()
	CODE:
        RETVAL = 0;
#if HAVE_EV
        RETVAL = 1;
#endif
        OUTPUT: RETVAL

