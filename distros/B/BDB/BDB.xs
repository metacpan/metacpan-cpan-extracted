#define X_STACKSIZE 1024 * 128 + sizeof (long) * 64 * 1024 / 4

#include "xthread.h"

#include <errno.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "schmorp.h"

// perl stupidly defines these as argument-less macros, breaking
// lots and lots of code.
#undef open
#undef close
#undef abort
#undef malloc
#undef free
#undef send

#include <stddef.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <limits.h>
#include <fcntl.h>

#ifndef _WIN32
# include <sys/time.h>
# include <unistd.h>
#endif

#include <db.h>

#define DBVER DB_VERSION_MAJOR * 100 + DB_VERSION_MINOR

#if DBVER < 403
# error you need Berkeley DB 4.3 or a newer version installed
#endif

/* number of seconds after which idle threads exit */
#define IDLE_TIMEOUT 10

typedef SV          SV_mutable;

typedef DB_ENV      DB_ENV_ornull;
typedef DB_TXN      DB_TXN_ornull;
typedef DBC         DBC_ornull;
typedef DB          DB_ornull;

typedef DB_ENV      DB_ENV_ornuked;
typedef DB_TXN      DB_TXN_ornuked;
typedef DBC         DBC_ornuked;
typedef DB          DB_ornuked;

#if DBVER >= 403
typedef DB_SEQUENCE DB_SEQUENCE_ornull;
typedef DB_SEQUENCE DB_SEQUENCE_ornuked;
#endif

typedef char *bdb_filename;

static SV *prepare_cb;

static HV
  *bdb_stash,
  *bdb_env_stash,
  *bdb_txn_stash,
  *bdb_cursor_stash,
  *bdb_db_stash,
  *bdb_sequence_stash;

#if DBVER >= 406
# define c_close close 
# define c_count count 
# define c_del   del   
# define c_dup   dup   
# define c_get   get   
# define c_pget  pget  
# define c_put   put   
#endif

static char *
get_bdb_filename (SV *sv)
{
  if (!SvOK (sv))
    return 0;

#if _WIN32
  /* win32 madness + win32 perl absolutely brokenness make for horrible hacks */
  {
    STRLEN len;
    char *src = SvPVbyte (sv, len);
    SV *t1 = sv_newmortal ();
    SV *t2 = sv_newmortal ();

    sv_upgrade (t1, SVt_PV); SvPOK_only (t1); SvGROW (t1, len * 16 + 1);
    sv_upgrade (t2, SVt_PV); SvPOK_only (t2); SvGROW (t2, len * 16 + 1);

    len = MultiByteToWideChar (CP_ACP, 0, src, len, (WCHAR *)SvPVX (t1), SvLEN (t1) / sizeof (WCHAR));
    len = WideCharToMultiByte (CP_UTF8, 0, (WCHAR *)SvPVX (t1), len, SvPVX (t2), SvLEN (t2), 0, 0);
    SvPOK_only (t2);
    SvPVX (t2)[len] = 0;
    SvCUR_set (t2, len);

    return SvPVX (t2);
  }
#else
  return SvPVbyte_nolen (sv);
#endif
}

static void
debug_errcall (const DB_ENV *dbenv, const char *errpfx, const char *msg)
{
  printf ("err[%s]\n", msg);
}

static void
debug_msgcall (const DB_ENV *dbenv, const char *msg)
{
  printf ("msg[%s]\n", msg);
}

static char *
strdup_ornull (const char *s)
{
  return s ? strdup (s) : 0;
}

static void
sv_to_dbt (DBT *dbt, SV *sv)
{
  STRLEN len;
  char *data = SvPVbyte (sv, len);

  dbt->data = malloc (len);
  memcpy (dbt->data, data, len);
  dbt->size = len;
  dbt->flags = DB_DBT_REALLOC;
}
	
static void
dbt_to_sv (SV *sv, DBT *dbt)
{
  if (sv)
    {
      SvREADONLY_off (sv);

      if (dbt->data)
        sv_setpvn_mg (sv, dbt->data, dbt->size);
      else
        sv_setsv_mg (sv, &PL_sv_undef);

      SvREFCNT_dec (sv);
    }

  free (dbt->data);
}
	
enum {
  REQ_QUIT,
  REQ_ENV_OPEN, REQ_ENV_CLOSE, REQ_ENV_TXN_CHECKPOINT, REQ_ENV_LOCK_DETECT,
  REQ_ENV_MEMP_SYNC, REQ_ENV_MEMP_TRICKLE, REQ_ENV_DBREMOVE, REQ_ENV_DBRENAME,
  REQ_ENV_LOG_ARCHIVE, REQ_ENV_LSN_RESET, REQ_ENV_FILEID_RESET,
  REQ_DB_OPEN, REQ_DB_CLOSE, REQ_DB_COMPACT, REQ_DB_SYNC, REQ_DB_VERIFY, REQ_DB_UPGRADE,
  REQ_DB_PUT, REQ_DB_EXISTS, REQ_DB_GET, REQ_DB_PGET, REQ_DB_DEL, REQ_DB_KEY_RANGE,
  REQ_TXN_COMMIT, REQ_TXN_ABORT, REQ_TXN_FINISH,
  REQ_C_CLOSE, REQ_C_COUNT, REQ_C_PUT, REQ_C_GET, REQ_C_PGET, REQ_C_DEL,
  REQ_SEQ_OPEN, REQ_SEQ_CLOSE, REQ_SEQ_GET, REQ_SEQ_REMOVE,
};

typedef struct bdb_cb
{
  struct bdb_cb *volatile next;
  SV *callback;
  int type, pri, result;

  DB_ENV *env;
  DB *db;
  DB_TXN *txn;
  DBC *dbc;

  UV uv1;
  int int1, int2;
  U32 uint1, uint2;
  char *buf1, *buf2, *buf3;
  SV *sv1, *sv2, *sv3;

  DBT dbt1, dbt2, dbt3;
  DB_KEY_RANGE key_range;
#if DBVER >= 403
  DB_SEQUENCE *seq;
  db_seq_t seq_t;
#endif

  SV *rsv1, *rsv2; // keep some request objects alive
} bdb_cb;

typedef bdb_cb *bdb_req;

enum {
  PRI_MIN     = -4,
  PRI_MAX     =  4,

  DEFAULT_PRI = 0,
  PRI_BIAS    = -PRI_MIN,
  NUM_PRI     = PRI_MAX + PRI_BIAS + 1,
};

#define AIO_TICKS ((1000000 + 1023) >> 10)

static SV *on_next_submit;

static unsigned int max_poll_time = 0;
static unsigned int max_poll_reqs = 0;

/* calculcate time difference in ~1/AIO_TICKS of a second */
static int tvdiff (struct timeval *tv1, struct timeval *tv2)
{
  return  (tv2->tv_sec  - tv1->tv_sec ) * AIO_TICKS
       + ((tv2->tv_usec - tv1->tv_usec) >> 10);
}

static int next_pri = DEFAULT_PRI + PRI_BIAS;

static unsigned int started, idle, wanted;

/* worker threads management */
static xmutex_t wrklock = X_MUTEX_INIT;

typedef struct worker {
  /* locked by wrklock */
  struct worker *prev, *next;

  xthread_t tid;

  /* locked by reslock, reqlock or wrklock */
  bdb_req req; /* currently processed request */
  void *dbuf;
  DIR *dirp;
} worker;

static worker wrk_first = { &wrk_first, &wrk_first, 0 };

static void worker_clear (worker *wrk)
{
}

static void worker_free (worker *wrk)
{
  wrk->next->prev = wrk->prev;
  wrk->prev->next = wrk->next;

  free (wrk);
}

static volatile unsigned int nreqs, nready, npending;
static volatile unsigned int max_idle = 4;
static volatile unsigned int max_outstanding = 0xffffffff;
static s_epipe respipe;

static xmutex_t reslock = X_MUTEX_INIT;
static xmutex_t reqlock = X_MUTEX_INIT;
static xcond_t  reqwait = X_COND_INIT;

#if WORDACCESS_UNSAFE

static unsigned int get_nready (void)
{
  unsigned int retval;

  X_LOCK   (reqlock);
  retval = nready;
  X_UNLOCK (reqlock);

  return retval;
}

static unsigned int get_npending (void)
{
  unsigned int retval;

  X_LOCK   (reslock);
  retval = npending;
  X_UNLOCK (reslock);

  return retval;
}

static unsigned int get_nthreads (void)
{
  unsigned int retval;

  X_LOCK   (wrklock);
  retval = started;
  X_UNLOCK (wrklock);

  return retval;
}

#else

# define get_nready()   nready
# define get_npending() npending
# define get_nthreads() started

#endif

/*
 * a somewhat faster data structure might be nice, but
 * with 8 priorities this actually needs <20 insns
 * per shift, the most expensive operation.
 */
typedef struct {
  bdb_req qs[NUM_PRI], qe[NUM_PRI]; /* qstart, qend */
  int size;
} reqq;

static reqq req_queue;
static reqq res_queue;

int reqq_push (reqq *q, bdb_req req)
{
  int pri = req->pri;
  req->next = 0;

  if (q->qe[pri])
    {
      q->qe[pri]->next = req;
      q->qe[pri] = req;
    }
  else
    q->qe[pri] = q->qs[pri] = req;

  return q->size++;
}

bdb_req reqq_shift (reqq *q)
{
  int pri;

  if (!q->size)
    return 0;

  --q->size;

  for (pri = NUM_PRI; pri--; )
    {
      bdb_req req = q->qs[pri];

      if (req)
        {
          if (!(q->qs[pri] = req->next))
            q->qe[pri] = 0;

          return req;
        }
    }

  abort ();
}

static int poll_cb (void);
static void req_free (bdb_req req);

static int req_invoke (bdb_req req)
{
  switch (req->type)
    {
      case REQ_DB_CLOSE:
        SvREFCNT_dec (req->sv1);
        break;

      case REQ_DB_GET:
      case REQ_DB_PGET:
      case REQ_C_GET:
      case REQ_C_PGET:
      case REQ_DB_PUT:
      case REQ_C_PUT:
        dbt_to_sv (req->sv1, &req->dbt1);
        dbt_to_sv (req->sv2, &req->dbt2);
        dbt_to_sv (req->sv3, &req->dbt3);
        break;

      case REQ_DB_KEY_RANGE:
        {
          AV *av = newAV ();

          av_push (av, newSVnv (req->key_range.less));
          av_push (av, newSVnv (req->key_range.equal));
          av_push (av, newSVnv (req->key_range.greater));

          av = (AV *)newRV_noinc ((SV *)av);

          SvREADONLY_off (req->sv1);
          sv_setsv_mg (req->sv1, newRV_noinc ((SV *)av));
          SvREFCNT_dec (av);
          SvREFCNT_dec (req->sv1);
        }
        break;

#if DBVER >= 403
      case REQ_SEQ_GET:
        SvREADONLY_off (req->sv1);

        if (sizeof (IV) > 4)
          sv_setiv_mg (req->sv1, (IV)req->seq_t);
        else
          sv_setnv_mg (req->sv1, (NV)req->seq_t);

        SvREFCNT_dec (req->sv1);
        break;
#endif

      case REQ_ENV_LOG_ARCHIVE:
        {
          AV *av = newAV ();
          char **listp = (char **)req->buf1;

          if (listp)
            while (*listp)
              av_push (av, newSVpv (*listp, 0)), ++listp;

          av = (AV *)newRV_noinc ((SV *)av);

          SvREADONLY_off (req->sv1);
          sv_setsv_mg (req->sv1, (SV *)av);
          SvREFCNT_dec (av);
          SvREFCNT_dec (req->sv1);
        }
        break;
    }

  errno = req->result;

  if (req->callback)
    {
      dSP;

      ENTER;
      SAVETMPS;
      PUSHMARK (SP);

      PUTBACK;
      call_sv (req->callback, G_VOID | G_EVAL);
      SPAGAIN;

      FREETMPS;
      LEAVE;

      return !SvTRUE (ERRSV);
    }

  return 1;
}

static void req_free (bdb_req req)
{
  SvREFCNT_dec (req->callback);

  SvREFCNT_dec (req->rsv1);
  SvREFCNT_dec (req->rsv2);

  free (req->buf1);
  free (req->buf2);
  free (req->buf3);

  Safefree (req);
}

static void
create_respipe (void)
{
  if (s_epipe_renew (&respipe))
    croak ("BDB: unable to create event pipe");
}

static void bdb_request (bdb_req req);
X_THREAD_PROC (bdb_proc);

static void start_thread (void)
{
  worker *wrk = calloc (1, sizeof (worker));

  if (!wrk)
    croak ("unable to allocate worker thread data");

  X_LOCK (wrklock);
  if (xthread_create (&wrk->tid, bdb_proc, (void *)wrk))
    {
      wrk->prev = &wrk_first;
      wrk->next = wrk_first.next;
      wrk_first.next->prev = wrk;
      wrk_first.next = wrk;
      ++started;
    }
  else
    free (wrk);

  X_UNLOCK (wrklock);
}

static void maybe_start_thread (void)
{
  if (get_nthreads () >= wanted)
    return;
  
  /* todo: maybe use idle here, but might be less exact */
  if (0 <= (int)get_nthreads () + (int)get_npending () - (int)nreqs)
    return;

  start_thread ();
}

static void req_send (bdb_req req)
{
  SV *wait_callback = 0;

  if (on_next_submit)
    {
      dSP;
      SV *cb = sv_2mortal (on_next_submit);

      on_next_submit = 0;

      PUSHMARK (SP);
      PUTBACK;
      call_sv (cb, G_DISCARD | G_EVAL);
      SPAGAIN;
    }

  // synthesize callback if none given
  if (!req->callback)
    {
      if (SvOK (prepare_cb))
        {
          int count;

          dSP;
          PUSHMARK (SP);
          PUTBACK;
          count = call_sv (prepare_cb, G_ARRAY);
          SPAGAIN;

          if (count != 2)
            croak ("sync prepare callback must return exactly two values\n");

          wait_callback = POPs;
          req->callback = SvREFCNT_inc (POPs);
        }
      else
        {
          // execute request synchronously
          bdb_request (req);
          req_invoke (req);
          req_free (req);
          return;
        }
    }

  ++nreqs;

  X_LOCK (reqlock);
  ++nready;
  reqq_push (&req_queue, req);
  X_COND_SIGNAL (reqwait);
  X_UNLOCK (reqlock);

  maybe_start_thread ();

  if (wait_callback)
    {
      dSP;
      PUSHMARK (SP);
      PUTBACK;
      call_sv (wait_callback, G_DISCARD);
    }
}

static void end_thread (void)
{
  bdb_req req = calloc (1, sizeof (bdb_cb));

  req->type = REQ_QUIT;
  req->pri  = PRI_MAX + PRI_BIAS;

  X_LOCK (reqlock);
  reqq_push (&req_queue, req);
  X_COND_SIGNAL (reqwait);
  X_UNLOCK (reqlock);

  X_LOCK (wrklock);
  --started;
  X_UNLOCK (wrklock);
}

static void set_max_idle (int nthreads)
{
  if (WORDACCESS_UNSAFE) X_LOCK   (reqlock);
  max_idle = nthreads <= 0 ? 1 : nthreads;
  if (WORDACCESS_UNSAFE) X_UNLOCK (reqlock);
}

static void min_parallel (int nthreads)
{
  if (wanted < nthreads)
    wanted = nthreads;
}

static void max_parallel (int nthreads)
{
  if (wanted > nthreads)
    wanted = nthreads;

  while (started > wanted)
    end_thread ();
}

static void poll_wait (void)
{
  while (nreqs)
    {
      int size;
      if (WORDACCESS_UNSAFE) X_LOCK   (reslock);
      size = res_queue.size;
      if (WORDACCESS_UNSAFE) X_UNLOCK (reslock);

      if (size)
        return;

      maybe_start_thread ();

      s_epipe_wait (&respipe);
    }
}

static int poll_cb (void)
{
  dSP;
  int count = 0;
  int maxreqs = max_poll_reqs;
  int do_croak = 0;
  struct timeval tv_start, tv_now;
  bdb_req req;

  if (max_poll_time)
    gettimeofday (&tv_start, 0);

  for (;;)
    {
      for (;;)
        {
          maybe_start_thread ();

          X_LOCK (reslock);
          req = reqq_shift (&res_queue);

          if (req)
            {
              --npending;

              if (!res_queue.size)
                /* read any signals sent by the worker threads */
                s_epipe_drain (&respipe);
            }

          X_UNLOCK (reslock);

          if (!req)
            break;

          --nreqs;

          if (!req_invoke (req))
            {
              req_free (req);
              croak (0);
            }

          count++;

          req_free (req);

          if (maxreqs && !--maxreqs)
            break;

          if (max_poll_time)
            {
              gettimeofday (&tv_now, 0);

              if (tvdiff (&tv_start, &tv_now) >= max_poll_time)
                break;
            }
        }

      if (nreqs <= max_outstanding)
        break;

      poll_wait ();

      ++maxreqs;
    }

  return count;
}

/*****************************************************************************/

static void
bdb_request (bdb_req req)
{
  switch (req->type)
    {
      case REQ_ENV_OPEN:
        req->result = req->env->open (req->env, req->buf1, req->uint1, req->int1);
        break;

      case REQ_ENV_CLOSE:
        req->result = req->env->close (req->env, req->uint1);
        break;

      case REQ_ENV_TXN_CHECKPOINT:
        req->result = req->env->txn_checkpoint (req->env, req->uint1, req->int1, req->uint2);
        break;

      case REQ_ENV_LOCK_DETECT:
        req->result = req->env->lock_detect (req->env, req->uint1, req->uint2, &req->int1);
        break;

      case REQ_ENV_MEMP_SYNC:
        req->result = req->env->memp_sync (req->env, 0);
        break;

      case REQ_ENV_MEMP_TRICKLE:
        req->result = req->env->memp_trickle (req->env, req->int1, &req->int2);
        break;

      case REQ_ENV_DBREMOVE:
        req->result = req->env->dbremove (req->env, req->txn, req->buf1, req->buf2, req->uint1);
        break;

      case REQ_ENV_DBRENAME:
        req->result = req->env->dbrename (req->env, req->txn, req->buf1, req->buf2, req->buf3, req->uint1);
        break;

      case REQ_DB_OPEN:
        req->result = req->db->open (req->db, req->txn, req->buf1, req->buf2, req->int1, req->uint1, req->int2);
        break;

      case REQ_DB_CLOSE:
        req->result = req->db->close (req->db, req->uint1);
        break;

#if DBVER >= 404
      case REQ_DB_COMPACT:
        req->result = req->db->compact (req->db, req->txn, req->dbt1.data ? &req->dbt1 : 0, req->dbt2.data ? &req->dbt2 : 0, 0, req->uint1, 0);
        break;
#endif

      case REQ_DB_SYNC:
        req->result = req->db->sync (req->db, req->uint1);
        break;

      case REQ_DB_VERIFY:
        req->result = req->db->verify (req->db, req->buf1, req->buf2, 0, req->uint1);
        break;

      case REQ_DB_UPGRADE:
        req->result = req->db->upgrade (req->db, req->buf1, req->uint1);
        break;

      case REQ_DB_PUT:
        req->result = req->db->put (req->db, req->txn, &req->dbt1, &req->dbt2, req->uint1);
        break;

#if DBVER >= 406
      case REQ_DB_EXISTS:
        req->result = req->db->exists (req->db, req->txn, &req->dbt1, req->uint1);
        break;
#endif
      case REQ_DB_GET:
        req->result = req->db->get (req->db, req->txn, &req->dbt1, &req->dbt3, req->uint1);
        break;

      case REQ_DB_PGET:
        req->result = req->db->pget (req->db, req->txn, &req->dbt1, &req->dbt2, &req->dbt3, req->uint1);
        break;

      case REQ_DB_DEL:
        req->result = req->db->del (req->db, req->txn, &req->dbt1, req->uint1);
        break;

      case REQ_DB_KEY_RANGE:
        req->result = req->db->key_range (req->db, req->txn, &req->dbt1, &req->key_range, req->uint1);
        break;

      case REQ_TXN_COMMIT:
        req->result = req->txn->commit (req->txn, req->uint1);
        break;

      case REQ_TXN_ABORT:
        req->result = req->txn->abort (req->txn);
        break;

      case REQ_TXN_FINISH:
        if (req->txn->flags & TXN_DEADLOCK)
          {
            req->result = req->txn->abort (req->txn);
            if (!req->result)
              req->result = DB_LOCK_DEADLOCK;
          }
        else
          req->result = req->txn->commit (req->txn, req->uint1);
        break;

      case REQ_C_CLOSE:
        req->result = req->dbc->c_close (req->dbc);
        break;

      case REQ_C_COUNT:
        {
          db_recno_t recno;
          req->result = req->dbc->c_count (req->dbc, &recno, req->uint1);
          req->uv1 = recno;
        }
        break;

      case REQ_C_PUT:
        req->result = req->dbc->c_put (req->dbc, &req->dbt1, &req->dbt2, req->uint1);
        break;

      case REQ_C_GET:
        req->result = req->dbc->c_get (req->dbc, &req->dbt1, &req->dbt3, req->uint1);
        break;

      case REQ_C_PGET:
        req->result = req->dbc->c_pget (req->dbc, &req->dbt1, &req->dbt2, &req->dbt3, req->uint1);
        break;

      case REQ_C_DEL:
        req->result = req->dbc->c_del (req->dbc, req->uint1);
        break;

#if DBVER >= 403
      case REQ_SEQ_OPEN:
        req->result = req->seq->open (req->seq, req->txn, &req->dbt1, req->uint1);
        break;

      case REQ_SEQ_CLOSE:
        req->result = req->seq->close (req->seq, req->uint1);
        break;

      case REQ_SEQ_GET:
        req->result = req->seq->get (req->seq, req->txn, req->int1, &req->seq_t, req->uint1);
        break;

      case REQ_SEQ_REMOVE:
        req->result = req->seq->remove (req->seq, req->txn, req->uint1);
        break;
#endif

#if DBVER >= 407
      case REQ_ENV_LSN_RESET:
        req->result = req->env->lsn_reset (req->env, req->buf1, req->uint1);
        break;

      case REQ_ENV_FILEID_RESET:
        req->result = req->env->fileid_reset (req->env, req->buf1, req->uint1);
        break;
#endif

      case REQ_ENV_LOG_ARCHIVE:
        {
          char **listp = 0; /* DB_ARCH_REMOVE does not touch listp, contrary to docs */
          req->result = req->env->log_archive (req->env, &listp, req->uint1);
          req->buf1 = (char *)listp;
        }
        break;

      default:
        req->result = ENOSYS;
        break;
    }

  if (req->txn && (req->result > 0 || req->result == DB_LOCK_NOTGRANTED))
    req->txn->flags |= TXN_DEADLOCK;
}

X_THREAD_PROC (bdb_proc)
{
  bdb_req req;
  struct timespec ts;
  worker *self = (worker *)thr_arg;

  /* try to distribute timeouts somewhat evenly */
  ts.tv_nsec = ((unsigned long)self & 1023UL) * (1000000000UL / 1024UL);

  for (;;)
    {
      ts.tv_sec = time (0) + IDLE_TIMEOUT;

      X_LOCK (reqlock);

      for (;;)
        {
          self->req = req = reqq_shift (&req_queue);

          if (req)
            break;

          ++idle;

          if (X_COND_TIMEDWAIT (reqwait, reqlock, ts)
              == ETIMEDOUT)
            {
              if (idle > max_idle)
                {
                  --idle;
                  X_UNLOCK (reqlock);
                  X_LOCK (wrklock);
                  --started;
                  X_UNLOCK (wrklock);
                  goto quit;
                }

              /* we are allowed to idle, so do so without any timeout */
              X_COND_WAIT (reqwait, reqlock);
              ts.tv_sec  = time (0) + IDLE_TIMEOUT;
            }

          --idle;
        }

      --nready;

      X_UNLOCK (reqlock);

      if (req->type == REQ_QUIT)
        {
          X_LOCK (reslock);
          free (req);
          self->req = 0;
          X_UNLOCK (reslock);

          goto quit;
        }

      bdb_request (req);

      X_LOCK (reslock);

      ++npending;

      if (!reqq_push (&res_queue, req))
        s_epipe_signal (&respipe);

      self->req = 0;
      worker_clear (self);

      X_UNLOCK (reslock);
    }

quit:
  X_LOCK (wrklock);
  worker_free (self);
  X_UNLOCK (wrklock);

  return 0;
}

/*****************************************************************************/

static void atfork_prepare (void)
{
  X_LOCK (wrklock);
  X_LOCK (reqlock);
  X_LOCK (reslock);
}

static void atfork_parent (void)
{
  X_UNLOCK (reslock);
  X_UNLOCK (reqlock);
  X_UNLOCK (wrklock);
}

static void atfork_child (void)
{
  bdb_req prv;

  while (prv = reqq_shift (&req_queue))
    req_free (prv);

  while (prv = reqq_shift (&res_queue))
    req_free (prv);

  while (wrk_first.next != &wrk_first)
    {
      worker *wrk = wrk_first.next;

      if (wrk->req)
        req_free (wrk->req);

      worker_clear (wrk);
      worker_free (wrk);
    }

  started  = 0;
  idle     = 0;
  nreqs    = 0;
  nready   = 0;
  npending = 0;

  create_respipe ();

  atfork_parent ();
}

#define dREQ(reqtype,rsvcnt)					\
  bdb_req req;							\
  int req_pri = next_pri;					\
  next_pri = DEFAULT_PRI + PRI_BIAS;				\
								\
  if (callback && SvOK (callback))				\
    croak ("callback has illegal type or extra arguments");	\
								\
  Newz (0, req, 1, bdb_cb);					\
  if (!req)							\
    croak ("out of memory during bdb_req allocation");		\
								\
  req->callback = SvREFCNT_inc (cb);				\
  req->type = (reqtype);					\
  req->pri  = req_pri;						\
  if (rsvcnt >= 1) req->rsv1 = SvREFCNT_inc (ST (0));		\
  if (rsvcnt >= 2) req->rsv2 = SvREFCNT_inc (ST (1));		\
  (void)0;

#define REQ_SEND						\
  req_send (req)

#define SvPTR(var, arg, type, stash, class, nullok)				\
  if (!SvOK (arg))								\
    {										\
      if (nullok != 1)								\
        croak (# var " must be a " # class " object, not undef");		\
										\
      (var) = 0;								\
    }										\
  else if (SvSTASH (SvRV (arg)) == stash || sv_derived_from ((arg), # class))   \
    {                                                           		\
      IV tmp = SvIV ((SV*) SvRV (arg));                         		\
      (var) = INT2PTR (type, tmp);                              		\
      if (!var && nullok != 2)							\
        croak (# var " is not a valid " # class " object anymore");		\
    }                                                           		\
  else                                                          		\
    croak (# var " is not of type " # class);

#define ARG_MUTABLE(name)							\
  if (SvREADONLY (name))							\
    croak ("argument " #name " is read-only/constant, but the request requires it to be mutable");

static SV *
newSVptr (void *ptr, HV *stash)
{
  SV *rv = NEWSV (0, 0);
  sv_upgrade (rv, SVt_PVMG);
  sv_setiv (rv, PTR2IV (ptr));

  return sv_bless (newRV_noinc (rv), stash);
}

static void
ptr_nuke (SV *sv)
{
  assert (SvROK (sv));
  sv_setiv (SvRV (sv), 0);
}

static int
errno_get (pTHX_ SV *sv, MAGIC *mg)
{
  if (*mg->mg_ptr == '!') // should always be the case
    if (-30999 <= errno && errno <= -30800)
      {
        sv_setnv (sv, (NV)errno);
        sv_setpv (sv, db_strerror (errno));
        SvNOK_on (sv); /* what a wonderful hack! */
                       // ^^^ copied from perl sources
        return 0;
      }

  return PL_vtbl_sv.svt_get (aTHX_ sv, mg);
}

static MGVTBL vtbl_errno;

// this wonderful hack :( patches perl's $! variable to support our errno values
static void
patch_errno (void)
{
  SV *sv;
  MAGIC *mg;

  if (!(sv = get_sv ("!", 1)))
    return;

  if (!(mg = mg_find (sv, PERL_MAGIC_sv)))
    return;

  if (mg->mg_virtual != &PL_vtbl_sv)
    return;

  vtbl_errno = PL_vtbl_sv;
  vtbl_errno.svt_get = errno_get;
  mg->mg_virtual = &vtbl_errno;
}

#if __GNUC__ >= 4
# define noinline                   __attribute__ ((noinline))
#else
# define noinline
#endif

static noinline SV *
pop_callback (I32 *ritems, SV *sv)
{
  if (SvROK (sv))
    {
      HV *st;
      GV *gvp;
      CV *cv;
      const char *name;

      /* forgive me */
      if (SvTYPE (SvRV (sv)) == SVt_PVMG
          && (st = SvSTASH (SvRV (sv)))
          && (name = HvNAME_get (st))
          && (name [0] == 'B' && name [1] == 'D' && name [2] == 'B' && name [3] == ':'))
        return 0;

      if ((cv = sv_2cv (sv, &st, &gvp, 0)))
        {
          --*ritems;
          return (SV *)cv;
        }
    }

  return 0;
}

/*****************************************************************************/

#if 0
static int
bt_pfxc_compare (DB *db, const DBT *dbt1, const DBT *dbt2)
{
  ssize_t size1 = dbt1->size;
  ssize_t size2 = dbt2->size;
  int res = memcmp ((void *)dbt1->data, (void *)dbt2->data,
                    size1 <= size2 ? size1 : size2);

  if (res)
    return res;
  else if (size1 - size2)
    return size1 - size2;
  else
    return 0;
}

static size_t
bt_pfxc_prefix_x (DB *db, const DBT *dbt1, const DBT *dbt2)
{
  ssize_t size1 = dbt1->size;
  ssize_t size2 = dbt2->size;
  u_int8_t *p1 = (u_int8_t *)dbt1->data;
  u_int8_t *p2 = (u_int8_t *)dbt2->data;
  u_int8_t *pe = p1 + (size1 <= size2 ? size1 : size2);

  while (p1 < pe)
    if (*p1++ != *p2++)
      return p1 - (u_int8_t *)dbt1->data - 1;

  if (size1 < size2) return size1 + 1;
  if (size1 > size2) return size2 + 1;

  return size1;
}
#endif

/*****************************************************************************/

/* stupid windows defines CALLBACK as well */
#undef CALLBACK
#define CALLBACK SV *cb = pop_callback (&items, ST (items - 1));

MODULE = BDB                PACKAGE = BDB

PROTOTYPES: ENABLE

BOOT:
{
        static const struct {
          const char *name;
          IV iv;
        } *civ, const_iv[] = {
#define const_iv(name) { # name, (IV)DB_ ## name },
#if DBVER <= 408
          const_iv (RPCCLIENT)
#endif
          const_iv (INIT_CDB)
          const_iv (INIT_LOCK)
          const_iv (INIT_LOG)
          const_iv (INIT_MPOOL)
          const_iv (INIT_REP)
          const_iv (INIT_TXN)
          const_iv (RECOVER)
          const_iv (INIT_TXN)
          const_iv (RECOVER_FATAL)
          const_iv (CREATE)
          const_iv (RDONLY)
          const_iv (USE_ENVIRON)
          const_iv (USE_ENVIRON_ROOT)
          const_iv (LOCKDOWN)
          const_iv (PRIVATE)
          const_iv (SYSTEM_MEM)
          const_iv (AUTO_COMMIT)
          const_iv (CDB_ALLDB)
          const_iv (DIRECT_DB)
          const_iv (NOLOCKING)
          const_iv (NOMMAP)
          const_iv (NOPANIC)
          const_iv (OVERWRITE)
          const_iv (PANIC_ENVIRONMENT)
          const_iv (REGION_INIT)
          const_iv (TIME_NOTGRANTED)
          const_iv (TXN_NOSYNC)
          const_iv (TXN_NOT_DURABLE)
          const_iv (TXN_WRITE_NOSYNC)
          const_iv (WRITECURSOR)
          const_iv (YIELDCPU)
          const_iv (ENCRYPT_AES)
#if DBVER < 408
          const_iv (XA_CREATE)
#endif
          const_iv (BTREE)
          const_iv (HASH)
          const_iv (QUEUE)
          const_iv (RECNO)
          const_iv (UNKNOWN)
          const_iv (EXCL)
          const_iv (TRUNCATE)
          const_iv (NOSYNC)
          const_iv (CHKSUM)
          const_iv (ENCRYPT)
          const_iv (DUP)
          const_iv (DUPSORT)
          //const_iv (RECNUM)
          const_iv (RENUMBER)
          const_iv (REVSPLITOFF)
          const_iv (CONSUME)
          const_iv (CONSUME_WAIT)
          const_iv (GET_BOTH)
          const_iv (GET_BOTH_RANGE)
          //const_iv (SET_RECNO)
          //const_iv (MULTIPLE)
          const_iv (SNAPSHOT)
          const_iv (JOIN_ITEM)
          const_iv (JOIN_NOSORT)
          const_iv (RMW)

          const_iv (NOTFOUND)
          const_iv (KEYEMPTY)
          const_iv (LOCK_DEADLOCK)
          const_iv (LOCK_NOTGRANTED)
          const_iv (RUNRECOVERY)
          const_iv (OLD_VERSION)
          const_iv (REP_HANDLE_DEAD)
          const_iv (SECONDARY_BAD)

          const_iv (APPEND)
          const_iv (NODUPDATA)
          const_iv (NOOVERWRITE)

          const_iv (TXN_NOWAIT)
          const_iv (TXN_SYNC)

          const_iv (SET_LOCK_TIMEOUT)
          const_iv (SET_TXN_TIMEOUT)

          const_iv (FIRST)
          const_iv (NEXT)
          const_iv (NEXT_DUP)
          const_iv (NEXT_NODUP)
          const_iv (PREV)
          const_iv (PREV_NODUP)
          const_iv (SET)
          const_iv (SET_RANGE)
          const_iv (LAST)
          const_iv (BEFORE)
          const_iv (AFTER)
          const_iv (CURRENT)
          const_iv (KEYFIRST)
          const_iv (KEYLAST)
          const_iv (NODUPDATA)

          const_iv (FORCE)

          const_iv (LOCK_DEFAULT)
          const_iv (LOCK_EXPIRE)
          const_iv (LOCK_MAXLOCKS)
          const_iv (LOCK_MINLOCKS)
          const_iv (LOCK_MINWRITE)
          const_iv (LOCK_OLDEST)
          const_iv (LOCK_RANDOM)
          const_iv (LOCK_YOUNGEST)

          const_iv (DONOTINDEX)
          const_iv (KEYEMPTY)
          const_iv (KEYEXIST)
          const_iv (LOCK_DEADLOCK)
          const_iv (LOCK_NOTGRANTED)
          const_iv (NOSERVER)
#if DBVER < 502
          const_iv (NOSERVER_HOME)
          const_iv (NOSERVER_ID)
#endif
          const_iv (NOTFOUND)
          const_iv (PAGE_NOTFOUND)
          const_iv (REP_DUPMASTER)
          const_iv (REP_HANDLE_DEAD)
          const_iv (REP_HOLDELECTION)
          const_iv (REP_ISPERM)
          const_iv (REP_NEWMASTER)
          const_iv (REP_NEWSITE)
          const_iv (REP_NOTPERM)
          const_iv (REP_UNAVAIL)
          const_iv (RUNRECOVERY)
          const_iv (SECONDARY_BAD)
          const_iv (VERIFY_BAD)

          const_iv (SALVAGE)
          const_iv (AGGRESSIVE)
          const_iv (PRINTABLE)
          const_iv (NOORDERCHK)
          const_iv (ORDERCHKONLY)

          const_iv (ARCH_ABS)
          const_iv (ARCH_DATA)
          const_iv (ARCH_LOG)
          const_iv (ARCH_REMOVE)

          const_iv (VERB_DEADLOCK)
          const_iv (VERB_RECOVERY)
          const_iv (VERB_REPLICATION)
          const_iv (VERB_WAITSFOR)

          const_iv (VERSION_MAJOR)
          const_iv (VERSION_MINOR)
          const_iv (VERSION_PATCH)
          const_iv (LOGVERSION)
          const_iv (LOGOLDVER)
#if DBVER >= 403
          const_iv (INORDER)
          const_iv (LOCK_MAXWRITE)
          const_iv (SEQ_DEC)
          const_iv (SEQ_INC)
          const_iv (SEQ_WRAP)
          const_iv (BUFFER_SMALL)
          const_iv (LOG_BUFFER_FULL)
          const_iv (VERSION_MISMATCH)
#endif
#if DBVER >= 404
          const_iv (REGISTER)
          const_iv (DSYNC_DB)
          const_iv (READ_COMMITTED)
          const_iv (READ_UNCOMMITTED)
          const_iv (REP_IGNORE)
          const_iv (REP_LOCKOUT)
          const_iv (REP_JOIN_FAILURE)
          const_iv (FREE_SPACE)
          const_iv (FREELIST_ONLY)
          const_iv (VERB_REGISTER)
#endif
#if DBVER >= 405
          const_iv (MULTIVERSION)
          const_iv (TXN_SNAPSHOT)
#endif
#if DBVER >= 406
          const_iv (PREV_DUP)
          const_iv (PRIORITY_UNCHANGED)
          const_iv (PRIORITY_VERY_LOW)
          const_iv (PRIORITY_LOW)
          const_iv (PRIORITY_DEFAULT)
          const_iv (PRIORITY_HIGH)
          const_iv (PRIORITY_VERY_HIGH)
          const_iv (IGNORE_LEASE)
#endif
#if DBVER >= 407
          //const_iv (MULTIPLE_KEY)
          const_iv (LOG_DIRECT)
          const_iv (LOG_DSYNC)
          const_iv (LOG_AUTO_REMOVE)
          const_iv (LOG_IN_MEMORY)
          const_iv (LOG_ZERO)
#else
          const_iv (DIRECT_LOG)
          const_iv (LOG_AUTOREMOVE)
# if DBVER >= 403
          const_iv (DSYNC_LOG)
          const_iv (LOG_INMEMORY)
# endif
#if DBVER >= 408
          const_iv (LOGVERSION_LATCHING)
#endif
#endif
        };

	bdb_stash          = gv_stashpv ("BDB"          , 1);
        bdb_env_stash      = gv_stashpv ("BDB::Env"     , 1);
        bdb_txn_stash      = gv_stashpv ("BDB::Txn"     , 1);
        bdb_cursor_stash   = gv_stashpv ("BDB::Cursor"  , 1);
        bdb_db_stash       = gv_stashpv ("BDB::Db"      , 1);
        bdb_sequence_stash = gv_stashpv ("BDB::Sequence", 1);

        for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
          newCONSTSUB (bdb_stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

        prepare_cb = &PL_sv_undef;

        {
          /* we currently only allow version, minor-version and patchlevel to go up to 255 */
          char vstring[3] = { DB_VERSION_MAJOR, DB_VERSION_MINOR, DB_VERSION_PATCH };

          newCONSTSUB (bdb_stash, "VERSION_v", newSVpvn (vstring, 3));
        }

        newCONSTSUB (bdb_stash, "VERSION_STRING", newSVpv (DB_VERSION_STRING, 0));

        create_respipe ();

        X_THREAD_ATFORK (atfork_prepare, atfork_parent, atfork_child);
        patch_errno ();
}

void
max_poll_reqs (int nreqs)
	PROTOTYPE: $
        CODE:
        max_poll_reqs = nreqs;

void
max_poll_time (double nseconds)
	PROTOTYPE: $
        CODE:
        max_poll_time = nseconds * AIO_TICKS;

void
min_parallel (int nthreads)
	PROTOTYPE: $

void
max_parallel (int nthreads)
	PROTOTYPE: $

void
max_idle (int nthreads)
	PROTOTYPE: $
        CODE:
        set_max_idle (nthreads);

int
max_outstanding (int maxreqs)
	PROTOTYPE: $
        CODE:
        RETVAL = max_outstanding;
        max_outstanding = maxreqs;
	OUTPUT:
        RETVAL

int
dbreq_pri (int pri = 0)
	PROTOTYPE: ;$
	CODE:
	RETVAL = next_pri - PRI_BIAS;
	if (items > 0)
	  {
	    if (pri < PRI_MIN) pri = PRI_MIN;
	    if (pri > PRI_MAX) pri = PRI_MAX;
	    next_pri = pri + PRI_BIAS;
	  }
	OUTPUT:
	RETVAL

void
dbreq_nice (int nice = 0)
	CODE:
	nice = next_pri - nice;
	if (nice < PRI_MIN) nice = PRI_MIN;
	if (nice > PRI_MAX) nice = PRI_MAX;
	next_pri = nice + PRI_BIAS;

void
flush ()
	PROTOTYPE:
	CODE:
        while (nreqs)
          {
            poll_wait ();
            poll_cb ();
          }

int
poll ()
	PROTOTYPE:
	CODE:
        poll_wait ();
        RETVAL = poll_cb ();
	OUTPUT:
	RETVAL

int
poll_fileno ()
	PROTOTYPE:
	CODE:
        RETVAL = s_epipe_fd (&respipe);
	OUTPUT:
	RETVAL

int
poll_cb (...)
	PROTOTYPE:
	CODE:
        RETVAL = poll_cb ();
	OUTPUT:
	RETVAL

void
poll_wait ()
	PROTOTYPE:
	CODE:
        poll_wait ();

int
nreqs ()
	PROTOTYPE:
	CODE:
        RETVAL = nreqs;
	OUTPUT:
	RETVAL

int
nready ()
	PROTOTYPE:
	CODE:
        RETVAL = get_nready ();
	OUTPUT:
	RETVAL

int
npending ()
	PROTOTYPE:
	CODE:
        RETVAL = get_npending ();
	OUTPUT:
	RETVAL

int
nthreads ()
	PROTOTYPE:
	CODE:
        if (WORDACCESS_UNSAFE) X_LOCK   (wrklock);
        RETVAL = started;
        if (WORDACCESS_UNSAFE) X_UNLOCK (wrklock);
	OUTPUT:
	RETVAL

SV *
set_sync_prepare (SV *cb)
	PROTOTYPE: &
	CODE:
        RETVAL = prepare_cb;
        prepare_cb = newSVsv (cb);
	OUTPUT:
        RETVAL

char *
strerror (int errorno = errno)
	PROTOTYPE: ;$
        CODE:
        RETVAL = db_strerror (errorno);
	OUTPUT:
        RETVAL

void _on_next_submit (SV *cb)
        CODE:
        SvREFCNT_dec (on_next_submit);
        on_next_submit = SvOK (cb) ? newSVsv (cb) : 0;

DB_ENV *
db_env_create (U32 env_flags = 0)
	CODE:
{
        errno = db_env_create (&RETVAL, env_flags);
        if (errno)
          croak ("db_env_create: %s", db_strerror (errno));

        if (0)
          {
            RETVAL->set_errcall (RETVAL, debug_errcall);
            RETVAL->set_msgcall (RETVAL, debug_msgcall);
          }
}
	OUTPUT:
	RETVAL

void
db_env_open (DB_ENV *env, bdb_filename db_home, U32 open_flags, int mode, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_ENV_OPEN, 1);
        req->env   = env;
        req->uint1 = open_flags | DB_THREAD;
        req->int1  = mode;
        req->buf1  = strdup_ornull (db_home);
        REQ_SEND;
}

void
db_env_close (DB_ENV *env, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	dREQ (REQ_ENV_CLOSE, 0);
        ptr_nuke (ST (0));
        req->env   = env;
        req->uint1 = flags;
        REQ_SEND;
}

void
db_env_txn_checkpoint (DB_ENV *env, U32 kbyte = 0, U32 min = 0, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_ENV_TXN_CHECKPOINT, 1);
        req->env   = env;
        req->uint1 = kbyte;
        req->int1  = min;
        req->uint2 = flags;
        REQ_SEND;
}

void
db_env_lock_detect (DB_ENV *env, U32 flags = 0, U32 atype = DB_LOCK_DEFAULT, SV *dummy = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_ENV_LOCK_DETECT, 1);
        req->env   = env;
        req->uint1 = flags;
        req->uint2 = atype;
        /* req->int2  = 0; dummy */
        REQ_SEND;
}

void
db_env_memp_sync (DB_ENV *env, SV *dummy = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_ENV_MEMP_SYNC, 1);
        req->env  = env;
        REQ_SEND;
}

void
db_env_memp_trickle (DB_ENV *env, int percent, SV *dummy = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_ENV_MEMP_TRICKLE, 1);
        req->env  = env;
        req->int1 = percent;
        REQ_SEND;
}

void
db_env_dbremove (DB_ENV *env, DB_TXN_ornull *txnid, bdb_filename file, bdb_filename database, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	dREQ (REQ_ENV_DBREMOVE, 2);
        req->env   = env;
        req->buf1  = strdup_ornull (file);
        req->buf2  = strdup_ornull (database);
        req->uint1 = flags;
        REQ_SEND;
}

void
db_env_dbrename (DB_ENV *env, DB_TXN_ornull *txnid, bdb_filename file, bdb_filename database, bdb_filename newname, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	dREQ (REQ_ENV_DBRENAME, 2);
        req->env   = env;
        req->buf1  = strdup_ornull (file);
        req->buf2  = strdup_ornull (database);
        req->buf3  = strdup_ornull (newname);
        req->uint1 = flags;
        REQ_SEND;
}

void
db_env_lsn_reset (DB_ENV *env, bdb_filename db, U32 flags = 0, SV *callback = 0)
	ALIAS:
        db_env_fileid_reset = 1
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (ix ? REQ_ENV_FILEID_RESET : REQ_ENV_LSN_RESET, 1);
        req->env   = env;
        req->uint1 = flags;
        req->buf1  = strdup_ornull (db);
        REQ_SEND;
}

void
db_env_log_archive (DB_ENV *env, SV_mutable *listp, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	dREQ (REQ_ENV_LOG_ARCHIVE, 1);
        req->sv1   = SvREFCNT_inc (listp);
        req->env   = env;
        req->uint1 = flags;
        REQ_SEND;
}

DB *
db_create (DB_ENV *env = 0, U32 flags = 0)
	CODE:
{
        errno = db_create (&RETVAL, env, flags);
        if (errno)
          croak ("db_create: %s", db_strerror (errno));

        if (RETVAL)
          RETVAL->app_private = (void *)newSVsv (ST (0));
}
	OUTPUT:
	RETVAL

void
db_open (DB *db, DB_TXN_ornull *txnid, bdb_filename file, bdb_filename database, int type, U32 flags, int mode, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_OPEN, 2);
        req->db    = db;
        req->txn   = txnid;
        req->buf1  = strdup_ornull (file);
        req->buf2  = strdup_ornull (database);
        req->int1  = type;
        req->uint1 = flags | DB_THREAD;
        req->int2  = mode;
        REQ_SEND;
}

void
db_close (DB *db, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_CLOSE, 0);
        ptr_nuke (ST (0));
        req->db    = db;
        req->uint1 = flags;
        req->sv1   = (SV *)db->app_private;
        REQ_SEND;
}

#if DBVER >= 404

void
db_compact (DB *db, DB_TXN_ornull *txn = 0, SV *start = 0, SV *stop = 0, SV *unused1 = 0, U32 flags = DB_FREE_SPACE, SV *unused2 = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_COMPACT, 2);
        req->db    = db;
        req->txn   = txn;
        if (start) sv_to_dbt (&req->dbt1, start);
        if (stop ) sv_to_dbt (&req->dbt2, stop );
        req->uint1 = flags;
        REQ_SEND;
}

#endif

void
db_sync (DB *db, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_SYNC, 1);
        req->db    = db;
        req->uint1 = flags;
        REQ_SEND;
}

void
db_verify (DB *db, bdb_filename file, bdb_filename database = 0, SV *dummy = 0, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_VERIFY, 1);
        ptr_nuke (ST (0)); /* verify destroys the database handle, hopefully it is freed as well */
        req->db    = db;
        req->buf1  = strdup (file);
        req->buf2  = strdup_ornull (database);
        req->uint1 = flags;
        REQ_SEND;
}

void
db_upgrade (DB *db, bdb_filename file, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_UPGRADE, 1);
        req->db    = db;
        req->buf1  = strdup (file);
        req->uint1 = flags;
        REQ_SEND;
}

void
db_key_range (DB *db, DB_TXN_ornull *txn, SV *key, SV_mutable *key_range, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_KEY_RANGE, 2);
        req->db    = db;
        req->txn   = txn;
        sv_to_dbt (&req->dbt1, key);
        req->uint1 = flags;
        req->sv1   = SvREFCNT_inc (key_range); SvREADONLY_on (key_range);
        REQ_SEND;
}

void
db_put (DB *db, DB_TXN_ornull *txn, SV *key, SV *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_PUT, 2);
        req->db    = db;
        req->txn   = txn;
        sv_to_dbt (&req->dbt1, key);
        sv_to_dbt (&req->dbt2, data);
        req->uint1 = flags;
        REQ_SEND;
}

#if DBVER >= 406

void
db_exists (DB *db, DB_TXN_ornull *txn, SV *key, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_EXISTS, 2);
        req->db    = db;
        req->txn   = txn;
        req->uint1 = flags;
        sv_to_dbt (&req->dbt1, key);
        REQ_SEND;
}

#endif

void
db_get (DB *db, DB_TXN_ornull *txn, SV *key, SV_mutable *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	//TODO: key is somtimesmutable
        dREQ (REQ_DB_GET, 2);
        req->db    = db;
        req->txn   = txn;
        req->uint1 = flags;
        sv_to_dbt (&req->dbt1, key);
        req->dbt3.flags = DB_DBT_MALLOC;
        req->sv3 = SvREFCNT_inc (data); SvREADONLY_on (data);
        REQ_SEND;
}

void
db_pget (DB *db, DB_TXN_ornull *txn, SV *key, SV_mutable *pkey, SV_mutable *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
	//TODO: key is somtimesmutable
        dREQ (REQ_DB_PGET, 2);
        req->db    = db;
        req->txn   = txn;
        req->uint1 = flags;

        sv_to_dbt (&req->dbt1, key);

        req->dbt2.flags = DB_DBT_MALLOC;
        req->sv2 = SvREFCNT_inc (pkey); SvREADONLY_on (pkey);

        req->dbt3.flags = DB_DBT_MALLOC;
        req->sv3 = SvREFCNT_inc (data); SvREADONLY_on (data);
        REQ_SEND;
}

void
db_del (DB *db, DB_TXN_ornull *txn, SV *key, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_DB_DEL, 2);
        req->db    = db;
        req->txn   = txn;
        req->uint1 = flags;
        sv_to_dbt (&req->dbt1, key);
        REQ_SEND;
}

void
db_txn_commit (DB_TXN *txn, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_TXN_COMMIT, 0);
        ptr_nuke (ST (0));
        req->txn   = txn;
        req->uint1 = flags;
        REQ_SEND;
}

void
db_txn_abort (DB_TXN *txn, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_TXN_ABORT, 0);
        ptr_nuke (ST (0));
        req->txn   = txn;
        REQ_SEND;
}

void
db_txn_finish (DB_TXN *txn, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_TXN_FINISH, 0);
        ptr_nuke (ST (0));
        req->txn   = txn;
        req->uint1 = flags;
        REQ_SEND;
}

void
db_c_close (DBC *dbc, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_C_CLOSE, 0);
        ptr_nuke (ST (0));
        req->dbc = dbc;
        REQ_SEND;
}

void
db_c_count (DBC *dbc, SV *count, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_C_COUNT, 1);
        req->dbc = dbc;
        req->sv1 = SvREFCNT_inc (count);
        REQ_SEND;
}

void
db_c_put (DBC *dbc, SV *key, SV *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_C_PUT, 1);
        req->dbc   = dbc;
        sv_to_dbt (&req->dbt1, key);
        sv_to_dbt (&req->dbt2, data);
        req->uint1 = flags;
        REQ_SEND;
}

void
db_c_get (DBC *dbc, SV *key, SV_mutable *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        if ((flags & DB_OPFLAGS_MASK) != DB_SET && SvREADONLY (key))
          croak ("db_c_get was passed a read-only/constant 'key' argument but operation is not DB_SET");
        if (SvPOKp (key) && !sv_utf8_downgrade (key, 1))
          croak ("argument \"%s\" must be byte/octet-encoded in %s",
                 "key",
                 "BDB::db_c_get");

        {
          dREQ (REQ_C_GET, 1);
          req->dbc   = dbc;
          req->uint1 = flags;
          if ((flags & DB_OPFLAGS_MASK) == DB_SET)
            sv_to_dbt (&req->dbt1, key);
          else
            {
              if ((flags & DB_OPFLAGS_MASK) == DB_SET_RANGE)
                sv_to_dbt (&req->dbt1, key);
              else
                req->dbt1.flags = DB_DBT_MALLOC;

              req->sv1 = SvREFCNT_inc (key); SvREADONLY_on (key);
            }

          if ((flags & DB_OPFLAGS_MASK) == DB_GET_BOTH
              || (flags & DB_OPFLAGS_MASK) == DB_GET_BOTH_RANGE)
            sv_to_dbt (&req->dbt3, data);
          else
            req->dbt3.flags = DB_DBT_MALLOC;

          req->sv3 = SvREFCNT_inc (data); SvREADONLY_on (data);
          REQ_SEND;
        }
}

void
db_c_pget (DBC *dbc, SV *key, SV_mutable *pkey, SV_mutable *data, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        if ((flags & DB_OPFLAGS_MASK) != DB_SET && SvREADONLY (key))
          croak ("db_c_pget was passed a read-only/constant 'key' argument but operation is not DB_SET");
        if (SvPOKp (key) && !sv_utf8_downgrade (key, 1))
          croak ("argument \"%s\" must be byte/octet-encoded in %s",
                 "key",
                 "BDB::db_c_pget");

        {
          dREQ (REQ_C_PGET, 1);
          req->dbc   = dbc;
          req->uint1 = flags;
          if ((flags & DB_OPFLAGS_MASK) == DB_SET)
            sv_to_dbt (&req->dbt1, key);
          else
            {
              if ((flags & DB_OPFLAGS_MASK) == DB_SET_RANGE)
                sv_to_dbt (&req->dbt1, key);
              else
                req->dbt1.flags = DB_DBT_MALLOC;

              req->sv1 = SvREFCNT_inc (key); SvREADONLY_on (key);
            }

          req->dbt2.flags = DB_DBT_MALLOC;
          req->sv2 = SvREFCNT_inc (pkey); SvREADONLY_on (pkey);

          if ((flags & DB_OPFLAGS_MASK) == DB_GET_BOTH
              || (flags & DB_OPFLAGS_MASK) == DB_GET_BOTH_RANGE)
            sv_to_dbt (&req->dbt3, data);
          else
            req->dbt3.flags = DB_DBT_MALLOC;

          req->sv3 = SvREFCNT_inc (data); SvREADONLY_on (data);
          REQ_SEND;
        }
}

void
db_c_del (DBC *dbc, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_C_DEL, 1);
        req->dbc   = dbc;
        req->uint1 = flags;
        REQ_SEND;
}


#if DBVER >= 403

void
db_sequence_open (DB_SEQUENCE *seq, DB_TXN_ornull *txnid, SV *key, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_SEQ_OPEN, 2);
        req->seq   = seq;
        req->txn   = txnid;
        req->uint1 = flags | DB_THREAD;
        sv_to_dbt (&req->dbt1, key);
        REQ_SEND;
}

void
db_sequence_close (DB_SEQUENCE *seq, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_SEQ_CLOSE, 0);
        ptr_nuke (ST (0));
        req->seq   = seq;
        req->uint1 = flags;
        REQ_SEND;
}

void
db_sequence_get (DB_SEQUENCE *seq, DB_TXN_ornull *txnid, int delta, SV_mutable *seq_value, U32 flags = DB_TXN_NOSYNC, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_SEQ_GET, 2);
        req->seq   = seq;
        req->txn   = txnid;
        req->int1  = delta;
        req->uint1 = flags;
        req->sv1   = SvREFCNT_inc (seq_value); SvREADONLY_on (seq_value);
        REQ_SEND;
}

void
db_sequence_remove (DB_SEQUENCE *seq, DB_TXN_ornull *txnid = 0, U32 flags = 0, SV *callback = 0)
	PREINIT:
        CALLBACK
	CODE:
{
        dREQ (REQ_SEQ_REMOVE, 2);
        req->seq   = seq;
        req->txn   = txnid;
        req->uint1 = flags;
        REQ_SEND;
}

#endif


MODULE = BDB		PACKAGE = BDB::Env

void
DESTROY (DB_ENV_ornuked *env)
	CODE:
        if (env)
          env->close (env, 0);

int set_data_dir (DB_ENV *env, const char *dir)
	CODE:
        RETVAL = env->set_data_dir (env, dir);
	OUTPUT:
        RETVAL

int set_tmp_dir (DB_ENV *env, const char *dir)
	CODE:
        RETVAL = env->set_tmp_dir (env, dir);
	OUTPUT:
        RETVAL

int set_lg_dir (DB_ENV *env, const char *dir)
	CODE:
        RETVAL = env->set_lg_dir (env, dir);
	OUTPUT:
        RETVAL

int set_shm_key (DB_ENV *env, long shm_key)
	CODE:
        RETVAL = env->set_shm_key (env, shm_key);
	OUTPUT:
        RETVAL

int set_cachesize (DB_ENV *env, U32 gbytes, U32 bytes, int ncache = 0)
	CODE:
        RETVAL = env->set_cachesize (env, gbytes, bytes, ncache);
	OUTPUT:
        RETVAL

int set_flags (DB_ENV *env, U32 flags, int onoff = 1)
	CODE:
        RETVAL = env->set_flags (env, flags, onoff);
	OUTPUT:
        RETVAL

#if DBVER >= 407

int set_intermediate_dir_mode (DB_ENV *env, const char *mode)
	CODE:
        RETVAL = env->set_intermediate_dir_mode (env, mode);
	OUTPUT:
        RETVAL

int log_set_config (DB_ENV *env, U32 flags, int onoff = 1)
	CODE:
        RETVAL = env->log_set_config (env, flags, onoff);
	OUTPUT:
        RETVAL

#endif


void set_errfile (DB_ENV *env, FILE *errfile = 0)
	CODE:
        env->set_errfile (env, errfile);

void set_msgfile (DB_ENV *env, FILE *msgfile = 0)
	CODE:
        env->set_msgfile (env, msgfile);

int set_verbose (DB_ENV *env, U32 which = -1, int onoff = 1)
	CODE:
        RETVAL = env->set_verbose (env, which, onoff);
	OUTPUT:
        RETVAL

int set_encrypt (DB_ENV *env, const char *password, U32 flags = 0)
	CODE:
        RETVAL = env->set_encrypt (env, password, flags);
	OUTPUT:
        RETVAL

int set_timeout (DB_ENV *env, NV timeout, U32 flags = DB_SET_TXN_TIMEOUT)
	CODE:
        RETVAL = env->set_timeout (env, timeout * 1000000, flags);
	OUTPUT:
        RETVAL

int set_mp_max_openfd (DB_ENV *env, int maxopenfd);
	CODE:
        RETVAL = env->set_mp_max_openfd (env, maxopenfd);
	OUTPUT:
        RETVAL

int set_mp_max_write (DB_ENV *env, int maxwrite, int maxwrite_sleep);
	CODE:
        RETVAL = env->set_mp_max_write (env, maxwrite, maxwrite_sleep);
	OUTPUT:
        RETVAL

int set_mp_mmapsize (DB_ENV *env, int mmapsize_mb)
	CODE:
        RETVAL = env->set_mp_mmapsize (env, ((size_t)mmapsize_mb) << 20);
	OUTPUT:
        RETVAL

int set_lk_detect (DB_ENV *env, U32 detect = DB_LOCK_DEFAULT)
	CODE:
        RETVAL = env->set_lk_detect (env, detect);
	OUTPUT:
        RETVAL

int set_lk_max_lockers (DB_ENV *env, U32 max)
	CODE:
        RETVAL = env->set_lk_max_lockers (env, max);
	OUTPUT:
        RETVAL

int set_lk_max_locks (DB_ENV *env, U32 max)
	CODE:
        RETVAL = env->set_lk_max_locks (env, max);
	OUTPUT:
        RETVAL

int set_lk_max_objects (DB_ENV *env, U32 max)
	CODE:
        RETVAL = env->set_lk_max_objects (env, max);
	OUTPUT:
        RETVAL

int set_lg_bsize (DB_ENV *env, U32 max)
	CODE:
        RETVAL = env->set_lg_bsize (env, max);
	OUTPUT:
        RETVAL

int set_lg_max (DB_ENV *env, U32 max)
	CODE:
        RETVAL = env->set_lg_max (env, max);
	OUTPUT:
        RETVAL

#if DBVER >= 404

int mutex_set_max (DB_ENV *env, U32 max)
        CODE:
        RETVAL = env->mutex_set_max (env, max);
        OUTPUT:
        RETVAL

int mutex_set_increment (DB_ENV *env, U32 increment)
        CODE:
        RETVAL = env->mutex_set_increment (env, increment);
        OUTPUT:
        RETVAL

int mutex_set_tas_spins (DB_ENV *env, U32 tas_spins)
        CODE:
        RETVAL = env->mutex_set_tas_spins (env, tas_spins);
        OUTPUT:
        RETVAL

int mutex_set_align (DB_ENV *env, U32 align)
        CODE:
        RETVAL = env->mutex_set_align (env, align);
        OUTPUT:
        RETVAL

#endif

DB_TXN *
txn_begin (DB_ENV *env, DB_TXN_ornull *parent = 0, U32 flags = 0)
	CODE:
        errno = env->txn_begin (env, parent, &RETVAL, flags);
        if (errno)
          croak ("DB_ENV->txn_begin: %s", db_strerror (errno));
        OUTPUT:
        RETVAL

#if DBVER >= 405

DB_TXN *
cdsgroup_begin (DB_ENV *env)
	CODE:
        errno = env->cdsgroup_begin (env, &RETVAL);
        if (errno)
          croak ("DB_ENV->cdsgroup_begin: %s", db_strerror (errno));
        OUTPUT:
        RETVAL

#endif

MODULE = BDB		PACKAGE = BDB::Db

void
DESTROY (DB_ornuked *db)
	CODE:
        if (db)
          {
            SV *env = (SV *)db->app_private;
            db->close (db, 0);
            SvREFCNT_dec (env);
          }

int set_cachesize (DB *db, U32 gbytes, U32 bytes, int ncache = 0)
	CODE:
        RETVAL = db->set_cachesize (db, gbytes, bytes, ncache);
	OUTPUT:
        RETVAL

int set_pagesize (DB *db, U32 pagesize)
	CODE:
        RETVAL = db->set_pagesize (db, pagesize);
	OUTPUT:
        RETVAL

int set_flags (DB *db, U32 flags)
	CODE:
        RETVAL = db->set_flags (db, flags);
	OUTPUT:
        RETVAL

int set_encrypt (DB *db, const char *password, U32 flags)
	CODE:
        RETVAL = db->set_encrypt (db, password, flags);
	OUTPUT:
        RETVAL

int set_lorder (DB *db, int lorder)
	CODE:
        RETVAL = db->set_lorder (db, lorder);
	OUTPUT:
        RETVAL

int set_bt_minkey (DB *db, U32 minkey)
	CODE:
        RETVAL = db->set_bt_minkey (db, minkey);
	OUTPUT:
        RETVAL

int set_re_delim (DB *db, int delim)
	CODE:
        RETVAL = db->set_re_delim (db, delim);
	OUTPUT:
        RETVAL

int set_re_pad (DB *db, int re_pad)
	CODE:
        RETVAL = db->set_re_pad (db, re_pad);
	OUTPUT:
        RETVAL

int set_re_source (DB *db, char *source)
	CODE:
        RETVAL = db->set_re_source (db, source);
	OUTPUT:
        RETVAL

int set_re_len (DB *db, U32 re_len)
	CODE:
        RETVAL = db->set_re_len (db, re_len);
	OUTPUT:
        RETVAL

int set_h_ffactor (DB *db, U32 h_ffactor)
	CODE:
        RETVAL = db->set_h_ffactor (db, h_ffactor);
	OUTPUT:
        RETVAL

int set_h_nelem (DB *db, U32 h_nelem)
	CODE:
        RETVAL = db->set_h_nelem (db, h_nelem);
	OUTPUT:
        RETVAL

int set_q_extentsize (DB *db, U32 extentsize)
	CODE:
        RETVAL = db->set_q_extentsize (db, extentsize);
	OUTPUT:
        RETVAL

DBC *
cursor (DB *db, DB_TXN_ornull *txn = 0, U32 flags = 0)
	CODE:
        errno = db->cursor (db, txn, &RETVAL, flags);
        if (errno)
          croak ("DB->cursor: %s", db_strerror (errno));
        OUTPUT:
        RETVAL

#if DBVER >= 403

DB_SEQUENCE *
sequence (DB *db, U32 flags = 0)
	CODE:
{
        errno = db_sequence_create (&RETVAL, db, flags);
        if (errno)
          croak ("db_sequence_create: %s", db_strerror (errno));
}
	OUTPUT:
	RETVAL

#endif


MODULE = BDB		PACKAGE = BDB::Txn

void
DESTROY (DB_TXN_ornuked *txn)
	CODE:
        if (txn)
          txn->abort (txn);

int set_timeout (DB_TXN *txn, NV timeout, U32 flags = DB_SET_TXN_TIMEOUT)
	CODE:
        RETVAL = txn->set_timeout (txn, timeout * 1000000, flags);
	OUTPUT:
        RETVAL

int failed (DB_TXN *txn)
	CODE:
        RETVAL = !!(txn->flags & TXN_DEADLOCK);
	OUTPUT:
        RETVAL


MODULE = BDB		PACKAGE = BDB::Cursor

void
DESTROY (DBC_ornuked *dbc)
	CODE:
        if (dbc)
          dbc->c_close (dbc);

#if DBVER >= 406

int set_priority (DBC *dbc, int priority)
        CODE:
        dbc->set_priority (dbc, priority);

#endif

#if DBVER >= 403

MODULE = BDB		PACKAGE = BDB::Sequence

void
DESTROY (DB_SEQUENCE_ornuked *seq)
	CODE:
        if (seq)
          seq->close (seq, 0);

int initial_value (DB_SEQUENCE *seq, db_seq_t value)
	CODE:
        RETVAL = seq->initial_value (seq, value);
	OUTPUT:
        RETVAL

int set_cachesize (DB_SEQUENCE *seq, U32 size)
	CODE:
        RETVAL = seq->set_cachesize (seq, size);
	OUTPUT:
        RETVAL

int set_flags (DB_SEQUENCE *seq, U32 flags)
	CODE:
        RETVAL = seq->set_flags (seq, flags);
	OUTPUT:
        RETVAL

int set_range (DB_SEQUENCE *seq, db_seq_t min, db_seq_t max)
	CODE:
        RETVAL = seq->set_range (seq, min, max);
	OUTPUT:
        RETVAL

#endif


