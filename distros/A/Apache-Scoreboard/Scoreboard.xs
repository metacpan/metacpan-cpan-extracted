#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include "mod_perl.h"
#include "modperl_xs_sv_convert.h"
#include "modperl_xs_typedefs.h"
#include "modperl_xs_util.h"

#include "scoreboard.h"

/* XXX: currently only for mp2 */
#define SB_TRACE_DO 0

#if SB_TRACE_DO && defined(MP_TRACE)
#define SB_TRACE modperl_trace
#else
#define SB_TRACE if (0) modperl_trace
#endif

/* scoreboard */
typedef struct {
    scoreboard *sb;
    apr_pool_t *pool;
    int server_limit;
    int thread_limit;
} modperl_scoreboard_t;

typedef struct {
    worker_score *record;
    int parent_idx;
    int worker_idx;
} modperl_worker_score_t;

/* XXX: notice that here we reference a struct living in a different
 * perl object ($image), so if that object is destroyed earlier we get
 * a segfault. a possible solution: inline modperl_scoreboard_t in
 * modperl_parent_score_t (can't create a dependency inside $image,
 * since there can be many objects referencing it, will require a
 * complicated real ref counting)
 */
typedef struct {
    process_score *record;
    int idx;
    modperl_scoreboard_t *image;
} modperl_parent_score_t;

typedef modperl_scoreboard_t   *Apache__Scoreboard;
typedef modperl_worker_score_t *Apache__ScoreboardWorkerScore;
typedef modperl_parent_score_t *Apache__ScoreboardParentScore;

static char status_flags[SERVER_NUM_STATUS];

#define server_limit(image) image->server_limit
#define thread_limit(image) image->thread_limit
    
#define scoreboard_up_time(image)                               \
    (apr_uint32_t) apr_time_sec(                                \
        apr_time_now() - image->sb->global->restart_time);

#define parent_score_pid(mps)  mps->record->pid

#define worker_score_most_recent(mws)                                   \
    (apr_uint32_t) apr_time_sec(apr_time_now() - mws->record->last_used);

/* XXX: as of 20031219, tid is not maintained in scoreboard */
#if APR_HAS_THREADS
#define worker_score_tid(mws)             mws->record->tid
#else
#define worker_score_tid(mws)             NULL
#endif

#define worker_score_thread_num(mws)      mws->record->thread_num
#define worker_score_access_count(mws)    mws->record->access_count
#define worker_score_bytes_served(mws)    mws->record->bytes_served
#define worker_score_my_access_count(mws) mws->record->my_access_count
#define worker_score_my_bytes_served(mws) mws->record->my_bytes_served
#define worker_score_conn_bytes(mws)      mws->record->conn_bytes
#define worker_score_conn_count(mws)      mws->record->conn_count
#define worker_score_client(mws)          mws->record->client
#define worker_score_request(mws)         mws->record->request
#define worker_score_vhost(mws)           mws->record->vhost

/* a worker that have served/serves at least one request and isn't
 * dead yet */
#define LIVE_WORKER(ws) !(ws->access_count == 0 && ws->status == SERVER_DEAD)

/* a worker that does something at this very moment */
#define ACTIVE_WORKER(ws)                                               \
    !(ws->access_count == 0 &&                                          \
      (ws->status == SERVER_DEAD || ws->status == SERVER_READY))

#include "apxs/send.c"

static void status_flags_init(void)
{
    status_flags[SERVER_DEAD]           = '.';
    status_flags[SERVER_READY]          = '_';
    status_flags[SERVER_STARTING]       = 'S';
    status_flags[SERVER_BUSY_READ]      = 'R';
    status_flags[SERVER_BUSY_WRITE]     = 'W';
    status_flags[SERVER_BUSY_KEEPALIVE] = 'K';
    status_flags[SERVER_BUSY_LOG]       = 'L';
    status_flags[SERVER_BUSY_DNS]       = 'D';
    status_flags[SERVER_CLOSING]        = 'C';
    status_flags[SERVER_GRACEFUL]       = 'G';
    status_flags[SERVER_IDLE_KILL]      = 'I';
}

static void constants_init(pTHX)
{
      HV *stash;
      int server_limit, thread_limit;

      /* SERVER_LIMIT and THREAD_LIMIT constants are deprecated, use
       * $image->server_limit and $image->thread_limit instead */
#ifndef DUMMY_SCOREBOARD
    ap_mpm_query(AP_MPMQ_HARD_LIMIT_DAEMONS, &server_limit);
    ap_mpm_query(AP_MPMQ_HARD_LIMIT_THREADS, &thread_limit);
#else
    /* XXX: how can we figure out that data w/o having an access to
     * ap_mpm_query? */
    server_limit = 0;
    thread_limit = 0;
#endif
    
    stash = gv_stashpv("Apache::Const", TRUE);
    newCONSTSUB(stash, "SERVER_LIMIT", newSViv(server_limit));
    
    stash = gv_stashpv("Apache::Const", TRUE);
    newCONSTSUB(stash, "THREAD_LIMIT", newSViv(thread_limit));

    stash = gv_stashpv("Apache::Scoreboard", TRUE);
    newCONSTSUB(stash, "REMOTE_SCOREBOARD_TYPE",
                newSVpv(REMOTE_SCOREBOARD_TYPE, 0));

}

MP_INLINE
static worker_score *my_get_scoreboard_worker(pTHX_
                                              modperl_scoreboard_t *image,
                                              int x, int y)
{
    if (((x < 0) || (image->server_limit < x)) ||
        ((y < 0) || (image->thread_limit < y))) {
        Perl_croak(aTHX_ "worker score [%d][%d] is out of limit", x, y);
    }
    return &image->sb->servers[x][y];
}

MP_INLINE
static process_score *my_get_scoreboard_process(pTHX_
                                                modperl_scoreboard_t *image,
                                                int x)
{
    if ((x < 0) || (image->server_limit < x)) {
        Perl_croak(aTHX_ "parent score [%d] is out of limit", x);
    }
    return &image->sb->parent[x];
}

static void image_sanity_check(pTHX)
{
#ifdef DUMMY_SCOREBOARD
    Perl_croak(aTHX_ "Don't call the image() method when not"
               "running under mod_perl");
#endif
}

#ifdef DUMMY_SCOREBOARD
#define MY_WARN fprintf(stderr,
#else
#define MY_WARN ap_log_error(APLOG_MARK, APLOG_ERR, 0, modperl_global_get_server_rec(),
#endif
      
#if 0
static void debug_dump_sb(modperl_scoreboard_t *image)
{
    int i, j;

    for (i = 0; i < image->server_limit; i++) {
        for (j = 0; j < image->thread_limit; j++) {
            worker_score *ws = &image->sb->servers[i][j];
            if (ws->access_count) {
                MY_WARN
                    "rcv %02d-%02d: stat: %c cnt: %d\n", i, j,
                    status_flags[ws->status],
                    (int)ws->access_count);
            }
        }
    }
}
#endif







MODULE = Apache::Scoreboard   PACKAGE = Apache::Scoreboard   PREFIX = scoreboard_

BOOT:
{

    /* XXX: this must be performed only once and before other threads are spawned.
     * but not sure. could be that need to use local storage.
     *
     */
    status_flags_init();
    
    constants_init(aTHX);
}

int
scoreboard_send(r)
    Apache2::RequestRec r


SV *
freeze(image)
    Apache::Scoreboard image

    PREINIT:
    int psize, ssize, tsize, msize, i;
    char buf[SIZE16*4];
    char *dptr, *ptr = buf;
    scoreboard *sb;

    CODE:
    sb = image->sb;
    
    psize = sizeof(process_score) * image->server_limit;
    msize = sizeof(worker_score)  * image->thread_limit;
    ssize = msize * image->server_limit;
    tsize = psize + ssize + sizeof(global_score) + sizeof(buf);
    /* fprintf(stderr, "sizes %d, %d, %d, %d, %d\n",
       psize, ssize, sizeof(global_score) , sizeof(buf), tsize); */
                 
    pack16(ptr, psize);
    ptr += SIZE16;
    pack16(ptr, ssize);
    ptr += SIZE16;
    pack16(ptr, image->server_limit);
    ptr += SIZE16;
    pack16(ptr, image->thread_limit);

    RETVAL = NEWSV(0, tsize);
    dptr = SvPVX(RETVAL);
    SvCUR_set(RETVAL, tsize+1);
    SvPOK_only(RETVAL);

    /* fill the data buffer with the data we want to freeze */
    Move(&buf[0],        dptr, sizeof(buf),          char);
    dptr += sizeof(buf);
    Move(&sb->parent[0], dptr, psize,                char);
    dptr += psize;
    for (i = 0; i < image->server_limit; i++) {
        Move(sb->servers[i], dptr, msize, char);
        dptr += msize;
    }
    Move(&sb->global,    dptr, sizeof(global_score), char);

    OUTPUT:
    RETVAL

Apache::Scoreboard
thaw(CLASS, pool, packet)
    SV *CLASS
    APR::Pool pool
    SV *packet

    PREINIT:
    modperl_scoreboard_t *image;
    scoreboard *sb;
    int psize, ssize;
    char *ptr;
    int i;
    
    CODE:
    if (!(SvOK(packet) && SvCUR(packet) > (SIZE16*2))) {
        XSRETURN_UNDEF;
    }

    CLASS = CLASS; /* avoid warnings */
 
    image = (modperl_scoreboard_t *)apr_pcalloc(pool, sizeof(*image));

    ptr = SvPVX(packet);
    psize = unpack16(ptr);
    ptr += SIZE16;
    ssize = unpack16(ptr);
    ptr += SIZE16;
    image->server_limit = unpack16(ptr);
    ptr += SIZE16;
    image->thread_limit = unpack16(ptr);
    ptr += SIZE16;

   /* MY_WARN
      "recv: sizes server_num=%d, thread_num=%d, psize=%d, "
                 "ssize=%d\n",
                 image->server_limit, image->thread_limit, psize, ssize);
   */

    sb = (scoreboard *)apr_palloc(pool, sizeof(scoreboard) +
                                   image->server_limit * sizeof(worker_score *));
    sb->parent  = (process_score *)Copy_pool(pool, ptr, psize, char);
    ptr += psize;

    sb->servers = (worker_score **)((char*)sb + sizeof(scoreboard));
    for (i = 0; i < image->server_limit; i++) {
        sb->servers[i] = (worker_score *)Copy_pool(pool, ptr,
                                                   image->thread_limit * sizeof(worker_score), char);
        ptr += image->thread_limit * sizeof(worker_score);
    }

    sb->global  = (global_score *)Copy_pool(pool, ptr,
                                            sizeof(global_score), char);

    image->pool = pool;
    image->sb   = sb;

   /* debug_dump_sb(image); */

    RETVAL = image;

    OUTPUT:
    RETVAL


SV *
image(CLASS, pool_sv)
    SV *CLASS
    SV *pool_sv
    
    INIT:
    modperl_scoreboard_t *image;
    apr_pool_t *pool = mp_xs_sv2_APR__Pool(pool_sv);

    CODE:
    image_sanity_check(aTHX);

    image = (modperl_scoreboard_t *)apr_palloc(pool, sizeof(*image));

    if (ap_exists_scoreboard_image()) {
        image->sb   = ap_scoreboard_image;
        image->pool = pool;
        ap_mpm_query(AP_MPMQ_HARD_LIMIT_DAEMONS, &(image->server_limit));
        ap_mpm_query(AP_MPMQ_HARD_LIMIT_THREADS, &(image->thread_limit));
    }
    else {
        Perl_croak(aTHX_ "ap_scoreboard_image doesn't exist");
    }
    RETVAL = sv_setref_pv(NEWSV(0, 0), "Apache::Scoreboard", (void*)image);
    /* make sure the pool sticks around as long as this object is alive */
    mpxs_add_pool_magic(RETVAL, pool_sv);

    CLASS = CLASS; /* avoid warnings */

    OUTPUT:
    RETVAL


int
server_limit(image)
    Apache::Scoreboard image

int
thread_limit(image)
    Apache::Scoreboard image

    
Apache::ScoreboardParentScore
parent_score(image, idx=0)
    Apache::Scoreboard image
    int idx

    PREINIT:
    process_score *ps;
    
    CODE:
    ps = my_get_scoreboard_process(aTHX_ image, idx);
    /* XXX */
    if (!ps->quiescing && ps->pid) {
        RETVAL = (modperl_parent_score_t *)apr_pcalloc(image->pool,
                                                       (sizeof(*RETVAL)));
        RETVAL->record = ps;
        RETVAL->idx    = idx;
        RETVAL->image  = image;
    }
    else {
        XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

Apache::ScoreboardWorkerScore
worker_score(image, parent_idx, worker_idx)
    Apache::Scoreboard image
    int parent_idx
    int worker_idx

    PREINIT:
    worker_score *ws;
    
    CODE:
    ws = my_get_scoreboard_worker(aTHX_ image, parent_idx, worker_idx);
    RETVAL = (modperl_worker_score_t *)apr_pcalloc(image->pool,
                                                   (sizeof(*RETVAL)));
    RETVAL->parent_idx = parent_idx;
    RETVAL->worker_idx = worker_idx;
    RETVAL->record = ws;
    
    OUTPUT:
    RETVAL

SV *
pids(image)
    Apache::Scoreboard image

    PREINIT:
    AV *av = newAV();
    int i;
    scoreboard *sb;

    CODE:
    sb = image->sb;
    for (i = 0; i < image->server_limit; i++) {
        if (!(sb->parent[i].pid)) {
            break;
        }
        /* fprintf(stderr, "pids: server %d: pid %d\n",
           i, (int)(sb->parent[i].pid)); */
        av_push(av, newSViv(sb->parent[i].pid));
    }
        
    RETVAL = newRV_noinc((SV*)av);

    OUTPUT:
    RETVAL

# XXX: need to move pid_t => apr_proc_t and work with pid->pid as in
# find_child_by_pid from scoreboard.c

int
parent_idx_by_pid(image, pid)   
    Apache::Scoreboard image
    pid_t pid

    PREINIT:
    int i;
    scoreboard *sb;

    CODE:
    sb = image->sb;
    RETVAL = -1;

    for (i = 0; i < image->server_limit; i++) {
        if (sb->parent[i].pid == pid) {
            RETVAL = i;
            break;
        }
    }

    OUTPUT:
    RETVAL

SV *
thread_numbers(image, parent_idx)
    Apache::Scoreboard image
    int parent_idx

    PREINIT:
    AV *av = newAV();
    int i;
    scoreboard *sb;

    CODE:
    sb = image->sb;

    for (i = 0; i < image->thread_limit; ++i) {
        /* fprintf(stderr, "thread_num: server %d, thread %d pid %d\n",
           i, sb->servers[parent_idx][i].thread_num,
           (int)(sb->parent[parent_idx].pid)); */
        
        av_push(av, newSViv(sb->servers[parent_idx][i].thread_num));
    }

    RETVAL = newRV_noinc((SV*)av);

    OUTPUT:
    RETVAL

apr_uint32_t
scoreboard_up_time(image)
    Apache::Scoreboard image








MODULE = Apache::Scoreboard PACKAGE = Apache::ScoreboardParentScore PREFIX = parent_score_
    
Apache::ScoreboardParentScore
next(self)
    Apache::ScoreboardParentScore self

    PREINIT:
    int next_idx;
    process_score *ps;
    modperl_scoreboard_t *image;

    CODE:
    image = self->image;
    next_idx = self->idx + 1;
    if (next_idx <= image->server_limit) {
        ps = my_get_scoreboard_process(aTHX_ image, next_idx);
    }
    else {
        XSRETURN_UNDEF;
    }

    if (ps->pid) {
        RETVAL = (modperl_parent_score_t *)apr_pcalloc(image->pool,
                                                       sizeof(*RETVAL));
        RETVAL->record = ps;
        RETVAL->idx    = next_idx;
        RETVAL->image  = image;
    }
    else {
        XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

Apache::ScoreboardWorkerScore
worker_score(self)
    Apache::ScoreboardParentScore self

    CODE:
    RETVAL = (modperl_worker_score_t *)apr_pcalloc(self->image->pool,
                                                   sizeof(*RETVAL));
    RETVAL->parent_idx = self->idx;
    RETVAL->worker_idx = 0;
    RETVAL->record     = my_get_scoreboard_worker(aTHX_ self->image,
                                                  self->idx, 0);

    OUTPUT:
    RETVAL
    
Apache::ScoreboardWorkerScore
next_worker_score(self, mws)
    Apache::ScoreboardParentScore self
    Apache::ScoreboardWorkerScore mws

    PREINIT:
    int next_idx;
    
    CODE:
    next_idx = mws->worker_idx + 1;
    if (next_idx < self->image->thread_limit) {
        RETVAL = (modperl_worker_score_t *)apr_pcalloc(self->image->pool,
                                                       sizeof(*RETVAL));
        RETVAL->parent_idx = mws->parent_idx;
        RETVAL->worker_idx = next_idx;
        RETVAL->record     = my_get_scoreboard_worker(aTHX_ self->image,
                                                      mws->parent_idx, next_idx);
    }
    else {
        XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
    
Apache::ScoreboardWorkerScore
next_live_worker_score(self, mws)
    Apache::ScoreboardParentScore self
    Apache::ScoreboardWorkerScore mws

    PREINIT:
    int next_idx;
    int found = 0;
    
    CODE:
    next_idx = mws->worker_idx;

    while (++next_idx < self->image->thread_limit) {
        worker_score *ws = my_get_scoreboard_worker(aTHX_ self->image,
                                                    mws->parent_idx, next_idx);
        if (LIVE_WORKER(ws)) {
            RETVAL = (modperl_worker_score_t *)apr_pcalloc(self->image->pool,
                                                           sizeof(*RETVAL));
            RETVAL->record     = ws;
            RETVAL->parent_idx = mws->parent_idx;
            RETVAL->worker_idx = next_idx;
            found++;
            break;
        }
    }

    if (!found) {
        XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    


Apache::ScoreboardWorkerScore
next_active_worker_score(self, mws)
    Apache::ScoreboardParentScore self
    Apache::ScoreboardWorkerScore mws

    PREINIT:
    int next_idx;
    int found = 0;

    CODE:
    next_idx = mws->worker_idx;
    while (++next_idx < self->image->thread_limit) {
        worker_score *ws = my_get_scoreboard_worker(aTHX_ self->image,
                                                    mws->parent_idx, next_idx);
        if (ACTIVE_WORKER(ws)) {
            RETVAL = (modperl_worker_score_t *)apr_pcalloc(self->image->pool,
                                                           sizeof(*RETVAL));
            RETVAL->record     = ws;
            RETVAL->parent_idx = mws->parent_idx;
            RETVAL->worker_idx = next_idx;
            found++;
            break;
        }
    }

    if (!found) {
        XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

pid_t
parent_score_pid(self)
    Apache::ScoreboardParentScore self









MODULE = Apache::Scoreboard PACKAGE = Apache::ScoreboardWorkerScore PREFIX = worker_score_

void
times(self)
    Apache::ScoreboardWorkerScore self

    PPCODE:
    if (GIMME == G_ARRAY) {
        /* same return values as CORE::times() */
        EXTEND(sp, 4);
        PUSHs(sv_2mortal(newSViv(self->record->times.tms_utime)));
        PUSHs(sv_2mortal(newSViv(self->record->times.tms_stime)));
        PUSHs(sv_2mortal(newSViv(self->record->times.tms_cutime)));
        PUSHs(sv_2mortal(newSViv(self->record->times.tms_cstime)));
    }
    else {
#ifdef _SC_CLK_TCK
        float tick = sysconf(_SC_CLK_TCK);
#else
        float tick = HZ;
#endif
        if (self->record->access_count) {
            /* cpu %, same value mod_status displays */
            float RETVAL = (self->record->times.tms_utime +
                            self->record->times.tms_stime +
                            self->record->times.tms_cutime +
                            self->record->times.tms_cstime);
            XPUSHs(sv_2mortal(newSVnv((double)RETVAL/tick)));
        }
        else {
            XPUSHs(sv_2mortal(newSViv((0))));
        }
    }


void
start_time(self)
    Apache::ScoreboardWorkerScore self

    ALIAS:
    stop_time = 1

    PREINIT:
    apr_time_t tp;

    PPCODE:
    ix = ix; /* warnings */
    tp = (XSANY.any_i32 == 0) ? 
         self->record->start_time : self->record->stop_time;

    SB_TRACE(MP_FUNC, "%s_time: %5" APR_TIME_T_FMT "\n",
            (XSANY.any_i32 == 0 ? "start" : "stop"), tp);

    {
        SB_TRACE(MP_FUNC, "start: %5" APR_TIME_T_FMT "\n"
                 "stop: %5" APR_TIME_T_FMT "\n"
                 "last used: %5" APR_TIME_T_FMT "\n",
                 self->record->start_time,
                 self->record->stop_time,
                 self->record->last_used);
    }

    /* do the same as Time::HiRes::gettimeofday */
    if (GIMME == G_ARRAY) {
        EXTEND(sp, 2);
        PUSHs(sv_2mortal(newSViv(apr_time_sec(tp))));
        PUSHs(sv_2mortal(newSViv(apr_time_usec(tp))));
    } 
    else {
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSVnv(apr_time_sec(tp))));
    }

long
req_time(self)
    Apache::ScoreboardWorkerScore self

    CODE:
    if (self->record->start_time == 0L) {
        RETVAL = 0L;
    }
    else {
        RETVAL = (long)
            ((self->record->stop_time - self->record->start_time) / 1000);
    }
    if (RETVAL < 0L || !self->record->access_count) {
        RETVAL = 0L;
    }

    OUTPUT:
    RETVAL

SV *
worker_score_status(self)
    Apache::ScoreboardWorkerScore self

    CODE:
    RETVAL = newSV(0);
    sv_setnv(RETVAL, (double)self->record->status);
    Perl_sv_setpvf(aTHX_ RETVAL, "%c", status_flags[self->record->status]);
    SvNOK_on(RETVAL); /* dual-var */ 

    OUTPUT:
    RETVAL

# at the moment always gives 0 (blame httpd)    
U32
worker_score_tid(self)
    Apache::ScoreboardWorkerScore self

    CODE:
    RETVAL = worker_score_tid(self);

    OUTPUT:
    RETVAL
    
int
worker_score_thread_num(self)
    Apache::ScoreboardWorkerScore self
    
unsigned long
worker_score_access_count(self)
    Apache::ScoreboardWorkerScore self

unsigned long
worker_score_bytes_served(self)
    Apache::ScoreboardWorkerScore self

unsigned long
worker_score_my_access_count(self)
    Apache::ScoreboardWorkerScore self

unsigned long
worker_score_my_bytes_served(self)
    Apache::ScoreboardWorkerScore self

unsigned long
worker_score_conn_bytes(self)
    Apache::ScoreboardWorkerScore self

unsigned short
worker_score_conn_count(self)
    Apache::ScoreboardWorkerScore self

char *
worker_score_client(self)
    Apache::ScoreboardWorkerScore self

char *
worker_score_request(self)
    Apache::ScoreboardWorkerScore self

char *
worker_score_vhost(self)
    Apache::ScoreboardWorkerScore self

apr_uint32_t
worker_score_most_recent(self)
    Apache::ScoreboardWorkerScore self
