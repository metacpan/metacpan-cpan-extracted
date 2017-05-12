/*this file contains code controlling the first,
 I/O event facing layer*/

#include "perl-couchbase.h"
#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif
#include <libcouchbase/plugins/io/bsdio-inl.c>
#include <stdarg.h>

#define X_IOPROCS_OPTIONS(X) \
    X("event_update", CV, cv_evmod) \
    X("timer_update", CV, cv_timermod) \
    X("event_init", CV, cv_evinit) \
    X("event_clean", CV, cv_evclean) \
    X("timer_init", CV, cv_tminit) \
    X("timer_clean", CV, cv_tmclean) \
    X("data", SV, userdata)

static void
cb_args_noret(SV *code, int mortalize, int nargs, ...)
{
    va_list ap;
    SV *cursv;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs);

    va_start(ap, nargs);

    while (nargs) {
        cursv = va_arg(ap, SV*);
        if (mortalize) {
            cursv = sv_2mortal(cursv);
        }

        PUSHs(cursv);
        nargs--;
    }
    va_end(ap);

    PUTBACK;

    call_sv(code, G_DISCARD);

    FREETMPS;
    LEAVE;
}

static void *
create_event_common(lcb_io_opt_t cbcio, int type)
{
    plcb_EVENT *cevent;
    plcb_IOPROCS *async;
    SV *initproc = NULL, *tmprv = NULL;
    async = (plcb_IOPROCS*) cbcio->v.v0.cookie;

    Newxz(cevent, 1, plcb_EVENT);
    cevent->pl_event = newAV();
    cevent->rv_event = newRV_noinc((SV*)cevent->pl_event);
    cevent->evtype = type;
    cevent->fd = -1;

    sv_bless(cevent->rv_event, gv_stashpv(PLCB_EVENT_CLASS, GV_ADD));
    av_store(cevent->pl_event, PLCB_EVIDX_OPAQUE, newSViv(PTR2IV(cevent)));
    av_store(cevent->pl_event, PLCB_EVIDX_FD, newSViv(-1));
    av_store(cevent->pl_event, PLCB_EVIDX_TYPE, newSViv(type));
    av_store(cevent->pl_event, PLCB_EVIDX_WATCHFLAGS, newSViv(0));

    tmprv = newRV_inc(*av_fetch(cevent->pl_event, PLCB_EVIDX_OPAQUE, 0));
    sv_bless(tmprv, gv_stashpv("Couchbase::IO::_CEvent", GV_ADD));
    SvREFCNT_dec(tmprv);


    if (type == PLCB_EVTYPE_IO) {
        initproc = async->cv_evinit;
    } else {
        initproc = async->cv_tminit;
    }

    if (initproc) {
        cb_args_noret(initproc, 0, 2, async->userdata, cevent->rv_event);
    }
    return cevent;
}

static void *
create_event(lcb_io_opt_t cbcio)
{
    return create_event_common(cbcio, PLCB_EVTYPE_IO);
}

static void
destroy_event(lcb_io_opt_t cbcio, void *event)
{
    plcb_EVENT *cevent = (plcb_EVENT*)event;
    plcb_IOPROCS *async = (plcb_IOPROCS*)cbcio->v.v0.cookie;
    if (async->cv_evclean) {
        cb_args_noret(async->cv_evclean, 0, 2, async->selfrv, cevent->rv_event);
    }

    SvREFCNT_dec(cevent->rv_event);
    Safefree(cevent);
}

static void
modify_event_perl(plcb_IOPROCS *async, plcb_EVENT *cevent, short flags)
{
    SV **tmpsv;
    tmpsv = av_fetch(cevent->pl_event, PLCB_EVIDX_FD, 1);

    if (SvIOK(*tmpsv)) {
        SvIVX(*tmpsv) = cevent->fd;
    } else {
        sv_setiv(*tmpsv, cevent->fd);
    }

    SvIVX(async->flags_sv) = flags;
    /* Figure out the proper masks */

    SvIVX(async->sched_r_sv) = flags & LCB_READ_EVENT && (cevent->flags & LCB_READ_EVENT) == 0;
    SvIVX(async->sched_w_sv) = flags & LCB_WRITE_EVENT && (cevent->flags & LCB_WRITE_EVENT) == 0;
    SvIVX(async->stop_r_sv) = (flags & LCB_READ_EVENT) == 0  && cevent->flags & LCB_READ_EVENT;
    SvIVX(async->stop_w_sv) = (flags & LCB_WRITE_EVENT) == 0 && cevent->flags & LCB_WRITE_EVENT;


    cb_args_noret(async->cv_evmod, 0, 7,
        async->userdata, cevent->rv_event, async->flags_sv,
        async->sched_r_sv, async->sched_w_sv,
        async->stop_r_sv, async->stop_w_sv);

    cevent->flags = flags;
    tmpsv = av_fetch(cevent->pl_event, PLCB_EVIDX_WATCHFLAGS, 1);
    SvIVX(*tmpsv) = cevent->flags;
}

/*start select()ing on a socket*/
static int
update_event(lcb_io_opt_t cbcio, lcb_socket_t sock, void *event, short flags,
    void *cb_data, lcb_ioE_callback handler)
{
    plcb_IOPROCS *object;
    plcb_EVENT *cevent;
    
    cevent = (plcb_EVENT*)event;
    object = (plcb_IOPROCS*)(cbcio->v.v0.cookie);

    if (cevent->flags == flags &&
            cevent->lcb_handler == handler &&
            cevent->lcb_arg == cb_data) {

        return 0;
    }

    /*these are set in the AV after the call to Perl*/
    cevent->fd = sock;
    cevent->lcb_handler = handler;
    cevent->lcb_arg = cb_data;

    modify_event_perl(object, cevent, flags);
    return 0;
}

/*stop select()ing a socket*/
static void
delete_event(lcb_io_opt_t cbcio, lcb_socket_t sock, void *event)
{
    update_event(cbcio, sock, event, 0, NULL, NULL);
}

static void *
create_timer(lcb_io_opt_t cbcio)
{
    return create_event_common(cbcio, PLCB_EVTYPE_TIMER);
}

static void
modify_timer_perl(plcb_IOPROCS *async, plcb_EVENT *cevent, uint32_t usecs,
    int action)
{
    SvNVX(async->usec_sv) = (double) usecs / 1000000;
    SvIVX(async->action_sv) = action;
    cb_args_noret(async->cv_timermod, 0, 4,
        async->userdata, cevent->rv_event, async->action_sv, async->usec_sv);
}

static int
update_timer(lcb_io_opt_t cbcio, void *event, uint32_t usecs,
    void *cb_data, lcb_ioE_callback handler)
{
    /*we cannot do any sane caching or clever magic like we do for I/O
     watchers, because the time will always be different*/
    plcb_EVENT *cevent = (plcb_EVENT*)event;

    cevent->lcb_handler = handler;
    cevent->lcb_arg = cb_data;
    modify_timer_perl(cbcio->v.v0.cookie, cevent, usecs, PLCB_EVACTION_WATCH);
    return 0;
}

static void delete_timer(lcb_io_opt_t cbcio, void *event)
{
    plcb_EVENT *cevent = (plcb_EVENT*)event;
    modify_timer_perl(cbcio->v.v0.cookie, cevent, 0, PLCB_EVACTION_UNWATCH);
}

void
PLCB_ioprocs_dtor(lcb_io_opt_t cbcio)
{
    /*free any remaining events*/
    plcb_IOPROCS *async = cbcio->v.v0.cookie;

    if (async->refcount) {
        return;
    }

    #define X(name, t, tgt) SvREFCNT_dec(async->tgt); async->tgt = NULL;
    X_IOPROCS_OPTIONS(X)
    #undef X

    SvREFCNT_dec(async->action_sv);
    SvREFCNT_dec(async->flags_sv);
    SvREFCNT_dec(async->usec_sv);
    SvREFCNT_dec(async->userdata);
    SvREFCNT_dec(async->sched_r_sv);
    SvREFCNT_dec(async->sched_w_sv);
    SvREFCNT_dec(async->stop_r_sv);
    SvREFCNT_dec(async->stop_w_sv);

    Safefree(async);
    Safefree(cbcio);
}

static void startstop_dummy(lcb_io_opt_t io) { (void)io; }

SV *
PLCB_ioprocs_new(SV *options)
{
    plcb_IOPROCS async_s = { NULL }, *async = NULL;
    lcb_io_opt_t cbcio = NULL;
    SV *ptriv, *blessedrv;

    /* First make sure all the options are ok */
    plcb_OPTION argopts[] = {
        #define X(name, t, tgt) PLCB_KWARG(name, t, &async_s.tgt),
        X_IOPROCS_OPTIONS(X)
        #undef X
        { NULL }
    };

    plcb_extract_args(options, argopts);

    /* Verify we have at least the basic functions */
    if (!async_s.cv_evmod) {
        die("Need event_update");
    }
    if (!async_s.cv_timermod) {
        die("Need timer_update");
    }

    if (!async_s.userdata) {
        async_s.userdata = &PL_sv_undef;
    }

    Newxz(cbcio, 1, struct lcb_io_opt_st);
    Newxz(async, 1, plcb_IOPROCS);

    *async = async_s;

    #define X(name, t, tgt) SvREFCNT_inc(async->tgt);
    X_IOPROCS_OPTIONS(X)
    #undef X

    ptriv = newSViv(PTR2IV(async));
    blessedrv = newRV_noinc(ptriv);
    sv_bless(blessedrv, gv_stashpv(PLCB_IOPROCS_CLASS, GV_ADD));

    async->refcount = 1;
    async->iops_ptr = cbcio;
    cbcio->v.v0.cookie = async;

    async->selfrv = newRV_inc(ptriv); sv_rvweaken(async->selfrv);
    async->action_sv = newSViv(0); SvREADONLY_on(async->action_sv);
    async->flags_sv = newSViv(0); SvREADONLY_on(async->flags_sv);
    async->usec_sv = newSVnv(0); SvREADONLY_on(async->usec_sv);
    async->sched_r_sv = newSViv(0); SvREADONLY_on(async->sched_r_sv);
    async->sched_w_sv = newSViv(0); SvREADONLY_on(async->sched_w_sv);
    async->stop_r_sv = newSViv(0); SvREADONLY_on(async->stop_r_sv);
    async->stop_w_sv = newSViv(0); SvREADONLY_on(async->stop_w_sv);

    /* i/o events */
    cbcio->v.v0.create_event = create_event;
    cbcio->v.v0.destroy_event = destroy_event;
    cbcio->v.v0.update_event = update_event;
    cbcio->v.v0.delete_event = delete_event;

    /* timer events */
    cbcio->v.v0.create_timer = create_timer;
    cbcio->v.v0.destroy_timer = destroy_event;
    cbcio->v.v0.delete_timer = delete_timer;
    cbcio->v.v0.update_timer = update_timer;

    wire_lcb_bsd_impl(cbcio);

    cbcio->v.v0.run_event_loop = startstop_dummy;
    cbcio->v.v0.stop_event_loop = startstop_dummy;
    cbcio->v.v0.need_cleanup = 0;

    /* Now all we need to do is return the blessed reference */
    return blessedrv;
}
