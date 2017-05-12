#ifndef PERL_COUCHBASE_ASYNC_H_
#define PERL_COUCHBASE_ASYNC_H_

#include "perl-couchbase.h"
#include <perlio.h>

typedef void(*plcba_c_evhandler)(libcouchbase_socket_t, short, void*);
typedef struct libcouchbase_io_opt_st plcba_cbcio;


/*two layered approach:
 LAYER ONE:
 layer defines event loop functions for libcouchbase.
 layer exposes perl-compatible event loop API for event loop implementation
 to select() on sockets, and stop selecting on them.
 
 event loop implementation *must* keep track of an opaque object passed to it,
 and call into the 'master' XS function with the following:
    the opaque object
    the event which ocurred.
    
 this opaque object on the C end will contain the private C I/O handlers, and
 a void*-typed argument, the internals of which will be known only to libcouchbase
 itself.
 
 specifically, Perl will only know about update_event() and delete_event().
 update_event will be called with an additional empty RV - which, if needed
 can be populated with a dup'd file descriptor, available for perl to select()
 on.
 The purpose for the dup'd fd is that perl will close() it when its object goes
 out of scope. We don't want this to be seen from within libcouchbase.
 
 LAYER TWO:
 this layer defines the notification mechanism for operation results.
 
 Operation requests will involve a user-defined 'opaque' data object (SV*),
 and is asynchronously batched to libcouchbase_* functions.
 
 The cookies for these functions are special. A cookie will have a hashref
 in which it will store a Couchbase::Client::Return object for each key.
 (in the case of stat(), which is only a single command, a pseudo-key will be
 used TBC..)
 
 Additionally, the cookie will have a counter which will decrement for each
 response received. When the counter reaches 0, it means all the responses have
 been received.
 
 The cookie will have an SV* which is a function to call once the data has been
 collected for an operation. It will be passed the hashref and the user-supplied
 data
*/
  
#define PLCBA_EVENT_CLASS "Couchbase::Client::Async::Event"

/*various fields for helper class*/
typedef enum {
    PLCBA_EVIDX_FD,
    PLCBA_EVIDX_DUPFH,
    PLCBA_EVIDX_WATCHFLAGS,
    PLCBA_EVIDX_STATEFLAGS,
    PLCBA_EVIDX_OPAQUE,
    PLCBA_EVIDX_PLDATA,
} PLCBA_evidx_t;

#define PLCBA_EVIDX_TIMERID PLCBA_EVIDX_FD

/*various types of actions which may be taken by the callback*/
typedef enum {
    PLCBA_EVACTION_WATCH,
    PLCBA_EVACTION_UNWATCH,
    PLCBA_EVACTION_SUSPEND,
    PLCBA_EVACTION_RESUME,
} PLCBA_evaction_t;

typedef enum {
    PLCBA_EVSTATE_INITIALIZED,
    PLCBA_EVSTATE_ACTIVE,
    PLCBA_EVSTATE_SUSPENDED
} PLCBA_evstate_t;

typedef enum {
    PLCBA_EVTYPE_IO,
    PLCBA_EVTYPE_TIMER
} PLCBA_evtype_t;

typedef struct PLCBA_c_event_st PLCBA_c_event;

struct PLCBA_c_event_st {
    /*position within linked list*/
    PLCBA_c_event *next;
    PLCBA_c_event *prev;
    
    /*Couchbase::Client::Async::Event object*/
    AV *pl_event;
    PLCBA_evtype_t evtype;
    
    struct {
        plcba_c_evhandler handler;
        void *arg;
    } c;

    
    /*we can compare some basic flags and functions here with these
     two flags, so that we don't need to call into perl for stupid
     stuff*/
    
    short flags;
    PLCBA_evstate_t state;
    /*FD from libcouchbase*/
    libcouchbase_socket_t fd;    
};



/*our base object*/
typedef struct {
    /*base object*/
    PLCB_t base;
    
    /*reference to 'base' object*/
    SV *base_rv;
    
    SV *cv_evmod;
    SV *cv_timermod;
    SV *cv_err;
    SV *cv_waitdone;
    
    PLCBA_c_event *cevents;
    HV *event_stash;
    
} PLCBA_t;


typedef enum {
    PLCBA_CBTYPE_COMPLETION,
    PLCBA_CBTYPE_INCREMENTAL
} PLCBA_cbtype_t;

typedef enum {
    PLCBA_REQTYPE_SINGLE,
    PLCBA_REQTYPE_MULTI,
} PLCBA_reqtype_t;

typedef struct {
    /*hash of results, (specifically, Client::Couchbase::Return objects)*/
    HV *results;
    
    /*counter of remaining requests for this cookie. when this hits zero,
     the callback is invoked, and this object is freed*/
    int remaining;
    
    /*the callback to invoke*/
    SV *cbdata;
    
    /*any user defined data which was passed to us when the request was made*/
    SV *callcb;
    
    /*whether this should be called 'incrementally' for each response, or
     at the end, when all operations have been completed*/
    PLCBA_cbtype_t cbtype;
    
    PLCBA_t *parent;
} PLCBA_cookie_t;



/*this specifies indices for perl functions which interact with an event loop
 to modify events:
 
 sub event_update {
    my ($fd,$evtype,$arg) = @_;
 }
*/

/*extra constructor parameters*/
typedef enum {
    PLCBA_CTORIDX_CBEVMOD = PLCB_CTOR_STDIDX_MAX,
    PLCBA_CTORIDX_CBTIMERMOD,
    PLCBA_CTORIDX_CBERR,
    PLCBA_CTORIDX_CBWAITDONE,
    PLCBA_CTORIDX_BLESS_EVENT,
    
} PLCBA_ctoridx_t;

/*Types of commands we currently handle*/

#define plcba_cmd_needs_key(cmd) \
    (cmd < PLCBA_CMD_MISC)

#define plcba_cmd_needs_conversion(cmd) \
    (cmd & (PLCBA_CMD_SET|PLCBA_CMD_ADD))

#define plcba_cmd_needs_strval(cmd) \
    (cmd & (PLCBA_CMD_SET \
        |PLCBA_CMD_REPLACE|PLCBA_CMD_APPEND|PLCBA_CMD_PREPEND))

typedef enum {
    PLCBA_CMD_GET = 0x1,
    
    /*'clean' mutators*/
    PLCBA_CMD_SET = 0x2,
    PLCBA_CMD_ADD = 0x4,
    
    /*'dirty' mutators*/
    PLCBA_CMD_REPLACE = 0x8,
    PLCBA_CMD_APPEND = 0x10,
    PLCBA_CMD_PREPEND = 0x12,
    
    /*simple key operations*/
    PLCBA_CMD_REMOVE = 0x20,
    PLCBA_CMD_TOUCH = 0x30,
    
    /*arithmetic*/
    PLCBA_CMD_ARITHMETIC = 0x100,
    
    PLCBA_CMD_MISC,
    PLCBA_CMD_STATS,
    PLCBA_CMD_FLUSH,
} PLCBA_cmd_t;

/*Fields for the 'request' object*/
typedef enum {
    PLCBA_REQIDX_KEY,
    PLCBA_REQIDX_VALUE,
    PLCBA_REQIDX_EXP,
    PLCBA_REQIDX_CAS,
    PLCBA_REQIDX_ARITH_DELTA,
    PLCBA_REQIDX_ARITH_INITIAL,
    PLCBA_REQIDX_STAT_ARGS,
} PLCBA_reqidx_t;

/*C version of the 'request' object*/
typedef struct PLCBA_request_st {
    char *key;
    STRLEN nkey;
    
    SV *value;
    STRLEN nvalue;
    uint32_t store_flags;
    
    uint64_t cas;
    time_t exp;
        
    int has_conversion;
    
    struct {
        int64_t delta;
        uint64_t initial;
        int create;
    } arithmetic;
    
    
} PLCBA_request_t;

/*wire callbacks*/
void plcba_setup_callbacks(PLCBA_t *async);

/*wire io structure*/
plcba_cbcio *plcba_make_io_opts(PLCBA_t *async);


/*immediate error notification*/
void plcba_callback_notify_err(PLCBA_t *async,
                               PLCBA_cookie_t *cookie,
                               const char *key, size_t nkey,
                               libcouchbase_error_t err);


/*prototypes for perl-facing functions, for Async.xs*/
SV *PLCBA_construct(const char*, AV*);
void PLCBA_connect(SV*);
void PLCBA_HaveEvent(const char*, short, SV*);
void PLCBA_request(SV *, int, int, SV*, SV*, int, AV*);


#endif /* PERL_COUCHBASE_ASYNC_H_ */
