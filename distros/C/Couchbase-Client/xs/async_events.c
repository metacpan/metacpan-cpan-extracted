/*this file contains code controlling the first,
 I/O event facing layer*/

#include "perl-couchbase-async.h"
#include "plcb-util.h"

#ifndef _WIN32
#include <libcouchbase/libevent_io_opts.h>
#define plcba_default_io_opts() \
    libcouchbase_create_io_ops(LIBCOUCHBASE_IO_OPS_LIBEVENT,NULL,NULL)

#else

#include <libcouchbase/winsock_io_opts.h>
#define plcba_default_io_opts() \
    libcouchbase_create_winsock_io_opts()

#endif


static inline void
plcb_call_sv_with_args_noret(SV *code,
                       int mortalize,
                       int nargs,
                       ...)
{
    va_list ap;
    SV *cursv;    
    
    dSP;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs);
        
    va_start(ap, nargs);
    while(nargs) {
        cursv = va_arg(ap, SV*);
        if(mortalize) {
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


static void *create_event(plcba_cbcio *cbcio)
{
    PLCBA_c_event *cevent;
    PLCBA_t *async;
    
    async = (PLCBA_t*)cbcio->cookie;
    Newxz(cevent, 1, PLCBA_c_event);
    
    cevent->pl_event = newAV();
    cevent->evtype = PLCBA_EVTYPE_IO;
    
    av_store(cevent->pl_event, PLCBA_EVIDX_OPAQUE,
             newSViv(PTR2IV(cevent)));
    
    if(async->cevents) {
        cevent->prev = NULL;
        cevent->next = async->cevents;
        async->cevents->prev = cevent;
        async->cevents = cevent;
    } else {
        async->cevents = cevent;
        cevent->next = NULL;
        cevent->prev = NULL;
    }
    
    return cevent;
}

static void destroy_event(plcba_cbcio *cbcio, void *event)
{
    PLCBA_c_event *cevent = (PLCBA_c_event*)event;
    PLCBA_t *async = (PLCBA_t*)cbcio->cookie;
    
    //warn("Event destruction requested");
    
    if(cevent == async->cevents) {
        if(cevent->next) {
            async->cevents = cevent->next;
        }
    } else if(cevent->next == NULL) {
        if(cevent->prev) {
            cevent->prev->next = NULL;
        }
    } else if (cevent->next && cevent->prev) {
        cevent->next->prev = cevent->prev;
        cevent->prev->next = cevent->next;
    } else {
        die("uhh... messed up double-linked list state");
    }
    
    if(cevent->pl_event) {
        SvREFCNT_dec(cevent->pl_event);
        cevent->pl_event = NULL;
    }
    
    Safefree(cevent);
}

static inline void
modify_event_perl(PLCBA_t *async, PLCBA_c_event *cevent,
                  PLCBA_evaction_t action,
                  short flags)
{
    SV **tmpsv;
    dSP;
    
    tmpsv = av_fetch(cevent->pl_event, PLCBA_EVIDX_FD, 1);
    if(SvIOK(*tmpsv)) {
        if(SvIV(*tmpsv) != cevent->fd) {
            /*file descriptor mismatch!*/
            av_delete(cevent->pl_event, PLCBA_EVIDX_DUPFH, G_DISCARD);
        }
    } else {
        sv_setiv(*tmpsv, cevent->fd);
    }
    
    plcb_call_sv_with_args_noret(async->cv_evmod, 1, 3,
                                 newRV_inc( (SV*)(cevent->pl_event)),
                                 newSViv(action), newSViv(flags));
    
    /*set the current flags*/
    if(action != PLCBA_EVACTION_SUSPEND && action != PLCBA_EVACTION_RESUME) {
        sv_setiv(
            *(av_fetch(cevent->pl_event, PLCBA_EVIDX_WATCHFLAGS, 1)),
            flags);
    }
    
    /*set the current state*/
    sv_setiv(
        *(av_fetch(cevent->pl_event, PLCBA_EVIDX_STATEFLAGS, 1)),
        cevent->state);
}

/*start select()ing on a socket*/
static int update_event(plcba_cbcio *cbcio,
                        libcouchbase_socket_t sock,
                        void *event,
                        short flags,
                        void *cb_data,
                        plcba_c_evhandler handler)
{
    PLCBA_t *object;
    PLCBA_c_event *cevent;
    PLCBA_evaction_t action;
    PLCBA_evstate_t new_state;
    
    cevent = (PLCBA_c_event*)event;
    object = (PLCBA_t*)(cbcio->cookie);
    
    if(!flags) {
        action = PLCBA_EVACTION_UNWATCH;
        new_state = PLCBA_EVSTATE_INITIALIZED;
    } else {
        action = PLCBA_EVACTION_WATCH;
        new_state = PLCBA_EVSTATE_ACTIVE;
    }

    
    if(cevent->flags == flags &&
       cevent->c.handler == handler &&
       cevent->c.arg == cb_data &&
       new_state == cevent->state) {
        /*nothing to do here*/
        return 0;
    }
    
    /*these are set in the AV after the call to Perl*/
    cevent->fd = sock;
    cevent->flags = flags;
    cevent->c.handler = handler;
    cevent->c.arg = cb_data;
    
    modify_event_perl(object, cevent, action, flags);
    return 0;
}

/*stop select()ing a socket*/
static void delete_event(plcba_cbcio *cbcio,
                         libcouchbase_socket_t sock, void *event)
{
    update_event(cbcio, sock, event, 0, NULL, NULL);
}


/*
  destroy_timer == destroy_event
*/


static void *create_timer(plcba_cbcio *cbcio)
{
    PLCBA_c_event *cevent = create_event(cbcio);
    cevent->evtype = PLCBA_EVTYPE_TIMER;
    //warn("Created timer %p", cevent);
    return cevent;
}

static inline void
modify_timer_perl(PLCBA_t *async,PLCBA_c_event *cevent,
                  uint32_t usecs, PLCBA_evaction_t action)
{
    SV **tmpsv;
    dSP;
    //warn("Calling cv_timermod");
    plcb_call_sv_with_args_noret(async->cv_timermod,
                                 1, 3,
                                 newRV_inc( (SV*)cevent->pl_event ),
                                 newSViv(action), newSVuv(usecs));
}
static int update_timer(plcba_cbcio *cbcio,
                         void *event, uint32_t usecs,
                         void *cb_data,
                         plcba_c_evhandler handler)
{
    /*we cannot do any sane caching or clever magic like we do for I/O
     watchers, because the time will always be different*/
    PLCBA_c_event *cevent = (PLCBA_c_event*)event;
    
    cevent->c.handler = handler;
    cevent->c.arg = cb_data;
        
    modify_timer_perl(cbcio->cookie, cevent, usecs, PLCBA_EVACTION_WATCH);
    return 0;
}

static void delete_timer(plcba_cbcio *cbcio, void *event)
{
    PLCBA_c_event *cevent = (PLCBA_c_event*)event;
    //warn("Deletion requested for timer!");
    modify_timer_perl(cbcio->cookie, cevent, 0, PLCBA_EVACTION_UNWATCH);
}


/*We need to resume watching on all events here*/
static void run_event_loop(plcba_cbcio *cbcio)
{
    PLCBA_t *async;
    PLCBA_c_event *cevent;
    
    async = (PLCBA_t*)cbcio->cookie;
    
    //warn("Resuming events..");
    for(cevent = async->cevents; cevent; cevent = cevent->next) {
        if(cevent->evtype == PLCBA_EVTYPE_IO && cevent->fd > 0) {
            cevent->state = PLCBA_EVSTATE_ACTIVE;
            modify_event_perl(
                async, cevent, PLCBA_EVACTION_RESUME, cevent->flags);
        }
    }
    
    //warn("Running event loop...");
}

/*
 we use this to tell the event system that pending operations have been
 completed.
 this is mainly useful for things like connect().
 
 Apparently we need to make sure libcouchbase also does not actually receive
 events here either, or things become inconsistent.
 
*/
static void stop_event_loop(plcba_cbcio *cbcio)
{
    PLCBA_t *async;
    PLCBA_c_event *cevent;
    dSP;

    async = cbcio->cookie;
    
    for(cevent = async->cevents; cevent; cevent = cevent->next) {
        if(cevent->evtype == PLCBA_EVTYPE_IO && cevent->fd > 0) {
            cevent->state = PLCBA_EVSTATE_SUSPENDED;
            modify_event_perl(async, cevent, PLCBA_EVACTION_SUSPEND, -1);
        }
    }
    
    //warn("Calling cv_waitdone");
    PUSHMARK(SP);
    call_sv(async->cv_waitdone, G_DISCARD|G_NOARGS);
}

void destructor(plcba_cbcio *cbcio)
{
    /*free any remaining events*/
    PLCBA_c_event *cevent;
    PLCBA_t *async;
    if(!cbcio) {
        return;
    }
    
    if(! (async = cbcio->cookie) ) {
        return; /*already freed*/
    }
    
    cevent = async->cevents;
    while(cevent) {
        if(cevent->next) {
            cevent = cevent->next;
            free(cevent->prev);
        } else {
            free(cevent);
            cevent = NULL;
        }
    }
    async->cevents = NULL;
    cbcio->cookie = NULL;
}


plcba_cbcio *
plcba_make_io_opts(PLCBA_t *async)
{
    plcba_cbcio *cbcio;
    
    cbcio = plcba_default_io_opts();
    
    cbcio->cookie = async;
    
    /* i/o events */
    cbcio->create_event = create_event;
    cbcio->destroy_event = destroy_event;
    cbcio->update_event = update_event;
    cbcio->delete_event = delete_event;
    
    /* timer events */
    cbcio->create_timer = create_timer;
    cbcio->destroy_timer = destroy_event;
    cbcio->delete_timer = delete_timer;
    cbcio->update_timer = update_timer;
    
    cbcio->run_event_loop = run_event_loop;
    cbcio->stop_event_loop = stop_event_loop;
    cbcio->destructor = destructor;
    
    return cbcio;
}
